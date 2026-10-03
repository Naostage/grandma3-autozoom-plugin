local T = require("t")
local az = require("az")

T.test("json round trip", function()
  local json = az().json
  local text = json.encode({ v = 1, armed = { 101, 102 }, size = { ["104"] = 1.5 }, name = "a \"b\"\n" })
  T.eq(json.decode(text), { v = 1, armed = { 101, 102 }, size = { ["104"] = 1.5 }, name = "a \"b\"\n" }, "decoded")
end)

T.test("json encodes integers without decimals and sorts keys", function()
  T.eq(az().json.encode({ b = 2, a = 0.5 }), '{"a":0.5,"b":2}', "text")
end)

T.test("json rejects garbage", function()
  local ok = pcall(az().json.decode, "{oops")
  T.eq(ok, false, "pcall result")
end)
