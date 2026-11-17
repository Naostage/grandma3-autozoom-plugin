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

T.test("program commands accept a data pool preset address", function()
  local cmds = az().program.programCommands({ 102 }, 4, { source = "preset", preset = "DataPool 4 Preset 2.30", values = { 0, 0, 0 } })
  T.eq(cmds[3], 'Attribute "XYZ_X" Thru "XYZ_Z" At DataPool 4 Preset 2.30', "data pool address")
end)

local U = require("ma3ui")
local M = require("ma3mock")

local function setup()
  local d = F.new({ fixtures = { F.fixture(101) }, markers = { F.marker(1) }, problems = {} })
  local a = az().runtime.createAutoZoom(d, "id")
  a:Install()
  return d, a
end

local ANSWERS = { source = "values", preset = "", x = "9", y = "9", z = "9", min = "2", max = "3", rate = "60" }
local function answers(action) local t = { action = action } for k, v in pairs(ANSWERS) do t[k] = v end return t end

T.test("Pick preset opens the picker even while stopped", function()
  local d, a = setup()
  d.setupAnswer = answers("pick")
  a:Setup(); d:runLaters()
  T.truthy(d.picker, "picker opened"); T.eq(d.picker.current, "", "current preset")
  T.eq(a.config.rate, 30, "other answers not applied")
  d.picker.onPick("2.30")
  local cfg = az().config.parseConfig(d.saved["AutoZoom.config"]).config
  T.eq(cfg.offset.source, "preset", "source"); T.eq(cfg.offset.preset, "2.30", "preset")
  T.eq(d.logs[#d.logs], "Offset preset 2.30", "logged")
  T.eq(d.views["setup"].text, "Setup\nXYZ Preset 2.30", "setup cell shows preset")
end)

T.test("PickOffset opens the picker", function()
  local d, a = setup()
  a.config.offset.preset = "2.12"
  a:Start(); a:PickOffset()
  T.truthy(d.picker, "picker opened"); T.eq(d.picker.current, "2.12", "current preset")
  d.saved["AutoZoom.instance"] = "other"; d.picker = nil
  a:PickOffset()
  T.eq(d.picker, nil, "refused when not current")
end)

local function pickerWindow()
  M.reset(); U.install()
  M.presetPool(2, "Position")
  M.preset(2, 1, "Pan only", { Pan = {} })
  M.preset(2, 30, "Offset", { XYZ_X = {}, XYZ_Y = {} })
  az().window.setPlugin(U.signals, {})
  local got = {}
  az().madesk.createMaDesk():openPresetPicker("", function(p) got[#got + 1] = p end)
  return got
end

local function tile(prefix)
  return U.find(function(n) return type(rawget(n, "Text")) == "string" and n.Text:sub(1, #prefix) == prefix end)[1]
end

T.test("picker window greys presets without XYZ and picks a tile", function()
  local got = pickerWindow()
  T.truthy(U.texts():find("choose the XYZ offset preset", 1, true), "title")
  T.eq(tile("2.1 ").Enabled, "No", "no XYZ greyed")
  T.truthy(tile("2.1 ").Text:find("no XYZ", 1, true), "status text")
  T.truthy(tile("2.30").Enabled ~= "No", "XYZ preset usable")
  U.click(tile("2.30").Clicked)
  T.eq(got, { "2.30" }, "picked"); T.eq(U.texts(), "", "window closed")
end)

T.test("Cancel closes without a pick", function()
  local got = pickerWindow()
  U.click("AZW_PickCancel")
  T.eq(got, {}, "no pick"); T.eq(U.texts(), "", "window closed")
end)

T.test("Cancel sits above the grid, so a full pool cannot push it off a short screen", function()
  pickerWindow()
  local holder, body = U.bodyRowOf("AZW_PickCancel")
  T.truthy(holder, "Cancel in a body row"); T.eq(holder.Anchors, "0,1", "hint row, under the pool tabs")
  T.eq(body.Rows, 3, "tabs, hint + Cancel, grid: no footer row")
end)

T.test("Setup with Save applies the answers", function()
  local d, a = setup()
  d.setupAnswer = { action = "save", source = "values", preset = "", x = "1", y = "2", z = "3", min = "1", max = "4", rate = "30" }
  a:Setup(); d:runLaters()
  T.eq(a.config.offset.values, { 1, 2, 3 }, "applied"); T.eq(d.picker, nil, "no picker")
  T.eq(a.message, "Setup saved", "saved")
end)
