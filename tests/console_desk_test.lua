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
  T.eq(layout._kids[1].Action, "Go+", "clickable cell"); T.eq(layout._kids[2].Action, "Pause", "display-only cell")
  desk:refreshLayout({ toggle = { text = "Stop", border = "3ECF6EFF", textColor = "E6E8EBFF", appearance = "button" } })
  T.eq(layout._kids[1].CustomTextText, "Stop", "text"); T.eq(layout._kids[1].BorderColor, "3ECF6EFF", "border")
  layout._kids[1].CustomTextText = "tampered"
  desk:refreshLayout({ toggle = { text = "Stop", border = "3ECF6EFF", textColor = "E6E8EBFF", appearance = "button" } })
  T.eq(layout._kids[1].CustomTextText, "tampered", "unchanged view not rewritten")
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
  T.eq(a.source, "preset", "source"); T.eq(a.preset, "2.12", "preset"); T.eq(a.y, "-1", "y"); T.eq(a.pick, false, "save")
  T.eq(M.lastBox.commands, { { value = 1, name = "Save" }, { value = 2, name = "Pick preset…" }, { value = 0, name = "Cancel" } }, "three commands")
  M.boxAnswer.result = 2
  local p = desk:setupDialog(az().config.defaultConfig())
  T.eq(p.pick, true, "pick"); T.eq(p.preset, "2.12", "inputs still read")
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

local function cellA(x) return { key = "a", x = x, y = 0, w = 1, h = 1, command = "" } end
local function cellB() return { key = "b", x = 1, y = 0, w = 1, h = 1, command = "" } end

