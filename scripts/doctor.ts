// deno task doctor: try every step on this computer and print a report to paste
// into Canvas. A failing step is useful information, not a failed activity.

const steps = ["setup", "import", "test", "build", "art"];

async function capture(cmd: string, args: string[]): Promise<{ ok: boolean; text: string; seconds: number }> {
  const start = performance.now();
  try {
    const out = await new Deno.Command(cmd, { args, stdout: "piped", stderr: "piped" }).output();
    const text = new TextDecoder().decode(out.stdout) + new TextDecoder().decode(out.stderr);
    return { ok: out.success, text, seconds: (performance.now() - start) / 1000 };
  } catch (e) {
    return { ok: false, text: `${cmd} not found (${e instanceof Error ? e.message : e})`, seconds: 0 };
  }
}

// The most informative line of a failure: the last one mentioning an error.
function lastError(text: string): string {
  const lines = text.split("\n").map((l) => l.replace(/\x1b\[[0-9;]*m/g, "").trim()).filter(Boolean);
  const hit = lines.findLast((l) => /^error:/i.test(l)) ??
    lines.findLast((l) => /error|fail|not found|denied|no matching/i.test(l)) ?? lines.at(-1) ?? "";
  return hit.slice(0, 160);
}

function firstLine(text: string): string {
  return text.trim().split("\n")[0] ?? "";
}

const report: string[] = [];
const row = (name: string, value: string) => report.push(`${name.padEnd(10)} ${value}`);

row("platform", `${Deno.build.os}-${Deno.build.arch} (${Deno.osRelease()})`);
row("deno", Deno.version.deno);
const uv = await capture("uv", ["--version"]);
row("uv", uv.ok ? firstLine(uv.text) : "MISSING");

for (const step of steps) {
  console.log(`doctor: running deno task ${step} ...`);
  const result = await capture("deno", ["task", step]);
  const time = `${result.seconds.toFixed(1)}s`.padStart(7);
  row(step, result.ok ? `ok   ${time}` : `FAIL ${time}  ${lastError(result.text)}`);
  if (!result.ok && /DLL load failed/.test(result.text)) {
    // Blender's Python package needs the Microsoft Visual C++ runtime on Windows.
    row("", "fix: winget install Microsoft.VCRedist.2015+.x64, then rerun");
  }
  if (step === "setup") {
    const godot = await capture("deno", ["run", "-A", "scripts/godot.ts", "--", "--version"]);
    row("godot", godot.ok ? firstLine(godot.text) : "MISSING");
  }
}

console.log("\n----- D4 doctor report: paste everything between the lines -----");
console.log(report.join("\n"));
console.log("------------------------------------------------------------------");
console.log("Not checked here: `deno task dev` (native window) and `deno task preview` (browser).");
