local T = require("t")
local az = require("az")
local U = require("ma3ui")
local M = require("ma3mock")

local G3 = { kind = "group", no = 3, name = "Front truss" }
local F205 = { kind = "fixture", fid = 205 }
local CATALOG = {
  groups = { { no = 3, name = "Front truss", fids = { 101, 102 } }, { no = 4, name = "Floor", fids = { 205 } } },
  fixtures = { { fid = 101, name = "Spot 101" }, { fid = 102, name = "Spot 102" }, { fid = 205, name = "Spot 5" } },
}

local function editor(rows)
  M.reset(); U.install()
  az().window.setPlugin(U.signals, {})
  local got = { changes = {}, closed = {} }
  az().madesk.createMaDesk():openRowsEditor(rows, CATALOG,
    function(r) got.changes[#got.changes + 1] = r end,
    function(changed) got.closed[#got.closed + 1] = changed end)
  return got
end

local function tile(prefix)
  return U.find(function(n) return type(rawget(n, "Text")) == "string" and n.Text:sub(1, #prefix) == prefix end)[1]
end

T.test("editor reorders and removes with confirmation", function()
  local got = editor({ G3, F205 })
  T.truthy(U.texts():find("AutoZoom — layout rows", 1, true), "title")
  T.truthy(U.texts():find("Group 3  Front truss", 1, true), "group label")
  T.truthy(U.texts():find("Fixture 205  Spot 5", 1, true), "fixture label")
  U.click("AZW_RowDown_1")
  T.eq(got.changes[1], { F205, G3 }, "moved down")
  M.boxAnswer = { result = 0 }
  U.click("AZW_RowDel_1")
  T.eq(#got.changes, 1, "No keeps the line")
  T.eq(M.lastBox.message, "Remove Fixture 205  Spot 5?", "confirmation text")
  M.boxAnswer = { result = 1 }
  U.click("AZW_RowDel_1")
  T.eq(got.changes[2], { G3 }, "Yes removes")
end)

T.test("empty editor shows the hint", function()
  editor({})
  T.truthy(U.texts():find("Empty: every XYZ fixture gets its own row", 1, true), "hint")
end)

T.test("add picker adds several tiles in tap order", function()
  local got = editor({ G3 })
  U.click("AZW_RowAdd")
  U.click("AZW_AddTab_2")
  U.click(tile("205  ").Clicked)
  U.click(tile("101  ").Clicked)
  T.truthy(tile("205  ").Text:find("\n1", 1, true), "tap order 1"); T.truthy(tile("101  ").Text:find("\n2", 1, true), "tap order 2")
  T.truthy(U.texts():find("Add 2", 1, true), "add button counts")
  U.click("AZW_AddOk")
  T.eq(got.changes[#got.changes], { G3, F205, { kind = "fixture", fid = 101 } }, "appended in tap order")
  T.truthy(U.texts():find("AutoZoom — layout rows", 1, true), "back to the editor")
end)

T.test("tapping a picked tile again unpicks it; Cancel adds nothing", function()
  local got = editor({})
  U.click("AZW_RowAdd"); U.click("AZW_AddTab_2")
  U.click(tile("205  ").Clicked); U.click(tile("205  ").Clicked)
  T.eq(tile("205  ").Text:find("\n", 1, true), nil, "unpicked")
  U.click(tile("101  ").Clicked)
  U.click("AZW_AddCancel")
  T.eq(got.changes, {}, "nothing added")
end)

T.test("ticks show what the list covers", function()
  editor({ G3, { kind = "fixture", fid = 102 } })
  U.click("AZW_RowAdd")
  U.click("AZW_AddTab_2")
  local w = az().window
  local t101, t102, t205 = tile("101  "), tile("102  "), tile("205  ")
  T.truthy(t101.Text:find("✔", 1, true), "101 ticked"); T.eq(t101.TextColor, w.tickColor("group"), "101 yellow")
  T.eq(rawget(t101, "Enabled"), nil, "101 still tappable")
  T.truthy(t102.Text:find("✔", 1, true), "102 ticked"); T.eq(t102.TextColor, w.tickColor("self"), "102 green")
  T.eq(t102.Enabled, "No", "102 disabled")
  T.eq(t205.Text:find("✔", 1, true), nil, "205 not ticked")
  U.click("AZW_AddTab_1")
  T.truthy(tile("3  ").Text:find("✔", 1, true), "group 3 ticked"); T.eq(tile("3  ").TextColor, w.tickColor("self"), "group green")
  T.eq(tile("4  ").Text:find("✔", 1, true), nil, "group 4 not ticked")
end)

T.test("Close reports whether anything changed", function()
  local got = editor({ G3, F205 })
  U.click("AZW_RowClose")
  T.eq(got.closed, { false }, "unchanged"); T.eq(U.texts(), "", "window closed")
  got = editor({ G3, F205 })
  U.click("AZW_RowUp_2")
  U.click("AZW_RowClose")
  T.eq(got.closed, { true }, "changed")
end)
