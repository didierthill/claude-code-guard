import { copyFileSync, mkdirSync, chmodSync, readFileSync, writeFileSync, existsSync } from "node:fs";
import { join, dirname } from "node:path";
import { homedir } from "node:os";
import { fileURLToPath } from "node:url";
import { HOOK_DESCRIPTIONS, type GuardConfig } from "./config.js";

const __dirname = dirname(fileURLToPath(import.meta.url));

function getHooksSourceDir(): string {
  // In the npm package, hooks are at ../hooks/ relative to dist/
  const fromDist = join(__dirname, "..", "hooks");
  if (existsSync(fromDist)) return fromDist;
  // Dev: hooks are at ../hooks/ relative to src/
  return join(__dirname, "..", "hooks");
}

function getHooksTargetDir(scope: "global" | "project"): string {
  if (scope === "global") {
    return join(homedir(), ".claude", "hooks", "claude-code-guard");
  }
  return join(process.cwd(), ".claude", "hooks", "claude-code-guard");
}

function getSettingsPath(scope: "global" | "project"): string {
  if (scope === "global") {
    return join(homedir(), ".claude", "settings.json");
  }
  return join(process.cwd(), ".claude", "settings.json");
}

export function installHooks(config: GuardConfig): { installed: string[]; skipped: string[] } {
  const sourceDir = getHooksSourceDir();
  const targetDir = getHooksTargetDir(config.scope);
  const installed: string[] = [];
  const skipped: string[] = [];

  mkdirSync(targetDir, { recursive: true });

  for (const [hookName, hookConfig] of Object.entries(config.hooks)) {
    if (!hookConfig.enabled) {
      skipped.push(hookName);
      continue;
    }

    const sourceFile = join(sourceDir, `${hookName}.sh`);
    const targetFile = join(targetDir, `${hookName}.sh`);

    if (!existsSync(sourceFile)) {
      skipped.push(hookName);
      continue;
    }

    copyFileSync(sourceFile, targetFile);
    chmodSync(targetFile, 0o755);
    installed.push(hookName);
  }

  return { installed, skipped };
}

export function patchSettings(config: GuardConfig): void {
  const settingsPath = getSettingsPath(config.scope);
  const targetDir = getHooksTargetDir(config.scope);

  // Read existing settings
  let settings: Record<string, unknown> = {};
  if (existsSync(settingsPath)) {
    try {
      settings = JSON.parse(readFileSync(settingsPath, "utf-8"));
    } catch {
      settings = {};
    }
  } else {
    mkdirSync(dirname(settingsPath), { recursive: true });
  }

  // Ensure hooks object exists
  if (!settings.hooks || typeof settings.hooks !== "object") {
    settings.hooks = {};
  }
  const hooks = settings.hooks as Record<string, unknown[]>;

  // Remove any existing claude-code-guard entries (for clean re-install)
  for (const event of Object.keys(hooks)) {
    if (Array.isArray(hooks[event])) {
      hooks[event] = hooks[event].filter((entry: unknown) => {
        const e = entry as Record<string, unknown>;
        const hooksList = e.hooks as Array<Record<string, string>> | undefined;
        if (!hooksList) return true;
        return !hooksList.some((h) => h.command?.includes("claude-code-guard"));
      });
    }
  }

  // Add new entries for enabled hooks
  for (const [hookName, hookConfig] of Object.entries(config.hooks)) {
    if (!hookConfig.enabled) continue;

    const meta = HOOK_DESCRIPTIONS[hookName];
    if (!meta) continue;

    const event = meta.event;
    if (!hooks[event]) hooks[event] = [];

    const scriptPath = join(targetDir, `${hookName}.sh`);
    const entry: Record<string, unknown> = {
      matcher: meta.matcher,
      hooks: [
        {
          type: "command",
          command: `bash ${scriptPath}`,
        },
      ],
    };

    hooks[event].push(entry);
  }

  settings.hooks = hooks;
  writeFileSync(settingsPath, JSON.stringify(settings, null, 2) + "\n");
}

export function removeHookFromSettings(hookName: string, scope: "global" | "project"): boolean {
  const settingsPath = getSettingsPath(scope);
  if (!existsSync(settingsPath)) return false;

  try {
    const settings = JSON.parse(readFileSync(settingsPath, "utf-8"));
    const hooks = settings.hooks || {};
    let removed = false;

    for (const event of Object.keys(hooks)) {
      if (!Array.isArray(hooks[event])) continue;
      const before = hooks[event].length;
      hooks[event] = hooks[event].filter((entry: Record<string, unknown>) => {
        const hooksList = entry.hooks as Array<Record<string, string>> | undefined;
        if (!hooksList) return true;
        return !hooksList.some((h) => h.command?.includes(`claude-code-guard/${hookName}.sh`));
      });
      if (hooks[event].length < before) removed = true;
      if (hooks[event].length === 0) delete hooks[event];
    }

    settings.hooks = hooks;
    writeFileSync(settingsPath, JSON.stringify(settings, null, 2) + "\n");
    return removed;
  } catch {
    return false;
  }
}
