# AutoZoom — BeatGrid-style layout cells Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Layout cells show coloured fills on the console: copy BeatGrid 1.2 — every cell is a sequence in the AutoZoom pool whose `Appearance` the plugin sets from the cell's state; the AZ appearances live in a contiguous block of high pool numbers ("far": from 9001).

**Why:** On grandMA3 2.5.1.0 the 2.0.0.1 build showed macro-bound cells with the macro's "paper" appearance and no fill. BeatGrid (working on the console) binds cells to sequences, leaves `el.Appearance = nil`, and colours via `seq.Appearance` / cue-part appearances created in `ShowData().Appearances`.

**Spec:** `docs/superpowers/specs/2026-10-03-autozoom-layout-ux-design.md` §15.1 (amended by Task 1 Step 5).

## Global Constraints

- Every `src` file starts with `/** @noSelfInFile */`; never enable tstl `noImplicitSelf`; only `src/console/` calls the grandMA3 API.
- Appearance names/colours: exactly `APPEARANCES` in `src/ui/view-model.ts` (unchanged).
- `npm test` passes (`nix shell nixpkgs#nodejs_22 nixpkgs#lua5_4 -c sh -c 'npm test'`, currently 107/107); commit `out/` with the change; commits without attribution lines.

## Review Focus

1. **AZ appearances already exist at low numbers (2.0.0.1 build)** → they are deleted and recreated in the far block; nothing else in the pool is touched. Test: `low AZ appearance is moved to the far block`.
2. **Far block partly occupied by the operator's appearances** → the block starts at the first free run of 9 consecutive numbers ≥ 9001; operator appearances are never overwritten. Test: `far block skips occupied numbers`.
3. **A cell sequence deleted by the operator** → refresh skips it silently; Rescan recreates it. Test: `deleted cell sequence is skipped`.

---

### Task 1: Sequences as cells, far appearances

**Files:**
- Modify: `src/console/appearances.ts`, `src/console/layout.ts`, `src/console/pool.ts`, `tests/lib/ma3mock.lua`, `tests/console_desk_test.lua`, `tests/integration_test.lua` (if it references cell macros), `docs/superpowers/specs/2026-10-03-autozoom-layout-ux-design.md`, `README.md`, `docs/console-test-checklist.md`

**Interfaces:**
- `src/console/appearances.ts`: `export const APPEARANCE_BASE = 9001;` `ensureAppearances(): void` (now places missing/low ones in the far block), `appearanceHandle(kind)` unchanged.
- `src/console/pool.ts`: `export function ensureCellSequence(name: string, luaCall: string): any` (BeatGrid `ensureSeq` pattern) and `export function cellSequenceName(key: string): string` → `"AZ " + key`. `ensureMacro` is removed (only `ensureRawMacro` for AZ Start remains).
- `src/console/layout.ts`: `buildLayout(cells)` binds each element to its cell sequence; `refreshLayout(views)` writes the text on the element and the appearance on the **sequence** (`seq.Appearance = appearanceHandle(kind)`), never on the element.

- [ ] **Step 1: Failing tests** (tests/console_desk_test.lua; adapt existing appearance/layout tests to the new behaviour)

