package.path = "test/?.lua;" .. package.path
local mocks = require("mocks")
local plugin = assert(loadfile("out/autozoom-grandma3.lua"))

local tests = {}
local function test(name, fn) tests[#tests + 1] = {name = name, fn = fn} end

local function assertEqual(actual, expected, what)
    if actual ~= expected then
        error((what or "value") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
    end
end

local function zoomFader(fid)
    local seq = mocks.sequence("AZ_ZOOM_" .. fid)
    return seq and seq.fader
end

-- Fixtures 101..103 hang 10m above marker 1001 (PSN marker id 1), beam 3m -> zoom 27, at 5m -> zoom 63
local function setup()
    mocks.reset()
    for _, fid in ipairs({101, 102, 103}) do mocks.addFixture(fid, 0, 0, 10) end
    mocks.addMarker(1001, 1)
    mocks.addMarker(1002, 2)
    mocks.setTracker(1, 0, 0, 0)
    plugin()()
end

test("EnableFixture with size fader enabled before its sequence exists falls back to the beam size", function()
    mocks.addSequence("AZ_ZOOM_101")
    AZ:Enable()
    AZ:EnableSizeFader(101)
    AZ:EnableFixture(101, 1001, 3)
    mocks.tick()
    assertEqual(zoomFader(101), 27, "AZ_ZOOM_101 with fixture size fader")
    AZ:EnableGlobalSizeFader()
    AZ:EnableFixture(101, 1001, 3)
    mocks.tick()
    assertEqual(zoomFader(101), 27, "AZ_ZOOM_101 with global size fader")
end)

test("zoom fader is set once sequences are created after EnableFixture", function()
    AZ:Enable()
    AZ:EnableFixture(101, 1001, 3)
    AZ:CreateAZSequences(101)
    mocks.tick()
    assertEqual(zoomFader(101), 27, "AZ_ZOOM_101")
end)

test("EnableFixture does not move faders when the marker is not tracked", function()
    mocks.addSequence("AZ_ZOOM_101")
    AZ:Enable()
    AZ:EnableFixture(101, 1002, 3)
    mocks.tick()
    assertEqual(zoomFader(101), nil, "AZ_ZOOM_101")
end)

test("fixture on an untracked marker follows it once a PSN tracker is assigned", function()
    mocks.addSequence("AZ_ZOOM_101")
    AZ:Enable()
    AZ:EnableFixture(101, 1002, 3)
    mocks.tick()
    mocks.setTracker(2, 0, 0, 5)
    mocks.tick()
    assertEqual(zoomFader(101), 63, "AZ_ZOOM_101")
end)

test("Enable re-syncs faders changed while AutoZoom was disabled", function()
    local seq = mocks.addSequence("AZ_ZOOM_101")
    AZ:Enable()
    AZ:EnableFixture(101, 1001, 3)
    AZ:Disable()
    seq.fader = 50
    AZ:Enable()
    mocks.tick()
    assertEqual(zoomFader(101), 27, "AZ_ZOOM_101")
end)

test("EnableFixture does not move faders while AutoZoom is disabled", function()
    mocks.addSequence("AZ_ZOOM_101")
    AZ:EnableFixture(101, 1001, 3)
    assertEqual(zoomFader(101), nil, "AZ_ZOOM_101")
end)

test("DisableFixture in the middle keeps the remaining fixtures working", function()
    for _, fid in ipairs({101, 102, 103}) do mocks.addSequence("AZ_ZOOM_" .. fid) end
    AZ:Enable()
    for _, fid in ipairs({101, 102, 103}) do AZ:EnableFixture(fid, 1001, 3) end
    AZ:DisableFixture(102)
    AZ:EnableFixture(103, 1001, 3)
    mocks.setTracker(1, 0, 0, 5)
    mocks.tick()
    assertEqual(zoomFader(101), 63, "AZ_ZOOM_101")
    assertEqual(zoomFader(102), 27, "AZ_ZOOM_102")
    assertEqual(zoomFader(103), 63, "AZ_ZOOM_103")
end)

test("enabled fixtures keep following their marker after ScanPatch", function()
    mocks.addSequence("AZ_ZOOM_101")
    AZ:Enable()
    AZ:EnableFixture(101, 1001, 3)
    AZ:ScanPatch()
    mocks.setTracker(1, 0, 0, 5)
    mocks.tick()
    assertEqual(zoomFader(101), 63, "AZ_ZOOM_101")
end)

test("zoom fader reaches 0 after ScanPatch relinks the fixture", function()
    mocks.addSequence("AZ_ZOOM_101")
    AZ:Enable()
    AZ:EnableFixture(101, 1001, 3)
    AZ:ScanPatch()
    mocks.setTracker(1, 0, 0, -100)
    mocks.tick()
    assertEqual(zoomFader(101), 0, "AZ_ZOOM_101")
end)

test("Enable restarts the update loop even if the previous loop never completed", function()
    AZ:Enable()
    AZ:Disable()
    AZ:Enable()
    assertEqual(#mocks.timers, 2, "registered timers")
    local remaining = AZ.expected_remaining_update
    mocks.tick()
    assertEqual(AZ.expected_remaining_update, remaining - 1, "remaining updates after one tick")
end)

local failed = 0
for _, t in ipairs(tests) do
    setup()
    local ok, err = xpcall(t.fn, debug.traceback)
    if ok then
        print("ok   " .. t.name)
    else
        failed = failed + 1
        print("FAIL " .. t.name .. "\n     " .. tostring(err):gsub("\n", "\n     "))
    end
end
print(("\n%d passed, %d failed"):format(#tests - failed, failed))
if failed > 0 then error("tests failed", 0) end
