# Preset Picker and Layout Rows Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the timed tap-to-pick of the XYZ offset preset with a picker window, and let the operator choose the layout rows as an ordered list of console Groups and single Fixtures, with group rows that arm and program all their fixtures.

**Architecture:** Pure logic (row list operations, group resolution, group-row summaries, group programmer commands) lives in `store/`, `engine/` and `ui/` and is tested through the fake desk. Windows are a new console module (`console/window.ts`, a TS port of Bake Offset's helpers) behind callback methods on `Desk`. The runtime keeps the full XYZ patch scan and derives the managed fixtures and the layout rows from `Config.rows`.

**Tech Stack:** TypeScript → Lua (typescript-to-lua 1.33, luaTarget 5.3), grandMA3 2.5.x plugin API, Lua test harness `tests/run.lua` (`tests/lib/t.lua`, `fakedesk.lua`, `ma3mock.lua`).

**Spec:** `docs/superpowers/specs/2026-11-01-preset-picker-and-layout-rows-design.md`

## Global Constraints

- Setup on NixOS: `nix shell nixpkgs#nodejs_22 nixpkgs#lua5_4 -c npm ci` once, then every test run is `nix shell nixpkgs#nodejs_22 nixpkgs#lua5_4 -c npm test` (builds the plugin and the test bundle, then runs `lua tests/run.lua`; the last line reports passed/failed).
- Every new test file is added to `FILES` in `tests/run.lua`; every new module under test is re-exported from `src/testing/exports.ts`.
- Every `.ts` file starts with `/** @noSelfInFile */`.
- An empty `Config.rows` is today's behaviour exactly: one fixture row per scanned XYZ fixture, in patch order.
- Fixtures not reached by a non-empty `rows` list are not managed: no row, not tracked, faders released (same path as fixtures dropped from the patch).
- Group membership is an exact FID match; group members that are not scanned XYZ fixtures are ignored silently.
- Group-row tap on a marker cell programs every XYZ fixture of the group with one selection command, then the same `Attribute …` lines as a fixture row.
- The plugin never changes the operator's selection or programmer except through the explicit tap commands (`Program`, `ProgramGroup`).
- Version 2.1.0.0 (`package.json` `version`, `Printf` in `src/main.ts`, header of `docs/console-test-checklist.md`).
- Cue command `Lua "AZ:Arm('101,102')"` is unchanged and stays fixture-level.

## Review Focus

- A fixture reached by two rows (a fixture entry and a group, or two groups): it is tracked once, both rows reflect it, and arming/programming through either row acts on that single fixture. → test in Task 6.
- A group deleted (or emptied) on the console after it was added: Rescan keeps the row as "Group missing" / "No XYZ fixtures"; tapping its Arm or marker cells logs and sends no command (never a bare `Fixture` command). → test in Task 6.
- A `fixture` entry whose fid is no longer an XYZ fixture: the row is left out and Rescan logs `Fixture 205 in the layout rows is not an XYZ fixture` once per Rescan (my call: the spec is silent). → test in Task 6.
- Closing the list editor while AutoZoom runs: the rebuild runs through `RescanLater()` (never inside the window's own signal) and AutoZoom keeps running. → test in Task 8.
- A 2.0 config without `rows`, and a config whose `rows` holds garbage entries: loads as an empty list / with the bad entries dropped, no extra warning. → test in Task 3.

---

### Task 1: Console probe (groups, multi-fixture programming, XYZ preset data)

The group work (Task 7) is blocked on this result; Tasks 2–6 can proceed meanwhile.

**Files:**
- Create: `probe/AutoZoomGroupProbe.lua`, `probe/AutoZoomGroupProbe.xml`

**Interfaces:**
- Produces: a System Monitor log the user pastes into `docs/superpowers/specs/2026-11-01-probe-groups-results.md` (create it with the pasted log and a short verdict per test).

- [ ] **Step 1: Write the probe.** Plain Lua, one `MessageBox` asking for a group number, an XYZ fixture list (e.g. `101 + 102`), a marker CID and an XYZ preset (`2.30`); each test prints `[AZP] <test>: <result>` with `Printf`. Tests, each wrapped in `pcall`:
  - G1: dump `DataPool().Groups[n]` (name, class, every child and its class/props via `:Children()`, and these properties if present: `SelectionData`, `Selection`, `Fixtures`, `Count`).
  - G2: `ObjectList("Group n")` — count and each element's class, `.fid`, `.name`.
  - G3: save the current selection (`SelectionFirst/SelectionNext` list of subfixture indexes), `Cmd("SelFix Group n")`, list the selection as `GetSubfixture(i).fid`, then restore the saved selection (`ClearSelection` + `Fixture <fids joined by " + ">`) and print whether the restored list equals the saved one.
  - P1: `ClearAll`; `Fixture <list>`; `Attribute "XYZ_MArker" At <cid>`; `Attribute "XYZ_X" Thru "XYZ_Z" At Preset <preset>`; print for every listed fid the programmer value of XYZ_MArker and XYZ_X (`GetProgPhaser(uich)`); `ClearAll`.
  - X1: `GetPresetData(<preset handle>, false, true).by_fixtures` — print each attribute name of the first fixture.
- [ ] **Step 2: Write the XML** (copy `../gma3-smart-offset/probe/BakeOffsetProbe.xml` shape; Name "AutoZoom Group Probe", Version 0.1.0.0, `ComponentLua FileName="AutoZoomGroupProbe.lua"`).
- [ ] **Step 3: Syntax check.** Run: `nix shell nixpkgs#lua5_4 -c luac -p probe/AutoZoomGroupProbe.lua` — Expected: no output.
- [ ] **Step 4: Hand to the user** with the import steps; wait for the log; write the results file. If neither G1 nor G2 gives the fids, and G3's restore is not exact, **stop and ask the user** (spec §7.3).
- [ ] **Step 5: Commit**

```bash
git add probe/ docs/superpowers/specs/2026-11-01-probe-groups-results.md
git commit -m "probe: group membership, multi-fixture programming, XYZ preset data"
```

### Task 2: Window toolkit and plugin handle

**Files:**
- Create: `src/console/window.ts`, `tests/lib/ma3ui.lua`, `tests/window_test.lua`
- Modify: `src/main.ts`, `src/testing/exports.ts`, `tests/run.lua`

**Interfaces:**
- Produces (`src/console/window.ts`):
  - `setPlugin(signals: any, handle: any): void` — stores the chunk's `signalTable` and component handle.
  - `buildBase(title: string, width: number): any` (body `DialogFrame`), `fixedRows(body: any, sizes: number[]): void`, `row(parent: any, anchorRow: number): any`, `label(parent: any, text: string, w: number, h: number): any`, `button(parent: any, text: string, w: number, h: number, signal: string, fn: (caller: any) => void): any`, `scrollGrid(parent: any, anchorRow: number, width: number, contentHeight: number, columns: number, rows: number): any`, `paint(obj: any, color: any): void`, `color(group: string, name: string): any`, `closeWindow(): void` (`ClearUIChildren` on the overlay), `ask(title: string, message: string): boolean` (Yes=1/No=0 MessageBox).
  - Behaviour copied from Bake Offset `BakeOffset.lua:1046-1200` (`_screenOverlay`, `_buildBase`, `_label`, `_button`, `_row`, `_paint`, `_scrollGrid`, `_fixedRows`); every cosmetic property write that may not exist goes through `pcall` as there. Signal names are prefixed `AZW_`.
- Produces (`tests/lib/ma3ui.lua`): `U.install()` (fake `GetFocusDisplay`, `Obj`, `GetDisplayByIndex`, `Root` exactly as in `../gma3-smart-offset/test/ui_smoke_test.lua:5-41`), `U.signals` (the table passed to `setPlugin`), `U.click(name, caller?)`, `U.texts(): string` (all `Text` joined by ` | `), `U.find(pred): node[]`.

- [ ] **Step 1: Write the failing test** `tests/window_test.lua`:

```lua
T.test("button registers its signal and the click runs it", function()
  U.install(); local w = az().window; w.setPlugin(U.signals, {})
  local hit = 0
  local body = w.buildBase("AutoZoom — test", 600)
  w.button(w.row(body, 0), "Go", 100, 50, "AZW_Test", function() hit = hit + 1 end)
  U.click("AZW_Test")
  T.eq(hit, 1, "clicked once"); T.truthy(U.texts():find("Go", 1, true), "button drawn")
end)
T.test("closeWindow clears the overlay", function()
  U.install(); local w = az().window; w.setPlugin(U.signals, {})
  w.buildBase("x", 600); w.closeWindow()
  T.eq(U.texts(), "", "nothing left")
end)
```

- [ ] **Step 2: Run** `npm test` (Global Constraints command) — Expected: FAIL, `window` is nil.
- [ ] **Step 3: Implement** `src/console/window.ts`; export it as `window` from `exports.ts`; add `"window_test"` to `run.lua`.
- [ ] **Step 4: Capture the chunk arguments in `src/main.ts`.** The bundle ends with `return require("src.main", ...)`, so the main module receives the chunk varargs. Add `/// <reference types="typescript-to-lua/language-extensions" />` and at file scope `const [, , signals, handle] = [...$vararg]; setPlugin(signals, handle);`. Bump the `Printf` to `AutoZoom 2.1.0.0 by Naostage` and `package.json` `version` to `2.1.0.0`.
- [ ] **Step 5: Run** `npm test` — Expected: all pass; then `grep -n "setPlugin" out/autozoom-grandma3.lua` shows the call inside the `src.main` module.
- [ ] **Step 6: Commit** `feat(console): window toolkit ported from Bake Offset`.

### Task 3: Row entries in the config

**Files:**
- Create: `src/store/rows.ts`, `tests/rows_test.lua`
- Modify: `src/store/config.ts`, `src/testing/exports.ts`, `tests/run.lua`, `tests/config_test.lua`

**Interfaces:**
- Produces (`src/store/rows.ts`):
  - `type RowEntry = { kind: "group"; no: number; name: string } | { kind: "fixture"; fid: number }`
  - `interface GroupInfo { no: number; name: string; fids: number[] }`
  - `sameEntry(a: RowEntry, b: RowEntry): boolean`
  - `addEntries(rows: RowEntry[], add: RowEntry[]): RowEntry[]` — appends in order, skips duplicates.
  - `moveEntry(rows: RowEntry[], index: number, delta: -1 | 1): RowEntry[]` — out of range = unchanged copy. Indexes are 0-based.
  - `removeEntry(rows: RowEntry[], index: number): RowEntry[]`
  - `coverage(rows: RowEntry[], groups: GroupInfo[]): { fixtures: { [fid: string]: "self" | "group" }; groups: { [no: string]: boolean } }` — "self" wins over "group".
  - `entryLabel(e: RowEntry, groups: GroupInfo[], fixtureName: (fid: number) => string | undefined): string` → `Group 3  Front truss` / `Fixture 205  Spot 5` (missing group: its saved name; missing fixture: `Fixture 205`).
- Produces (`config.ts`): `Config.rows: RowEntry[]`, default `[]`; parsed (entries with a non-integer `no`/`fid`, or a group without a string `name`, are dropped; duplicates dropped) and serialized.

- [ ] **Step 1: Write failing tests** in `tests/rows_test.lua`:
  - `addEntries skips duplicates and keeps order`: `addEntries({G3}, {F205, G3, G4})` → `{G3, F205, G4}`.
  - `moveEntry swaps neighbours and ignores the ends`: `{A,B,C}` index 1 delta -1 → `{B,A,C}`; index 0 delta -1 → `{A,B,C}`; index 2 delta 1 → `{A,B,C}`.
  - `removeEntry removes one line`.
  - `coverage marks self over group`: rows `{G3 (fids 101,102), F102}` → fixtures `{["101"]="group", ["102"]="self"}`, groups `{["3"]=true}`.
  - `entryLabel for live and missing entries`: `Group 3  Front truss`, `Fixture 205  Spot 5`, missing fixture `Fixture 205`.
  - In `tests/config_test.lua`: `rows round trip` (G3 + F205 serialize → parse equal); `a 2.0 config without rows gives an empty list`; `garbage rows are dropped without warning` (`rows = {{kind="group",no="x"}, {kind="fixture",fid=1.5}, {kind="fixture",fid=7}, {kind="fixture",fid=7}}` → `{F7}`, `warning == nil`).
- [ ] **Step 2: Run** `npm test` — Expected: FAIL (`rows` module missing).
- [ ] **Step 3: Implement** `rows.ts` and the `config.ts` changes; export `rows` from `exports.ts`; add `"rows_test"` to `run.lua`.
- [ ] **Step 4: Run** `npm test` — Expected: PASS.
- [ ] **Step 5: Commit** `feat(store): ordered layout row entries in the config`.

### Task 4: Multi-fixture programmer commands

**Files:**
- Modify: `src/engine/program.ts`, `src/runtime/autozoom.ts` (callers), `tests/program_test.lua`, `tests/commands_test.lua` if it calls these

**Interfaces:**
- Produces: `programCommands(fids: number[], cid: number, offset: Config["offset"]): string[]` and `releaseCommands(fids: number[]): string[]`. Empty `fids` → `[]`.
  - Selection line: `Fixture 101 + 102 + 103` (fids in the given order). The remaining lines are exactly today's.
  - Release: `Off Fixture 101 + 102 + 103`.

- [ ] **Step 1: Write failing tests** (pure, on `az().program`):
  - `group program is one selection then the attribute lines`: `programCommands({101,102,103}, 2, {source="values", values={0,0,0.3}})` → `{"Fixture 101 + 102 + 103", 'Attribute "XYZ_MArker" At 2', 'Attribute "XYZ_X" At 0', 'Attribute "XYZ_Y" At 0', 'Attribute "XYZ_Z" At 0.3'}`.
  - `group program from a preset`: source preset `2.30` → last line `Attribute "XYZ_X" Thru "XYZ_Z" At Preset 2.30`, 3 lines total.
  - `group release`: `releaseCommands({101,102})` → `{"Off Fixture 101 + 102"}`.
  - `no fixtures, no commands`: both return `{}` for `{}`.
- [ ] **Step 2: Run** — Expected: FAIL.
- [ ] **Step 3: Implement**; change `Program()` to pass `[fid]`.
- [ ] **Step 4: Run** — Expected: PASS, including the existing `Program loads marker and offset only` test unchanged.
- [ ] **Step 5: Commit** `feat(engine): programmer commands for several fixtures`.

### Task 5: Preset picker replaces the timed pick

**Files:**
- Create: `src/console/preset-picker.ts`
- Delete: `src/console/undo.ts`
- Modify: `src/desk.ts`, `src/console/ma-desk.ts`, `src/console/ui.ts`, `src/store/config.ts`, `src/runtime/autozoom.ts`, `src/engine/preset-ref.ts`, `src/ui/view-model.ts`, `tests/lib/fakedesk.lua`, `tests/lib/ma3mock.lua`, `tests/preset_pick_test.lua` (rewrite), `tests/view_model_test.lua`, `tests/program_test.lua`, `docs/console-test-checklist.md`

**Interfaces:**
- Consumes: Task 2 window toolkit.
- Produces:
  - `Desk.openPresetPicker(current: string, onPick: (preset: string) => void): void` (`current` = `config.offset.preset`, may be `""`; `onPick` gets `"<pool>.<no>"`).
  - `SetupAnswers.action: "save" | "pick" | "rows"` replaces `pick: boolean`. The MessageBox commands become `Save`(1), `Pick preset…`(2), `Layout rows…`(3), `Cancel`(0). Task 8 handles `"rows"`; until then the runtime ignores it.
  - `AutoZoom.PickOffset()` opens the picker (any running state).
  - Removed from `Desk`: `lastCommand`, `topUndoName`, `undoMark`, `undoProgrammer`. Removed: `PICK_SECONDS`, the pick fields and methods in the runtime, `HeaderState.pickSecondsLeft` and the countdown message, `undoMatches`, `stripAnsi`, `normalize`, `NOT_A_TAP`. `parsePresetCommand` stays.
- Picker window (`preset-picker.ts`, `openPresetPicker(current, onPick)`): Bake Offset `OpenPicker`/`DrawPicker` single-pick mode (`BakeOffset.lua:1303-1420`): pools from `DataPool().PresetPools` (as `BakeOffset.MA.ListPools`, `BakeOffset.lua:536`), title `AutoZoom — choose the XYZ offset preset`, first tab = pool of `current` else 2, current tile painted, tiles without an attribute name starting `XYZ_` in `GetPresetData(p, false, true).by_fixtures` disabled with status `no XYZ` (others `XYZ`), tile tap → `closeWindow()` then `onPick(addr)`, `Cancel` → `closeWindow()`. Signals `AZW_PickPool_<i>`, `AZW_PickTile_<i>`, `AZW_PickCancel`.

- [ ] **Step 1: Rewrite `tests/preset_pick_test.lua`** (keep the `preset command parsing` test, drop the undo ones):
  - `Pick preset opens the picker even while stopped`: fakedesk `openPresetPicker` records `current` and `onPick`; `setupAnswer = {action="pick", …}`; `a:Setup(); d:runLaters()` → picker opened with `current == ""`; calling `onPick("2.30")` → saved config has `offset.source == "preset"`, `offset.preset == "2.30"`, last log `Offset preset 2.30`.
  - `PickOffset opens the picker`.
  - `picker window greys presets without XYZ and picks a tile` (ma3mock + ma3ui): presets `2.1` (Pan only) and `2.30` (XYZ_X) in pool 2; `madesk.openPresetPicker("", fn)`; tile text starting `2.1` has `Enabled == "No"`; click the `2.30` tile → `fn` got `"2.30"` and `U.texts() == ""`.
  - `Cancel closes without a pick`.
- [ ] **Step 2: Add to `ma3mock.lua`** what the picker reads: `M.presetPool(no, name)`, `M.preset(poolNo, no, name, attrs)` behind `DataPool().PresetPools:Children()` and `GetPresetData` (shape `{by_fixtures = {["101"] = {XYZ_X = {...}}}}`), mirroring `../gma3-smart-offset/test/mocks.lua:42,93-109`.
- [ ] **Step 3: Run** — Expected: FAIL.
- [ ] **Step 4: Implement**; update `view_model_test.lua` (drop `message cell shows the pick countdown while picking`) and `program_test.lua` `Setup applies answers…` (`action = "save"`).
- [ ] **Step 5: Run** — Expected: PASS; `grep -rn "undoMark\|pickUntil\|PICK_SECONDS" src tests` — Expected: no output.
- [ ] **Step 6: Replace checklist items 22–25 and 28** with: picker opens from Setup (running and stopped); non-XYZ presets greyed; tapping a tile sets the Setup cell to `Preset X.Y` and leaves the programmer and selection untouched; Cancel changes nothing.
- [ ] **Step 7: Commit** `feat: preset picker window replaces the timed preset pick`.

### Task 6: Rows, managed fixtures and group rows (runtime + view model)

**Files:**
- Modify: `src/desk.ts`, `src/model.ts`, `src/ui/view-model.ts`, `src/runtime/autozoom.ts`, `tests/lib/fakedesk.lua`, `tests/view_model_test.lua`, `tests/runtime_test.lua`, `tests/program_test.lua`

**Interfaces:**
- Consumes: Task 3 (`RowEntry`, `GroupInfo`), Task 4 (list commands).
- Produces:
  - `Desk.listGroups(): GroupInfo[]` (fake desk: returns `d.groups or {}`; console implementation in Task 7 — until then `MaDesk.listGroups` returns `[]`).
  - `model.ts`: `type LayoutRow = { kind: "fixture"; fixture: PatchFixture } | { kind: "group"; no: number; name: string; fixtures: PatchFixture[]; missing: boolean }`.
  - `layoutCells(rows: LayoutRow[], markers: PatchMarker[]): CellSpec[]` — fixture rows unchanged; group rows `garm <no>` (`ArmGroup(<no>)`), `gmx <no> <cid>` (`ProgramGroup(<no>,<cid>)`), `gst <no>` (display only), no di/zo/ir/sz cells.
  - `view-model.ts`: `interface GroupRowState { no: number; name: string; missing: boolean; members: RowState[] }`; `buildViews(header, rows: (RowState | GroupRowState)[], markers, readings)` discriminated by `"members" in row`; `summarize(members: RowState[]): { tracking: number; total: number; worst: StateKind | undefined; worstCount: number }`.
  - Group cell texts and colours (spec §7.4): arm `G<no> <name>\n<armed>/<total> armed`, appearance `tracking` all armed / `idle` none / `warn` partial; marker `●` if any member follows the marker (colour from the best member state, as fixture rows), `P` all members have it in the programmer, `P <n>/<m>` some (programmer colours); state `<k>/<m> tracking\n<worstCount> <label>` (second line omitted when no member is non-tracking), colour/appearance of `worst`; `No XYZ fixtures` (idle) for 0 members; `Group missing` (error) when `missing`. Tracking states: `tracking`, `too-wide`, `too-small`. Worst order: `unknown-marker`, `no-psn`, `too-wide`, `too-small`, `tracking`, `no-marker`, `disarmed`, `offline`.
  - Runtime: `this.patch` = full scan; `this.scanned.fixtures` = managed fixtures (all when `rows` is empty, else the union reached by `rows`, patch order); `desk.install` receives only managed fixtures; fixtures leaving the managed set go through `releaseAll`. Group contents resolved by `desk.listGroups()` in `Rescan`. New commands `ArmGroup(no: number)` (any member disarmed → arm all members; else disarm all) and `ProgramGroup(no: number, cid: number)` (all members have `cid` in the programmer → `releaseCommands(fids)`; else `programCommands(fids, cid, offset)`); both log `Group <no> has no XYZ fixtures` and send nothing when there are no members. `Status()` logs group rows as `  G<no> <name>: <k>/<m> tracking`.

- [ ] **Step 1: Write failing view-model tests:** `group row cells have no distance, zoom, iris or size`; `group state counts tracking and shows the worst` (members tracking, tracking, no-psn → `2/3 tracking\n1 No PSN data`, appearance `nopsn`); `group marker cell P counts programmer members` (`P 1/2`, then `P` with both); `partially armed group arm cell is warn`; `missing group shows Group missing`.
- [ ] **Step 2: Write failing runtime tests** (fakedesk, patch fixtures 101, 102, 103, 205, groups `{no=3, name="Front truss", fids={101,102,999}}`):
  - `empty rows keep one row per patch fixture` (cells `arm 101` … `arm 205`, no `garm`).
  - `rows limit the managed fixtures and release the others`: `rows = {G3, F205}`, Rescan → installed fids `{101,102,205}`, `103` released, cells `garm 3` and `arm 205` only.
  - `ProgramGroup programs every XYZ member with one selection`: → `d.cmds[1] == "Fixture 101 + 102"` (999 ignored).
  - `ProgramGroup releases when all members are on that marker`: progCids 101 and 102 = 2 → `{"Off Fixture 101 + 102"}`.
  - `ArmGroup arms all when one is disarmed, else disarms all`.
  - `a fixture in two rows is tracked once` (`rows = {G3, F101}` → 101 installed once, `setFaders` once per tick for 101, both `arm 101` and `garm 3` present).
  - `missing or empty group: row kept, taps send nothing` (group 3 removed from `d.groups` then Rescan → `gst 3` text `Group missing`; `ProgramGroup(3,1)` → no cmds, log `Group 3 has no XYZ fixtures`).
  - `fixture entry not in the patch is left out and logged`: `rows = {F777}` → no `arm 777`, log `Fixture 777 in the layout rows is not an XYZ fixture`.
- [ ] **Step 3: Run** — Expected: FAIL.
- [ ] **Step 4: Implement**; existing view-model tests change only in the `layoutCells` argument (wrap fixtures as `{kind="fixture", fixture=f}`).
- [ ] **Step 5: Run** — Expected: PASS.
- [ ] **Step 6: Commit** `feat: layout rows from groups and fixtures, group arm and program`.

### Task 7: Read console groups (MaDesk.listGroups)

Blocked on Task 1's results file.

**Files:**
- Modify: `src/console/ma-desk.ts`, new helper in `src/console/patch.ts` (or `src/console/groups.ts` if over ~40 lines), `tests/lib/ma3mock.lua`, `tests/console_desk_test.lua`

**Interfaces:**
- Produces: `MaDesk.listGroups(): GroupInfo[]` — every group of the default data pool, sorted by `no`, `fids` in the group's order, using the method the probe proved (G1 or G2 preferred; G3 only if its restore was exact).

- [ ] **Step 1: Add groups to `ma3mock.lua`** shaped exactly like the probe's G1/G2 dump (record which in a comment citing the results file).
- [ ] **Step 2: Write failing test** `listGroups reads every group with its fids`: groups 3 `Front truss` {101,102}, 5 `Floor` {205} → `{{no=3,name="Front truss",fids={101,102}},{no=5,name="Floor",fids={205}}}`; and `listGroups leaves the selection alone` (if G3 is used: selection before == selection after, no `ClearAll`/programmer commands in `M.cmds`).
- [ ] **Step 3: Run** — Expected: FAIL. **Step 4: Implement.** **Step 5: Run** — Expected: PASS.
- [ ] **Step 6: Commit** `feat(console): read group membership`.

### Task 8: Layout rows editor and add picker

**Files:**
- Create: `src/console/rows-editor.ts`, `tests/rows_editor_test.lua`
- Modify: `src/desk.ts`, `src/console/ma-desk.ts`, `src/runtime/autozoom.ts`, `tests/lib/fakedesk.lua`, `tests/run.lua`, `tests/runtime_test.lua`

**Interfaces:**
- Consumes: Task 2 (window), Task 3 (`addEntries`, `moveEntry`, `removeEntry`, `coverage`, `entryLabel`), Task 6 (`listGroups`).
- Produces:
  - `interface Catalog { groups: GroupInfo[]; fixtures: { fid: number; name: string }[] }`
  - `Desk.openRowsEditor(rows: RowEntry[], catalog: Catalog, onChange: (rows: RowEntry[]) => void, onClose: (changed: boolean) => void): void`
  - Runtime: Setup `action == "rows"` and new command `AZ:Rows()` open the editor with `catalog = { groups: desk.listGroups(), fixtures: <full patch scan, fid + name> }`; `onChange` stores `config.rows` and `markDirty()`s; `onClose(true)` → `RescanLater()`.
- Editor window (spec §8): title `AutoZoom — layout rows`; per line `entryLabel` + `/\` (`AZW_RowUp_<i>`), `\/` (`AZW_RowDown_<i>`), trash (`AZW_RowDel_<i>`, confirms with `ask("Remove line", "Remove <label>?")`); ends disabled; empty hint `Empty: every XYZ fixture gets its own row`; `+` (`AZW_RowAdd`) and `Close` (`AZW_RowClose`). Each change calls `onChange` and redraws.
- Add picker: tabs `Groups` (`AZW_AddTab_1`) / `Fixtures` (`AZW_AddTab_2`); tiles `AZW_AddTile_<i>` toggle and show their tap order (`1`, `2`…); ticks from `coverage`: Fixtures tab `✔` green (`self`, tile disabled) / `✔` yellow (`group`, still tappable), Groups tab `✔` green (disabled); `Add <n>` (`AZW_AddOk`) appends in tap order via `addEntries`, `Cancel` (`AZW_AddCancel`); both return to the editor.

- [ ] **Step 1: Write failing tests** `tests/rows_editor_test.lua` (ma3ui, calling `madesk.openRowsEditor` directly):
  - `editor reorders and removes with confirmation`: rows `{G3, F205}`; click `AZW_RowDown_1` → `onChange` got `{F205, G3}`; `MessageBox` answer No then `AZW_RowDel_1` → no change; answer Yes → `{G3}`.
  - `add picker adds several tiles in tap order`: `AZW_RowAdd`, tab Fixtures, tap tiles of 205 then 101, `AZW_AddOk` → `onChange` last got `{G3, F205, F101}`.
  - `ticks show what the list covers`: rows `{G3 (101,102), F102}` → Fixtures tab tile 101 yellow tick, tile 102 green tick and `Enabled == "No"`, tile 205 no tick; Groups tab tile 3 green tick.
  - `Close reports whether anything changed`: no edit → `onClose(false)`; after an edit → `onClose(true)`.
  - In `runtime_test.lua`: `closing the editor with changes rebuilds via RescanLater while running` (fakedesk captures callbacks; `onChange({F101})`; `onClose(true)`; `d:runLaters()` → cells only `arm 101`, `a.running` still true).
- [ ] **Step 2: Run** — Expected: FAIL. **Step 3: Implement.** **Step 4: Run** — Expected: PASS.
- [ ] **Step 5: Commit** `feat: layout rows editor with group and fixture picker`.

### Task 9: Docs and console checklist

**Files:**
- Modify: `README.md`, `docs/console-test-checklist.md`

- [ ] **Step 1: README:** Setup section gains "Pick preset…" (window) and "Layout rows…" (editor, empty = all fixtures, group rows hide Distance/Zoom/Iris/Size); command list gains `AZ:ArmGroup(n)`, `AZ:ProgramGroup(n,cid)`, `AZ:Rows()`; `AZ:PickOffset()` described as opening the picker.
- [ ] **Step 2: Checklist** header 2.1.0.0 and new items: rows editor reorder/trash/+; ticks green/yellow; group row tap programs all its XYZ fixtures (check every fixture in the programmer); group Arm; a fixture left out stops being driven; deleting the group on the console then Rescan shows Group missing; empty list shows all fixtures.
- [ ] **Step 3: Run** `npm test` — Expected: PASS; `out/autozoom-grandma3.xml` has Version 2.1.0.0.
- [ ] **Step 4: Commit** `docs: 2.1 picker and layout rows`.
