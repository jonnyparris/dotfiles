// cmux-activity: publishes a rich, emoji-prefixed "what is Pi doing right now"
// label to the cmux workspace progress channel. The custom sidebar
// (~/.config/cmux/sidebars/pi-board.js) reads `progress.label` to render live
// activity, and treats "progress present" as the source of truth for "working".
//
// Label protocol (first glyph is the state marker the sidebar keys off):
//   ✨ …  brand-new session, no prompt sent yet (value 0)
//   🙋 …  waiting on the user (blocking UI prompt / ask_user_question)
//   ❌ …  last run errored (sticky until next prompt)
//   anything else = working
//
// Replaces pi-cmux's sidebar status/progress (disabled via PI_CMUX_SIDEBAR=0
// in ~/.zshenv) so there is exactly one writer.

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { basename } from "node:path";

// Best effort: if this loads before pi-cmux, it also disables pi-cmux's sidebar.
process.env.PI_CMUX_SIDEBAR = "0";

const TIMEOUT_MS = 1500;

function clip(text: string, max: number): string {
  const t = text.replace(/\s+/g, " ").trim();
  return t.length > max ? `${t.slice(0, max - 1)}…` : t;
}

function str(v: unknown): string | undefined {
  return typeof v === "string" && v.trim() ? v.trim() : undefined;
}

function describeTool(name: string, args: any): string {
  const a = args && typeof args === "object" ? args : {};
  const path = str(a.path) || str(a.file) || str(a.filePath);
  const file = path ? basename(path) : undefined;
  switch (name) {
    case "bash": {
      const cmd = str(a.command)?.split("\n")[0];
      return cmd ? `⚡ ${clip(cmd, 60)}` : "⚡ shell";
    }
    case "read":
      return `📖 ${file ?? "reading"}`;
    case "edit":
    case "write":
      return `✏️ ${file ?? "editing"}`;
    case "grep":
    case "find":
    case "ls":
      return `🔎 ${clip(str(a.pattern) || str(a.query) || file || name, 50)}`;
    case "mcp":
    case "mcpScript": {
      const tool = str(a.tool) || str(a.search) || str(a.describe) || str(a.server);
      return `🔌 ${clip(tool ?? "mcp", 50)}`;
    }
    case "ask_user_question":
      return "🙋 question for you";
    default:
      if (name.startsWith("mcp__")) {
        return `🔌 ${clip(str(a.tool) ?? name.replace(/^mcp__/, ""), 50)}`;
      }
      if (/subagent|task|team_spawn|dispatch/i.test(name)) return `🤖 ${clip(str(a.description) || "subagent", 50)}`;
      return `🔧 ${name}`;
  }
}

export default function cmuxActivity(pi: ExtensionAPI) {
  if (!process.env.CMUX_WORKSPACE_ID?.trim() || process.env.PI_CMUX_ACTIVITY === "0") return;

  // Coalescing single-flight writer: only the latest desired state is sent.
  type Desired = { kind: "set"; value: number; label: string } | { kind: "clear" };
  let desired: Desired | undefined;
  let lastSent = "";
  let inFlight = false;
  let dead = false;

  // Only interactive sessions own the workspace's progress channel. Headless
  // `pi -p` children (scripts, subagents) share CMUX_WORKSPACE_ID and would
  // otherwise stamp "✨ new session" over the parent's state.
  let interactive = false;

  const pump = async (): Promise<void> => {
    if (inFlight || dead || !interactive) return;
    inFlight = true;
    try {
      while (desired) {
        const d = desired;
        desired = undefined;
        const sig = d.kind === "clear" ? "clear" : `${d.value.toFixed(2)}|${d.label}`;
        if (sig === lastSent) continue;
        const args = d.kind === "clear"
          ? ["clear-progress"]
          : ["set-progress", d.value.toFixed(2), "--label", d.label];
        try {
          const r = await pi.exec("cmux", args, { timeout: TIMEOUT_MS });
          if (r.code === 0) lastSent = sig;
          else if (/ENOENT|not found|connect|socket/i.test(`${r.stderr}${r.stdout}`)) dead = true;
        } catch {
          dead = true;
        }
      }
    } finally {
      inFlight = false;
    }
  };

  let turns = 0;
  let tools = 0;
  let active = 0;
  let current = "💭 thinking";
  let waiting = 0;

  const progress = () => Math.min(0.92, 0.06 + turns * 0.1 + tools * 0.03);
  const set = (label: string) => {
    desired = { kind: "set", value: progress(), label };
    void pump();
  };
  const clear = () => {
    desired = { kind: "clear" };
    void pump();
  };
  const show = () => set(waiting > 0 ? "🙋 waiting for you" : current);

  const isFresh = (ctx: any): boolean => {
    try {
      const entries: any[] = ctx.sessionManager.getBranch() ?? [];
      return !entries.some((e) => e?.type === "message" && e.message?.role === "user");
    } catch {
      return false;
    }
  };
  let fresh = false;
  const markFresh = () => {
    fresh = true;
    desired = { kind: "set", value: 0, label: "✨ new session" };
    void pump();
  };

  pi.on("session_start", (_e, ctx) => {
    interactive = ctx.hasUI === true;
    turns = tools = active = waiting = 0;
    if (isFresh(ctx)) markFresh();
    else {
      fresh = false;
      clear();
    }
  });

  pi.on("agent_start", () => {
    fresh = false;
    if (turns === 0) tools = 0;
    current = "💭 thinking";
    show();
  });

  pi.on("turn_start", (e) => {
    turns = Math.max(turns, e.turnIndex + 1);
    if (active === 0) {
      current = "💭 thinking";
      show();
    }
  });

  pi.on("tool_execution_start", (e) => {
    active += 1;
    current = describeTool(e.toolName, e.args);
    show();
  });

  pi.on("tool_execution_end", () => {
    active = Math.max(0, active - 1);
    tools += 1;
    if (active === 0) {
      current = "💭 thinking";
      show();
    }
  });

  pi.on("ui_prompt_start", () => {
    waiting += 1;
    show();
  });

  pi.on("ui_prompt_end", () => {
    waiting = Math.max(0, waiting - 1);
    if (fresh && waiting === 0) markFresh();
    else show();
  });

  let lastEnd: { error?: string } = {};
  pi.on("agent_end", (e: any) => {
    const msgs: any[] = Array.isArray(e?.messages) ? e.messages : [];
    const last = [...msgs].reverse().find((m) => m?.role === "assistant");
    lastEnd = last?.stopReason === "error"
      ? { error: str(last.errorMessage) ?? "agent error" }
      : {};
  });

  pi.on("agent_settled", (_e, ctx) => {
    if (!ctx.isIdle()) return;
    turns = tools = active = waiting = 0;
    if (isFresh(ctx)) {
      // e.g. a slash command that never sent a user prompt
      markFresh();
    } else if (lastEnd.error) {
      desired = { kind: "set", value: 1, label: `❌ ${clip(lastEnd.error, 60)}` };
      void pump();
    } else {
      clear();
    }
  });

  pi.on("session_shutdown", async () => {
    desired = { kind: "clear" };
    await pump();
  });
}
