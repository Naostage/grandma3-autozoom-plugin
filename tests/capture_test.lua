local T = require("t")
local az = require("az")
local F = require("fakedesk")

local function setup()
  local d = F.new({ fixtures = { F.fixture(101), F.fixture(102) }, markers = { F.marker(1) }, problems = {} })
  local a = az().runtime.createAutoZoom(d, "id")
  a:Install(); a:Arm("102,101"); a:Start()
  d.cues["S12"] = { [1] = "", [2] = [[Go+ Sequence 3; Lua "AZ:Arm('101')"]], [3] = "" }
  return d, a
end
local MAIN = { id = "S12", no = 12, name = "Main" }

T.test("capture stores arms in the running cue after a selection change", function()
  local d, a = setup()
  d.selected = { id = "S1", no = 1, name = "Other" }
  a:Capture(); d:tick()
  T.eq(d.views["capture"].text, "Select a sequence…\n15 s · tap to cancel", "waiting")
  d.selected = MAIN; d.runningCues["S12"] = 2; d.answers = { "2" }
  d:tick(); d:runLaters()
  T.eq(d.lastPrompt.value, "2", "prefilled with running cue")
  T.eq(d.cues["S12"][2], [[Go+ Sequence 3; Lua "if AZ then AZ:Arm('101,102') end"]], "rewritten")
  T.eq(d.logs[#d.logs], "Stored in Seq 12 'Main' cue 2", "feedback")
end)

T.test("selected cue wins over running cue", function()
  local d, a = setup()
  a:Capture(); d.selected = MAIN; d.runningCues["S12"] = 1; d.selectedCues["S12"] = 3; d.answers = { "3" }
  d:tick(); d:runLaters()
  T.eq(d.lastPrompt.value, "3", "prefill"); T.eq(d.cues["S12"][3], [[Lua "if AZ then AZ:Arm('101,102') end"]], "stored")
end)

T.test("capture start explains how to pick an already selected sequence", function()
  local d, a = setup()
  d.selected = MAIN
  a:Capture(); d:tick()
  T.truthy(d.views["message"].text:find("select another sequence first"), "message")
end)

T.test("capture times out and can be cancelled", function()
  local d, a = setup()
  a:Capture(); d.t = 16; d:tick()
  T.eq(d.logs[#d.logs], "Capture timed out", "timeout")
  a:Capture(); a:Capture()
  T.eq(d.logs[#d.logs], "Capture cancelled", "cancel")
end)

T.test("unknown cue or cancelled prompt writes nothing", function()
  local d, a = setup()
  a:Capture(); d.selected = MAIN; d.answers = { "9" }
  d:tick(); d:runLaters()
  T.eq(d.logs[#d.logs], "Seq 12 has no cue 9; nothing stored", "unknown cue")
  a:Capture(); d.selected = { id = "S5", no = 5, name = "Five" }
  d:tick(); d:runLaters()
  T.eq(d.logs[#d.logs], "Capture cancelled", "cancelled prompt")
end)

local function has(list, text)
  for _, l in ipairs(list) do if l == text then return true end end
  return false
end

T.test("stopping during a capture cancels it", function()
  local d, a = setup()
  a:Capture(); d:tick()
  a:Stop()
  T.truthy(has(d.logs, "Capture cancelled"), "cancelled logged")
  T.eq(d.views["capture"].text, "Capture\narms → cue", "idle button")
end)

T.test("capture is refused while stopped", function()
  local d, a = setup()
  a:Stop(); a:Capture()
  T.eq(d.logs[#d.logs], "Start AutoZoom to use Capture", "refused")
  T.eq(d.views["capture"].text, "Capture\narms → cue", "idle button")
end)
