# AutoZoom 2.1 — Preset picker and chosen layout rows

Date: 2026-11-01 · Branch: `feat/ux-ui` · Target: grandMA3 2.5.x
Builds on: `2026-10-03-autozoom-layout-ux-design.md` (layout, cells, runtime, `Desk`).
Prior art: the Bake Offset plugin (`../gma3-smart-offset/BakeOffset.lua`): its preset picker window
(`BakeOffset.UI.OpenPicker` / `DrawPicker`) and window helpers (`_buildBase`, `_row`, `_button`, `_label`,
`_scrollGrid`, `_fixedRows`), proven on onPC 2.5.1.1.

## 1. Intent

Two changes, both about choosing things from the console's pools instead of typing or tapping blind.

1. **Preset picker.** Choosing the XYZ offset preset today means Setup → "Pick preset…", then tapping a
   preset on the console within 10 s while AutoZoom is running. The plugin watches the command line and
   Oopses the tap if it loaded values into the programmer. It is fragile, refuses to work while stopped,
   and six checklist items (22–25, 28) exist only to test it. Replace it with a window that shows the
   preset pools as tabs of tiles: tap a tile, done.
2. **Chosen layout rows.** Today the layout has one row per XYZ fixture in the patch. On a real show that
   is too many rows, and the operator thinks in groups ("front truss", "floor"). The user wants to choose
   what appears: an ordered list of **entries**, each a console **Group** or a single **Fixture**, mixed
   freely. One layout row per entry. A group row acts on all its fixtures at once.

What matters most to the user: **tapping a marker cell on a group row must put the marker and offset into
the programmer for every fixture of the group**, reliably. Everything else on group rows is secondary.

## 2. Goals

- Offset preset chosen from a picker window, working whether AutoZoom runs or not.
- A list editor (in Setup) to build the ordered entry list: add, reorder, remove.
- Layout rows follow the list: group rows and fixture rows, in list order.
- Group rows: Arm and marker cells act on every fixture of the group; a summarised state.
- The tap-and-Oops pick code is deleted.

## 3. Non-goals

- Section headers, nested groups, or rows sorted automatically.
- Per-group size, per-group offset, per-group refresh rate.
- Several saved lists / list profiles.
- Changing the cue command `Lua "AZ:Arm('101,102')"`: it stays fixture-level.
- Migrating anything: an empty list is today's behaviour, so old shows keep working untouched.

## 4. Anti-goals (it would be a failure if…)

- A group tap programs only some of the group's XYZ fixtures, or programs fixtures outside the group.
- The plugin changes the operator's fixture selection or programmer as a side effect of reading a group,
  opening a window, or rescanning.
- A fixture the operator left out of the list keeps being driven by AutoZoom.

## 5. Decisions made with the user

