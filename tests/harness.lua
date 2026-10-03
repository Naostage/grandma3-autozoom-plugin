-- Regression tests : runs the compiled plugin (out/autozoom-grandma3.lua) against a minimal grandMA3 API mock.
-- Usage (from the repo root, after `npm run build`) : lua tests/harness.lua

local LOG = {}
function Printf(s) LOG[#LOG+1] = s end
local CMDS = {}
function Cmd(s) CMDS[#CMDS+1] = s end
CmdIndirect = Cmd
CmdIndirectWait = Cmd
local TIMERS = {}
function Timer(fn, period, count) TIMERS[#TIMERS+1] = {fn=fn, left=count} end
local function tick(n)
  for _ = 1, n do
    for _, t in ipairs(TIMERS) do
      if t.left > 0 then t.left = t.left - 1; t.fn() end
    end
  end
end

local function list(t)
  t.count = #t
  t.Count = function(self) return #self end
  t.Children = function(self) local c = {} for i = 1, #self do c[i] = self[i] end return c end
  return t
end

-- Sequences record every SetFader call
local SEQ_SET = {}
local function seq(name, master)
  return {Name=name,
          SetFader=function(self, o) SEQ_SET[#SEQ_SET+1] = {self.Name, o.value, o.token} end,
          GetFader=function(self, o) return master or 0 end}
end
-- grandMA3 2.5 layout : sequences are no longer child 6 of a datapool, they are reached by name
local function makePools(pools)
  local dps = list({})
  for i, seqs in ipairs(pools) do
    dps[i] = {name="Pool"..i, Sequences=list(seqs), [6]=list({})}
  end
  dps.count = #pools
  return dps
end
local DATAPOOLS
local PSN = list({ list({}) })
function ShowData() return {DataPools=DATAPOOLS, PSNProtocol=PSN} end

-- Fixture type : zoom 4..50 deg (DMX order reversed), iris physical 0.1..1
local function cf(from, to) return list({ {physicalFrom=from, physicalTo=to} }) end
local function chan(attr, from, to)
  local lc = {attribute=attr, Children=function() return cf(from, to) end}
  return {Children=function() return {lc} end}
end
local FT = {Name="Spot", id=1,
            DMXModes={ {Name="Mode1", XYZ=true, DMXChannels={chan("Zoom", 50, 4), chan("Iris", 1, 0.1)}} }}
local STAGE_FIXTURES
function Patch()
  return {FixtureTypes={Children=function() return {FT} end},
          Stages=list({ {Fixtures=STAGE_FIXTURES} })}
end
local function fixture(fid, x, y, z) return {IDType="Fixture", fid=fid, cid=fid, Name="F"..fid, name="F"..fid, FixtureType={Name="Spot"}, POSX=x, POSY=y, POSZ=z} end
local function marker(fid, cid) return {IDType="MArker", fid=fid, cid=cid, name="M"..fid, FixtureType={Name="Marker"}} end
local function tracker(cid, x, y, z) return {MARKERID=cid, POSITIONX=x, POSITIONY=y, POSITIONZ=z} end

-- Fixtures 101..10n at 10 m height, marker 1001 at the origin
local function setup(nFix, pools)
  LOG, CMDS, TIMERS, SEQ_SET = {}, {}, {}, {}
  local fx = {}
  for i = 1, nFix do fx[i] = fixture(100+i, 0, 0, 10) end
  fx[#fx+1] = marker(1001, 1)
  STAGE_FIXTURES = list(fx)
  PSN[1] = list({ tracker(1, 0, 0, 0) })
  if pools == nil then
    local seqs = {}
    for i = 1, nFix do seqs[#seqs+1] = seq("AZ_ZOOM_"..(100+i)); seqs[#seqs+1] = seq("AZ_IRIS_"..(100+i)) end
    pools = { seqs }
  end
  DATAPOOLS = makePools(pools)
  AZ = nil
  local main = dofile("out/autozoom-grandma3.lua")
  main(nil, nil, nil)
end
local function lastSet(name)
  local v
  for _, s in ipairs(SEQ_SET) do if s[1] == name then v = s[2] end end
  return v
end

local failures, total = 0, 0
local function test(name, fn)
  total = total + 1
  local ok, err = pcall(fn)
  if ok then print("ok   - " .. name) else failures = failures + 1; print("FAIL - " .. name .. "\n       " .. tostring(err)) end
end
local function eq(actual, expected, what)
  if actual ~= expected then error((what or "value") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2) end
end

------------------------------------------------------------------

test("zoom/iris math at 10 m (zoom 4-50 deg, iris 0.1-1)", function()
  setup(1)
  AZ:EnableFixture(101, 1001, 2); AZ:Enable()
  -- {beam size (m), zoom fader, iris fader}
  local cases = {
    {0.05, 0, 0},     -- smaller than the smallest iris : clamped to 0
    {0.2, 0, 21},     -- 0.2 / 0.698 = 0.287 -> (0.287-0.1)/0.9
    {0.5, 0, 68},
    {2, 16, 100},     -- 11.42 deg -> (11.42-4)/46
    {5, 52, 100},
    {15, 100, 100},   -- wider than max zoom
  }
  for _, c in ipairs(cases) do
    AZ.enabledFixtures[1].beamSize = c[1]
    tick(1)
    eq(AZ.enabledFixtures[1].fixture.lastZoom, c[2], "zoom for " .. c[1] .. " m")
    eq(AZ.enabledFixtures[1].fixture.lastIris, c[3], "iris for " .. c[1] .. " m")
  end
end)

test("first computed values are sent even when zoom is 0", function()
  setup(1)
  AZ:EnableFixture(101, 1001, 0.3); AZ:Enable(); tick(1)
  eq(lastSet("AZ_ZOOM_101"), 0, "zoom fader")
  eq(lastSet("AZ_IRIS_101"), 37, "iris fader")
end)

test("sequence lookup finds the first sequence of a pool (2.5 datapool layout)", function()
  setup(1, { { seq("AZ_ZOOM_101"), seq("AZ_IRIS_101") } })
  AZ:EnableFixture(101, 1001, 2); AZ:Enable(); tick(1)
  eq(lastSet("AZ_ZOOM_101"), 16, "zoom fader")
end)

test("sequences in a second datapool (AZ datapool mode)", function()
  setup(1, { { seq("A"), seq("B") }, { seq("AZ_ZOOM_101"), seq("AZ_IRIS_101") } })
  AZ:EnableFixture(101, 1001, 0.5); AZ:Enable(); tick(1)
  eq(lastSet("AZ_ZOOM_101"), 0, "zoom fader")
  eq(lastSet("AZ_IRIS_101"), 68, "iris fader")
end)

test("disabling one fixture keeps the others updating", function()
  setup(3)
  AZ:EnableFixture(101, 1001, 2); AZ:EnableFixture(102, 1001, 2); AZ:EnableFixture(103, 1001, 2)
  AZ:Enable(); tick(1)
  AZ:DisableFixture(101)
  eq(#AZ.enabledFixtures, 2, "enabled fixtures")
  AZ.enabledFixtures[1].beamSize = 5; AZ.enabledFixtures[2].beamSize = 5
  tick(1)
  eq(lastSet("AZ_ZOOM_102"), 52, "fixture 102 zoom")
  eq(lastSet("AZ_ZOOM_103"), 52, "fixture 103 zoom")
  AZ:EnableFixture(103, 1001, 1)  -- updating an existing entry must not crash
end)

test("rescanning the patch keeps enabled fixtures following their marker", function()
  setup(1)
  AZ:EnableFixture(101, 1001, 2); AZ:Enable(); tick(1)
  AZ:ScanPatch()
  PSN[1] = list({ tracker(1, 0, 0, 5) })  -- marker now 5 m below the fixture
  tick(1)
  eq(AZ.enabledFixtures[1].marker.position.z, 5, "marker z")
  eq(AZ.enabledFixtures[1].marker, AZ.patch_info.markers[1], "marker object")
  eq(lastSet("AZ_ZOOM_101"), 40, "zoom fader") -- 2*atan(1/5) = 22.6 deg -> 40.5
end)

test("missing size fader falls back to fixed beam size and warns once", function()
  setup(1)
  AZ:EnableFixture(101, 1001, 2); AZ:EnableSizeFader(101); AZ:Enable()
  LOG = {}
  tick(5)
  eq(lastSet("AZ_ZOOM_101"), 16, "zoom fader")
  local warnings = 0
  for _, l in ipairs(LOG) do if l:find("AZ_SIZE_101 not found") then warnings = warnings + 1 end end
  eq(warnings, 1, "warnings")
end)

test("size fader drives the beam size", function()
  setup(1, { { seq("AZ_ZOOM_101"), seq("AZ_IRIS_101"), seq("AZ_SIZE", 50) } })
  AZ:EnableFixture(101, 1001, 9); AZ:EnableGlobalSizeFader(); AZ:SetSizeFaderRange(0, 4); AZ:Enable(); tick(1)
  eq(lastSet("AZ_ZOOM_101"), 16, "zoom fader") -- 50% of 0..4 m = 2 m
end)

test("disable/enable does not stack update timers", function()
  setup(1)
  AZ:EnableFixture(101, 1001, 2); AZ:Enable(); tick(10)
  AZ:Disable(); tick(1); AZ:Enable()
  SEQ_SET = {}
  AZ.enabledFixtures[1].beamSize = 5
  tick(1)
  eq(#SEQ_SET, 1, "SetFader calls in one frame")
end)

test("fixture without iris never moves an iris fader", function()
  local saved = FT.DMXModes
  FT.DMXModes = { {Name="Mode1", XYZ=true, DMXChannels={chan("Zoom", 50, 4)}} }
  setup(1)
  AZ:EnableFixture(101, 1001, 2); AZ:Enable(); tick(1)
  AZ:EnableFixture(101, 1001, 3)
  FT.DMXModes = saved
  eq(lastSet("AZ_IRIS_101"), nil, "iris fader")
end)

test("AZ datapool creation when DataPools[i] is nil for some i < Count() (2.5 crash)", function()
  setup(1)
  DATAPOOLS.Count = function(self) return #self + 1 end
  AZ:EnableFixture(101, 1001, 2); AZ:EnableDatapool()
  CMDS = {}
  AZ:CreateAZSequences(101)
  assert(table.concat(CMDS, "\n"):find("Store DataPool 'AZ'", 1, true), table.concat(CMDS, "\n"))
end)

test("CreateAZSequences uses quoted attributes and physical values", function()
  setup(1)
  AZ:EnableFixture(101, 1001, 2)
  CMDS = {}
  AZ:CreateAZSequences(101)
  local all = table.concat(CMDS, "\n")
  assert(all:find('Attribute "Zoom" At Absolute Physical 50', 1, true), all)
  assert(all:find('Attribute "Iris" At Absolute Physical 1', 1, true), all)
end)

print(string.format("\n%d/%d passed", total - failures, total))
os.exit(failures == 0 and 0 or 1)
