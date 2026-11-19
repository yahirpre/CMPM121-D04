// Export the web build into dist/ (Godot won't create the folder itself).
await Deno.mkdir("dist", { recursive: true });
// .gdignore tells Godot not to import the build output back into the project.
await Deno.writeTextFile("dist/.gdignore", "");
const { code } = await new Deno.Command("deno", {
  args: ["run", "-A", "scripts/godot.ts", "--", "--headless", "--path", ".", "--export-release", "Web", "dist/index.html"],
}).spawn().status;
Deno.exit(code);
