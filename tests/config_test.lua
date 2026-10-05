local T = require("t")
local az = require("az")

T.test("format helpers", function()
  local f = az().format
  T.eq(f.fmtInt(101.0), "101", "fmtInt")
  T.eq(f.fmtNum(1.5), "1.5", "fmtNum 1.5")
  T.eq(f.fmtNum(2), "2", "fmtNum 2")
  T.eq(f.fmtNum(0.1094), "0.109", "fmtNum rounds")
  T.eq(f.fmtNum(-0.0001), "0", "fmtNum -0")
  T.eq(f.fidKey(101), "101", "fidKey")
end)

T.test("missing config gives defaults without warning", function()
  local r = az().config.parseConfig(nil)
  T.eq(r.config.rate, 30, "rate"); T.eq(r.config.range, { 0.5, 5 }, "range"); T.eq(r.warning, nil, "warning")
end)

T.test("config round trip", function()
  local c = az().config
  local cfg = c.defaultConfig()
  cfg.armed = { 101, 103 }; cfg.size["104"] = 1.5; cfg.offset.source = "preset"; cfg.offset.preset = "2.12"
  T.eq(c.parseConfig(c.serializeConfig(cfg)).config, cfg, "config")
end)

T.test("unreadable config warns and falls back", function()
  local r = az().config.parseConfig("not json")
  T.truthy(r.warning, "warning"); T.eq(r.config.armed, {}, "armed")
end)

T.test("invalid fields fall back individually", function()
  local r = az().config.parseConfig('{"armed":[101,"x"],"rate":500,"range":[3,1],"size":{"104":-1,"105":2}}')
  T.eq(r.config.armed, { 101 }, "armed"); T.eq(r.config.rate, 30, "rate")
  T.eq(r.config.range, { 0.5, 5 }, "range"); T.eq(r.config.size, { ["105"] = 2 }, "size")
end)

T.test("prune drops fixtures that left the patch", function()
  local c = az().config
  local cfg = c.defaultConfig(); cfg.armed = { 101, 999 }; cfg.size["999"] = 2; cfg.size["101"] = 1
  local p = c.pruneConfig(cfg, { 101, 102 })
  T.eq(p.armed, { 101 }, "armed"); T.eq(p.size, { ["101"] = 1 }, "size")
end)

T.test("applySetup validates answers", function()
  local c = az().config
  local r = c.applySetup(c.defaultConfig(), { source = "values", preset = "", x = "0", y = "-1", z = "0.3", min = "1", max = "4", rate = "25" })
  T.eq(r.config.offset.values, { 0, -1, 0.3 }, "values"); T.eq(r.config.range, { 1, 4 }, "range"); T.eq(r.config.rate, 25, "rate"); T.eq(r.errors, {}, "errors")
  local bad = c.applySetup(c.defaultConfig(), { source = "preset", preset = "", x = "a", y = "0", z = "0", min = "5", max = "1", rate = "0" })
  T.eq(#bad.errors, 4, "errors: preset empty, x, range, rate"); T.eq(bad.config.offset.source, "values", "source kept")
  T.eq(c.offsetLabel(r.config), "0/-1/0.3 m", "label values")
end)

T.test("offset label shows plain and data pool presets", function()
  local c = az().config
  local cfg = c.defaultConfig(); cfg.offset.source = "preset"
  cfg.offset.preset = "2.30"; T.eq(c.offsetLabel(cfg), "Preset 2.30", "plain")
  cfg.offset.preset = "DataPool 4 Preset 2.30"; T.eq(c.offsetLabel(cfg), "DP4 2.30", "data pool")
end)

T.test("applySetup normalizes a typed data pool preset", function()
  local c = az().config
  local function preset(text)
    return c.applySetup(c.defaultConfig(), { source = "preset", preset = text, x = "0", y = "0", z = "0", min = "1", max = "4", rate = "30" }).config.offset.preset
  end
  T.eq(preset(" datapool 4 preset 2.30 "), "DataPool 4 Preset 2.30", "data pool, any case")
  T.eq(preset("DATAPOOL 4 PRESET 2.30"), "DataPool 4 Preset 2.30", "upper case")
  T.eq(preset("2.30"), "2.30", "plain number kept")
  T.eq(preset("Preset 2.30"), "2.30", "preset word dropped")
end)
