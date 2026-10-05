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
  d.saved["AutoZoom.config"] = '{"disarmed":[102]}'
  a:Install()
  T.eq(d.saved["AutoZoom.instance"], "id-1", "instance stamp")
  T.truthy(d.installed, "install called"); T.truthy(#d.cells > 0, "layout built")
  T.eq(d.logs[1], "Fixture 900: XYZ attributes not found, skipped", "scan problem logged")
  T.eq(d.views["arm 101"].border, az().view.COLORS.on, "101 armed from config")
  T.eq(d.views["arm 102"].border, az().view.COLORS.idle, "102 disarmed from config")
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
  d.saved["AutoZoom.config"] = '{"disarmed":[102],"size":{"101":2}}'
  a:Install(); a:Start()
  d.cids[101] = 1; d.markers["1"] = { pos = { x = 0, y = 0, z = 0 } }; d.size = 100
  d:tick()
  T.near(d.faders[1].zoom, 13.6, 0.05, "zoom for 2 m")
end)

T.test("Arm persists after one second", function()
  local d, a = setup()
  a:Install(); a:Start()
  a:Arm("102,999")
  d:tick(); T.eq(d.saved["AutoZoom.config"], nil, "not saved yet")
  d.t = 1.5; d:tick()
  T.eq(az().config.parseConfig(d.saved["AutoZoom.config"]).config.disarmed, { 101 }, "saved disarmed, unknown 999 dropped")
end)

T.test("Arm('') disarms all", function()
  local d, a = setup()
  a:Install(); a:ArmAll(); a:Arm("")
  a:Start(); d:tick()
  T.eq(d.views["arm 101"].border, az().view.COLORS.idle, "101 disarmed")
end)

T.test("disarmed fixture removed from the patch is kept; unpatched sizes are dropped", function()
  local d, a = setup()
  d.saved["AutoZoom.config"] = '{"disarmed":[102,555],"size":{"101":2,"555":3}}'
  a:Install(); a:Stop()
  local c = az().config.parseConfig(d.saved["AutoZoom.config"]).config
  T.eq(c.disarmed, { 102, 555 }, "disarmed kept"); T.eq(c.size, { ["101"] = 2 }, "size pruned")
end)

T.test("a disarmed fixture missing from one rescan stays disarmed", function()
  local d, a = setup()
  a:Install(); a:ArmToggle(102)
  local both = d.scanResult
  d.scanResult = { fixtures = { F.fixture(101) }, markers = both.markers, problems = {} }
  a:Rescan()
  d.scanResult = both
  a:Rescan()
  T.eq(a.config.disarmed, { 102 }, "still disarmed")
  T.eq(d.views["arm 102"].appearance, "idle", "102 idle")
  T.eq(d.views["arm 101"].appearance, "tracking", "101 armed")
end)

