-- Minimal test framework shared by every *_test.lua file.
local T = { total = 0, failed = 0 }

local function deepEq(a, b)
  if type(a) ~= type(b) then return false end
  if type(a) ~= "table" then return a == b end
  for k, v in pairs(a) do if not deepEq(v, b[k]) then return false end end
  for k in pairs(b) do if a[k] == nil then return false end end
  return true
end

local function show(v, depth)
  depth = depth or 0
  if type(v) ~= "table" or depth > 3 then return tostring(v) end
  local parts = {}
  for k, x in pairs(v) do parts[#parts + 1] = tostring(k) .. "=" .. show(x, depth + 1) end
  table.sort(parts)
  return "{" .. table.concat(parts, ", ") .. "}"
end
T.show = show

function T.test(name, fn)
  T.total = T.total + 1
  local ok, err = xpcall(fn, debug.traceback)
  if ok then print("ok   - " .. name)
  else T.failed = T.failed + 1; print("FAIL - " .. name .. "\n" .. tostring(err)) end
end

function T.eq(actual, expected, what)
  if not deepEq(actual, expected) then
    error((what or "value") .. ": expected " .. show(expected) .. ", got " .. show(actual), 2)
  end
end

function T.near(actual, expected, eps, what)
  if type(actual) ~= "number" or math.abs(actual - expected) > (eps or 1e-6) then
    error((what or "value") .. ": expected ~" .. tostring(expected) .. ", got " .. tostring(actual), 2)
  end
end

function T.truthy(v, what)
  if not v then error((what or "value") .. " should be truthy", 2) end
end

function T.finish()
  print(string.format("\n%d/%d passed", T.total - T.failed, T.total))
  os.exit(T.failed == 0 and 0 or 1)
end

return T
