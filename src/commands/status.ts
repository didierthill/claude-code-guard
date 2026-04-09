import pc from "picocolors";
import { readConfig, HOOK_DESCRIPTIONS, ALL_HOOKS } from "../config.js";
import { existsSync, statSync } from "node:fs";
import { join } from "node:path";
import { homedir } from "node:os";

export async function statusCommand(): Promise<void> {
  const config = readConfig();

  if (!config) {
    console.log(pc.yellow("claude-code-guard is not installed."));
    console.log(`Run ${pc.cyan("claude-code-guard init")} to get started.`);
    return;
  }

  const hooksDir = config.scope === "global"
    ? join(homedir(), ".claude", "hooks", "claude-code-guard")
    : join(process.cwd(), ".claude", "hooks", "claude-code-guard");

  console.log(pc.bold("\nclaude-code-guard status\n"));
  console.log(`  Scope:       ${pc.cyan(config.scope)}`);
  console.log(`  Installed:   ${pc.dim(config.installedAt)}`);
  console.log(`  Version:     ${config.version}\n`);

  console.log(pc.bold("  Hooks:\n"));

  for (const hookName of ALL_HOOKS) {
    const hookConfig = config.hooks[hookName];
    const meta = HOOK_DESCRIPTIONS[hookName];
    const scriptExists = existsSync(join(hooksDir, `${hookName}.sh`));

    if (!hookConfig?.enabled) {
      console.log(`  ${pc.dim("○")} ${pc.dim(hookName)} — disabled`);
      continue;
    }

    if (!scriptExists) {
      console.log(`  ${pc.red("✗")} ${hookName} — ${pc.red("script missing!")}`);
      continue;
    }

    const size = statSync(join(hooksDir, `${hookName}.sh`)).size;
    const blocking = meta.blocking ? pc.red("blocking") : pc.green("advisory");
    console.log(`  ${pc.green("✓")} ${hookName} — ${meta.description} [${blocking}] ${pc.dim(`(${size}B)`)}`);
  }

  // Audit log stats
  const auditLog = join(homedir(), ".claude", "bash-audit.log");
  if (existsSync(auditLog)) {
    const size = statSync(auditLog).size;
    const sizeStr = size > 1024 * 1024
      ? `${(size / 1024 / 1024).toFixed(1)}MB`
      : `${(size / 1024).toFixed(1)}KB`;
    console.log(`\n  ${pc.bold("Audit log:")} ${auditLog} ${pc.dim(`(${sizeStr})`)}`);
  }

  // Time tracking stats
  const timeLog = join(homedir(), ".claude", "time-tracking.jsonl");
  if (existsSync(timeLog)) {
    const size = statSync(timeLog).size;
    const sizeStr = size > 1024 * 1024
      ? `${(size / 1024 / 1024).toFixed(1)}MB`
      : `${(size / 1024).toFixed(1)}KB`;
    console.log(`  ${pc.bold("Time log:")}  ${timeLog} ${pc.dim(`(${sizeStr})`)}`);
  }

  console.log();
}
