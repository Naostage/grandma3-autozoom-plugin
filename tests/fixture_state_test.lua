local T = require("t")
local az = require("az")
local ESPRITE = { zoomMin = 5.5, zoomMax = 49, irisMin = 0.109, irisMax = 1 }

local function input(over)
  local i = { running = true, armed = true, markerCid = 1, offset = { x = 0, y = 0, z = 0 },
    fixturePos = { x = 0, y = 0, z = 10 }, optics = ESPRITE, size = 2,
    marker = { pos = { x = 0, y = 0, z = 0 }, live = true } }
  for k, v in pairs(over or {}) do i[k] = v end
  return i
end

T.test("states before tracking", function()
  local ev = az().state.evaluate
  T.eq(ev(input({ running = false })).state, "offline", "offline")
  T.eq(ev(input({ armed = false })).output, { kind = "release" }, "disarmed releases")
  T.eq(ev(input({ markerCid = 0, marker = false })).state, "no-marker", "no marker")
  T.eq(ev(input({ markerCid = 7, marker = false })).state, "unknown-marker", "unknown marker")
  T.eq(ev(input({ marker = { pos = { x = 0, y = 0, z = 0 }, live = false } })).output, { kind = "hold" }, "no psn holds")
end)

T.test("tracking aims at marker plus offset", function()
  local r = az().state.evaluate(input({ offset = { x = 0, y = 0, z = 1.5 } }))
  T.eq(r.state, "tracking", "state"); T.near(r.distance, 8.5, 1e-9, "distance"); T.eq(r.output.kind, "set", "output")
  T.eq(r.aim, { x = 0, y = 0, z = 1.5 }, "aim")
end)

T.test("marker rotation turns the offset", function()
  local r = az().state.evaluate(input({ offset = { x = 1, y = 0, z = 0 },
    marker = { pos = { x = 0, y = 0, z = 0 }, rot = { x = 0, y = 0, z = 90 }, live = true } }))
  T.near(r.aim.x, 0, 1e-9, "aim x"); T.near(r.aim.y, 1, 1e-9, "aim y")
end)

T.test("fit maps to state", function()
  T.eq(az().state.evaluate(input({ size = 15 })).state, "too-wide", "too wide")
  T.eq(az().state.evaluate(input({ size = 0.05 })).state, "too-small", "too small")
end)
