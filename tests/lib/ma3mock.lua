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

-- grandMA3 handles accept .Name writes and expose .name reads.
local function nameSetter(t, k, v) if k == "Name" then k = "name" end rawset(t, k, v) end

function M.reset()
  -- Invalidate handles of the previous test: the bundle caches handles across tests and checks IsObjectValid.
  if M.dataPools then
    for _, dp in ipairs(M.dataPools._kids) do
      dp._deleted = true
      for _, coll in ipairs({ dp.Sequences, dp.Macros, dp.Layouts }) do
        if coll then for _, x in ipairs(coll._kids) do
          x._deleted = true
          for _, e in ipairs(x._kids) do e._deleted = true; for _, part in ipairs(e._kids or {}) do part._deleted = true end end
        end end
      end
    end
  end
  if M.appearances then for _, a in ipairs(M.appearances._kids) do a._deleted = true end end
  M.printed, M.cmds, M.vars, M.rt, M.timers = {}, {}, {}, {}, {}
  M.subfixtures, M.subIndexOf, M.nextSub = {}, {}, 0
  M.attrs = { XYZ_MArker = 13, XYZ_X = 9, XYZ_Y = 10, XYZ_Z = 11 }
  M.stages = handle({}, {})
  M.fixtureTypes = handle({}, {})
  M.psn = handle({}, {})
  M.dataPools = handle({}, {})
  M.appearances = handle({}, {})
  function M.appearances:Find(name) for _, a in ipairs(self._kids) do if a.name == name then return a end end end
  local function newAppearance(pool, no)
    local a = handle({ name = "", No = no }, {})
    setmetatable(a, { __newindex = nameSetter })
    pool._kids[#pool._kids + 1] = a
    return a
  end
  function M.appearances:Acquire()
    local max = 0
    for _, a in ipairs(self._kids) do if type(a.No) == "number" and a.No > max then max = a.No end end
    return newAppearance(self, max + 1)
  end
  function M.appearances:Resize(n) self.size = n end
  function M.appearances:Create(no, class) self.createdClass = class; return newAppearance(self, no) end
  function M.appearances:GetChildClass() return "Appearance" end
  -- Only reachable through the command line (`Delete Appearance <n> /nc`); the pool has no Delete(no) here.
  function M.deleteAppearance(no)
    for i, a in ipairs(M.appearances._kids) do if a.No == no then a._deleted = true; table.remove(M.appearances._kids, i); return end end
  end
  M.time = 0
  M.cmdObj = { LastCommand = nil, Undos = { UndoIndex = 0 } }
  M.profile = { OopsProgrammer = false }
  M.oopsProgrammerDuringOops = nil
  M.textAnswer, M.boxAnswer = nil, nil
end

function Printf(s) M.printed[#M.printed + 1] = s end
function CmdObj() return M.cmdObj end
function CurrentProfile() return M.profile end
function Cmd(s) M.cmds[#M.cmds + 1] = s; if s == "Oops /nc" then M.oopsProgrammerDuringOops = M.profile and M.profile.OopsProgrammer end; if M.onCmd then M.onCmd(s) end; return "Ok" end
CmdIndirect = Cmd
CmdIndirectWait = Cmd
function Patch() return { Stages = M.stages, FixtureTypes = M.fixtureTypes } end
function ShowData() return { DataPools = M.dataPools, PSNProtocol = M.psn, Appearances = M.appearances } end
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
function M.tracker(cid, x, y, z, rot, online)
  if online == nil then online = "Yes" end
  local t = handle({ MARKERID = cid, POSITIONX = x, POSITIONY = y, POSITIONZ = z, ISONLINE = online }, {})
  if rot then t.ROTX, t.ROTY, t.ROTZ = rot[1], rot[2], rot[3] end
  return t
end
function M.psnSystem(trackers) M.psn._kids[#M.psn._kids + 1] = handle({}, trackers) end
function M.setRt(fid, attr, value, source) M.rt[M.subIndexOf[fid] * 1000 + M.attrs[attr]] = { value = value, source = source } end

local function find(coll, name) for _, c in ipairs(coll._kids) do if c.name == name then return c end end end
local function remove(coll, name)
  for i, c in ipairs(coll._kids) do if c.name == name then c._deleted = true; table.remove(coll._kids, i); return end end
end

function M.pool(name)
  local p = handle({ name = name }, {})
  p.Sequences = handle({}, {}); p.Macros = handle({}, {}); p.Layouts = handle({}, {})
  -- BeatGrid's ensureSeq path: Acquire() an unnamed sequence, then .Name = …
  function p.Sequences:Acquire()
    local s = M.sequence(p, "")
    setmetatable(s, { __newindex = nameSetter })
    return s
  end
  M.dataPools._kids[#M.dataPools._kids + 1] = p
  return p
end

-- Probe P6/P7: children are OffCue (no nil), CueZero (no 0); cues are stored as cue number x 1000.
function M.sequence(pool, name)
  local s = handle({ name = name, no = #pool.Sequences._kids + 1, faders = {}, master = nil }, {})
  function s:SetFader(o) self.faders[o.token] = o.value end
  function s:GetFader(o) return self.master end
  -- New cue appended after the existing ones; Create(i) adds part i (Command empty).
  function s:Append()
    local cue = handle({ name = "" }, {})
    -- Cues read back their number x1000 (probe P6/P7): .No = 1 is stored as no = 1000.
    setmetatable(cue, { __newindex = function(t, k, v) if k == "No" then k, v = "no", v * 1000 end rawset(t, k, v) end })
    function cue:Create(i) local part = handle({ Command = "" }, {}); self._kids[#self._kids + 1] = part; return part end
    self._kids[#self._kids + 1] = cue
    return cue
  end
  s._kids[1] = handle({ name = "OffCue" }, { handle({ Command = "" }, {}) })
  s._kids[2] = handle({ no = 0, name = "CueZero" }, { handle({ Command = "" }, {}) })
  pool.Sequences._kids[#pool.Sequences._kids + 1] = s
  return s
end

function M.layoutObj(pool, name)
  local l = handle({ name = name }, {})
  function l:Append() local e = handle({}, {}); self._kids[#self._kids + 1] = e; return e end
  pool.Layouts._kids[#pool.Layouts._kids + 1] = l
  return l
end

M.onCmd = function(s)
  local created = s:match("^Store DataPool '([^']+)' /nc$")
  if created then if not find(M.dataPools, created) then M.pool(created) end return end
  local p, kind, name = s:match("^Store DataPool '([^']+)' (%a+) '([^']+)' /o /nc$")
  if p then
    local dp = find(M.dataPools, p); if not dp then return end
    if kind == "Sequence" and not find(dp.Sequences, name) then M.sequence(dp, name) end
    if kind == "Macro" and not find(dp.Macros, name) then dp.Macros._kids[#dp.Macros._kids + 1] = handle({ name = name }, {}) end
    if kind == "Layout" and not find(dp.Layouts, name) then M.layoutObj(dp, name) end
    return
  end
  local dp2, dkind, dname = s:match("^Delete DataPool '([^']+)' (%a+) '([^']+)' /nc$")
  if dp2 then local dp = find(M.dataPools, dp2); if dp and dp[dkind .. "s"] then remove(dp[dkind .. "s"], dname) end return end
  local appNo = s:match("^Delete Appearance (%d+) /nc$")
  if appNo then M.deleteAppearance(tonumber(appNo)) end
end

function TextInput(title, value) M.lastPrompt = { title = title, value = value }; return M.textAnswer end
function MessageBox(o) M.lastBox = o; return M.boxAnswer end

M.reset()
return M
