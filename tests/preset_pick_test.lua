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
