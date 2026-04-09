import pc from "picocolors";
import { readConfig, writeConfig, HOOK_DESCRIPTIONS, ALL_HOOKS } from "../config.js";
import { installHooks, patchSettings } from "../installer.js";

export async function addCommand(hookName: string, options: { global?: boolean }): Promise<void> {
  if (!ALL_HOOKS.includes(hookName)) {
    console.log(pc.red(`Unknown hook: ${hookName}`));
    console.log(`Available hooks: ${ALL_HOOKS.join(", ")}`);
    process.exit(1);
  }

  const config = readConfig();
  if (!config) {
    console.log(pc.yellow("claude-code-guard is not installed."));
    console.log(`Run ${pc.cyan("claude-code-guard init")} first.`);
    process.exit(1);
  }

  if (config.hooks[hookName]?.enabled) {
    console.log(pc.yellow(`Hook ${hookName} is already enabled.`));
    return;
  }

  config.hooks[hookName] = { enabled: true };
  writeConfig(config);
  installHooks(config);
  patchSettings(config);

  const meta = HOOK_DESCRIPTIONS[hookName];
  console.log(`${pc.green("✓")} Added ${hookName} — ${meta.description}`);
}
