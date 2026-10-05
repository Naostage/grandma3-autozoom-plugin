# AutoZoom — Simplification (no Capture, armed by default, pick in Setup) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Implement spec §15.3: remove Capture, store disarmed fixtures (armed by default), move the preset pick into the Setup dialog, put Rescan in the layout header, version 2.0.0.2.

**Spec:** `docs/superpowers/specs/2026-10-03-autozoom-layout-ux-design.md` §15.3 (binding).

## Global Constraints

- Every `src` file starts with `/** @noSelfInFile */`; never enable tstl `noImplicitSelf`; only `src/console/` calls the grandMA3 API; every public `AutoZoom` command starts with `if (!this.ensureCurrent()) return;`.
- `npm test` passes after each task (`nix shell nixpkgs#nodejs_22 nixpkgs#lua5_4 -c sh -c 'npm test'`, currently 119/119); `nix shell nixpkgs#lua5_5 -c luac -p out/autozoom-grandma3.lua` passes; commit `out/` with each task; commits without attribution lines.
- Remove dead code with the feature (no unused Desk methods, console functions, mocks or tests left behind).

## Review Focus

1. **Config saved by an older build (`armed` list, no `disarmed`)** → all fixtures armed, no error. Test in Task 1.
2. **A disarmed fixture removed from the patch** → dropped from `disarmed` on Rescan (prune). Test in Task 1.
3. **Rescan tapped while running** → layout rebuilt, loop keeps running, no duplicate cells. Test in Task 2.
4. **Pick preset chosen in Setup while AutoZoom is stopped** → refused with "Start AutoZoom to pick a preset" (existing PickOffset rule). Test in Task 2.

---

### Task 1: Armed by default

**Files:** `src/store/config.ts`, `src/runtime/autozoom.ts`, `tests/config_test.lua`, `tests/runtime_test.lua` (and any other test asserting `armed` in saved config), `tests/lib/fakedesk.lua` if needed.

- [ ] **Step 1: Failing tests**
  - config: `defaultConfig().disarmed` is `{}`; round trip keeps `disarmed`; `parseConfig('{"armed":[101]}')` → `disarmed = {}` (old field ignored, all armed); `pruneConfig` drops missing fids from `disarmed`; `serializeConfig` writes `disarmed` and no `armed`.
  - runtime: after Install with no saved config, every scanned fixture is armed (layout `arm` cells use the `tracking` appearance); `ArmToggle(101)` disarms 101 and saves `disarmed = {101}`; `ArmToggle(101)` again re-arms; `Arm("101")` with fixtures 101,102 → `disarmed = {102}`; `ArmAll()` → `{}`; `DisarmAll()` → all fids; a config with `disarmed = {555}` (fixture not patched) is pruned to `{}` on Install. Update existing runtime tests that relied on "disarmed by default" (e.g. call `DisarmAll()` first where a test needs a disarmed fixture).
- [ ] **Step 2: RED** — `nix shell nixpkgs#nodejs_22 nixpkgs#lua5_4 -c sh -c 'npm run build:test && lua tests/run.lua'`.
- [ ] **Step 3: Implement**
  - `Config`: replace `armed: number[]` with `disarmed: number[]` (comment: fixtures excluded from AutoZoom; every other scanned fixture is armed). `defaultConfig`, `parseConfig` (read `raw.disarmed` the way `armed` was read; ignore `raw.armed`), `serializeConfig`, `pruneConfig` updated.
  - `AutoZoom.isArmed(fid)` → `this.config.disarmed.indexOf(fid) < 0`.
  - `setArmed(fids)` keeps its signature (the list of fixtures that should be armed): compute `disarmed = scanned fids not in normalizeFids(fids)`; unknown fids still logged as before.
  - `ArmToggle(fid)`: toggle membership of `fid` in `disarmed` (unknown fixture → existing log).
  - `ArmAll` → `disarmed = []`; `DisarmAll` → all scanned fids. `Status` prints the armed count as `scanned − disarmed`.
- [ ] **Step 4: GREEN** — full `npm test`; Lua 5.5 `luac -p`.
- [ ] **Step 5: Commit** — `git add src tests out && git commit -m "Fixtures are armed by default; config stores disarmed fixtures"`

### Task 2: Remove Capture, pick in Setup, Rescan cell, version 2.0.0.2

