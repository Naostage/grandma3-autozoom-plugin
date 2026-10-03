# AutoZoom 2.0 Layout UX Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild the AutoZoom grandMA3 plugin around a plugin-generated Layout, live "follow the console" marker/offset reads, arm recall from cues (Capture), tap-to-program and settings saved with the show.

**Architecture:** A pure core (engine math and state machine, config, view model) and a `runtime` (`AutoZoom` class, the global `AZ`) that talks to the console only through a `Desk` interface. `MaDesk` (in `src/console/`) is the only code touching the grandMA3 API. The runtime is tested in Lua against a fake desk; the console layer against a small grandMA3 mock; the full bundle in one integration test.

**Tech Stack:** TypeScript → Lua via TypeScriptToLua (`tstl`), `grandma3-ts-types`, `lua-types`; tests in plain Lua (5.3+) run by `tests/run.lua`.

**Spec:** `docs/superpowers/specs/2026-10-03-autozoom-layout-ux-design.md`

## Global Constraints

- Target grandMA3 2.5.x (Lua 5.5 runtime). Generated Lua must not use `global` as an identifier nor assign to `for` loop variables.
- Only files in `src/console/` call the grandMA3 API. Never index a grandMA3 collection by number: iterate `Children()`.
- Markers are keyed by **CID**, fixtures by **FID**; map keys are strings made with `fidKey()`.
- Every object the plugin creates lives in DataPool `AutoZoom`.
- The global command object is `AZ`; public commands are `Lua "AZ:<Command>(...)"` (methods on the `AutoZoom` class, PascalCase).
- Config is one JSON string in `GlobalVars` key `AutoZoom.config`; the live instance id is in `GlobalVars` key `AutoZoom.instance`.
- Layout colours are hex RGBA strings (`"3ECF6EFF"`).
- No backward compatibility with 1.x (commands, object names, datapool option).
- After every task `npm test` passes. Tooling: `nix shell nixpkgs#nodejs_22 nixpkgs#lua5_4` gives `npm`, `npx` and `lua` on this machine.
- Commit after each task. Commit messages have no attribution lines.
- tstl option `noImplicitSelf: true`: plain functions take no `self`; class and interface **methods** do (called with `:` from Lua).

## Review Focus

1. **A fixture saved as armed is later removed from the patch** → it disappears from the config on the next Rescan, no error. Test in Task 8 (`armed fixture removed from patch is dropped`).
2. **Capture when the target sequence is already the selected one** → selecting it again cannot be detected; the user must be told to select another sequence first, and the message must say so. Test in Task 9 (`capture start explains how to pick an already selected sequence`).
3. **A cue stores `AZ:Arm('')` (nothing armed)** → every fixture is disarmed, no error. Test in Task 6 (`empty arm list`) and Task 8 (`Arm('') disarms all`).
4. **Fixture exactly at the aim point (distance 0)** → "Too wide", zoom 100, never NaN. Test in Task 4 (`zero distance`).
5. **The plugin is run twice, or another show is loaded** → the old instance stops writing faders. Test in Task 8 (`stale instance stops`).

---

## File Structure

```
src/
  main.ts                      plugin entry (replaces old main)
  format.ts                    fmtInt, fmtNum, fidKey
  model.ts                     shared data types (patch, readings, cells)
  desk.ts                      Desk interface
  engine/vec.ts                Vec3 math
  engine/beam.ts               zoom/iris math
  engine/fixture-state.ts      per-fixture state machine
  engine/arm-command.ts        AZ:Arm formatting/parsing, cue command rewrite
  engine/program.ts            tap-to-program command lists
  store/json.ts                minimal JSON
  store/config.ts              Config, validation, setup answers
  ui/view-model.ts             layout geometry + cell views
  runtime/autozoom.ts          AutoZoom class (global AZ)
  console/ma-globals.d.ts      typings for grandMA3 globals not in grandma3-ts-types
  console/handles.ts           children(), num(), findChild()
  console/log.ts               info(), warnOnce()
  console/vars.ts              GlobalVars text I/O
  console/patch.ts             scanPatch()
  console/live.ts              live attribute and PSN reads
  console/pool.ts              DataPool, sequences, macros, faders
  console/cues.ts              selected sequence, cues, cue commands
  console/layout.ts            layout build/refresh
  console/ui.ts                prompt, setup dialog, timers, commands
  console/ma-desk.ts           MaDesk implements Desk
  testing/exports.ts           test bundle entry
tests/
  run.lua                      runs every *_test.lua listed in it
  lib/t.lua                    tiny test framework
  lib/az.lua                   loads build/azlib.lua once
  lib/fakedesk.lua             Desk fake for runtime tests
  lib/ma3mock.lua              grandMA3 API mock for console tests
  *_test.lua
spikes/ma3-probe/azprobe2.lua  console probe 2 (Task 1, not shipped)
```

Removed in Task 13: `src/autozoom_object.ts`, `src/calculate-zoom-iris.ts`, `src/create-macros.ts`, `src/handle-execs.ts`, `src/load-patch.ts`, `src/macros.ts`, `src/types.ts`, `src/utils.ts`, `tests/harness.lua`.

---

### Task 1: Console probe 2 (P1–P11)

Answers the spec's open questions on the user's onPC 2.5.0.3. The engineer writes the probe; the **user** runs it on the console; the engineer records results. Later tasks reference the results file by question number.

**Files:**
- Create: `spikes/ma3-probe/azprobe2.lua`, `spikes/ma3-probe/azprobe2.xml` (untracked, like probe 1)
- Create: `docs/superpowers/specs/2026-10-03-probe-2-results.md`

**Interfaces:**
- Produces: `docs/superpowers/specs/2026-10-03-probe-2-results.md` with one section per P1–P11 containing the observed values. Tasks 10–12 read: P1 `XYZ_RAW_PER_METRE`, P2 rotation yes/no + tracker rotation property names, P3/P4/P5 exact command syntax, P6 running/selected cue accessors, P7 cue command property, P8 selection behaviour, P9 parent/rotation property names and fixture mode accessor, P10 layout Y direction / multi-line text / click / fractional fader, P11 MessageBox return shape.

- [ ] **Step 1: Write the probe**

```lua
-- THROWAWAY probe 2 for AutoZoom 2.0 (answers spec P1–P11). Run once, then the AZQ.* commands.
AZQ = AZQ or {}
local _, _, _, PLUGIN = ...

local function log(fmt, ...) Printf("[AZQ] " .. (select("#", ...) > 0 and string.format(fmt, ...) or tostring(fmt))) end
local function dump(v, d) d = d or 2; if type(v) ~= "table" or d == 0 then return tostring(v) end
  local p = {} for k, x in pairs(v) do p[#p + 1] = tostring(k) .. "=" .. dump(x, d - 1) end return "{" .. table.concat(p, ", ") .. "}" end
local function try(label, fn, ...) local r = table.pack(pcall(fn, ...))
  if r[1] then local o = {} for i = 2, r.n do o[#o + 1] = dump(r[i]) end log("%s -> %s", label, table.concat(o, ", ")) return r[2] end
  log("%s -> ERROR %s", label, tostring(r[2])) end

local function sub(fid)
  for i = 0, GetSubfixtureCount() do local ok, sf = pcall(GetSubfixture, i)
    if ok and sf and tostring(sf.fid) == tostring(fid) then return i, sf end end
end
local function uich(fid, attr) local i = sub(fid); return GetUIChannelIndex(i, GetAttributeIndex(attr)) end
local function raw(fid, attr) local rt = GetRTChannel(uich(fid, attr)); return rt and rt.info and rt.info.value_after_master, rt and rt.info and tostring(rt.info.cue_part) end

-- P1: set XYZ_X=1, XYZ_Y=-2, XYZ_Z=0.5 on fixture fid in the programmer first
function AZQ.P1(fid)
  for _, a in ipairs({ "XYZ_X", "XYZ_Y", "XYZ_Z", "XYZ_MArker" }) do
    log("GetAttributeIndex(%s) = %s", a, tostring(GetAttributeIndex(a)))
    log("%s raw = %s (source %s)", a, tostring(select(1, raw(fid, a))), tostring(select(2, raw(fid, a))))
  end
end

-- P2: dump PSN trackers (find rotation property names); then compare aim with marker rotated 0 and 90 degrees
function AZQ.P2()
  for _, sys in ipairs(ShowData().PSNProtocol:Children()) do
    for _, t in ipairs(sys:Children()) do log("tracker MARKERID=%s", tostring(t.MARKERID)); t:Dump() end
  end
end

-- P3 + P5: set marker, offset and zoom/iris minimum by command, read back
function AZQ.P3(fid, cid, zoomMin, irisMin)
  local cmds = { "Fixture " .. fid, 'Attribute "XYZ_MArker" At ' .. cid, 'Attribute "XYZ_X" At 1',
    'Attribute "Zoom" At Absolute Physical ' .. zoomMin, 'Attribute "Iris" At Absolute Physical ' .. irisMin }
  for _, c in ipairs(cmds) do log("Cmd(%s) -> %s", c, tostring(Cmd(c))) end
  AZQ.P1(fid)
  log("Zoom raw %s, Iris raw %s", tostring(raw(fid, "Zoom")), tostring(raw(fid, "Iris")))
end

-- P4: recall only XYZ from a preset (a preset holding XYZ values, e.g. "2.12")
function AZQ.P4(fid, preset)
  for _, c in ipairs({ "Fixture " .. fid, 'Attribute "XYZ_X" Thru "XYZ_Z" At Preset ' .. preset }) do
    log("Cmd(%s) -> %s", c, tostring(Cmd(c))) end
  AZQ.P1(fid)
end

local function seqByName(name)
  for _, s in ipairs(DataPool().Sequences:Children()) do if s.name == name then return s end end
end
-- P6: running cue and selected cue (select a cue in the Sequence Sheet first; sequence must be running)
function AZQ.P6(name)
  local s = seqByName(name); if not s then log("no sequence %s", name) return end
  try("CurrentChild()", function() local c = s:CurrentChild(); return c and (tostring(c.no) .. " " .. tostring(c.name)) end)
  try("SelectedSequence()", function() local x = SelectedSequence(); return x and x.name end)
  log("sequence properties dump follows (look for current/selected cue):"); s:Dump()
end

-- P7: read/write the command of cue <no>
function AZQ.P7(name, no)
  local s = seqByName(name); if not s then return end
  for _, cue in ipairs(s:Children()) do
    if tonumber(cue.no) == no then
      local part = cue:Children()[1]
      try("part.Command read", function() return part.Command end)
      try("part.Command write", function() part.Command = 'Lua "AZQ.Hello()"' return part.Command end)
      try("cue.Command read", function() return cue.Command end)
      return
    end
  end
  log("cue %s not found", tostring(no))
end
function AZQ.Hello() log("hello from a cue command") end

-- P8: print SelectedSequence() changes for 20 s; tap pool tiles and executor Select keys
function AZQ.P8()
  local last
  Timer(function() local s = SelectedSequence(); local n = s and s.name
    if n ~= last then log("selected sequence: %s (%s)", tostring(n), s and HandleToStr(s) or "-") last = n end end, 0.1, 200)
end

-- P9: parent chain of a fixture inside a group, with position/rotation/mode properties
function AZQ.P9(fid)
  local _, sf = sub(fid); local h = sf
  while h do
    log("%s POS %s/%s/%s ROT %s/%s/%s mode=%s modeDirect=%s", tostring(h.name), tostring(h.POSX), tostring(h.POSY), tostring(h.POSZ),
      tostring(h.ROTX), tostring(h.ROTY), tostring(h.ROTZ), dump(h.mode, 1), dump(h.ModeDirect, 1))
    h = h:Parent(); if h and h.name == "Fixtures" then break end
  end
end

-- P10: two elements to check Y direction, multi-line text, click; fractional SetFader
function AZQ.P10(n, seqName)
  Cmd("Store Macro 'AZQ Click' /o /nc"); Cmd("Store Macro 'AZQ Click'.1 /o /nc")
  Cmd([[Set Macro 'AZQ Click'.1 Property 'Command' 'Lua "AZQ.Hello()"']])
  Cmd("Store Layout " .. n .. " 'AZQ' /o /nc")
  local layout; for _, l in ipairs(DataPool().Layouts:Children()) do if l.name == "AZQ" then layout = l end end
  local macro; for _, m in ipairs(DataPool().Macros:Children()) do if m.name == "AZQ Click" then macro = m end end
  for i, pos in ipairs({ { 0, 0 }, { 200, 100 } }) do
    local e = layout:Append(); e.Object = macro; e.PosX = pos[1]; e.PosY = pos[2]; e.Width = 150; e.Height = 60
    e.CustomTextText = string.format("E%d at %d/%d\nsecond line", i, pos[1], pos[2]); e.BorderColor = "3ECF6EFF"; e.Note = "AZQ:" .. i
  end
  log("Open layout %d: which element is higher on screen? Is the text on two lines? Click E1 (should print hello)", n)
  local s = seqByName(seqName); if s then s:SetFader({ value = 33.3, token = "FaderTemp" }); try("GetFader temp", function() return s:GetFader({ token = "FaderTemp" }) end) end
end

-- P11: MessageBox with inputs and selectors
function AZQ.P11()
  try("MessageBox", MessageBox, { title = "AZQ setup", message = "Change values, pick Values, press Save",
    commands = { { value = 1, name = "Save" }, { value = 0, name = "Cancel" } },
    inputs = { { name = "Offset X (m)", value = "0" }, { name = "Offset preset", value = "2.12" } },
    selectors = { { name = "Offset source", selectedValue = 1, values = { Preset = 1, Values = 2 } } } })
end

return function() log("Probe 2 loaded: AZQ.P1(fid) P2() P3(fid,cid,zmin,imin) P4(fid,preset) P6(seq) P7(seq,cue) P8() P9(fid) P10(layoutNo,seqName) P11()") end
```

`azprobe2.xml`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<GMA3 DataVersion="2.3.2.0">
<UserPlugin Name="AZ Probe 2" Version="0.0.2" Author="naostage">
    <ComponentLua FileName="azprobe2.lua" />
</UserPlugin>
</GMA3>
```

- [ ] **Step 2: Syntax check**

Run: `luac -p spikes/ma3-probe/azprobe2.lua && echo ok` (inside `nix shell nixpkgs#lua5_4`)
Expected: `ok`

- [ ] **Step 3: Ask the user to run it** on 2.5.0.3 with fixture 101 and marker CID 1, then drop the new system log into `spikes/ma3-probe/`. Give them this list:

```
P1: set 101 XYZ_X=1, XYZ_Y=-2, XYZ_Z=0.5 in the programmer → Lua "AZQ.P1(101)"
P2: Lua "AZQ.P2()" ; then aim 101 at marker 1 with XYZ_Y=1, rotate the marker 90° in PSN/Patch and say if the beam moved
P3: ClearAll → Lua "AZQ.P3(101, 1, 5.5, 0.109)"
P4: make preset 2.12 with only XYZ values (Z=0.3) → ClearAll → Lua "AZQ.P4(101, '2.12')"
P6: run sequence 'TEST' to a cue, select another cue in its Sequence Sheet → Lua "AZQ.P6('TEST')"
P7: Lua "AZQ.P7('TEST', 1)" then Go cue 1 (should print "hello from a cue command")
P8: Lua "AZQ.P8()" then within 20 s tap two sequences in the pool, then an executor Select key
P9: Lua "AZQ.P9(101)"
P10: Lua "AZQ.P10(901, 'TEST')" then look at layout 901 and click E1
P11: Lua "AZQ.P11()" , change values, Save
```

- [ ] **Step 4: Record results** in `docs/superpowers/specs/2026-10-03-probe-2-results.md`, one `## P<n>` section each, with the raw log lines and the decision. Compute `XYZ_RAW_PER_METRE = (raw(XYZ_X=1) - 8388608) / 1`. Record exact working command strings (P3/P4/P5); if a command failed, try the documented alternatives with the user (`At Preset 2.12` after selecting the `XYZ` feature, `Attribute "XYZ_X" + "XYZ_Y" + "XYZ_Z"`) until one works, and record that one.

- [ ] **Step 5: Commit**

```bash
git add docs/superpowers/specs/2026-10-03-probe-2-results.md
git commit -m "Record grandMA3 2.5 probe 2 results"
```

---

### Task 2: Test infrastructure

**Files:**
- Modify: `tsconfig.json`, `package.json`, `.gitignore`
- Create: `tsconfig.test.json`, `src/testing/exports.ts`, `tests/run.lua`, `tests/lib/t.lua`, `tests/lib/az.lua`, `tests/smoke_test.lua`

**Interfaces:**
- Produces: `npm test` (build plugin, build test bundle `build/azlib.lua`, run `lua tests/run.lua` then the old `lua tests/harness.lua`); Lua test API `T.test(name, fn)`, `T.eq(actual, expected, what)`, `T.near(actual, expected, eps, what)`, `T.truthy(v, what)`; `require("az")()` returns the test bundle's exports table. Every later task appends its test file to the `FILES` list in `tests/run.lua` and its modules to `src/testing/exports.ts`.

- [ ] **Step 1: Write the smoke test** `tests/smoke_test.lua`

```lua
local T = require("t")
local az = require("az")

T.test("test bundle loads", function()
  T.eq(az().ready, true, "ready flag")
end)
```

- [ ] **Step 2: Write the runner and helpers**

`tests/run.lua`:

```lua
-- Runs the unit/integration tests. Use: lua tests/run.lua (from the repo root, after `npm run build:test`)
package.path = "tests/?.lua;tests/lib/?.lua;" .. package.path
local T = require("t")

local FILES = {
  "smoke_test",
}

for _, name in ipairs(FILES) do
  print("\n# " .. name)
  dofile("tests/" .. name .. ".lua")
end
T.finish()
```

`tests/lib/t.lua`:

```lua
-- Minimal test framework shared by every *_test.lua file.
local T = { total = 0, failed = 0 }

local function deepEq(a, b)
  if type(a) ~= type(b) then return false end
  if type(a) ~= "table" then return a == b end
  for k, v in pairs(a) do if not deepEq(v, b[k]) then return false end end
  for k in pairs(b) do if a[k] == nil then return false end end
  return true
end

local function show(v, depth)
  depth = depth or 0
  if type(v) ~= "table" or depth > 3 then return tostring(v) end
  local parts = {}
  for k, x in pairs(v) do parts[#parts + 1] = tostring(k) .. "=" .. show(x, depth + 1) end
  table.sort(parts)
  return "{" .. table.concat(parts, ", ") .. "}"
end
T.show = show

function T.test(name, fn)
  T.total = T.total + 1
  local ok, err = xpcall(fn, debug.traceback)
  if ok then print("ok   - " .. name)
  else T.failed = T.failed + 1; print("FAIL - " .. name .. "\n" .. tostring(err)) end
end

function T.eq(actual, expected, what)
  if not deepEq(actual, expected) then
    error((what or "value") .. ": expected " .. show(expected) .. ", got " .. show(actual), 2)
  end
end

function T.near(actual, expected, eps, what)
  if type(actual) ~= "number" or math.abs(actual - expected) > (eps or 1e-6) then
    error((what or "value") .. ": expected ~" .. tostring(expected) .. ", got " .. tostring(actual), 2)
  end
end

function T.truthy(v, what)
  if not v then error((what or "value") .. " should be truthy", 2) end
end

function T.finish()
  print(string.format("\n%d/%d passed", T.total - T.failed, T.total))
  os.exit(T.failed == 0 and 0 or 1)
end

return T
```

`tests/lib/az.lua`:

```lua
-- Loads the test bundle (build/azlib.lua, built by `npm run build:test`) once.
local cached
return function()
  if not cached then cached = dofile("build/azlib.lua") end
  return cached
end
```

- [ ] **Step 3: Run it to verify it fails**

Run: `lua tests/run.lua`
Expected: FAIL — `cannot open build/azlib.lua`

- [ ] **Step 4: Add the test bundle**

`src/testing/exports.ts`:

```ts
// Entry of the test bundle (build/azlib.lua). Each module under test is re-exported here.
export const ready = true;
```

`tsconfig.test.json`:

```json
{
  "include": ["src/**/*"],
  "exclude": ["src/main.ts"],
  "tstl": {
    "luaTarget": "5.3",
    "luaBundleEntry": "./src/testing/exports.ts",
    "luaBundle": "./build/azlib.lua",
    "luaLibImport": "require-minimal",
    "noImplicitSelf": true,
    "noHeader": true
  },
  "compilerOptions": {
    "target": "ESNext",
    "lib": ["ESNext"],
    "moduleResolution": "node",
    "types": ["grandma3-ts-types", "lua-types/5.3"],
    "strict": true
  }
}
```

In `tsconfig.json` add `"noImplicitSelf": true,` inside `"tstl"` (after `"noHeader": true`).

