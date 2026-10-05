# AutoZoom 2.0 — Appearances and Offset Preset Pick Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give every layout cell a tinted fill from AutoZoom appearances (instead of the macro's "paper" look) and add an Offset header cell that picks the XYZ offset preset by tapping it in a pool.

**Architecture:** Pure view model decides each cell's appearance *kind*; the console layer owns the Appearances-pool objects and writes `el.Appearance` only on change. The preset pick is a runtime state machine (like Capture) polled by the update loop; the console exposes `lastCommand()`, `topUndoName()` and `undoProgrammer()` through the Desk.

**Tech Stack:** TypeScript → Lua (TypeScriptToLua), Lua tests (`tests/run.lua`, fake desk, grandMA3 mock).

**Spec:** `docs/superpowers/specs/2026-10-03-autozoom-layout-ux-design.md` §15 (addendum). Console facts: `docs/superpowers/specs/2026-10-03-probe-2-results.md`.

## Global Constraints

- Every `src` file starts with `/** @noSelfInFile */`; tstl `noImplicitSelf` is never enabled.
- Only `src/console/` calls the grandMA3 API. Collections are iterated with `Children()`; the one exception is `CmdObj().Undos[UndoIndex + 1]` (the console's own undo indexing, used by FXMAker 2.5), typed `any`.
- Appearance names/colours exactly as spec §15.1; they live in `ShowData().Appearances`, found by name, created with `Acquire()`, `IMAGERGBA` reapplied on every install.
- Layout writes happen only when a cell's text, colour or appearance kind changed.
- Public commands are PascalCase methods on `AutoZoom`; every public command starts with `if (!this.ensureCurrent()) return;`.
- `npm test` passes after each task (`nix shell nixpkgs#nodejs_22 nixpkgs#lua5_4 -c sh -c 'npm test'`; it also rebuilds `out/`, which is committed with each task).
- Commit messages have no attribution lines.

## Review Focus

1. **Appearance deleted by the operator while running** → next refresh doesn't crash; Rescan recreates it. Test in Task 1 (`deleted appearance is skipped and recreated on install`).
2. **Pick sees an unrelated command first (e.g. `Go+ Sequence 3`)** → keeps waiting, nothing undone. Test in Task 2 (`unrelated command keeps the pick waiting`).
3. **Undo entry doesn't match the preset command** → no Oops, preset still picked. Test in Task 2 (`no Oops when the undo entry is something else`).
4. **Command text with Lua pattern characters (`.`, `-`)** → plain comparison, no false match. Test in Task 2 (`undo match is plain text`).
5. **Pick during a show change (instance not current)** → refused with the standard message. Covered by the `ensureCurrent()` guard; test in Task 2 (`pick refused when not current`).

---

### Task 1: Layout appearances

**Files:**
- Modify: `src/model.ts` (CellView), `src/ui/view-model.ts`, `src/console/layout.ts`, `src/console/ma-desk.ts`, `tests/lib/ma3mock.lua`, `tests/view_model_test.lua`, `tests/console_desk_test.lua`
- Create: `src/console/appearances.ts`

**Interfaces:**
- Produces:
  - `src/model.ts`: `export type AppearanceKind = "tracking" | "warn" | "nopsn" | "error" | "programmer" | "capture" | "button" | "header" | "idle";` and `CellView` gains `appearance: AppearanceKind` (keep `text`, `border`, `textColor`).
  - `src/ui/view-model.ts`: `export const APPEARANCES: { [kind: string]: { name: string; rgba: string } }` with exactly the spec §15.1 table (kind → `{ name: "AZ Tracking", rgba: "137A38E0" }`, …).
  - `src/console/appearances.ts`: `ensureAppearances(): void` (create/repair all of `APPEARANCES`), `appearanceHandle(kind: string): any` (cached handle, re-found by name if invalid, `undefined` if missing — never creates).

- [ ] **Step 1: Failing tests**

`tests/view_model_test.lua` — add:

```lua
T.test("cells carry appearance kinds", function()
  local v = az().view
  local header = { running = true, liveMarkers = 1, globalSize = 2, offsetLabel = "0/0/0 m", message = "hi" }
  local row = { fixture = fx(101), armed = true, markerCid = 1, programmerCid = 2, offset = { x = 0, y = 0, z = 0 },
    result = { state = "too-wide", output = { kind = "set", zoom = 100, iris = 100 }, distance = 5, achieved = 4, zoom = 100, iris = 100 },
    size = 2, sizeFixed = false }
  local views = v.buildViews(header, { row }, MARKERS, { ["1"] = { pos = { x = 0, y = 0, z = 0 } } })
  T.eq(views["status"].appearance, "tracking", "status running")
  T.eq(views["toggle"].appearance, "button", "button")
  T.eq(views["size"].appearance, "header", "size value")
  T.eq(views["message"].appearance, "header", "message")
  T.eq(views["mh 1"].appearance, "tracking", "live marker head")
  T.eq(views["mh 2"].appearance, "nopsn", "marker head without PSN")
  T.eq(views["arm 101"].appearance, "tracking", "armed")
  T.eq(views["mx 101 1"].appearance, "tracking", "followed (too-wide counts as driven)")
  T.eq(views["mx 101 2"].appearance, "programmer", "programmer cell")
  T.eq(views["st 101"].appearance, "warn", "too wide")
  T.eq(views["zo 101"].appearance, "idle", "value cell")
  T.eq(views["sz 101"].appearance, "button", "size cell is tappable")
  T.eq(v.APPEARANCES.tracking, { name = "AZ Tracking", rgba = "137A38E0" }, "palette")
end)
```

`tests/lib/ma3mock.lua` — add an Appearances pool to the mock: in `M.reset()` add `M.appearances = handle({}, {})` and give it `Find(name)` (returns the child with that name or nil) and `Acquire()` (appends and returns a new `handle({ name = "" }, {})`); `ShowData()` returns `{ DataPools = M.dataPools, PSNProtocol = M.psn, Appearances = M.appearances }`. In the reset's invalidation block also mark previous appearances `_deleted = true`.

`tests/console_desk_test.lua` — add:

```lua
T.test("install creates the AutoZoom appearances once with their colours", function()
  M.reset()
  local desk = az().madesk.createMaDesk()
  desk:install({ fixtures = {}, markers = {}, problems = {} })
  local byName = {}
  for _, a in ipairs(M.appearances._kids) do byName[a.name] = a end
  T.eq(byName["AZ Tracking"].IMAGERGBA, "137A38E0", "tracking colour")
  T.eq(byName["AZ Idle"].IMAGERGBA, "10121CD9", "idle colour")
  local n = #M.appearances._kids
  T.eq(n, 9, "nine appearances")
  byName["AZ Tracking"].IMAGERGBA = "FFFFFFFF"
  desk:install({ fixtures = {}, markers = {}, problems = {} })
  T.eq(#M.appearances._kids, n, "no duplicates"); T.eq(byName["AZ Tracking"].IMAGERGBA, "137A38E0", "colour reapplied")
end)

T.test("layout elements hide object details and get the cell appearance", function()
  M.reset()
  local desk = az().madesk.createMaDesk()
  desk:install({ fixtures = {}, markers = {}, problems = {} })
  desk:buildLayout({ { key = "toggle", x = 0, y = 0, w = 100, h = 60, command = "Toggle()" } })
  local el = M.dataPools._kids[1].Layouts._kids[1]._kids[1]
  T.eq(el.VisibilityIcon, false, "icon hidden"); T.eq(el.VisibilityObjectName, false, "name hidden")
  T.eq(el.VisibilityBorder, false, "no border"); T.eq(el.VisibilityValue, false, "no value")
  desk:refreshLayout({ toggle = { text = "Stop", border = "3ECF6EFF", textColor = "E6E8EBFF", appearance = "button" } })
  T.eq(el.Appearance.name, "AZ Button", "button appearance")
  el.Appearance = "tampered"
  desk:refreshLayout({ toggle = { text = "Stop", border = "3ECF6EFF", textColor = "E6E8EBFF", appearance = "button" } })
  T.eq(el.Appearance, "tampered", "unchanged view not rewritten")
  desk:refreshLayout({ toggle = { text = "Stop", border = "3ECF6EFF", textColor = "E6E8EBFF", appearance = "error" } })
  T.eq(el.Appearance.name, "AZ Error", "appearance switched")
end)

T.test("deleted appearance is skipped and recreated on install", function()
  M.reset()
  local desk = az().madesk.createMaDesk()
  desk:install({ fixtures = {}, markers = {}, problems = {} })
  desk:buildLayout({ { key = "toggle", x = 0, y = 0, w = 100, h = 60, command = "Toggle()" } })
  for i, a in ipairs(M.appearances._kids) do if a.name == "AZ Button" then a._deleted = true; table.remove(M.appearances._kids, i) break end end
  desk:refreshLayout({ toggle = { text = "Stop", border = "3ECF6EFF", textColor = "E6E8EBFF", appearance = "button" } })
  desk:install({ fixtures = {}, markers = {}, problems = {} })
  local found = false
  for _, a in ipairs(M.appearances._kids) do if a.name == "AZ Button" then found = true end end
  T.truthy(found, "recreated")
end)
```

Update the existing `refreshLayout` calls in `tests/console_desk_test.lua` to include `appearance = "button"` in each view (views must carry the field now).

- [ ] **Step 2: Run to verify they fail**

Run: `nix shell nixpkgs#nodejs_22 nixpkgs#lua5_4 -c sh -c 'npm run build:test && lua tests/run.lua'`
Expected: FAIL — `appearance` nil / `APPEARANCES` nil / `M.appearances` nil.

- [ ] **Step 3: Implement**

`src/model.ts`: add `AppearanceKind` and the `appearance` field as specified.

`src/ui/view-model.ts`:
- Add `APPEARANCES` (spec §15.1 table, exact names and RGBA).
- Change the local `cell` helper to `cell(key, text, appearance: AppearanceKind, border = COLORS.idle, textColor = COLORS.text)` and pass a kind for every cell:
  - `status`: running → `"tracking"`, else `"error"`.
  - `toggle`, `setup`, `armall`, `disarmall`: `"button"`; `capture`: `"capture"` while `captureSecondsLeft !== undefined`, else `"button"`.
  - `size`, `message`: `"header"`.
  - `mh <cid>`: live → `"tracking"`, else `"nopsn"`.
  - `arm <fid>`: armed → `"tracking"`, else `"idle"`.
  - `mx`: programmer → `"programmer"`; followed and state tracking/too-wide/too-small → `"tracking"`; followed and no-psn → `"nopsn"`; otherwise `"idle"`.
  - `st`: tracking → `"tracking"`; too-wide/too-small → `"warn"`; no-psn → `"nopsn"`; unknown-marker → `"error"`; else `"idle"`.
  - `di`, `zo`, `ir`: `"idle"`; `sz`: `"button"`.
- Keep the existing texts and border/text colours unchanged.

`src/console/appearances.ts`:

```ts
/** @noSelfInFile */
import { APPEARANCES } from "../ui/view-model";
import { children } from "./handles";

const cache: { [kind: string]: any } = {};

function pool(): any {
    return ShowData().Appearances;
}

function findByName(name: string): any {
    for (const a of children(pool())) if (a.name === name) return a;
    return undefined;
}

// Creates missing AutoZoom appearances and reapplies their colours (operator edits are reset on install).
export function ensureAppearances(): void {
    for (const kind in APPEARANCES) {
        const spec = APPEARANCES[kind];
        let app = findByName(spec.name);
        if (app === undefined) {
            app = pool().Acquire();
            app.Name = spec.name;
        }
        if (app.IMAGERGBA !== spec.rgba) app.IMAGERGBA = spec.rgba;
        cache[kind] = app;
    }
}

// Never creates: a deleted appearance returns undefined until the next install.
export function appearanceHandle(kind: string): any {
    const cached = cache[kind];
    if (cached !== undefined && IsObjectValid(cached)) return cached;
    const spec = APPEARANCES[kind];
    const app = spec === undefined ? undefined : findByName(spec.name);
    cache[kind] = app;
    return app;
}
```

If `ShowData().Appearances` is not typed by grandma3-ts-types, access it through `(ShowData() as any).Appearances`. The mock's `Acquire()` returns a handle whose `name` is set by `app.Name = …` — make the mock handle map `Name` to `name` (set both in `Acquire`'s returned table via a `__newindex` metatable, or simply have the test read `a.Name or a.name`; prefer the metatable so `findByName` works on the next install).