Mock additions (tests/lib/ma3mock.lua):
- `M.appearances` gets `No`-numbered children: `Acquire()` assigns `No = (max existing No) + 1`; add `Resize(n)` (records `M.appearances.size = n`) and `Create(no, class)` returning a new handle with `No = no` (inserted in `_kids`), `GetChildClass()` returning `"Appearance"`, and `Delete(no)` removing the child with that `No` (mark `_deleted`).
- Sequences pool: `Acquire()` returns a new sequence handle (same shape as `M.sequence`, name ""), and sequence handles get `Append()` (returns a new cue handle with `Create(i)` returning a part handle `{ Command = "" }` appended to the cue's `_kids`).

Tests:

```lua
T.test("far block holds the nine AZ appearances", function()
  M.reset()
  local desk = az().madesk.createMaDesk()
  desk:install({ fixtures = {}, markers = {}, problems = {} })
  local nos = {}
  for _, a in ipairs(M.appearances._kids) do if a.name:sub(1, 3) == "AZ " then nos[#nos + 1] = a.No end end
  table.sort(nos)
  T.eq(#nos, 9, "nine"); T.eq(nos[1], 9001, "first"); T.eq(nos[9], 9009, "contiguous")
end)

T.test("far block skips occupied numbers", function()
  M.reset()
  M.appearances._kids[#M.appearances._kids + 1] = M.handle({ name = "Mine", No = 9003 }, {})
  local desk = az().madesk.createMaDesk()
  desk:install({ fixtures = {}, markers = {}, problems = {} })
  local mine = 0
  for _, a in ipairs(M.appearances._kids) do if a.No == 9003 then mine = mine + 1; T.eq(a.name, "Mine", "untouched") end end
  T.eq(mine, 1, "no overwrite")
  for _, a in ipairs(M.appearances._kids) do if a.name == "AZ Tracking" then T.truthy(a.No >= 9004, "after the occupied number") end end
end)

T.test("low AZ appearance is moved to the far block", function()
  M.reset()
  M.appearances._kids[#M.appearances._kids + 1] = M.handle({ name = "AZ Tracking", No = 7, IMAGERGBA = "137A38E0" }, {})
  M.appearances._kids[#M.appearances._kids + 1] = M.handle({ name = "Other", No = 8 }, {})
  local desk = az().madesk.createMaDesk()
  desk:install({ fixtures = {}, markers = {}, problems = {} })
  local low, other = false, false
  for _, a in ipairs(M.appearances._kids) do
    if a.name == "AZ Tracking" and a.No < 9001 then low = true end
    if a.name == "Other" then other = true end
  end
  T.eq(low, false, "moved"); T.eq(other, true, "others kept")
end)

T.test("cells are sequences coloured through the sequence appearance", function()
  M.reset()
  local desk = az().madesk.createMaDesk()
  desk:install({ fixtures = {}, markers = {}, problems = {} })
  desk:buildLayout({ { key = "toggle", x = 0, y = 0, w = 100, h = 60, command = "Toggle()" }, { key = "status", x = 110, y = 0, w = 100, h = 60, command = "" } })
  local pool = M.dataPools._kids[1]
  local function seqNamed(n) for _, s in ipairs(pool.Sequences._kids) do if s.name == n then return s end end end
  local toggle, status = seqNamed("AZ toggle"), seqNamed("AZ status")
  T.truthy(toggle, "toggle sequence"); T.truthy(status, "status sequence")
  local el = pool.Layouts._kids[1]._kids[1]
  T.eq(el.Object, toggle, "element bound to the sequence"); T.eq(el.Appearance, nil, "element appearance left empty")
  local cue = toggle._kids[#toggle._kids]
  T.eq(cue._kids[1].Command, [[Lua "if AZ then AZ:Toggle() end"]], "cue command")
  T.eq(#pool.Macros._kids, 1, "only AZ Start remains as a macro")
  desk:refreshLayout({ toggle = { text = "Stop", border = "3ECF6EFF", textColor = "E6E8EBFF", appearance = "button" } })
  T.eq(toggle.Appearance.name, "AZ Button", "sequence coloured"); T.eq(el.CustomTextText, "Stop", "text on element")
  desk:refreshLayout({ toggle = { text = "Stop", border = "3ECF6EFF", textColor = "E6E8EBFF", appearance = "error" } })
  T.eq(toggle.Appearance.name, "AZ Error", "switched")
end)

T.test("deleted cell sequence is skipped", function()
  M.reset()
  local desk = az().madesk.createMaDesk()
  desk:install({ fixtures = {}, markers = {}, problems = {} })
  desk:buildLayout({ { key = "toggle", x = 0, y = 0, w = 100, h = 60, command = "Toggle()" } })
  local pool = M.dataPools._kids[1]
  for i, s in ipairs(pool.Sequences._kids) do if s.name == "AZ toggle" then s._deleted = true; table.remove(pool.Sequences._kids, i) break end end
  desk:refreshLayout({ toggle = { text = "Stop", border = "3ECF6EFF", textColor = "E6E8EBFF", appearance = "button" } })
end)
```

Remove/replace the earlier tests that asserted `el.Appearance.name` on the element or counted cell macros.

- [ ] **Step 2: Run to verify they fail** — `nix shell nixpkgs#nodejs_22 nixpkgs#lua5_4 -c sh -c 'npm run build:test && lua tests/run.lua'`.

- [ ] **Step 3: Implement**

`src/console/appearances.ts` — keep `findByName`/cache/`appearanceHandle`; rewrite `ensureAppearances`:

```ts
export const APPEARANCE_BASE = 9001;

function occupied(): { [no: string]: boolean } {
    const out: { [no: string]: boolean } = {};
    for (const a of children(pool())) {
        const n = num(a.No);
        if (n !== undefined) out[fmtInt(n)] = true;
    }
    return out;
}

// First run of `count` free numbers at or above APPEARANCE_BASE (BeatGrid's findContiguousBase, started far up).
function farBase(count: number): number {
    const used = occupied();
    let start = APPEARANCE_BASE;
    let run = 0;
    for (let n = APPEARANCE_BASE; n < APPEARANCE_BASE + 10000; n++) {
        if (used[fmtInt(n)]) { run = 0; start = n + 1; continue; }
        run++;
        if (run === count) return start;
    }
    return start;
}

function createAt(no: number, name: string): any {
    const p = pool();
    if (no > p.Count()) p.Resize(no);
    const app = p.Create(no, p.GetChildClass());
    app.Name = name;
    return app;
}

export function ensureAppearances(): void {
    const kinds: string[] = [];
    for (const kind in APPEARANCES) kinds.push(kind);
    kinds.sort();
    // AZ appearances created below the far block (2.0.0.1 build) are removed and recreated far up.
    for (const kind of kinds) {
        const app = findByName(APPEARANCES[kind].name);
        const n = app === undefined ? undefined : num(app.No);
        if (app !== undefined && n !== undefined && n < APPEARANCE_BASE) pool().Delete(n);
    }
    const missing = kinds.filter(k => findByName(APPEARANCES[k].name) === undefined);
    let next = missing.length > 0 ? farBase(missing.length) : 0;
    for (const kind of kinds) {
        const spec = APPEARANCES[kind];
        let app = findByName(spec.name);
        if (app === undefined) {
            app = createAt(next, spec.name);
            next++;
        }
        if (app.IMAGERGBA !== spec.rgba) app.IMAGERGBA = spec.rgba;
        cache[kind] = app;
    }
}
```

(import `num` from `./handles`, `fmtInt` from `../format`.)

`src/console/pool.ts` — replace `ensureMacro` with BeatGrid's `ensureSeq` pattern:

```ts
export function cellSequenceName(key: string): string {
    return "AZ " + key;
}

// Layout cell = sequence (BeatGrid): cue 1 part 0 runs AZ:<luaCall>; display-only cells have no command.
export function ensureCellSequence(name: string, luaCall: string): any {
    const dp = ensurePool();
    const command = luaCall === "" ? "" : `Lua "if AZ then AZ:${luaCall} end"`;
    let seq = findSequence(name);
    if (seq === undefined) {
        seq = dp.Sequences.Acquire();
        seq.Name = name;
        const cue = seq.Append();
        cue.No = 1;
        const part = cue.Create(1);
        part.Command = command;
        return seq;
    }
    const cues = children(seq);
    const cue = cues[cues.length - 1];
    const part = cue === undefined ? undefined : children(cue)[0];
    if (part !== undefined && tostring(part.Command ?? "") !== command) part.Command = command;
    return seq;
}
```

`src/console/layout.ts`:
- `buildLayout`: replace the macro lines with `const seq = ensureCellSequence(cellSequenceName(cell.key), cell.command); el.Object = seq; el.Action = cell.command === "" ? "Pause" : "Go+";` (BeatGrid uses Pause for non-clickable cells). Keep `hideDetails(el)`; do NOT set `el.Appearance`. Keep `sequences[cell.key] = seq` in a new module map (reset with `elements`).
- `findElements`: also rebuild `sequences` from each element's `el.Object`.
- `refreshLayout`: keep text writes on the element; replace the element appearance write with:
  ```ts
  const seq = sequences[key];
  const app = appearanceHandle(view.appearance);
  if (seq !== undefined && IsObjectValid(seq) && app !== undefined) seq.Appearance = app;
  ```
  An invalid/missing sequence is skipped silently (text still written).
- Remove `macroName`.

`src/console/ma-desk.ts`: unchanged (AZ Start via `ensureRawMacro`).

- [ ] **Step 4: Run tests** — `nix shell nixpkgs#nodejs_22 nixpkgs#lua5_4 -c sh -c 'npm test'`.

- [ ] **Step 5: Docs** —
  - Spec §15.1: replace "el.Appearance is set to the cell's appearance" with "every cell is a sequence `AZ <key>` in the AutoZoom pool (cue 1 runs the cell's command; display-only cells have none, element Action Pause); the plugin sets the sequence's Appearance when the cell's kind changes; element Appearance stays empty (BeatGrid model)". Add: "the AZ appearances occupy a contiguous block of free numbers from 9001; AZ appearances found below 9001 are recreated there".
  - README "Colours" bullet: same facts in one or two sentences; mention cells are `AZ …` sequences in the AutoZoom pool (running ones were tapped).
  - Checklist item 22 → "Cells show tinted fills (no paper icon); colours follow state"; item 23 → "Appearances pool holds the nine AZ appearances at 9001+ once; Rescan neither duplicates nor moves them again".

- [ ] **Step 6: Commit**

```bash
git add src tests out README.md docs
git commit -m "Layout cells are BeatGrid-style sequences; AZ appearances stored from 9001"
```
