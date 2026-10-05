-- Runs the real plugin bundle (out/autozoom-grandma3.lua) against the grandMA3 mock.
local T = require("t")
local M = require("ma3mock")

local function show()
  M.reset()
  M.fixtureType("Robin Esprite", { M.mode("Mode 2", true, { M.channel("Zoom", 49, 5.5), M.channel("Iris", 1, 0.109) }) })
  M.stage({ M.fixture(101, "Robin Esprite", "Mode 2", { 0, 0, 10 }), M.fixture(102, "Robin Esprite", "Mode 2", { 4, 0, 10 }), M.marker(1, "Lead") })
  M.psnSystem({ M.tracker(1, 0, 0, 0) })
  AZ = nil
end

local function seq(name)
  for _, dp in ipairs(M.dataPools._kids) do for _, s in ipairs(dp.Sequences._kids) do if s.name == name then return s end end end
end
local function element(key)
  for _, dp in ipairs(M.dataPools._kids) do for _, l in ipairs(dp.Layouts._kids) do
    for _, e in ipairs(l._kids) do if e.Note == "AZ:" .. key then return e end end end end
end

T.test("plugin installs, follows a cue marker and drives the zoom fader", function()
  show()
  local main = dofile("out/autozoom-grandma3.lua")
  main(nil, nil)
  T.truthy(seq("AZ_ZOOM_101"), "zoom sequence"); T.truthy(element("arm 101"), "layout element")
  AZ:Arm("101")
  M.setRt(101, "XYZ_MArker", 1, "DataPool 1.7.1.1.0")
  seq("AZ_SIZE").master = 100 * (2 - 0.5) / (5 - 0.5)   -- 2 m
  M.runTimers(2)
  T.near(seq("AZ_ZOOM_101").faders.FaderTemp, 13.6, 0.05, "zoom temp")
  T.eq(element("st 101").CustomTextText:sub(1, 8), "Tracking", "state cell")
  T.eq(element("status").CustomTextText:sub(1, 7), "Running", "status cell")
end)

T.test("running the plugin again replaces the instance", function()
  show()
  local main = dofile("out/autozoom-grandma3.lua")
  main(nil, nil); local first = AZ
  main(nil, nil)
  T.truthy(AZ ~= first, "new instance")
  M.runTimers(3)   -- old timers must be no-ops and must not error
  T.eq(element("status").CustomTextText:sub(1, 7), "Running", "still running")
end)