**Files:** `src/runtime/autozoom.ts`, `src/desk.ts`, `src/console/ma-desk.ts`, `src/console/cues.ts` (delete), `src/console/ui.ts`, `src/ui/view-model.ts`, `src/engine/arm-command.ts` (remove `rewriteCueCommand`/`armCommand` if unused after Capture removal; keep `parseArmList`/`normalizeFids`/`formatArmList` if used), `src/store/config.ts` (SetupAnswers gains `pick: boolean`), `src/testing/exports.ts`, `tests/capture_test.lua` (delete), `tests/run.lua`, `tests/lib/fakedesk.lua`, `tests/lib/ma3mock.lua`, `tests/console_desk_test.lua`, `tests/view_model_test.lua`, `tests/commands_test.lua`, `tests/preset_pick_test.lua`, `tests/runtime_test.lua`, `tests/integration_test.lua`, `package.json` (version 2.0.0.2), `src/main.ts` (startup line "AutoZoom 2.0.0.2"), `README.md`, `docs/console-test-checklist.md`.

- [ ] **Step 1: Failing tests**
  - view model: header keys are exactly `status, toggle, setup, rescan, size, message` (in that order); `rescan` command `Rescan()`, appearance `button`; no `capture`, `offset`, `armall`, `disarmall` keys; `HeaderState` has no `captureSecondsLeft`; while a pick is active the `message` cell reads `Tap a preset…  <n> s` (use the existing pick countdown) with the `capture` appearance, otherwise the normal message with `header`.
  - runtime/setup: `desk.setupDialog` returning answers with `pick = true` → no config change from the answers, and `PickOffset()` behaviour starts (message "Tap the preset that holds the XYZ offset", pick active); when stopped → "Start AutoZoom to pick a preset". `pick = false` → existing Save behaviour.
  - console: `setupDialog` MessageBox has three commands: Save (1), Pick preset… (2), Cancel (0); result 2 → answers with `pick = true` (inputs still read); result 0 → undefined.
  - Rescan from the layout while running: Rescan() rebuilds the layout (fake desk `cells` replaced, same count), loop still running (`d.loop` not nil).
  - Delete `tests/capture_test.lua` and its FILES entry; remove capture assertions elsewhere; remove `rewriteCueCommand`/`armCommand` tests if those functions are removed.
- [ ] **Step 2: RED** — as Task 1.
- [ ] **Step 3: Implement**
  - Runtime: delete `Capture`, `storeArms`, `endCapture`, `captureUntil`, `captureStartId`, `CAPTURE_SECONDS`, capture handling in `beforeUpdate`/`Stop`/`render`. `Setup()`: if `answers.pick` → call `this.PickOffset()` (do not apply the other answers) else existing logic. Keep `PickOffset()` public.
  - Desk: remove `selectedSequence`, `runningCue`, `selectedCue`, `readCueCommand`, `writeCueCommand` from the interface, `MaDesk`, the fake desk; delete `src/console/cues.ts` and its mock-only helpers/tests (`HandleToStr`/`StrToHandle`/`SelectedSequence` mock globals may stay only if still used elsewhere).
  - `SetupAnswers` gains `pick: boolean`; `src/console/ui.ts` `setupDialog`: commands `[{value:1,name:"Save"},{value:2,name:"Pick preset…"},{value:0,name:"Cancel"}]`; result 1 or 2 → answers (`pick = r.result === 2`), else undefined.
  - View model: header list `[["status",""],["toggle","Toggle()"],["setup","Setup()"],["rescan","Rescan()"],["size",""],["message",""]]`; `rescan` cell text `Rescan\npatch` with appearance `button`; message cell shows the pick countdown while picking (HeaderState keeps `pickSecondsLeft`), else the message.
  - `arm-command.ts`: remove functions that no longer have callers (and their exports/tests); `Arm(list)` still uses `parseArmList`.
  - Version: package.json `2.0.0.2`, main.ts startup line `AutoZoom 2.0.0.2 by Naostage`, checklist item 1.
  - README: remove the Capture and Offset-cell bullets; Setup bullet mentions **Pick preset…**; header described as Status · Start/Stop · Setup · Rescan · AZ_SIZE · message; fixtures armed by default (tap Arm to exclude one). Checklist: remove items 8, 9 (Capture) and the Offset-cell wording in 24–27 (now "Setup → Pick preset…"); add "Rescan cell rebuilds the layout while running"; add "New fixtures are armed by default".
- [ ] **Step 4: GREEN** — full `npm test`; Lua 5.5 `luac -p out/autozoom-grandma3.lua`.
- [ ] **Step 5: Commit** — `git add -A src tests out package.json README.md docs && git commit -m "Remove Capture, pick preset from Setup, Rescan cell; version 2.0.0.2"`