T.test("Status counts armed scanned fixtures, ignoring stale disarmed numbers", function()
  local d, a = setup()
  d.saved["AutoZoom.config"] = '{"disarmed":[555]}'
  a:Install(); a:Status()
  T.eq(d.logs[#d.logs - 2], "AutoZoom stopped, 2 armed", "armed count")
end)

T.test("fixtures are armed by default", function()
  local d, a = setup()
  a:Install()
  T.eq(d.views["arm 101"].appearance, "tracking", "101 armed"); T.eq(d.views["arm 102"].appearance, "tracking", "102 armed")
end)

T.test("config from an older build arms everything", function()
  local d, a = setup()
  d.saved["AutoZoom.config"] = '{"armed":[101]}'
  a:Install()
  T.eq(d.views["arm 102"].appearance, "tracking", "102 armed")
end)

T.test("ArmToggle disarms then re-arms and saves", function()
  local d, a = setup()
  a:Install(); a:ArmToggle(101)
  T.eq(az().config.parseConfig(d.saved["AutoZoom.config"]).config.disarmed, { 101 }, "disarmed")
  T.eq(d.views["arm 101"].appearance, "idle", "idle")
  a:ArmToggle(101)
  T.eq(az().config.parseConfig(d.saved["AutoZoom.config"]).config.disarmed, {}, "re-armed")
end)

T.test("ArmAll and DisarmAll", function()
  local d, a = setup()
  a:Install(); a:DisarmAll()
  T.eq(az().config.parseConfig(d.saved["AutoZoom.config"]).config.disarmed, { 101, 102 }, "all disarmed")
  a:ArmAll()
  T.eq(az().config.parseConfig(d.saved["AutoZoom.config"]).config.disarmed, {}, "all armed")
end)

T.test("Arm lists the fixtures to arm; the rest are disarmed", function()
  local d, a = setup()
  a:Install(); a:Arm("101")
  T.eq(az().config.parseConfig(d.saved["AutoZoom.config"]).config.disarmed, { 102 }, "102 disarmed")
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

T.test("stop releases a fixture whose live read throws", function()
  local d, a = setup()
  a:Install(); a:ArmAll(); a:Start()
  d.cids[101] = 1; d.cids[102] = 1; d.markers["1"] = { pos = { x = 0, y = 0, z = 0 } }
  d:tick()
  d.offsetError = { [101] = "boom" }
  d.releases = {}
  a:Stop()
  local got = {}; for _, f in ipairs(d.releases) do got[f] = true end
  T.truthy(got[101], "101 released"); T.truthy(got[102], "102 released")
end)

T.test("config changes while stopped are saved immediately", function()
  local d, a = setup()
  a:Install(); a:Arm("101")
  T.eq(az().config.parseConfig(d.saved["AutoZoom.config"]).config.disarmed, { 102 }, "saved right away")
end)

T.test("rescan releases driven fixtures that are no longer patched", function()
  local d, a = setup()
  a:Install(); a:Start()
  d.cids[102] = 1; d.markers["1"] = { pos = { x = 0, y = 0, z = 0 } }; d.size = 0
  d:tick()
  T.eq(d.faders[#d.faders].fid, 102, "102 driven")
  d.releases = {}
  d.scanResult = { fixtures = { F.fixture(101) }, markers = { F.marker(1, "Lead") }, problems = {} }
  a:Rescan()
  local got = {}; for _, fid in ipairs(d.releases) do got[fid] = (got[fid] or 0) + 1 end
  T.eq(got[102], 1, "102 released once")
end)

T.test("an abnormal loop end releases the driven fixtures", function()
  local d, a = setup()
  a:Install(); a:Start()
  d.cids[101] = 1; d.markers["1"] = { pos = { x = 0, y = 0, z = 0 } }; d.size = 0
  d:tick()
  d.releases = {}
  d.loop.cleanup()   -- loop ended without Stop (e.g. Timer cleanup)
  T.eq(d.releases, { 101 }, "101 released, 102 already released")
  d.releases = {}
  a:Stop()
  T.eq(d.releases, {}, "not released twice")
end)

T.test("late cleanup of an old loop does not stop a newer one", function()
  local d, a = setup()
  d.stopLoop = function(self) self.oldLoop = self.loop; self.loop = nil end
  a:Install(); a:Start(); a:Stop(); a:Start()
  d.oldLoop.cleanup()
  d:tick()
  T.eq(d.views["status"].text:sub(1, 7), "Running", "still running")
end)

T.test("a replaced instance neither saves on Stop nor obeys commands", function()
  local d = F.new({ fixtures = { F.fixture(101), F.fixture(102) }, markers = { F.marker(1, "Lead") }, problems = {} })
  local a = az().runtime.createAutoZoom(d, "id-A")
  d.saved["AutoZoom.config"] = '{"disarmed":[101]}'
  a:Install(); a:Start()
  local b = az().runtime.createAutoZoom(d, "id-B")
  d.saved["AutoZoom.config"] = '{"disarmed":[102]}'
  b:Install()
  local cfg = d.saved["AutoZoom.config"]
  d.releases = {}
  a:Stop()
  T.eq(d.saved["AutoZoom.config"], cfg, "Stop of the old instance does not save")
  T.eq(#d.releases, 0, "old instance releases nothing")
  T.eq(d.loop, nil, "old loop stopped")
  d.logs = {}
  a:Arm("101,102"); a:ArmAll(); a:DisarmAll(); a:ArmToggle(101); a:Toggle(); a:Start(); a:Program(101, 1); a:Setup(); a:Size(101); a:Rescan(); a:Status()
  T.eq(d.saved["AutoZoom.config"], cfg, "commands of the old instance do not save")
  T.eq(d.logs[1], "Run the AutoZoom plugin for this show", "told to run the plugin")
  T.eq(#d.logs, 11, "every command refused")
  T.eq(d.loop, nil, "old instance did not start"); T.eq(#d.laters, 0, "no dialogs"); T.eq(#d.cmds, 0, "no programmer commands")
  b:Arm("102")
  T.eq(az().config.parseConfig(d.saved["AutoZoom.config"]).config.disarmed, { 101 }, "current instance still works")
end)

T.test("stop releases every fixture even when the refresh throws", function()
  local d, a = setup()
  a:Install(); a:ArmAll(); a:Start()
  d.cids[101] = 1; d.cids[102] = 1; d.markers["1"] = { pos = { x = 0, y = 0, z = 0 } }
  d:tick()
  d.readMarkers = function() error("psn gone") end
  d.releases = {}; d.logs = {}
  local ok, err = pcall(function() a:Stop() end)
  T.truthy(ok, "Stop does not raise: " .. tostring(err))
  local got = {}; for _, f in ipairs(d.releases) do got[f] = true end
  T.truthy(got[101], "101 released"); T.truthy(got[102], "102 released")
  local n = 0; for _, l in ipairs(d.logs) do if l:find("psn gone") then n = n + 1 end end
  T.eq(n, 1, "refresh error logged once")
end)

T.test("Rescan from the layout while running rebuilds the layout and keeps the loop", function()
  local d, a = setup()
  a:Install(); a:Start()
  local before = d.cells
  local loop = d.loop
  a:Rescan()
  T.truthy(d.cells ~= before, "layout rebuilt"); T.eq(#d.cells, #before, "no duplicate cells")
  T.truthy(d.loop ~= nil, "loop still running"); T.truthy(d.loop == loop, "same loop")
  d:tick()
  T.eq(d.views["status"].text:sub(1, 7), "Running", "still running")
end)

T.test("RescanLater queues the rescan and runLaters performs it", function()
  local d, a = setup()
  a:Install()
  local before = d.cells
  a:RescanLater()
  T.eq(d.cells, before, "nothing rebuilt yet"); T.eq(#d.laters, 1, "queued")
  d:runLaters()
  T.truthy(d.cells ~= before, "layout rebuilt later")
end)

T.test("Capture logs that it was removed", function()
  local d, a = setup()
  a:Install(); a:Capture()
  T.eq(d.logs[#d.logs], "Capture was removed in 2.0.0.2", "logged")
end)
