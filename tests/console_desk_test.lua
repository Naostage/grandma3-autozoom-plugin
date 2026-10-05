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
  T.truthy(joined:find([[Set DataPool 'AutoZoom' Macro 'AZ Start'.1 Property 'Command' 'Call Plugin "GMA3 Autozoom"']], 1, true), "AZ Start macro")
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
  T.truthy(table.concat(M.cmds, "\n"):find([[Property 'Command' 'Lua "if AZ then AZ:Toggle() end"']], 1, true), "macro command")
  desk:refreshLayout({ toggle = { text = "Stop", border = "3ECF6EFF", textColor = "E6E8EBFF", appearance = "button" } })
  T.eq(layout._kids[1].CustomTextText, "Stop", "text"); T.eq(layout._kids[1].BorderColor, "3ECF6EFF", "border")
  layout._kids[1].CustomTextText = "tampered"
  desk:refreshLayout({ toggle = { text = "Stop", border = "3ECF6EFF", textColor = "E6E8EBFF", appearance = "button" } })
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

local function builtLayout()
  M.reset()
  local desk = az().madesk.createMaDesk()
  desk:install({ fixtures = {}, markers = {}, problems = {} })
  desk:buildLayout({ { key = "a", x = 0, y = 0, w = 1, h = 1, command = "" }, { key = "b", x = 1, y = 0, w = 1, h = 1, command = "" } })
  return desk
end
local VIEWS = { a = { text = "A", border = "1", textColor = "2", appearance = "button" }, b = { text = "B", border = "1", textColor = "2", appearance = "button" } }

