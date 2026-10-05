local T = require("t")
local az = require("az")

local function fx(fid) return { fid = fid, name = "Spot " .. fid, position = { x = 0, y = 0, z = 10 },
  optics = { zoomMin = 5.5, zoomMax = 49, irisMin = 0.109, irisMax = 1 }, uich = { marker = 1, x = 2, y = 3, z = 4 } } end
local MARKERS = { { cid = 1, name = "Lead" }, { cid = 2, name = "Bass" } }

T.test("layout cells cover header, marker heads and every row cell", function()
  local cells = az().view.layoutCells({ fx(101), fx(102) }, MARKERS)
  local keys = {}
  for _, c in ipairs(cells) do keys[c.key] = c.command end
  T.eq(keys["toggle"], "Toggle()", "toggle"); T.eq(keys["setup"], "Setup()", "setup"); T.eq(keys["rescan"], "Rescan()", "rescan")
  for _, gone in ipairs({ "capture", "offset", "armall", "disarmall" }) do T.eq(keys[gone], nil, "no " .. gone .. " cell") end
  T.eq(keys["arm 101"], "ArmToggle(101)", "arm"); T.eq(keys["mx 102 2"], "Program(102,2)", "matrix")
  T.eq(keys["sz 101"], "Size(101)", "size"); T.eq(keys["st 101"], "", "state is display only")
  T.eq(keys["mh 2"], "", "marker head"); T.eq(#cells, 6 + 2 + 2 * (1 + 2 + 5), "count")
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

T.test("header cells are status, toggle, setup, rescan, size, message in that order", function()
  local cells = az().view.layoutCells({}, {})
  local order = {}
  for _, c in ipairs(cells) do if c.y == 0 then order[#order + 1] = c.key end end
  T.eq(order, { "status", "toggle", "setup", "rescan", "size", "message" }, "header order")
  local views = az().view.buildViews({ running = true, liveMarkers = 0, globalSize = 1, offsetLabel = "", message = "hi" }, {}, {}, {})
  T.eq(views["rescan"].text, "Rescan\npatch", "rescan text"); T.eq(views["rescan"].appearance, "button", "rescan look")
  for _, gone in ipairs({ "capture", "offset", "armall", "disarmall" }) do T.eq(views[gone], nil, "no " .. gone .. " view") end
end)

T.test("message cell shows the pick countdown while picking", function()
  local v = az().view
  local views = v.buildViews({ running = true, pickSecondsLeft = 7, liveMarkers = 0, globalSize = 1, offsetLabel = "", message = "Tap the preset that holds the XYZ offset" }, {}, {}, {})
  T.eq(views["message"].text, "Tap a preset…  7 s", "countdown"); T.eq(views["message"].appearance, "capture", "capture look")
  views = v.buildViews({ running = true, liveMarkers = 0, globalSize = 1, offsetLabel = "", message = "Setup saved" }, {}, {}, {})
  T.eq(views["message"].text, "Setup saved", "message"); T.eq(views["message"].appearance, "header", "header look")
end)

T.test("cells carry appearance kinds", function()
  local v = az().view
  local header = { running = true, liveMarkers = 1, globalSize = 2, offsetLabel = "0/0/0 m", message = "hi" }
  local row = { fixture = fx(101), armed = true, markerCid = 1, programmerCid = 2, offset = { x = 0, y = 0, z = 0 },
    result = { state = "too-wide", output = { kind = "set", zoom = 100, iris = 100 }, distance = 5, achieved = 4, zoom = 100, iris = 100 },
    size = 2, sizeFixed = false }
  local views = v.buildViews(header, { row }, MARKERS, { ["1"] = { pos = { x = 0, y = 0, z = 0 } } })
  T.eq(views["status"].appearance, "tracking", "status running")
  T.eq(views["toggle"].appearance, "button", "button")
  T.eq(views["size"].appearance, "header", "size value")
  T.eq(views["message"].appearance, "header", "message")
  T.eq(views["mh 1"].appearance, "tracking", "live marker head")
  T.eq(views["mh 2"].appearance, "nopsn", "marker head without PSN")
  T.eq(views["arm 101"].appearance, "tracking", "armed")
  T.eq(views["mx 101 1"].appearance, "tracking", "followed (too-wide counts as driven)")
  T.eq(views["mx 101 2"].appearance, "programmer", "programmer cell")
  T.eq(views["st 101"].appearance, "warn", "too wide")
  T.eq(views["zo 101"].appearance, "idle", "value cell")
  T.eq(views["sz 101"].appearance, "button", "size cell is tappable")
  T.eq(v.APPEARANCES.tracking, { name = "AZ Tracking", rgba = "137A38E0" }, "palette")
end)