In `package.json` replace `"scripts"` with:

```json
  "scripts": {
    "build": "tstl && node scripts/generateXML.js",
    "build:test": "tstl -p tsconfig.test.json",
    "dev": "tstl --watch",
    "test": "npm run build && npm run build:test && lua tests/run.lua && lua tests/harness.lua"
  },
```

Append to `.gitignore`:

```
build/
other_plugins/
spikes/
```

- [ ] **Step 5: Run the tests**

Run: `npm test`
Expected: `ok   - test bundle loads`, `1/1 passed`, then the old harness `12/12 passed` (the old code still builds with `noImplicitSelf`: it only calls its own functions).

- [ ] **Step 6: Commit**

```bash
git add tsconfig.json tsconfig.test.json package.json .gitignore src/testing tests/run.lua tests/lib tests/smoke_test.lua
git commit -m "Add Lua unit test infrastructure and test bundle"
```

---

### Task 3: Formatting, JSON and config

**Files:**
- Create: `src/format.ts`, `src/store/json.ts`, `src/store/config.ts`, `tests/json_test.lua`, `tests/config_test.lua`
- Modify: `src/testing/exports.ts`, `tests/run.lua` (FILES)

**Interfaces:**
- Produces:
  - `fmtInt(n: number): string` ("101"), `fmtNum(n: number): string` (≤3 decimals, trailing zeros trimmed, "-0" → "0"), `fidKey(fid: number): string`
  - `encode(value: unknown): string`, `decode(text: string): unknown` (throws on invalid input)
  - `type OffsetSource = "preset" | "values"`; `interface Config { armed: number[]; size: { [fid: string]: number }; range: number[]; rate: number; offset: { source: OffsetSource; preset: string; values: number[] } }`
  - `CONFIG_KEY = "AutoZoom.config"`, `INSTANCE_KEY = "AutoZoom.instance"`
  - `defaultConfig(): Config`, `parseConfig(text: string | undefined): { config: Config; warning?: string }`, `serializeConfig(c: Config): string`, `pruneConfig(c: Config, fids: number[]): Config`
  - `interface SetupAnswers { source: OffsetSource; preset: string; x: string; y: string; z: string; min: string; max: string; rate: string }`, `applySetup(c: Config, a: SetupAnswers): { config: Config; errors: string[] }`, `offsetLabel(c: Config): string`

- [ ] **Step 1: Write the failing tests**

`tests/json_test.lua`:

```lua
local T = require("t")
local az = require("az")

T.test("json round trip", function()
  local json = az().json
  local text = json.encode({ v = 1, armed = { 101, 102 }, size = { ["104"] = 1.5 }, name = "a \"b\"\n" })
  T.eq(json.decode(text), { v = 1, armed = { 101, 102 }, size = { ["104"] = 1.5 }, name = "a \"b\"\n" }, "decoded")
end)

T.test("json encodes integers without decimals and sorts keys", function()
  T.eq(az().json.encode({ b = 2, a = 0.5 }), '{"a":0.5,"b":2}', "text")
end)

T.test("json rejects garbage", function()
  local ok = pcall(az().json.decode, "{oops")
  T.eq(ok, false, "pcall result")
end)
```

`tests/config_test.lua`:

```lua
local T = require("t")
local az = require("az")

T.test("format helpers", function()
  local f = az().format
  T.eq(f.fmtInt(101.0), "101", "fmtInt")
  T.eq(f.fmtNum(1.5), "1.5", "fmtNum 1.5")
  T.eq(f.fmtNum(2), "2", "fmtNum 2")
  T.eq(f.fmtNum(0.1094), "0.109", "fmtNum rounds")
  T.eq(f.fmtNum(-0.0001), "0", "fmtNum -0")
  T.eq(f.fidKey(101), "101", "fidKey")
end)

T.test("missing config gives defaults without warning", function()
  local r = az().config.parseConfig(nil)
  T.eq(r.config.rate, 30, "rate"); T.eq(r.config.range, { 0.5, 5 }, "range"); T.eq(r.warning, nil, "warning")
end)

T.test("config round trip", function()
  local c = az().config
  local cfg = c.defaultConfig()
  cfg.armed = { 101, 103 }; cfg.size["104"] = 1.5; cfg.offset.source = "preset"; cfg.offset.preset = "2.12"
  T.eq(c.parseConfig(c.serializeConfig(cfg)).config, cfg, "config")
end)

T.test("unreadable config warns and falls back", function()
  local r = az().config.parseConfig("not json")
  T.truthy(r.warning, "warning"); T.eq(r.config.armed, {}, "armed")
end)

T.test("invalid fields fall back individually", function()
  local r = az().config.parseConfig('{"armed":[101,"x"],"rate":500,"range":[3,1],"size":{"104":-1,"105":2}}')
  T.eq(r.config.armed, { 101 }, "armed"); T.eq(r.config.rate, 30, "rate")
  T.eq(r.config.range, { 0.5, 5 }, "range"); T.eq(r.config.size, { ["105"] = 2 }, "size")
end)

T.test("prune drops fixtures that left the patch", function()
  local c = az().config
  local cfg = c.defaultConfig(); cfg.armed = { 101, 999 }; cfg.size["999"] = 2; cfg.size["101"] = 1
  local p = c.pruneConfig(cfg, { 101, 102 })
  T.eq(p.armed, { 101 }, "armed"); T.eq(p.size, { ["101"] = 1 }, "size")
end)

T.test("applySetup validates answers", function()
  local c = az().config
  local r = c.applySetup(c.defaultConfig(), { source = "values", preset = "", x = "0", y = "-1", z = "0.3", min = "1", max = "4", rate = "25" })
  T.eq(r.config.offset.values, { 0, -1, 0.3 }, "values"); T.eq(r.config.range, { 1, 4 }, "range"); T.eq(r.config.rate, 25, "rate"); T.eq(r.errors, {}, "errors")
  local bad = c.applySetup(c.defaultConfig(), { source = "preset", preset = "", x = "a", y = "0", z = "0", min = "5", max = "1", rate = "0" })
  T.eq(#bad.errors, 4, "errors: preset empty, x, range, rate"); T.eq(bad.config.offset.source, "values", "source kept")
  T.eq(c.offsetLabel(r.config), "0/-1/0.3 m", "label values")
end)
```

Add `"json_test", "config_test",` to `FILES` in `tests/run.lua`.

- [ ] **Step 2: Run to verify they fail**

Run: `npm run build:test && lua tests/run.lua`
Expected: FAIL — `attempt to index a nil value (field 'json')`

- [ ] **Step 3: Implement**

`src/format.ts`:

```ts
// Number formatting for command lines, layout texts and config keys.

export function fmtInt(n: number): string {
    return string.format("%d", Math.floor(n + 0.5));
}

export function fmtNum(n: number): string {
    let s = string.format("%.3f", n);
    while (s.endsWith("0")) s = s.substring(0, s.length - 1);
    if (s.endsWith(".")) s = s.substring(0, s.length - 1);
    return s === "-0" ? "0" : s;
}

export function fidKey(fid: number): string {
    return fmtInt(fid);
}
```

`src/store/json.ts`:

```ts
// Minimal JSON for the config stored in GlobalVars.
// Lua cannot tell an empty array from an empty object: both encode as [] and decode to an empty table.

export function encode(value: unknown): string {
    if (value === undefined || value === null) return "null";
    if (typeof value === "boolean") return value ? "true" : "false";
    if (typeof value === "number") {
        if (value !== value || value === Infinity || value === -Infinity) return "null";
        return Math.floor(value) === value && Math.abs(value) < 1e15 ? string.format("%d", value) : string.format("%.10g", value);
    }
    if (typeof value === "string") return encodeString(value);
    if (Array.isArray(value)) {
        const parts: string[] = [];
        for (const item of value) parts.push(encode(item));
        return "[" + parts.join(",") + "]";
    }
    const obj = value as { [key: string]: unknown };
    const keys: string[] = [];
    for (const key in obj) keys.push(key);
    keys.sort();
    const parts: string[] = [];
    for (const key of keys) parts.push(encodeString(key) + ":" + encode(obj[key]));
    return "{" + parts.join(",") + "}";
}

function encodeString(s: string): string {
    let out = "\"";
    for (let i = 0; i < s.length; i++) {
        const c = s.charAt(i);
        if (c === "\"") out += "\\\"";
        else if (c === "\\") out += "\\\\";
        else if (c === "\n") out += "\\n";
        else if (c === "\r") out += "\\r";
        else if (c === "\t") out += "\\t";
        else out += c;
    }
    return out + "\"";
}

interface Cursor { s: string; i: number }

export function decode(text: string): unknown {
    const c: Cursor = { s: text, i: 0 };
    const value = parseValue(c);
    skipSpace(c);
    if (c.i < c.s.length) throw new Error("unexpected text at " + c.i);
    return value;
}

function skipSpace(c: Cursor): void {
    while (c.i < c.s.length) {
        const ch = c.s.charAt(c.i);
        if (ch !== " " && ch !== "\n" && ch !== "\r" && ch !== "\t") return;
        c.i++;
    }
}

function expectWord(c: Cursor, word: string): void {
    if (c.s.substring(c.i, c.i + word.length) !== word) throw new Error("expected " + word + " at " + c.i);
    c.i += word.length;
}

function parseValue(c: Cursor): unknown {
    skipSpace(c);
    const ch = c.s.charAt(c.i);
    if (ch === "{") return parseObject(c);
    if (ch === "[") return parseArray(c);
    if (ch === "\"") return parseString(c);
    if (ch === "t") { expectWord(c, "true"); return true; }
    if (ch === "f") { expectWord(c, "false"); return false; }
    if (ch === "n") { expectWord(c, "null"); return undefined; }
    return parseNumber(c);
}

function parseNumber(c: Cursor): number {
    const start = c.i;
    while (c.i < c.s.length && "+-0123456789.eE".indexOf(c.s.charAt(c.i)) >= 0) c.i++;
    if (c.i === start) throw new Error("unexpected character at " + start);
    const n = Number(c.s.substring(start, c.i));
    if (n !== n) throw new Error("bad number at " + start);
    return n;
}

function parseString(c: Cursor): string {
    c.i++;
    let out = "";
    while (c.i < c.s.length) {
        const ch = c.s.charAt(c.i);
        c.i++;
        if (ch === "\"") return out;
        if (ch === "\\") {
            const e = c.s.charAt(c.i);
            c.i++;
            if (e === "n") out += "\n";
            else if (e === "r") out += "\r";
            else if (e === "t") out += "\t";
            else out += e;
        } else {
            out += ch;
        }
    }
    throw new Error("unterminated string");
}

function parseArray(c: Cursor): unknown[] {
    c.i++;
    const out: unknown[] = [];
    skipSpace(c);
    if (c.s.charAt(c.i) === "]") { c.i++; return out; }
    while (true) {
        out.push(parseValue(c));
        skipSpace(c);
        const ch = c.s.charAt(c.i);
        c.i++;
        if (ch === "]") return out;
        if (ch !== ",") throw new Error("expected , or ] at " + (c.i - 1));
    }
}

function parseObject(c: Cursor): { [key: string]: unknown } {
    c.i++;
    const out: { [key: string]: unknown } = {};
    skipSpace(c);
    if (c.s.charAt(c.i) === "}") { c.i++; return out; }
    while (true) {
        skipSpace(c);
        if (c.s.charAt(c.i) !== "\"") throw new Error("expected key at " + c.i);
        const key = parseString(c);
        skipSpace(c);
        if (c.s.charAt(c.i) !== ":") throw new Error("expected : at " + c.i);
        c.i++;
        const value = parseValue(c);
        if (value !== undefined) out[key] = value;
        skipSpace(c);
        const ch = c.s.charAt(c.i);
        c.i++;
        if (ch === "}") return out;
        if (ch !== ",") throw new Error("expected , or } at " + (c.i - 1));
    }
}
```

`src/store/config.ts`:

```ts
import { fidKey, fmtNum } from "../format";
import { decode, encode } from "./json";

export type OffsetSource = "preset" | "values";

export interface Config {
    armed: number[];
    size: { [fid: string]: number };   // fixed beam size (m) per fixture; absent = global fader
    range: number[];                    // [min, max] metres of the AZ_SIZE fader
    rate: number;                       // updates per second
    offset: { source: OffsetSource; preset: string; values: number[] };
}

export const CONFIG_KEY = "AutoZoom.config";
export const INSTANCE_KEY = "AutoZoom.instance";
const UNREADABLE = "Saved AutoZoom settings were unreadable; defaults restored";

export function defaultConfig(): Config {
    return { armed: [], size: {}, range: [0.5, 5], rate: 30, offset: { source: "values", preset: "", values: [0, 0, 0] } };
}

function num(v: unknown): number | undefined {
    return typeof v === "number" && v === v ? v : undefined;
}

export function parseConfig(text: string | undefined): { config: Config; warning?: string } {
    const config = defaultConfig();
    if (text === undefined || text === "") return { config };
    let raw: any;
    try {
        raw = decode(text);
    } catch (e) {
        return { config, warning: UNREADABLE };
    }
    if (typeof raw !== "object") return { config, warning: UNREADABLE };
    if (Array.isArray(raw.armed)) {
        for (const fid of raw.armed) if (num(fid) !== undefined) config.armed.push(Math.floor(fid));
    }
    if (typeof raw.size === "object") {
        for (const key in raw.size) {
            const v = num(raw.size[key]);
            if (v !== undefined && v > 0) config.size[key] = v;
        }
    }
    if (Array.isArray(raw.range) && raw.range.length === 2) {
        const lo = num(raw.range[0]), hi = num(raw.range[1]);
        if (lo !== undefined && hi !== undefined && lo > 0 && hi > lo) config.range = [lo, hi];
    }
    const rate = num(raw.rate);
    if (rate !== undefined && rate >= 1 && rate <= 60) config.rate = rate;
    if (typeof raw.offset === "object") {
        const o = raw.offset;
        if (o.source === "preset" || o.source === "values") config.offset.source = o.source;
        if (typeof o.preset === "string") config.offset.preset = o.preset;
        if (Array.isArray(o.values) && o.values.length === 3) {
            config.offset.values = [num(o.values[0]) ?? 0, num(o.values[1]) ?? 0, num(o.values[2]) ?? 0];
        }
    }
    return { config };
}

export function serializeConfig(c: Config): string {
    return encode({ v: 1, armed: c.armed, size: c.size, range: c.range, rate: c.rate, offset: c.offset });
}

export function pruneConfig(config: Config, fids: number[]): Config {
    const keep: { [fid: string]: boolean } = {};
    for (const fid of fids) keep[fidKey(fid)] = true;
    const armed: number[] = [];
    for (const fid of config.armed) if (keep[fidKey(fid)]) armed.push(fid);
    const size: { [fid: string]: number } = {};
    for (const key in config.size) if (keep[key]) size[key] = config.size[key];
    return { ...config, armed, size };
}

export interface SetupAnswers { source: OffsetSource; preset: string; x: string; y: string; z: string; min: string; max: string; rate: string }

export function applySetup(current: Config, a: SetupAnswers): { config: Config; errors: string[] } {
    const errors: string[] = [];
    const config: Config = { ...current, range: [...current.range], offset: { ...current.offset, values: [...current.offset.values] } };
    const read = (label: string, text: string): number | undefined => {
        const n = Number(text.trim());
        if (text.trim() === "" || n !== n) { errors.push(`${label}: "${text}" is not a number`); return undefined; }
        return n;
    };
    const x = read("Offset X", a.x), y = read("Offset Y", a.y), z = read("Offset Z", a.z);
    if (x !== undefined && y !== undefined && z !== undefined) config.offset.values = [x, y, z];
    if (a.source === "preset" && a.preset.trim() === "") errors.push("Offset source is Preset but no preset number was given");
    else config.offset.source = a.source;
    config.offset.preset = a.preset.trim();
    const lo = read("Size min", a.min), hi = read("Size max", a.max);
    if (lo !== undefined && hi !== undefined) {
        if (lo > 0 && hi > lo) config.range = [lo, hi];
        else errors.push("Size range must be min > 0 and max > min");
    }
    const rate = read("Refresh rate", a.rate);
    if (rate !== undefined) {
        if (rate >= 1 && rate <= 60) config.rate = rate;
        else errors.push("Refresh rate must be between 1 and 60");
    }
    return { config, errors };
}

export function offsetLabel(c: Config): string {
    if (c.offset.source === "preset") return "preset " + c.offset.preset;
    return c.offset.values.map(v => fmtNum(v)).join("/") + " m";
}
```

In `applySetup` a bad number for `rate` ("0") is a range error, so the bad-answers test expects exactly 4 errors: empty preset, `x`, range, rate.

`src/testing/exports.ts`:

```ts
// Entry of the test bundle (build/azlib.lua). Each module under test is re-exported here.
import * as format from "../format";
import * as json from "../store/json";
import * as config from "../store/config";

export const ready = true;
export { format, json, config };
```

- [ ] **Step 4: Run tests**

Run: `npm test`
Expected: all pass (`10/10` new, `12/12` old harness)

- [ ] **Step 5: Commit**

```bash
git add src/format.ts src/store src/testing/exports.ts tests/json_test.lua tests/config_test.lua tests/run.lua
git commit -m "Add config store with JSON encoding and setup validation"
```

---

### Task 4: Vector and beam math

**Files:**
- Create: `src/engine/vec.ts`, `src/engine/beam.ts`, `tests/beam_test.lua`
- Modify: `src/testing/exports.ts`, `tests/run.lua`

**Interfaces:**
- Produces:
  - `interface Vec3 { x: number; y: number; z: number }`, `vec(x, y, z): Vec3`, `add(a, b): Vec3`, `distance(a, b): number`, `rotate(v: Vec3, deg: Vec3): Vec3` (Euler degrees, applied X then Y then Z about fixed axes)
  - `interface Optics { zoomMin: number; zoomMax: number; irisMin: number; irisMax: number }` (iris both 0 = no iris)
  - `type BeamFit = "ok" | "too-wide" | "too-small"`, `interface BeamResult { zoom: number; iris?: number; fit: BeamFit; achieved: number }`
  - `beamFor(distance: number, size: number, o: Optics): BeamResult` — zoom/iris in percent, rounded to 0.1, clamped 0–100

- [ ] **Step 1: Write the failing tests** `tests/beam_test.lua`

```lua
local T = require("t")
local az = require("az")
local ESPRITE = { zoomMin = 5.5, zoomMax = 49, irisMin = 0.109, irisMax = 1 }

T.test("vec helpers", function()
  local v = az().vec
  T.near(v.distance(v.vec(0, 0, 10), v.vec(0, 0, 1.5)), 8.5, 1e-9, "distance")
  local r = v.rotate(v.vec(1, 0, 0), v.vec(0, 0, 90))
  T.near(r.x, 0, 1e-9, "x"); T.near(r.y, 1, 1e-9, "y"); T.near(r.z, 0, 1e-9, "z")
end)

T.test("zoom only within range", function()
  local b = az().beam.beamFor(10, 2, ESPRITE)   -- 11.42 deg
  T.eq(b.fit, "ok", "fit"); T.near(b.zoom, 13.6, 0.05, "zoom"); T.eq(b.iris, 100, "iris"); T.near(b.achieved, 2, 1e-9, "achieved")
end)

T.test("iris below minimum zoom", function()
  local b = az().beam.beamFor(10, 0.5, ESPRITE)  -- 0.5 / 0.9607 = 0.5205
  T.eq(b.fit, "ok", "fit"); T.eq(b.zoom, 0, "zoom"); T.near(b.iris, 46.2, 0.05, "iris")
end)

T.test("too small clamps iris to 0", function()
  local b = az().beam.beamFor(10, 0.05, ESPRITE)
  T.eq(b.fit, "too-small", "fit"); T.eq(b.iris, 0, "iris"); T.near(b.achieved, 0.9607 * 0.109, 0.001, "achieved")
end)

T.test("too wide", function()
  local b = az().beam.beamFor(10, 15, ESPRITE)
  T.eq(b.fit, "too-wide", "fit"); T.eq(b.zoom, 100, "zoom"); T.eq(b.iris, 100, "iris"); T.near(b.achieved, 9.1145, 0.001, "achieved")
end)

T.test("fixture without iris", function()
  local b = az().beam.beamFor(10, 0.5, { zoomMin = 5.5, zoomMax = 49, irisMin = 0, irisMax = 0 })
  T.eq(b.fit, "too-small", "fit"); T.eq(b.zoom, 0, "zoom"); T.eq(b.iris, nil, "iris")
end)

T.test("fixed-angle fixture does not divide by zero", function()
  local b = az().beam.beamFor(10, 1.5, { zoomMin = 11, zoomMax = 11, irisMin = 0.1, irisMax = 1 })  -- 8.6 deg < 11
  T.eq(b.zoom, 0, "zoom"); T.truthy(b.iris == b.iris, "iris not NaN")
end)

T.test("zero distance", function()
  local b = az().beam.beamFor(0, 2, ESPRITE)
  T.eq(b.fit, "too-wide", "fit"); T.eq(b.zoom, 100, "zoom")
end)
```

