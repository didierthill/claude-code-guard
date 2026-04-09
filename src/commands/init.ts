import * as p from "@clack/prompts";
import pc from "picocolors";
import { getDefaultConfig, writeConfig, ALL_HOOKS, HOOK_DESCRIPTIONS } from "../config.js";
import { installHooks, patchSettings } from "../installer.js";

export async function initCommand(options: { global?: boolean; project?: boolean }): Promise<void> {
  p.intro(pc.bgCyan(pc.black(" claude-code-guard ")));

  // Scope selection
  let scope: "global" | "project";
  if (options.global) {
    scope = "global";
  } else if (options.project) {
    scope = "project";
  } else {
    const scopeAnswer = await p.select({
      message: "Install scope:",
      options: [
        {
          value: "global",
          label: "Global (~/.claude/)",
          hint: "hooks active in all projects",
        },
        {
          value: "project",
          label: "Project (.claude/)",
          hint: "hooks active in this repo only",
        },
      ],
    });
    if (p.isCancel(scopeAnswer)) {
      p.cancel("Setup cancelled.");
      process.exit(0);
    }
    scope = scopeAnswer as "global" | "project";
  }

  // Hook selection
  const hookChoices = ALL_HOOKS.map((name) => ({
    value: name,
    label: `${name}${HOOK_DESCRIPTIONS[name].blocking ? pc.red(" (blocking)") : pc.dim(" (advisory)")}`,
    hint: HOOK_DESCRIPTIONS[name].description,
  }));

  const selectedHooks = await p.multiselect({
    message: "Which hooks to install?",
    options: hookChoices,
    initialValues: ALL_HOOKS,
    required: true,
  });

  if (p.isCancel(selectedHooks)) {
    p.cancel("Setup cancelled.");
    process.exit(0);
  }

  const config = getDefaultConfig(scope);

  // Disable unselected hooks
  for (const hookName of ALL_HOOKS) {
    if (!(selectedHooks as string[]).includes(hookName)) {
      config.hooks[hookName].enabled = false;
    }
  }

  // Agent guard config
  if (config.hooks["agent-guard"]?.enabled) {
    const filesInput = await p.text({
      message: "Agent Guard: which files must sub-agent prompts reference?",
      placeholder: "CLAUDE.md",
      defaultValue: "CLAUDE.md",
    });
    if (!p.isCancel(filesInput) && filesInput) {
      config.hooks["agent-guard"].requiredFiles = (filesInput as string)
        .split(",")
        .map((f) => f.trim())
        .filter(Boolean);
    }
  }

  // Session reminder config
  if (config.hooks["session-reminder"]?.enabled) {
    const linesInput = await p.text({
      message: "Session Reminder: context lines (comma-separated):",
      placeholder: "Read CLAUDE.md before making changes, Check existing code first",
      defaultValue: "Read CLAUDE.md before making changes, Check existing code first",
    });
    if (!p.isCancel(linesInput) && linesInput) {
      config.hooks["session-reminder"].lines = (linesInput as string)
        .split(",")
        .map((l) => l.trim())
        .filter(Boolean);
    }
  }

  // Install
  const s = p.spinner();

  s.start("Installing hooks...");
  const { installed, skipped } = installHooks(config);
  s.stop(`Installed ${installed.length} hooks`);

  s.start("Patching settings.json...");
  patchSettings(config);
  s.stop("settings.json updated");

  s.start("Saving configuration...");
  writeConfig(config);
  s.stop("Configuration saved");

  // Summary
  p.note(
    [
      `${pc.green("Scope:")} ${scope === "global" ? "~/.claude/" : ".claude/"}`,
      "",
      ...installed.map((h) => `${pc.green("✓")} ${h} — ${HOOK_DESCRIPTIONS[h].description}`),
      ...skipped.map((h) => `${pc.dim("○")} ${h} — skipped`),
      "",
      `Config: ${pc.dim("~/.claude-guard/config.json")}`,
    ].join("\n"),
    "Installed hooks"
  );

  p.outro(`Run ${pc.cyan("claude-code-guard status")} to verify.`);
}
