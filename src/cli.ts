#!/usr/bin/env node
import { Command } from "commander";
import { initCommand } from "./commands/init.js";
import { statusCommand } from "./commands/status.js";
import { addCommand } from "./commands/add.js";
import { removeCommand } from "./commands/remove.js";

const program = new Command();

program
  .name("claude-code-guard")
  .description("Governance hooks for Claude Code — guardrails that prevent AI agent mistakes.")
  .version("1.0.0");

program
  .command("init")
  .description("Interactive setup — choose hooks, configure, and install")
  .option("--global", "Install hooks globally (~/.claude/)")
  .option("--project", "Install hooks for current project (.claude/)")
  .action(initCommand);

program
  .command("status")
  .description("Show installed hooks and their status")
  .action(statusCommand);

program
  .command("add <hook>")
  .description("Add a specific hook (agent-guard, config-protection, audit-log, time-tracker, compact-suggester, session-reminder)")
  .option("--global", "Install globally")
  .action(addCommand);

program
  .command("remove <hook>")
  .description("Remove a specific hook")
  .action(removeCommand);

program.parse();
