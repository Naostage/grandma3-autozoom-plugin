-- Fake Desk for runtime tests: records every call, returns scripted values.
local F = {}

function F.fixture(fid, x, y, z, optics)
  return { fid = fid, name = "Spot " .. fid, position = { x = x or 0, y = y or 0, z = z or 10 },
    optics = optics or { zoomMin = 5.5, zoomMax = 49, irisMin = 0.109, irisMax = 1 },
    uich = { marker = fid * 10 + 1, x = fid * 10 + 2, y = fid * 10 + 3, z = fid * 10 + 4 } }
end

function F.marker(cid, name) return { cid = cid, name = name or ("Marker " .. cid) } end

function F.new(scan)
  local d = { logs = {}, saved = {}, faders = {}, releases = {}, laters = {}, cmds = {}, t = 0,
    undos = 0, cids = {}, offsets = {}, progCids = {}, markers = {}, answers = {},
    scanResult = scan or { fixtures = {}, markers = {}, problems = {} } }
  function d:lastCommand() return self.lastCmd end
  function d:topUndoName() return self.undoName end
  function d:undoMark() return tostring(self.undoIndex or 0) .. "|" .. tostring(self.undoCount or 0) .. "|" .. tostring(self.undoName or "") end
  function d:undoProgrammer() self.undos = self.undos + 1 end
  function d:now() return self.t end
  function d:log(m) self.logs[#self.logs + 1] = m end
  function d:loadText(k) return self.saved[k] end
  function d:saveText(k, v) self.saved[k] = v end
  function d:scan() return self.scanResult end
  function d:install(scan) self.installed = scan end
  function d:readMarkerCid(f) return self.cids[f.fid] or 0 end
  function d:readOffset(f)
    if self.offsetError and self.offsetError[f.fid] then error(self.offsetError[f.fid]) end
    local o = self.offsets[f.fid] or { 0, 0, 0 }
    return { x = o[1], y = o[2], z = o[3] }
  end
  function d:readProgrammerCid(f) return self.progCids[f.fid] or 0 end
  function d:readMarkers() return self.markers end
  function d:readSizeFader() return self.size end
  function d:setFaders(f, zoom, iris) self.faders[#self.faders + 1] = { fid = f.fid, zoom = zoom, iris = iris } end
  function d:releaseFaders(f) self.releases[#self.releases + 1] = f.fid end
  function d:buildLayout(cells) self.cells = cells end
  function d:refreshLayout(views) self.views = views end
  function d:startLoop(rate, tick, cleanup) self.loop = { rate = rate, tick = tick, cleanup = cleanup } end
  function d:stopLoop() local l = self.loop; self.loop = nil; if l then l.cleanup() end end
  function d:later(fn) self.laters[#self.laters + 1] = fn end
  function d:prompt(title, value) self.lastPrompt = { title = title, value = value }; return table.remove(self.answers, 1) end
  function d:setupDialog(current) self.setupShown = current; return self.setupAnswer end
  function d:runCommands(c) for _, x in ipairs(c) do self.cmds[#self.cmds + 1] = x end end
  function d:tick(n) for _ = 1, n or 1 do self.loop.tick() end end
  function d:runLaters() local l = self.laters; self.laters = {}; for _, fn in ipairs(l) do fn() end end
  return d
end

return F
