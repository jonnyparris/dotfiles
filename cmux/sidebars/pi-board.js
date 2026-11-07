// pi-board: workspace sidebar that makes Pi agent state obvious at a glance.
//
// Folders: ungrouped workspaces go in "Agents" at the top; cmux workspace
// groups (MR author, MR reviews, Work HQ, ...) render as collapsible folders
// with a per-folder state summary, so a collapsed folder still shows that
// something inside needs you.
//
// Every row answers:
//   1. What state is it in?   (glyph + colour bar + chip)
//   2. What is it about?      (latest prompt)
//   3. What is it doing now?  (live activity from ~/.pi/agent/extensions/cmux-activity.ts)
//
// States (loudest first):
//   🙋 NEEDS YOU  orange  blocked on your answer / approval
//   ❌ ERROR      red     last run failed
//   ◐  WORKING    blue    agent running (spinner, elapsed, current tool)
//   ✅ DONE       green   replied, you haven't looked yet
//   ✨ NEW        mint    brand-new blank session, nothing asked yet
//   💬 REPLIED    grey    replied earlier and you've seen it
//   ▫️            dim     no agent in this workspace
//
// Open: right-click the sidebar toggle → pi-board, or `cmux sidebar select pi-board`.

const S = {
  needs:   { glyph: "🙋", chip: "NEEDS YOU", color: "#FF9F0A", tint: "#FF9F0A22" },
  error:   { glyph: "❌", chip: "ERROR",     color: "#FF453A", tint: "#FF453A1f" },
  working: { glyph: "◐",  chip: "WORKING",   color: "#0A84FF", tint: "#0A84FF14" },
  done:    { glyph: "✅", chip: "DONE",      color: "#30D158", tint: "#30D1581a" },
  fresh:   { glyph: "✨", chip: "NEW",       color: "#63E6BE", tint: "#63E6BE14" },
  replied: { glyph: "💬", chip: "REPLIED",   color: "#8E8E93", tint: null },
  shell:   { glyph: "▫️", chip: "",          color: "#7f7f7f55", tint: null },
};
const SUMMARY_ORDER = ["needs", "error", "working", "done", "fresh"];
const SPIN = ["◐", "◓", "◑", "◒"];

const FOLDER_ICON = [
  [/author/i, "✍️"],
  [/review/i, "🔍"],
  [/work\s*hq/i, "🏠"],
  [/auto|nightly|cron/i, "🌙"],
];

const now = () => data.clock()?.epoch ?? 0;

function ago(epoch) {
  if (!epoch) return "";
  const s = Math.max(0, Math.floor(now() - epoch));
  if (s < 60) return s + "s";
  const m = Math.floor(s / 60);
  if (m < 60) return m + "m";
  const h = Math.floor(m / 60);
  if (h < 48) return h + "h";
  return Math.floor(h / 24) + "d";
}

function clip(t, n) {
  const s = String(t ?? "").replace(/\s+/g, " ").trim();
  return s.length > n ? s.slice(0, n - 1) + "…" : s;
}

function base(p) {
  const parts = String(p ?? "").split("/").filter(Boolean);
  return parts[parts.length - 1] ?? "";
}

const isPiTitle = (t) => /^π\s*[·\-]/.test(String(t ?? ""));

function agentOf(w) {
  return (w?.agents ?? []).find((a) => a.status !== "ended") ?? null;
}

