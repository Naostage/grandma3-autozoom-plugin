local T = require("t")
local az = require("az")
local F = require("fakedesk")

local function setup()
  local d = F.new({ fixtures = { F.fixture(101) }, markers = { F.marker(1), F.marker(2) }, problems = {} })
  local a = az().runtime.createAutoZoom(d, "id")
  a:Install()
  return d, a
end

T.test("Program loads marker and offset only", function()
  local d, a = setup()
  a:Program(101, 2)
  T.eq(d.cmds[1], "Fixture 101", "select"); T.eq(d.cmds[2], 'Attribute "XYZ_MArker" At 2', "marker")
  T.eq(#d.cmds, 5, "select + marker + 3 offsets")
  for _, c in ipairs(d.cmds) do T.truthy(not c:find("Zoom", 1, true) and not c:find("Iris", 1, true), "no zoom/iris: " .. c) end
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
