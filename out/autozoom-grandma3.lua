
local ____modules = {}
local ____moduleCache = {}
local ____originalRequire = require
local function require(file, ...)
    if ____moduleCache[file] then
        return ____moduleCache[file].value
    end
    if ____modules[file] then
        local module = ____modules[file]
        local value = nil
        if (select("#", ...) > 0) then value = module(...) else value = module(file) end
        ____moduleCache[file] = { value = value }
        return value
    else
        if ____originalRequire then
            return ____originalRequire(file)
        else
            error("module '" .. file .. "' not found")
        end
    end
end
____modules = {
["lualib_bundle"] = function(...) 
local function __TS__StringIncludes(self, searchString, position)
    if not position then
        position = 1
    else
        position = position + 1
    end
    local index = string.find(self, searchString, position, true)
    return index ~= nil
end

local __TS__Match = string.match

local function __TS__SourceMapTraceBack(fileName, sourceMap)
    _G.__TS__sourcemap = _G.__TS__sourcemap or ({})
    _G.__TS__sourcemap[fileName] = sourceMap
    if _G.__TS__originalTraceback == nil then
        local originalTraceback = debug.traceback
        _G.__TS__originalTraceback = originalTraceback
        debug.traceback = function(thread, message, level)
            local trace
            if thread == nil and message == nil and level == nil then
                trace = originalTraceback()
            elseif __TS__StringIncludes(_VERSION, "Lua 5.0") then
                trace = originalTraceback((("[Level " .. tostring(level)) .. "] ") .. tostring(message))
            else
                trace = originalTraceback(thread, message, level)
            end
            if type(trace) ~= "string" then
                return trace
            end
            local function replacer(____, file, srcFile, line)
                local fileSourceMap = _G.__TS__sourcemap[file]
                if fileSourceMap ~= nil and fileSourceMap[line] ~= nil then
                    local data = fileSourceMap[line]
                    if type(data) == "number" then
                        return (srcFile .. ":") .. tostring(data)
                    end
                    return (data.file .. ":") .. tostring(data.line)
                end
                return (file .. ":") .. line
            end
            local result = string.gsub(
                trace,
                "(%S+)%.lua:(%d+)",
                function(file, line) return replacer(nil, file .. ".lua", file .. ".ts", line) end
            )
            local function stringReplacer(____, file, line)
                local fileSourceMap = _G.__TS__sourcemap[file]
                if fileSourceMap ~= nil and fileSourceMap[line] ~= nil then
                    local chunkName = (__TS__Match(file, "%[string \"([^\"]+)\"%]"))
                    local sourceName = string.gsub(chunkName, ".lua$", ".ts")
                    local data = fileSourceMap[line]
                    if type(data) == "number" then
                        return (sourceName .. ":") .. tostring(data)
                    end
                    return (data.file .. ":") .. tostring(data.line)
                end
                return (file .. ":") .. line
            end
            result = string.gsub(
                result,
                "(%[string \"[^\"]+\"%]):(%d+)",
                function(file, line) return stringReplacer(nil, file, line) end
            )
            return result
        end
    end
end

local function __TS__ArrayFilter(self, callbackfn, thisArg)
    local result = {}
    local len = 0
    for i = 1, #self do
        if callbackfn(thisArg, self[i], i - 1, self) then
            len = len + 1
            result[len] = self[i]
        end
    end
    return result
end

local function __TS__ArrayIsArray(value)
    return type(value) == "table" and (value[1] ~= nil or next(value) == nil)
end

local function __TS__ArrayFlatMap(self, callback, thisArg)
    local result = {}
    local len = 0
    for i = 1, #self do
        local value = callback(thisArg, self[i], i - 1, self)
        if __TS__ArrayIsArray(value) then
            for j = 1, #value do
                len = len + 1
                result[len] = value[j]
            end
        else
            len = len + 1
            result[len] = value
        end
    end
    return result
end

local function __TS__ArrayFind(self, predicate, thisArg)
    for i = 1, #self do
        local elem = self[i]
        if predicate(thisArg, elem, i - 1, self) then
            return elem
        end
    end
    return nil
end

local function __TS__Class(self)
    local c = {prototype = {}}
    c.prototype.__index = c.prototype
    c.prototype.constructor = c
    return c
end

local function __TS__New(target, ...)
    local instance = setmetatable({}, target.prototype)
    instance:____constructor(...)
    return instance
end

local function __TS__ArrayForEach(self, callbackFn, thisArg)
    for i = 1, #self do
        callbackFn(thisArg, self[i], i - 1, self)
    end
end

local function __TS__ArrayMap(self, callbackfn, thisArg)
    local result = {}
    for i = 1, #self do
        result[i] = callbackfn(thisArg, self[i], i - 1, self)
    end
    return result
end

local function __TS__CountVarargs(...)
    return select("#", ...)
end

local function __TS__SparseArrayNew(...)
    local sparseArray = {...}
    sparseArray.sparseLength = __TS__CountVarargs(...)
    return sparseArray
end

local function __TS__SparseArrayPush(sparseArray, ...)
    local args = {...}
    local argsLen = __TS__CountVarargs(...)
    local listLen = sparseArray.sparseLength
    for i = 1, argsLen do
        sparseArray[listLen + i] = args[i]
    end
    sparseArray.sparseLength = listLen + argsLen
end

local function __TS__SparseArraySpread(sparseArray)
    local _unpack = unpack or table.unpack
    return _unpack(sparseArray, 1, sparseArray.sparseLength)
end

local function __TS__ArrayFindIndex(self, callbackFn, thisArg)
    for i = 1, #self do
        if callbackFn(thisArg, self[i], i - 1, self) then
            return i - 1
        end
    end
    return -1
end

local function __TS__ArraySplice(self, ...)
    local args = {...}
    local len = #self
    local actualArgumentCount = __TS__CountVarargs(...)
    local start = args[1]
    local deleteCount = args[2]
    if start < 0 then
        start = len + start
        if start < 0 then
            start = 0
        end
    elseif start > len then
        start = len
    end
    local itemCount = actualArgumentCount - 2
    if itemCount < 0 then
        itemCount = 0
    end
    local actualDeleteCount
    if actualArgumentCount == 0 then
        actualDeleteCount = 0
    elseif actualArgumentCount == 1 then
        actualDeleteCount = len - start
    else
        actualDeleteCount = deleteCount or 0
        if actualDeleteCount < 0 then
            actualDeleteCount = 0
        end
        if actualDeleteCount > len - start then
            actualDeleteCount = len - start
        end
    end
    local out = {}
    for k = 1, actualDeleteCount do
        local from = start + k
        if self[from] ~= nil then
            out[k] = self[from]
        end
    end
    if itemCount < actualDeleteCount then
        for k = start + 1, len - actualDeleteCount do
            local from = k + actualDeleteCount
            local to = k + itemCount
            if self[from] then
                self[to] = self[from]
            else
                self[to] = nil
            end
        end
        for k = len - actualDeleteCount + itemCount + 1, len do
            self[k] = nil
        end
    elseif itemCount > actualDeleteCount then
        for k = len - actualDeleteCount, start + 1, -1 do
            local from = k + actualDeleteCount
            local to = k + itemCount
            if self[from] then
                self[to] = self[from]
            else
                self[to] = nil
            end
        end
    end
    local j = start + 1
    for i = 3, actualArgumentCount do
        self[j] = args[i]
        j = j + 1
    end
    for k = #self, len - actualDeleteCount + itemCount + 1, -1 do
        self[k] = nil
    end
    return out
end

return {
  __TS__SourceMapTraceBack = __TS__SourceMapTraceBack,
  __TS__ArrayFilter = __TS__ArrayFilter,
  __TS__ArrayFlatMap = __TS__ArrayFlatMap,
  __TS__ArrayFind = __TS__ArrayFind,
  __TS__Class = __TS__Class,
  __TS__New = __TS__New,
  __TS__ArrayForEach = __TS__ArrayForEach,
  __TS__ArrayMap = __TS__ArrayMap,
  __TS__SparseArrayNew = __TS__SparseArrayNew,
  __TS__SparseArrayPush = __TS__SparseArrayPush,
  __TS__SparseArraySpread = __TS__SparseArraySpread,
  __TS__ArrayFindIndex = __TS__ArrayFindIndex,
  __TS__ArraySplice = __TS__ArraySplice
}
 end,
["src.utils"] = function(...) 
local ____lualib = require("lualib_bundle")
local __TS__SourceMapTraceBack = ____lualib.__TS__SourceMapTraceBack
local ____exports = {}
local getLogLevelString
function getLogLevelString(self, level)
    repeat
        local ____switch5 = level
        local ____cond5 = ____switch5 == 0
        if ____cond5 then
            return " - DEBUG"
        end
        ____cond5 = ____cond5 or ____switch5 == 1
        if ____cond5 then
            return " - INFO"
        end
        ____cond5 = ____cond5 or ____switch5 == 2
        if ____cond5 then
            return " - WARN"
        end
        ____cond5 = ____cond5 or ____switch5 == 3
        if ____cond5 then
            return " - ERROR"
        end
        do
            return ""
        end
    until true
end
function ____exports.Popup(self, message, level)
    if level == nil then
        level = 10
    end
    MessageBox({
        title = "AutoZoom" .. getLogLevelString(nil, level),
        message = type(message) == "string" and message or table.concat(message, "\n"),
        commands = {{value = 1, name = "OK"}}
    })
end
local logLevel = 1
function ____exports.SetLogLevel(self, levelString)
    repeat
        local ____switch3 = levelString
        local ____cond3 = ____switch3 == "DEBUG"
        if ____cond3 then
            logLevel = 0
            break
        end
        ____cond3 = ____cond3 or ____switch3 == "INFO"
        if ____cond3 then
            logLevel = 1
            break
        end
        ____cond3 = ____cond3 or ____switch3 == "WARN"
        if ____cond3 then
            logLevel = 2
            break
        end
        ____cond3 = ____cond3 or ____switch3 == "ERROR"
        if ____cond3 then
            logLevel = 3
            break
        end
        do
            logLevel = 1
            break
        end
    until true
    ____exports.Popup(
        nil,
        "Log level set to " .. getLogLevelString(nil, logLevel)
    )
end
function ____exports.PrintLogLevel(self)
    ____exports.Popup(
        nil,
        "Log level is " .. getLogLevelString(nil, logLevel)
    )
end
function ____exports.PrintEcho(self, message, level)
    if level >= logLevel then
        Printf((("[AZ" .. getLogLevelString(nil, level)) .. "] ") .. message)
    end
end
function ____exports.remap(self, value, low1, high1, low2, high2)
    return low2 + (high2 - low2) * (value - low1) / (high1 - low1)
end
function ____exports.ClearAll(self)
    Cmd("ClearAll")
end
return ____exports
 end,
["src.calculate-zoom-iris"] = function(...) 
local ____lualib = require("lualib_bundle")
local __TS__SourceMapTraceBack = ____lualib.__TS__SourceMapTraceBack
local ____exports = {}
local function getFaderValue(self, min, max, value)
    return math.floor((value - min) / (max - min) * 100 + 0.5)
end
local function getBeamSizeAtTarget(self, zoom, distance)
    local angle = zoom * math.pi / 180
    return 2 * distance * math.tan(angle / 2)
end
function ____exports.calculateZoomIrisFaderValues(self, fixturePosition, targetPosition, opticalParameters, targetBeamDiameter)
    local distance = fixturePosition:distance(targetPosition)
    local angle = math.atan(targetBeamDiameter / 2 / distance) * 2 * 180 / math.pi
    if angle >= opticalParameters.zoom.min and angle <= opticalParameters.zoom.max then
        return {
            zoom = getFaderValue(nil, opticalParameters.zoom.min, opticalParameters.zoom.max, angle),
            iris = 100
        }
    elseif angle < opticalParameters.zoom.min then
        local zoomBeamSize = getBeamSizeAtTarget(nil, opticalParameters.zoom.min, distance)
        if opticalParameters.iris.min == opticalParameters.iris.max then
            return {zoom = 0, iris = -1}
        end
        local irisLevel = getFaderValue(nil, opticalParameters.iris.min, opticalParameters.iris.max, targetBeamDiameter / zoomBeamSize)
        return {zoom = 0, iris = irisLevel}
    else
        return {zoom = 100, iris = 100}
    end
end
return ____exports
 end,
["src.handle-execs"] = function(...) 
local ____lualib = require("lualib_bundle")
local __TS__ArrayFilter = ____lualib.__TS__ArrayFilter
local __TS__ArrayFlatMap = ____lualib.__TS__ArrayFlatMap
local __TS__ArrayFind = ____lualib.__TS__ArrayFind
local __TS__SourceMapTraceBack = ____lualib.__TS__SourceMapTraceBack
local ____exports = {}
local ____utils = require("src.utils")
local ClearAll = ____utils.ClearAll
local PrintEcho = ____utils.PrintEcho
local Popup = ____utils.Popup
function ____exports.getSeqHandleFromName(self, seqName)
    local seq = __TS__ArrayFind(
        __TS__ArrayFlatMap(
            __TS__ArrayFlatMap(
                ShowData().DataPools:Children(),
                function(____, datapool) return __TS__ArrayFilter(
                    datapool:Children(),
                    function(____, child) return child:GetClass() == "Sequences" end
                ) end
            ),
            function(____, sequences) return sequences:Children() end
        ),
        function(____, seq) return seq.name == seqName end
    )
    if seq then
        return seq
    end
    return nil
end
function ____exports.moveFaderGMA3(self, faderName, level)
    PrintEcho(
        nil,
        (("Moving fader " .. faderName) .. " to ") .. tostring(level),
        0
    )
    local seq = ____exports.getSeqHandleFromName(nil, faderName)
    if seq == nil then
        PrintEcho(nil, ("Sequence " .. faderName) .. " not found", 3)
        return
    end
    seq:SetFader({value = level, token = "FaderTemp"})
end
function ____exports.getFixtureSizeFaderValue(self, fid)
    local seqName = "AZ_SIZE_" .. tostring(fid)
    local seq = ____exports.getSeqHandleFromName(nil, seqName)
    local ____opt_result_2
    if seq ~= nil then
        ____opt_result_2 = seq:GetFader({token = "FaderMaster"})
    end
    return ____opt_result_2
end
function ____exports.getGlobalSizeFaderValue(self)
    local seqName = "AZ_SIZE"
    local seq = ____exports.getSeqHandleFromName(nil, seqName)
    local ____opt_result_5
    if seq ~= nil then
        ____opt_result_5 = seq:GetFader({token = "FaderMaster"})
    end
    return ____opt_result_5
end
local function storeTrackingCue(self, enabledFixture)
    PrintEcho(nil, "Not implemented yet", 3)
end
local function createAZDatapool(self)
    do
        local i = 0
        while i < ShowData().DataPools:Count() do
            local datapool = ShowData().DataPools[i + 1]
            if datapool.name == "AZ" then
                return
            end
            i = i + 1
        end
    end
    Cmd("Store DataPool 'AZ'")
end
local function createTrackingSequence(self, fixtureid)
    PrintEcho(nil, "Not implemented yet", 3)
end
local function createZoomIrisSequence(self, fixture, useAZDatapool)
    if useAZDatapool then
        createAZDatapool(nil)
    end
    ClearAll(nil)
    Cmd("Fixture " .. tostring(fixture.fid))
    Cmd("Attribute Zoom At 100")
    if useAZDatapool then
        CmdIndirectWait(("Store Datapool 'AZ' Sequence 'AZ_ZOOM_" .. tostring(fixture.fid)) .. "' /o /nc")
    else
        CmdIndirectWait(("Store Sequence 'AZ_ZOOM_" .. tostring(fixture.fid)) .. "' /o /nc")
    end
    ClearAll(nil)
    if fixture.fixtureType.opticalParameters.iris.max ~= fixture.fixtureType.opticalParameters.iris.min then
        Cmd("Fixture " .. tostring(fixture.fid))
        Cmd("Attribute Iris At 100")
        if useAZDatapool then
            CmdIndirectWait(("Store Datapool 'AZ' Sequence 'AZ_IRIS_" .. tostring(fixture.fid)) .. "' /o /nc")
        else
            CmdIndirectWait(("Store Sequence 'AZ_IRIS_" .. tostring(fixture.fid)) .. "' /o /nc")
        end
    end
end
local function createSizeSequence(self, fixture, useAZDatapool)
    if useAZDatapool then
        createAZDatapool(nil)
    end
    ClearAll(nil)
    if useAZDatapool then
        CmdIndirectWait(("Store Datapool 'AZ' Sequence 'AZ_SIZE_" .. tostring(fixture.fid)) .. "' /o /nc")
        CmdIndirectWait("Store Datapool 'AZ' Sequence 'AZ_SIZE' /o /nc")
    else
        CmdIndirectWait(("Store Sequence 'AZ_SIZE_" .. tostring(fixture.fid)) .. "' /o /nc")
        CmdIndirectWait("Store Sequence 'AZ_SIZE' /o /nc")
    end
end
function ____exports.createSequencesForFixture(self, enabledFixture, useAZDatapool)
    ClearAll(nil)
    createZoomIrisSequence(nil, enabledFixture.fixture, useAZDatapool)
    createSizeSequence(nil, enabledFixture.fixture, useAZDatapool)
    if useAZDatapool then
        Popup(
            nil,
            ("Sequences created for fixture " .. tostring(enabledFixture.fixture.fid)) .. " in AZ Datapool"
        )
    else
        Popup(
            nil,
            "Sequences created for fixture " .. tostring(enabledFixture.fixture.fid)
        )
    end
end
return ____exports
 end,
["src.types"] = function(...) 
local ____lualib = require("lualib_bundle")
local __TS__Class = ____lualib.__TS__Class
local __TS__New = ____lualib.__TS__New
local __TS__ArrayFlatMap = ____lualib.__TS__ArrayFlatMap
local __TS__ArrayFind = ____lualib.__TS__ArrayFind
local __TS__SourceMapTraceBack = ____lualib.__TS__SourceMapTraceBack
local ____exports = {}
local ____calculate_2Dzoom_2Diris = require("src.calculate-zoom-iris")
local calculateZoomIrisFaderValues = ____calculate_2Dzoom_2Diris.calculateZoomIrisFaderValues
local ____handle_2Dexecs = require("src.handle-execs")
local getFixtureSizeFaderValue = ____handle_2Dexecs.getFixtureSizeFaderValue
local getGlobalSizeFaderValue = ____handle_2Dexecs.getGlobalSizeFaderValue
local moveFaderGMA3 = ____handle_2Dexecs.moveFaderGMA3
local ____utils = require("src.utils")
local remap = ____utils.remap
____exports.Vector3 = __TS__Class()
local Vector3 = ____exports.Vector3
Vector3.name = "Vector3"
function Vector3.prototype.____constructor(self, x, y, z)
    self.x = x
    self.y = y
    self.z = z
end
function Vector3.getDistance(self, a, b)
    return math.sqrt((a.x - b.x) ^ 2 + (a.y - b.y) ^ 2 + (a.z - b.z) ^ 2)
end
function Vector3.prototype.distance(self, a)
    return ____exports.Vector3:getDistance(self, a)
end
____exports.AZ_FixtureType = __TS__Class()
local AZ_FixtureType = ____exports.AZ_FixtureType
AZ_FixtureType.name = "AZ_FixtureType"
function AZ_FixtureType.prototype.____constructor(self, id, name, opticalParameters, mode)
    self.id = id
    self.name = name
    self.opticalParameters = opticalParameters
    self.mode = mode
end
function AZ_FixtureType.prototype.describe(self)
    return {
        ((("Fixture Type: " .. self.name) .. " is in ") .. self.mode) .. " mode",
        (("Optical Parameters: Zoom min: " .. tostring(self.opticalParameters.zoom.min)) .. " max: ") .. tostring(self.opticalParameters.zoom.max),
        (("Optical Parameters: Iris min: " .. tostring(self.opticalParameters.iris.min)) .. " max: ") .. tostring(self.opticalParameters.iris.max)
    }
end
____exports.AZ_Fixture = __TS__Class()
local AZ_Fixture = ____exports.AZ_Fixture
AZ_Fixture.name = "AZ_Fixture"
function AZ_Fixture.prototype.____constructor(self, fid, name, fixtureType, position, handle)
    self.fid = fid
    self.name = name
    self.fixtureType = fixtureType
    self.position = position
    self.handle = handle
    self.lastZoom = -1
    self.lastIris = -1
end
function AZ_Fixture.prototype.describe(self)
    return {
        ((((((((("Fixture: " .. tostring(self.fid)) .. "  -  ") .. self.name) .. " at position (") .. tostring(self.position.x)) .. ", ") .. tostring(self.position.y)) .. ", ") .. tostring(self.position.z)) .. ")",
        table.unpack(self.fixtureType:describe())
    }
end
function AZ_Fixture.prototype.updateTo(self, targetZI)
    if math.floor(targetZI.zoom + 0.5) ~= self.lastZoom then
        moveFaderGMA3(
            nil,
            self:getZoomFader(),
            math.floor(targetZI.zoom + 0.5)
        )
        self.lastZoom = math.floor(targetZI.zoom + 0.5)
    end
    if self:hasIris() and math.floor(targetZI.iris + 0.5) ~= self.lastIris and targetZI.iris ~= -1 then
        moveFaderGMA3(
            nil,
            self:getIrisFader(),
            math.floor(targetZI.iris + 0.5)
        )
        self.lastIris = math.floor(targetZI.iris + 0.5)
    end
end
function AZ_Fixture.prototype.hasIris(self)
    return self.fixtureType.opticalParameters.iris.min ~= self.fixtureType.opticalParameters.iris.max
end
function AZ_Fixture.prototype.invalidate(self)
    self.lastZoom = -1
    self.lastIris = -1
end
function AZ_Fixture.prototype.getZoomFader(self)
    return "AZ_ZOOM_" .. tostring(self.fid)
end
function AZ_Fixture.prototype.getIrisFader(self)
    return "AZ_IRIS_" .. tostring(self.fid)
end
____exports.AZ_Marker = __TS__Class()
local AZ_Marker = ____exports.AZ_Marker
AZ_Marker.name = "AZ_Marker"
function AZ_Marker.prototype.____constructor(self, fid, cid, name, handle)
    self.tracked = false
    self.fid = fid
    self.cid = cid
    self.name = name
    self.handle = handle
    self.position = __TS__New(____exports.Vector3, 0, 0, 0)
end
function AZ_Marker.prototype.describe(self)
    return (("Marker: " .. tostring(self.fid)) .. " - ") .. self.name
end
function AZ_Marker.prototype.update(self)
    local tracker = __TS__ArrayFind(
        __TS__ArrayFlatMap(
            ShowData().PSNProtocol:Children(),
            function(____, trackingSystem) return trackingSystem:Children() end
        ),
        function(____, tracker) return tracker.MARKERID == self.cid end
    )
    self.tracked = tracker ~= nil
    if not tracker then
        return false
    end
    self.position.x = tracker.POSITIONX
    self.position.y = tracker.POSITIONY
    self.position.z = tracker.POSITIONZ
    return true
end
____exports.AZ_EnabledFixture = __TS__Class()
local AZ_EnabledFixture = ____exports.AZ_EnabledFixture
AZ_EnabledFixture.name = "AZ_EnabledFixture"
function AZ_EnabledFixture.prototype.____constructor(self, fixture, marker, beamSize)
    self.fixture = fixture
    self.marker = marker
    self.beamSize = beamSize
end
function AZ_EnabledFixture.prototype.Update(self, sizeFaderConfig)
    if not self.marker.tracked then
        return
    end
    local sizeFaderValue = nil
    if sizeFaderConfig.globalEnabled == true then
        sizeFaderValue = getGlobalSizeFaderValue(nil)
    elseif sizeFaderConfig.fixturesEnabled[self.fixture.fid] == true then
        sizeFaderValue = getFixtureSizeFaderValue(nil, self.fixture.fid)
    end
    local targettedBeamSize = sizeFaderValue == nil and self.beamSize or remap(
        nil,
        sizeFaderValue,
        0,
        100,
        sizeFaderConfig.rangeMin,
        sizeFaderConfig.rangeMax
    )
    local targetZoomIris = calculateZoomIrisFaderValues(
        nil,
        self.fixture.position,
        self.marker.position,
        self.fixture.fixtureType.opticalParameters,
        targettedBeamSize
    )
    self.fixture:updateTo(targetZoomIris)
end
function AZ_EnabledFixture.prototype.forceUpdate(self, sizeFaderConfig)
    self.fixture:invalidate()
    self:Update(sizeFaderConfig)
end
return ____exports
 end,
["src.load-patch"] = function(...) 
local ____lualib = require("lualib_bundle")
local __TS__ArrayForEach = ____lualib.__TS__ArrayForEach
local __TS__New = ____lualib.__TS__New
local __TS__SourceMapTraceBack = ____lualib.__TS__SourceMapTraceBack
local ____exports = {}
local ____types = require("src.types")
local AZ_Fixture = ____types.AZ_Fixture
local AZ_FixtureType = ____types.AZ_FixtureType
local AZ_Marker = ____types.AZ_Marker
local Vector3 = ____types.Vector3
local ____utils = require("src.utils")
local PrintEcho = ____utils.PrintEcho
local Popup = ____utils.Popup
function ____exports.getFTZoom(self, fixtureType)
    local min = 0
    local max = 0
    __TS__ArrayForEach(
        fixtureType.DMXChannels,
        function(____, channel)
            if #channel:Children() == 0 then
                return
            end
            if channel:Children()[1].attribute == "Zoom" then
                min = channel:Children()[1]:Children()[1].physicalFrom
                max = channel:Children()[1]:Children()[1].physicalTo
            end
        end
    )
    return {
        min = math.min(min, max),
        max = math.max(min, max)
    }
end
function ____exports.getFTIris(self, fixtureType)
    local min = 0
    local max = 0
    __TS__ArrayForEach(
        fixtureType.DMXChannels,
        function(____, channel)
            if #channel:Children() == 0 then
                return
            end
            if channel:Children()[1].attribute == "Iris" then
                min = channel:Children()[1]:Children()[1].physicalFrom
                max = channel:Children()[1]:Children()[1].physicalTo
            end
        end
    )
    if min == nil then
        min = 0
    end
    if max == nil then
        max = 0
    end
    return {
        min = math.min(min, max),
        max = math.max(min, max)
    }
end
function ____exports.getOpticalParameters(self, fixtureType)
    local zoom = ____exports.getFTZoom(nil, fixtureType)
    local iris = ____exports.getFTIris(nil, fixtureType)
    if zoom.min == nil or zoom.max == nil or iris.min == nil or iris.max == nil then
        return {zoom = {min = 0, max = 0}, iris = {min = 0, max = 0}}
    end
    return {
        zoom = ____exports.getFTZoom(nil, fixtureType),
        iris = ____exports.getFTIris(nil, fixtureType)
    }
end
function ____exports.loadFixtureTypes(self)
    local returnFTs = {}
    local fixtureTypes = Patch().FixtureTypes:Children()
    __TS__ArrayForEach(
        fixtureTypes,
        function(____, fixtureType)
            local modes = fixtureType.DMXModes
            if modes == nil then
                return nil
            end
            __TS__ArrayForEach(
                modes,
                function(____, mode)
                    if mode.XYZ == true then
                        local opticalParameters = ____exports.getOpticalParameters(nil, mode)
                        local id = fixtureType.id
                        local name = fixtureType.Name
                        local ft = __TS__New(
                            AZ_FixtureType,
                            id,
                            name,
                            opticalParameters,
                            mode.Name
                        )
                        returnFTs[#returnFTs + 1] = ft
                    end
                end
            )
        end
    )
    return returnFTs
end
function ____exports.getFixturePosition(self, fixture)
    return __TS__New(Vector3, fixture.POSX, fixture.POSY, fixture.POSZ)
end
local function searchXYZFixtures(self, fixtureOrGroup, return_fixtures, return_markers, XYZFixtureTypes)
    if fixtureOrGroup.IDType == "MArker" then
        local marker = __TS__New(
            AZ_Marker,
            fixtureOrGroup.fid,
            fixtureOrGroup.cid,
            fixtureOrGroup.name,
            fixtureOrGroup
        )
        return_markers[#return_markers + 1] = marker
        return
    end
    if fixtureOrGroup.FixtureType == nil then
        return
    end
    local fixtureType = fixtureOrGroup.FixtureType
    local fixtureTypeName = fixtureType.Name
    if fixtureTypeName == "Grouping" then
        local fixtures = fixtureOrGroup:Children()
        do
            local i = 0
            while i < fixtureOrGroup.count do
                searchXYZFixtures(
                    nil,
                    fixtures[i + 1],
                    return_fixtures,
                    return_markers,
                    XYZFixtureTypes
                )
                i = i + 1
            end
        end
    else
        local az_ft = nil
        __TS__ArrayForEach(
            XYZFixtureTypes,
            function(____, fixtureTypeXYZ)
                if not (fixtureTypeXYZ.name == fixtureTypeName) then
                    return
                else
                    az_ft = fixtureTypeXYZ
                end
            end
        )
        if az_ft == nil then
            return
        end
        if fixtureOrGroup.fid == "None" then
            return
        end
        local fixture = __TS__New(
            AZ_Fixture,
            fixtureOrGroup.fid,
            fixtureOrGroup.Name,
            az_ft,
            ____exports.getFixturePosition(nil, fixtureOrGroup),
            fixtureOrGroup
        )
        if az_ft ~= nil and fixture ~= nil then
            return_fixtures[#return_fixtures + 1] = fixture
        end
    end
end
function ____exports.fetchFixtures(self, XYZFixtureTypes)
    local return_fixtures = {}
    local return_markers = {}
    local stages = Patch().Stages
    if stages.count == 0 then
        Popup(nil, "No stages found", 3)
        return {fixtures = {}, markers = {}}
    end
    PrintEcho(
        nil,
        "Number of stages : " .. tostring(stages.count),
        0
    )
    do
        local i = 0
        while i < stages.count do
            PrintEcho(
                nil,
                "Stage number : " .. tostring(i + 1),
                0
            )
            local stage = stages:Children()[i + 1]
            local fixtures = stage.Fixtures:Children()
            do
                local j = 1
                while j <= stage.Fixtures.count do
                    local fixture = fixtures[j]
                    searchXYZFixtures(
                        nil,
                        fixture,
                        return_fixtures,
                        return_markers,
                        XYZFixtureTypes
                    )
                    j = j + 1
                end
            end
            i = i + 1
        end
    end
    return {fixtures = return_fixtures, markers = return_markers}
end
return ____exports
 end,
["src.create-macros"] = function(...) 
local ____lualib = require("lualib_bundle")
local __TS__SourceMapTraceBack = ____lualib.__TS__SourceMapTraceBack
local ____exports = {}
function ____exports.createMacro(self, name, number, lines)
    CmdIndirect(((("Store Macro " .. tostring(number)) .. " '") .. name) .. "' /o /nc")
    do
        local i = 0
        while i < #lines do
            CmdIndirect(((("Store Macro " .. tostring(number)) .. ".") .. tostring(i + 1)) .. " /o /nc")
            CmdIndirect(((((("Set Macro " .. tostring(number)) .. ".") .. tostring(i + 1)) .. " Property 'Command' '") .. lines[i + 1]) .. "'")
            i = i + 1
        end
    end
end
return ____exports
 end,
["src.macros"] = function(...) 
local ____lualib = require("lualib_bundle")
local __TS__SourceMapTraceBack = ____lualib.__TS__SourceMapTraceBack
local ____exports = {}
____exports.IMPORTED_MACROS = {
    {name = "AZ ENABLE", commands = {"Lua \"AZ:Enable()\""}},
    {name = "AZ DISABLE", commands = {"Lua \"AZ:Disable()\""}},
    {name = "AZ ShowEnabled", commands = {"Lua \"AZ:ShowEnabled()\""}},
    {name = "AZ RESCAN PATCH", commands = {"Lua \"AZ:ScanPatch()\""}},
    {name = "AZ PRINT PATCH", commands = {"Lua \"AZ:PrintCurrentPatch()\""}},
    {name = "AZ GET FIXTURE STATUS", commands = {"Lua \"AZ:GetFixturesStatus()\""}},
    {name = "AZ DISABLE ALL FIXTURES", commands = {"Lua \"AZ:DisableAllFixtures()\""}},
    {name = "AZ ENABLE GLOBAL SIZE FADER", commands = {"Lua \"AZ:EnableGlobalSizeFader()\""}},
    {name = "AZ DISABLE GLOBAL SIZE FADER", commands = {"Lua \"AZ:DisableGlobalSizeFader()\""}},
    {name = "AZ SET SIZE FADER RANGE", commands = {"Lua \"AZ:SetSizeFaderRange(0,5)\""}},
    {name = "AZ Enable Datapool", commands = {"Lua \"AZ:EnableDatapool()\""}},
    {name = "AZ Disable Datapool", commands = {"Lua \"AZ:DisableDatapool()\""}},
    {name = "AZ Example ENABLE FIXTURE", commands = {"Lua \"AZ:EnableFixture(301,1001,3)\""}},
    {name = "AZ Example DISABLE FIXTURE", commands = {"Lua \"AZ:DisableFixture(301)\""}},
    {name = "AZ Example ENABLE SIZE FADER", commands = {"Lua \"AZ:EnableSizeFader(301)\""}},
    {name = "AZ Example DISABLE SIZE FADER", commands = {"Lua \"AZ:DisableSizeFader(301)\""}},
    {name = "AZ Example CREATE AZ SEQUENCES FOR FIXTURE", commands = {"Lua \"AZ:CreateAZSequences(301)\""}}
}
return ____exports
 end,
["src.autozoom_object"] = function(...) 
local ____lualib = require("lualib_bundle")
local __TS__Class = ____lualib.__TS__Class
local __TS__ArrayForEach = ____lualib.__TS__ArrayForEach
local __TS__ArrayFind = ____lualib.__TS__ArrayFind
local __TS__ArrayFilter = ____lualib.__TS__ArrayFilter
local __TS__ArrayFlatMap = ____lualib.__TS__ArrayFlatMap
local __TS__ArrayMap = ____lualib.__TS__ArrayMap
local __TS__SparseArrayNew = ____lualib.__TS__SparseArrayNew
local __TS__SparseArrayPush = ____lualib.__TS__SparseArrayPush
local __TS__SparseArraySpread = ____lualib.__TS__SparseArraySpread
local __TS__New = ____lualib.__TS__New
local __TS__ArrayFindIndex = ____lualib.__TS__ArrayFindIndex
local __TS__ArraySplice = ____lualib.__TS__ArraySplice
local __TS__SourceMapTraceBack = ____lualib.__TS__SourceMapTraceBack
local ____exports = {}
local ____utils = require("src.utils")
local PrintEcho = ____utils.PrintEcho
local PrintLogLevel = ____utils.PrintLogLevel
local Popup = ____utils.Popup
local SetLogLevel = ____utils.SetLogLevel
local ____load_2Dpatch = require("src.load-patch")
local fetchFixtures = ____load_2Dpatch.fetchFixtures
local loadFixtureTypes = ____load_2Dpatch.loadFixtureTypes
local ____types = require("src.types")
local AZ_EnabledFixture = ____types.AZ_EnabledFixture
local ____handle_2Dexecs = require("src.handle-execs")
local createSequencesForFixture = ____handle_2Dexecs.createSequencesForFixture
local ____create_2Dmacros = require("src.create-macros")
local createMacro = ____create_2Dmacros.createMacro
local ____macros = require("src.macros")
local IMPORTED_MACROS = ____macros.IMPORTED_MACROS
____exports.AZ_Global_Type = __TS__Class()
local AZ_Global_Type = ____exports.AZ_Global_Type
AZ_Global_Type.name = "AZ_Global_Type"
function AZ_Global_Type.prototype.____constructor(self)
    self.sizeFaderConfig = {globalEnabled = false, fixturesEnabled = {}, rangeMin = 0.5, rangeMax = 3}
    self.createSequences = false
    self.refreshRate = 30
    self.initialized = false
    self.useAZDatapool = false
    self.expected_remaining_update = 0
    self.global_call_repeat = 10
    self.loopId = 0
    self.patch_info = {fixtures = {}, markers = {}}
    self.enabledFixtures = {}
    self.enabled = false
    PrintEcho(nil, "AZ created, patch_info", 0)
end
function AZ_Global_Type.prototype.statusMessage(self)
    return self.enabled and "AutoZoom is enabled" or "AutoZoom is disabled"
end
function AZ_Global_Type.prototype.ShowEnabled(self)
    Popup(
        nil,
        self:statusMessage()
    )
end
function AZ_Global_Type.prototype.Enable(self)
    if not self.initialized then
        self:Start()
    end
    self.enabled = true
    __TS__ArrayForEach(
        self.enabledFixtures,
        function(____, enabledFixture) return enabledFixture.fixture:invalidate() end
    )
    self:RegisterUpdateLoop()
    self:ShowEnabled()
end
function AZ_Global_Type.prototype.Disable(self)
    self.enabled = false
    self:ShowEnabled()
end
function AZ_Global_Type.prototype.Toggle(self)
    if self.enabled then
        self:Disable()
    else
        self:Enable()
    end
end
function AZ_Global_Type.prototype.ScanPatch(self)
    Popup(
        nil,
        self:loadPatch()
    )
end
function AZ_Global_Type.prototype.loadPatch(self)
    self.patch_info = {fixtures = {}, markers = {}}
    local fixtureTypes_in_XYZ = loadFixtureTypes(nil)
    local fixture_and_markers = fetchFixtures(nil, fixtureTypes_in_XYZ)
    PrintEcho(nil, "--- Scanned all fixtures that have XYZ", 1)
    self.patch_info = {fixtures = fixture_and_markers.fixtures, markers = fixture_and_markers.markers}
    local removedFixtures = {}
    self.enabledFixtures = __TS__ArrayFilter(
        self.enabledFixtures,
        function(____, enabledFixture)
            local fixture = __TS__ArrayFind(
                self.patch_info.fixtures,
                function(____, fixture) return fixture.fid == enabledFixture.fixture.fid end
            )
            local marker = __TS__ArrayFind(
                self.patch_info.markers,
                function(____, marker) return marker.fid == enabledFixture.marker.fid end
            )
            if not fixture or not marker then
                removedFixtures[#removedFixtures + 1] = enabledFixture.fixture.fid
                return false
            end
            enabledFixture.fixture = fixture
            enabledFixture.marker = marker
            return true
        end
    )
    local message = ((("Patch fetched - found " .. tostring(#self.patch_info.fixtures)) .. " fixtures and ") .. tostring(#self.patch_info.markers)) .. " markers."
    if #removedFixtures == 0 then
        return message
    end
    return (message .. "\nDisabled fixtures no longer in the patch : ") .. table.concat(removedFixtures, ", ")
end
function AZ_Global_Type.prototype.PrintCurrentPatch(self)
    if #self.patch_info.fixtures == 0 then
        return Popup(nil, "No fixtures in patch", 3)
    end
    if #self.patch_info.markers == 0 then
        return Popup(nil, "No markers in patch", 3)
    end
    local ____Popup_1 = Popup
    local ____array_0 = __TS__SparseArrayNew(
        "Current Patch",
        "Fixtures",
        table.unpack(__TS__ArrayFlatMap(
            self.patch_info.fixtures,
            function(____, fixture) return fixture:describe() end
        ))
    )
    __TS__SparseArrayPush(
        ____array_0,
        "Markers",
        table.unpack(__TS__ArrayMap(
            self.patch_info.markers,
            function(____, marker) return marker:describe() end
        ))
    )
    ____Popup_1(
        nil,
        {__TS__SparseArraySpread(____array_0)}
    )
end
function AZ_Global_Type.prototype.GetFixturesStatus(self)
    if #self.enabledFixtures == 0 then
        return Popup(nil, "No fixtures enabled")
    end
    Popup(
        nil,
        __TS__ArrayMap(
            self.enabledFixtures,
            function(____, enabledFixture) return (((("Fixture " .. tostring(enabledFixture.fixture.fid)) .. " -> ") .. tostring(enabledFixture.marker.fid)) .. " | beamsize : ") .. tostring(enabledFixture.beamSize) end
        )
    )
end
function AZ_Global_Type.prototype.EnableFixture(self, fixtureid, markerid, beamSize)
    if #self.patch_info.fixtures == 0 then
        return Popup(nil, "No fixtures with XYZ mode active in patch", 3)
    end
    if #self.patch_info.markers == 0 then
        return Popup(nil, "No markers in patch", 3)
    end
    local fixture = __TS__ArrayFind(
        self.patch_info.fixtures,
        function(____, fixture) return fixture.fid == fixtureid end
    )
    if not fixture then
        return Popup(
            nil,
            ("No fixture with id " .. tostring(fixtureid)) .. " found",
            3
        )
    end
    local marker = __TS__ArrayFind(
        self.patch_info.markers,
        function(____, marker) return marker.fid == markerid end
    )
    if not marker then
        return Popup(
            nil,
            ("No marker with id " .. tostring(markerid)) .. " found",
            3
        )
    end
    local enabledFixture = __TS__ArrayFind(
        self.enabledFixtures,
        function(____, enabledFixture) return enabledFixture.fixture.fid == fixtureid end
    )
    local messages = {}
    if enabledFixture then
        enabledFixture.marker = marker
        enabledFixture.beamSize = beamSize
        messages[#messages + 1] = (((("Updated fixture " .. tostring(fixtureid)) .. " - Marker : ") .. tostring(marker.fid)) .. " | Beam size : ") .. tostring(beamSize)
    else
        enabledFixture = __TS__New(AZ_EnabledFixture, fixture, marker, beamSize)
        local ____self_enabledFixtures_2 = self.enabledFixtures
        ____self_enabledFixtures_2[#____self_enabledFixtures_2 + 1] = enabledFixture
        messages[#messages + 1] = (((("Enabled fixture " .. tostring(fixtureid)) .. " - Marker : ") .. tostring(marker.fid)) .. " | Beam size : ") .. tostring(beamSize)
    end
    enabledFixture.fixture:invalidate()
    if not marker:update() then
        messages[#messages + 1] = ((("( - WARNING - Marker ID : " .. tostring(marker.fid)) .. " with Channel ID: ") .. tostring(marker.cid)) .. ") is not assigned to any PSN tracker in, the zoom will not follow it. Set the Channel ID of the Marker in the PSN configuration."
    elseif self.enabled then
        enabledFixture:forceUpdate(self.sizeFaderConfig)
    end
    Popup(nil, messages)
end
function AZ_Global_Type.prototype.DisableFixture(self, fixtureid)
    local index = __TS__ArrayFindIndex(
        self.enabledFixtures,
        function(____, enabledFixture) return enabledFixture.fixture.fid == fixtureid end
    )
    if index == -1 then
        return Popup(
            nil,
            ("Fixture " .. tostring(fixtureid)) .. " was not enabled",
            3
        )
    end
    __TS__ArraySplice(self.enabledFixtures, index, 1)
    Popup(
        nil,
        "Disabled fixture " .. tostring(fixtureid)
    )
end
function AZ_Global_Type.prototype.LogLevel(self, levelString)
    SetLogLevel(nil, levelString)
end
function AZ_Global_Type.prototype.GetLogLevel(self)
    PrintLogLevel(nil)
end
function AZ_Global_Type.prototype.DisableAllFixtures(self)
    self.enabledFixtures = {}
    Popup(nil, "Disabled all fixtures")
end
function AZ_Global_Type.prototype.UpdateMarkers(self)
    for ____, marker in ipairs(self.patch_info.markers) do
        marker:update()
    end
end
function AZ_Global_Type.prototype.UpdateFixtures(self)
    for ____, enabledFixture in ipairs(self.enabledFixtures) do
        enabledFixture:Update(self.sizeFaderConfig)
    end
end
function AZ_Global_Type.prototype.UpdateLoop(self, loopId)
    if loopId ~= self.loopId then
        return
    end
    self.expected_remaining_update = self.expected_remaining_update - 1
    if not self.enabled then
        self.expected_remaining_update = 0
        self.global_call_repeat = 0
        return
    end
    self:UpdateMarkers()
    self:UpdateFixtures()
    if self.expected_remaining_update == 0 then
        self:RegisterUpdateLoop()
    end
end
function AZ_Global_Type.prototype.SetRefreshRate(self, rate)
    self.refreshRate = rate
    Popup(
        nil,
        ("Set refresh rate to " .. tostring(rate)) .. " updates/second"
    )
end
function AZ_Global_Type.prototype.RegisterUpdateLoop(self)
    if not self.enabled then
        PrintEcho(nil, "Autozoom is disabled, failed to start loop", 3)
        return
    end
    local updatePeriod = 1 / self.refreshRate
    self.global_call_repeat = self.refreshRate * 10
    self.expected_remaining_update = self.global_call_repeat
    self.loopId = self.loopId + 1
    local loopId = self.loopId
    Timer(
        function()
            self:UpdateLoop(loopId)
        end,
        updatePeriod,
        self.expected_remaining_update
    )
end
function AZ_Global_Type.prototype.Init(self)
    if not self.initialized then
        self:Start()
    end
end
function AZ_Global_Type.prototype.Start(self)
    local patchMessage = self:loadPatch()
    self.initialized = true
    Popup(
        nil,
        {
            "Plugin GRANDMA3 AUTOZOOM launched",
            "Plugin version : 1.1.2",
            "Plugin author : Naostage 2025",
            "",
            patchMessage,
            self:statusMessage()
        }
    )
end
function AZ_Global_Type.prototype.Cleanup(self)
    self.expected_remaining_update = 0
    self.global_call_repeat = 0
    self.enabled = false
    PrintEcho(nil, "Plugin GRANDMA3 AUTOZOOM stopped", 1)
end
function AZ_Global_Type.prototype.EnableSizeFader(self, fid)
    for ____, fixture in ipairs(self.patch_info.fixtures) do
        if fixture.fid == fid then
            self.sizeFaderConfig.fixturesEnabled[fid] = true
            Popup(
                nil,
                "Enabled size fader for fixture " .. tostring(fid)
            )
            return
        end
    end
    Popup(
        nil,
        ("Fixture " .. tostring(fid)) .. " not found in the patch",
        3
    )
end
function AZ_Global_Type.prototype.DisableSizeFader(self, fid)
    for ____, fixture in ipairs(self.patch_info.fixtures) do
        if fixture.fid == fid then
            self.sizeFaderConfig.fixturesEnabled[fid] = false
            Popup(
                nil,
                "Disabled size fader for fixture " .. tostring(fid)
            )
            return
        end
    end
    Popup(
        nil,
        ("Fixture " .. tostring(fid)) .. " not found in the patch",
        3
    )
end
function AZ_Global_Type.prototype.EnableGlobalSizeFader(self)
    self.sizeFaderConfig.globalEnabled = true
    Popup(nil, "Enabled global size fader")
end
function AZ_Global_Type.prototype.DisableGlobalSizeFader(self)
    self.sizeFaderConfig.globalEnabled = false
    Popup(nil, "Disabled global size fader")
end
function AZ_Global_Type.prototype.SetSizeFaderRange(self, min, max)
    self.sizeFaderConfig.rangeMin = min
    self.sizeFaderConfig.rangeMax = max
    Popup(
        nil,
        ((("Set size fader range to [" .. tostring(min)) .. ", ") .. tostring(max)) .. "]"
    )
end
function AZ_Global_Type.prototype.EnableDatapool(self)
    self.useAZDatapool = true
    Popup(nil, "Enabled AZ Datapool")
end
function AZ_Global_Type.prototype.DisableDatapool(self)
    self.useAZDatapool = false
    Popup(nil, "Disabled AZ Datapool")
end
function AZ_Global_Type.prototype.CreateMacros(self, startingIndex)
    if not startingIndex then
        Popup(nil, "No starting index provided, macros creation cancelled, Usage : AZ:CreateMacros(<Starting Index>)", 3)
        return
    end
    do
        local i = 0
        while i < #IMPORTED_MACROS do
            createMacro(nil, IMPORTED_MACROS[i + 1].name, startingIndex + i, IMPORTED_MACROS[i + 1].commands)
            i = i + 1
        end
    end
end
function AZ_Global_Type.prototype.CreateAZSequences(self, fid)
    local enabledFixture = __TS__ArrayFind(
        self.enabledFixtures,
        function(____, enabledFixture) return enabledFixture.fixture.fid == fid end
    )
    if not enabledFixture then
        return Popup(
            nil,
            ("Fixture " .. tostring(fid)) .. " is not enabled",
            3
        )
    end
    createSequencesForFixture(nil, enabledFixture, self.useAZDatapool)
    enabledFixture.fixture:invalidate()
end
return ____exports
 end,
["src.main"] = function(...) 
local ____lualib = require("lualib_bundle")
local __TS__New = ____lualib.__TS__New
local __TS__SourceMapTraceBack = ____lualib.__TS__SourceMapTraceBack
local ____exports = {}
local ____autozoom_object = require("src.autozoom_object")
local AZ_Global_Type = ____autozoom_object.AZ_Global_Type
local function main(self, display, args)
    if AZ ~= nil then
        AZ:Cleanup()
    end
    AZ = __TS__New(AZ_Global_Type)
    AZ:Init()
end
return main
 end,
}
local __TS__SourceMapTraceBack = require("lualib_bundle").__TS__SourceMapTraceBack
__TS__SourceMapTraceBack(debug.getinfo(1).short_src, {["293"] = {line = 25, file = "utils.ts"},["294"] = {line = 25, file = "utils.ts"},["296"] = {line = 26, file = "utils.ts"},["297"] = {line = 27, file = "utils.ts"},["299"] = {line = 28, file = "utils.ts"},["301"] = {line = 29, file = "utils.ts"},["303"] = {line = 30, file = "utils.ts"},["305"] = {line = 31, file = "utils.ts"},["307"] = {line = 32, file = "utils.ts"},["309"] = {line = 33, file = "utils.ts"},["311"] = {line = 34, file = "utils.ts"},["314"] = {line = 36, file = "utils.ts"},["318"] = {line = 59, file = "utils.ts"},["319"] = {line = 59, file = "utils.ts"},["320"] = {line = 59, file = "utils.ts"},["322"] = {line = 60, file = "utils.ts"},["323"] = {line = 61, file = "utils.ts"},["324"] = {line = 62, file = "utils.ts"},["325"] = {line = 63, file = "utils.ts"},["326"] = {line = 60, file = "utils.ts"},["327"] = {line = 59, file = "utils.ts"},["328"] = {line = 2, file = "utils.ts"},["329"] = {line = 4, file = "utils.ts"},["331"] = {line = 5, file = "utils.ts"},["332"] = {line = 6, file = "utils.ts"},["334"] = {line = 7, file = "utils.ts"},["337"] = {line = 9, file = "utils.ts"},["339"] = {line = 10, file = "utils.ts"},["342"] = {line = 12, file = "utils.ts"},["344"] = {line = 13, file = "utils.ts"},["347"] = {line = 15, file = "utils.ts"},["349"] = {line = 16, file = "utils.ts"},["353"] = {line = 19, file = "utils.ts"},["357"] = {line = 22, file = "utils.ts"},["358"] = {line = 22, file = "utils.ts"},["359"] = {line = 22, file = "utils.ts"},["360"] = {line = 22, file = "utils.ts"},["361"] = {line = 4, file = "utils.ts"},["362"] = {line = 40, file = "utils.ts"},["363"] = {line = 41, file = "utils.ts"},["364"] = {line = 41, file = "utils.ts"},["365"] = {line = 41, file = "utils.ts"},["366"] = {line = 41, file = "utils.ts"},["367"] = {line = 40, file = "utils.ts"},["368"] = {line = 43, file = "utils.ts"},["369"] = {line = 44, file = "utils.ts"},["370"] = {line = 45, file = "utils.ts"},["372"] = {line = 43, file = "utils.ts"},["373"] = {line = 50, file = "utils.ts"},["374"] = {line = 51, file = "utils.ts"},["375"] = {line = 50, file = "utils.ts"},["376"] = {line = 55, file = "utils.ts"},["377"] = {line = 56, file = "utils.ts"},["378"] = {line = 55, file = "utils.ts"},["385"] = {line = 10, file = "calculate-zoom-iris.ts"},["386"] = {line = 11, file = "calculate-zoom-iris.ts"},["387"] = {line = 10, file = "calculate-zoom-iris.ts"},["388"] = {line = 15, file = "calculate-zoom-iris.ts"},["389"] = {line = 18, file = "calculate-zoom-iris.ts"},["390"] = {line = 19, file = "calculate-zoom-iris.ts"},["391"] = {line = 15, file = "calculate-zoom-iris.ts"},["392"] = {line = 23, file = "calculate-zoom-iris.ts"},["393"] = {line = 32, file = "calculate-zoom-iris.ts"},["394"] = {line = 35, file = "calculate-zoom-iris.ts"},["395"] = {line = 39, file = "calculate-zoom-iris.ts"},["396"] = {line = 41, file = "calculate-zoom-iris.ts"},["397"] = {line = 41, file = "calculate-zoom-iris.ts"},["398"] = {line = 41, file = "calculate-zoom-iris.ts"},["399"] = {line = 41, file = "calculate-zoom-iris.ts"},["400"] = {line = 44, file = "calculate-zoom-iris.ts"},["401"] = {line = 45, file = "calculate-zoom-iris.ts"},["402"] = {line = 46, file = "calculate-zoom-iris.ts"},["403"] = {line = 47, file = "calculate-zoom-iris.ts"},["405"] = {line = 49, file = "calculate-zoom-iris.ts"},["406"] = {line = 50, file = "calculate-zoom-iris.ts"},["408"] = {line = 54, file = "calculate-zoom-iris.ts"},["410"] = {line = 23, file = "calculate-zoom-iris.ts"},["420"] = {line = 2, file = "handle-execs.ts"},["421"] = {line = 2, file = "handle-execs.ts"},["422"] = {line = 2, file = "handle-execs.ts"},["423"] = {line = 2, file = "handle-execs.ts"},["424"] = {line = 17, file = "handle-execs.ts"},["425"] = {line = 18, file = "handle-execs.ts"},["426"] = {line = 18, file = "handle-execs.ts"},["427"] = {line = 18, file = "handle-execs.ts"},["428"] = {line = 18, file = "handle-execs.ts"},["429"] = {line = 19, file = "handle-execs.ts"},["430"] = {line = 19, file = "handle-execs.ts"},["431"] = {line = 19, file = "handle-execs.ts"},["432"] = {line = 19, file = "handle-execs.ts"},["433"] = {line = 18, file = "handle-execs.ts"},["434"] = {line = 20, file = "handle-execs.ts"},["435"] = {line = 18, file = "handle-execs.ts"},["436"] = {line = 21, file = "handle-execs.ts"},["437"] = {line = 18, file = "handle-execs.ts"},["438"] = {line = 22, file = "handle-execs.ts"},["439"] = {line = 22, file = "handle-execs.ts"},["441"] = {line = 23, file = "handle-execs.ts"},["442"] = {line = 17, file = "handle-execs.ts"},["443"] = {line = 4, file = "handle-execs.ts"},["444"] = {line = 5, file = "handle-execs.ts"},["445"] = {line = 5, file = "handle-execs.ts"},["446"] = {line = 5, file = "handle-execs.ts"},["447"] = {line = 5, file = "handle-execs.ts"},["448"] = {line = 5, file = "handle-execs.ts"},["449"] = {line = 7, file = "handle-execs.ts"},["450"] = {line = 8, file = "handle-execs.ts"},["451"] = {line = 9, file = "handle-execs.ts"},["454"] = {line = 12, file = "handle-execs.ts"},["455"] = {line = 4, file = "handle-execs.ts"},["456"] = {line = 27, file = "handle-execs.ts"},["457"] = {line = 28, file = "handle-execs.ts"},["458"] = {line = 29, file = "handle-execs.ts"},["460"] = {line = 30, file = "handle-execs.ts"},["461"] = {line = 30, file = "handle-execs.ts"},["463"] = {line = 30, file = "handle-execs.ts"},["464"] = {line = 27, file = "handle-execs.ts"},["465"] = {line = 34, file = "handle-execs.ts"},["466"] = {line = 35, file = "handle-execs.ts"},["467"] = {line = 36, file = "handle-execs.ts"},["469"] = {line = 37, file = "handle-execs.ts"},["470"] = {line = 37, file = "handle-execs.ts"},["472"] = {line = 37, file = "handle-execs.ts"},["473"] = {line = 34, file = "handle-execs.ts"},["474"] = {line = 41, file = "handle-execs.ts"},["475"] = {line = 49, file = "handle-execs.ts"},["476"] = {line = 41, file = "handle-execs.ts"},["477"] = {line = 53, file = "handle-execs.ts"},["479"] = {line = 54, file = "handle-execs.ts"},["480"] = {line = 54, file = "handle-execs.ts"},["481"] = {line = 55, file = "handle-execs.ts"},["482"] = {line = 56, file = "handle-execs.ts"},["485"] = {line = 54, file = "handle-execs.ts"},["488"] = {line = 60, file = "handle-execs.ts"},["489"] = {line = 53, file = "handle-execs.ts"},["490"] = {line = 64, file = "handle-execs.ts"},["491"] = {line = 68, file = "handle-execs.ts"},["492"] = {line = 64, file = "handle-execs.ts"},["493"] = {line = 71, file = "handle-execs.ts"},["494"] = {line = 72, file = "handle-execs.ts"},["495"] = {line = 73, file = "handle-execs.ts"},["497"] = {line = 75, file = "handle-execs.ts"},["498"] = {line = 76, file = "handle-execs.ts"},["499"] = {line = 77, file = "handle-execs.ts"},["500"] = {line = 78, file = "handle-execs.ts"},["501"] = {line = 79, file = "handle-execs.ts"},["503"] = {line = 81, file = "handle-execs.ts"},["505"] = {line = 84, file = "handle-execs.ts"},["506"] = {line = 85, file = "handle-execs.ts"},["507"] = {line = 86, file = "handle-execs.ts"},["508"] = {line = 87, file = "handle-execs.ts"},["509"] = {line = 88, file = "handle-execs.ts"},["510"] = {line = 89, file = "handle-execs.ts"},["512"] = {line = 91, file = "handle-execs.ts"},["515"] = {line = 71, file = "handle-execs.ts"},["516"] = {line = 96, file = "handle-execs.ts"},["517"] = {line = 97, file = "handle-execs.ts"},["518"] = {line = 98, file = "handle-execs.ts"},["520"] = {line = 100, file = "handle-execs.ts"},["521"] = {line = 101, file = "handle-execs.ts"},["522"] = {line = 102, file = "handle-execs.ts"},["523"] = {line = 103, file = "handle-execs.ts"},["525"] = {line = 105, file = "handle-execs.ts"},["526"] = {line = 106, file = "handle-execs.ts"},["528"] = {line = 96, file = "handle-execs.ts"},["529"] = {line = 110, file = "handle-execs.ts"},["530"] = {line = 111, file = "handle-execs.ts"},["531"] = {line = 116, file = "handle-execs.ts"},["532"] = {line = 117, file = "handle-execs.ts"},["533"] = {line = 118, file = "handle-execs.ts"},["534"] = {line = 119, file = "handle-execs.ts"},["535"] = {line = 119, file = "handle-execs.ts"},["536"] = {line = 119, file = "handle-execs.ts"},["537"] = {line = 119, file = "handle-execs.ts"},["539"] = {line = 121, file = "handle-execs.ts"},["540"] = {line = 121, file = "handle-execs.ts"},["541"] = {line = 121, file = "handle-execs.ts"},["542"] = {line = 121, file = "handle-execs.ts"},["544"] = {line = 110, file = "handle-execs.ts"},["555"] = {line = 1, file = "types.ts"},["556"] = {line = 1, file = "types.ts"},["557"] = {line = 2, file = "types.ts"},["558"] = {line = 2, file = "types.ts"},["559"] = {line = 2, file = "types.ts"},["560"] = {line = 2, file = "types.ts"},["561"] = {line = 4, file = "types.ts"},["562"] = {line = 4, file = "types.ts"},["563"] = {line = 6, file = "types.ts"},["564"] = {line = 6, file = "types.ts"},["565"] = {line = 6, file = "types.ts"},["566"] = {line = 11, file = "types.ts"},["567"] = {line = 12, file = "types.ts"},["568"] = {line = 13, file = "types.ts"},["569"] = {line = 14, file = "types.ts"},["570"] = {line = 11, file = "types.ts"},["571"] = {line = 17, file = "types.ts"},["572"] = {line = 18, file = "types.ts"},["573"] = {line = 17, file = "types.ts"},["574"] = {line = 21, file = "types.ts"},["575"] = {line = 22, file = "types.ts"},["576"] = {line = 21, file = "types.ts"},["577"] = {line = 36, file = "types.ts"},["578"] = {line = 36, file = "types.ts"},["579"] = {line = 36, file = "types.ts"},["580"] = {line = 41, file = "types.ts"},["581"] = {line = 42, file = "types.ts"},["582"] = {line = 43, file = "types.ts"},["583"] = {line = 44, file = "types.ts"},["584"] = {line = 45, file = "types.ts"},["585"] = {line = 41, file = "types.ts"},["586"] = {line = 48, file = "types.ts"},["587"] = {line = 49, file = "types.ts"},["588"] = {line = 50, file = "types.ts"},["589"] = {line = 51, file = "types.ts"},["590"] = {line = 52, file = "types.ts"},["591"] = {line = 49, file = "types.ts"},["592"] = {line = 48, file = "types.ts"},["593"] = {line = 57, file = "types.ts"},["594"] = {line = 57, file = "types.ts"},["595"] = {line = 57, file = "types.ts"},["596"] = {line = 65, file = "types.ts"},["597"] = {line = 66, file = "types.ts"},["598"] = {line = 67, file = "types.ts"},["599"] = {line = 68, file = "types.ts"},["600"] = {line = 69, file = "types.ts"},["601"] = {line = 70, file = "types.ts"},["602"] = {line = 71, file = "types.ts"},["603"] = {line = 72, file = "types.ts"},["604"] = {line = 65, file = "types.ts"},["605"] = {line = 75, file = "types.ts"},["606"] = {line = 76, file = "types.ts"},["607"] = {line = 77, file = "types.ts"},["608"] = {line = 78, file = "types.ts"},["609"] = {line = 76, file = "types.ts"},["610"] = {line = 75, file = "types.ts"},["611"] = {line = 82, file = "types.ts"},["612"] = {line = 83, file = "types.ts"},["613"] = {line = 84, file = "types.ts"},["614"] = {line = 84, file = "types.ts"},["615"] = {line = 84, file = "types.ts"},["616"] = {line = 84, file = "types.ts"},["617"] = {line = 84, file = "types.ts"},["618"] = {line = 85, file = "types.ts"},["620"] = {line = 87, file = "types.ts"},["621"] = {line = 88, file = "types.ts"},["622"] = {line = 88, file = "types.ts"},["623"] = {line = 88, file = "types.ts"},["624"] = {line = 88, file = "types.ts"},["625"] = {line = 88, file = "types.ts"},["626"] = {line = 89, file = "types.ts"},["628"] = {line = 82, file = "types.ts"},["629"] = {line = 93, file = "types.ts"},["630"] = {line = 94, file = "types.ts"},["631"] = {line = 93, file = "types.ts"},["632"] = {line = 97, file = "types.ts"},["633"] = {line = 98, file = "types.ts"},["634"] = {line = 99, file = "types.ts"},["635"] = {line = 97, file = "types.ts"},["636"] = {line = 102, file = "types.ts"},["637"] = {line = 103, file = "types.ts"},["638"] = {line = 102, file = "types.ts"},["639"] = {line = 105, file = "types.ts"},["640"] = {line = 106, file = "types.ts"},["641"] = {line = 105, file = "types.ts"},["642"] = {line = 110, file = "types.ts"},["643"] = {line = 110, file = "types.ts"},["644"] = {line = 110, file = "types.ts"},["645"] = {line = 118, file = "types.ts"},["646"] = {line = 116, file = "types.ts"},["647"] = {line = 119, file = "types.ts"},["648"] = {line = 120, file = "types.ts"},["649"] = {line = 121, file = "types.ts"},["650"] = {line = 122, file = "types.ts"},["651"] = {line = 123, file = "types.ts"},["652"] = {line = 118, file = "types.ts"},["653"] = {line = 126, file = "types.ts"},["654"] = {line = 127, file = "types.ts"},["655"] = {line = 126, file = "types.ts"},["656"] = {line = 130, file = "types.ts"},["657"] = {line = 131, file = "types.ts"},["658"] = {line = 131, file = "types.ts"},["659"] = {line = 131, file = "types.ts"},["660"] = {line = 132, file = "types.ts"},["661"] = {line = 131, file = "types.ts"},["662"] = {line = 133, file = "types.ts"},["663"] = {line = 131, file = "types.ts"},["664"] = {line = 134, file = "types.ts"},["665"] = {line = 135, file = "types.ts"},["666"] = {line = 135, file = "types.ts"},["668"] = {line = 137, file = "types.ts"},["669"] = {line = 138, file = "types.ts"},["670"] = {line = 139, file = "types.ts"},["671"] = {line = 140, file = "types.ts"},["672"] = {line = 130, file = "types.ts"},["673"] = {line = 149, file = "types.ts"},["674"] = {line = 149, file = "types.ts"},["675"] = {line = 149, file = "types.ts"},["676"] = {line = 154, file = "types.ts"},["677"] = {line = 155, file = "types.ts"},["678"] = {line = 156, file = "types.ts"},["679"] = {line = 157, file = "types.ts"},["680"] = {line = 154, file = "types.ts"},["681"] = {line = 160, file = "types.ts"},["682"] = {line = 161, file = "types.ts"},["685"] = {line = 162, file = "types.ts"},["686"] = {line = 163, file = "types.ts"},["687"] = {line = 164, file = "types.ts"},["688"] = {line = 166, file = "types.ts"},["689"] = {line = 167, file = "types.ts"},["691"] = {line = 169, file = "types.ts"},["692"] = {line = 169, file = "types.ts"},["693"] = {line = 169, file = "types.ts"},["694"] = {line = 169, file = "types.ts"},["695"] = {line = 169, file = "types.ts"},["696"] = {line = 169, file = "types.ts"},["697"] = {line = 169, file = "types.ts"},["698"] = {line = 169, file = "types.ts"},["699"] = {line = 170, file = "types.ts"},["700"] = {line = 170, file = "types.ts"},["701"] = {line = 170, file = "types.ts"},["702"] = {line = 170, file = "types.ts"},["703"] = {line = 170, file = "types.ts"},["704"] = {line = 170, file = "types.ts"},["705"] = {line = 170, file = "types.ts"},["706"] = {line = 172, file = "types.ts"},["707"] = {line = 160, file = "types.ts"},["708"] = {line = 175, file = "types.ts"},["709"] = {line = 176, file = "types.ts"},["710"] = {line = 177, file = "types.ts"},["711"] = {line = 175, file = "types.ts"},["720"] = {line = 2, file = "load-patch.ts"},["721"] = {line = 2, file = "load-patch.ts"},["722"] = {line = 2, file = "load-patch.ts"},["723"] = {line = 2, file = "load-patch.ts"},["724"] = {line = 2, file = "load-patch.ts"},["725"] = {line = 3, file = "load-patch.ts"},["726"] = {line = 3, file = "load-patch.ts"},["727"] = {line = 3, file = "load-patch.ts"},["728"] = {line = 21, file = "load-patch.ts"},["729"] = {line = 22, file = "load-patch.ts"},["730"] = {line = 23, file = "load-patch.ts"},["731"] = {line = 24, file = "load-patch.ts"},["732"] = {line = 24, file = "load-patch.ts"},["733"] = {line = 24, file = "load-patch.ts"},["734"] = {line = 26, file = "load-patch.ts"},["737"] = {line = 31, file = "load-patch.ts"},["738"] = {line = 32, file = "load-patch.ts"},["739"] = {line = 33, file = "load-patch.ts"},["741"] = {line = 24, file = "load-patch.ts"},["742"] = {line = 24, file = "load-patch.ts"},["743"] = {line = 37, file = "load-patch.ts"},["744"] = {line = 37, file = "load-patch.ts"},["745"] = {line = 37, file = "load-patch.ts"},["746"] = {line = 37, file = "load-patch.ts"},["747"] = {line = 21, file = "load-patch.ts"},["748"] = {line = 40, file = "load-patch.ts"},["749"] = {line = 41, file = "load-patch.ts"},["750"] = {line = 42, file = "load-patch.ts"},["751"] = {line = 43, file = "load-patch.ts"},["752"] = {line = 43, file = "load-patch.ts"},["753"] = {line = 43, file = "load-patch.ts"},["754"] = {line = 45, file = "load-patch.ts"},["757"] = {line = 50, file = "load-patch.ts"},["758"] = {line = 51, file = "load-patch.ts"},["759"] = {line = 52, file = "load-patch.ts"},["761"] = {line = 43, file = "load-patch.ts"},["762"] = {line = 43, file = "load-patch.ts"},["763"] = {line = 55, file = "load-patch.ts"},["764"] = {line = 56, file = "load-patch.ts"},["766"] = {line = 58, file = "load-patch.ts"},["767"] = {line = 59, file = "load-patch.ts"},["769"] = {line = 61, file = "load-patch.ts"},["770"] = {line = 61, file = "load-patch.ts"},["771"] = {line = 61, file = "load-patch.ts"},["772"] = {line = 61, file = "load-patch.ts"},["773"] = {line = 40, file = "load-patch.ts"},["774"] = {line = 64, file = "load-patch.ts"},["775"] = {line = 65, file = "load-patch.ts"},["776"] = {line = 66, file = "load-patch.ts"},["777"] = {line = 67, file = "load-patch.ts"},["778"] = {line = 68, file = "load-patch.ts"},["780"] = {line = 70, file = "load-patch.ts"},["781"] = {line = 71, file = "load-patch.ts"},["782"] = {line = 72, file = "load-patch.ts"},["783"] = {line = 70, file = "load-patch.ts"},["784"] = {line = 64, file = "load-patch.ts"},["785"] = {line = 76, file = "load-patch.ts"},["786"] = {line = 77, file = "load-patch.ts"},["787"] = {line = 78, file = "load-patch.ts"},["788"] = {line = 81, file = "load-patch.ts"},["789"] = {line = 81, file = "load-patch.ts"},["790"] = {line = 81, file = "load-patch.ts"},["791"] = {line = 82, file = "load-patch.ts"},["792"] = {line = 83, file = "load-patch.ts"},["793"] = {line = 84, file = "load-patch.ts"},["795"] = {line = 86, file = "load-patch.ts"},["796"] = {line = 86, file = "load-patch.ts"},["797"] = {line = 86, file = "load-patch.ts"},["798"] = {line = 88, file = "load-patch.ts"},["799"] = {line = 89, file = "load-patch.ts"},["800"] = {line = 90, file = "load-patch.ts"},["801"] = {line = 91, file = "load-patch.ts"},["802"] = {line = 92, file = "load-patch.ts"},["803"] = {line = 92, file = "load-patch.ts"},["804"] = {line = 92, file = "load-patch.ts"},["805"] = {line = 92, file = "load-patch.ts"},["806"] = {line = 92, file = "load-patch.ts"},["807"] = {line = 92, file = "load-patch.ts"},["808"] = {line = 92, file = "load-patch.ts"},["809"] = {line = 93, file = "load-patch.ts"},["811"] = {line = 86, file = "load-patch.ts"},["812"] = {line = 86, file = "load-patch.ts"},["813"] = {line = 81, file = "load-patch.ts"},["814"] = {line = 81, file = "load-patch.ts"},["815"] = {line = 97, file = "load-patch.ts"},["816"] = {line = 76, file = "load-patch.ts"},["817"] = {line = 100, file = "load-patch.ts"},["818"] = {line = 101, file = "load-patch.ts"},["819"] = {line = 100, file = "load-patch.ts"},["820"] = {line = 104, file = "load-patch.ts"},["821"] = {line = 106, file = "load-patch.ts"},["822"] = {line = 107, file = "load-patch.ts"},["823"] = {line = 107, file = "load-patch.ts"},["824"] = {line = 108, file = "load-patch.ts"},["825"] = {line = 108, file = "load-patch.ts"},["826"] = {line = 108, file = "load-patch.ts"},["827"] = {line = 108, file = "load-patch.ts"},["828"] = {line = 107, file = "load-patch.ts"},["829"] = {line = 110, file = "load-patch.ts"},["832"] = {line = 115, file = "load-patch.ts"},["835"] = {line = 118, file = "load-patch.ts"},["836"] = {line = 119, file = "load-patch.ts"},["837"] = {line = 121, file = "load-patch.ts"},["838"] = {line = 124, file = "load-patch.ts"},["840"] = {line = 126, file = "load-patch.ts"},["841"] = {line = 126, file = "load-patch.ts"},["842"] = {line = 127, file = "load-patch.ts"},["843"] = {line = 127, file = "load-patch.ts"},["844"] = {line = 127, file = "load-patch.ts"},["845"] = {line = 127, file = "load-patch.ts"},["846"] = {line = 127, file = "load-patch.ts"},["847"] = {line = 127, file = "load-patch.ts"},["848"] = {line = 127, file = "load-patch.ts"},["849"] = {line = 126, file = "load-patch.ts"},["853"] = {line = 133, file = "load-patch.ts"},["854"] = {line = 134, file = "load-patch.ts"},["855"] = {line = 134, file = "load-patch.ts"},["856"] = {line = 134, file = "load-patch.ts"},["857"] = {line = 135, file = "load-patch.ts"},["860"] = {line = 139, file = "load-patch.ts"},["862"] = {line = 134, file = "load-patch.ts"},["863"] = {line = 134, file = "load-patch.ts"},["864"] = {line = 141, file = "load-patch.ts"},["867"] = {line = 144, file = "load-patch.ts"},["870"] = {line = 147, file = "load-patch.ts"},["871"] = {line = 147, file = "load-patch.ts"},["872"] = {line = 147, file = "load-patch.ts"},["873"] = {line = 147, file = "load-patch.ts"},["874"] = {line = 147, file = "load-patch.ts"},["875"] = {line = 147, file = "load-patch.ts"},["876"] = {line = 147, file = "load-patch.ts"},["877"] = {line = 147, file = "load-patch.ts"},["878"] = {line = 149, file = "load-patch.ts"},["879"] = {line = 150, file = "load-patch.ts"},["882"] = {line = 104, file = "load-patch.ts"},["883"] = {line = 165, file = "load-patch.ts"},["884"] = {line = 166, file = "load-patch.ts"},["885"] = {line = 167, file = "load-patch.ts"},["886"] = {line = 168, file = "load-patch.ts"},["887"] = {line = 169, file = "load-patch.ts"},["888"] = {line = 170, file = "load-patch.ts"},["889"] = {line = 171, file = "load-patch.ts"},["891"] = {line = 173, file = "load-patch.ts"},["892"] = {line = 173, file = "load-patch.ts"},["893"] = {line = 173, file = "load-patch.ts"},["894"] = {line = 173, file = "load-patch.ts"},["895"] = {line = 173, file = "load-patch.ts"},["897"] = {line = 174, file = "load-patch.ts"},["898"] = {line = 174, file = "load-patch.ts"},["899"] = {line = 175, file = "load-patch.ts"},["900"] = {line = 175, file = "load-patch.ts"},["901"] = {line = 175, file = "load-patch.ts"},["902"] = {line = 175, file = "load-patch.ts"},["903"] = {line = 175, file = "load-patch.ts"},["904"] = {line = 176, file = "load-patch.ts"},["905"] = {line = 178, file = "load-patch.ts"},["907"] = {line = 179, file = "load-patch.ts"},["908"] = {line = 179, file = "load-patch.ts"},["909"] = {line = 180, file = "load-patch.ts"},["910"] = {line = 183, file = "load-patch.ts"},["911"] = {line = 183, file = "load-patch.ts"},["912"] = {line = 183, file = "load-patch.ts"},["913"] = {line = 183, file = "load-patch.ts"},["914"] = {line = 183, file = "load-patch.ts"},["915"] = {line = 183, file = "load-patch.ts"},["916"] = {line = 183, file = "load-patch.ts"},["917"] = {line = 179, file = "load-patch.ts"},["920"] = {line = 174, file = "load-patch.ts"},["923"] = {line = 186, file = "load-patch.ts"},["924"] = {line = 165, file = "load-patch.ts"},["931"] = {line = 3, file = "create-macros.ts"},["932"] = {line = 4, file = "create-macros.ts"},["934"] = {line = 5, file = "create-macros.ts"},["935"] = {line = 5, file = "create-macros.ts"},["936"] = {line = 6, file = "create-macros.ts"},["937"] = {line = 7, file = "create-macros.ts"},["938"] = {line = 5, file = "create-macros.ts"},["941"] = {line = 3, file = "create-macros.ts"},["948"] = {line = 1, file = "macros.ts"},["949"] = {line = 2, file = "macros.ts"},["950"] = {line = 8, file = "macros.ts"},["951"] = {line = 14, file = "macros.ts"},["952"] = {line = 20, file = "macros.ts"},["953"] = {line = 26, file = "macros.ts"},["954"] = {line = 32, file = "macros.ts"},["955"] = {line = 38, file = "macros.ts"},["956"] = {line = 44, file = "macros.ts"},["957"] = {line = 50, file = "macros.ts"},["958"] = {line = 56, file = "macros.ts"},["959"] = {line = 62, file = "macros.ts"},["960"] = {line = 68, file = "macros.ts"},["961"] = {line = 74, file = "macros.ts"},["962"] = {line = 80, file = "macros.ts"},["963"] = {line = 86, file = "macros.ts"},["964"] = {line = 92, file = "macros.ts"},["965"] = {line = 98, file = "macros.ts"},["966"] = {line = 1, file = "macros.ts"},["985"] = {line = 1, file = "autozoom_object.ts"},["986"] = {line = 1, file = "autozoom_object.ts"},["987"] = {line = 1, file = "autozoom_object.ts"},["988"] = {line = 1, file = "autozoom_object.ts"},["989"] = {line = 1, file = "autozoom_object.ts"},["990"] = {line = 2, file = "autozoom_object.ts"},["991"] = {line = 2, file = "autozoom_object.ts"},["992"] = {line = 2, file = "autozoom_object.ts"},["993"] = {line = 3, file = "autozoom_object.ts"},["994"] = {line = 3, file = "autozoom_object.ts"},["995"] = {line = 4, file = "autozoom_object.ts"},["996"] = {line = 4, file = "autozoom_object.ts"},["997"] = {line = 5, file = "autozoom_object.ts"},["998"] = {line = 5, file = "autozoom_object.ts"},["999"] = {line = 6, file = "autozoom_object.ts"},["1000"] = {line = 6, file = "autozoom_object.ts"},["1001"] = {line = 9, file = "autozoom_object.ts"},["1002"] = {line = 9, file = "autozoom_object.ts"},["1003"] = {line = 9, file = "autozoom_object.ts"},["1005"] = {line = 14, file = "autozoom_object.ts"},["1006"] = {line = 15, file = "autozoom_object.ts"},["1007"] = {line = 17, file = "autozoom_object.ts"},["1008"] = {line = 18, file = "autozoom_object.ts"},["1009"] = {line = 20, file = "autozoom_object.ts"},["1010"] = {line = 169, file = "autozoom_object.ts"},["1011"] = {line = 170, file = "autozoom_object.ts"},["1012"] = {line = 172, file = "autozoom_object.ts"},["1013"] = {line = 24, file = "autozoom_object.ts"},["1014"] = {line = 25, file = "autozoom_object.ts"},["1015"] = {line = 26, file = "autozoom_object.ts"},["1016"] = {line = 28, file = "autozoom_object.ts"},["1017"] = {line = 23, file = "autozoom_object.ts"},["1018"] = {line = 32, file = "autozoom_object.ts"},["1019"] = {line = 33, file = "autozoom_object.ts"},["1020"] = {line = 32, file = "autozoom_object.ts"},["1021"] = {line = 36, file = "autozoom_object.ts"},["1022"] = {line = 37, file = "autozoom_object.ts"},["1023"] = {line = 37, file = "autozoom_object.ts"},["1024"] = {line = 37, file = "autozoom_object.ts"},["1025"] = {line = 37, file = "autozoom_object.ts"},["1026"] = {line = 36, file = "autozoom_object.ts"},["1027"] = {line = 39, file = "autozoom_object.ts"},["1028"] = {line = 40, file = "autozoom_object.ts"},["1029"] = {line = 41, file = "autozoom_object.ts"},["1031"] = {line = 43, file = "autozoom_object.ts"},["1032"] = {line = 44, file = "autozoom_object.ts"},["1033"] = {line = 44, file = "autozoom_object.ts"},["1034"] = {line = 44, file = "autozoom_object.ts"},["1035"] = {line = 44, file = "autozoom_object.ts"},["1036"] = {line = 45, file = "autozoom_object.ts"},["1037"] = {line = 46, file = "autozoom_object.ts"},["1038"] = {line = 39, file = "autozoom_object.ts"},["1039"] = {line = 48, file = "autozoom_object.ts"},["1040"] = {line = 49, file = "autozoom_object.ts"},["1041"] = {line = 50, file = "autozoom_object.ts"},["1042"] = {line = 48, file = "autozoom_object.ts"},["1043"] = {line = 52, file = "autozoom_object.ts"},["1044"] = {line = 53, file = "autozoom_object.ts"},["1045"] = {line = 54, file = "autozoom_object.ts"},["1047"] = {line = 56, file = "autozoom_object.ts"},["1049"] = {line = 52, file = "autozoom_object.ts"},["1050"] = {line = 59, file = "autozoom_object.ts"},["1051"] = {line = 60, file = "autozoom_object.ts"},["1052"] = {line = 60, file = "autozoom_object.ts"},["1053"] = {line = 60, file = "autozoom_object.ts"},["1054"] = {line = 60, file = "autozoom_object.ts"},["1055"] = {line = 59, file = "autozoom_object.ts"},["1056"] = {line = 63, file = "autozoom_object.ts"},["1057"] = {line = 64, file = "autozoom_object.ts"},["1058"] = {line = 65, file = "autozoom_object.ts"},["1059"] = {line = 66, file = "autozoom_object.ts"},["1060"] = {line = 67, file = "autozoom_object.ts"},["1061"] = {line = 68, file = "autozoom_object.ts"},["1062"] = {line = 69, file = "autozoom_object.ts"},["1063"] = {line = 70, file = "autozoom_object.ts"},["1064"] = {line = 70, file = "autozoom_object.ts"},["1065"] = {line = 70, file = "autozoom_object.ts"},["1066"] = {line = 71, file = "autozoom_object.ts"},["1067"] = {line = 71, file = "autozoom_object.ts"},["1068"] = {line = 71, file = "autozoom_object.ts"},["1069"] = {line = 71, file = "autozoom_object.ts"},["1070"] = {line = 72, file = "autozoom_object.ts"},["1071"] = {line = 72, file = "autozoom_object.ts"},["1072"] = {line = 72, file = "autozoom_object.ts"},["1073"] = {line = 72, file = "autozoom_object.ts"},["1074"] = {line = 73, file = "autozoom_object.ts"},["1075"] = {line = 74, file = "autozoom_object.ts"},["1076"] = {line = 75, file = "autozoom_object.ts"},["1078"] = {line = 77, file = "autozoom_object.ts"},["1079"] = {line = 78, file = "autozoom_object.ts"},["1080"] = {line = 79, file = "autozoom_object.ts"},["1081"] = {line = 70, file = "autozoom_object.ts"},["1082"] = {line = 70, file = "autozoom_object.ts"},["1083"] = {line = 82, file = "autozoom_object.ts"},["1084"] = {line = 83, file = "autozoom_object.ts"},["1085"] = {line = 83, file = "autozoom_object.ts"},["1087"] = {line = 84, file = "autozoom_object.ts"},["1088"] = {line = 63, file = "autozoom_object.ts"},["1089"] = {line = 87, file = "autozoom_object.ts"},["1090"] = {line = 88, file = "autozoom_object.ts"},["1091"] = {line = 88, file = "autozoom_object.ts"},["1093"] = {line = 89, file = "autozoom_object.ts"},["1094"] = {line = 89, file = "autozoom_object.ts"},["1096"] = {line = 91, file = "autozoom_object.ts"},["1098"] = {line = 92, file = "autozoom_object.ts"},["1099"] = {line = 93, file = "autozoom_object.ts"},["1100"] = {line = 94, file = "autozoom_object.ts"},["1101"] = {line = 94, file = "autozoom_object.ts"},["1102"] = {line = 94, file = "autozoom_object.ts"},["1103"] = {line = 94, file = "autozoom_object.ts"},["1107"] = {line = 95, file = "autozoom_object.ts"},["1108"] = {line = 96, file = "autozoom_object.ts"},["1109"] = {line = 96, file = "autozoom_object.ts"},["1110"] = {line = 96, file = "autozoom_object.ts"},["1111"] = {line = 96, file = "autozoom_object.ts"},["1113"] = {line = 91, file = "autozoom_object.ts"},["1114"] = {line = 91, file = "autozoom_object.ts"},["1115"] = {line = 91, file = "autozoom_object.ts"},["1116"] = {line = 91, file = "autozoom_object.ts"},["1117"] = {line = 87, file = "autozoom_object.ts"},["1118"] = {line = 99, file = "autozoom_object.ts"},["1119"] = {line = 100, file = "autozoom_object.ts"},["1120"] = {line = 100, file = "autozoom_object.ts"},["1122"] = {line = 102, file = "autozoom_object.ts"},["1123"] = {line = 102, file = "autozoom_object.ts"},["1124"] = {line = 102, file = "autozoom_object.ts"},["1125"] = {line = 102, file = "autozoom_object.ts"},["1126"] = {line = 102, file = "autozoom_object.ts"},["1127"] = {line = 102, file = "autozoom_object.ts"},["1128"] = {line = 102, file = "autozoom_object.ts"},["1129"] = {line = 99, file = "autozoom_object.ts"},["1130"] = {line = 105, file = "autozoom_object.ts"},["1131"] = {line = 106, file = "autozoom_object.ts"},["1132"] = {line = 106, file = "autozoom_object.ts"},["1134"] = {line = 108, file = "autozoom_object.ts"},["1135"] = {line = 108, file = "autozoom_object.ts"},["1137"] = {line = 110, file = "autozoom_object.ts"},["1138"] = {line = 110, file = "autozoom_object.ts"},["1139"] = {line = 110, file = "autozoom_object.ts"},["1140"] = {line = 110, file = "autozoom_object.ts"},["1141"] = {line = 111, file = "autozoom_object.ts"},["1142"] = {line = 111, file = "autozoom_object.ts"},["1143"] = {line = 111, file = "autozoom_object.ts"},["1144"] = {line = 111, file = "autozoom_object.ts"},["1145"] = {line = 111, file = "autozoom_object.ts"},["1146"] = {line = 111, file = "autozoom_object.ts"},["1148"] = {line = 113, file = "autozoom_object.ts"},["1149"] = {line = 113, file = "autozoom_object.ts"},["1150"] = {line = 113, file = "autozoom_object.ts"},["1151"] = {line = 113, file = "autozoom_object.ts"},["1152"] = {line = 114, file = "autozoom_object.ts"},["1153"] = {line = 114, file = "autozoom_object.ts"},["1154"] = {line = 114, file = "autozoom_object.ts"},["1155"] = {line = 114, file = "autozoom_object.ts"},["1156"] = {line = 114, file = "autozoom_object.ts"},["1157"] = {line = 114, file = "autozoom_object.ts"},["1159"] = {line = 116, file = "autozoom_object.ts"},["1160"] = {line = 116, file = "autozoom_object.ts"},["1161"] = {line = 116, file = "autozoom_object.ts"},["1162"] = {line = 116, file = "autozoom_object.ts"},["1163"] = {line = 117, file = "autozoom_object.ts"},["1164"] = {line = 119, file = "autozoom_object.ts"},["1165"] = {line = 120, file = "autozoom_object.ts"},["1166"] = {line = 121, file = "autozoom_object.ts"},["1167"] = {line = 122, file = "autozoom_object.ts"},["1169"] = {line = 124, file = "autozoom_object.ts"},["1170"] = {line = 125, file = "autozoom_object.ts"},["1171"] = {line = 125, file = "autozoom_object.ts"},["1172"] = {line = 126, file = "autozoom_object.ts"},["1174"] = {line = 129, file = "autozoom_object.ts"},["1175"] = {line = 130, file = "autozoom_object.ts"},["1176"] = {line = 131, file = "autozoom_object.ts"},["1177"] = {line = 132, file = "autozoom_object.ts"},["1178"] = {line = 133, file = "autozoom_object.ts"},["1180"] = {line = 135, file = "autozoom_object.ts"},["1181"] = {line = 105, file = "autozoom_object.ts"},["1182"] = {line = 138, file = "autozoom_object.ts"},["1183"] = {line = 139, file = "autozoom_object.ts"},["1184"] = {line = 139, file = "autozoom_object.ts"},["1185"] = {line = 139, file = "autozoom_object.ts"},["1186"] = {line = 139, file = "autozoom_object.ts"},["1187"] = {line = 140, file = "autozoom_object.ts"},["1188"] = {line = 140, file = "autozoom_object.ts"},["1189"] = {line = 140, file = "autozoom_object.ts"},["1190"] = {line = 140, file = "autozoom_object.ts"},["1191"] = {line = 140, file = "autozoom_object.ts"},["1192"] = {line = 140, file = "autozoom_object.ts"},["1194"] = {line = 142, file = "autozoom_object.ts"},["1195"] = {line = 143, file = "autozoom_object.ts"},["1196"] = {line = 143, file = "autozoom_object.ts"},["1197"] = {line = 143, file = "autozoom_object.ts"},["1198"] = {line = 143, file = "autozoom_object.ts"},["1199"] = {line = 138, file = "autozoom_object.ts"},["1200"] = {line = 145, file = "autozoom_object.ts"},["1201"] = {line = 146, file = "autozoom_object.ts"},["1202"] = {line = 145, file = "autozoom_object.ts"},["1203"] = {line = 148, file = "autozoom_object.ts"},["1204"] = {line = 149, file = "autozoom_object.ts"},["1205"] = {line = 148, file = "autozoom_object.ts"},["1206"] = {line = 152, file = "autozoom_object.ts"},["1207"] = {line = 153, file = "autozoom_object.ts"},["1208"] = {line = 154, file = "autozoom_object.ts"},["1209"] = {line = 152, file = "autozoom_object.ts"},["1210"] = {line = 157, file = "autozoom_object.ts"},["1211"] = {line = 158, file = "autozoom_object.ts"},["1212"] = {line = 159, file = "autozoom_object.ts"},["1214"] = {line = 157, file = "autozoom_object.ts"},["1215"] = {line = 163, file = "autozoom_object.ts"},["1216"] = {line = 164, file = "autozoom_object.ts"},["1217"] = {line = 165, file = "autozoom_object.ts"},["1219"] = {line = 163, file = "autozoom_object.ts"},["1220"] = {line = 174, file = "autozoom_object.ts"},["1221"] = {line = 175, file = "autozoom_object.ts"},["1224"] = {line = 178, file = "autozoom_object.ts"},["1225"] = {line = 179, file = "autozoom_object.ts"},["1226"] = {line = 180, file = "autozoom_object.ts"},["1227"] = {line = 181, file = "autozoom_object.ts"},["1230"] = {line = 186, file = "autozoom_object.ts"},["1231"] = {line = 187, file = "autozoom_object.ts"},["1232"] = {line = 189, file = "autozoom_object.ts"},["1233"] = {line = 190, file = "autozoom_object.ts"},["1235"] = {line = 174, file = "autozoom_object.ts"},["1236"] = {line = 194, file = "autozoom_object.ts"},["1237"] = {line = 195, file = "autozoom_object.ts"},["1238"] = {line = 196, file = "autozoom_object.ts"},["1239"] = {line = 196, file = "autozoom_object.ts"},["1240"] = {line = 196, file = "autozoom_object.ts"},["1241"] = {line = 196, file = "autozoom_object.ts"},["1242"] = {line = 194, file = "autozoom_object.ts"},["1243"] = {line = 199, file = "autozoom_object.ts"},["1244"] = {line = 200, file = "autozoom_object.ts"},["1245"] = {line = 201, file = "autozoom_object.ts"},["1248"] = {line = 204, file = "autozoom_object.ts"},["1249"] = {line = 206, file = "autozoom_object.ts"},["1250"] = {line = 207, file = "autozoom_object.ts"},["1251"] = {line = 208, file = "autozoom_object.ts"},["1252"] = {line = 209, file = "autozoom_object.ts"},["1253"] = {line = 210, file = "autozoom_object.ts"},["1254"] = {line = 210, file = "autozoom_object.ts"},["1255"] = {line = 210, file = "autozoom_object.ts"},["1256"] = {line = 210, file = "autozoom_object.ts"},["1257"] = {line = 210, file = "autozoom_object.ts"},["1258"] = {line = 210, file = "autozoom_object.ts"},["1259"] = {line = 210, file = "autozoom_object.ts"},["1260"] = {line = 199, file = "autozoom_object.ts"},["1261"] = {line = 213, file = "autozoom_object.ts"},["1262"] = {line = 214, file = "autozoom_object.ts"},["1263"] = {line = 215, file = "autozoom_object.ts"},["1265"] = {line = 213, file = "autozoom_object.ts"},["1266"] = {line = 219, file = "autozoom_object.ts"},["1267"] = {line = 220, file = "autozoom_object.ts"},["1268"] = {line = 221, file = "autozoom_object.ts"},["1269"] = {line = 222, file = "autozoom_object.ts"},["1270"] = {line = 222, file = "autozoom_object.ts"},["1271"] = {line = 222, file = "autozoom_object.ts"},["1272"] = {line = 223, file = "autozoom_object.ts"},["1273"] = {line = 224, file = "autozoom_object.ts"},["1274"] = {line = 225, file = "autozoom_object.ts"},["1275"] = {line = 226, file = "autozoom_object.ts"},["1276"] = {line = 227, file = "autozoom_object.ts"},["1277"] = {line = 228, file = "autozoom_object.ts"},["1278"] = {line = 222, file = "autozoom_object.ts"},["1279"] = {line = 222, file = "autozoom_object.ts"},["1280"] = {line = 219, file = "autozoom_object.ts"},["1281"] = {line = 232, file = "autozoom_object.ts"},["1282"] = {line = 233, file = "autozoom_object.ts"},["1283"] = {line = 234, file = "autozoom_object.ts"},["1284"] = {line = 235, file = "autozoom_object.ts"},["1285"] = {line = 236, file = "autozoom_object.ts"},["1286"] = {line = 232, file = "autozoom_object.ts"},["1287"] = {line = 239, file = "autozoom_object.ts"},["1288"] = {line = 240, file = "autozoom_object.ts"},["1289"] = {line = 241, file = "autozoom_object.ts"},["1290"] = {line = 242, file = "autozoom_object.ts"},["1291"] = {line = 243, file = "autozoom_object.ts"},["1292"] = {line = 243, file = "autozoom_object.ts"},["1293"] = {line = 243, file = "autozoom_object.ts"},["1294"] = {line = 243, file = "autozoom_object.ts"},["1298"] = {line = 247, file = "autozoom_object.ts"},["1299"] = {line = 247, file = "autozoom_object.ts"},["1300"] = {line = 247, file = "autozoom_object.ts"},["1301"] = {line = 247, file = "autozoom_object.ts"},["1302"] = {line = 247, file = "autozoom_object.ts"},["1303"] = {line = 239, file = "autozoom_object.ts"},["1304"] = {line = 250, file = "autozoom_object.ts"},["1305"] = {line = 251, file = "autozoom_object.ts"},["1306"] = {line = 252, file = "autozoom_object.ts"},["1307"] = {line = 253, file = "autozoom_object.ts"},["1308"] = {line = 254, file = "autozoom_object.ts"},["1309"] = {line = 254, file = "autozoom_object.ts"},["1310"] = {line = 254, file = "autozoom_object.ts"},["1311"] = {line = 254, file = "autozoom_object.ts"},["1315"] = {line = 258, file = "autozoom_object.ts"},["1316"] = {line = 258, file = "autozoom_object.ts"},["1317"] = {line = 258, file = "autozoom_object.ts"},["1318"] = {line = 258, file = "autozoom_object.ts"},["1319"] = {line = 258, file = "autozoom_object.ts"},["1320"] = {line = 250, file = "autozoom_object.ts"},["1321"] = {line = 261, file = "autozoom_object.ts"},["1322"] = {line = 264, file = "autozoom_object.ts"},["1323"] = {line = 265, file = "autozoom_object.ts"},["1324"] = {line = 261, file = "autozoom_object.ts"},["1325"] = {line = 268, file = "autozoom_object.ts"},["1326"] = {line = 269, file = "autozoom_object.ts"},["1327"] = {line = 270, file = "autozoom_object.ts"},["1328"] = {line = 268, file = "autozoom_object.ts"},["1329"] = {line = 273, file = "autozoom_object.ts"},["1330"] = {line = 274, file = "autozoom_object.ts"},["1331"] = {line = 275, file = "autozoom_object.ts"},["1332"] = {line = 276, file = "autozoom_object.ts"},["1333"] = {line = 276, file = "autozoom_object.ts"},["1334"] = {line = 276, file = "autozoom_object.ts"},["1335"] = {line = 276, file = "autozoom_object.ts"},["1336"] = {line = 273, file = "autozoom_object.ts"},["1337"] = {line = 279, file = "autozoom_object.ts"},["1338"] = {line = 280, file = "autozoom_object.ts"},["1339"] = {line = 281, file = "autozoom_object.ts"},["1340"] = {line = 279, file = "autozoom_object.ts"},["1341"] = {line = 284, file = "autozoom_object.ts"},["1342"] = {line = 285, file = "autozoom_object.ts"},["1343"] = {line = 286, file = "autozoom_object.ts"},["1344"] = {line = 284, file = "autozoom_object.ts"},["1345"] = {line = 289, file = "autozoom_object.ts"},["1346"] = {line = 290, file = "autozoom_object.ts"},["1347"] = {line = 291, file = "autozoom_object.ts"},["1351"] = {line = 295, file = "autozoom_object.ts"},["1352"] = {line = 295, file = "autozoom_object.ts"},["1353"] = {line = 296, file = "autozoom_object.ts"},["1354"] = {line = 295, file = "autozoom_object.ts"},["1357"] = {line = 289, file = "autozoom_object.ts"},["1358"] = {line = 300, file = "autozoom_object.ts"},["1359"] = {line = 301, file = "autozoom_object.ts"},["1360"] = {line = 301, file = "autozoom_object.ts"},["1361"] = {line = 301, file = "autozoom_object.ts"},["1362"] = {line = 301, file = "autozoom_object.ts"},["1363"] = {line = 302, file = "autozoom_object.ts"},["1364"] = {line = 302, file = "autozoom_object.ts"},["1365"] = {line = 302, file = "autozoom_object.ts"},["1366"] = {line = 302, file = "autozoom_object.ts"},["1367"] = {line = 302, file = "autozoom_object.ts"},["1368"] = {line = 302, file = "autozoom_object.ts"},["1370"] = {line = 304, file = "autozoom_object.ts"},["1371"] = {line = 305, file = "autozoom_object.ts"},["1372"] = {line = 300, file = "autozoom_object.ts"},["1380"] = {line = 2, file = "main.ts"},["1381"] = {line = 2, file = "main.ts"},["1382"] = {line = 9, file = "main.ts"},["1383"] = {line = 11, file = "main.ts"},["1384"] = {line = 12, file = "main.ts"},["1386"] = {line = 14, file = "main.ts"},["1387"] = {line = 15, file = "main.ts"},["1388"] = {line = 9, file = "main.ts"},["1389"] = {line = 20, file = "main.ts"}});
return require("src.main", ...)