`src/console/layout.ts`:
- In `buildLayout`, replace the three string visibility assignments with booleans, as BeatGrid does:
  ```ts
  el.VisibilityObjectName = false;
  el.VisibilityIcon = false;
  el.VisibilityID = false;
  el.VisibilityCID = false;
  el.VisibilityValue = false;
  el.VisibilityBar = false;
  el.VisibilityBorder = false;
  el.BorderSize = 0;
  ```
- In `refreshLayout`, include the appearance kind in the signature (`${view.text}|${view.border}|${view.textColor}|${view.appearance}`) and, when writing, set `el.Appearance = appearanceHandle(view.appearance)` only if the handle is not `undefined` (a deleted appearance is skipped silently).

`src/console/ma-desk.ts`: `install()` calls `ensureAppearances()` (after `ensurePool()`).

- [ ] **Step 4: Run tests**

Run: `nix shell nixpkgs#nodejs_22 nixpkgs#lua5_4 -c sh -c 'npm test'`
Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add src tests out
git commit -m "Layout cells get AutoZoom appearances instead of the macro look"
```

---

### Task 2: Offset preset pick

**Files:**
- Create: `src/engine/preset-ref.ts`, `tests/preset_pick_test.lua`
- Modify: `src/engine/program.ts`, `src/desk.ts`, `src/runtime/autozoom.ts`, `src/ui/view-model.ts`, `src/console/ui.ts` (or a new `src/console/undo.ts`), `src/console/ma-desk.ts`, `tests/lib/fakedesk.lua`, `tests/lib/ma3mock.lua`, `tests/view_model_test.lua`, `tests/commands_test.lua`, `tests/console_desk_test.lua`, `tests/run.lua`, `src/testing/exports.ts`

**Interfaces:**
- Consumes: Task 1 `AppearanceKind` (`"capture"` for the waiting Offset cell, `"button"` otherwise).
- Produces:
  - `src/engine/preset-ref.ts`: `parsePresetCommand(command: string): string | undefined` → `"2.30"` or `"DataPool 4 Preset 2.30"`; `undoMatches(undoName: string | undefined, command: string): boolean`; `stripAnsi(text: string): string`.
  - `Desk` gains `lastCommand(): string | undefined`, `topUndoName(): string | undefined`, `undoProgrammer(): void`.
  - `AutoZoom.PickOffset(): void`; `export const PICK_SECONDS = 10`.
  - `HeaderState` gains `pickSecondsLeft?: number`; new header cell key `offset` with command `PickOffset()` (inserted after `setup`).

- [ ] **Step 1: Failing tests**

`tests/preset_pick_test.lua`:

```lua
local T = require("t")
local az = require("az")
local F = require("fakedesk")

