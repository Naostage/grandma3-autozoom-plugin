local T = require("t")
local az = require("az")
local ESPRITE = { zoomMin = 5.5, zoomMax = 49, irisMin = 0.109, irisMax = 1 }

T.test("vec helpers", function()
  local v = az().vec
  T.near(v.distance(v.vec(0, 0, 10), v.vec(0, 0, 1.5)), 8.5, 1e-9, "distance")
  local r = v.rotate(v.vec(1, 0, 0), v.vec(0, 0, 90))
  T.near(r.x, 0, 1e-9, "x"); T.near(r.y, 1, 1e-9, "y"); T.near(r.z, 0, 1e-9, "z")
end)

T.test("zoom only within range", function()
  local b = az().beam.beamFor(10, 2, ESPRITE)   -- 11.42 deg
  T.eq(b.fit, "ok", "fit"); T.near(b.zoom, 13.6, 0.05, "zoom"); T.eq(b.iris, 100, "iris"); T.near(b.achieved, 2, 1e-9, "achieved")
end)

T.test("iris below minimum zoom", function()
  local b = az().beam.beamFor(10, 0.5, ESPRITE)  -- 0.5 / 0.9607 = 0.5205
  T.eq(b.fit, "ok", "fit"); T.eq(b.zoom, 0, "zoom"); T.near(b.iris, 46.2, 0.05, "iris")
end)

T.test("too small clamps iris to 0", function()
  local b = az().beam.beamFor(10, 0.05, ESPRITE)
  T.eq(b.fit, "too-small", "fit"); T.eq(b.iris, 0, "iris"); T.near(b.achieved, 0.9607 * 0.109, 0.001, "achieved")
end)

T.test("too wide", function()
  local b = az().beam.beamFor(10, 15, ESPRITE)
  T.eq(b.fit, "too-wide", "fit"); T.eq(b.zoom, 100, "zoom"); T.eq(b.iris, 100, "iris"); T.near(b.achieved, 9.1145, 0.001, "achieved")
end)

T.test("fixture without iris", function()
  local b = az().beam.beamFor(10, 0.5, { zoomMin = 5.5, zoomMax = 49, irisMin = 0, irisMax = 0 })
  T.eq(b.fit, "too-small", "fit"); T.eq(b.zoom, 0, "zoom"); T.eq(b.iris, nil, "iris")
end)

T.test("fixed-angle fixture does not divide by zero", function()
  local b = az().beam.beamFor(10, 1.5, { zoomMin = 11, zoomMax = 11, irisMin = 0.1, irisMax = 1 })  -- 8.6 deg < 11
  T.eq(b.zoom, 0, "zoom"); T.truthy(b.iris == b.iris, "iris not NaN")
end)

T.test("zero distance", function()
  local b = az().beam.beamFor(0, 2, ESPRITE)
  T.eq(b.fit, "too-wide", "fit"); T.eq(b.zoom, 100, "zoom")
end)
