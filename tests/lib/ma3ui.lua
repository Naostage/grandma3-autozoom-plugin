-- Fake grandMA3 UI tree (screen overlay, Append, cell sizing) for the window tests.
local U = {}

local function node(class)
  local n = { class = class, children = {} }
  local cells = {}
  return setmetatable(n, {
    __index = function(_, k)
      if type(k) == "number" then
        cells[k] = cells[k] or setmetatable({}, { __index = function(c, j)
          rawset(c, j, {}); return rawget(c, j) end })
        return cells[k]
      end
      if k == "Append" then
        return function(self, cls)
          local c = node(cls); self.children[#self.children + 1] = c; return c
        end
      end
      if k == "ClearUIChildren" then return function(self) self.children = {} end end
      return nil
    end,
  })
end

U.signals = {}

function U.install()
  U.overlay = node("ScreenOverlay")
  U.signals = {}
  _G.GetFocusDisplay = function() return {} end
  _G.Obj = { Index = function() return 1 end }
  _G.GetDisplayByIndex = function() return { ScreenOverlay = U.overlay } end
  _G.Root = function() return { ColorTheme = { ColorGroups = { Global = { ErrorText = "red", Selected = "green", WarningText = "yellow" },
    ProgLayer = { Absolute = "blue" } } } } end
  _G.CloseAllOverlays = function() end
end

function U.find(pred, n, out)
  n = n or U.overlay
  out = out or {}
  if pred(n) then out[#out + 1] = n end
  for _, c in ipairs(n.children) do U.find(pred, c, out) end
  return out
end

-- All Text values in draw order, joined by " | ".
function U.texts()
  local t = {}
  for _, n in ipairs(U.find(function(x) return rawget(x, "Text") ~= nil end)) do t[#t + 1] = tostring(n.Text) end
  return table.concat(t, " | ")
end

function U.click(name, caller)
  local fn = U.signals[name]
  assert(fn, "no signal " .. tostring(name))
  fn(caller or {})
end

return U