function stateOf(w) {
  if (!w) return "shell";
  const a = agentOf(w);
  const label = w.progress?.label ?? "";
  const hasPi = !!a || isPiTitle(w.title) || (w.tabs ?? []).some((t) => isPiTitle(t.title));
  // Ignore a stale ✨ left behind if Pi exited without clearing it.
  if (label.startsWith("✨")) return hasPi ? "fresh" : "shell";
  if (label.startsWith("🙋") || a?.status === "needs_input") return "needs";
  if (label.startsWith("❌")) return "error";
  // cmux-activity owns "working" for Pi; trust native status for other agents.
  if (w.progress || (a && a.status === "working" && a.kind !== "pi")) return "working";
  if (!hasPi) return "shell";
  // cmux-activity marks blank sessions with ✨ explicitly, so without that
  // label assume the session has history. (Pi agent records carry no
  // `title`, so it can't be used to detect a first prompt.) Only fall back to
  // "fresh" when cmux has never seen a prompt or reply in this workspace.
  const hasHistory = !!(w.latestPrompt || w.latestMessage || a?.title);
  if (!hasHistory) return "fresh";
  if ((w.unread ?? 0) > 0) return "done";
  return "replied";
}

function nameOf(w) {
  if (!w) return "";
  if (!isPiTitle(w.title) && w.title && w.title !== base(w.directory)) return w.title;
  return base(w.directory) || w.title || "workspace";
}

function taskLine(w, st) {
  if (!w) return "";
  if (st === "fresh") return "Blank session, waiting for a first prompt";
  if (st === "shell") {
    const t = (w.tabs ?? []).find((x) => x.focused) ?? (w.tabs ?? [])[0];
    return clip(w.description || t?.title || "", 80);
  }
  const p = w.latestPrompt || agentOf(w)?.title || w.description || "";
  return p ? "› " + clip(p, 90) : "";
}

function activityLine(w, st) {
  if (!w) return "";
  const label = w.progress?.label ?? "";
  if (st === "working" || st === "error" || st === "needs") {
    if (label) return label;
    return st === "needs" ? "🙋 waiting for you" : "💭 working";
  }
  if (st === "done" || st === "replied") return w.latestMessage ? "↳ " + clip(w.latestMessage, 90) : "";
  return "";
}

function glyphOf(st) {
  if (st === "working") return SPIN[(data.clock()?.second ?? 0) % SPIN.length];
  return S[st].glyph;
}

function chipOf(w, st) {
  const a = agentOf(w);
  if (st === "working") return "WORKING " + ago(a?.sinceEpoch || w?.latestAt);
  if (st === "needs") return "NEEDS YOU " + ago(a?.sinceEpoch);
  if (st === "done" || st === "replied") return S[st].chip + " " + ago(a?.lastActivityAt || w?.latestAt);
  return S[st].chip;
}

const wsById = (id) => (data.workspaces() ?? []).find((w) => w.id === id);

function jumpTo(w) {
  if (!w) return;
  cmux("workspace.select", { workspace_id: w.id });
  const a = agentOf(w);
  if (a?.surfaceId) cmux("surface.focus", { surface_id: a.surfaceId, workspace_id: w.id });
}

// --- folders ----------------------------------------------------------------
const sections = computed(() => {
  const ws = data.workspaces() ?? [];
  const groups = data.groups() ?? [];
  const known = new Set(groups.map((g) => g.id));
  const out = [];
  const loose = ws.filter((w) => !w.group || !known.has(w.group));
  if (loose.length) {
    out.push({ id: "sec:agents", name: "Agents", icon: "π", groupId: null, anchorId: null, memberIds: loose.map((w) => w.id), rowIds: loose.map((w) => w.id) });
  }
  const idx = (g) => ws.find((w) => w.id === g.anchorId)?.index ?? 1e9;
  for (const g of [...groups].sort((a, b) => idx(a) - idx(b))) {
    const members = ws.filter((w) => w.group === g.id);
    const icon = g.icon || (FOLDER_ICON.find(([re]) => re.test(g.name)) ?? [null, "📁"])[1];
    out.push({
      id: "g:" + g.id, name: g.name, icon, color: g.color, groupId: g.id, anchorId: g.anchorId,
      memberIds: members.map((w) => w.id),
      rowIds: members.filter((w) => w.id !== g.anchorId).map((w) => w.id),
    });
  }
  return out;
});

// Collapse: native groups sync through cmux (optimistic override until the
// data catches up); the synthetic "Agents" folder keeps local state.
const collapseOverride = new Map();
const [collapseTick, setCollapseTick] = signal(0);