T.test("preset command parsing", function()
  local p = az().preset
  T.eq(p.parsePresetCommand("OK: Preset 2.30"), "2.30", "plain")
  T.eq(p.parsePresetCommand("OK: Go+ Preset 2.30"), "2.30", "with keyword before")
  T.eq(p.parsePresetCommand("Datapool 4 Preset 2.30"), "DataPool 4 Preset 2.30", "data pool")
  T.eq(p.parsePresetCommand("OK: Go+ Sequence 3"), nil, "not a preset")
  T.eq(p.parsePresetCommand("Preset 2"), nil, "pool only")
end)

T.test("undo match is plain text", function()
  local p = az().preset
  T.eq(p.undoMatches("\27[32mPreset 2.30\27[0m", "OK: Preset 2.30"), true, "ansi stripped, OK: removed")
  T.eq(p.undoMatches("Preset 2x30", "Preset 2.30"), false, "dot is not a wildcard")
  T.eq(p.undoMatches(nil, "Preset 2.30"), false, "no undo entry")
end)

local function setup()
  local d = F.new({ fixtures = { F.fixture(101) }, markers = { F.marker(1) }, problems = {} })
  local a = az().runtime.createAutoZoom(d, "id")
  a:Install(); a:Start()
  d.lastCmd = "OK: Fixture 101"
  return d, a