Add `"beam_test",` to `FILES`.

- [ ] **Step 2: Run to verify they fail**

Run: `npm run build:test && lua tests/run.lua`
Expected: FAIL — `attempt to index a nil value (field 'vec')`

- [ ] **Step 3: Implement**

`src/engine/vec.ts`:

```ts
export interface Vec3 { x: number; y: number; z: number }

export function vec(x: number, y: number, z: number): Vec3 {
    return { x, y, z };
}

export function add(a: Vec3, b: Vec3): Vec3 {
    return { x: a.x + b.x, y: a.y + b.y, z: a.z + b.z };
}

export function distance(a: Vec3, b: Vec3): number {
    const dx = a.x - b.x, dy = a.y - b.y, dz = a.z - b.z;
    return Math.sqrt(dx * dx + dy * dy + dz * dz);
}

// Euler rotation in degrees, applied about the fixed X, then Y, then Z axes.
export function rotate(v: Vec3, deg: Vec3): Vec3 {
    const rx = deg.x * Math.PI / 180, ry = deg.y * Math.PI / 180, rz = deg.z * Math.PI / 180;
    let x = v.x, y = v.y, z = v.z;
    let t = y * Math.cos(rx) - z * Math.sin(rx); z = y * Math.sin(rx) + z * Math.cos(rx); y = t;
    t = x * Math.cos(ry) + z * Math.sin(ry); z = -x * Math.sin(ry) + z * Math.cos(ry); x = t;
    t = x * Math.cos(rz) - y * Math.sin(rz); y = x * Math.sin(rz) + y * Math.cos(rz); x = t;
    return { x, y, z };
}
```

`src/engine/beam.ts`:

```ts
// Zoom/iris needed for a beam of `size` metres diameter at `distance` metres.
// Zoom range = full beam angle in degrees; iris range = fraction of the open diameter (GDTF 0..1).

export interface Optics { zoomMin: number; zoomMax: number; irisMin: number; irisMax: number }
export type BeamFit = "ok" | "too-wide" | "too-small";
export interface BeamResult { zoom: number; iris?: number; fit: BeamFit; achieved: number }

function percent(value: number, min: number, max: number): number {
    if (max <= min) return 0;
    const p = (value - min) / (max - min) * 100;
    return Math.round(Math.min(100, Math.max(0, p)) * 10) / 10;
}

function beamAt(angleDeg: number, distance: number): number {
    return 2 * distance * Math.tan(angleDeg * Math.PI / 360);
}

export function beamFor(distance: number, size: number, o: Optics): BeamResult {
    const hasIris = o.irisMax > o.irisMin;
    const full = hasIris ? 100 : undefined;
    if (distance <= 0.001) return { zoom: 100, iris: full, fit: "too-wide", achieved: 0 };
    const angle = Math.atan(size / 2 / distance) * 360 / Math.PI;
    if (angle > o.zoomMax) return { zoom: 100, iris: full, fit: "too-wide", achieved: beamAt(o.zoomMax, distance) };
    if (angle >= o.zoomMin) return { zoom: percent(angle, o.zoomMin, o.zoomMax), iris: full, fit: "ok", achieved: size };
    const atMin = beamAt(o.zoomMin, distance);
    if (!hasIris) return { zoom: 0, iris: undefined, fit: "too-small", achieved: atMin };
    const ratio = size / atMin;
    if (ratio < o.irisMin) return { zoom: 0, iris: 0, fit: "too-small", achieved: atMin * o.irisMin };
    return { zoom: 0, iris: percent(ratio, o.irisMin, o.irisMax), fit: "ok", achieved: size };
}
```

In `src/testing/exports.ts` add `import * as vec from "../engine/vec";` and `import * as beam from "../engine/beam";` and add `vec, beam` to the export list.

- [ ] **Step 4: Run tests**

Run: `npm test`
Expected: all pass

- [ ] **Step 5: Commit**

```bash
git add src/engine/vec.ts src/engine/beam.ts src/testing/exports.ts tests/beam_test.lua tests/run.lua
git commit -m "Add vector and beam math with clamping and fixed-angle handling"
```

---

### Task 5: Fixture state machine

**Files:**
- Create: `src/engine/fixture-state.ts`, `tests/fixture_state_test.lua`
- Modify: `src/testing/exports.ts`, `tests/run.lua`

**Interfaces:**
- Consumes: `Vec3`, `add`, `distance`, `rotate` (Task 4), `Optics`, `beamFor` (Task 4)
- Produces:
  - `type StateKind = "offline" | "disarmed" | "no-marker" | "unknown-marker" | "no-psn" | "tracking" | "too-wide" | "too-small"`
  - `type FaderOutput = { kind: "release" } | { kind: "hold" } | { kind: "set"; zoom: number; iris?: number }`
  - `interface MarkerSample { pos: Vec3; rot?: Vec3; live: boolean }`
  - `interface FixtureInput { running: boolean; armed: boolean; markerCid: number; offset: Vec3; fixturePos: Vec3; optics: Optics; size: number; marker?: MarkerSample }`
  - `interface FixtureResult { state: StateKind; output: FaderOutput; aim?: Vec3; distance?: number; achieved?: number; zoom?: number; iris?: number }`
  - `evaluate(input: FixtureInput): FixtureResult`

- [ ] **Step 1: Write the failing tests** `tests/fixture_state_test.lua`

```lua
local T = require("t")
local az = require("az")
local ESPRITE = { zoomMin = 5.5, zoomMax = 49, irisMin = 0.109, irisMax = 1 }

local function input(over)
  local i = { running = true, armed = true, markerCid = 1, offset = { x = 0, y = 0, z = 0 },
    fixturePos = { x = 0, y = 0, z = 10 }, optics = ESPRITE, size = 2,
    marker = { pos = { x = 0, y = 0, z = 0 }, live = true } }
  for k, v in pairs(over or {}) do i[k] = v end
  return i
end

T.test("states before tracking", function()
  local ev = az().state.evaluate
  T.eq(ev(input({ running = false })).state, "offline", "offline")
  T.eq(ev(input({ armed = false })).output, { kind = "release" }, "disarmed releases")
  T.eq(ev(input({ markerCid = 0, marker = false })).state, "no-marker", "no marker")
  T.eq(ev(input({ markerCid = 7, marker = false })).state, "unknown-marker", "unknown marker")
  T.eq(ev(input({ marker = { pos = { x = 0, y = 0, z = 0 }, live = false } })).output, { kind = "hold" }, "no psn holds")
end)

T.test("tracking aims at marker plus offset", function()
  local r = az().state.evaluate(input({ offset = { x = 0, y = 0, z = 1.5 } }))
  T.eq(r.state, "tracking", "state"); T.near(r.distance, 8.5, 1e-9, "distance"); T.eq(r.output.kind, "set", "output")
  T.eq(r.aim, { x = 0, y = 0, z = 1.5 }, "aim")
end)

T.test("marker rotation turns the offset", function()
  local r = az().state.evaluate(input({ offset = { x = 1, y = 0, z = 0 },
    marker = { pos = { x = 0, y = 0, z = 0 }, rot = { x = 0, y = 0, z = 90 }, live = true } }))
  T.near(r.aim.x, 0, 1e-9, "aim x"); T.near(r.aim.y, 1, 1e-9, "aim y")
end)

T.test("fit maps to state", function()
  T.eq(az().state.evaluate(input({ size = 15 })).state, "too-wide", "too wide")
  T.eq(az().state.evaluate(input({ size = 0.05 })).state, "too-small", "too small")
end)
```

In these tests `marker = false` stands for "no marker sample": implement `evaluate` to treat any falsy `marker` as absent.

Add `"fixture_state_test",` to `FILES`.

- [ ] **Step 2: Run to verify they fail**

Run: `npm run build:test && lua tests/run.lua`
Expected: FAIL — `attempt to index a nil value (field 'state')`

- [ ] **Step 3: Implement** `src/engine/fixture-state.ts`

```ts
import { beamFor, Optics } from "./beam";
import { add, distance, rotate, Vec3 } from "./vec";

export type StateKind = "offline" | "disarmed" | "no-marker" | "unknown-marker" | "no-psn" | "tracking" | "too-wide" | "too-small";
export type FaderOutput = { kind: "release" } | { kind: "hold" } | { kind: "set"; zoom: number; iris?: number };
export interface MarkerSample { pos: Vec3; rot?: Vec3; live: boolean }
export interface FixtureInput {
    running: boolean; armed: boolean; markerCid: number; offset: Vec3;
    fixturePos: Vec3; optics: Optics; size: number; marker?: MarkerSample;
}
export interface FixtureResult {
    state: StateKind; output: FaderOutput; aim?: Vec3; distance?: number; achieved?: number; zoom?: number; iris?: number;
}

const RELEASE: FaderOutput = { kind: "release" };

export function evaluate(i: FixtureInput): FixtureResult {
    if (!i.running) return { state: "offline", output: RELEASE };
    if (!i.armed) return { state: "disarmed", output: RELEASE };
    if (i.markerCid === 0) return { state: "no-marker", output: RELEASE };
    if (!i.marker) return { state: "unknown-marker", output: RELEASE };
    if (!i.marker.live) return { state: "no-psn", output: { kind: "hold" } };
    const offset = i.marker.rot !== undefined ? rotate(i.offset, i.marker.rot) : i.offset;
    const aim = add(i.marker.pos, offset);
    const d = distance(i.fixturePos, aim);
    const beam = beamFor(d, i.size, i.optics);
    const state: StateKind = beam.fit === "ok" ? "tracking" : beam.fit;
    return {
        state, aim, distance: d, achieved: beam.achieved, zoom: beam.zoom, iris: beam.iris,
        output: { kind: "set", zoom: beam.zoom, iris: beam.iris },
    };
}
```

In `src/testing/exports.ts` add `import * as state from "../engine/fixture-state";` and export `state`.

- [ ] **Step 4: Run tests**

Run: `npm test`
Expected: all pass

- [ ] **Step 5: Commit**

```bash
git add src/engine/fixture-state.ts src/testing/exports.ts tests/fixture_state_test.lua tests/run.lua
git commit -m "Add per-fixture AutoZoom state machine"
```

---

### Task 6: Arm commands and tap-to-program command lists

**Files:**
- Create: `src/engine/arm-command.ts`, `src/engine/program.ts`, `tests/commands_test.lua`
- Modify: `src/testing/exports.ts`, `tests/run.lua`

**Interfaces:**
- Consumes: `fmtInt`, `fmtNum` (Task 3), `Config` (Task 3), `Optics` (Task 4)
- Produces:
  - `normalizeFids(fids: number[]): number[]` (unique positive integers, ascending)
  - `formatArmList(fids: number[]): string` → `"101,102"`; `armCommand(fids: number[]): string` → `Lua "AZ:Arm('101,102')"`
  - `parseArmList(text: string): number[]`
  - `rewriteCueCommand(existing: string | undefined, armLine: string): string`
  - `programCommands(fid: number, cid: number, optics: Optics, offset: Config["offset"]): string[]`, `releaseCommands(fid: number): string[]`

The exact syntax of the `XYZ_MArker`, XYZ offset, preset and zoom/iris lines comes from probe results P3, P4 and P5 (`docs/superpowers/specs/2026-10-03-probe-2-results.md`). The code below uses the syntax the probe tested; if a result recorded a different working form, use that form in `programCommands` and the matching test expectations.

- [ ] **Step 1: Write the failing tests** `tests/commands_test.lua`

```lua
local T = require("t")
local az = require("az")

T.test("arm command formatting", function()
  local a = az().arm
  T.eq(a.formatArmList({ 103, 101, 101 }), "101,103", "sorted unique")
  T.eq(a.armCommand({ 102, 101 }), [[Lua "AZ:Arm('101,102')"]], "command")
end)

T.test("arm list parsing ignores junk", function()
  T.eq(az().arm.parseArmList(" 101, x,102 ,-3, 1.5,101"), { 101, 102 }, "parsed")
end)

T.test("empty arm list", function()
  T.eq(az().arm.parseArmList(""), {}, "empty")
  T.eq(az().arm.armCommand({}), [[Lua "AZ:Arm('')"]], "command")
end)

T.test("cue command rewrite keeps other commands and replaces old arms", function()
  local a = az().arm
  T.eq(a.rewriteCueCommand([[Go+ Sequence 3; Lua "AZ:Arm('101')"]], [[Lua "AZ:Arm('102')"]]),
    [[Go+ Sequence 3; Lua "AZ:Arm('102')"]], "rewritten")
  T.eq(a.rewriteCueCommand(nil, "X"), "X", "empty existing")
  T.eq(a.rewriteCueCommand("", "X"), "X", "blank existing")
end)

T.test("program commands with values offset", function()
  local optics = { zoomMin = 5.5, zoomMax = 49, irisMin = 0.109, irisMax = 1 }
  local cmds = az().program.programCommands(101, 1, optics, { source = "values", preset = "", values = { 0, -1, 0.3 } })
  T.eq(cmds, {
    "Fixture 101",
    'Attribute "XYZ_MArker" At 1',
    'Attribute "XYZ_X" At 0',
    'Attribute "XYZ_Y" At -1',
    'Attribute "XYZ_Z" At 0.3',
    'Attribute "Zoom" At Absolute Physical 5.5',
    'Attribute "Iris" At Absolute Physical 0.109',
  }, "commands")
end)

T.test("program commands with preset offset and no iris", function()
  local optics = { zoomMin = 10, zoomMax = 40, irisMin = 0, irisMax = 0 }
  local cmds = az().program.programCommands(102, 4, optics, { source = "preset", preset = "2.12", values = { 0, 0, 0 } })
  T.eq(cmds, { "Fixture 102", 'Attribute "XYZ_MArker" At 4', 'Attribute "XYZ_X" Thru "XYZ_Z" At Preset 2.12',
    'Attribute "Zoom" At Absolute Physical 10' }, "commands")
  T.eq(az().program.releaseCommands(102), { "Off Fixture 102" }, "release")
end)
```

Add `"commands_test",` to `FILES`.

- [ ] **Step 2: Run to verify they fail**

Run: `npm run build:test && lua tests/run.lua`
Expected: FAIL — `attempt to index a nil value (field 'arm')`

- [ ] **Step 3: Implement**

`src/engine/arm-command.ts`:

```ts
import { fmtInt } from "../format";

export function normalizeFids(fids: number[]): number[] {
    const seen: { [key: string]: boolean } = {};
    const out: number[] = [];
    for (const fid of fids) {
        if (fid > 0 && Math.floor(fid) === fid && !seen[fmtInt(fid)]) {
            seen[fmtInt(fid)] = true;
            out.push(fid);
        }
    }
    out.sort((a, b) => a - b);
    return out;
}

export function formatArmList(fids: number[]): string {
    return normalizeFids(fids).map(f => fmtInt(f)).join(",");
}

export function armCommand(fids: number[]): string {
    return `Lua "AZ:Arm('${formatArmList(fids)}')"`;
}

export function parseArmList(text: string): number[] {
    const out: number[] = [];
    for (const part of text.split(",")) {
        const n = Number(part.trim());
        if (part.trim() !== "" && n === n) out.push(n);
    }
    return normalizeFids(out);
}

// Cue commands are separated by ";". A ";" inside a quoted user command would be split too.
export function rewriteCueCommand(existing: string | undefined, armLine: string): string {
    const kept: string[] = [];
    if (existing !== undefined) {
        for (const raw of existing.split(";")) {
            const part = raw.trim();
            if (part !== "" && part.indexOf("AZ:Arm(") < 0) kept.push(part);
        }
    }
    kept.push(armLine);
    return kept.join("; ");
}
```

`src/engine/program.ts`:

```ts
import { fmtInt, fmtNum } from "../format";
import { Config } from "../store/config";
import { Optics } from "./beam";

// Programmer commands for "fixture follows marker": marker, XYZ offset, zoom/iris at the AutoZoom base (minimum).
export function programCommands(fid: number, cid: number, optics: Optics, offset: Config["offset"]): string[] {
    const cmds = [`Fixture ${fmtInt(fid)}`, `Attribute "XYZ_MArker" At ${fmtInt(cid)}`];
    if (offset.source === "preset" && offset.preset !== "") {
        cmds.push(`Attribute "XYZ_X" Thru "XYZ_Z" At Preset ${offset.preset}`);
    } else {
        cmds.push(`Attribute "XYZ_X" At ${fmtNum(offset.values[0])}`);
        cmds.push(`Attribute "XYZ_Y" At ${fmtNum(offset.values[1])}`);
        cmds.push(`Attribute "XYZ_Z" At ${fmtNum(offset.values[2])}`);
    }
    cmds.push(`Attribute "Zoom" At Absolute Physical ${fmtNum(optics.zoomMin)}`);
    if (optics.irisMax > optics.irisMin) cmds.push(`Attribute "Iris" At Absolute Physical ${fmtNum(optics.irisMin)}`);
    return cmds;
}

export function releaseCommands(fid: number): string[] {
    return [`Off Fixture ${fmtInt(fid)}`];
}
```

In `src/testing/exports.ts` add `import * as arm from "../engine/arm-command";`, `import * as program from "../engine/program";` and export `arm, program`.

- [ ] **Step 4: Run tests**

Run: `npm test`
Expected: all pass

- [ ] **Step 5: Commit**

```bash
git add src/engine/arm-command.ts src/engine/program.ts src/testing/exports.ts tests/commands_test.lua tests/run.lua
git commit -m "Add arm recall command handling and tap-to-program commands"
```

---

### Task 7: Shared model and layout view model

**Files:**
- Create: `src/model.ts`, `src/ui/view-model.ts`, `tests/view_model_test.lua`
- Modify: `src/testing/exports.ts`, `tests/run.lua`

**Interfaces:**
- Consumes: `Vec3` (Task 4), `Optics` (Task 4), `FixtureResult`, `StateKind` (Task 5), `fmtInt`, `fmtNum`, `fidKey` (Task 3)
- Produces (`src/model.ts`):
  - `interface PatchFixture { fid: number; name: string; position: Vec3; optics: Optics; uich: { marker: number; x: number; y: number; z: number } }`
  - `interface PatchMarker { cid: number; name: string }`
  - `interface PatchScan { fixtures: PatchFixture[]; markers: PatchMarker[]; problems: string[] }`
  - `interface MarkerReading { pos: Vec3; rot?: Vec3 }`, `type MarkerReadings = { [cid: string]: MarkerReading }` (key `fidKey(cid)`; present = PSN data received)
  - `interface CellSpec { key: string; x: number; y: number; w: number; h: number; command: string }` (`command` = Lua call after `AZ:`, `""` = display only)
  - `interface CellView { text: string; border: string; textColor: string }`, `type Views = { [key: string]: CellView }`
  - `interface SeqRef { id: string; no: number; name: string }`
- Produces (`src/ui/view-model.ts`):
  - `COLORS`, `GRID`, `Y_DIR`
  - `interface HeaderState { running: boolean; captureSecondsLeft?: number; liveMarkers: number; globalSize: number; offsetLabel: string; message: string }`
  - `interface RowState { fixture: PatchFixture; armed: boolean; markerCid: number; programmerCid: number; offset: Vec3; result: FixtureResult; size: number; sizeFixed: boolean }`
  - `layoutCells(fixtures: PatchFixture[], markers: PatchMarker[]): CellSpec[]`
  - `buildViews(header: HeaderState, rows: RowState[], markers: PatchMarker[], readings: MarkerReadings): Views`
  - `stateLabel(state: StateKind): string`
  - Cell keys: `status`, `toggle`, `capture`, `setup`, `armall`, `disarmall`, `size`, `message`, `mh <cid>`, `arm <fid>`, `mx <fid> <cid>`, `st <fid>`, `di <fid>`, `zo <fid>`, `ir <fid>`, `sz <fid>` (numbers via `fmtInt`, single spaces)

`Y_DIR` is the layout's "down" sign. Use the value from probe result P10 (`-1` if a larger `PosY` is higher on screen, `1` otherwise).

- [ ] **Step 1: Write the failing tests** `tests/view_model_test.lua`

