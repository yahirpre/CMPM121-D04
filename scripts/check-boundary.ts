// deno task boundary: core/ must run with no scene tree, no window, and no input,
// which is what lets `deno task test` drive it headless. The same gate as D3's, for
// GDScript. It reads text rather than asking Godot, which is simple and strict:
//
// 1. Every core/ script extends RefCounted, Object, Resource, or another core/ class.
// 2. No core/ script names the scene tree, nodes, input, or the screen (the words in
//    ENGINE_ONLY below), or reaches for a node with `$Name`.
//
// Comments and string literals are ignored. Reading and writing files (FileAccess)
// is allowed: levels and replays are data, and tests can load them headless.

const CORE = "core";
const ALLOWED_BASES = new Set(["RefCounted", "Object", "Resource"]);
const ENGINE_ONLY = [
  "Node",
  "Node2D",
  "Node3D",
  "Control",
  "CanvasItem",
  "SceneTree",
  "PackedScene",
  "get_tree",
  "get_node",
  "get_viewport",
  "Input",
  "InputEvent",
  "DisplayServer",
  "RenderingServer",
  "AudioServer",
];
const ENGINE_WORD = new RegExp(`\\b(${ENGINE_ONLY.join("|")})\\b`);
const NODE_PATH = /\$["A-Za-z_]/;

async function scriptsIn(dir: string): Promise<string[]> {
  const files: string[] = [];
  for await (const entry of Deno.readDir(dir)) {
    const path = `${dir}/${entry.name}`;
    if (entry.isDirectory) files.push(...await scriptsIn(path));
    else if (entry.name.endsWith(".gd")) files.push(path);
  }
  return files.sort();
}

// Drop string literals, then comments, so "Input" in a message or a note is fine.
function codeOnly(line: string): string {
  return line.replace(/"(\\.|[^"\\])*"|'(\\.|[^'\\])*'/g, '""').replace(/#.*/, "");
}

const files = await scriptsIn(CORE);
const lines = new Map<string, string[]>();
const coreClasses = new Set<string>();
for (const file of files) {
  const text = (await Deno.readTextFile(file)).split("\n").map(codeOnly);
  lines.set(file, text);
  for (const line of text) {
    const name = line.match(/^class_name\s+(\w+)/)?.[1];
    if (name) coreClasses.add(name);
  }
}

const violations: string[] = [];
for (const [file, text] of lines) {
  text.forEach((line, i) => {
    const where = `${file}:${i + 1}`;
    const base = line.match(/^extends\s+(\w+)/)?.[1];
    if (base && !ALLOWED_BASES.has(base) && !coreClasses.has(base)) {
      violations.push(`${where} extends ${base}, which is not RefCounted or a core/ class`);
    }
    const word = line.replace(/^extends\s+\w+/, "").match(ENGINE_WORD)?.[1];
    if (word) violations.push(`${where} uses ${word}, which belongs to the engine side`);
    if (NODE_PATH.test(line)) violations.push(`${where} reaches for a node with $`);
  });
}

if (violations.length > 0) {
  console.error("Boundary check failed: core/ must not depend on the scene tree, input, or the screen.\n");
  for (const violation of violations) console.error(`  ${violation}`);
  console.error(`
The core has to run headless, with no window and no scene, which is what lets
deno task test check a rule in a second. Move this into app/, and have the core
report what happened (a signal, or state that app/ reads) so app/ can show it.`);
  Deno.exit(1);
}
console.log(`Boundary check passed: ${files.length} scripts in core/.`);
