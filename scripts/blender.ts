// Open the kit in the Blender app, the way `deno task edit` opens Godot's editor.
//
//   deno task blender                      open art/dragon_kit.blend (made by deno task art)
//   deno task blender art/my_kit.blend     open another .blend, such as a hand-edited copy
//   deno task blender <file> <blender args>   anything after the file goes to Blender
//
// `deno task art` uses Blender's Python package (bpy), which has no window, so this
// needs the Blender app itself. Set BLENDER=/path/to/blender to use a specific one.

import { fromFileUrl } from "jsr:@std/path@1";

const VERSION = "5.2"; // keep in step with bpy in tools/build_art.py
const DEFAULT = fromFileUrl(new URL("../art/dragon_kit.blend", import.meta.url));

// Where each OS's installer puts Blender. On Windows the folder name carries the
// version ("Blender 5.2"), so we list them all and take the newest.
async function candidates(): Promise<string[]> {
  const found: string[] = [];
  const home = Deno.env.get("HOME") ?? "";
  if (Deno.build.os === "darwin") {
    found.push("/Applications/Blender.app/Contents/MacOS/Blender");
    found.push(`${home}/Applications/Blender.app/Contents/MacOS/Blender`);
  }
  if (Deno.build.os === "windows") {
    const programFiles = Deno.env.get("ProgramFiles") ?? "C:\\Program Files";
    const foundation = `${programFiles}\\Blender Foundation`;
    const versions: string[] = [];
    try {
      for await (const entry of Deno.readDir(foundation)) versions.push(entry.name);
    } catch { /* not installed this way */ }
    versions.sort((a, b) => b.localeCompare(a, undefined, { numeric: true }));
    found.push(...versions.map((v) => `${foundation}\\${v}\\blender.exe`));
    const steam = Deno.env.get("ProgramFiles(x86)");
    if (steam) found.push(`${steam}\\Steam\\steamapps\\common\\Blender\\blender.exe`);
  }
  // Linux packages (apt, snap) and some manual installs put `blender` on PATH.
  const exe = Deno.build.os === "windows" ? "blender.exe" : "blender";
  const separator = Deno.build.os === "windows" ? ";" : ":";
  for (const dir of (Deno.env.get("PATH") ?? "").split(separator)) {
    if (dir) found.push(`${dir}/${exe}`);
  }
  return found;
}

async function exists(path: string): Promise<boolean> {
  try {
    return (await Deno.stat(path)).isFile;
  } catch {
    return false;
  }
}

async function blenderPath(): Promise<string | undefined> {
  const custom = Deno.env.get("BLENDER");
  if (custom) {
    if (await exists(custom)) return custom;
    console.error(`blender.ts: BLENDER=${custom} is not a file.`);
    return undefined;
  }
  for (const path of await candidates()) {
    if (await exists(path)) return path;
  }
}

const blender = await blenderPath();
if (!blender) {
  console.error(`blender.ts: no Blender app found. Install Blender ${VERSION} from`);
  console.error("https://www.blender.org/download/ (on an Intel Mac, 4.5 LTS, to match deno task art:lts),");
  console.error("or set BLENDER=/path/to/blender if it lives somewhere else.");
  console.error("You do not need it for the game: deno task art and the .glb are enough.");
  Deno.exit(1);
}

const args = [...Deno.args];
if (!args[0]?.endsWith(".blend")) args.unshift(DEFAULT);
if (!(await exists(args[0]))) {
  console.error(`blender.ts: ${args[0]} does not exist yet; run deno task art first.`);
  Deno.exit(1);
}
console.log(`Opening ${args[0]} with ${blender}`);
const { code } = await new Deno.Command(blender, { args }).spawn().status;
Deno.exit(code);
