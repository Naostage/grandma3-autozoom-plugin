local T = require("t")
local az = require("az")

T.test("arm list parsing ignores junk, sorts and dedupes", function()
  T.eq(az().arm.parseArmList("103,101,101"), { 101, 103 }, "sorted unique")
  T.eq(az().arm.parseArmList(" 101, x,102 ,-3, 1.5,101"), { 101, 102 }, "parsed")
end)

T.test("empty arm list", function()
  T.eq(az().arm.parseArmList(""), {}, "empty")
end)

T.test("program commands with values offset", function()
  local cmds = az().program.programCommands(101, 1, { source = "values", preset = "", values = { 0, -1, 0.3 } })
  T.eq(cmds, {
    "Fixture 101",
    'Attribute "XYZ_MArker" At 1',
    'Attribute "XYZ_X" At 0',
    'Attribute "XYZ_Y" At -1',
    'Attribute "XYZ_Z" At 0.3',
  }, "commands")
end)

T.test("program commands with preset offset and no iris", function()
  local cmds = az().program.programCommands(102, 4, { source = "preset", preset = "2.12", values = { 0, 0, 0 } })
  T.eq(cmds, { "Fixture 102", 'Attribute "XYZ_MArker" At 4', 'Attribute "XYZ_X" Thru "XYZ_Z" At Preset 2.12' }, "commands")
  T.eq(az().program.releaseCommands(102), { "Off Fixture 102" }, "release")
end)
