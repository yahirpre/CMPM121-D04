// Drive Godot as a command-line tool, the way we drove Vite and Deno.
//
//   deno task setup          download the pinned Godot and its web template into .tools/
//   deno run -A scripts/godot.ts -- <godot args>   run Godot strictly (used by the other tasks)
//
// Set GODOT=/path/to/godot to use your own install instead of .tools/.

const VERSION = "4.7.2";
const RELEASE = `https://github.com/godotengine/godot/releases/download/${VERSION}-stable`;
import { fromFileUrl } from "jsr:@std/path@1";

const TOOLS = fromFileUrl(new URL("../.tools/", import.meta.url));

// Editor builds per platform: [zip on the release page, binary inside .tools/].
const MAC: [string, string] = ["macos.universal.zip", "Godot.app/Contents/MacOS/Godot"];
const EDITORS: Record<string, [string, string]> = {
  "darwin-aarch64": MAC,
  "darwin-x86_64": MAC,
  "linux-x86_64": ["linux.x86_64.zip", `Godot_v${VERSION}-stable_linux.x86_64`],
  "linux-aarch64": ["linux.arm64.zip", `Godot_v${VERSION}-stable_linux.arm64`],
  "windows-x86_64": ["win64.exe.zip", `Godot_v${VERSION}-stable_win64_console.exe`],
  "windows-aarch64": ["windows_arm64.exe.zip", `Godot_v${VERSION}-stable_windows_arm64_console.exe`],
};
const PLATFORM = `${Deno.build.os}-${Deno.build.arch}`;

// Godot reports script errors but still exits 0, so we watch its output too.
const FAILURE = /SCRIPT ERROR|Parse Error|Failed to load script/;

function godotPath(): string {
  const custom = Deno.env.get("GODOT");
  if (custom) return custom;
  const editor = EDITORS[PLATFORM];
  if (!editor) throw new Error(`No Godot build listed for ${PLATFORM}; set GODOT=/path/to/godot`);
  return TOOLS + editor[1];
}

async function run(args: string[]): Promise<number> {
  const child = new Deno.Command(godotPath(), {
    args,
    stdout: "piped",
    stderr: "piped",
  }).spawn();
  let sawFailure = false;
  let sawFontconfig = false;
  const relay = async (stream: ReadableStream<Uint8Array>, out: typeof Deno.stdout) => {
    for await (const chunk of stream) {
      const text = new TextDecoder().decode(chunk);
      if (FAILURE.test(text)) sawFailure = true;
      if (text.includes("fontconfig")) sawFontconfig = true;
      await out.write(chunk);
    }
  };
  await Promise.all([relay(child.stdout, Deno.stdout), relay(child.stderr, Deno.stderr)]);
  const { code } = await child.status;
  if (sawFontconfig) {
    console.error("\ngodot.ts: the fontconfig errors above are harmless; to silence them on Linux,");
    console.error("install the font library: sudo apt install libfontconfig1 (or your distro's fontconfig).");
  }
  if (code === 0 && sawFailure) {
    console.error("\ngodot.ts: Godot exited 0 but printed script errors; treating as failure.");
    return 1;
  }
  return code;
}

// --- setup -----------------------------------------------------------------

async function download(url: string, dest: string) {
  console.log(`Downloading ${url}`);
  const response = await fetch(url);
  if (!response.ok || !response.body) throw new Error(`${response.status} for ${url}`);
  await response.body.pipeTo((await Deno.create(dest)).writable);
}

async function unzip(zip: string, dir: string) {
  // macOS ships unzip; Windows 10+ ships a tar that reads zips. Some Linux
  // installs lack unzip, so fall back to Python's zipfile through uv.
  const attempts: [string, string[]][] = Deno.build.os === "windows"
    ? [["tar", ["-xf", zip, "-C", dir]]]
    : [
      ["unzip", ["-q", "-o", zip, "-d", dir]],
      ["uv", ["run", "--no-project", "python", "-m", "zipfile", "-e", zip, dir]],
    ];
  for (const [cmd, args] of attempts) {
    try {
      const { success } = await new Deno.Command(cmd, { args }).output();
      if (!success) continue;
      if (Deno.build.os !== "windows") await Deno.chmod(godotPath(), 0o755); // zipfile drops this bit
      return;
    } catch (e) {
      if (!(e instanceof Deno.errors.NotFound)) throw e;
    }
  }
  throw new Error(`Could not extract ${zip}`);
}

// The export templates archive is 1.3 GB, but we only need one 10 MB file in it.
// A zip keeps its table of contents at the end, so we read that first, then
// fetch just the bytes of the entry we want using HTTP range requests.
async function fetchRange(url: string, start: number, end: number): Promise<Uint8Array<ArrayBuffer>> {
  const response = await fetch(url, { headers: { Range: `bytes=${start}-${end}` } });
  if (response.status !== 206) throw new Error(`Range request failed: ${response.status}`);
  return new Uint8Array(await response.arrayBuffer());
}