```lua
local T = require("t")
local az = require("az")

local function fx(fid) return { fid = fid, name = "Spot " .. fid, position = { x = 0, y = 0, z = 10 },
  optics = { zoomMin = 5.5, zoomMax = 49, irisMin = 0.109, irisMax = 1 }, uich = { marker = 1, x = 2, y = 3, z = 4 } } end
local MARKERS = { { cid = 1, name = "Lead" }, { cid = 2, name = "Bass" } }

T.test("layout cells cover header, marker heads and every row cell", function()
  local cells = az().view.layoutCells({ fx(101), fx(102) }, MARKERS)
  local keys = {}
  for _, c in ipairs(cells) do keys[c.key] = c.command end
  T.eq(keys["toggle"], "Toggle()", "toggle"); T.eq(keys["capture"], "Capture()", "capture")
  T.eq(keys["arm 101"], "ArmToggle(101)", "arm"); T.eq(keys["mx 102 2"], "Program(102,2)", "matrix")
  T.eq(keys["sz 101"], "Size(101)", "size"); T.eq(keys["st 101"], "", "state is display only")
  T.eq(keys["mh 2"], "", "marker head"); T.eq(#cells, 8 + 2 + 2 * (1 + 2 + 5), "count")
end)

T.test("views for a tracking row and a programmer cell", function()
  local v = az().view
  local header = { running = true, liveMarkers = 1, globalSize = 2, offsetLabel = "0/0/0 m", message = "" }
  local row = { fixture = fx(101), armed = true, markerCid = 1, programmerCid = 2, offset = { x = 0, y = 0, z = 0.3 },
    result = { state = "tracking", output = { kind = "set", zoom = 13.6, iris = 100 }, distance = 8.5, achieved = 2, zoom = 13.6, iris = 100 },
    size = 2, sizeFixed = false }
  local views = v.buildViews(header, { row }, MARKERS, { ["1"] = { pos = { x = 0, y = 0, z = 0 } } })
  T.eq(views["status"].text, "Running\nPSN 1/2", "status")
  T.eq(views["mx 101 1"].text, "●", "following cell"); T.eq(views["mx 101 1"].border, v.COLORS.on, "following colour")
  T.eq(views["mx 101 2"].text, "P", "programmer cell"); T.eq(views["mx 101 2"].border, v.COLORS.bad, "programmer colour")
  T.eq(views["st 101"].text, "Tracking\nLead +0/+0/+0.3", "state")
  T.eq(views["zo 101"].text, "13.6 %", "zoom"); T.eq(views["sz 101"].text, "Global\n2 m", "size")
  T.eq(views["mh 2"].border, v.COLORS.bad, "marker without PSN")
end)

T.test("capture header shows countdown and instructions", function()
  local views = az().view.buildViews({ running = true, captureSecondsLeft = 12, liveMarkers = 0, globalSize = 1, offsetLabel = "", message = "Select a sequence" }, {}, {}, {})
  T.eq(views["capture"].text, "Select a sequence…\n12 s · tap to cancel", "capture")
  T.eq(views["message"].text, "Select a sequence", "message")
end)
```

Add `"view_model_test",` to `FILES`.

- [ ] **Step 2: Run to verify they fail**

Run: `npm run build:test && lua tests/run.lua`
Expected: FAIL — `attempt to index a nil value (field 'view')`

- [ ] **Step 3: Implement**

`src/model.ts`:

```ts
import { Optics } from "./engine/beam";
import { Vec3 } from "./engine/vec";

export interface PatchFixture {
    fid: number;
    name: string;
    position: Vec3;                                            // stage position, parents included
    optics: Optics;
    uich: { marker: number; x: number; y: number; z: number }; // UI channel indexes of XYZ_MArker, XYZ_X/Y/Z
}
export interface PatchMarker { cid: number; name: string }
export interface PatchScan { fixtures: PatchFixture[]; markers: PatchMarker[]; problems: string[] }
export interface MarkerReading { pos: Vec3; rot?: Vec3 }
export type MarkerReadings = { [cid: string]: MarkerReading };
export interface CellSpec { key: string; x: number; y: number; w: number; h: number; command: string }
export interface CellView { text: string; border: string; textColor: string }
export type Views = { [key: string]: CellView };
export interface SeqRef { id: string; no: number; name: string }
```

`src/ui/view-model.ts`:

```ts
import { FixtureResult, StateKind } from "../engine/fixture-state";
import { Vec3 } from "../engine/vec";
import { fidKey, fmtInt, fmtNum } from "../format";
import { CellSpec, MarkerReadings, PatchFixture, PatchMarker, Views } from "../model";

export const COLORS = {
    on: "3ECF6EFF", warn: "E8C547FF", bad: "E5534BFF", idle: "5B6573FF",
    accent: "F5A623FF", text: "E6E8EBFF", muted: "8E96A3FF",
};
export const GRID = { w: 130, markerW: 70, h: 64, gap: 6 };
export const Y_DIR = -1; // layout "down" direction (probe P10)

export interface HeaderState { running: boolean; captureSecondsLeft?: number; liveMarkers: number; globalSize: number; offsetLabel: string; message: string }
export interface RowState {
    fixture: PatchFixture; armed: boolean; markerCid: number; programmerCid: number; offset: Vec3;
    result: FixtureResult; size: number; sizeFixed: boolean;
}

const LABELS: { [state: string]: string } = {
    "offline": "Offline", "disarmed": "Disarmed", "no-marker": "Armed · no marker", "unknown-marker": "Unknown marker",
    "no-psn": "No PSN data", "tracking": "Tracking", "too-wide": "Too wide", "too-small": "Too small",
};

export function stateLabel(state: StateKind): string {
    return LABELS[state];
}

function signed(n: number): string {
    return (n >= 0 ? "+" : "") + fmtNum(n);
}

export function layoutCells(fixtures: PatchFixture[], markers: PatchMarker[]): CellSpec[] {
    const cells: CellSpec[] = [];
    const step = GRID.h + GRID.gap;
    let x = 0;
    const header: [string, string][] = [
        ["status", ""], ["toggle", "Toggle()"], ["capture", "Capture()"], ["setup", "Setup()"],
        ["armall", "ArmAll()"], ["disarmall", "DisarmAll()"], ["size", ""], ["message", ""],
    ];
    for (const [key, command] of header) {
        const w = key === "message" ? GRID.w * 3 : GRID.w;
        cells.push({ key, x, y: 0, w, h: GRID.h, command });
        x += w + GRID.gap;
    }
    const markerX = (i: number) => GRID.w + GRID.gap + i * (GRID.markerW + GRID.gap);
    markers.forEach((m, i) => cells.push({ key: `mh ${fmtInt(m.cid)}`, x: markerX(i), y: Y_DIR * step, w: GRID.markerW, h: GRID.h, command: "" }));
    const afterMarkers = markerX(markers.length);
    fixtures.forEach((f, row) => {
        const y = Y_DIR * step * (row + 2);
        const fid = fmtInt(f.fid);
        cells.push({ key: `arm ${fid}`, x: 0, y, w: GRID.w, h: GRID.h, command: `ArmToggle(${fid})` });
        markers.forEach((m, i) => cells.push({ key: `mx ${fid} ${fmtInt(m.cid)}`, x: markerX(i), y, w: GRID.markerW, h: GRID.h, command: `Program(${fid},${fmtInt(m.cid)})` }));
        const tail: [string, number, string][] = [["st", GRID.w * 1.6, ""], ["di", GRID.w, ""], ["zo", GRID.w * 0.8, ""], ["ir", GRID.w * 0.8, ""], ["sz", GRID.w, `Size(${fid})`]];
        let cx = afterMarkers;
        for (const [prefix, w, command] of tail) {
            cells.push({ key: `${prefix} ${fid}`, x: cx, y, w, h: GRID.h, command });
            cx += w + GRID.gap;
        }
    });
    return cells;
}

function stateColor(state: StateKind): string {
    if (state === "tracking") return COLORS.on;
    if (state === "too-wide" || state === "too-small") return COLORS.warn;
    if (state === "no-psn" || state === "unknown-marker") return COLORS.bad;
    return COLORS.idle;
}

export function buildViews(header: HeaderState, rows: RowState[], markers: PatchMarker[], readings: MarkerReadings): Views {
    const v: Views = {};
    const cell = (key: string, text: string, border: string = COLORS.idle, textColor: string = COLORS.text) => { v[key] = { text, border, textColor }; };
    cell("status", `${header.running ? "Running" : "Offline"}\nPSN ${fmtInt(header.liveMarkers)}/${fmtInt(markers.length)}`, header.running ? COLORS.on : COLORS.bad);
    cell("toggle", header.running ? "Stop" : "Start");
    if (header.captureSecondsLeft !== undefined) cell("capture", `Select a sequence…\n${fmtInt(header.captureSecondsLeft)} s · tap to cancel`, COLORS.accent, COLORS.accent);
    else cell("capture", "Capture\narms → cue");
    cell("setup", `Setup\nXYZ ${header.offsetLabel}`);
    cell("armall", "Arm all");
    cell("disarmall", "Disarm all");
    cell("size", `AZ_SIZE\n${fmtNum(header.globalSize)} m`);
    cell("message", header.message, COLORS.idle, COLORS.muted);
    for (const m of markers) {
        const live = readings[fidKey(m.cid)] !== undefined;
        cell(`mh ${fmtInt(m.cid)}`, `${m.name}\nCID ${fmtInt(m.cid)}`, live ? COLORS.on : COLORS.bad, live ? COLORS.text : COLORS.bad);
    }
    for (const r of rows) {
        const fid = fmtInt(r.fixture.fid);
        const s = r.result.state;
        cell(`arm ${fid}`, `${fid}\n${r.fixture.name}`, r.armed ? COLORS.on : COLORS.idle);
        for (const m of markers) {
            const key = `mx ${fid} ${fmtInt(m.cid)}`;
            if (r.programmerCid === m.cid) cell(key, "P", COLORS.bad, COLORS.bad);
            else if (r.markerCid === m.cid) {
                const color = s === "tracking" || s === "too-wide" || s === "too-small" ? COLORS.on : s === "no-psn" ? COLORS.accent : COLORS.muted;
                cell(key, "●", color, color);
            } else cell(key, "");
        }
        const marker = markers.find(m => m.cid === r.markerCid);
        const detail = marker !== undefined ? `${marker.name} ${signed(r.offset.x)}/${signed(r.offset.y)}/${signed(r.offset.z)}` : "";
        cell(`st ${fid}`, detail === "" ? stateLabel(s) : `${stateLabel(s)}\n${detail}`, stateColor(s));
        cell(`di ${fid}`, r.result.distance === undefined ? "—" : `${fmtNum(Math.round(r.result.distance * 10) / 10)} m\nbeam ${fmtNum(Math.round((r.result.achieved ?? 0) * 100) / 100)} m`);
        cell(`zo ${fid}`, r.result.zoom === undefined ? "—" : `${fmtNum(r.result.zoom)} %`);
        cell(`ir ${fid}`, r.result.iris === undefined ? "—" : `${fmtNum(r.result.iris)} %`);
        cell(`sz ${fid}`, `${r.sizeFixed ? "Fixed" : "Global"}\n${fmtNum(Math.round(r.size * 100) / 100)} m`);
    }
    return v;
}
```

In `src/testing/exports.ts` add `import * as view from "../ui/view-model";` and export `view`.

- [ ] **Step 4: Run tests**

Run: `npm test`
Expected: all pass

- [ ] **Step 5: Commit**

```bash
git add src/model.ts src/ui src/testing/exports.ts tests/view_model_test.lua tests/run.lua
git commit -m "Add layout geometry and cell view model"
```

---

### Task 8: Desk interface and AutoZoom runtime core

**Files:**
- Create: `src/desk.ts`, `src/runtime/autozoom.ts`, `tests/lib/fakedesk.lua`, `tests/runtime_test.lua`
- Modify: `src/testing/exports.ts`, `tests/run.lua`

**Interfaces:**
- Consumes: everything from Tasks 3–7
- Produces:
  - `interface Desk` (exact methods below; `src/console/ma-desk.ts` implements it in Task 12)
  - `class AutoZoom` with public commands `Install()`, `Rescan()`, `Start()`, `Stop()`, `Toggle()`, `Arm(list: string)`, `ArmToggle(fid: number)`, `ArmAll()`, `DisarmAll()`, `Status()`; Tasks 9–10 add `Capture()`, `Program(fid, cid)`, `Setup()`, `Size(fid)`
  - `createAutoZoom(desk: Desk, id: string): AutoZoom`
  - Lua fake: `require("fakedesk").new(scan)` → desk with fields `logs, saved, faders, releases, cells, views, loop, laters, cmds, t, cids, offsets, progCids, markers, size, answers, setupAnswer, selected, runningCues, selectedCues, cues`; helpers `F.fixture(fid, x, y, z)`, `F.marker(cid, name)`, `d:tick(n)`, `d:runLaters()`

- [ ] **Step 1: Write the fake desk** `tests/lib/fakedesk.lua`

```lua
-- Fake Desk for runtime tests: records every call, returns scripted values.
local F = {}

function F.fixture(fid, x, y, z, optics)
  return { fid = fid, name = "Spot " .. fid, position = { x = x or 0, y = y or 0, z = z or 10 },
    optics = optics or { zoomMin = 5.5, zoomMax = 49, irisMin = 0.109, irisMax = 1 },
    uich = { marker = fid * 10 + 1, x = fid * 10 + 2, y = fid * 10 + 3, z = fid * 10 + 4 } }
end

function F.marker(cid, name) return { cid = cid, name = name or ("Marker " .. cid) } end

function F.new(scan)
  local d = { logs = {}, saved = {}, faders = {}, releases = {}, laters = {}, cmds = {}, t = 0,
    cids = {}, offsets = {}, progCids = {}, markers = {}, answers = {}, runningCues = {}, selectedCues = {}, cues = {},
    scanResult = scan or { fixtures = {}, markers = {}, problems = {} } }
  function d:now() return self.t end
  function d:log(m) self.logs[#self.logs + 1] = m end
  function d:loadText(k) return self.saved[k] end
  function d:saveText(k, v) self.saved[k] = v end
  function d:scan() return self.scanResult end
  function d:install(scan) self.installed = scan end
  function d:readMarkerCid(f) return self.cids[f.fid] or 0 end
  function d:readOffset(f)
    if self.offsetError and self.offsetError[f.fid] then error(self.offsetError[f.fid]) end
    local o = self.offsets[f.fid] or { 0, 0, 0 }
    return { x = o[1], y = o[2], z = o[3] }
  end
  function d:readProgrammerCid(f) return self.progCids[f.fid] or 0 end
  function d:readMarkers() return self.markers end
  function d:readSizeFader() return self.size end
  function d:setFaders(f, zoom, iris) self.faders[#self.faders + 1] = { fid = f.fid, zoom = zoom, iris = iris } end
  function d:releaseFaders(f) self.releases[#self.releases + 1] = f.fid end
  function d:buildLayout(cells) self.cells = cells end
  function d:refreshLayout(views) self.views = views end
  function d:startLoop(rate, tick, cleanup) self.loop = { rate = rate, tick = tick, cleanup = cleanup } end
  function d:stopLoop() local l = self.loop; self.loop = nil; if l then l.cleanup() end end
  function d:later(fn) self.laters[#self.laters + 1] = fn end
  function d:selectedSequence() return self.selected end
  function d:runningCue(seq) return self.runningCues[seq.id] end
  function d:selectedCue(seq) return self.selectedCues[seq.id] end
  function d:readCueCommand(seq, cue) local s = self.cues[seq.id]; return s and s[cue] end
  function d:writeCueCommand(seq, cue, text)
    local s = self.cues[seq.id]; if not (s and s[cue]) then return false end
    s[cue] = text; return true
  end
  function d:prompt(title, value) self.lastPrompt = { title = title, value = value }; return table.remove(self.answers, 1) end
  function d:setupDialog(current) self.setupShown = current; return self.setupAnswer end
  function d:runCommands(c) for _, x in ipairs(c) do self.cmds[#self.cmds + 1] = x end end
  function d:tick(n) for _ = 1, n or 1 do self.loop.tick() end end
  function d:runLaters() local l = self.laters; self.laters = {}; for _, fn in ipairs(l) do fn() end end
  return d
end

return F
```

`prompt` returns the next queued answer; the test queues `nil` by leaving `answers` empty (cancel).

- [ ] **Step 2: Write the failing tests** `tests/runtime_test.lua`

```lua
local T = require("t")
local az = require("az")
local F = require("fakedesk")

local function setup(fixtures, markers)
  local d = F.new({ fixtures = fixtures or { F.fixture(101), F.fixture(102) }, markers = markers or { F.marker(1, "Lead") }, problems = { "Fixture 900: XYZ attributes not found, skipped" } })
  local a = az().runtime.createAutoZoom(d, "id-1")
  return d, a
end

T.test("install loads config, stamps instance, builds layout", function()
  local d, a = setup()
  d.saved["AutoZoom.config"] = '{"armed":[101]}'
  a:Install()
  T.eq(d.saved["AutoZoom.instance"], "id-1", "instance stamp")
  T.truthy(d.installed, "install called"); T.truthy(#d.cells > 0, "layout built")
  T.eq(d.logs[1], "Fixture 900: XYZ attributes not found, skipped", "scan problem logged")
  T.eq(d.views["arm 101"].border, az().view.COLORS.on, "101 armed from config")
end)

T.test("armed fixture following a live marker drives faders once", function()
  local d, a = setup()
  a:Install(); a:Arm("101"); a:Start()
  d.cids[101] = 1; d.markers["1"] = { pos = { x = 0, y = 0, z = 0 } }; d.size = 0   -- size fader 0 % -> range min 0.5 m
  d:tick()
  T.eq(#d.faders, 1, "one set"); T.eq(d.faders[1].fid, 101, "fixture")
  T.near(d.faders[1].iris, 46.2, 0.05, "iris for 0.5 m at 10 m")
  d:tick()
  T.eq(#d.faders, 1, "unchanged values are not resent")
  T.eq(d.releases, { 101, 102 }, "both released once at install (stopped), never again")
end)

T.test("fixed size overrides the global fader", function()
  local d, a = setup()
  d.saved["AutoZoom.config"] = '{"armed":[101],"size":{"101":2}}'
  a:Install(); a:Start()
  d.cids[101] = 1; d.markers["1"] = { pos = { x = 0, y = 0, z = 0 } }; d.size = 100
  d:tick()
  T.near(d.faders[1].zoom, 13.6, 0.05, "zoom for 2 m")
end)

T.test("Arm persists after one second", function()
  local d, a = setup()
  a:Install(); a:Start()
  a:Arm("102,101,999")
  d:tick(); T.eq(d.saved["AutoZoom.config"], nil, "not saved yet")
  d.t = 1.5; d:tick()
  T.eq(az().config.parseConfig(d.saved["AutoZoom.config"]).config.armed, { 101, 102 }, "saved armed, unknown 999 dropped")
end)

T.test("Arm('') disarms all", function()
  local d, a = setup()
  a:Install(); a:ArmAll(); a:Arm("")
  a:Start(); d:tick()
  T.eq(d.views["arm 101"].border, az().view.COLORS.idle, "101 disarmed")
end)

T.test("armed fixture removed from patch is dropped", function()
  local d, a = setup()
  d.saved["AutoZoom.config"] = '{"armed":[101,555]}'
  a:Install(); a:Stop()
  T.eq(az().config.parseConfig(d.saved["AutoZoom.config"]).config.armed, { 101 }, "pruned and saved on stop")
end)

T.test("stale instance stops without touching faders", function()
  local d, a = setup()
  a:Install(); a:ArmAll(); a:Start()
  d.saved["AutoZoom.instance"] = "id-2"
  d.cids[101] = 1; d.markers["1"] = { pos = { x = 0, y = 0, z = 0 } }
  d.loop.tick()
  T.eq(d.loop, nil, "loop stopped"); T.eq(#d.faders, 0, "no fader writes")
  T.truthy(d.logs[#d.logs]:find("Another AutoZoom instance"), "logged")
end)

T.test("an error on one fixture does not stop the others", function()
  local d, a = setup()
  a:Install(); a:ArmAll(); a:Start()
  d.cids[101] = 1; d.cids[102] = 1; d.markers["1"] = { pos = { x = 0, y = 0, z = 0 } }
  d.offsetError = { [101] = "boom" }
  d:tick(); d:tick()
  T.eq(#d.faders, 1, "102 still updated"); T.eq(d.faders[1].fid, 102, "fixture 102")
  local n = 0; for _, l in ipairs(d.logs) do if l:find("boom") then n = n + 1 end end
  T.eq(n, 1, "error logged once")
end)

T.test("stop releases faders and shows offline", function()
  local d, a = setup()
  a:Install(); a:ArmAll(); a:Start()
  d.cids[101] = 1; d.markers["1"] = { pos = { x = 0, y = 0, z = 0 } }
  d:tick(); a:Stop()
  T.eq(d.releases[#d.releases], 101, "tracking fixture released on stop"); T.eq(d.views["status"].text:sub(1, 7), "Offline", "offline")
  T.eq(d.views["st 101"].text, "Offline\nLead +0/+0/+0", "row offline")
end)
```

