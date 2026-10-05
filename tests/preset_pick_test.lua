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
  T.eq(p.parsePresetCommand("Go+ Preset 2.30"), "2.30", "go+ without OK:")
  T.eq(p.parsePresetCommand("at preset 2.30"), "2.30", "at")
  T.eq(p.parsePresetCommand("OK: Call Preset 2.30"), "2.30", "call")
  T.eq(p.parsePresetCommand("At DataPool 4 Preset 2.30"), "DataPool 4 Preset 2.30", "at data pool")
  T.eq(p.parsePresetCommand("OK: Store Preset 2.30"), nil, "store")
  T.eq(p.parsePresetCommand("Delete Preset 2.30"), nil, "delete")
  T.eq(p.parsePresetCommand('Label Preset 2.30 "x"'), nil, "label")
  T.eq(p.parsePresetCommand('Attribute "XYZ_X" Thru "XYZ_Z" At Preset 2.30'), nil, "plugin's own attribute command")
  T.eq(p.parsePresetCommand("Fixture 1 At Preset 2.30"), nil, "selection before")
end)

T.test("undo match is strict plain text", function()
  local p = az().preset
  T.eq(p.undoMatches("\27[32mPreset 2.30\27[0m", "OK: Preset 2.30"), true, "ansi stripped, OK: removed")
  T.eq(p.undoMatches("preset  2.30 ", "ok: PRESET 2.30"), true, "case and whitespace")
  T.eq(p.undoMatches("Preset 2.30", "Preset 2.30"), true, "equal")
  T.eq(p.undoMatches("Store Preset 2.30", "Preset 2.30"), false, "store is not the tap")
  T.eq(p.undoMatches("Delete Preset 2.30", "OK: Preset 2.30"), false, "delete is not the tap")
  T.eq(p.undoMatches("Preset 2.30 Thru 2.31", "Preset 2.30"), false, "containment is not enough")
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
  T.eq(d.views["message"].text, "Tap a preset…  10 s", "waiting")
  T.eq(d.views["message"].appearance, "capture", "capture look")
  d.lastCmd = "OK: Preset 2.30"; d.undoName = "Preset 2.30"; d.undoCount = 1
  d:tick()
  T.eq(d.undos, 1, "oops once")
  T.eq(az().config.parseConfig(d.saved["AutoZoom.config"] or "").config.offset.preset, "", "debounced: not yet saved")
  d.t = 2; d:tick()
  local cfg = az().config.parseConfig(d.saved["AutoZoom.config"]).config
  T.eq(cfg.offset.source, "preset", "source"); T.eq(cfg.offset.preset, "2.30", "preset")
  T.eq(d.views["setup"].text, "Setup\nXYZ Preset 2.30", "setup cell shows preset")
  T.eq(d.views["message"].text, "Offset preset 2.30", "result in message"); T.eq(d.views["message"].appearance, "header", "message look")
end)

T.test("unrelated command keeps the pick waiting", function()
  local d, a = setup()
  a:PickOffset(); d:tick()
  d.lastCmd = "OK: Go+ Sequence 3"; d:tick()
  T.eq(d.undos, 0, "nothing undone"); T.truthy(d.views["message"].text:find("Tap a preset"), "still waiting")
end)

T.test("no Oops when the undo entry is something else", function()
  local d, a = setup()
  a:PickOffset(); d:tick()
  d.lastCmd = "OK: Preset 2.30"; d.undoName = "Store Sequence 3"; d.undoCount = 1
  d:tick()
  T.eq(d.undos, 0, "nothing undone"); T.eq(d.views["message"].text, "Offset preset 2.30", "picked anyway")
end)

T.test("a stale undo entry from before the pick is never undone", function()
  for _, stale in ipairs({ "Store Preset 2.30", "Preset 2.30" }) do
    local d, a = setup()
    d.undoName = stale; d.undoCount = 5; d.undoIndex = 0
    a:PickOffset(); d:tick()
    d.lastCmd = "OK: Preset 2.30"; d:tick()
    T.eq(d.undos, 0, "nothing undone (" .. stale .. ")")
    T.eq(d.views["message"].text, "Offset preset 2.30", "picked anyway (" .. stale .. ")")
  end
end)

T.test("a new undo entry equal to the tap is undone exactly once", function()
  local d, a = setup()
  d.undoName = "Store Preset 2.30"; d.undoCount = 5
  a:PickOffset(); d:tick()
  d.lastCmd = "OK: Preset 2.30"; d.undoName = "Preset 2.30"; d.undoCount = 6
  d:tick(); d:tick()
  T.eq(d.undos, 1, "one oops")
end)

T.test("a new Store undo entry is not undone", function()
  local d, a = setup()
  a:PickOffset(); d:tick()
  d.lastCmd = "OK: Preset 2.30"; d.undoName = "Store Preset 2.30"; d.undoCount = 1
  d:tick()
  T.eq(d.undos, 0, "nothing undone")
end)

T.test("storing a preset during a pick is ignored, logged once and never undone", function()
  local d, a = setup()
  a:PickOffset(); d:tick()
  d.lastCmd = "OK: Store Preset 2.30"; d.undoName = "Store Preset 2.30"; d.undoCount = 1
  d:tick(); d:tick()
  T.eq(d.undos, 0, "nothing undone")
  T.truthy(d.views["message"].text:find("Tap a preset"), "still waiting")
  local n = 0; for _, l in ipairs(d.logs) do if l == 'Preset pick ignored "OK: Store Preset 2.30"' then n = n + 1 end end
  T.eq(n, 1, "ignored logged once")
end)

