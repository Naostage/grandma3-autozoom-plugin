local T = require("t")
local az = require("az")

local function fx(fid) return { fid = fid, name = "Spot " .. fid, position = { x = 0, y = 0, z = 10 },
  optics = { zoomMin = 5.5, zoomMax = 49, irisMin = 0.109, irisMax = 1 }, uich = { marker = 1, x = 2, y = 3, z = 4 } } end
local MARKERS = { { cid = 1, name = "Lead" }, { cid = 2, name = "Bass" } }

T.test("layout cells cover header, marker heads and every row cell", function()
  local cells = az().view.layoutCells({ fx(101), fx(102) }, MARKERS)
  local keys = {}
  for _, c in ipairs(cells) do keys[c.key] = c.command end
  T.eq(keys["toggle"], "Toggle()", "toggle"); T.eq(keys["capture"], "Capture()", "capture")
  T.eq(keys["arm 101"], "ArmToggle(101)", "arm"); T.eq(keys["mx 102 2"], "Program(102,2)", "matrix")
  T.eq(keys["sz 101"], "Size(101)", "size"); T.eq(keys["st 101"], "", "state is display only")
  T.eq(keys["mh 2"], "", "marker head"); T.eq(#cells, 8 + 2 + 2 * (1 + 2 + 5), "count")
end)

T.test("views for a tracking row and a programmer cell", function()
  local v = az().view
  local header = { running = true, liveMarkers = 1, globalSize = 2, offsetLabel = "0/0/0 m", message = "" }
  local row = { fixture = fx(101), armed = true, markerCid = 1, programmerCid = 2, offset = { x = 0, y = 0, z = 0.3 },
    result = { state = "tracking", output = { kind = "set", zoom = 13.6, iris = 100 }, distance = 8.5, achieved = 2, zoom = 13.6, iris = 100 },
    size = 2, sizeFixed = false }
  local views = v.buildViews(header, { row }, MARKERS, { ["1"] = { pos = { x = 0, y = 0, z = 0 } } })
  T.eq(views["status"].text, "Running\nPSN 1/2", "status")
  T.eq(views["mx 101 1"].text, "●", "following cell"); T.eq(views["mx 101 1"].border, v.COLORS.on, "following colour")
  T.eq(views["mx 101 2"].text, "P", "programmer cell"); T.eq(views["mx 101 2"].border, v.COLORS.bad, "programmer colour")
  T.eq(views["st 101"].text, "Tracking\nLead +0/+0/+0.3", "state")
  T.eq(views["zo 101"].text, "13.6 %", "zoom"); T.eq(views["sz 101"].text, "Global\n2 m", "size")
  T.eq(views["mh 2"].border, v.COLORS.bad, "marker without PSN")
end)

T.test("capture header shows countdown and instructions", function()
  local views = az().view.buildViews({ running = true, captureSecondsLeft = 12, liveMarkers = 0, globalSize = 1, offsetLabel = "", message = "Select a sequence" }, {}, {}, {})
  T.eq(views["capture"].text, "Select a sequence…\n12 s · tap to cancel", "capture")
  T.eq(views["message"].text, "Select a sequence", "message")
end)