Add `"runtime_test",` to `FILES`.

- [ ] **Step 3: Run to verify they fail**

Run: `npm run build:test && lua tests/run.lua`
Expected: FAIL — `attempt to index a nil value (field 'runtime')`

- [ ] **Step 4: Implement**

`src/desk.ts`:

```ts
import { Vec3 } from "./engine/vec";
import { CellSpec, MarkerReadings, PatchFixture, PatchScan, SeqRef, Views } from "./model";
import { Config, SetupAnswers } from "./store/config";

// Everything AutoZoom needs from the console. MaDesk (src/console) implements it on grandMA3;
// tests use tests/lib/fakedesk.lua.
export interface Desk {
    now(): number;                                         // seconds
    log(message: string): void;                            // System Monitor
    loadText(key: string): string | undefined;             // GlobalVars
    saveText(key: string, value: string): void;
    scan(): PatchScan;
    install(scan: PatchScan): void;                        // DataPool, AZ_ZOOM/AZ_IRIS/AZ_SIZE sequences
    readMarkerCid(f: PatchFixture): number;                // live XYZ_MArker output, 0 = none
    readOffset(f: PatchFixture): Vec3;                     // live XYZ_X/Y/Z output in metres
    readProgrammerCid(f: PatchFixture): number;            // XYZ_MArker when it comes from the programmer, else 0
    readMarkers(): MarkerReadings;                         // PSN positions by CID
    readSizeFader(): number | undefined;                   // AZ_SIZE master 0..100, undefined if missing
    setFaders(f: PatchFixture, zoom: number, iris: number | undefined): void;
    releaseFaders(f: PatchFixture): void;
    buildLayout(cells: CellSpec[]): void;
    refreshLayout(views: Views): void;
    startLoop(rate: number, tick: () => void, cleanup: () => void): void;
    stopLoop(): void;
    later(fn: () => void): void;                           // run in its own coroutine (prompts must not block the loop)
    selectedSequence(): SeqRef | undefined;
    runningCue(seq: SeqRef): number | undefined;
    selectedCue(seq: SeqRef): number | undefined;
    readCueCommand(seq: SeqRef, cue: number): string | undefined;   // undefined = no such cue
    writeCueCommand(seq: SeqRef, cue: number, text: string): boolean;
    prompt(title: string, value: string): string | undefined;      // undefined = cancelled
    setupDialog(current: Config): SetupAnswers | undefined;
    runCommands(commands: string[]): void;
}
```

`src/runtime/autozoom.ts`:

```ts
import { normalizeFids, parseArmList } from "../engine/arm-command";
import { evaluate, FaderOutput, FixtureResult, MarkerSample } from "../engine/fixture-state";
import { vec, Vec3 } from "../engine/vec";
import { Desk } from "../desk";
import { fidKey, fmtInt } from "../format";
import { MarkerReadings, PatchFixture, PatchScan } from "../model";
import { Config, CONFIG_KEY, defaultConfig, INSTANCE_KEY, offsetLabel, parseConfig, pruneConfig, serializeConfig } from "../store/config";
import { buildViews, layoutCells, RowState, stateLabel } from "../ui/view-model";

interface Live { cid: number; programmerCid: number; offset: Vec3 }

export class AutoZoom {
    protected config: Config = defaultConfig();
    protected scanned: PatchScan = { fixtures: [], markers: [], problems: [] };
    protected running = false;
    protected message = "";
    protected captureUntil: number | undefined;
    protected captureStartId: string | undefined;
    private results: { [fid: string]: FixtureResult } = {};
    private live: { [fid: string]: Live } = {};
    private sent: { [fid: string]: string } = {};
    private warned: { [key: string]: boolean } = {};
    private dirtyAt: number | undefined;
    private lastSize: number | undefined;

    constructor(protected readonly desk: Desk, private readonly id: string) {}

    // ---------- lifecycle ----------
    Install(): void {
        const loaded = parseConfig(this.desk.loadText(CONFIG_KEY));
        if (loaded.warning !== undefined) this.desk.log(loaded.warning);
        this.config = loaded.config;
        this.desk.saveText(INSTANCE_KEY, this.id);
        this.Rescan();
    }

    Rescan(): void {
        this.scanned = this.desk.scan();
        for (const p of this.scanned.problems) this.desk.log(p);
        this.config = pruneConfig(this.config, this.scanned.fixtures.map(f => f.fid));
        this.desk.install(this.scanned);
        this.desk.buildLayout(layoutCells(this.scanned.fixtures, this.scanned.markers));
        this.sent = {};
        this.results = {};
        this.desk.log(`Found ${fmtInt(this.scanned.fixtures.length)} fixtures and ${fmtInt(this.scanned.markers.length)} markers`);
        this.update();
    }

    Start(): void {
        if (this.running) return;
        this.running = true;
        this.desk.startLoop(this.config.rate, () => this.tick(), () => this.onLoopStopped());
        this.say("AutoZoom started");
    }

    Stop(): void {
        this.saveConfig();
        if (!this.running) return;
        this.running = false;
        this.desk.stopLoop();
        this.update();
        this.say("AutoZoom stopped");
    }

    Toggle(): void {
        if (this.running) this.Stop(); else this.Start();
    }

    // ---------- arms ----------
    Arm(list: string): void {
        this.setArmed(parseArmList(list));
    }

    ArmToggle(fid: number): void {
        const armed = this.config.armed.filter(f => f !== fid);
        if (armed.length === this.config.armed.length) armed.push(fid);
        this.setArmed(armed);
    }

    ArmAll(): void {
        this.setArmed(this.scanned.fixtures.map(f => f.fid));
    }

    DisarmAll(): void {
        this.setArmed([]);
    }

    Status(): void {
        this.desk.log(`AutoZoom ${this.running ? "running" : "stopped"}, ${fmtInt(this.config.armed.length)} armed`);
        for (const f of this.scanned.fixtures) {
            const r = this.results[fidKey(f.fid)];
            this.desk.log(`  ${fmtInt(f.fid)} ${f.name}: ${r === undefined ? "-" : stateLabel(r.state)}`);
        }
    }

    // ---------- loop ----------
    protected tick(): void {
        if (this.desk.loadText(INSTANCE_KEY) !== this.id) {
            this.desk.log("Another AutoZoom instance took over; this one stops");
            this.running = false;
            this.desk.stopLoop();
            return;
        }
        this.update();
        if (this.dirtyAt !== undefined && this.desk.now() - this.dirtyAt >= 1) this.saveConfig();
    }

    protected onLoopStopped(): void {
        // Called when the loop ends; Stop() already released everything when it was a normal stop.
        this.running = false;
    }

    protected update(): void {
        this.beforeUpdate();
        const markers = this.desk.readMarkers();
        const globalSize = this.globalSize();
        for (const f of this.scanned.fixtures) {
            try {
                this.updateFixture(f, markers, globalSize);
            } catch (e) {
                this.warnOnce(`${fmtInt(f.fid)}:${tostring(e)}`, `Fixture ${fmtInt(f.fid)}: ${tostring(e)}`);
            }
        }
        this.render(markers, globalSize);
    }

    protected beforeUpdate(): void {
        // Capture (Task 9) hooks in here.
    }

    private updateFixture(f: PatchFixture, markers: MarkerReadings, globalSize: number): void {
        const key = fidKey(f.fid);
        const cid = this.desk.readMarkerCid(f);
        const live: Live = { cid, programmerCid: this.desk.readProgrammerCid(f), offset: this.desk.readOffset(f) };
        this.live[key] = live;
        let marker: MarkerSample | undefined;
        if (cid !== 0 && this.scanned.markers.some(m => m.cid === cid)) {
            const reading = markers[fidKey(cid)];
            marker = reading !== undefined ? { pos: reading.pos, rot: reading.rot, live: true } : { pos: vec(0, 0, 0), live: false };
        }
        const result = evaluate({
            running: this.running, armed: this.isArmed(f.fid), markerCid: cid, offset: live.offset,
            fixturePos: f.position, optics: f.optics, size: this.sizeFor(f.fid, globalSize), marker,
        });
        this.results[key] = result;
        this.apply(f, result.output);
    }

    private apply(f: PatchFixture, out: FaderOutput): void {
        if (out.kind === "hold") return;
        const key = fidKey(f.fid);
        const signature = out.kind === "release" ? "release" : `${out.zoom}|${out.iris}`;
        if (this.sent[key] === signature) return;
        this.sent[key] = signature;
        if (out.kind === "release") this.desk.releaseFaders(f);
        else this.desk.setFaders(f, out.zoom, out.iris);
    }

    private render(markers: MarkerReadings, globalSize: number): void {
        const rows: RowState[] = [];
        for (const f of this.scanned.fixtures) {
            const key = fidKey(f.fid);
            const live = this.live[key] ?? { cid: 0, programmerCid: 0, offset: vec(0, 0, 0) };
            rows.push({
                fixture: f, armed: this.isArmed(f.fid), markerCid: live.cid, programmerCid: live.programmerCid, offset: live.offset,
                result: this.results[key] ?? { state: "offline", output: { kind: "release" } },
                size: this.sizeFor(f.fid, globalSize), sizeFixed: this.config.size[key] !== undefined,
            });
        }
        let liveMarkers = 0;
        for (const m of this.scanned.markers) if (markers[fidKey(m.cid)] !== undefined) liveMarkers++;
        const left = this.captureUntil === undefined ? undefined : Math.max(0, Math.ceil(this.captureUntil - this.desk.now()));
        this.desk.refreshLayout(buildViews(
            { running: this.running, captureSecondsLeft: left, liveMarkers, globalSize, offsetLabel: offsetLabel(this.config), message: this.message },
            rows, this.scanned.markers, markers,
        ));
    }

    // ---------- helpers ----------
    protected isArmed(fid: number): boolean {
        return this.config.armed.indexOf(fid) >= 0;
    }

    protected fixture(fid: number): PatchFixture | undefined {
        return this.scanned.fixtures.find(f => f.fid === fid);
    }

    private setArmed(fids: number[]): void {
        const known = normalizeFids(fids).filter(fid => this.fixture(fid) !== undefined);
        const unknown = normalizeFids(fids).filter(fid => this.fixture(fid) === undefined);
        if (unknown.length > 0) this.desk.log(`Not AutoZoom fixtures, ignored: ${unknown.map(f => fmtInt(f)).join(", ")}`);
        this.config.armed = known;
        this.markDirty();
        this.update();
    }

    private globalSize(): number {
        const [min, max] = [this.config.range[0], this.config.range[1]];
        const fader = this.desk.readSizeFader();
        if (fader !== undefined) this.lastSize = min + (max - min) * Math.min(100, Math.max(0, fader)) / 100;
        return this.lastSize ?? min;
    }

    protected sizeFor(fid: number, globalSize: number): number {
        return this.config.size[fidKey(fid)] ?? globalSize;
    }

    protected markDirty(): void {
        this.dirtyAt = this.desk.now();
    }

    protected saveConfig(): void {
        this.desk.saveText(CONFIG_KEY, serializeConfig(this.config));
        this.dirtyAt = undefined;
    }

    protected say(message: string): void {
        this.message = message;
        this.desk.log(message);
    }

    private warnOnce(key: string, message: string): void {
        if (this.warned[key]) return;
        this.warned[key] = true;
        this.desk.log(message);
    }
}

export function createAutoZoom(desk: Desk, id: string): AutoZoom {
    return new AutoZoom(desk, id);
}
```

`Stop()` saves the config first, even when the loop never started (the pruned config must reach the show file).

In `src/testing/exports.ts` add `import * as runtime from "../runtime/autozoom";` and export `runtime`.

- [ ] **Step 5: Run tests**

Run: `npm test`
Expected: all pass

- [ ] **Step 6: Commit**

```bash
git add src/desk.ts src/runtime src/testing/exports.ts tests/lib/fakedesk.lua tests/runtime_test.lua tests/run.lua
git commit -m "Add Desk interface and AutoZoom runtime core"
```

---

### Task 9: Capture

**Files:**
- Modify: `src/runtime/autozoom.ts`
- Create: `tests/capture_test.lua`
- Modify: `tests/run.lua`

**Interfaces:**
- Consumes: `armCommand`, `rewriteCueCommand` (Task 6), `Desk.selectedSequence/runningCue/selectedCue/readCueCommand/writeCueCommand/prompt/later` (Task 8), `fmtNum` (Task 3)
- Produces: `AutoZoom.Capture(): void`; `export const CAPTURE_SECONDS = 15`

- [ ] **Step 1: Write the failing tests** `tests/capture_test.lua`

```lua
local T = require("t")
local az = require("az")
local F = require("fakedesk")

local function setup()
  local d = F.new({ fixtures = { F.fixture(101), F.fixture(102) }, markers = { F.marker(1) }, problems = {} })
  local a = az().runtime.createAutoZoom(d, "id")
  a:Install(); a:Arm("102,101"); a:Start()
  d.cues["S12"] = { [1] = "", [2] = [[Go+ Sequence 3; Lua "AZ:Arm('101')"]], [3] = "" }
  return d, a
end
local MAIN = { id = "S12", no = 12, name = "Main" }

T.test("capture stores arms in the running cue after a selection change", function()
  local d, a = setup()
  d.selected = { id = "S1", no = 1, name = "Other" }
  a:Capture(); d:tick()
  T.eq(d.views["capture"].text, "Select a sequence…\n15 s · tap to cancel", "waiting")
  d.selected = MAIN; d.runningCues["S12"] = 2; d.answers = { "2" }
  d:tick(); d:runLaters()
  T.eq(d.lastPrompt.value, "2", "prefilled with running cue")
  T.eq(d.cues["S12"][2], [[Go+ Sequence 3; Lua "AZ:Arm('101,102')"]], "rewritten")
  T.eq(d.logs[#d.logs], "Stored in Seq 12 'Main' cue 2", "feedback")
end)

T.test("selected cue wins over running cue", function()
  local d, a = setup()
  a:Capture(); d.selected = MAIN; d.runningCues["S12"] = 1; d.selectedCues["S12"] = 3; d.answers = { "3" }
  d:tick(); d:runLaters()
  T.eq(d.lastPrompt.value, "3", "prefill"); T.eq(d.cues["S12"][3], [[Lua "AZ:Arm('101,102')"]], "stored")
end)

T.test("capture start explains how to pick an already selected sequence", function()
  local d, a = setup()
  d.selected = MAIN
  a:Capture(); d:tick()
  T.truthy(d.views["message"].text:find("select another sequence first"), "message")
end)

T.test("capture times out and can be cancelled", function()
  local d, a = setup()
  a:Capture(); d.t = 16; d:tick()
  T.eq(d.logs[#d.logs], "Capture timed out", "timeout")
  a:Capture(); a:Capture()
  T.eq(d.logs[#d.logs], "Capture cancelled", "cancel")
end)

T.test("unknown cue or cancelled prompt writes nothing", function()
  local d, a = setup()
  a:Capture(); d.selected = MAIN; d.answers = { "9" }
  d:tick(); d:runLaters()
  T.eq(d.logs[#d.logs], "Seq 12 has no cue 9; nothing stored", "unknown cue")
  a:Capture(); d.selected = { id = "S5", no = 5, name = "Five" }
  d:tick(); d:runLaters()
  T.eq(d.logs[#d.logs], "Capture cancelled", "cancelled prompt")
end)
```

Add `"capture_test",` to `FILES`.

- [ ] **Step 2: Run to verify they fail**

Run: `npm run build:test && lua tests/run.lua`
Expected: FAIL — `attempt to call a nil value (method 'Capture')`

- [ ] **Step 3: Implement** — in `src/runtime/autozoom.ts`:

Add imports `armCommand, rewriteCueCommand` from `../engine/arm-command`, `fmtNum` from `../format`, `SeqRef` from `../model`, and:

```ts
export const CAPTURE_SECONDS = 15;
```

Replace `beforeUpdate()` and add the capture methods to the class:

```ts
    Capture(): void {
        if (this.captureUntil !== undefined) {
            this.endCapture("Capture cancelled");
            return;
        }
        const current = this.desk.selectedSequence();
        this.captureStartId = current?.id;
        this.captureUntil = this.desk.now() + CAPTURE_SECONDS;
        this.message = current === undefined
            ? "Select the sequence to store the arms in"
            : `Select the sequence to store the arms in (to use Seq ${fmtInt(current.no)}, select another sequence first, then it)`;
        this.update();
    }

    protected beforeUpdate(): void {
        if (this.captureUntil === undefined) return;
        if (this.desk.now() > this.captureUntil) {
            this.endCapture("Capture timed out");
            return;
        }
        const seq = this.desk.selectedSequence();
        if (seq === undefined || seq.id === this.captureStartId) return;
        this.captureUntil = undefined;
        this.desk.later(() => this.storeArms(seq));
    }

    private storeArms(seq: SeqRef): void {
        const suggested = this.desk.selectedCue(seq) ?? this.desk.runningCue(seq);
        const answer = this.desk.prompt(`Store AutoZoom arms in Seq ${fmtInt(seq.no)} '${seq.name}': cue number`, suggested === undefined ? "" : fmtNum(suggested));
        if (answer === undefined) {
            this.endCapture("Capture cancelled");
            return;
        }
        const cue = Number(answer.trim());
        const existing = answer.trim() !== "" && cue === cue ? this.desk.readCueCommand(seq, cue) : undefined;
        if (existing === undefined) {
            this.endCapture(`Seq ${fmtInt(seq.no)} has no cue ${answer.trim()}; nothing stored`);
            return;
        }
        const ok = this.desk.writeCueCommand(seq, cue, rewriteCueCommand(existing, armCommand(this.config.armed)));
        this.endCapture(ok ? `Stored in Seq ${fmtInt(seq.no)} '${seq.name}' cue ${fmtNum(cue)}` : `Could not write the command of Seq ${fmtInt(seq.no)} cue ${fmtNum(cue)}`);
    }

    private endCapture(message: string): void {
        this.captureUntil = undefined;
        this.captureStartId = undefined;
        this.say(message);
    }
```

The test "capture start explains…" checks for the words `select another sequence first`: keep that wording.

- [ ] **Step 4: Run tests**

Run: `npm test`
Expected: all pass

- [ ] **Step 5: Commit**

```bash
git add src/runtime/autozoom.ts tests/capture_test.lua tests/run.lua
git commit -m "Add Capture: store current arms into a selected sequence cue"
```

---

### Task 10: Tap-to-program, Setup and Size

**Files:**
- Modify: `src/runtime/autozoom.ts`
- Create: `tests/program_test.lua`
- Modify: `tests/run.lua`

**Interfaces:**
- Consumes: `programCommands`, `releaseCommands` (Task 6), `applySetup` (Task 3), `Desk.runCommands/setupDialog/prompt/later/readProgrammerCid` (Task 8)
- Produces: `AutoZoom.Program(fid: number, cid: number)`, `AutoZoom.Setup()`, `AutoZoom.Size(fid: number)`

- [ ] **Step 1: Write the failing tests** `tests/program_test.lua`

```lua
local T = require("t")
local az = require("az")
local F = require("fakedesk")

local function setup()
  local d = F.new({ fixtures = { F.fixture(101) }, markers = { F.marker(1), F.marker(2) }, problems = {} })
  local a = az().runtime.createAutoZoom(d, "id")
  a:Install()
  return d, a
end

T.test("Program loads marker, offset and zoom/iris minimum", function()
  local d, a = setup()
  a:Program(101, 2)
  T.eq(d.cmds[1], "Fixture 101", "select"); T.eq(d.cmds[2], 'Attribute "XYZ_MArker" At 2', "marker")
  T.eq(#d.cmds, 7, "marker + 3 offsets + zoom + iris + select")
end)

T.test("Program on the cell already in the programmer releases the fixture", function()
  local d, a = setup()
  d.progCids[101] = 2
  a:Program(101, 2)
  T.eq(d.cmds, { "Off Fixture 101" }, "release")
end)

T.test("Program on an unknown fixture only logs", function()
  local d, a = setup()
  a:Program(999, 1)
  T.eq(#d.cmds, 0, "no commands"); T.eq(d.logs[#d.logs], "Fixture 999 is not an AutoZoom fixture", "log")
end)

T.test("Setup applies answers and reports errors", function()
  local d, a = setup()
  d.setupAnswer = { source = "preset", preset = "2.12", x = "0", y = "0", z = "0", min = "1", max = "3", rate = "500" }
  a:Setup(); d:runLaters()
  T.eq(d.logs[#d.logs], "Setup saved", "saved")
  local found = false; for _, l in ipairs(d.logs) do if l == "Refresh rate must be between 1 and 60" then found = true end end
  T.truthy(found, "rate error logged")
  a:Program(101, 1)
  T.eq(d.cmds[3], 'Attribute "XYZ_X" Thru "XYZ_Z" At Preset 2.12', "preset used by Program")
end)

T.test("Size sets, clears and rejects values", function()
  local d, a = setup()
  d.answers = { "1,5" }; a:Size(101); d:runLaters()
  T.eq(d.views["sz 101"].text, "Fixed\n1.5 m", "fixed")
  d.answers = { "" }; a:Size(101); d:runLaters()
  T.eq(d.views["sz 101"].text:sub(1, 6), "Global", "back to global")
  d.answers = { "-2" }; a:Size(101); d:runLaters()
  T.eq(d.logs[#d.logs], "Size must be a number of metres above 0", "rejected")
end)
```