T.test("Program during a pick re-takes the baseline so the plugin's own commands are never picked", function()
  local d, a = setup()
  local cfg = az().config.defaultConfig(); cfg.offset.source = "preset"; cfg.offset.preset = "2.30"
  a:PickOffset(); d:tick()
  function d:runCommands(c) for _, x in ipairs(c) do self.cmds[#self.cmds + 1] = x; self.lastCmd = "OK: " .. x end; self.undoCount = (self.undoCount or 0) + 1 end
  a.config.offset = cfg.offset
  a:Program(101, 1)
  T.eq(a.pickBaseline, d.lastCmd, "baseline re-taken"); T.eq(a.pickUndoMark, d:undoMark(), "undo mark re-taken")
  d:tick()
  for _, l in ipairs(d.logs) do T.truthy(not l:find("Preset pick ignored", 1, true), "own command not considered: " .. l) end
  T.truthy(d.views["message"].text:find("Tap a preset"), "still waiting")
end)

T.test("a failing Oops does not lose the picked preset", function()
  local d, a = setup()
  a:PickOffset(); d:tick()
  function d:undoProgrammer() error("oops denied") end
  d.lastCmd = "OK: Preset 2.30"; d.undoName = "Preset 2.30"; d.undoCount = 1
  d:tick()
  d.t = 2; d:tick()
  local cfg = az().config.parseConfig(d.saved["AutoZoom.config"]).config
  T.eq(cfg.offset.source, "preset", "source saved"); T.eq(cfg.offset.preset, "2.30", "preset saved")
end)

T.test("pick times out, cancels and is refused when stopped or not current", function()
  local d, a = setup()
  a:PickOffset(); d.t = 11; d:tick()
  T.eq(d.logs[#d.logs], "Preset pick timed out", "timeout")
  a:PickOffset(); a:PickOffset()
  T.eq(d.logs[#d.logs], "Preset pick cancelled", "cancel")
  d.logs = {}
  a:PickOffset(); a:Stop()
  local cancelled = false; for _, l in ipairs(d.logs) do if l == "Preset pick cancelled" then cancelled = true end end
  T.truthy(cancelled, "stop cancels")
  T.eq(d.views["message"].appearance, "header", "message cell idle after stop")
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

T.test("a failing pick poll ends the pick and does not stop the fixtures being driven", function()
  local d = F.new({ fixtures = { F.fixture(101) }, markers = { F.marker(1) }, problems = {} })
  local a = az().runtime.createAutoZoom(d, "id")
  a:Install(); a:Arm("101"); a:Start()
  d.cids[101] = 1; d.markers["1"] = { pos = { x = 0, y = 0, z = 0 } }; d.size = 0
  a:PickOffset()
  d.lastCommand = function() error("boom") end
  d:tick()
  local failed = false; for _, l in ipairs(d.logs) do if l:find("Preset pick failed", 1, true) then failed = true end end
  T.truthy(failed, "failure logged")
  T.truthy(#d.faders >= 1, "fixture still driven")
  T.eq(d.views["message"].appearance, "header", "pick ended")
end)

T.test("Setup with Pick preset starts the pick and ignores the other answers", function()
  local d, a = setup()
  local before = az().config.serializeConfig(a.config)
  d.setupAnswer = { pick = true, source = "values", preset = "", x = "9", y = "9", z = "9", min = "2", max = "3", rate = "60" }
  a:Setup(); d:runLaters()
  T.eq(az().config.serializeConfig(a.config), before, "answers not applied")
  T.truthy(a.pickUntil ~= nil, "pick active")
  T.eq(a.message, "Tap the preset that holds the XYZ offset", "pick message")
  T.eq(d.views["message"].text, "Tap a preset…  10 s", "countdown in message cell")
  for _, l in ipairs(d.logs) do T.truthy(l ~= "Setup saved", "not saved") end
end)

T.test("Setup with Pick preset during an active pick restarts it", function()
  local d, a = setup()
  a:PickOffset(); d:tick()
  d.t = 6; d.lastCmd = "OK: Go+ Sequence 3"
  d.setupAnswer = { pick = true, source = "values", preset = "", x = "9", y = "9", z = "9", min = "2", max = "3", rate = "60" }
  a:Setup(); d:runLaters()
  T.truthy(a.pickUntil ~= nil, "pick still active")
  T.eq(a.pickUntil, 16, "fresh 10 s countdown")
  T.eq(a.pickBaseline, "OK: Go+ Sequence 3", "fresh baseline")
  T.eq(a.message, "Tap the preset that holds the XYZ offset", "pick message")
end)

T.test("PickOffset still toggles an active pick off", function()
  local d, a = setup()
  a:PickOffset(); a:PickOffset()
  T.eq(a.pickUntil, nil, "cancelled")
end)

T.test("Setup with Pick preset while stopped is refused", function()
  local d, a = setup()
  a:Stop()
  d.setupAnswer = { pick = true, source = "values", preset = "", x = "9", y = "9", z = "9", min = "2", max = "3", rate = "60" }
  a:Setup(); d:runLaters()
  T.eq(d.logs[#d.logs], "Start AutoZoom to pick a preset", "refused")
  T.eq(a.pickUntil, nil, "no pick"); T.eq(a.config.rate, 30, "answers not applied")
end)

T.test("Setup with Save applies the answers", function()
  local d, a = setup()
  d.setupAnswer = { pick = false, source = "values", preset = "", x = "1", y = "2", z = "3", min = "1", max = "4", rate = "30" }
  a:Setup(); d:runLaters()
  T.eq(a.config.offset.values, { 1, 2, 3 }, "applied"); T.eq(a.pickUntil, nil, "no pick")
  T.eq(a.message, "Setup saved", "saved")
end)