function isCollapsed(sec) {
  collapseTick();
  if (!sec.groupId) return !!collapseOverride.get(sec.id);
  const g = (data.groups() ?? []).find((x) => x.id === sec.groupId);
  const actual = !!g?.collapsed;
  if (collapseOverride.has(sec.id)) {
    const v = collapseOverride.get(sec.id);
    if (v === actual) collapseOverride.delete(sec.id);
    else return v;
  }
  return actual;
}

function toggleCollapse(sec) {
  const next = !isCollapsed(sec);
  collapseOverride.set(sec.id, next);
  setCollapseTick(collapseTick() + 1);
  if (sec.groupId) cmux(next ? "workspace.group.collapse" : "workspace.group.expand", { group_id: sec.groupId });
}

function countStates(ids) {
  const c = { needs: 0, error: 0, working: 0, done: 0, fresh: 0, replied: 0, shell: 0 };
  for (const id of ids) c[stateOf(wsById(id))] += 1;
  return c;
}

function firstIn(ids, st) {
  for (const id of ids) {
    const w = wsById(id);
    if (stateOf(w) === st) return w;
  }
  return null;
}

function miniChip(ids, st) {
  const m = S[st];
  const n = () => countStates(ids())[st];
  return Text(() => (n() ? m.glyph + " " + n() : ""))
    .font(10).weight("semibold").monospaced()
    .color(m.color)
    .paddingHorizontal(() => (n() ? 5 : 0))
    .paddingVertical(() => (n() ? 1 : 0))
    .background(() => (n() ? m.color + "22" : null))
    .cornerRadius(5)
    .onTap(() => jumpTo(firstIn(ids(), st)));
}

function folderHeader(sec) {
  const ids = () => sec().memberIds;
  const anchor = () => (sec().anchorId ? wsById(sec().anchorId) : null);
  return HStack({ spacing: 6 }, [
    Text("▶").font(8).color("tertiary")
      .rotation(() => (isCollapsed(sec()) ? 0 : 90))
      .frame({ width: 12 })
      .onTap(() => toggleCollapse(sec())),
    Text(() => sec().icon).font(12).frame({ width: 18 }),
    Text(() => sec().name).font(12).weight("bold")
      .color(() => sec().color || "primary")
      .lineLimit(1).truncation("tail"),
    Text(() => String(sec().rowIds.length)).font(10).monospaced().color("tertiary"),
    Spacer({ minLength: 0 }),
    ...SUMMARY_ORDER.map((st) => miniChip(ids, st)),
  ])
    .paddingHorizontal(6).paddingVertical(5)
    .cornerRadius(7)
    .background(() => (anchor()?.selected ? "#7f7f7f3d" : "#7f7f7f14"))
    .hoverBackground("#7f7f7f2a")
    .frame({ maxWidth: "infinity" })
    .onTap(() => (anchor() ? jumpTo(anchor()) : toggleCollapse(sec())));
}

