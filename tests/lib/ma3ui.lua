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
  U.display = { name = "Display 1" }
  _G.GetFocusDisplay = function() return U.display end
  -- Obj.Index(handle) is a plain function on the console: Obj:Index(handle) would pass Obj as the handle.
  _G.Obj = { Index = function(h) if h ~= U.display then error("Obj.Index called with " .. tostring(h)) end return 1 end }
  _G.GetDisplayByIndex = function() return { ScreenOverlay = U.overlay } end
  _G.Root = function() return { ColorTheme = { ColorGroups = { Global = { ErrorText = "red", Selected = "blue", SuccessText = "green", WarningText = "yellow" },
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

-- The window body and the body row holding the button wired to `signal`.
function U.bodyRowOf(signal)
  local body = U.find(function(x) return x.class == "DialogFrame" end)[1]
  for _, c in ipairs(body.children) do
    for _, b in ipairs(c.children) do if b.Clicked == signal then return c, body end end
  end
  return nil, body
end

function U.click(name, caller)
  local fn = U.signals[name]
  assert(fn, "no signal " .. tostring(name))
  fn(caller or {})
end

return U
