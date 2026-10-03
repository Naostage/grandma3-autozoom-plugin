-- Runs the unit/integration tests. Use: lua tests/run.lua (from the repo root, after `npm run build:test`)
package.path = "tests/?.lua;tests/lib/?.lua;" .. package.path
local T = require("t")

local FILES = {
  "smoke_test",
  "json_test",
  "config_test",
  "beam_test",
  "fixture_state_test",
  "commands_test",
  "view_model_test",
  "runtime_test",
  "capture_test",
  "program_test",
}

for _, name in ipairs(FILES) do
  print("\n# " .. name)
  dofile("tests/" .. name .. ".lua")
end
T.finish()