T.test("rebuilding keeps the layout object and never deletes it", function()
  M.reset()
  local desk = az().madesk.createMaDesk()
  desk:install({ fixtures = {}, markers = {}, problems = {} })
  desk:buildLayout({ cellA(0), cellB() })
  local layout = M.dataPools._kids[1].Layouts._kids[1]
  M.cmds = {}
  desk:buildLayout({ cellA(0), cellB() })
  T.eq(#M.dataPools._kids[1].Layouts._kids, 1, "one layout"); T.truthy(M.dataPools._kids[1].Layouts._kids[1] == layout, "same handle")
  T.truthy(not (layout._deleted), "not deleted")
  for _, c in ipairs(M.cmds) do T.truthy(not (c:find("Delete DataPool 'AutoZoom' Layout", 1, true)), "no layout delete: " .. c) end
end)

T.test("rebuilding reuses a tagged element and updates it", function()
  M.reset()
  local desk = az().madesk.createMaDesk()
  desk:install({ fixtures = {}, markers = {}, problems = {} })
  desk:buildLayout({ cellA(0), cellB() })
  local layout = M.dataPools._kids[1].Layouts._kids[1]
  local el = layout._kids[1]
  desk:buildLayout({ cellA(50), cellB() })
  T.eq(#layout._kids, 2, "no duplicates"); T.truthy(layout._kids[1] == el, "same element"); T.eq(el.PosX, 50, "PosX updated")
  T.eq(el.Note, "AZ:a", "tag kept")
end)

T.test("rebuilding deletes stale tagged elements and keeps operator elements", function()
  M.reset()
  local desk = az().madesk.createMaDesk()
  desk:install({ fixtures = {}, markers = {}, problems = {} })
  desk:buildLayout({ cellA(0), cellB() })
  local layout = M.dataPools._kids[1].Layouts._kids[1]
  local mine = layout:Append(); mine.Note = "my button"
  local plain = layout:Append()
  local b = layout._kids[2]
  desk:buildLayout({ cellA(0) })
  T.truthy(b._deleted, "stale AZ element deleted")
  T.truthy(not (mine._deleted), "operator element kept"); T.truthy(not (plain._deleted), "unnoted element kept")
  T.eq(#layout._kids, 3, "a + two operator elements")
end)

T.test("texts are rewritten after a rebuild", function()
  local desk = builtLayout()
  desk:refreshLayout(VIEWS)
  local layout = M.dataPools._kids[1].Layouts._kids[1]
  desk:buildLayout({ cellA(0), cellB() })
  layout._kids[1].CustomTextText = "tampered"
  desk:refreshLayout(VIEWS)
  T.eq(layout._kids[1].CustomTextText, "A", "rewritten after rebuild")
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

T.test("layout elements hide object details and the sequence gets the cell appearance", function()
  M.reset()
  local desk = az().madesk.createMaDesk()
  desk:install({ fixtures = {}, markers = {}, problems = {} })
  desk:buildLayout({ { key = "toggle", x = 0, y = 0, w = 100, h = 60, command = "Toggle()" } })
  local el = M.dataPools._kids[1].Layouts._kids[1]._kids[1]
  T.eq(el.VisibilityIcon, false, "icon hidden"); T.eq(el.VisibilityObjectName, false, "name hidden")
  T.eq(el.VisibilityBorder, false, "no border"); T.eq(el.VisibilityValue, false, "no value")
  local seq = el.Object
  desk:refreshLayout({ toggle = { text = "Stop", border = "3ECF6EFF", textColor = "E6E8EBFF", appearance = "button" } })
  T.eq(seq.Appearance.name, "AZ Button", "button appearance")
  seq.Appearance = "tampered"
  desk:refreshLayout({ toggle = { text = "Stop", border = "3ECF6EFF", textColor = "E6E8EBFF", appearance = "button" } })
  T.eq(seq.Appearance, "tampered", "unchanged view not rewritten")
  desk:refreshLayout({ toggle = { text = "Stop", border = "3ECF6EFF", textColor = "E6E8EBFF", appearance = "error" } })
  T.eq(seq.Appearance.name, "AZ Error", "appearance switched")
  T.eq(el.Appearance, nil, "element appearance never written")
end)

T.test("rebuilding the layout reuses the cell sequences and repairs their command", function()
  M.reset()
  local desk = az().madesk.createMaDesk()
  desk:install({ fixtures = {}, markers = {}, problems = {} })
  desk:buildLayout({ { key = "toggle", x = 0, y = 0, w = 100, h = 60, command = "Toggle()" } })
  local pool = M.dataPools._kids[1]
  local n = #pool.Sequences._kids
  local seq = pool.Layouts._kids[1]._kids[1].Object
  local part = seq._kids[#seq._kids]._kids[1]
  part.Command = "tampered"
  desk:buildLayout({ { key = "toggle", x = 0, y = 0, w = 100, h = 60, command = "Toggle()" } })
  T.eq(#pool.Sequences._kids, n, "no new sequence")
  T.eq(pool.Layouts._kids[1]._kids[1].Object, seq, "same sequence bound")
  T.eq(part.Command, [[Lua "if AZ then AZ:Toggle() end"]], "command repaired")
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

T.test("install survives an Appearances pool that cannot create", function()
  M.reset()
  function M.appearances:Acquire() error("no appearances here") end
  function M.appearances:Create() error("no appearances here") end
  local desk = az().madesk.createMaDesk()
  desk:install({ fixtures = { fixture101() }, markers = {}, problems = {} })
  local joined = table.concat(M.cmds, "\n")
  T.truthy(joined:find("Store DataPool 'AutoZoom' Sequence 'AZ_ZOOM_101' /o /nc", 1, true), "zoom seq still created")
  T.truthy(joined:find("Store DataPool 'AutoZoom' Sequence 'AZ_SIZE' /o /nc", 1, true), "size seq still created")
  local warned = false
  for _, p in ipairs(M.printed) do if p:find("Could not create the AutoZoom appearances", 1, true) then warned = true end end
  T.truthy(warned, "warning printed")
end)

T.test("layout is built although an element rejects a visibility property", function()
  M.reset()
  local desk = az().madesk.createMaDesk()
  desk:install({ fixtures = {}, markers = {}, problems = {} })
  local orig = M.onCmd
  M.onCmd = function(s)
    orig(s)
    local l = M.dataPools._kids[1].Layouts._kids[1]
    if l and not l._patched then
      l._patched = true
      function l:Append()
        local e = M.handle({}, {})
        setmetatable(e, { __newindex = function(t, k, v) if k == "VisibilityCID" then error("unknown property") end rawset(t, k, v) end })
        self._kids[#self._kids + 1] = e
        return e
      end
    end
  end
  local ok, err = pcall(desk.buildLayout, desk, { { key = "a", x = 0, y = 0, w = 1, h = 1, command = "" }, { key = "b", x = 1, y = 0, w = 1, h = 1, command = "" } })
  M.onCmd = orig
  T.truthy(ok, "build did not throw: " .. tostring(err))
  local layout = M.dataPools._kids[1].Layouts._kids[1]
  T.eq(#layout._kids, 2, "both elements"); T.eq(layout._kids[2].Note, "AZ:b", "second element tagged")
  T.eq(layout._kids[1].BorderSize, 0, "other properties still written")
  desk:refreshLayout(VIEWS)
  T.eq(layout._kids[2].CustomTextText, "B", "refresh works")
  local warned = false
  for _, p in ipairs(M.printed) do if p:find("[AZ warning]", 1, true) and p:find("unknown property", 1, true) then warned = true end end
  T.truthy(warned, "warning printed")
end)

T.test("a missing appearance is looked up once until the next install", function()
  M.reset()
  local desk = az().madesk.createMaDesk()
  desk:install({ fixtures = {}, markers = {}, problems = {} })
  desk:buildLayout({ { key = "toggle", x = 0, y = 0, w = 100, h = 60, command = "Toggle()" } })
  for i, a in ipairs(M.appearances._kids) do if a.name == "AZ Button" then a._deleted = true; table.remove(M.appearances._kids, i) break end end
  local scans, orig = 0, M.appearances.Children
  M.appearances.Children = function(self) scans = scans + 1; return orig(self) end
  for i = 1, 5 do
    desk:refreshLayout({ toggle = { text = "Stop " .. i, border = "3ECF6EFF", textColor = "E6E8EBFF", appearance = "button" } })
  end
  T.eq(scans, 1, "one pool scan for five changed refreshes")
  desk:install({ fixtures = {}, markers = {}, problems = {} })
  desk:refreshLayout({ toggle = { text = "Stop again", border = "3ECF6EFF", textColor = "E6E8EBFF", appearance = "button" } })
  T.eq(M.dataPools._kids[1].Layouts._kids[1]._kids[1].Object.Appearance.name, "AZ Button", "recreated appearance used after install")
end)

T.test("far block holds the nine AZ appearances", function()
  M.reset()
  local desk = az().madesk.createMaDesk()
  desk:install({ fixtures = {}, markers = {}, problems = {} })
  local nos = {}
  for _, a in ipairs(M.appearances._kids) do if a.name:sub(1, 3) == "AZ " then nos[#nos + 1] = a.No end end
  table.sort(nos)
  T.eq(#nos, 9, "nine"); T.eq(nos[1], 9001, "first"); T.eq(nos[9], 9009, "contiguous")
  T.eq(M.appearances.createdClass, "Appearance", "created with the pool's child class")
  T.truthy(M.appearances.size >= 9009, "pool resized up to the block")
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
  local issued = false
  for _, c in ipairs(M.cmds) do if c == "Delete Appearance 7 /nc" then issued = true end end
  T.truthy(issued, "deleted by number through the command line")
end)

T.test("a low AZ appearance that survives the delete is kept, not duplicated", function()
  M.reset()
  M.appearances._kids[#M.appearances._kids + 1] = M.handle({ name = "AZ Tracking", No = 7 }, {})
  local orig = M.onCmd
  M.onCmd = function(s) if not s:match("^Delete Appearance") then orig(s) end end
  local desk = az().madesk.createMaDesk()
  desk:install({ fixtures = {}, markers = {}, problems = {} })
  M.onCmd = orig
  local count, no = 0, nil
  for _, a in ipairs(M.appearances._kids) do if a.name == "AZ Tracking" then count = count + 1; no = a.No end end
  T.eq(count, 1, "one"); T.eq(no, 7, "kept where it is")
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
  T.eq(pool.Layouts._kids[1]._kids[1].CustomTextText, "Stop", "text still written")
end)

T.test("install removes the 2.0.0.1 cell macros and keeps AZ Start", function()
  M.reset()
  local pool = M.pool("AutoZoom")
  for _, n in ipairs({ "AZ toggle", "AZ arm 101", "AZ Start" }) do pool.Macros._kids[#pool.Macros._kids + 1] = M.handle({ name = n }, {}) end
  local desk = az().madesk.createMaDesk()
  desk:install({ fixtures = {}, markers = {}, problems = {} })
  T.eq(#pool.Macros._kids, 1, "one macro left"); T.eq(pool.Macros._kids[1].name, "AZ Start", "AZ Start kept")
end)

T.test("a cell sequence whose cue 1 was deleted gets a new cue 1 with the command", function()
  M.reset()
  local desk = az().madesk.createMaDesk()
  desk:install({ fixtures = {}, markers = {}, problems = {} })
  local cells = { { key = "toggle", x = 0, y = 0, w = 100, h = 60, command = "Toggle()" } }
  desk:buildLayout(cells)
  local seq = M.dataPools._kids[1].Layouts._kids[1]._kids[1].Object
  T.eq(seq._kids[3].no, 1000, "cue 1 reads back x1000")
  table.remove(seq._kids, 3)
  desk:buildLayout(cells)
  T.eq(#seq._kids, 3, "one new cue"); T.eq(seq._kids[3].no, 1000, "numbered 1")
  T.eq(seq._kids[3]._kids[1].Command, [[Lua "if AZ then AZ:Toggle() end"]], "command written")
  T.eq(seq._kids[1]._kids[1].Command, "", "OffCue untouched"); T.eq(seq._kids[2]._kids[1].Command, "", "CueZero untouched")
end)

T.test("layout build deletes stale cell sequences and keeps fader sequences", function()
  M.reset()
  local desk = az().madesk.createMaDesk()
  desk:install({ fixtures = { fixture101() }, markers = {}, problems = {} })
  local pool = M.dataPools._kids[1]
  M.sequence(pool, "AZ arm 999")
  desk:buildLayout({ { key = "toggle", x = 0, y = 0, w = 100, h = 60, command = "Toggle()" } })
  local names = {}
  for _, sq in ipairs(pool.Sequences._kids) do names[sq.name] = true end
  T.eq(names["AZ arm 999"], nil, "stale deleted"); T.truthy(names["AZ_ZOOM_101"], "fader kept")
  T.truthy(names["AZ_SIZE"], "size kept"); T.truthy(names["AZ toggle"], "current cell kept")
end)

T.test("an element that rejects Pause falls back to Go+", function()
  M.reset()
  local desk = az().madesk.createMaDesk()
  desk:install({ fixtures = {}, markers = {}, problems = {} })
  local orig = M.onCmd
  M.onCmd = function(s)
    orig(s)
    local l = M.dataPools._kids[1].Layouts._kids[1]
    if l and not l._patched then
      l._patched = true
      function l:Append()
        local e = M.handle({}, {})
        setmetatable(e, { __newindex = function(t, k, v) if k == "Action" and v == "Pause" then error("unknown action") end rawset(t, k, v) end })
        self._kids[#self._kids + 1] = e
        return e
      end
    end
  end
  local ok, err = pcall(desk.buildLayout, desk, { { key = "a", x = 0, y = 0, w = 1, h = 1, command = "" } })
  M.onCmd = orig
  T.truthy(ok, "build did not throw: " .. tostring(err))
  local el = M.dataPools._kids[1].Layouts._kids[1]._kids[1]
  T.eq(el.Action, "Go+", "fallback"); T.eq(el.VisibilityElement, true, "element visible")
end)

T.test("cell text is centred vertically and horizontally", function()
  M.reset()
  local desk = az().madesk.createMaDesk()
  desk:install({ fixtures = {}, markers = {}, problems = {} })
  desk:buildLayout({ { key = "toggle", x = 0, y = 0, w = 100, h = 60, command = "Toggle()" } })
  local el = M.dataPools._kids[1].Layouts._kids[1]._kids[1]
  T.eq(el.CustomTextAlignmentV, "Center", "vertical"); T.eq(el.CustomTextAlignmentH, "Center", "horizontal")
end)
