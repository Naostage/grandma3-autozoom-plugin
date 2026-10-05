local T = require("t")
local az = require("az")
local M = require("ma3mock")

local function esprite()
  M.fixtureType("Robin Esprite", {
    M.mode("Mode 1", false, { M.channel("Zoom", 49, 5.5) }),
    M.mode("Mode 2", true, { M.channel("Dimmer", 0, 100), M.channel("Zoom", 49, 5.5), M.channel("Iris", 1, 0.109) }),
  })
end

local function space(min, max)
  return { min = { x = min[1], y = min[2], z = min[3] }, max = { x = max[1], y = max[2], z = max[3] } }
end

T.test("scan finds XYZ fixtures with parent positions and markers by CID", function()
  M.reset(); esprite()
  local ts = M.space("MArker 1 Target", { -100, -100, 0 }, { 100, 100, 100 })
  M.stage({
    M.group("SPOTS", { 2, 0, 6 }, { 0, 0, 90 }, { M.fixture(101, "Robin Esprite", "Mode 2", { 1, 0, 0 }) }),
    M.fixture(102, "Robin Esprite", "Mode 1", { 0, 0, 8 }),   -- not XYZ: skipped
    M.marker(1, "Lead", ts),
  }, { M.space("Stage", { -35, -35, 0 }, { 35, 35, 35 }), ts })
  local scan = az().patch.scanPatch()
  T.eq(#scan.fixtures, 1, "fixtures"); local f = scan.fixtures[1]
  T.eq(f.fid, 101, "fid")
  T.near(f.position.x, 2, 1e-9, "x (group rotated 90: child +1 x becomes +1 y)"); T.near(f.position.y, 1, 1e-9, "y"); T.near(f.position.z, 6, 1e-9, "z")
  T.eq(f.optics, { zoomMin = 5.5, zoomMax = 49, irisMin = 0.109, irisMax = 1 }, "optics")
  T.eq(scan.markers, { { cid = 1, name = "Lead", targetSpace = space({ -100, -100, 0 }, { 100, 100, 100 }) } }, "markers")
  T.eq(f.uich.marker, 0 * 1000 + 13, "marker ui channel")
end)

T.test("marker target space falls back to '<name> Target' in stage.Spaces", function()
  M.reset()
  M.stage({ M.marker(1, "Lead") }, { M.space("Stage", { -35, -35, 0 }, { 35, 35, 35 }), M.space("Lead Target", { -10, -20, 0 }, { 10, 20, 5 }) })
  T.eq(az().patch.scanPatch().markers[1].targetSpace, space({ -10, -20, 0 }, { 10, 20, 5 }), "named space")
end)

T.test("marker TARGETSPACE given as a name string is looked up in stage.Spaces", function()
  M.reset()
  local m = M.marker(1, "Lead"); m.TARGETSPACE = "2 'Custom Space'"
  M.stage({ m }, { M.space("Stage", { -35, -35, 0 }, { 35, 35, 35 }), M.space("Custom Space", { -10, -20, 0 }, { 10, 20, 5 }) })
  T.eq(az().patch.scanPatch().markers[1].targetSpace, space({ -10, -20, 0 }, { 10, 20, 5 }), "string ref")
end)

T.test("marker with no target space gets the default", function()
  M.reset()
  M.stage({ M.marker(1, "Lead") })
  T.eq(az().patch.scanPatch().markers[1].targetSpace, az().live.DEFAULT_TARGET_SPACE, "default")
  T.eq(az().live.DEFAULT_TARGET_SPACE, space({ -100, -100, 0 }, { 100, 100, 100 }), "default values")
end)

T.test("fixtures without XYZ attributes are reported", function()
  M.reset(); esprite(); M.attrs.XYZ_MArker = nil
  M.stage({ M.fixture(101, "Robin Esprite", "Mode 2", { 0, 0, 8 }) })
  local scan = az().patch.scanPatch()
  T.eq(#scan.fixtures, 0, "skipped"); T.eq(scan.problems, { "Fixture 101: XYZ attributes not found, skipped" }, "problem")
end)

T.test("live marker CID and programmer reads", function()
  M.reset(); esprite()
  M.stage({ M.fixture(101, "Robin Esprite", "Mode 2", { 0, 0, 8 }) })
  local f = az().patch.scanPatch().fixtures[1]
  local live = az().live
  T.eq(live.readMarkerCid(f), 0, "no value")
  M.setRt(101, "XYZ_MArker", 1, "Programmer ")
  T.eq(live.readMarkerCid(f), 1, "cid"); T.eq(live.readProgrammerCid(f), 1, "from programmer")
  M.setRt(101, "XYZ_MArker", 1, "DataPool 4.7.6.1000.0")
  T.eq(live.readProgrammerCid(f), 0, "from playback")
end)

T.test("offset is converted through the followed marker's target space", function()
  M.reset(); esprite()
  local ts = M.space("MArker 1 Target", { -100, -100, 0 }, { 100, 100, 100 })
  M.stage({ M.fixture(101, "Robin Esprite", "Mode 2", { 0, 0, 8 }), M.marker(1, "Lead", ts) }, { M.space("Stage", { -35, -35, 0 }, { 35, 35, 35 }), ts })
  local scan = az().patch.scanPatch(); local f = scan.fixtures[1]
  local live = az().live
  M.setRt(101, "XYZ_MArker", 1)
  M.setRt(101, "XYZ_X", 8472495); M.setRt(101, "XYZ_Y", 8556379); M.setRt(101, "XYZ_Z", 83885)
  local o = live.readOffset(f, scan.markers)
  T.near(o.x, 1, 1e-3, "x"); T.near(o.y, 2, 1e-3, "y"); T.near(o.z, 0.5, 1e-3, "z")
  M.setRt(101, "XYZ_MArker", 0)
  o = live.readOffset(f, scan.markers)
  T.eq(o, { x = 0, y = 0, z = 0 }, "no marker -> zero")
  M.setRt(101, "XYZ_MArker", 1); M.rt[M.subIndexOf[101] * 1000 + M.attrs.XYZ_Y] = nil
  T.near(live.readOffset(f, scan.markers).y, 0, 1e-9, "missing y = 0")
  M.setRt(101, "XYZ_MArker", 7)   -- unknown marker: default space
  T.near(live.readOffset(f, scan.markers).x, -100 + 200 * 8472495 / 16777216, 1e-6, "default space")
end)

T.test("rawToMetres matches stage-space probe values", function()
  local live = az().live
  T.near(live.rawToMetres(8628281, -35, 35), 1.0, 1e-3, "x")
  T.near(live.rawToMetres(239671, 0, 35), 0.5, 1e-3, "z")
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