// --- rows -------------------------------------------------------------------
function row(w) {
  const st = () => stateOf(w());
  const m = () => S[st()];
  const sel = () => !!w()?.selected;
  const unreadBadge = () => ((w()?.unread ?? 0) > 0 && st() !== "done" ? String(w().unread) : "");

  return HStack({ spacing: 0 }, [
    Rectangle().fill(() => m().color).frame({ width: 3 }).cornerRadius(2),
    VStack({ spacing: 2 }, [
      HStack({ spacing: 6 }, [
        Text(() => glyphOf(st()))
          .font(() => (st() === "working" ? 14 : 12))
          .weight("bold")
          .color(() => m().color)
          .frame({ width: 18 }),
        Text(() => nameOf(w()))
          .font(13)
          .weight(() => (st() === "needs" || st() === "done" || sel() ? "semibold" : "regular"))
          .color(() => (st() === "replied" || st() === "shell" ? "secondary" : "primary"))
          .lineLimit(1).truncation("tail").marquee(),
        Text(() => (w()?.branch && w().branch !== "main" && w().branch !== "master" ? "⎇ " + clip(w().branch, 22) : ""))
          .font(10).color("tertiary").lineLimit(1).truncation("middle"),
        Spacer({ minLength: 0 }),
        Text(() => chipOf(w(), st()))
          .font(9).weight("bold").monospaced()
          .color(() => m().color)
          .paddingHorizontal(() => (chipOf(w(), st()) ? 5 : 0))
          .paddingVertical(() => (chipOf(w(), st()) ? 1 : 0))
          .background(() => (chipOf(w(), st()) ? m().color + "22" : null))
          .cornerRadius(5),
        Text(unreadBadge)
          .font("caption2").bold().color("white")
          .paddingHorizontal(() => (unreadBadge() ? 5 : 0))
          .background(() => (unreadBadge() ? "#E4573D" : null))
          .cornerRadius(7),
      ]),
      Text(() => taskLine(w(), st()))
        .font(11)
        .color(() => (st() === "fresh" ? S.fresh.color : st() === "replied" ? "tertiary" : "secondary"))
        .lineLimit(1).truncation("tail")
        .paddingLeading(24),
      Text(() => activityLine(w(), st()))
        .font(11).monospaced()
        .color(() => (st() === "replied" ? "tertiary" : m().color))
        .lineLimit(1).truncation("tail")
        .paddingLeading(24),
    ])
      .paddingLeading(7).paddingTrailing(8).paddingVertical(5)
      .frame({ maxWidth: "infinity" }),
  ])
    .cornerRadius(8)
    .background(() => (sel() ? "#7f7f7f3d" : m().tint))
    .borderColor(() => (sel() ? "accent" : "clear"))
    .borderWidth(() => (sel() ? 1 : 0))
    .hoverBackground("#7f7f7f2a")
    .frame({ maxWidth: "infinity" })
    .onTap(() => jumpTo(w()))
    .contextMenu([
      Button(() => (w()?.pinned ? "Unpin" : "Pin"), () =>
        cmux("workspace.action", { action: w()?.pinned ? "unpin" : "pin", workspace_id: w().id })),
      Button(() => ((w()?.unread ?? 0) > 0 ? "Mark as Read" : "Mark as Unread"), () =>
        cmux("workspace.action", { action: (w()?.unread ?? 0) > 0 ? "mark_read" : "mark_unread", workspace_id: w().id })),
      Divider(),
      Menu("Move to Folder", (data.groups() ?? []).map((g) =>
        Button(g.name, () => cmux("workspace.group.add", { group_id: g.id, workspace_id: w().id })))),
      Button("Remove from Folder", () => cmux("workspace.group.remove", { workspace_id: w().id })),
      Divider(),
      Button("Close", () => cmux("workspace.close", { workspace_id: w().id })).destructive(),
    ]);
}

function section(sec) {
  return VStack({ spacing: 3 }, [
    folderHeader(sec),
    ForEach(
      {
        items: () => (isCollapsed(sec()) ? [] : sec().rowIds.map(wsById).filter(Boolean)),
        key: (w) => w.id,
      },
      (w) => row(w).paddingLeading(8)
    ),
  ]);
}

// --- global header ------------------------------------------------------------
const allIds = () => (data.workspaces() ?? []).map((w) => w.id);

sidebar(() =>
  VStack({ spacing: 8 }, [
    HStack({ spacing: 5 }, [
      Text("Pi board").font(13).weight("semibold"),
      Spacer({ minLength: 0 }),
      ...SUMMARY_ORDER.map((st) => miniChip(allIds, st)),
    ]).paddingHorizontal(6),
    Divider(),
    ForEach({ items: sections, key: (s) => s.id }, (sec) => section(sec)),
    Spacer(),
  ]).paddingHorizontal(6).paddingVertical(6),
  { surface: "glass" }
)
