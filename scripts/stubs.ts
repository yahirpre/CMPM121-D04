// deno task setup:stubs: Blender 5.2 Python stubs for editor completion, installed by uv.
// uv is new in D4, so when it is missing (or this terminal predates installing it),
// say exactly what to do instead of failing with "command not found".

const ARGS = [
  "pip",
  "install",
  "--quiet",
  "--python",
  "3.13",
  "--target",
  ".tools/python-stubs",
  "fake-bpy-module-5.2==20260730",
];

try {
  const { success } = await new Deno.Command("uv", { args: ARGS }).spawn()
    .status;
  Deno.exit(success ? 0 : 1);
} catch (e) {
  if (!(e instanceof Deno.errors.NotFound)) throw e;
  const install = Deno.build.os === "windows"
    ? 'powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"'
    : "curl -LsSf https://astral.sh/uv/install.sh | sh";
  console.error(`
Godot is ready, but uv was not found. D4 needs uv for Blender and the GDScript linter.

If you have not installed uv yet, install it with:

  ${install}

Then open a NEW terminal window (the old one cannot see uv yet) and run:

  deno task setup

More help: https://docs.astral.sh/uv/getting-started/installation/
`);
  Deno.exit(1);
}
