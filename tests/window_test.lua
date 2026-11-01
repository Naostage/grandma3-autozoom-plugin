local T = require("t")
local az = require("az")
local U = require("ma3ui")

T.test("button registers its signal and the click runs it", function()
  U.install(); local w = az().window; w.setPlugin(U.signals, {})
  local hit = 0
  local body = w.buildBase("AutoZoom — test", 600)
  w.button(w.row(body, 0), "Go", 100, 50, "AZW_Test", function() hit = hit + 1 end)
  U.click("AZW_Test")
  T.eq(hit, 1, "clicked once"); T.truthy(U.texts():find("Go", 1, true), "button drawn")
end)

T.test("closeWindow clears the overlay", function()
  U.install(); local w = az().window; w.setPlugin(U.signals, {})
  w.buildBase("x", 600); w.closeWindow()
  T.eq(U.texts(), "", "nothing left")
end)
