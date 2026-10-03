-- Loads the test bundle (build/azlib.lua, built by `npm run build:test`) once.
local cached
return function()
  if not cached then cached = dofile("build/azlib.lua") end
  return cached
end