Add `"program_test",` to `FILES`.

- [ ] **Step 2: Run to verify they fail**

Run: `npm run build:test && lua tests/run.lua`
Expected: FAIL — `attempt to call a nil value (method 'Program')`

- [ ] **Step 3: Implement** — in `src/runtime/autozoom.ts` add imports `programCommands, releaseCommands` from `../engine/program` and `applySetup` from `../store/config`, then these methods:

```ts
    Program(fid: number, cid: number): void {
        const f = this.fixture(fid);
        if (f === undefined) {
            this.desk.log(`Fixture ${fmtInt(fid)} is not an AutoZoom fixture`);
            return;
        }
        if (this.desk.readProgrammerCid(f) === cid) {
            this.desk.runCommands(releaseCommands(fid));
        } else {
            this.desk.runCommands(programCommands(fid, cid, f.optics, this.config.offset));
        }
        this.update();
    }

    Setup(): void {
        this.desk.later(() => {
            const answers = this.desk.setupDialog(this.config);
            if (answers === undefined) return;
            const rate = this.config.rate;
            const result = applySetup(this.config, answers);
            for (const e of result.errors) this.desk.log(e);
            this.config = result.config;
            this.markDirty();
            if (this.config.rate !== rate && this.running) this.desk.log("The new refresh rate applies after Stop and Start");
            this.say("Setup saved");
            this.update();
        });
    }

    Size(fid: number): void {
        const f = this.fixture(fid);
        if (f === undefined) {
            this.desk.log(`Fixture ${fmtInt(fid)} is not an AutoZoom fixture`);
            return;
        }
        this.desk.later(() => {
            const key = fidKey(fid);
            const current = this.config.size[key];
            const answer = this.desk.prompt(`Beam size of ${fmtInt(fid)} in metres (empty = global fader)`, current === undefined ? "" : fmtNum(current));
            if (answer === undefined) return;
            const text = answer.trim().replace(",", ".");
            if (text === "") {
                delete this.config.size[key];
            } else {
                const n = Number(text);
                if (n !== n || n <= 0) {
                    this.desk.log("Size must be a number of metres above 0");
                    return;
                }
                this.config.size[key] = n;
            }
            this.markDirty();
            this.update();
        });
    }
```

- [ ] **Step 4: Run tests**

Run: `npm test`
Expected: all pass

- [ ] **Step 5: Commit**

```bash
git add src/runtime/autozoom.ts tests/program_test.lua tests/run.lua
git commit -m "Add tap-to-program, Setup dialog and per-fixture size"
```

---

### Task 11: grandMA3 console layer — patch scan, live reads, variables

**Files:**
- Create: `src/console/ma-globals.d.ts`, `src/console/handles.ts`, `src/console/log.ts`, `src/console/vars.ts`, `src/console/patch.ts`, `src/console/live.ts`, `tests/lib/ma3mock.lua`, `tests/console_patch_test.lua`
- Modify: `src/testing/exports.ts`, `tests/run.lua`

**Interfaces:**
- Consumes: `PatchFixture`, `PatchMarker`, `PatchScan`, `MarkerReadings` (Task 7), `Vec3`, `vec`, `add`, `rotate` (Task 4), `Optics` (Task 4), `fidKey` (Task 3)
- Produces:
  - `children(h: any): any[]`, `num(v: unknown): number | undefined`, `findChild(collection: any, name: string): any`
  - `info(message: string): void`, `warnOnce(key: string, message: string): void`
  - `loadText(key: string): string | undefined`, `saveText(key: string, value: string): void`
  - `scanPatch(): PatchScan`
  - `XYZ_RAW_CENTER`, `XYZ_RAW_PER_METRE`, `APPLY_MARKER_ROTATION`, `TRACKER_ROTATION_PROPS`, `readMarkerCid(f): number`, `readOffset(f): Vec3`, `readProgrammerCid(f): number`, `readMarkers(): MarkerReadings`
  - Lua mock `require("ma3mock")`: `M.reset()`, builders `M.fixtureType(name, modes)`, `M.mode(name, xyz, channels)`, `M.channel(attr, from, to)`, `M.fixture(fid, typeName, modeName, pos, rot, kids)`, `M.group(name, pos, rot, kids)`, `M.marker(cid, name)`, `M.stage(nodes)`, `M.psnSystem(trackers)`, `M.tracker(cid, x, y, z, rot)`, `M.setRt(fid, attr, value, source)`

