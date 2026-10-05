-- grandMA3 API mock for console-layer tests. Handles are tables with Children()/Count().
local M = {}

local function handle(props, kids)
  local h = props or {}
  h._kids = kids or {}
  function h:Children() local out = {} for i, k in ipairs(self._kids) do out[i] = k end return out end
  function h:Count() return #self._kids end
  return h
end
M.handle = handle

function M.reset()
  -- Invalidate handles of the previous test: the bundle caches handles across tests and checks IsObjectValid.
  if M.dataPools then
    for _, dp in ipairs(M.dataPools._kids) do
      dp._deleted = true
      for _, coll in ipairs({ dp.Sequences, dp.Macros, dp.Layouts }) do
        if coll then for _, x in ipairs(coll._kids) do x._deleted = true; for _, e in ipairs(x._kids) do e._deleted = true end end end
      end
    end
  end
  M.printed, M.cmds, M.vars, M.rt, M.timers = {}, {}, {}, {}, {}
  M.subfixtures, M.subIndexOf, M.nextSub = {}, {}, 0
  M.attrs = { XYZ_MArker = 13, XYZ_X = 9, XYZ_Y = 10, XYZ_Z = 11 }
  M.stages = handle({}, {})
  M.fixtureTypes = handle({}, {})
  M.psn = handle({}, {})
  M.dataPools = handle({}, {})
  M.time = 0
end

function Printf(s) M.printed[#M.printed + 1] = s end
function Cmd(s) M.cmds[#M.cmds + 1] = s; if M.onCmd then M.onCmd(s) end; return "Ok" end
CmdIndirect = Cmd
CmdIndirectWait = Cmd
function Patch() return { Stages = M.stages, FixtureTypes = M.fixtureTypes } end
function ShowData() return { DataPools = M.dataPools, PSNProtocol = M.psn } end
function GlobalVars() return "GlobalVars" end
function GetVar(_, k) return M.vars[k] end
function SetVar(_, k, v) M.vars[k] = v end
function GetSubfixtureCount() return M.nextSub end
function GetSubfixture(i) return M.subfixtures[i] end
function GetAttributeIndex(name) return M.attrs[name] end
function GetUIChannelIndex(sub, attr) if sub == nil or attr == nil then return nil end return sub * 1000 + attr end
function GetRTChannel(uich)
  local v = M.rt[uich]
  if v == nil then return nil end
  return { info = { value_after_master = v.value, cue_part = v.source or "DataPool 1.7.1.1.0" } }
end
function Time() return M.time end
function IsObjectValid(h) return h ~= nil and not h._deleted end
function Timer(fn, period, count, cleanup)
  M.timers[#M.timers + 1] = { fn = fn, period = period, left = count == 0 and math.huge or count, cleanup = cleanup }
end
function M.runTimers(n)
  for _ = 1, n or 1 do
    local list = {}
    for _, t in ipairs(M.timers) do list[#list + 1] = t end
    for _, t in ipairs(list) do if t.left > 0 then t.left = t.left - 1; t.fn() end end
  end
end

function M.channel(attr, from, to)
  local fn = handle({ physicalFrom = from, physicalTo = to }, {})
  local logical = handle({ attribute = attr }, { fn })
  return handle({}, { logical })
end
function M.mode(name, xyz, channels) return handle({ name = name, XYZ = xyz, DMXChannels = handle({}, channels) }, {}) end
function M.fixtureType(name, modes)
  local ft = handle({ name = name, DMXModes = handle({}, modes) }, {})
  M.fixtureTypes._kids[#M.fixtureTypes._kids + 1] = ft
  return ft
end
function M.fixture(fid, typeName, modeName, pos, rot, kids)
  pos = pos or { 0, 0, 0 }; rot = rot or { 0, 0, 0 }
  local h = handle({ fid = fid, name = "F" .. fid, IDType = "Fixture", FixtureType = { name = typeName }, ModeDirect = { name = modeName },
    POSX = pos[1], POSY = pos[2], POSZ = pos[3], ROTX = rot[1], ROTY = rot[2], ROTZ = rot[3] }, kids)
  M.subfixtures[M.nextSub] = { fid = fid }
  M.subIndexOf[fid] = M.nextSub
  M.nextSub = M.nextSub + 1
  return h
end
function M.group(name, pos, rot, kids)
  return handle({ fid = "None", name = name, IDType = "Fixture", FixtureType = { name = "Grouping" },
    POSX = pos[1], POSY = pos[2], POSZ = pos[3], ROTX = rot[1], ROTY = rot[2], ROTZ = rot[3] }, kids)
end
function M.marker(cid, name, targetSpace)
  return handle({ cid = cid, fid = "None", name = name, IDType = "MArker", TARGETSPACE = targetSpace }, {})
end
function M.space(name, min, max)
  local f = function(n) return string.format("%.3f", n) end
  return handle({ name = name, MINX = f(min[1]), MAXX = f(max[1]), MINY = f(min[2]), MAXY = f(max[2]), MINZ = f(min[3]), MAXZ = f(max[3]) }, {})
end
function M.stage(nodes, spaces)
  M.stages._kids[#M.stages._kids + 1] = handle({
    Fixtures = handle({}, nodes),
    Spaces = handle({}, spaces or { M.space("Stage", { -35, -35, 0 }, { 35, 35, 35 }) }),
  }, {})
end
function M.tracker(cid, x, y, z, rot)
  local t = handle({ MARKERID = cid, POSITIONX = x, POSITIONY = y, POSITIONZ = z }, {})
  if rot then t.ROTX, t.ROTY, t.ROTZ = rot[1], rot[2], rot[3] end
  return t
end
function M.psnSystem(trackers) M.psn._kids[#M.psn._kids + 1] = handle({}, trackers) end
function M.setRt(fid, attr, value, source) M.rt[M.subIndexOf[fid] * 1000 + M.attrs[attr]] = { value = value, source = source } end

M.reset()
return M
