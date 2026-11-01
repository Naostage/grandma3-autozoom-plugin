local T = require("t")
local az = require("az")

local function G(no, name) return { kind = "group", no = no, name = name or ("G" .. no) } end
local function F(fid) return { kind = "fixture", fid = fid } end

T.test("addEntries skips duplicates and keeps order", function()
  local r = az().rows
  T.eq(r.addEntries({ G(3) }, { F(205), G(3), G(4) }), { G(3), F(205), G(4) }, "rows")
end)

T.test("moveEntry swaps neighbours and ignores the ends", function()
  local r = az().rows
  local A, B, C = F(1), F(2), F(3)
  T.eq(r.moveEntry({ A, B, C }, 1, -1), { B, A, C }, "up")
  T.eq(r.moveEntry({ A, B, C }, 0, -1), { A, B, C }, "top stays")
  T.eq(r.moveEntry({ A, B, C }, 2, 1), { A, B, C }, "bottom stays")
  T.eq(r.moveEntry({ A, B, C }, 0, 1), { B, A, C }, "down")
end)

T.test("removeEntry removes one line", function()
  local r = az().rows
  T.eq(r.removeEntry({ F(1), F(2), F(3) }, 1), { F(1), F(3) }, "middle gone")
  T.eq(r.removeEntry({ F(1) }, 5), { F(1) }, "out of range unchanged")
end)

T.test("coverage marks self over group", function()
  local r = az().rows
  local cov = r.coverage({ G(3), F(102) }, { { no = 3, name = "G3", fids = { 101, 102 } } })
  T.eq(cov.fixtures, { ["101"] = "group", ["102"] = "self" }, "fixtures")
  T.eq(cov.groups, { ["3"] = true }, "groups")
end)

T.test("entryLabel for live and missing entries", function()
  local r = az().rows
  local groups = { { no = 3, name = "Front truss", fids = {} } }
  local name = function(fid) if fid == 205 then return "Spot 5" end end
  T.eq(r.entryLabel(G(3, "old"), groups, name), "Group 3  Front truss", "live group")
  T.eq(r.entryLabel(G(9, "Floor"), groups, name), "Group 9  Floor", "missing group keeps saved name")
  T.eq(r.entryLabel(F(205), groups, name), "Fixture 205  Spot 5", "fixture")
  T.eq(r.entryLabel(F(206), groups, name), "Fixture 206", "missing fixture")
end)
