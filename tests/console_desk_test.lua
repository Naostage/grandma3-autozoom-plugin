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

T.test("selected sequence, running cue and cue command (cues stored x1000)", function()
  M.reset()
  local pool = M.pool("Default")
  local s = M.sequence(pool, "Main", { { no = 1 }, { no = 2, cmd = "Go+ Sequence 3" }, { no = 2.5, cmd = "Go- Sequence 4" } })
  local function cue(no) for _, c in ipairs(s._kids) do if c.no == no then return c end end end
  s.current = cue(2000); M.selected = s
  local desk = az().madesk.createMaDesk()
  local ref = desk:selectedSequence()
  T.eq(ref.name, "Main", "name"); T.eq(desk:runningCue(ref), 2, "running cue")
  T.eq(desk:readCueCommand(ref, 2), "Go+ Sequence 3", "read"); T.eq(desk:readCueCommand(ref, 9), nil, "missing cue")
  T.eq(desk:readCueCommand(ref, 2.5), "Go- Sequence 4", "fractional cue")
  T.eq(desk:readCueCommand(ref, 0), nil, "cue zero is not addressable")
  T.eq(desk:writeCueCommand(ref, 2, "X"), true, "write ok"); T.eq(cue(2000)._kids[1].Command, "X", "written")
  T.eq(desk:writeCueCommand(ref, 9, "X"), false, "write missing")
  s.current = cue(0); T.eq(desk:runningCue(ref), nil, "CueZero is not a running cue")
  s.current = s._kids[1]; T.eq(desk:runningCue(ref), nil, "OffCue is not a running cue")
  s.current = nil; T.eq(desk:runningCue(ref), nil, "nothing running")
  T.eq(desk:selectedCue(ref), nil, "no selected-cue accessor")
end)

T.test("readOffset uses the followed marker's target space from the last scan", function()
  M.reset()
  M.fixtureType("Robin Esprite", { M.mode("Mode 2", true, { M.channel("Zoom", 49, 5.5) }) })
  local ts = M.space("MArker 1 Target", { -100, -100, 0 }, { 100, 100, 100 })
  M.stage({ M.fixture(101, "Robin Esprite", "Mode 2", { 0, 0, 8 }), M.marker(1, "Lead", ts) },
    { M.space("Stage", { -35, -35, 0 }, { 35, 35, 35 }), ts })
  local desk = az().madesk.createMaDesk()
  local scan = desk:scan()
  local f = scan.fixtures[1]
  M.setRt(101, "XYZ_MArker", 1); M.setRt(101, "XYZ_X", 8472495)
  T.near(desk:readOffset(f).x, 1, 1e-3, "x in marker space")
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
