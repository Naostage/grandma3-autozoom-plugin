local T = require("t")
local az = require("az")

T.test("arm command formatting", function()
  local a = az().arm
  T.eq(a.formatArmList({ 103, 101, 101 }), "101,103", "sorted unique")
  T.eq(a.armCommand({ 102, 101 }), [[Lua "if AZ then AZ:Arm('101,102') end"]], "command")
end)

T.test("arm list parsing ignores junk", function()
  T.eq(az().arm.parseArmList(" 101, x,102 ,-3, 1.5,101"), { 101, 102 }, "parsed")
end)

T.test("empty arm list", function()
  T.eq(az().arm.parseArmList(""), {}, "empty")
  T.eq(az().arm.armCommand({}), [[Lua "if AZ then AZ:Arm('') end"]], "command")
end)

T.test("cue command rewrite keeps other commands and replaces old arms", function()
  local a = az().arm
  T.eq(a.rewriteCueCommand([[Go+ Sequence 3; Lua "AZ:Arm('101')"]], [[Lua "AZ:Arm('102')"]]),
    [[Go+ Sequence 3; Lua "AZ:Arm('102')"]], "rewritten")
  T.eq(a.rewriteCueCommand([[Lua "if AZ then AZ:Arm('101') end"; Go+ Sequence 3]], a.armCommand({ 102 })),
    [[Go+ Sequence 3; Lua "if AZ then AZ:Arm('102') end"]], "nil-safe form replaced too")
  T.eq(a.rewriteCueCommand(nil, "X"), "X", "empty existing")
  T.eq(a.rewriteCueCommand("", "X"), "X", "blank existing")
end)

T.test("program commands with values offset", function()
  local optics = { zoomMin = 5.5, zoomMax = 49, irisMin = 0.109, irisMax = 1 }
  local cmds = az().program.programCommands(101, 1, optics, { source = "values", preset = "", values = { 0, -1, 0.3 } })
  T.eq(cmds, {
    "Fixture 101",
    'Attribute "XYZ_MArker" At 1',
    'Attribute "XYZ_X" At 0',
    'Attribute "XYZ_Y" At -1',
    'Attribute "XYZ_Z" At 0.3',
    'Attribute "Zoom" At Absolute Physical 5.5',
    'Attribute "Iris" At Absolute Physical 0.109',
  }, "commands")
end)

T.test("program commands with preset offset and no iris", function()
  local optics = { zoomMin = 10, zoomMax = 40, irisMin = 0, irisMax = 0 }
  local cmds = az().program.programCommands(102, 4, optics, { source = "preset", preset = "2.12", values = { 0, 0, 0 } })
  T.eq(cmds, { "Fixture 102", 'Attribute "XYZ_MArker" At 4', 'Attribute "XYZ_X" Thru "XYZ_Z" At Preset 2.12',
    'Attribute "Zoom" At Absolute Physical 10' }, "commands")
  T.eq(az().program.releaseCommands(102), { "Off Fixture 102" }, "release")
end)