T.test("refresh with the layout deleted creates nothing", function()
  local desk = builtLayout()
  M.cmds = {}
  for _, e in ipairs(M.dataPools._kids[1].Layouts._kids[1]._kids) do e._deleted = true end
  M.onCmd("Delete DataPool 'AutoZoom' Layout 'AutoZoom' /nc")
  desk:refreshLayout(VIEWS); desk:refreshLayout(VIEWS)
  T.eq(#M.cmds, 0, "no commands")
end)

T.test("refresh with the data pool deleted issues no command", function()
  local desk = builtLayout()
  M.cmds = {}
  local pool = M.dataPools._kids[1]
  for _, e in ipairs(pool.Layouts._kids[1]._kids) do e._deleted = true end
  pool._deleted = true; table.remove(M.dataPools._kids, 1)
  desk:refreshLayout(VIEWS); desk:refreshLayout(VIEWS)
  T.eq(#M.cmds, 0, "no commands")
end)

T.test("a reloaded layout gets its texts rewritten although the views did not change", function()
  local desk = builtLayout()
  desk:refreshLayout(VIEWS)
  local layout = M.dataPools._kids[1].Layouts._kids[1]
  local fresh = {}
  for i, e in ipairs(layout._kids) do e._deleted = true; fresh[i] = M.handle({ Note = e.Note }, {}) end
  layout._kids = fresh
  desk:refreshLayout(VIEWS)
  T.eq(fresh[1].CustomTextText, "A", "a rewritten"); T.eq(fresh[2].CustomTextText, "B", "b rewritten")
  T.eq(fresh[2].BorderColor, "1", "border rewritten")
  fresh[1].CustomTextText = "tampered"
  desk:refreshLayout(VIEWS)
  T.eq(fresh[1].CustomTextText, "tampered", "then unchanged views are skipped again")
end)

T.test("install creates the AutoZoom appearances once with their colours", function()
  M.reset()
  local desk = az().madesk.createMaDesk()
  desk:install({ fixtures = {}, markers = {}, problems = {} })
  local byName = {}
  for _, a in ipairs(M.appearances._kids) do byName[a.name] = a end
  T.eq(byName["AZ Tracking"].IMAGERGBA, "137A38E0", "tracking colour")
  T.eq(byName["AZ Idle"].IMAGERGBA, "10121CD9", "idle colour")
  local n = #M.appearances._kids
  T.eq(n, 9, "nine appearances")
  byName["AZ Tracking"].IMAGERGBA = "FFFFFFFF"
  desk:install({ fixtures = {}, markers = {}, problems = {} })
  T.eq(#M.appearances._kids, n, "no duplicates"); T.eq(byName["AZ Tracking"].IMAGERGBA, "137A38E0", "colour reapplied")
end)

T.test("layout elements hide object details and get the cell appearance", function()
  M.reset()
  local desk = az().madesk.createMaDesk()
  desk:install({ fixtures = {}, markers = {}, problems = {} })
  desk:buildLayout({ { key = "toggle", x = 0, y = 0, w = 100, h = 60, command = "Toggle()" } })
  local el = M.dataPools._kids[1].Layouts._kids[1]._kids[1]
  T.eq(el.VisibilityIcon, false, "icon hidden"); T.eq(el.VisibilityObjectName, false, "name hidden")
  T.eq(el.VisibilityBorder, false, "no border"); T.eq(el.VisibilityValue, false, "no value")
  desk:refreshLayout({ toggle = { text = "Stop", border = "3ECF6EFF", textColor = "E6E8EBFF", appearance = "button" } })
  T.eq(el.Appearance.name, "AZ Button", "button appearance")
  el.Appearance = "tampered"
  desk:refreshLayout({ toggle = { text = "Stop", border = "3ECF6EFF", textColor = "E6E8EBFF", appearance = "button" } })
  T.eq(el.Appearance, "tampered", "unchanged view not rewritten")
  desk:refreshLayout({ toggle = { text = "Stop", border = "3ECF6EFF", textColor = "E6E8EBFF", appearance = "error" } })
  T.eq(el.Appearance.name, "AZ Error", "appearance switched")
end)

T.test("deleted appearance is skipped and recreated on install", function()
  M.reset()
  local desk = az().madesk.createMaDesk()
  desk:install({ fixtures = {}, markers = {}, problems = {} })
  desk:buildLayout({ { key = "toggle", x = 0, y = 0, w = 100, h = 60, command = "Toggle()" } })
  for i, a in ipairs(M.appearances._kids) do if a.name == "AZ Button" then a._deleted = true; table.remove(M.appearances._kids, i) break end end
  desk:refreshLayout({ toggle = { text = "Stop", border = "3ECF6EFF", textColor = "E6E8EBFF", appearance = "button" } })
  desk:install({ fixtures = {}, markers = {}, problems = {} })
  local found = false
  for _, a in ipairs(M.appearances._kids) do if a.name == "AZ Button" then found = true end end
  T.truthy(found, "recreated")
end)

T.test("desk reads last command and undo name, oops restores OopsProgrammer", function()
  M.reset()
  M.cmdObj = { LastCommand = "OK: Preset 2.30", Undos = { UndoIndex = 0, [1] = { Name = "Preset 2.30" } } }
  M.profile = { OopsProgrammer = false }
  local desk = az().madesk.createMaDesk()
  T.eq(desk:lastCommand(), "OK: Preset 2.30", "last command"); T.eq(desk:topUndoName(), "Preset 2.30", "undo name")
  desk:undoProgrammer()
  T.eq(M.cmds[#M.cmds], "Oops /nc", "oops"); T.eq(M.profile.OopsProgrammer, false, "restored")
  T.eq(M.oopsProgrammerDuringOops, true, "was true during Oops")
end)

T.test("a failing Oops is logged and OopsProgrammer is still restored", function()
  M.reset()
  M.profile = { OopsProgrammer = false }
  local orig = M.onCmd
  M.onCmd = function(s) if s == "Oops /nc" then error("denied") end end
  local desk = az().madesk.createMaDesk()
  desk:undoProgrammer()
  M.onCmd = orig
  T.eq(M.profile.OopsProgrammer, false, "restored")
  local found = false; for _, p in ipairs(M.printed) do if p:find("[AZ] Oops failed", 1, true) then found = true end end
  T.truthy(found, "failure printed")
end)

T.test("undo mark combines index, count and top entry name", function()
  M.reset()
  M.cmdObj = { LastCommand = "x", Undos = M.handle({ UndoIndex = 2 }, { {}, {}, {} }) }
  M.cmdObj.Undos[3] = { Name = "\27[32mPreset 2.30\27[0m" }
  local desk = az().madesk.createMaDesk()
  T.eq(desk:undoMark(), "2|3|Preset 2.30", "with count")
  M.cmdObj = { LastCommand = "x", Undos = { UndoIndex = 0 } }
  T.eq(desk:undoMark(), "0||", "no Count(), no entry")
  M.cmdObj = { LastCommand = "x" }
  T.eq(desk:undoMark(), "||", "no undo list")
end)