| Topic | Decision |
|---|---|
| Entries | Ordered list; each entry is a Group or a single Fixture; mixed freely. |
| Empty list | Today's behaviour: one fixture row per XYZ fixture in the patch. |
| Fixtures not in any entry (list not empty) | Left out of AutoZoom completely: no row, not tracked, faders released. |
| Group contents | Follow the console Group: re-read at every Rescan. |
| Group row cells | Arm and marker cells act on all its fixtures. Distance, Zoom %, Iris % and Size are **not shown**. |
| Group row state | A count such as `4/6 tracking`, coloured by the worst state in the group. Marker cells light when at least one fixture of the group is on that marker. |
| List editor | Lines with **/\\** and **\\/** to reorder, a **trash** button (with confirmation) to remove, a **+** button to add. |
| **+** | Opens a picker; you can tap **several** tiles before closing; each becomes its own line, in tap order. |
| Preset picker | Pool tabs over preset tiles, Bake Offset style; one tap picks. Replaces the 10 s tap pick. |

## 6. Preset picker

- Opened by Setup → **Pick preset…** (the MessageBox button stays; it now opens the window instead of
  starting the timed pick). Works while AutoZoom is stopped.
- Window: title "AutoZoom — choose the XYZ offset preset"; row of pool tabs (number + name); grid of preset
  tiles (`<pool>.<no>  <name>`, second line a short status). The tab first shown is the pool of the current
  offset preset, else pool 2 (Position). The current offset preset's tile is highlighted.
- Tiles of presets holding no `XYZ_X/Y/Z` data are disabled (status "no XYZ"). Detection reads
  `GetPresetData(preset).by_fixtures` attribute names, as Bake Offset's `PresetStatus` does (it greys XYZ
  presets; here it is the opposite test).
- Tap a tile → `offset = { source: "preset", preset: "<pool>.<no>" }`, config saved, window closed,
  message "Offset preset 2.30". A **Cancel** button closes without change.
- *(My call)* After a pick the Setup dialog is not reopened; the Setup cell already shows the new preset.
- *(My call)* Only the default data pool's presets are listed. A `DataPool n Preset p.q` value typed in
  the Setup input keeps working as today.
- Removed: `startPick`, `updatePick`, `endPick`, `pickUntil/pickBaseline/pickUndoMark/pickIgnored`,
  `PICK_SECONDS`, `HeaderState.pickSecondsLeft` and the "Tap a preset… n s" message cell, `undoMatches`,
  `stripAnsi`/`normalize` if unused, `src/console/undo.ts`, and the `Desk` methods `lastCommand`,
  `topUndoName`, `undoMark`, `undoProgrammer`. `parsePresetCommand` stays (Setup input normalisation).
  The `Program()` code that refreshes the pick baseline goes too. `AZ:PickOffset()` stays as a command and
  opens the picker. `tests/preset_pick_test.lua` is rewritten for the window. Checklist items 22–25 and 28
  are replaced by picker items.

## 7. Layout rows

### 7.1 Config

`Config.rows: RowEntry[]`, saved in the same JSON (`serializeConfig` / `parseConfig`, invalid entries
dropped with no warning beyond the existing "unreadable" one):

```ts
type RowEntry = { kind: "group"; no: number; name: string } | { kind: "fixture"; fid: number };
```

- *(My call)* Groups are referenced by their **pool number**; `name` is what was shown when it was added,
  used only as a fallback label when the group is gone. The label shown is the group's current name.
- No duplicate entries (same group number, or same fid as a fixture entry). A fixture may still be reached
  through several entries (a fixture entry and a group, or two groups): it is one fixture, tracked once,
  shown in each row it belongs to.

### 7.2 Which fixtures AutoZoom manages

- List empty → every scanned XYZ fixture (unchanged).
- List not empty → the union of the XYZ fixtures reached by the entries. Group members that are not XYZ
  fixtures with a Zoom channel are ignored silently. Fixtures that leave the managed set are released
  exactly like fixtures dropped from the patch (`releaseAll`). *(My call)* Their `AZ_BASE/ZOOM/IRIS`
  sequences are not deleted; `install` only creates sequences for managed fixtures.
- Resolved at `Rescan` (which also runs on plugin start) and when the list editor closes with changes.

### 7.3 Reading a group's fixtures — must be probed first

The way to read a Group's fixtures from Lua **without touching the operator's selection** is not verified.
Candidates, in order of preference: a property or child list of the group object
(`DataPool().Groups[n]`), `ObjectList("Group n")` returning fixtures, and as last resort
`SelFix Group n` + `SelectionFirst/SelectionNext` with the previous selection saved and restored (rejected
if restoring is not exact — see anti-goals). The user expects one of these to work; if none does, stop
and bring it back to the user rather than choosing a fallback. Membership is an **exact FID match**: no
expansion to sub-fixtures or parents (the user's rigs have no multi-instance XYZ fixtures). A probe plugin (Bake Offset probe style: one button per test,
results in the System Monitor, the user pastes the log) settles it before the group work is built.
Same probe also confirms:

- `Fixture 101 + 102 + 103` followed by the existing `Attribute "XYZ_MArker" At <cid>` and XYZ commands
  programs all listed fixtures (also with `At Preset` for the XYZ part).
- `GetPresetData` exposes `XYZ_X/Y/Z` attribute names for an XYZ preset (picker greying).

### 7.4 Rows and cells

Rows are drawn in list order (empty list: patch order as today). Fixture rows are unchanged
(cells `arm <fid>`, `mx <fid> <cid>`, `st/di/zo/ir/sz <fid>`). If the same fixture has two fixture rows it
cannot (no duplicate entries); a fixture inside a group row has no cells of its own unless it also has a
fixture entry.

Group rows, keyed by group number: `garm <no>`, `gmx <no> <cid>`, `gst <no>`. No `di/zo/ir/sz` cells;
the space stays empty.

| Cell | Content | Tap |
|---|---|---|
| Arm | `G<no>` + group name, second line `n/m armed`. Green all armed, grey none armed, warn colour partially. | Any disarmed → arm all of the group; all armed → disarm all. (`ArmGroup(no)`) |
| Marker | `●` when at least one fixture of the group follows that marker (colour as fixture rows, from the best state among them). `P` when **all** XYZ fixtures of the group have that marker in the programmer, `P n/m` when only some. | Not all in programmer on that marker → program all of them (marker + offset); all → release all. (`ProgramGroup(no, cid)`) |
| State | `k/m tracking`, second line the worst non-tracking state label with its count (`1 No PSN`). Colour/appearance = worst state. Empty group: "No XYZ fixtures"; group gone: "Group missing" (error colour), its label from `RowEntry.name`. | — |

- Tracking count includes `tracking`, `too-wide`, `too-small`. Worst-state order, worst first:
  `unknown-marker`, `no-psn`, `too-wide`/`too-small`, `tracking`, `no-marker`, `disarmed`, `offline`.
- Group programming must be **one** selection then the attribute commands: build `programCommands` for
  a fid list (`Fixture a + b + c`, then the same `Attribute …` lines), and `releaseCommands` for a list.
  Covered by tests with the exact command strings; console-checked in the probe.
- *(My call)* Header unchanged. `Status()` logs one line per row, group rows with their counts.

## 8. List editor

- Opened from Setup by a new MessageBox button **Layout rows…** (between "Pick preset…" and Cancel).
- Window "AutoZoom — layout rows": one line per entry (`Group 3  Front truss` / `Fixture 205  Spot 5`),
  each with **/\\**, **\\/** (disabled at the ends) and a **trash** button. Trash asks "Remove <entry>?"
  (Yes/No) before removing. Under the lines: **+** and **Close**. Empty list shows the hint
  "Empty: every XYZ fixture gets its own row".
- **+** opens the picker window in add mode: two tabs **Groups** (group pool tiles) and **Fixtures** (one
  tile per scanned XYZ fixture: fid + name). Tiles toggle on tap and show their order number (1, 2, 3…).
  **Add n** appends the toggled tiles in tap order and returns to the editor; **Cancel** returns without
  change.
- Ticks show what the list already covers (user decision):
  - **Fixtures tab:** green tick = the fixture is already in the list by itself; yellow tick = it is only
    included through a group in the list; nothing = not covered.
  - **Groups tab:** green tick = the group is in the list; nothing otherwise.
  - *(My call)* Green-ticked tiles cannot be toggled (no duplicate entries); a yellow-ticked fixture can
    still be added by itself.
- *(My call)* Edits are saved to config as they are made; on **Close**, if anything changed, the runtime
  runs `RescanLater()` once (rebuilds layout and managed set). Works while running or stopped.

## 9. Architecture notes

- The windows are new to this plugin: port Bake Offset's window helpers to a TS module
  (`src/console/window.ts`). They need the plugin's `signalTable` and component handle, which the chunk
  receives as `...` (Bake Offset: `select(1, ...)` at the top of the file); `main.ts` must capture them.
- Windows are event-driven (signals), not blocking like `MessageBox`. The `Desk` gets callback methods,
  e.g. `openPresetPicker(current, onPick)` and `openRowsEditor(rows, catalog, onChange, onClose)`, with
  a `catalog` of groups and XYZ fixtures provided by a new `Desk.listGroups()` (number, name, fids).
- Pure logic stays testable without UI: list operations (add/move/remove/dedupe), entry resolution to
  fids, group-row aggregation (counts, worst state, marker/programmer summary) and the new cells in
  `ui/view-model.ts`, group commands in `engine/program.ts`.
- Tests: `ma3mock.lua` gains UI objects (adapt Bake Offset's `test/ui_smoke_test.lua` approach: click a
  signal by name), groups, and selection; `fakedesk.lua` gains the new `Desk` methods.
- *(My call)* Version 2.1.0.0 (`package.json`, the startup `Printf`, the checklist header).

## 10. Left to the builder

Window sizes, tile counts per row, colours (reuse `COLORS`/appearances), exact cell widths, module and
function names beyond those named above, how the probe is laid out, test structure.