end

T.test("pick stores the tapped preset and undoes its programmer effect", function()
  local d, a = setup()
  a:PickOffset(); d:tick()
  T.eq(d.views["offset"].text, "Tap a preset…\n10 s · tap to cancel", "waiting")
  T.eq(d.views["offset"].appearance, "capture", "capture look")
  d.lastCmd = "OK: Preset 2.30"; d.undoName = "Preset 2.30"
  d:tick()
  T.eq(d.undos, 1, "oops once")
  T.eq(az().config.parseConfig(d.saved["AutoZoom.config"] or "").config.offset.preset, "", "debounced: not yet saved")
  d.t = 2; d:tick()
  local cfg = az().config.parseConfig(d.saved["AutoZoom.config"]).config
  T.eq(cfg.offset.source, "preset", "source"); T.eq(cfg.offset.preset, "2.30", "preset")
  T.eq(d.views["offset"].text, "Offset\nPreset 2.30", "cell shows preset")
end)

T.test("unrelated command keeps the pick waiting", function()
  local d, a = setup()
  a:PickOffset(); d:tick()
  d.lastCmd = "OK: Go+ Sequence 3"; d:tick()
  T.eq(d.undos, 0, "nothing undone"); T.truthy(d.views["offset"].text:find("Tap a preset"), "still waiting")
end)