Constants from probe results: `XYZ_RAW_PER_METRE` = P1 value; `APPLY_MARKER_ROTATION` = P2 answer (true if rotating the marker moved the aim point); `TRACKER_ROTATION_PROPS` = the three tracker property names P2 dumped for rotation; parent position/rotation property names = P9 (the code uses `POSX..POSZ`, `ROTX..ROTZ`; replace with P9's names if different); fixture mode accessor = P9 (`ModeDirect` then `Mode` below).

- [ ] **Step 1: Write the mock** `tests/lib/ma3mock.lua`

```lua
-- grandMA3 API mock for console-layer tests. Handles are tables with Children()/Count().
local M = {}

local function handle(props, kids)
  local h = props or {}
  h._kids = kids or {}
  function h:Children() local out = {} for i, k in ipairs(self._kids) do out[i] = k end return out end
  function h:Count() return #self._kids end
  return h
end
M.handle = handle

function M.reset()
  -- Invalidate handles of the previous test: the bundle caches handles across tests and checks IsObjectValid.
  if M.dataPools then
    for _, dp in ipairs(M.dataPools._kids) do
      dp._deleted = true
      for _, coll in ipairs({ dp.Sequences, dp.Macros, dp.Layouts }) do
        if coll then for _, x in ipairs(coll._kids) do x._deleted = true; for _, e in ipairs(x._kids) do e._deleted = true end end end
      end
    end
  end
  M.printed, M.cmds, M.vars, M.rt, M.timers = {}, {}, {}, {}, {}
  M.subfixtures, M.subIndexOf, M.nextSub = {}, {}, 0
  M.attrs = { XYZ_MArker = 13, XYZ_X = 9, XYZ_Y = 10, XYZ_Z = 11 }
  M.stages = handle({}, {})
  M.fixtureTypes = handle({}, {})
  M.psn = handle({}, {})
  M.dataPools = handle({}, {})
  M.time = 0
end

function Printf(s) M.printed[#M.printed + 1] = s end
function Cmd(s) M.cmds[#M.cmds + 1] = s; if M.onCmd then M.onCmd(s) end; return "Ok" end
CmdIndirect = Cmd
CmdIndirectWait = Cmd
function Patch() return { Stages = M.stages, FixtureTypes = M.fixtureTypes } end
function ShowData() return { DataPools = M.dataPools, PSNProtocol = M.psn } end
function GlobalVars() return "GlobalVars" end
function GetVar(_, k) return M.vars[k] end
function SetVar(_, k, v) M.vars[k] = v end
function GetSubfixtureCount() return M.nextSub end
function GetSubfixture(i) return M.subfixtures[i] end
function GetAttributeIndex(name) return M.attrs[name] end
function GetUIChannelIndex(sub, attr) if sub == nil or attr == nil then return nil end return sub * 1000 + attr end
function GetRTChannel(uich)
  local v = M.rt[uich]
  if v == nil then return nil end
  return { info = { value_after_master = v.value, cue_part = v.source or "DataPool 1.7.1.1.0" } }
end
function Time() return M.time end
function IsObjectValid(h) return h ~= nil and not h._deleted end
function Timer(fn, period, count, cleanup)
  M.timers[#M.timers + 1] = { fn = fn, period = period, left = count == 0 and math.huge or count, cleanup = cleanup }
end
function M.runTimers(n)
  for _ = 1, n or 1 do
    local list = {}
    for _, t in ipairs(M.timers) do list[#list + 1] = t end
    for _, t in ipairs(list) do if t.left > 0 then t.left = t.left - 1; t.fn() end end
  end
end

function M.channel(attr, from, to)
  local fn = handle({ physicalFrom = from, physicalTo = to }, {})
  local logical = handle({ attribute = attr }, { fn })
  return handle({}, { logical })
end
function M.mode(name, xyz, channels) return handle({ name = name, XYZ = xyz, DMXChannels = handle({}, channels) }, {}) end
function M.fixtureType(name, modes)
  local ft = handle({ name = name, DMXModes = handle({}, modes) }, {})
  M.fixtureTypes._kids[#M.fixtureTypes._kids + 1] = ft
  return ft
end
function M.fixture(fid, typeName, modeName, pos, rot, kids)
  pos = pos or { 0, 0, 0 }; rot = rot or { 0, 0, 0 }
  local h = handle({ fid = fid, name = "F" .. fid, IDType = "Fixture", FixtureType = { name = typeName }, ModeDirect = { name = modeName },
    POSX = pos[1], POSY = pos[2], POSZ = pos[3], ROTX = rot[1], ROTY = rot[2], ROTZ = rot[3] }, kids)
  M.subfixtures[M.nextSub] = { fid = fid }
  M.subIndexOf[fid] = M.nextSub
  M.nextSub = M.nextSub + 1
  return h
end
function M.group(name, pos, rot, kids)
  return handle({ fid = "None", name = name, IDType = "Fixture", FixtureType = { name = "Grouping" },
    POSX = pos[1], POSY = pos[2], POSZ = pos[3], ROTX = rot[1], ROTY = rot[2], ROTZ = rot[3] }, kids)
end
function M.marker(cid, name) return handle({ cid = cid, fid = "None", name = name, IDType = "MArker" }, {}) end
function M.stage(nodes) M.stages._kids[#M.stages._kids + 1] = handle({ Fixtures = handle({}, nodes) }, {}) end
function M.tracker(cid, x, y, z, rot)
  local t = handle({ MARKERID = cid, POSITIONX = x, POSITIONY = y, POSITIONZ = z }, {})
  if rot then t.ROTATIONX, t.ROTATIONY, t.ROTATIONZ = rot[1], rot[2], rot[3] end
  return t
end
function M.psnSystem(trackers) M.psn._kids[#M.psn._kids + 1] = handle({}, trackers) end
function M.setRt(fid, attr, value, source) M.rt[M.subIndexOf[fid] * 1000 + M.attrs[attr]] = { value = value, source = source } end

M.reset()
return M
```

- [ ] **Step 2: Write the failing tests** `tests/console_patch_test.lua`

```lua
local T = require("t")
local az = require("az")
local M = require("ma3mock")

local function esprite()
  M.fixtureType("Robin Esprite", {
    M.mode("Mode 1", false, { M.channel("Zoom", 49, 5.5) }),
    M.mode("Mode 2", true, { M.channel("Dimmer", 0, 100), M.channel("Zoom", 49, 5.5), M.channel("Iris", 1, 0.109) }),
  })
end

T.test("scan finds XYZ fixtures with parent positions and markers by CID", function()
  M.reset(); esprite()
  M.stage({
    M.group("SPOTS", { 2, 0, 6 }, { 0, 0, 90 }, { M.fixture(101, "Robin Esprite", "Mode 2", { 1, 0, 0 }) }),
    M.fixture(102, "Robin Esprite", "Mode 1", { 0, 0, 8 }),   -- not XYZ: skipped
    M.marker(1, "Lead"),
  })
  local scan = az().patch.scanPatch()
  T.eq(#scan.fixtures, 1, "fixtures"); local f = scan.fixtures[1]
  T.eq(f.fid, 101, "fid")
  T.near(f.position.x, 2, 1e-9, "x (group rotated 90: child +1 x becomes +1 y)"); T.near(f.position.y, 1, 1e-9, "y"); T.near(f.position.z, 6, 1e-9, "z")
  T.eq(f.optics, { zoomMin = 5.5, zoomMax = 49, irisMin = 0.109, irisMax = 1 }, "optics")
  T.eq(scan.markers, { { cid = 1, name = "Lead" } }, "markers")
  T.eq(f.uich.marker, 0 * 1000 + 13, "marker ui channel")
end)

T.test("fixtures without XYZ attributes are reported", function()
  M.reset(); esprite(); M.attrs.XYZ_MArker = nil
  M.stage({ M.fixture(101, "Robin Esprite", "Mode 2", { 0, 0, 8 }) })
  local scan = az().patch.scanPatch()
  T.eq(#scan.fixtures, 0, "skipped"); T.eq(scan.problems, { "Fixture 101: XYZ attributes not found, skipped" }, "problem")
end)

T.test("live marker, offset and programmer reads", function()
  M.reset(); esprite()
  M.stage({ M.fixture(101, "Robin Esprite", "Mode 2", { 0, 0, 8 }) })
  local f = az().patch.scanPatch().fixtures[1]
  local live = az().live
  T.eq(live.readMarkerCid(f), 0, "no value")
  M.setRt(101, "XYZ_MArker", 1, "Programmer ")
  M.setRt(101, "XYZ_X", live.XYZ_RAW_CENTER + live.XYZ_RAW_PER_METRE, nil)
  T.eq(live.readMarkerCid(f), 1, "cid"); T.eq(live.readProgrammerCid(f), 1, "from programmer")
  T.near(live.readOffset(f).x, 1, 1e-6, "x offset 1 m"); T.near(live.readOffset(f).y, 0, 1e-6, "missing y = 0")
  M.setRt(101, "XYZ_MArker", 1, "DataPool 4.7.6.1000.0")
  T.eq(live.readProgrammerCid(f), 0, "from playback")
end)

T.test("PSN markers", function()
  M.reset()
  M.psnSystem({ M.tracker(1, 1, 2, 1.5, { 0, 0, 45 }), M.tracker(3, 0, 0, 0) })
  local r = az().live.readMarkers()
  T.eq(r["1"].pos, { x = 1, y = 2, z = 1.5 }, "pos"); T.truthy(r["3"], "second tracker")
  T.eq(r["2"], nil, "missing")
end)

T.test("GlobalVars text", function()
  M.reset()
  az().vars.saveText("k", "v"); T.eq(az().vars.loadText("k"), "v", "round trip")
end)
```

Add `"console_patch_test",` to `FILES`. Load the mock before the bundle runs any console code: at the top of `tests/run.lua`, after `package.path`, add `require("ma3mock")`.

- [ ] **Step 3: Run to verify they fail**

Run: `npm run build:test && lua tests/run.lua`
Expected: FAIL — `attempt to index a nil value (field 'patch')`

- [ ] **Step 4: Implement**

`src/console/ma-globals.d.ts`:

```ts
// grandMA3 globals used by AutoZoom that grandma3-ts-types does not declare (or declares too narrowly).
declare function GetRTChannel(uiChannel: number): any;
declare function Time(): number;
declare function StrToHandle(id: string): any;
declare function SelectedSequence(): any;
declare function Timer(callback: () => void, delaySec: number, repeatTimes: number, cleanup?: () => void): void;
```

`src/console/handles.ts`:

```ts
// Helpers for grandMA3 object handles. Always iterate Children(); never index collections by number.

export function children(h: any): any[] {
    if (h === undefined) return [];
    const list = h.Children();
    return list === undefined ? [] : list;
}

export function num(v: unknown): number | undefined {
    if (typeof v === "number") return v;
    if (typeof v === "string") return tonumber(v);
    return undefined;
}

export function findChild(collection: any, name: string): any {
    for (const c of children(collection)) if (c.name === name) return c;
    return undefined;
}
```

`src/console/log.ts`:

```ts
const warned: { [key: string]: boolean } = {};

export function info(message: string): void {
    Printf("[AZ] " + message);
}

export function warnOnce(key: string, message: string): void {
    if (warned[key]) return;
    warned[key] = true;
    Printf("[AZ warning] " + message);
}
```

`src/console/vars.ts`:

```ts
export function loadText(key: string): string | undefined {
    const v = GetVar(GlobalVars(), key);
    return v === undefined ? undefined : tostring(v);
}

export function saveText(key: string, value: string): void {
    SetVar(GlobalVars(), key, value);
}
```

`src/console/patch.ts`:

```ts
import { Optics } from "../engine/beam";
import { add, rotate, vec, Vec3 } from "../engine/vec";
import { fidKey, fmtInt } from "../format";
import { PatchFixture, PatchMarker, PatchScan } from "../model";
import { children, num } from "./handles";

interface Transform { pos: Vec3; rot: Vec3 }
const XYZ_ATTRIBUTES = ["XYZ_MArker", "XYZ_X", "XYZ_Y", "XYZ_Z"];

function readOptics(mode: any): Optics | undefined {
    let zoom: number[] | undefined;
    let iris: number[] | undefined;
    for (const channel of children(mode.DMXChannels)) {
        const logical = children(channel)[0];
        if (logical === undefined) continue;
        const fn = children(logical)[0];
        if (fn === undefined) continue;
        const from = num(fn.physicalFrom), to = num(fn.physicalTo);
        if (from === undefined || to === undefined) continue;
        const range = [Math.min(from, to), Math.max(from, to)];
        if (logical.attribute === "Zoom") zoom = range;
        if (logical.attribute === "Iris") iris = range;
    }
    if (zoom === undefined) return undefined;
    return { zoomMin: zoom[0], zoomMax: zoom[1], irisMin: iris === undefined ? 0 : iris[0], irisMax: iris === undefined ? 0 : iris[1] };
}

// "<fixture type>|<mode>" -> optics, for XYZ-enabled modes with a Zoom channel
function xyzModes(): { [key: string]: Optics } {
    const out: { [key: string]: Optics } = {};
    for (const ft of children(Patch().FixtureTypes)) {
        for (const mode of children(ft.DMXModes)) {
            if (mode.XYZ !== true) continue;
            const optics = readOptics(mode);
            if (optics !== undefined) out[`${ft.name}|${mode.name}`] = optics;
        }
    }
    return out;
}

function modeName(node: any): string | undefined {
    const m = node.ModeDirect ?? node.Mode;
    if (m === undefined) return undefined;
    if (typeof m !== "string") return m.name;
    const space = m.indexOf(" ");                       // "2 Mode 2" -> "Mode 2"
    return space > 0 && num(m.substring(0, space)) !== undefined ? m.substring(space + 1) : m;
}

function subfixtureIndexes(): { [fid: string]: number } {
    const out: { [fid: string]: number } = {};
    const count = GetSubfixtureCount();
    for (let i = 0; i <= count; i++) {
        const sf = GetSubfixture(i);
        const fid = sf === undefined ? undefined : num(sf.fid);
        if (fid !== undefined && out[fidKey(fid)] === undefined) out[fidKey(fid)] = i;
    }
    return out;
}

function transformOf(node: any, parent: Transform): Transform {
    const pos = vec(num(node.POSX) ?? 0, num(node.POSY) ?? 0, num(node.POSZ) ?? 0);
    const rot = vec(num(node.ROTX) ?? 0, num(node.ROTY) ?? 0, num(node.ROTZ) ?? 0);
    // Rotations are summed per axis: exact for single-axis (yaw) rigs, an approximation otherwise.
    return { pos: add(parent.pos, rotate(pos, parent.rot)), rot: add(parent.rot, rot) };
}

export function scanPatch(): PatchScan {
    const scan: PatchScan = { fixtures: [], markers: [], problems: [] };
    const modes = xyzModes();
    const subIndex = subfixtureIndexes();
    const attrIndex: number[] = [];
    for (const a of XYZ_ATTRIBUTES) attrIndex.push(GetAttributeIndex(a) ?? -1);   // -1 = missing (no holes in Lua arrays)

    function walk(node: any, parent: Transform): void {
        if (node.IDType === "MArker") {
            const cid = num(node.cid);
            if (cid !== undefined) scan.markers.push({ cid, name: tostring(node.name ?? `Marker ${fmtInt(cid)}`) });
            return;
        }
        const t = transformOf(node, parent);
        for (const child of children(node)) walk(child, t);   // groups and sub-fixtures
        const fid = num(node.fid);
        const ft = node.FixtureType;
        if (fid === undefined || ft === undefined) return;
        const optics = modes[`${ft.name}|${modeName(node)}`];
        if (optics === undefined) return;                    // not XYZ-enabled, or no zoom
        const sub = subIndex[fidKey(fid)];
        const ui: number[] = [];
        for (const a of attrIndex) {
            const u = sub === undefined || a < 0 ? undefined : GetUIChannelIndex(sub, a);
            if (u === undefined) break;
            ui.push(u);
        }
        if (ui.length < 4) {
            scan.problems.push(`Fixture ${fmtInt(fid)}: XYZ attributes not found, skipped`);
            return;
        }
        scan.fixtures.push({ fid, name: tostring(node.name), position: t.pos, optics, uich: { marker: ui[0], x: ui[1], y: ui[2], z: ui[3] } });
    }

    const origin: Transform = { pos: vec(0, 0, 0), rot: vec(0, 0, 0) };
    for (const stage of children(Patch().Stages)) for (const node of children(stage.Fixtures)) walk(node, origin);
    scan.fixtures.sort((a, b) => a.fid - b.fid);
    scan.markers.sort((a, b) => a.cid - b.cid);
    return scan;
}
```

`src/console/live.ts`:

```ts
import { vec, Vec3 } from "../engine/vec";
import { fidKey } from "../format";
import { MarkerReadings, PatchFixture } from "../model";
import { children, num } from "./handles";

// Raw XYZ_X/Y/Z readback = XYZ_RAW_CENTER + metres * XYZ_RAW_PER_METRE (probe P1).
export const XYZ_RAW_CENTER = 8388608;
export const XYZ_RAW_PER_METRE = 0;               // replace 0 with the P1 value before running on a console
export const APPLY_MARKER_ROTATION = false;       // probe P2
export const TRACKER_ROTATION_PROPS = ["ROTATIONX", "ROTATIONY", "ROTATIONZ"]; // probe P2

function rt(uich: number): any {
    const r = GetRTChannel(uich);
    return r === undefined ? undefined : r.info;
}

export function readMarkerCid(f: PatchFixture): number {
    const v = num(rt(f.uich.marker)?.value_after_master);
    return v === undefined ? 0 : Math.floor(v);
}

export function readProgrammerCid(f: PatchFixture): number {
    const info = rt(f.uich.marker);
    if (info === undefined || !tostring(info.cue_part).startsWith("Programmer")) return 0;
    return Math.floor(num(info.value_after_master) ?? 0);
}

function metres(uich: number): number {
    const v = num(rt(uich)?.value_after_master);
    if (v === undefined || XYZ_RAW_PER_METRE === 0) return 0;
    return (v - XYZ_RAW_CENTER) / XYZ_RAW_PER_METRE;
}

export function readOffset(f: PatchFixture): Vec3 {
    return vec(metres(f.uich.x), metres(f.uich.y), metres(f.uich.z));
}

export function readMarkers(): MarkerReadings {
    const out: MarkerReadings = {};
    for (const system of children(ShowData().PSNProtocol)) {
        for (const tracker of children(system)) {
            const cid = num(tracker.MARKERID);
            if (cid === undefined || cid === 0) continue;
            const pos = vec(num(tracker.POSITIONX) ?? 0, num(tracker.POSITIONY) ?? 0, num(tracker.POSITIONZ) ?? 0);
            const rot = APPLY_MARKER_ROTATION
                ? vec(num(tracker[TRACKER_ROTATION_PROPS[0]]) ?? 0, num(tracker[TRACKER_ROTATION_PROPS[1]]) ?? 0, num(tracker[TRACKER_ROTATION_PROPS[2]]) ?? 0)
                : undefined;
            out[fidKey(cid)] = { pos, rot };
        }
    }
    return out;
}
```

Before Step 5, set `XYZ_RAW_PER_METRE`, `APPLY_MARKER_ROTATION` and `TRACKER_ROTATION_PROPS` to the recorded probe values (P1, P2). The live test computes its raw value from the exported constants, so it passes with any non-zero `XYZ_RAW_PER_METRE`; with `0` the offset test fails (offset reads 0) — that is intended: it blocks shipping without the P1 value.

In `src/testing/exports.ts` add `import * as patch from "../console/patch";`, `import * as live from "../console/live";`, `import * as vars from "../console/vars";` and export `patch, live, vars`.

- [ ] **Step 5: Run tests**

Run: `npm test`
Expected: all pass

- [ ] **Step 6: Commit**

```bash
git add src/console tests/lib/ma3mock.lua tests/console_patch_test.lua tests/run.lua src/testing/exports.ts
git commit -m "Add grandMA3 patch scan with parent transforms and live attribute reads"
```

---

### Task 12: grandMA3 console layer — pool, cues, layout, UI and MaDesk

**Files:**
- Create: `src/console/pool.ts`, `src/console/cues.ts`, `src/console/layout.ts`, `src/console/ui.ts`, `src/console/ma-desk.ts`, `tests/console_desk_test.lua`
- Modify: `tests/lib/ma3mock.lua`, `src/testing/exports.ts`, `tests/run.lua`

**Interfaces:**
- Consumes: Task 11 modules, `Desk` (Task 8), `CellSpec`, `Views`, `SeqRef`, `PatchScan`, `PatchFixture` (Task 7), `Config`, `SetupAnswers` (Task 3), `fmtInt`, `fmtNum` (Task 3)
- Produces:
  - `POOL = "AutoZoom"`, `POOL_ADDR = "DataPool 'AutoZoom'"`, `SIZE_SEQ = "AZ_SIZE"`, `zoomSeqName(fid)`, `irisSeqName(fid)`, `findPool()`, `ensurePool()`, `findSequence(name)`, `ensureFaderSequence(name, fid, attribute, physical)`, `ensureSizeSequence()`, `ensureMacro(name, luaCall)`, `setTemp(name, value)`, `readMaster(name)`
  - `selectedSequence(): SeqRef | undefined`, `runningCue(seq)`, `selectedCue(seq)`, `readCueCommand(seq, cue)`, `writeCueCommand(seq, cue, text)`
  - `LAYOUT = "AutoZoom"`, `macroName(key: string): string`, `buildLayout(cells: CellSpec[])`, `refreshLayout(views: Views)`
  - `prompt(title, value)`, `setupDialog(c: Config)`, `later(fn)`, `startLoop(rate, tick, cleanup)`, `stopLoop()`, `runCommands(cmds)`
  - `class MaDesk implements Desk`
  - Mock additions: `M.pool(name)`, `M.sequence(pool, name, cues)`, `M.layoutObj(pool, name)`, `M.onCmd`, `HandleToStr`, `StrToHandle`, `SelectedSequence`, `TextInput`, `MessageBox`

Probe results used: P6 (running cue via `CurrentChild()`; selected cue accessor), P7 (cue command on the cue's first part, property `Command`), P8 (`SelectedSequence()` changes on pool tap / Select key), P10 (fractional `SetFader`; layout element properties), P11 (`MessageBox` result shape: `result`, `inputs[name]`, `selectors[name]`). Where a result differs from the code below, change the code and the matching mock/test line together.

- [ ] **Step 1: Extend the mock** — append to `tests/lib/ma3mock.lua` before `M.reset()` at the bottom:

```lua
local function find(coll, name) for _, c in ipairs(coll._kids) do if c.name == name then return c end end end
local function remove(coll, name)
  for i, c in ipairs(coll._kids) do if c.name == name then c._deleted = true; table.remove(coll._kids, i); return end end
end

function M.pool(name)
  local p = handle({ name = name }, {})
  p.Sequences = handle({}, {}); p.Macros = handle({}, {}); p.Layouts = handle({}, {})
  M.dataPools._kids[#M.dataPools._kids + 1] = p
  return p
end

function M.sequence(pool, name, cues)
  local s = handle({ name = name, no = #pool.Sequences._kids + 1, faders = {}, master = nil, current = nil }, {})
  function s:SetFader(o) self.faders[o.token] = o.value end
  function s:GetFader(o) return self.master end
  function s:CurrentChild() return self.current end
  for _, c in ipairs(cues or {}) do
    s._kids[#s._kids + 1] = handle({ no = c.no, name = c.name or ("Cue " .. c.no) }, { handle({ Command = c.cmd or "" }, {}) })
  end
  pool.Sequences._kids[#pool.Sequences._kids + 1] = s
  return s
end

function M.layoutObj(pool, name)
  local l = handle({ name = name }, {})
  function l:Append() local e = handle({}, {}); self._kids[#self._kids + 1] = e; return e end
  pool.Layouts._kids[#pool.Layouts._kids + 1] = l
  return l
end

M.onCmd = function(s)
  local created = s:match("^Store DataPool '([^']+)' /nc$")
  if created then if not find(M.dataPools, created) then M.pool(created) end return end
  local p, kind, name = s:match("^Store DataPool '([^']+)' (%a+) '([^']+)' /o /nc$")
  if p then
    local dp = find(M.dataPools, p); if not dp then return end
    if kind == "Sequence" and not find(dp.Sequences, name) then M.sequence(dp, name) end
    if kind == "Macro" and not find(dp.Macros, name) then dp.Macros._kids[#dp.Macros._kids + 1] = handle({ name = name }, {}) end
    if kind == "Layout" and not find(dp.Layouts, name) then M.layoutObj(dp, name) end
    return
  end
  local dp2, lname = s:match("^Delete DataPool '([^']+)' Layout '([^']+)' /nc$")
  if dp2 then local dp = find(M.dataPools, dp2); if dp then remove(dp.Layouts, lname) end end
end

function HandleToStr(h)
  if not M.handleIds[h] then M.handles[#M.handles + 1] = h; M.handleIds[h] = "H" .. #M.handles end
  return M.handleIds[h]
end
function StrToHandle(s) return M.handles[tonumber(s:sub(2))] end
function SelectedSequence() return M.selected end
function TextInput(title, value) M.lastPrompt = { title = title, value = value }; return M.textAnswer end
function MessageBox(o) M.lastBox = o; return M.boxAnswer end
```

and in `M.reset()` add: `M.handles, M.handleIds, M.selected, M.textAnswer, M.boxAnswer = {}, {}, nil, nil, nil`.

- [ ] **Step 2: Write the failing tests** `tests/console_desk_test.lua`

```lua
local T = require("t")
local az = require("az")
local M = require("ma3mock")

local function fixture101()
  return { fid = 101, name = "F101", position = { x = 0, y = 0, z = 8 },
    optics = { zoomMin = 5.5, zoomMax = 49, irisMin = 0.109, irisMax = 1 }, uich = { marker = 13, x = 9, y = 10, z = 11 } }
end

T.test("install creates pool, fader sequences and size sequence once", function()
  M.reset()
  local desk = az().madesk.createMaDesk()
  desk:install({ fixtures = { fixture101() }, markers = {}, problems = {} })
  T.eq(M.cmds[1], "Store DataPool 'AutoZoom' /nc", "pool")
  local joined = table.concat(M.cmds, "\n")
  T.truthy(joined:find('Attribute "Zoom" At Absolute Physical 49', 1, true), "zoom max")
  T.truthy(joined:find('Attribute "Iris" At Absolute Physical 1', 1, true), "iris max")
  T.truthy(joined:find("Store DataPool 'AutoZoom' Sequence 'AZ_ZOOM_101' /o /nc", 1, true), "zoom seq")
  T.truthy(joined:find("Store DataPool 'AutoZoom' Sequence 'AZ_SIZE' /o /nc", 1, true), "size seq")
  local n = #M.cmds
  desk:install({ fixtures = { fixture101() }, markers = {}, problems = {} })
  T.eq(#M.cmds, n, "second install changes nothing")
end)

T.test("faders write Temp and read Master", function()
  M.reset()
  local desk = az().madesk.createMaDesk()
  desk:install({ fixtures = { fixture101() }, markers = {}, problems = {} })
  desk:setFaders(fixture101(), 13.6, 100)
  local pool = M.dataPools._kids[1]
  local function seq(name) for _, s in ipairs(pool.Sequences._kids) do if s.name == name then return s end end end
  T.eq(seq("AZ_ZOOM_101").faders.FaderTemp, 13.6, "zoom temp"); T.eq(seq("AZ_IRIS_101").faders.FaderTemp, 100, "iris temp")
  desk:releaseFaders(fixture101())
  T.eq(seq("AZ_ZOOM_101").faders.FaderTemp, 0, "released")
  T.eq(desk:readSizeFader(), nil, "no master value"); seq("AZ_SIZE").master = 40; T.eq(desk:readSizeFader(), 40, "master")
end)

T.test("layout build tags elements and refresh writes only changes", function()
  M.reset()
  local desk = az().madesk.createMaDesk()
  desk:install({ fixtures = {}, markers = {}, problems = {} })
  desk:buildLayout({ { key = "toggle", x = 0, y = 0, w = 100, h = 60, command = "Toggle()" }, { key = "status", x = 110, y = 0, w = 100, h = 60, command = "" } })
  local layout = M.dataPools._kids[1].Layouts._kids[1]
  T.eq(#layout._kids, 2, "elements"); T.eq(layout._kids[1].Note, "AZ:toggle", "tag"); T.eq(layout._kids[1].PosX, 0, "x")
  T.truthy(table.concat(M.cmds, "\n"):find([[Property 'Command' 'Lua "AZ:Toggle()"']], 1, true), "macro command")
  desk:refreshLayout({ toggle = { text = "Stop", border = "3ECF6EFF", textColor = "E6E8EBFF" } })
  T.eq(layout._kids[1].CustomTextText, "Stop", "text"); T.eq(layout._kids[1].BorderColor, "3ECF6EFF", "border")
  layout._kids[1].CustomTextText = "tampered"
  desk:refreshLayout({ toggle = { text = "Stop", border = "3ECF6EFF", textColor = "E6E8EBFF" } })
  T.eq(layout._kids[1].CustomTextText, "tampered", "unchanged view not rewritten")
end)

T.test("selected sequence, running cue and cue command", function()
  M.reset()
  local pool = M.pool("Default")
  local s = M.sequence(pool, "Main", { { no = 1 }, { no = 2, cmd = "Go+ Sequence 3" } })
  s.current = s._kids[2]; M.selected = s
  local desk = az().madesk.createMaDesk()
  local ref = desk:selectedSequence()
  T.eq(ref.name, "Main", "name"); T.eq(desk:runningCue(ref), 2, "running cue")
  T.eq(desk:readCueCommand(ref, 2), "Go+ Sequence 3", "read"); T.eq(desk:readCueCommand(ref, 9), nil, "missing cue")
  T.eq(desk:writeCueCommand(ref, 2, "X"), true, "write ok"); T.eq(s._kids[2]._kids[1].Command, "X", "written")
end)

T.test("prompt and setup dialog", function()
  M.reset()
  local desk = az().madesk.createMaDesk()
  M.textAnswer = "2.5"; T.eq(desk:prompt("Size", "1"), "2.5", "prompt"); T.eq(M.lastPrompt.value, "1", "default")
  M.boxAnswer = { result = 1, inputs = { ["Offset preset"] = "2.12", ["Offset X (m)"] = "0", ["Offset Y (m)"] = "-1", ["Offset Z (m)"] = "0",
    ["Size min (m)"] = "0.5", ["Size max (m)"] = "5", ["Refresh rate (Hz)"] = "30" }, selectors = { ["Offset source"] = 1 } }
  local a = desk:setupDialog(az().config.defaultConfig())
  T.eq(a.source, "preset", "source"); T.eq(a.preset, "2.12", "preset"); T.eq(a.y, "-1", "y")
  M.boxAnswer = { result = 0 }; T.eq(desk:setupDialog(az().config.defaultConfig()), nil, "cancel")
end)

T.test("loop runs ticks and ignores stale timers after stop", function()
  M.reset()
  local desk = az().madesk.createMaDesk()
  local ticks, cleaned = 0, 0
  desk:startLoop(30, function() ticks = ticks + 1 end, function() cleaned = cleaned + 1 end)
  M.runTimers(3); T.eq(ticks, 3, "ticks")
  desk:stopLoop(); M.runTimers(3)
  T.eq(ticks, 3, "no ticks after stop"); T.eq(cleaned, 1, "cleanup once")
end)
```

Add `"console_desk_test",` to `FILES`.

- [ ] **Step 3: Run to verify they fail**

Run: `npm run build:test && lua tests/run.lua`
Expected: FAIL — `attempt to index a nil value (field 'madesk')`

- [ ] **Step 4: Implement**

`src/console/pool.ts`:

```ts
import { fmtInt, fmtNum } from "../format";
import { children, findChild } from "./handles";
import { warnOnce } from "./log";

export const POOL = "AutoZoom";
export const POOL_ADDR = `DataPool '${POOL}'`;
export const SIZE_SEQ = "AZ_SIZE";

export function zoomSeqName(fid: number): string { return "AZ_ZOOM_" + fmtInt(fid); }
export function irisSeqName(fid: number): string { return "AZ_IRIS_" + fmtInt(fid); }

export function findPool(): any {
    return findChild(ShowData().DataPools, POOL);
}

export function ensurePool(): any {
    let dp = findPool();
    if (dp === undefined) {
        Cmd(`Store ${POOL_ADDR} /nc`);
        dp = findPool();
    }
    if (dp === undefined) throw new Error("Could not create the AutoZoom data pool");
    return dp;
}

const seqCache: { [name: string]: any } = {};

export function findSequence(name: string): any {
    const cached = seqCache[name];
    if (cached !== undefined && IsObjectValid(cached)) return cached;
    const pool = findPool();
    const seq = pool === undefined ? undefined : findChild(pool.Sequences, name);
    if (seq !== undefined) seqCache[name] = seq;
    return seq;
}

// One cue with the attribute at `physical` (its maximum); the Temp fader crossfades the cue's base value to it.
// Clears the programmer: only runs when the sequence is missing.
export function ensureFaderSequence(name: string, fid: number, attribute: string, physical: number): void {
    ensurePool();
    if (findSequence(name) !== undefined) return;
    Cmd("ClearAll");
    Cmd(`Fixture ${fmtInt(fid)}`);
    Cmd(`Attribute "${attribute}" At Absolute Physical ${fmtNum(physical)}`);
    Cmd(`Store ${POOL_ADDR} Sequence '${name}' /o /nc`);
    Cmd("ClearAll");
}

export function ensureSizeSequence(): void {
    ensurePool();
    if (findSequence(SIZE_SEQ) !== undefined) return;
    Cmd("ClearAll");
    Cmd(`Store ${POOL_ADDR} Sequence '${SIZE_SEQ}' /o /nc`);
}

export function ensureMacro(name: string, luaCall: string): void {
    const pool = ensurePool();
    if (findChild(pool.Macros, name) === undefined) Cmd(`Store ${POOL_ADDR} Macro '${name}' /o /nc`);
    if (luaCall === "") return;
    Cmd(`Store ${POOL_ADDR} Macro '${name}'.1 /o /nc`);
    Cmd(`Set ${POOL_ADDR} Macro '${name}'.1 Property 'Command' 'Lua "AZ:${luaCall}"'`);
}

export function setTemp(name: string, value: number): void {
    const seq = findSequence(name);
    if (seq === undefined) {
        warnOnce("missing:" + name, `Sequence ${name} is missing; run Rescan to recreate it`);
        return;
    }
    seq.SetFader({ value, token: "FaderTemp" });
}

export function readMaster(name: string): number | undefined {
    const seq = findSequence(name);
    if (seq === undefined) return undefined;
    const v = seq.GetFader({ token: "FaderMaster" });
    return typeof v === "number" ? v : undefined;
}

export function poolChildren(kind: "Macros" | "Layouts"): any[] {
    const pool = findPool();
    return pool === undefined ? [] : children(pool[kind]);
}
```

`src/console/cues.ts`:

```ts
import { SeqRef } from "../model";
import { children, num } from "./handles";

export function selectedSequence(): SeqRef | undefined {
    const h = SelectedSequence();
    if (h === undefined) return undefined;
    return { id: HandleToStr(h), no: num(h.no) ?? 0, name: tostring(h.name) };
}

function handleOf(seq: SeqRef): any {
    const h = StrToHandle(seq.id);
    return h !== undefined && IsObjectValid(h) ? h : undefined;
}

function cueHandle(seq: SeqRef, no: number): any {
    for (const cue of children(handleOf(seq))) if (num(cue.no) === no) return cue;
    return undefined;
}

export function runningCue(seq: SeqRef): number | undefined {
    const h = handleOf(seq);
    if (h === undefined) return undefined;
    const cue = h.CurrentChild();
    return cue === undefined ? undefined : num(cue.no);
}

// Cue selected in the Sequence Sheet (probe P6). Returns undefined when the console exposes none.
export function selectedCue(_seq: SeqRef): number | undefined {
    return undefined;
}

export function readCueCommand(seq: SeqRef, no: number): string | undefined {
    const cue = cueHandle(seq, no);
    if (cue === undefined) return undefined;
    const part = children(cue)[0];
    return part === undefined ? "" : tostring(part.Command ?? "");
}

export function writeCueCommand(seq: SeqRef, no: number, text: string): boolean {
    const part = children(cueHandle(seq, no))[0];
    if (part === undefined) return false;
    part.Command = text;
    return true;
}
```

If probe P6 recorded an accessor for the cue selected in the Sequence Sheet, implement `selectedCue` with it (read the accessor from the sequence handle, return `num(<cue>.no)`), and add a mock field plus a test case for it in `tests/console_desk_test.lua`. If P6 found none, keep the version above: the Capture prompt then pre-fills the running cue and the user types another number.

`HandleToStr` is declared by grandma3-ts-types; if the compiler reports it missing, add `declare function HandleToStr(h: any): string;` to `src/console/ma-globals.d.ts`.

`src/console/layout.ts`:

```ts
import { CellSpec, Views } from "../model";
import { children, findChild } from "./handles";
import { ensureMacro, ensurePool, POOL_ADDR } from "./pool";

export const LAYOUT = "AutoZoom";
const TAG = "AZ:";

export function macroName(key: string): string {
    return "AZ " + key;
}

let elements: { [key: string]: any } = {};
let written: { [key: string]: string } = {};

export function buildLayout(cells: CellSpec[]): void {
    const pool = ensurePool();
    if (findChild(pool.Layouts, LAYOUT) !== undefined) Cmd(`Delete ${POOL_ADDR} Layout '${LAYOUT}' /nc`);
    Cmd(`Store ${POOL_ADDR} Layout '${LAYOUT}' /o /nc`);
    const layout = findChild(pool.Layouts, LAYOUT);
    if (layout === undefined) throw new Error("Could not create the AutoZoom layout");
    elements = {};
    written = {};
    for (const cell of cells) {
        ensureMacro(macroName(cell.key), cell.command);
        const el = layout.Append();
        el.Object = findChild(pool.Macros, macroName(cell.key));
        el.Action = "Go+";
        el.Note = TAG + cell.key;
        el.PosX = cell.x;
        el.PosY = cell.y;
        el.Width = cell.w;
        el.Height = cell.h;
        el.VisibilityObjectName = "Hidden";
        el.VisibilityIcon = "Hidden";
        el.VisibilityBorder = "Visible";
        elements[cell.key] = el;
    }
}

function findElements(): void {
    const pool = ensurePool();
    elements = {};
    for (const el of children(findChild(pool.Layouts, LAYOUT))) {
        const note = tostring(el.Note ?? "");
        if (note.startsWith(TAG)) elements[note.substring(TAG.length)] = el;
    }
}

export function refreshLayout(views: Views): void {
    for (const key in views) {
        const view = views[key];
        const signature = `${view.text}|${view.border}|${view.textColor}`;
        if (written[key] === signature) continue;
        let el = elements[key];
        if (el === undefined || !IsObjectValid(el)) {
            findElements();
            el = elements[key];
            if (el === undefined) continue;     // user deleted it; Rescan recreates it
        }
        el.CustomTextText = view.text;
        el.CustomTextColor = view.textColor;
        el.BorderColor = view.border;
        written[key] = signature;
    }
}
```

`src/console/ui.ts`:

```ts
import { fmtNum } from "../format";
import { Config, SetupAnswers } from "../store/config";
import { warnOnce } from "./log";

export function prompt(title: string, value: string): string | undefined {
    const answer = TextInput(title, value);
    return answer === undefined ? undefined : tostring(answer);
}

const INPUTS = ["Offset preset", "Offset X (m)", "Offset Y (m)", "Offset Z (m)", "Size min (m)", "Size max (m)", "Refresh rate (Hz)"];

export function setupDialog(c: Config): SetupAnswers | undefined {
    const values = [c.offset.preset, fmtNum(c.offset.values[0]), fmtNum(c.offset.values[1]), fmtNum(c.offset.values[2]),
        fmtNum(c.range[0]), fmtNum(c.range[1]), fmtNum(c.rate)];
    const r: any = MessageBox({
        title: "AutoZoom setup",
        message: "XYZ offset applied when you tap a marker cell, size fader range and refresh rate.",
        commands: [{ value: 1, name: "Save" }, { value: 0, name: "Cancel" }],
        inputs: INPUTS.map((name, i) => ({ name, value: values[i] })),
        selectors: [{ name: "Offset source", selectedValue: c.offset.source === "preset" ? 1 : 2, values: { Preset: 1, Values: 2 } }],
    } as any);
    if (r === undefined || r.result !== 1) return undefined;
    const input = (name: string) => tostring(r.inputs?.[name] ?? "");
    return {
        source: r.selectors?.["Offset source"] === 1 ? "preset" : "values",
        preset: input(INPUTS[0]), x: input(INPUTS[1]), y: input(INPUTS[2]), z: input(INPUTS[3]),
        min: input(INPUTS[4]), max: input(INPUTS[5]), rate: input(INPUTS[6]),
    };
}

// Runs fn in its own Timer coroutine, so a prompt it opens does not pause the update loop.
export function later(fn: () => void): void {
    Timer(() => fn(), 0, 1);
}

let generation = 0;
let activeCleanup: (() => void) | undefined;

// Batches of rate*10 timer calls re-armed by the last call; a generation number makes stale batches no-ops.
export function startLoop(rate: number, tick: () => void, cleanup: () => void): void {
    generation++;
    const gen = generation;
    const batch = Math.max(1, Math.floor(rate * 10));
    let left = 0;
    function step(): void {
        if (gen !== generation) return;
        left--;
        try {
            tick();
        } catch (e) {
            warnOnce("loop:" + tostring(e), "Update failed: " + tostring(e));
        }
        if (left <= 0 && gen === generation) arm();
    }
    function arm(): void {
        left = batch;
        Timer(step, 1 / rate, batch);
    }
    activeCleanup = cleanup;
    arm();
}

export function stopLoop(): void {
    generation++;
    const cleanup = activeCleanup;
    activeCleanup = undefined;
    if (cleanup !== undefined) cleanup();
}

export function runCommands(commands: string[]): void {
    for (const c of commands) Cmd(c);
}
```

`step` and `arm` call each other; TSTL hoists nested function declarations, and the loop test ("loop runs ticks and ignores stale timers after stop") fails if that ever breaks.

`src/console/ma-desk.ts`:

```ts
import { Desk } from "../desk";
import { Vec3 } from "../engine/vec";
import { CellSpec, MarkerReadings, PatchFixture, PatchScan, SeqRef, Views } from "../model";
import { Config, SetupAnswers } from "../store/config";
import * as cues from "./cues";
import * as layout from "./layout";
import * as live from "./live";
import { info } from "./log";
import { scanPatch } from "./patch";
import * as pool from "./pool";
import * as ui from "./ui";
import * as vars from "./vars";

export class MaDesk implements Desk {
    now(): number { return Time(); }
    log(message: string): void { info(message); }
    loadText(key: string): string | undefined { return vars.loadText(key); }
    saveText(key: string, value: string): void { vars.saveText(key, value); }
    scan(): PatchScan { return scanPatch(); }
    install(scan: PatchScan): void {
        pool.ensurePool();
        pool.ensureSizeSequence();
        for (const f of scan.fixtures) {
            pool.ensureFaderSequence(pool.zoomSeqName(f.fid), f.fid, "Zoom", f.optics.zoomMax);
            if (f.optics.irisMax > f.optics.irisMin) pool.ensureFaderSequence(pool.irisSeqName(f.fid), f.fid, "Iris", f.optics.irisMax);
        }
    }
    readMarkerCid(f: PatchFixture): number { return live.readMarkerCid(f); }
    readOffset(f: PatchFixture): Vec3 { return live.readOffset(f); }
    readProgrammerCid(f: PatchFixture): number { return live.readProgrammerCid(f); }
    readMarkers(): MarkerReadings { return live.readMarkers(); }
    readSizeFader(): number | undefined { return pool.readMaster(pool.SIZE_SEQ); }
    setFaders(f: PatchFixture, zoom: number, iris: number | undefined): void {
        pool.setTemp(pool.zoomSeqName(f.fid), zoom);
        if (iris !== undefined && f.optics.irisMax > f.optics.irisMin) pool.setTemp(pool.irisSeqName(f.fid), iris);
    }
    releaseFaders(f: PatchFixture): void {
        pool.setTemp(pool.zoomSeqName(f.fid), 0);
        if (f.optics.irisMax > f.optics.irisMin) pool.setTemp(pool.irisSeqName(f.fid), 0);
    }
    buildLayout(cells: CellSpec[]): void { layout.buildLayout(cells); }
    refreshLayout(views: Views): void { layout.refreshLayout(views); }
    startLoop(rate: number, tick: () => void, cleanup: () => void): void { ui.startLoop(rate, tick, cleanup); }
    stopLoop(): void { ui.stopLoop(); }
    later(fn: () => void): void { ui.later(fn); }
    selectedSequence(): SeqRef | undefined { return cues.selectedSequence(); }
    runningCue(seq: SeqRef): number | undefined { return cues.runningCue(seq); }
    selectedCue(seq: SeqRef): number | undefined { return cues.selectedCue(seq); }
    readCueCommand(seq: SeqRef, cue: number): string | undefined { return cues.readCueCommand(seq, cue); }
    writeCueCommand(seq: SeqRef, cue: number, text: string): boolean { return cues.writeCueCommand(seq, cue, text); }
    prompt(title: string, value: string): string | undefined { return ui.prompt(title, value); }
    setupDialog(current: Config): SetupAnswers | undefined { return ui.setupDialog(current); }
    runCommands(commands: string[]): void { ui.runCommands(commands); }
}

export function createMaDesk(): MaDesk {
    return new MaDesk();
}
```

In `src/testing/exports.ts` add `import * as madesk from "../console/ma-desk";` and export `madesk`.

- [ ] **Step 5: Run tests**

Run: `npm test`
Expected: all pass

- [ ] **Step 6: Commit**

```bash
git add src/console tests/lib/ma3mock.lua tests/console_desk_test.lua tests/run.lua src/testing/exports.ts
git commit -m "Add grandMA3 desk: data pool, faders, cues, layout, dialogs and loop"
```

---

### Task 13: Plugin entry, old code removal, integration test, version 2.0

**Files:**
- Modify: `src/main.ts`, `package.json` (`version`), `tests/run.lua`
- Delete: `src/autozoom_object.ts`, `src/calculate-zoom-iris.ts`, `src/create-macros.ts`, `src/handle-execs.ts`, `src/load-patch.ts`, `src/macros.ts`, `src/types.ts`, `src/utils.ts`, `tests/harness.lua`
- Create: `tests/integration_test.lua`
- Regenerated: `out/autozoom-grandma3.lua`, `out/autozoom-grandma3.xml`

**Interfaces:**
- Consumes: `AutoZoom` (Tasks 8–10), `MaDesk` (Task 12)
- Produces: plugin `main(display, args)`; global `AZ: AutoZoom`

- [ ] **Step 1: Write the failing integration test** `tests/integration_test.lua`

```lua
-- Runs the real plugin bundle (out/autozoom-grandma3.lua) against the grandMA3 mock.
local T = require("t")
local M = require("ma3mock")

local function show()
  M.reset()
  M.fixtureType("Robin Esprite", { M.mode("Mode 2", true, { M.channel("Zoom", 49, 5.5), M.channel("Iris", 1, 0.109) }) })
  M.stage({ M.fixture(101, "Robin Esprite", "Mode 2", { 0, 0, 10 }), M.fixture(102, "Robin Esprite", "Mode 2", { 4, 0, 10 }), M.marker(1, "Lead") })
  M.psnSystem({ M.tracker(1, 0, 0, 0) })
  AZ = nil
end

local function seq(name)
  for _, dp in ipairs(M.dataPools._kids) do for _, s in ipairs(dp.Sequences._kids) do if s.name == name then return s end end end
end
local function element(key)
  for _, dp in ipairs(M.dataPools._kids) do for _, l in ipairs(dp.Layouts._kids) do
    for _, e in ipairs(l._kids) do if e.Note == "AZ:" .. key then return e end end end end
end

T.test("plugin installs, follows a cue marker and drives the zoom fader", function()
  show()
  local main = dofile("out/autozoom-grandma3.lua")
  main(nil, nil)
  T.truthy(seq("AZ_ZOOM_101"), "zoom sequence"); T.truthy(element("arm 101"), "layout element")
  AZ:Arm("101")
  M.setRt(101, "XYZ_MArker", 1, "DataPool 1.7.1.1.0")
  seq("AZ_SIZE").master = 100 * (2 - 0.5) / (5 - 0.5)   -- 2 m
  M.runTimers(2)
  T.near(seq("AZ_ZOOM_101").faders.FaderTemp, 13.6, 0.05, "zoom temp")
  T.eq(element("st 101").CustomTextText:sub(1, 8), "Tracking", "state cell")
  T.eq(element("status").CustomTextText:sub(1, 7), "Running", "status cell")
end)

T.test("running the plugin again replaces the instance", function()
  show()
  local main = dofile("out/autozoom-grandma3.lua")
  main(nil, nil); local first = AZ
  main(nil, nil)
  T.truthy(AZ ~= first, "new instance")
  M.runTimers(3)   -- old timers must be no-ops and must not error
  T.eq(element("status").CustomTextText:sub(1, 7), "Running", "still running")
end)
```

In `tests/run.lua` add `"integration_test",` to `FILES`.

- [ ] **Step 2: Run to verify it fails**

Run: `npm run build && npm run build:test && lua tests/run.lua`
Expected: FAIL — the old `main` creates the 1.x object (`attempt to call a nil value (method 'Arm')`)

- [ ] **Step 3: Replace the entry** `src/main.ts`

```ts
import { MaDesk } from "./console/ma-desk";
import { AutoZoom } from "./runtime/autozoom";

declare let AZ: AutoZoom | undefined;

function main(_display: unknown, _args: unknown): void {
    if (AZ !== undefined) {
        try {
            AZ.Stop();
        } catch (e) {
            Printf("[AZ] The previous AutoZoom instance did not stop cleanly: " + tostring(e));
        }
    }
    const id = string.format("%d-%d", os.time(), math.random(1, 1000000));
    AZ = new AutoZoom(new MaDesk(), id);
    Printf("[AZ] AutoZoom 2.0.0 by Naostage");
    AZ.Install();
    AZ.Start();
}

// @ts-ignore: grandMA3 runs the chunk's returned function
return main;
```

- [ ] **Step 4: Delete the 1.x code and harness**

```bash
git rm src/autozoom_object.ts src/calculate-zoom-iris.ts src/create-macros.ts src/handle-execs.ts src/load-patch.ts src/macros.ts src/types.ts src/utils.ts tests/harness.lua
```

In `package.json`: set `"version": "2.0.0.0"` and change the test script to `"test": "npm run build && npm run build:test && lua tests/run.lua"`.

- [ ] **Step 5: Run tests**

Run: `npm test`
Expected: all pass (unit + integration). `out/autozoom-grandma3.xml` now says `Version="2.0.0.0"`.

- [ ] **Step 6: Commit**

```bash
git add -A src tests package.json out
git commit -m "AutoZoom 2.0: layout UI entry point, remove 1.x code"
```

---

### Task 14: Documentation and console checklist

**Files:**
- Modify: `README.md`
- Create: `docs/console-test-checklist.md`

**Interfaces:**
- Consumes: the commands and behaviour from Tasks 8–13

- [ ] **Step 1: Rewrite `README.md`** with these sections, keeping the logo line and the Developing section's tooling notes:

```markdown
# Auto Zoom grandma3 plugin <img src="docs/assets/naostage-logo-white.svg" alt="drawing" width="120" align="right" height="100%">

AutoZoom keeps a constant beam size on tracked performers: it reads which marker each fixture follows
(from your cues), the marker position (PSN) and the fixture position, and drives zoom and iris.

Requires grandMA3 2.5 or later.

## Installation
1. Copy `out/autozoom-grandma3.lua` and `out/autozoom-grandma3.xml` to `gma3_library/datapools/plugins` (USB stick) or `C:\ProgramData\MALightingTechnology\gma3_library\datapools\plugins` (onPC).
2. Import the plugin and run it. It creates the **AutoZoom** data pool with the **AutoZoom** layout, one `AZ_ZOOM_<fid>` / `AZ_IRIS_<fid>` sequence per fixture and the `AZ_SIZE` sequence. Creating missing sequences clears the programmer.
3. Open the AutoZoom layout in a view.

Fixtures appear when their fixture type mode has XYZ enabled and a Zoom channel. Set the zoom and iris physical ranges of the fixture type to the manufacturer's optical data.

## Using the layout
- **Arm column**: tap to arm/disarm a fixture. Only armed fixtures are driven.
- **Marker cells**: a lit cell shows the marker the fixture currently follows (green tracking, amber no PSN data, grey disarmed). Tap a cell to put that fixture in the programmer on that marker, with the Setup XYZ offset and zoom/iris at minimum (red **P**); tap it again to release it. Store your cue as usual.
- **State, Distance, Zoom, Iris**: live values. "Too wide"/"Too small" mean the beam size is outside the fixture's optics.
- **Size**: "Global" follows the `AZ_SIZE` fader (range set in Setup); tap to type a fixed size in metres.
- **Capture**: tap, then select a sequence (pool tile or executor Select key). Confirm the cue number (pre-filled with the running cue). The current arms are written into that cue as `Lua "AZ:Arm('101,102')"`; replaying the cue restores them. If the target sequence is already selected, select another sequence first.
- **Setup**: XYZ offset source (preset number or X/Y/Z values), size fader range, refresh rate.
- **Start/Stop**: stopping releases every AutoZoom fader.

## Commands
`Lua "AZ:Start()"`, `Stop()`, `Toggle()`, `Arm('101,102')`, `ArmToggle(101)`, `ArmAll()`, `DisarmAll()`, `Capture()`, `Program(101, 1)`, `Setup()`, `Size(101)`, `Rescan()`, `Status()`.
Run `Rescan()` after changing the patch (fixtures, positions, optics, markers).

## How it works
Each `AZ_ZOOM_<fid>` sequence holds zoom at maximum; its Temp fader crossfades from the cue's zoom (minimum) to it. Iris works the same way when the beam must be smaller than the minimum zoom allows.

## Developing
`npm install`, then `npm run build`. Tests: `npm test` (needs `lua` 5.3+ on the PATH; on NixOS `nix shell nixpkgs#nodejs_22 nixpkgs#lua5_4`). Design: `docs/superpowers/specs/2026-10-03-autozoom-layout-ux-design.md`. Prototype: `docs/prototype/autozoom-layout-prototype.html`.
```

- [ ] **Step 2: Write `docs/console-test-checklist.md`**

```markdown
# AutoZoom 2.0 console test checklist (grandMA3 onPC 2.5.x)

Tick each line on a copy of a real show. Note the System Monitor output for any failure.

1. [ ] Import and run the plugin: "AutoZoom 2.0.0", "Found N fixtures and M markers"; data pool AutoZoom exists with layout, AZ_ZOOM/AZ_IRIS per fixture, AZ_SIZE.
2. [ ] Layout opens in a view; header shows Running and PSN x/y; one row per XYZ fixture; marker columns by name/CID.
3. [ ] Tap an Arm cell: border turns green; tap again: grey.
4. [ ] Tap a marker cell: programmer gets XYZ_MArker, XYZ offset from Setup, zoom/iris minimum; cell shows red P; tap again releases.
5. [ ] Store a cue with that programmer, clear, play the cue: matrix cell lit green, state Tracking, zoom % changes as the performer moves.
6. [ ] Move AZ_SIZE: beam size follows; set a fixed size on one fixture: it ignores the fader.
7. [ ] Stop the PSN source: state "No PSN data", zoom holds.
8. [ ] Capture: tap, select the sequence, confirm the running cue: cue command contains `Lua "AZ:Arm('…')"`; disarm all, replay the cue: arms restored.
9. [ ] Capture into a cue selected in the Sequence Sheet (if supported) and into a typed cue number.
10. [ ] Setup: switch offset source to a preset, tap a marker cell: XYZ comes from the preset only.
11. [ ] Save the show, load another show, load it back, run the plugin: arms, sizes and Setup are kept.
12. [ ] Run the plugin twice: only one instance updates (no doubled System Monitor output).
13. [ ] Stop: zoom/iris return to the cue values; layout shows Offline.
14. [ ] Rescan after moving a fixture group: distances change accordingly.
15. [ ] Watch the update rate at 30 Hz with all fixtures armed: no UI stutter.
```

- [ ] **Step 3: Run tests**

Run: `npm test`
Expected: all pass

- [ ] **Step 4: Commit**

```bash
git add README.md docs/console-test-checklist.md
git commit -m "Document AutoZoom 2.0 and add the console test checklist"
```
