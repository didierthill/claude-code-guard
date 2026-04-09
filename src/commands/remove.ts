import pc from "picocolors";
import { readConfig, writeConfig, ALL_HOOKS } from "../config.js";
import { removeHookFromSettings } from "../installer.js";
import { existsSync, unlinkSync } from "node:fs";
import { join } from "node:path";
import { homedir } from "node:os";

export async function removeCommand(hookName: string): Promise<void> {
  if (!ALL_HOOKS.includes(hookName)) {
    console.log(pc.red(`Unknown hook: ${hookName}`));
    console.log(`Available hooks: ${ALL_HOOKS.join(", ")}`);
    process.exit(1);
  }

  const config = readConfig();
  if (!config) {
    console.log(pc.yellow("claude-code-guard is not installed."));
    return;
  }

  // Disable in config
  if (config.hooks[hookName]) {
    config.hooks[hookName].enabled = false;
  }
  writeConfig(config);

  // Remove from settings.json
  removeHookFromSettings(hookName, config.scope);

  // Remove script file
  const hooksDir = config.scope === "global"
    ? join(homedir(), ".claude", "hooks", "claude-code-guard")
    : join(process.cwd(), ".claude", "hooks", "claude-code-guard");
  const scriptPath = join(hooksDir, `${hookName}.sh`);
  if (existsSync(scriptPath)) {
    unlinkSync(scriptPath);
  }

  console.log(`${pc.green("✓")} Removed ${hookName}`);
}