T.test("no Oops when the undo entry is something else", function()
  local d, a = setup()
  a:PickOffset(); d:tick()
  d.lastCmd = "OK: Preset 2.30"; d.undoName = "Store Sequence 3"
  d:tick()
  T.eq(d.undos, 0, "nothing undone"); T.eq(d.views["offset"].text, "Offset\nPreset 2.30", "picked anyway")
end)

T.test("pick times out, cancels and is refused when stopped or not current", function()
  local d, a = setup()
  a:PickOffset(); d.t = 11; d:tick()
  T.eq(d.logs[#d.logs], "Preset pick timed out", "timeout")
  a:PickOffset(); a:PickOffset()
  T.eq(d.logs[#d.logs], "Preset pick cancelled", "cancel")
  a:PickOffset(); a:Stop()
  local cancelled = false; for _, l in ipairs(d.logs) do if l == "Preset pick cancelled" then cancelled = true end end
  T.truthy(cancelled, "stop cancels")
  a:PickOffset()
  T.eq(d.logs[#d.logs], "Start AutoZoom to pick a preset", "refused when stopped")
  d.saved["AutoZoom.instance"] = "other"
  a:PickOffset()
  T.eq(d.logs[#d.logs], "Run the AutoZoom plugin for this show", "pick refused when not current")
end)

T.test("program commands accept a data pool preset address", function()
  local optics = { zoomMin = 10, zoomMax = 40, irisMin = 0, irisMax = 0 }
  local cmds = az().program.programCommands(102, 4, optics, { source = "preset", preset = "DataPool 4 Preset 2.30", values = { 0, 0, 0 } })
  T.eq(cmds[3], 'Attribute "XYZ_X" Thru "XYZ_Z" At DataPool 4 Preset 2.30', "data pool address")
end)
```

`tests/lib/fakedesk.lua` — add fields `lastCmd`, `undoName`, `undos = 0` and methods:

```lua
  function d:lastCommand() return self.lastCmd end
  function d:topUndoName() return self.undoName end
  function d:undoProgrammer() self.undos = self.undos + 1 end
```

`tests/view_model_test.lua` — update the header cell count in the layout-cells test from `8` to `9` and add `T.eq(keys["offset"], "PickOffset()", "offset pick")`.

`tests/console_desk_test.lua` — add a console test for the desk side, with mock additions (`CmdObj()` returning `M.cmdObj = { LastCommand = …, Undos = { UndoIndex = 0, [1] = { Name = … } } }` and `CurrentProfile()` returning `M.profile = { OopsProgrammer = false }`):

```lua
T.test("desk reads last command and undo name, oops restores OopsProgrammer", function()
  M.reset()
  M.cmdObj = { LastCommand = "OK: Preset 2.30", Undos = { UndoIndex = 0, [1] = { Name = "Preset 2.30" } } }
  M.profile = { OopsProgrammer = false }
  local desk = az().madesk.createMaDesk()
  T.eq(desk:lastCommand(), "OK: Preset 2.30", "last command"); T.eq(desk:topUndoName(), "Preset 2.30", "undo name")
  desk:undoProgrammer()
  T.eq(M.cmds[#M.cmds], "Oops /nc", "oops"); T.eq(M.profile.OopsProgrammer, false, "restored")
  T.eq(M.oopsProgrammerDuringOops, true, "was true during Oops")
end)
```

(The mock's `Cmd` records `M.oopsProgrammerDuringOops = M.profile and M.profile.OopsProgrammer` when the command is `Oops /nc`; `M.reset()` sets `M.cmdObj = { LastCommand = nil, Undos = { UndoIndex = 0 } }`, `M.profile = { OopsProgrammer = false }`; globals `function CmdObj() return M.cmdObj end`, `function CurrentProfile() return M.profile end`.)

Add `"preset_pick_test",` to `FILES` in `tests/run.lua`.

- [ ] **Step 2: Run to verify they fail**

Run: `nix shell nixpkgs#nodejs_22 nixpkgs#lua5_4 -c sh -c 'npm run build:test && lua tests/run.lua'`
Expected: FAIL — `preset` export nil, `PickOffset` nil.

- [ ] **Step 3: Implement**

`src/engine/preset-ref.ts`:

```ts
/** @noSelfInFile */

// Preset taps as they appear in CmdObj().LastCommand (FXMAker/BounceMAker 2.5 match the same two forms).
export function parsePresetCommand(command: string): string | undefined {
    const lower = command.toLowerCase();
    const [dp, a, b] = string.match(lower, "datapool%s+(%d+)%s+preset%s+(%d+)%.(%d+)");
    if (dp !== undefined) return `DataPool ${dp} Preset ${a}.${b}`;
    const [p, q] = string.match(lower, "preset%s+(%d+)%.(%d+)");
    if (p !== undefined) return `${p}.${q}`;
    return undefined;
}

export function stripAnsi(text: string): string {
    const [out] = string.gsub(text, "\27%[[%d;]*m", "");
    return out;
}

// Plain-text containment: the undo entry name contains the command (without a leading "OK:").
export function undoMatches(undoName: string | undefined, command: string): boolean {
    if (undoName === undefined) return false;
    let cmd = command.trim();
    if (cmd.startsWith("OK:")) cmd = cmd.substring(3).trim();
    if (cmd === "") return false;
    const [found] = string.find(stripAnsi(undoName), cmd, 1, true);
    return found !== undefined;
}
```

(`string.match`/`string.gsub`/`string.find` are the Lua functions from lua-types; they return LuaMultiReturn — destructure as shown. If tstl typing requires, use `const r = string.match(...)` and index `r[0]`… — keep behaviour identical.)

`src/engine/program.ts`: in the preset branch use `const target = offset.preset.startsWith("DataPool") ? offset.preset : `Preset ${offset.preset}`;` and push `Attribute "XYZ_X" Thru "XYZ_Z" At ${target}`.

`src/desk.ts`: add
```ts
    lastCommand(): string | undefined;                     // CmdObj().LastCommand
    topUndoName(): string | undefined;                     // name of the most recent undo entry
    undoProgrammer(): void;                                // Oops with CurrentProfile().OopsProgrammer temporarily on
```

Console (`src/console/undo.ts`, re-exported through MaDesk):

```ts
/** @noSelfInFile */
export function lastCommand(): string | undefined {
    const v = CmdObj().LastCommand;
    return v === undefined ? undefined : tostring(v);
}

export function topUndoName(): string | undefined {
    const undos: any = CmdObj().Undos;
    if (undos === undefined) return undefined;
    const entry = undos[undos.UndoIndex + 1];   // the console's own indexing (as FXMAker 2.5)
    return entry === undefined || entry.Name === undefined ? undefined : tostring(entry.Name);
}

export function undoProgrammer(): void {
    const profile: any = CurrentProfile();
    const saved = profile.OopsProgrammer;
    profile.OopsProgrammer = true;
    try {
        Cmd("Oops /nc");
    } finally {
        profile.OopsProgrammer = saved;
    }
}
```

Declare `CmdObj` / `CurrentProfile` in `src/console/ma-globals.d.ts` only if grandma3-ts-types lacks them (return `any`). `MaDesk` gets the three methods delegating to these functions.

`src/runtime/autozoom.ts`:
- `export const PICK_SECONDS = 10;` fields `protected pickUntil: number | undefined; protected pickBaseline: string | undefined;`
- `PickOffset()`:
  ```ts
    PickOffset(): void {
        if (!this.ensureCurrent()) return;
        if (this.pickUntil !== undefined) { this.endPick("Preset pick cancelled"); return; }
        if (!this.running) { this.say("Start AutoZoom to pick a preset"); return; }
        this.pickBaseline = this.desk.lastCommand();
        this.pickUntil = this.desk.now() + PICK_SECONDS;
        this.message = "Tap the preset that holds the XYZ offset";
        this.update();
    }
  ```
- `beforeUpdate()` additionally calls a private `updatePick()` (keep the capture logic as is):
  ```ts
    private updatePick(): void {
        if (this.pickUntil === undefined) return;
        if (this.desk.now() > this.pickUntil) { this.endPick("Preset pick timed out"); return; }
        const cmd = this.desk.lastCommand();
        if (cmd === undefined || cmd === this.pickBaseline) return;
        const preset = parsePresetCommand(cmd);
        if (preset === undefined) return;                      // unrelated command: keep waiting
        const undoName = this.desk.topUndoName();
        this.desk.log(`Preset pick saw "${cmd}", undo entry "${undoName ?? ""}"`);
        if (undoMatches(undoName, cmd)) this.desk.undoProgrammer();
        this.config.offset = { ...this.config.offset, source: "preset", preset };
        this.markDirty();
        this.endPick(`Offset preset ${preset}`);
    }

    private endPick(message: string): void {
        this.pickUntil = undefined;
        this.pickBaseline = undefined;
        this.say(message);
    }
  ```
- `Stop()`: next to the capture cancel, `if (this.pickUntil !== undefined) this.endPick("Preset pick cancelled");` (current path only, like capture).
- `render()`: pass `pickSecondsLeft` (same ceil logic as capture) in the header state.

`src/ui/view-model.ts`:
- Header list: insert `["offset", "PickOffset()"]` after `["setup", "Setup()"]`.
- `HeaderState.pickSecondsLeft?: number`.
- View: while picking → `cell("offset", `Tap a preset…\n${fmtInt(left)} s · tap to cancel`, "capture", COLORS.accent, COLORS.accent)`; else `cell("offset", `Offset\n${label}`, "button")` where `label` is `"Preset " + preset` for preset sources (`header.offsetLabel` already reads `preset 2.30` — change `offsetLabel` in `src/store/config.ts` to return `"Preset " + c.offset.preset` with a capital P, and update its test expectation in `tests/config_test.lua` if one exists for the preset branch).

`src/testing/exports.ts`: export `preset` (`import * as preset from "../engine/preset-ref"`).

- [ ] **Step 4: Run tests**

Run: `nix shell nixpkgs#nodejs_22 nixpkgs#lua5_4 -c sh -c 'npm test'`
Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add src tests out
git commit -m "Offset preset pick: tap a preset to set the XYZ offset source"
```

---

### Task 3: Docs and checklist

**Files:**
- Modify: `README.md`, `docs/console-test-checklist.md`

- [ ] **Step 1: README** — in "Using the layout": add an **Offset** bullet (tap, then tap a preset in any preset pool within 10 s; if that loaded the preset into the programmer it is undone with Oops; the cell shows the preset; tap again to cancel; works only while AutoZoom runs). Mention that cells are coloured by the AutoZoom appearances (`AZ …` in the Appearances pool), recreated by Rescan.

- [ ] **Step 2: Checklist** — add:
  - 22. Layout cells show tinted fills (no paper icon, no macro name); colours change with state (arm, tracking, no PSN, programmer P, capture waiting).
  - 23. Appearances pool contains the nine `AZ …` appearances once; Rescan does not duplicate them.
  - 24. Offset pick with fixtures selected: tap Offset, tap an XYZ preset → cell shows "Preset X.Y", programmer is back to what it was, nothing else undone. Note the System Monitor line "Preset pick saw …".
  - 25. Offset pick with nothing selected: preset picked, no Oops.
  - 26. Offset pick ignores an unrelated command (e.g. Go on a sequence) and times out after 10 s.

- [ ] **Step 3: Run tests** — `nix shell nixpkgs#nodejs_22 nixpkgs#lua5_4 -c sh -c 'npm test'` (docs only; must stay green).

- [ ] **Step 4: Commit**

```bash
git add README.md docs/console-test-checklist.md
git commit -m "Document appearances and the offset preset pick"
```
