import { readFileSync, writeFileSync, mkdirSync, existsSync } from "node:fs";
import { join } from "node:path";
import { homedir } from "node:os";

export interface HookConfig {
  enabled: boolean;
  requiredFiles?: string[];
  protectedFiles?: string[];
  threshold?: number;
  interval?: number;
  lines?: string[];
}

export interface GuardConfig {
  version: string;
  scope: "global" | "project";
  installedAt: string;
  hooks: Record<string, HookConfig>;
}

const CONFIG_DIR = join(homedir(), ".claude-guard");
const CONFIG_FILE = join(CONFIG_DIR, "config.json");

export function getConfigDir(): string {
  return CONFIG_DIR;
}

export function getConfigPath(): string {
  return CONFIG_FILE;
}

export function readConfig(): GuardConfig | null {
  if (!existsSync(CONFIG_FILE)) return null;
  try {
    return JSON.parse(readFileSync(CONFIG_FILE, "utf-8"));
  } catch {
    return null;
  }
}

export function writeConfig(config: GuardConfig): void {
  mkdirSync(CONFIG_DIR, { recursive: true });
  writeFileSync(CONFIG_FILE, JSON.stringify(config, null, 2) + "\n");
}

export function getDefaultConfig(scope: "global" | "project"): GuardConfig {
  return {
    version: "1.0.0",
    scope,
    installedAt: new Date().toISOString(),
    hooks: {
      "agent-guard": {
        enabled: true,
        requiredFiles: ["CLAUDE.md"],
      },
      "config-protection": {
        enabled: true,
        protectedFiles: [
          ".eslintrc*", "eslint.config.*",
          ".prettierrc*", "prettier.config.*",
          "biome.json*",
          "tsconfig*.json",
          "vitest.config.*", "jest.config.*",
          "tailwind.config.*",
          "Dockerfile", "Dockerfile.*",
        ],
      },
      "audit-log": { enabled: true },
      "time-tracker": { enabled: true },
      "compact-suggester": {
        enabled: true,
        threshold: 50,
        interval: 25,
      },
      "session-reminder": {
        enabled: true,
        lines: [
          "Read CLAUDE.md before making changes",
          "Check existing code before creating new files",
        ],
      },
    },
  };
}

export const HOOK_DESCRIPTIONS: Record<string, { event: string; matcher: string; blocking: boolean; description: string }> = {
  "agent-guard": {
    event: "PreToolUse",
    matcher: "Agent",
    blocking: true,
    description: "Block sub-agents missing required context files",
  },
  "config-protection": {
    event: "PreToolUse",
    matcher: "Edit|Write",
    blocking: true,
    description: "Block modifications to linter/formatter/build configs",
  },
  "audit-log": {
    event: "PostToolUse",
    matcher: "Bash",
    blocking: false,
    description: "Log every bash command with automatic secret redaction",
  },
  "time-tracker": {
    event: "UserPromptSubmit",
    matcher: "",
    blocking: false,
    description: "JSONL time tracking per project and session",
  },
  "compact-suggester": {
    event: "PreToolUse",
    matcher: "Edit|Write",
    blocking: false,
    description: "Suggest /compact at strategic tool call intervals",
  },
  "session-reminder": {
    event: "UserPromptSubmit",
    matcher: "",
    blocking: false,
    description: "Inject critical context reminders every prompt",
  },
};

export const ALL_HOOKS = Object.keys(HOOK_DESCRIPTIONS);
