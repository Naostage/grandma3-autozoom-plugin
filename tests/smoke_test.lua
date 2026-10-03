local T = require("t")
local az = require("az")

T.test("test bundle loads", function()
  T.eq(az().ready, true, "ready flag")
end)