async function extractRemoteEntry(url: string, name: string): Promise<Uint8Array<ArrayBuffer>> {
  const probe = await fetch(url, { headers: { Range: "bytes=0-0" } });
  await probe.body?.cancel();
  const size = Number(probe.headers.get("content-range")?.split("/")[1]);
  const tail = await fetchRange(url, size - 65536, size - 1);
  const view = new DataView(tail.buffer);
  let eocd = tail.length - 22; // end-of-central-directory record, signature PK\5\6
  while (view.getUint32(eocd, true) !== 0x06054b50) eocd--;
  const dirSize = view.getUint32(eocd + 12, true);
  const dirOffset = view.getUint32(eocd + 16, true);
  const dir = await fetchRange(url, dirOffset, dirOffset + dirSize - 1);
  const d = new DataView(dir.buffer);
  for (let p = 0; p < dir.length;) { // central directory entries, signature PK\1\2
    const method = d.getUint16(p + 10, true);
    const compressed = d.getUint32(p + 20, true);
    const nameLength = d.getUint16(p + 28, true);
    const extraLength = d.getUint16(p + 30, true);
    const commentLength = d.getUint16(p + 32, true);
    const local = d.getUint32(p + 42, true);
    const entry = new TextDecoder().decode(dir.subarray(p + 46, p + 46 + nameLength));
    if (entry === name) {
      const header = new DataView((await fetchRange(url, local, local + 29)).buffer);
      const start = local + 30 + header.getUint16(26, true) + header.getUint16(28, true);
      const data = await fetchRange(url, start, start + compressed - 1);
      if (method === 0) return data;
      const inflated = new Blob([data]).stream().pipeThrough(new DecompressionStream("deflate-raw"));
      return new Uint8Array(await new Response(inflated).arrayBuffer());
    }
    p += 46 + nameLength + extraLength + commentLength;
  }
  throw new Error(`${name} not found in ${url}`);
}

// One path that works on every platform, for tools like VS Code's godot-tools
// (.vscode/settings.json points at .tools/godot). Its own _sc_ keeps editor data
// in .tools/editor_data, the same place the real binary keeps it.
async function linkForEditors() {
  const link = `${TOOLS}godot${Deno.build.os === "windows" ? ".exe" : ""}`;
  await Deno.remove(link).catch(() => {});
  // On Windows, link the real Godot, not the _console.exe beside it: that one is a small
  // wrapper that finds Godot by its own file name, so a renamed link to it cannot start.
  const target = godotPath().replace("_console.exe", ".exe");
  if (Deno.build.os === "windows") await Deno.link(target, link); // symlinks need admin
  else await Deno.symlink(godotPath(), link);
  await Deno.writeTextFile(`${TOOLS}_sc_`, "");
}

async function setup() {
  if (Deno.env.get("GODOT")) {
    await Deno.stat(godotPath()); // throws NotFound if GODOT points nowhere
    console.log(`Using GODOT=${godotPath()}. Install its Web export template from the editor:`);
    console.log("Editor > Manage Export Templates > Download and Install.");
    return;
  }
  await Deno.mkdir(TOOLS, { recursive: true });
  if (!EDITORS[PLATFORM]) throw new Error(`No Godot build listed for ${PLATFORM}`);
  const [zipName] = EDITORS[PLATFORM];
  try {
    await Deno.stat(godotPath());
    console.log(`Godot ${VERSION} already in .tools/`);
  } catch {
    const zip = `${TOOLS}godot.zip`;
    try {
      await download(`${RELEASE}/Godot_v${VERSION}-stable_${zipName}`, zip);
      await unzip(zip, TOOLS);
    } finally {
      await Deno.remove(zip).catch(() => {}); // never leave 170 MB behind
    }
  }
  // "_sc_" next to the binary means self-contained mode: editor settings and
  // export templates live in .tools/editor_data/, not your home directory.
  const binaryDir = godotPath().replace(/[^/\\]+$/, "");
  if (Deno.build.os === "darwin") {
    // On macOS, Godot looks for _sc_ beside Godot.app (linkForEditors writes it), and a
    // file inside the signed bundle would break Apple's signature seal, so remove any
    // copy an older setup left there.
    await Deno.remove(`${binaryDir}_sc_`).catch(() => {});
  } else {
    await Deno.writeTextFile(`${binaryDir}_sc_`, "");
  }
  await linkForEditors();
  const templates = `${TOOLS}editor_data/export_templates/${VERSION}.stable/`;
  const template = "web_nothreads_release.zip";
  try {
    await Deno.stat(templates + template);
    console.log("Web export template already present");
  } catch {
    console.log(`Fetching only templates/${template} from the export templates archive`);
    const tpz = `${RELEASE}/Godot_v${VERSION}-stable_export_templates.tpz`;
    await Deno.mkdir(templates, { recursive: true });
    await Deno.writeFile(templates + template, await extractRemoteEntry(tpz, `templates/${template}`));
  }
  console.log(`Ready: ${godotPath()}`);
  if (PLATFORM === "linux-aarch64") {
    console.log("Note: Blender's Python package has no ARM Linux build, so `deno task art` won't run here.");
    console.log("Godot tasks work; the committed art/*.glb files are enough, and a partner can regenerate them.");
  }
}

if (Deno.args[0] === "setup") {
  await setup();
} else {
  const args = Deno.args[0] === "--" ? Deno.args.slice(1) : Deno.args;
  Deno.exit(await run(args));
}
