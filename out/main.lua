
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

local __TS__Symbol, Symbol
do
    local symbolMetatable = {__tostring = function(self)
        return ("Symbol(" .. (self.description or "")) .. ")"
    end}
    function __TS__Symbol(description)
        return setmetatable({description = description}, symbolMetatable)
    end
    Symbol = {
        asyncDispose = __TS__Symbol("Symbol.asyncDispose"),
        dispose = __TS__Symbol("Symbol.dispose"),
        iterator = __TS__Symbol("Symbol.iterator"),
        hasInstance = __TS__Symbol("Symbol.hasInstance"),
        species = __TS__Symbol("Symbol.species"),
        toStringTag = __TS__Symbol("Symbol.toStringTag")
    }
end

local __TS__Iterator
do
    local function iteratorGeneratorStep(self)
        local co = self.____coroutine
        local status, value = coroutine.resume(co)
        if not status then
            error(value, 0)
        end
        if coroutine.status(co) == "dead" then
            return
        end
        return true, value
    end
    local function iteratorIteratorStep(self)
        local result = self:next()
        if result.done then
            return
        end
        return true, result.value
    end
    local function iteratorStringStep(self, index)
        index = index + 1
        if index > #self then
            return
        end
        return index, string.sub(self, index, index)
    end
    function __TS__Iterator(iterable)
        if type(iterable) == "string" then
            return iteratorStringStep, iterable, 0
        elseif iterable.____coroutine ~= nil then
            return iteratorGeneratorStep, iterable
        elseif iterable[Symbol.iterator] then
            local iterator = iterable[Symbol.iterator](iterable)
            return iteratorIteratorStep, iterator
        else
            return ipairs(iterable)
        end
    end
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

local function __TS__ClassExtends(target, base)
    target.____super = base
    local staticMetatable = setmetatable({__index = base}, base)
    setmetatable(target, staticMetatable)
    local baseMetatable = getmetatable(base)
    if baseMetatable then
        if type(baseMetatable.__index) == "function" then
            staticMetatable.__index = baseMetatable.__index
        end
        if type(baseMetatable.__newindex) == "function" then
            staticMetatable.__newindex = baseMetatable.__newindex
        end
    end
    setmetatable(target.prototype, base.prototype)
    if type(base.prototype.__index) == "function" then
        target.prototype.__index = base.prototype.__index
    end
    if type(base.prototype.__newindex) == "function" then
        target.prototype.__newindex = base.prototype.__newindex
    end
    if type(base.prototype.__tostring) == "function" then
        target.prototype.__tostring = base.prototype.__tostring
    end
end

local Error, RangeError, ReferenceError, SyntaxError, TypeError, URIError
do
    local function getErrorStack(self, constructor)
        if debug == nil then
            return nil
        end
        local level = 1
        while true do
            local info = debug.getinfo(level, "f")
            level = level + 1
            if not info then
                level = 1
                break
            elseif info.func == constructor then
                break
            end
        end
        if __TS__StringIncludes(_VERSION, "Lua 5.0") then
            return debug.traceback(("[Level " .. tostring(level)) .. "]")
        else
            return debug.traceback(nil, level)
        end
    end
    local function wrapErrorToString(self, getDescription)
        return function(self)
            local description = getDescription(self)
            local caller = debug.getinfo(3, "f")
            local isClassicLua = __TS__StringIncludes(_VERSION, "Lua 5.0") or _VERSION == "Lua 5.1"
            if isClassicLua or caller and caller.func ~= error then
                return description
            else
                return (description .. "\n") .. tostring(self.stack)
            end
        end
    end
    local function initErrorClass(self, Type, name)
        Type.name = name
        return setmetatable(
            Type,
            {__call = function(____, _self, message) return __TS__New(Type, message) end}
        )
    end
    local ____initErrorClass_1 = initErrorClass
    local ____class_0 = __TS__Class()
    ____class_0.name = ""
    function ____class_0.prototype.____constructor(self, message)
        if message == nil then
            message = ""
        end
        self.message = message
        self.name = "Error"
        self.stack = getErrorStack(nil, self.constructor.new)
        local metatable = getmetatable(self)
        if metatable and not metatable.__errorToStringPatched then
            metatable.__errorToStringPatched = true
            metatable.__tostring = wrapErrorToString(nil, metatable.__tostring)
        end
    end
    function ____class_0.prototype.__tostring(self)
        return self.message ~= "" and (self.name .. ": ") .. self.message or self.name
    end
    Error = ____initErrorClass_1(nil, ____class_0, "Error")
    local function createErrorClass(self, name)
        local ____initErrorClass_3 = initErrorClass
        local ____class_2 = __TS__Class()
        ____class_2.name = ____class_2.name
        __TS__ClassExtends(____class_2, Error)
        function ____class_2.prototype.____constructor(self, ...)
            ____class_2.____super.prototype.____constructor(self, ...)
            self.name = name
        end
        return ____initErrorClass_3(nil, ____class_2, name)
    end
    RangeError = createErrorClass(nil, "RangeError")
    ReferenceError = createErrorClass(nil, "ReferenceError")
    SyntaxError = createErrorClass(nil, "SyntaxError")
    TypeError = createErrorClass(nil, "TypeError")
    URIError = createErrorClass(nil, "URIError")
end

local function __TS__ObjectGetOwnPropertyDescriptors(object)
    local metatable = getmetatable(object)
    if not metatable then
        return {}
    end
    return rawget(metatable, "_descriptors") or ({})
end

local function __TS__Delete(target, key)
    local descriptors = __TS__ObjectGetOwnPropertyDescriptors(target)
    local descriptor = descriptors[key]
    if descriptor then
        if not descriptor.configurable then
            error(
                __TS__New(
                    TypeError,
                    ((("Cannot delete property " .. tostring(key)) .. " of ") .. tostring(target)) .. "."
                ),
                0
            )
        end
        descriptors[key] = nil
        return true
    end
    target[key] = nil
    return true
end

return {
  __TS__SourceMapTraceBack = __TS__SourceMapTraceBack,
  __TS__Iterator = __TS__Iterator,
  __TS__Class = __TS__Class,
  __TS__New = __TS__New,
  __TS__ArrayForEach = __TS__ArrayForEach,
  __TS__Delete = __TS__Delete
}
 end,
["src.utils"] = function(...) 
local ____lualib = require("lualib_bundle")
local __TS__SourceMapTraceBack = ____lualib.__TS__SourceMapTraceBack
local ____exports = {}
local getLogLevelString, logLevel
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
function ____exports.PrintEcho(self, message, level)
    if level >= logLevel then
        Printf((("[AZ" .. getLogLevelString(nil, level)) .. "] ") .. message)
    end
end
logLevel = 1
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
    ____exports.PrintEcho(
        nil,
        "Log level set to " .. getLogLevelString(nil, logLevel),
        10
    )
end
function ____exports.PrintLogLevel(self)
    ____exports.PrintEcho(
        nil,
        "Log level is " .. getLogLevelString(nil, logLevel),
        10
    )
end
return ____exports
 end,
["src.calculate-zoom-iris"] = function(...) 
local ____lualib = require("lualib_bundle")
local __TS__SourceMapTraceBack = ____lualib.__TS__SourceMapTraceBack
local ____exports = {}
local function getFaderValue(self, min, max, value)
    return (value - min) / (max - min) * 100
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
            iris = 0
        }
    elseif angle < opticalParameters.zoom.min then
        local zoomBeamSize = getBeamSizeAtTarget(nil, opticalParameters.zoom.min, distance)
        if opticalParameters.iris.min == opticalParameters.iris.max then
            return {zoom = 0, iris = -1}
        end
        local irisLevel = getFaderValue(nil, opticalParameters.iris.min, opticalParameters.iris.max, targetBeamDiameter / zoomBeamSize)
        return {zoom = 0, iris = irisLevel}
    else
        return {zoom = 100, iris = 0}
    end
end
return ____exports
 end,
["src.handle-execs"] = function(...) 
local ____lualib = require("lualib_bundle")
local __TS__Iterator = ____lualib.__TS__Iterator
local __TS__SourceMapTraceBack = ____lualib.__TS__SourceMapTraceBack
local ____exports = {}
local getSeqHandleFromName
local ____utils = require("src.utils")
local PrintEcho = ____utils.PrintEcho
function getSeqHandleFromName(self, seqName)
    for ____, datapool in ipairs(ShowData().DataPools) do
        for ____, seq in __TS__Iterator(datapool.Sequences) do
            if seq.Name == seqName then
                return seq
            end
        end
        return nil
    end
end
function ____exports.moveFaderGMA3(self, faderName, level)
    PrintEcho(
        nil,
        (("Moving fader " .. faderName) .. " to ") .. tostring(level),
        0
    )
    local seq = getSeqHandleFromName(nil, faderName)
    seq:SetFader({value = level})
end
return ____exports
 end,
["src.types"] = function(...) 
local ____lualib = require("lualib_bundle")
local __TS__Class = ____lualib.__TS__Class
local __TS__New = ____lualib.__TS__New
local __TS__SourceMapTraceBack = ____lualib.__TS__SourceMapTraceBack
local ____exports = {}
local ____calculate_2Dzoom_2Diris = require("src.calculate-zoom-iris")
local calculateZoomIrisFaderValues = ____calculate_2Dzoom_2Diris.calculateZoomIrisFaderValues
local ____handle_2Dexecs = require("src.handle-execs")
local moveFaderGMA3 = ____handle_2Dexecs.moveFaderGMA3
local ____utils = require("src.utils")
local PrintEcho = ____utils.PrintEcho
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
function AZ_FixtureType.prototype.print(self, level)
    PrintEcho(nil, ((("Fixture Type: " .. self.name) .. " is in ") .. self.mode) .. " mode", level)
    PrintEcho(
        nil,
        (("Optical Parameters: Zoom min: " .. tostring(self.opticalParameters.zoom.min)) .. " max: ") .. tostring(self.opticalParameters.zoom.max),
        level
    )
    PrintEcho(
        nil,
        (("Optical Parameters: Iris min: " .. tostring(self.opticalParameters.iris.min)) .. " max: ") .. tostring(self.opticalParameters.iris.max),
        level
    )
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
    self.lastZoom = 0
    self.lastIris = 0
end
function AZ_Fixture.prototype.print(self, level)
    PrintEcho(
        nil,
        ((((((((("Fixture: " .. tostring(self.fid)) .. "  -  ") .. self.name) .. " at position (") .. tostring(self.position.x)) .. ", ") .. tostring(self.position.y)) .. ", ") .. tostring(self.position.z)) .. ")",
        level
    )
    self.fixtureType:print(level)
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
    if math.floor(targetZI.iris + 0.5) ~= self.lastIris and targetZI.iris ~= -1 then
        moveFaderGMA3(
            nil,
            self:getIrisFader(),
            math.floor(targetZI.iris + 0.5)
        )
        self.lastIris = math.floor(targetZI.iris + 0.5)
    end
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
    self.fid = fid
    self.cid = cid
    self.name = name
    self.handle = handle
    self.position = __TS__New(____exports.Vector3, 0, 0, 0)
end
function AZ_Marker.prototype.print(self, level)
    PrintEcho(
        nil,
        (("Marker: " .. tostring(self.fid)) .. " - ") .. self.name,
        level
    )
end
function AZ_Marker.prototype.update(self)
    local PSNProtocol = ShowData().PSNProtocol
    do
        local i = 1
        while i <= PSNProtocol.count do
            local trackingSystem = PSNProtocol[i]
            do
                local j = 1
                while j <= trackingSystem.count do
                    local tracker = trackingSystem[j]
                    if tracker.MARKERID == self.cid then
                        self.position.x = tracker.POSITIONX
                        self.position.y = tracker.POSITIONY
                        self.position.z = tracker.POSITIONZ
                        return
                    end
                    j = j + 1
                end
            end
            i = i + 1
        end
    end
end
____exports.AZ_EnabledFixture = __TS__Class()
local AZ_EnabledFixture = ____exports.AZ_EnabledFixture
AZ_EnabledFixture.name = "AZ_EnabledFixture"
function AZ_EnabledFixture.prototype.____constructor(self, fixture, marker, beamSize)
    self.fixture = fixture
    self.marker = marker
    self.beamSize = beamSize
end
function AZ_EnabledFixture.prototype.Update(self)
    local targetZoomIris = calculateZoomIrisFaderValues(
        nil,
        self.fixture.position,
        self.marker.position,
        self.fixture.fixtureType.opticalParameters,
        self.beamSize
    )
    self.fixture:updateTo(targetZoomIris)
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
        PrintEcho(nil, "No stages found", 3)
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
["src.autozoom_object"] = function(...) 
local ____lualib = require("lualib_bundle")
local __TS__Class = ____lualib.__TS__Class
local __TS__New = ____lualib.__TS__New
local __TS__Delete = ____lualib.__TS__Delete
local __TS__SourceMapTraceBack = ____lualib.__TS__SourceMapTraceBack
local ____exports = {}
local ____utils = require("src.utils")
local PrintEcho = ____utils.PrintEcho
local PrintLogLevel = ____utils.PrintLogLevel
local SetLogLevel = ____utils.SetLogLevel
local ____load_2Dpatch = require("src.load-patch")
local fetchFixtures = ____load_2Dpatch.fetchFixtures
local loadFixtureTypes = ____load_2Dpatch.loadFixtureTypes
local ____types = require("src.types")
local AZ_EnabledFixture = ____types.AZ_EnabledFixture
local ____handle_2Dexecs = require("src.handle-execs")
local moveFaderGMA3 = ____handle_2Dexecs.moveFaderGMA3
____exports.AZ_Global_Type = __TS__Class()
local AZ_Global_Type = ____exports.AZ_Global_Type
AZ_Global_Type.name = "AZ_Global_Type"
function AZ_Global_Type.prototype.____constructor(self)
    self.refreshRate = 30
    self.initialized = false
    self.expected_remaining_update = 0
    self.global_call_repeat = 10
    self.patch_info = {fixtures = {}, markers = {}}
    self.enabledFixtures = {}
    self.enabled = false
    PrintEcho(nil, "AZ created, patch_info", 10)
end
function AZ_Global_Type.prototype.PrintLength(self)
    PrintEcho(
        nil,
        tostring(#self.patch_info.fixtures),
        10
    )
    PrintEcho(
        nil,
        tostring(#self.patch_info.markers),
        10
    )
end
function AZ_Global_Type.prototype.ShowEnabled(self)
    if self.enabled then
        PrintEcho(nil, "AutoZoom is enabled", 10)
    else
        PrintEcho(nil, "AutoZoom is disabled", 10)
    end
end
function AZ_Global_Type.prototype.Enable(self)
    if not self.initialized then
        self:Start()
    end
    if not self.enabled then
        PrintEcho(nil, "Enabling Plugin AutoZoom", 10)
        self.enabled = true
    end
    self:ShowEnabled()
    self:RegisterUpdateLoop()
end
function AZ_Global_Type.prototype.Disable(self)
    if self.enabled then
        PrintEcho(nil, "Disabling Plugin AutoZoom", 10)
        self.enabled = false
    end
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
    self.patch_info = {fixtures = {}, markers = {}}
    local fixtureTypes_in_XYZ = loadFixtureTypes(nil)
    local fixture_and_markers = fetchFixtures(nil, fixtureTypes_in_XYZ)
    PrintEcho(nil, "--- Scanned all fixtures that have XYZ", 1)
    self.patch_info = {fixtures = fixture_and_markers.fixtures, markers = fixture_and_markers.markers}
    PrintEcho(
        nil,
        ((("--- Patch fetched - found " .. tostring(#self.patch_info.fixtures)) .. " fixtures and ") .. tostring(#self.patch_info.markers)) .. " markers.",
        10
    )
end
function AZ_Global_Type.prototype.PrintCurrentPatch(self)
    if not self then
        PrintEcho(nil, "AZ is not defined", 3)
        return
    end
    if not self.patch_info then
        PrintEcho(nil, "Patch is not defined", 3)
        return
    end
    if self.patch_info == nil then
        PrintEcho(nil, "Nothing is defined, problem...", 3)
        return
    end
    if self.patch_info.fixtures == nil then
        PrintEcho(nil, "Fixtures aren't defined, problem...", 3)
        return
    end
    if self.patch_info.markers == nil then
        PrintEcho(nil, "Markers aren't defined, problem...", 3)
        return
    end
    if #self.patch_info.fixtures == 0 then
        PrintEcho(nil, "No fixtures in patch", 3)
        return
    end
    if #self.patch_info.markers == 0 then
        PrintEcho(nil, "No markers in patch", 3)
        return
    end
    PrintEcho(nil, "Current Patch", 10)
    PrintEcho(nil, "Fixtures", 10)
    for ____, fixture in ipairs(self.patch_info.fixtures) do
        fixture:print(10)
    end
    PrintEcho(nil, "Markers", 10)
    for ____, marker in ipairs(self.patch_info.markers) do
        marker:print(10)
    end
end
function AZ_Global_Type.prototype.GetFixturesStatus(self)
    for ____, enabledFixture in ipairs(self.enabledFixtures) do
        PrintEcho(
            nil,
            (((("Fixture " .. tostring(enabledFixture.fixture.fid)) .. " -> ") .. tostring(enabledFixture.marker.fid)) .. " | beamsize : ") .. tostring(enabledFixture.beamSize),
            10
        )
    end
end
function AZ_Global_Type.prototype.EnableFixture(self, fixtureid, markerid, beamSize)
    if not self.patch_info.fixtures then
        PrintEcho(nil, "Patch is not defined", 10)
    end
    if #self.patch_info.fixtures == 0 then
        PrintEcho(nil, "No fixtures in patch", 10)
        return
    end
    if #self.patch_info.markers == 0 then
        PrintEcho(nil, "No markers in patch", 10)
        return
    end
    for ____, fixture in ipairs(self.patch_info.fixtures) do
        if fixture.fid == fixtureid then
            for ____, marker in ipairs(self.patch_info.markers) do
                if marker.fid == markerid then
                    local enabledFixture = __TS__New(AZ_EnabledFixture, fixture, marker, beamSize)
                    do
                        local i = 0
                        while i < #self.enabledFixtures do
                            if self.enabledFixtures[i + 1].fixture.fid == fixtureid then
                                self.enabledFixtures[i + 1].marker = marker
                                self.enabledFixtures[i + 1].beamSize = beamSize
                                PrintEcho(
                                    nil,
                                    (((((("Updated fixture " .. tostring(fixtureid)) .. " - Marker : ") .. tostring(marker.fid)) .. " - ") .. tostring(marker.cid)) .. " |  Beam size : ") .. tostring(beamSize),
                                    10
                                )
                                return
                            end
                            i = i + 1
                        end
                    end
                    local ____self_enabledFixtures_0 = self.enabledFixtures
                    ____self_enabledFixtures_0[#____self_enabledFixtures_0 + 1] = enabledFixture
                    PrintEcho(
                        nil,
                        (((("Enabled fixture " .. tostring(fixtureid)) .. " - Marker : ") .. tostring(marker.fid)) .. " |  Beam size : ") .. tostring(beamSize),
                        10
                    )
                    return
                end
            end
            PrintEcho(
                nil,
                ("No marker with id " .. tostring(markerid)) .. " found",
                10
            )
            return
        end
    end
    PrintEcho(
        nil,
        ("No fixture with id " .. tostring(fixtureid)) .. " found",
        10
    )
end
function AZ_Global_Type.prototype.DisableFixture(self, fixtureid)
    do
        local i = 0
        while i < #self.enabledFixtures do
            if self.enabledFixtures[i + 1].fixture.fid == fixtureid then
                __TS__Delete(self.enabledFixtures, i + 1)
                PrintEcho(
                    nil,
                    "Disabled fixture " .. tostring(fixtureid),
                    10
                )
                return
            end
            i = i + 1
        end
    end
    PrintEcho(
        nil,
        ("Fixture " .. tostring(fixtureid)) .. " was not enabled",
        10
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
    PrintEcho(nil, "Disabled all fixtures", 10)
end
function AZ_Global_Type.prototype.UpdateMarkers(self)
    for ____, marker in ipairs(self.patch_info.markers) do
        marker:update()
    end
end
function AZ_Global_Type.prototype.UpdateFixtures(self)
    for ____, enabledFixture in ipairs(self.enabledFixtures) do
        enabledFixture:Update()
    end
end
function AZ_Global_Type.prototype.UpdateLoop(self)
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
    PrintEcho(
        nil,
        ("Set refresh rate to " .. tostring(rate)) .. " updates/second",
        10
    )
end
function AZ_Global_Type.prototype.RegisterUpdateLoop(self)
    if not self.enabled then
        PrintEcho(nil, "Autozoom is disabled, failed to start loop", 10)
        return
    end
    local updatePeriod = 1 / self.refreshRate
    if self.expected_remaining_update > 0 then
        PrintEcho(
            nil,
            "Update loop is already registered, expected remaining update " .. tostring(self.expected_remaining_update),
            2
        )
        return
    end
    self.global_call_repeat = self.refreshRate * 10
    self.expected_remaining_update = self.global_call_repeat
    Timer(
        function()
            self:UpdateLoop()
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
    PrintEcho(nil, "Plugin GRANDMA3 AUTOZOOM launched ", 10)
    PrintEcho(nil, "Plugin version : 0.1", 10)
    PrintEcho(nil, "Plugin author : Naostage 2024", 10)
    PrintEcho(nil, "", 10)
    self:ScanPatch()
    self:ShowEnabled()
end
function AZ_Global_Type.prototype.Cleanup(self)
    self.expected_remaining_update = 0
    self.global_call_repeat = 0
    self.enabled = false
    PrintEcho(nil, "Plugin GRANDMA3 AUTOZOOM stopped", 10)
end
function AZ_Global_Type.prototype.TestMoveFader(self, ExecName, value)
    PrintEcho(
        nil,
        (("Trying to move fader " .. ExecName) .. " to ") .. tostring(value),
        10
    )
    moveFaderGMA3(nil, ExecName, value)
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
        AZ:DisableAllFixtures()
        AZ:Cleanup()
        AZ:Disable()
    end
    AZ = __TS__New(AZ_Global_Type)
    AZ:Init()
end
return main
 end,
}
local __TS__SourceMapTraceBack = require("lualib_bundle").__TS__SourceMapTraceBack
__TS__SourceMapTraceBack(debug.getinfo(1).short_src, {["318"] = {line = 25, file = "utils.ts"},["319"] = {line = 25, file = "utils.ts"},["321"] = {line = 26, file = "utils.ts"},["322"] = {line = 27, file = "utils.ts"},["324"] = {line = 28, file = "utils.ts"},["326"] = {line = 29, file = "utils.ts"},["328"] = {line = 30, file = "utils.ts"},["330"] = {line = 31, file = "utils.ts"},["332"] = {line = 32, file = "utils.ts"},["334"] = {line = 33, file = "utils.ts"},["336"] = {line = 34, file = "utils.ts"},["339"] = {line = 36, file = "utils.ts"},["343"] = {line = 43, file = "utils.ts"},["344"] = {line = 44, file = "utils.ts"},["345"] = {line = 45, file = "utils.ts"},["347"] = {line = 43, file = "utils.ts"},["348"] = {line = 2, file = "utils.ts"},["349"] = {line = 4, file = "utils.ts"},["351"] = {line = 5, file = "utils.ts"},["352"] = {line = 6, file = "utils.ts"},["354"] = {line = 7, file = "utils.ts"},["357"] = {line = 9, file = "utils.ts"},["359"] = {line = 10, file = "utils.ts"},["362"] = {line = 12, file = "utils.ts"},["364"] = {line = 13, file = "utils.ts"},["367"] = {line = 15, file = "utils.ts"},["369"] = {line = 16, file = "utils.ts"},["373"] = {line = 19, file = "utils.ts"},["377"] = {line = 22, file = "utils.ts"},["378"] = {line = 22, file = "utils.ts"},["379"] = {line = 22, file = "utils.ts"},["380"] = {line = 22, file = "utils.ts"},["381"] = {line = 22, file = "utils.ts"},["382"] = {line = 4, file = "utils.ts"},["383"] = {line = 40, file = "utils.ts"},["384"] = {line = 41, file = "utils.ts"},["385"] = {line = 41, file = "utils.ts"},["386"] = {line = 41, file = "utils.ts"},["387"] = {line = 41, file = "utils.ts"},["388"] = {line = 41, file = "utils.ts"},["389"] = {line = 40, file = "utils.ts"},["396"] = {line = 10, file = "calculate-zoom-iris.ts"},["397"] = {line = 11, file = "calculate-zoom-iris.ts"},["398"] = {line = 10, file = "calculate-zoom-iris.ts"},["399"] = {line = 15, file = "calculate-zoom-iris.ts"},["400"] = {line = 18, file = "calculate-zoom-iris.ts"},["401"] = {line = 19, file = "calculate-zoom-iris.ts"},["402"] = {line = 15, file = "calculate-zoom-iris.ts"},["403"] = {line = 23, file = "calculate-zoom-iris.ts"},["404"] = {line = 32, file = "calculate-zoom-iris.ts"},["405"] = {line = 35, file = "calculate-zoom-iris.ts"},["406"] = {line = 39, file = "calculate-zoom-iris.ts"},["407"] = {line = 41, file = "calculate-zoom-iris.ts"},["408"] = {line = 41, file = "calculate-zoom-iris.ts"},["409"] = {line = 41, file = "calculate-zoom-iris.ts"},["410"] = {line = 41, file = "calculate-zoom-iris.ts"},["411"] = {line = 44, file = "calculate-zoom-iris.ts"},["412"] = {line = 45, file = "calculate-zoom-iris.ts"},["413"] = {line = 46, file = "calculate-zoom-iris.ts"},["414"] = {line = 47, file = "calculate-zoom-iris.ts"},["416"] = {line = 49, file = "calculate-zoom-iris.ts"},["417"] = {line = 50, file = "calculate-zoom-iris.ts"},["419"] = {line = 54, file = "calculate-zoom-iris.ts"},["421"] = {line = 23, file = "calculate-zoom-iris.ts"},["429"] = {line = 12, file = "handle-execs.ts"},["430"] = {line = 1, file = "handle-execs.ts"},["431"] = {line = 1, file = "handle-execs.ts"},["432"] = {line = 12, file = "handle-execs.ts"},["433"] = {line = 13, file = "handle-execs.ts"},["434"] = {line = 15, file = "handle-execs.ts"},["435"] = {line = 16, file = "handle-execs.ts"},["436"] = {line = 17, file = "handle-execs.ts"},["439"] = {line = 20, file = "handle-execs.ts"},["442"] = {line = 3, file = "handle-execs.ts"},["443"] = {line = 4, file = "handle-execs.ts"},["444"] = {line = 4, file = "handle-execs.ts"},["445"] = {line = 4, file = "handle-execs.ts"},["446"] = {line = 4, file = "handle-execs.ts"},["447"] = {line = 4, file = "handle-execs.ts"},["448"] = {line = 6, file = "handle-execs.ts"},["449"] = {line = 7, file = "handle-execs.ts"},["450"] = {line = 3, file = "handle-execs.ts"},["459"] = {line = 1, file = "types.ts"},["460"] = {line = 1, file = "types.ts"},["461"] = {line = 2, file = "types.ts"},["462"] = {line = 2, file = "types.ts"},["463"] = {line = 4, file = "types.ts"},["464"] = {line = 4, file = "types.ts"},["465"] = {line = 6, file = "types.ts"},["466"] = {line = 6, file = "types.ts"},["467"] = {line = 6, file = "types.ts"},["468"] = {line = 11, file = "types.ts"},["469"] = {line = 12, file = "types.ts"},["470"] = {line = 13, file = "types.ts"},["471"] = {line = 14, file = "types.ts"},["472"] = {line = 11, file = "types.ts"},["473"] = {line = 17, file = "types.ts"},["474"] = {line = 18, file = "types.ts"},["475"] = {line = 17, file = "types.ts"},["476"] = {line = 21, file = "types.ts"},["477"] = {line = 22, file = "types.ts"},["478"] = {line = 21, file = "types.ts"},["479"] = {line = 36, file = "types.ts"},["480"] = {line = 36, file = "types.ts"},["481"] = {line = 36, file = "types.ts"},["482"] = {line = 41, file = "types.ts"},["483"] = {line = 42, file = "types.ts"},["484"] = {line = 43, file = "types.ts"},["485"] = {line = 44, file = "types.ts"},["486"] = {line = 45, file = "types.ts"},["487"] = {line = 41, file = "types.ts"},["488"] = {line = 48, file = "types.ts"},["489"] = {line = 49, file = "types.ts"},["490"] = {line = 50, file = "types.ts"},["491"] = {line = 50, file = "types.ts"},["492"] = {line = 50, file = "types.ts"},["493"] = {line = 50, file = "types.ts"},["494"] = {line = 50, file = "types.ts"},["495"] = {line = 51, file = "types.ts"},["496"] = {line = 51, file = "types.ts"},["497"] = {line = 51, file = "types.ts"},["498"] = {line = 51, file = "types.ts"},["499"] = {line = 51, file = "types.ts"},["500"] = {line = 48, file = "types.ts"},["501"] = {line = 55, file = "types.ts"},["502"] = {line = 55, file = "types.ts"},["503"] = {line = 55, file = "types.ts"},["504"] = {line = 63, file = "types.ts"},["505"] = {line = 64, file = "types.ts"},["506"] = {line = 65, file = "types.ts"},["507"] = {line = 66, file = "types.ts"},["508"] = {line = 67, file = "types.ts"},["509"] = {line = 68, file = "types.ts"},["510"] = {line = 69, file = "types.ts"},["511"] = {line = 70, file = "types.ts"},["512"] = {line = 63, file = "types.ts"},["513"] = {line = 73, file = "types.ts"},["514"] = {line = 74, file = "types.ts"},["515"] = {line = 74, file = "types.ts"},["516"] = {line = 74, file = "types.ts"},["517"] = {line = 74, file = "types.ts"},["518"] = {line = 74, file = "types.ts"},["519"] = {line = 75, file = "types.ts"},["520"] = {line = 73, file = "types.ts"},["521"] = {line = 78, file = "types.ts"},["522"] = {line = 79, file = "types.ts"},["523"] = {line = 80, file = "types.ts"},["524"] = {line = 80, file = "types.ts"},["525"] = {line = 80, file = "types.ts"},["526"] = {line = 80, file = "types.ts"},["527"] = {line = 80, file = "types.ts"},["528"] = {line = 81, file = "types.ts"},["530"] = {line = 83, file = "types.ts"},["531"] = {line = 84, file = "types.ts"},["532"] = {line = 84, file = "types.ts"},["533"] = {line = 84, file = "types.ts"},["534"] = {line = 84, file = "types.ts"},["535"] = {line = 84, file = "types.ts"},["536"] = {line = 85, file = "types.ts"},["538"] = {line = 78, file = "types.ts"},["539"] = {line = 89, file = "types.ts"},["540"] = {line = 90, file = "types.ts"},["541"] = {line = 89, file = "types.ts"},["542"] = {line = 92, file = "types.ts"},["543"] = {line = 93, file = "types.ts"},["544"] = {line = 92, file = "types.ts"},["545"] = {line = 97, file = "types.ts"},["546"] = {line = 97, file = "types.ts"},["547"] = {line = 97, file = "types.ts"},["548"] = {line = 104, file = "types.ts"},["549"] = {line = 105, file = "types.ts"},["550"] = {line = 106, file = "types.ts"},["551"] = {line = 107, file = "types.ts"},["552"] = {line = 108, file = "types.ts"},["553"] = {line = 109, file = "types.ts"},["554"] = {line = 104, file = "types.ts"},["555"] = {line = 112, file = "types.ts"},["556"] = {line = 113, file = "types.ts"},["557"] = {line = 113, file = "types.ts"},["558"] = {line = 113, file = "types.ts"},["559"] = {line = 113, file = "types.ts"},["560"] = {line = 113, file = "types.ts"},["561"] = {line = 112, file = "types.ts"},["562"] = {line = 116, file = "types.ts"},["563"] = {line = 119, file = "types.ts"},["565"] = {line = 120, file = "types.ts"},["566"] = {line = 120, file = "types.ts"},["567"] = {line = 121, file = "types.ts"},["569"] = {line = 123, file = "types.ts"},["570"] = {line = 123, file = "types.ts"},["571"] = {line = 125, file = "types.ts"},["572"] = {line = 126, file = "types.ts"},["573"] = {line = 127, file = "types.ts"},["574"] = {line = 128, file = "types.ts"},["575"] = {line = 129, file = "types.ts"},["578"] = {line = 123, file = "types.ts"},["581"] = {line = 120, file = "types.ts"},["584"] = {line = 116, file = "types.ts"},["585"] = {line = 143, file = "types.ts"},["586"] = {line = 143, file = "types.ts"},["587"] = {line = 143, file = "types.ts"},["588"] = {line = 148, file = "types.ts"},["589"] = {line = 149, file = "types.ts"},["590"] = {line = 150, file = "types.ts"},["591"] = {line = 151, file = "types.ts"},["592"] = {line = 148, file = "types.ts"},["593"] = {line = 154, file = "types.ts"},["594"] = {line = 155, file = "types.ts"},["595"] = {line = 155, file = "types.ts"},["596"] = {line = 155, file = "types.ts"},["597"] = {line = 155, file = "types.ts"},["598"] = {line = 155, file = "types.ts"},["599"] = {line = 155, file = "types.ts"},["600"] = {line = 155, file = "types.ts"},["601"] = {line = 157, file = "types.ts"},["602"] = {line = 154, file = "types.ts"},["611"] = {line = 2, file = "load-patch.ts"},["612"] = {line = 2, file = "load-patch.ts"},["613"] = {line = 2, file = "load-patch.ts"},["614"] = {line = 2, file = "load-patch.ts"},["615"] = {line = 2, file = "load-patch.ts"},["616"] = {line = 3, file = "load-patch.ts"},["617"] = {line = 3, file = "load-patch.ts"},["618"] = {line = 21, file = "load-patch.ts"},["619"] = {line = 22, file = "load-patch.ts"},["620"] = {line = 23, file = "load-patch.ts"},["621"] = {line = 24, file = "load-patch.ts"},["622"] = {line = 24, file = "load-patch.ts"},["623"] = {line = 24, file = "load-patch.ts"},["624"] = {line = 26, file = "load-patch.ts"},["627"] = {line = 31, file = "load-patch.ts"},["628"] = {line = 32, file = "load-patch.ts"},["629"] = {line = 33, file = "load-patch.ts"},["631"] = {line = 24, file = "load-patch.ts"},["632"] = {line = 24, file = "load-patch.ts"},["633"] = {line = 37, file = "load-patch.ts"},["634"] = {line = 37, file = "load-patch.ts"},["635"] = {line = 37, file = "load-patch.ts"},["636"] = {line = 37, file = "load-patch.ts"},["637"] = {line = 21, file = "load-patch.ts"},["638"] = {line = 40, file = "load-patch.ts"},["639"] = {line = 41, file = "load-patch.ts"},["640"] = {line = 42, file = "load-patch.ts"},["641"] = {line = 43, file = "load-patch.ts"},["642"] = {line = 43, file = "load-patch.ts"},["643"] = {line = 43, file = "load-patch.ts"},["644"] = {line = 45, file = "load-patch.ts"},["647"] = {line = 50, file = "load-patch.ts"},["648"] = {line = 51, file = "load-patch.ts"},["649"] = {line = 52, file = "load-patch.ts"},["651"] = {line = 43, file = "load-patch.ts"},["652"] = {line = 43, file = "load-patch.ts"},["653"] = {line = 55, file = "load-patch.ts"},["654"] = {line = 56, file = "load-patch.ts"},["656"] = {line = 58, file = "load-patch.ts"},["657"] = {line = 59, file = "load-patch.ts"},["659"] = {line = 61, file = "load-patch.ts"},["660"] = {line = 61, file = "load-patch.ts"},["661"] = {line = 61, file = "load-patch.ts"},["662"] = {line = 61, file = "load-patch.ts"},["663"] = {line = 40, file = "load-patch.ts"},["664"] = {line = 64, file = "load-patch.ts"},["665"] = {line = 65, file = "load-patch.ts"},["666"] = {line = 66, file = "load-patch.ts"},["667"] = {line = 67, file = "load-patch.ts"},["668"] = {line = 68, file = "load-patch.ts"},["670"] = {line = 70, file = "load-patch.ts"},["671"] = {line = 71, file = "load-patch.ts"},["672"] = {line = 72, file = "load-patch.ts"},["673"] = {line = 70, file = "load-patch.ts"},["674"] = {line = 64, file = "load-patch.ts"},["675"] = {line = 76, file = "load-patch.ts"},["676"] = {line = 77, file = "load-patch.ts"},["677"] = {line = 78, file = "load-patch.ts"},["678"] = {line = 81, file = "load-patch.ts"},["679"] = {line = 81, file = "load-patch.ts"},["680"] = {line = 81, file = "load-patch.ts"},["681"] = {line = 82, file = "load-patch.ts"},["682"] = {line = 83, file = "load-patch.ts"},["683"] = {line = 84, file = "load-patch.ts"},["685"] = {line = 86, file = "load-patch.ts"},["686"] = {line = 86, file = "load-patch.ts"},["687"] = {line = 86, file = "load-patch.ts"},["688"] = {line = 88, file = "load-patch.ts"},["689"] = {line = 89, file = "load-patch.ts"},["690"] = {line = 90, file = "load-patch.ts"},["691"] = {line = 91, file = "load-patch.ts"},["692"] = {line = 92, file = "load-patch.ts"},["693"] = {line = 92, file = "load-patch.ts"},["694"] = {line = 92, file = "load-patch.ts"},["695"] = {line = 92, file = "load-patch.ts"},["696"] = {line = 92, file = "load-patch.ts"},["697"] = {line = 92, file = "load-patch.ts"},["698"] = {line = 92, file = "load-patch.ts"},["699"] = {line = 93, file = "load-patch.ts"},["701"] = {line = 86, file = "load-patch.ts"},["702"] = {line = 86, file = "load-patch.ts"},["703"] = {line = 81, file = "load-patch.ts"},["704"] = {line = 81, file = "load-patch.ts"},["705"] = {line = 97, file = "load-patch.ts"},["706"] = {line = 76, file = "load-patch.ts"},["707"] = {line = 100, file = "load-patch.ts"},["708"] = {line = 101, file = "load-patch.ts"},["709"] = {line = 100, file = "load-patch.ts"},["710"] = {line = 104, file = "load-patch.ts"},["711"] = {line = 106, file = "load-patch.ts"},["712"] = {line = 107, file = "load-patch.ts"},["713"] = {line = 107, file = "load-patch.ts"},["714"] = {line = 108, file = "load-patch.ts"},["715"] = {line = 108, file = "load-patch.ts"},["716"] = {line = 108, file = "load-patch.ts"},["717"] = {line = 108, file = "load-patch.ts"},["718"] = {line = 107, file = "load-patch.ts"},["719"] = {line = 110, file = "load-patch.ts"},["722"] = {line = 115, file = "load-patch.ts"},["725"] = {line = 118, file = "load-patch.ts"},["726"] = {line = 119, file = "load-patch.ts"},["727"] = {line = 121, file = "load-patch.ts"},["728"] = {line = 124, file = "load-patch.ts"},["730"] = {line = 126, file = "load-patch.ts"},["731"] = {line = 126, file = "load-patch.ts"},["732"] = {line = 127, file = "load-patch.ts"},["733"] = {line = 127, file = "load-patch.ts"},["734"] = {line = 127, file = "load-patch.ts"},["735"] = {line = 127, file = "load-patch.ts"},["736"] = {line = 127, file = "load-patch.ts"},["737"] = {line = 127, file = "load-patch.ts"},["738"] = {line = 127, file = "load-patch.ts"},["739"] = {line = 126, file = "load-patch.ts"},["743"] = {line = 133, file = "load-patch.ts"},["744"] = {line = 134, file = "load-patch.ts"},["745"] = {line = 134, file = "load-patch.ts"},["746"] = {line = 134, file = "load-patch.ts"},["747"] = {line = 135, file = "load-patch.ts"},["750"] = {line = 139, file = "load-patch.ts"},["752"] = {line = 134, file = "load-patch.ts"},["753"] = {line = 134, file = "load-patch.ts"},["754"] = {line = 141, file = "load-patch.ts"},["757"] = {line = 144, file = "load-patch.ts"},["760"] = {line = 147, file = "load-patch.ts"},["761"] = {line = 147, file = "load-patch.ts"},["762"] = {line = 147, file = "load-patch.ts"},["763"] = {line = 147, file = "load-patch.ts"},["764"] = {line = 147, file = "load-patch.ts"},["765"] = {line = 147, file = "load-patch.ts"},["766"] = {line = 147, file = "load-patch.ts"},["767"] = {line = 147, file = "load-patch.ts"},["768"] = {line = 149, file = "load-patch.ts"},["769"] = {line = 150, file = "load-patch.ts"},["772"] = {line = 104, file = "load-patch.ts"},["773"] = {line = 165, file = "load-patch.ts"},["774"] = {line = 166, file = "load-patch.ts"},["775"] = {line = 167, file = "load-patch.ts"},["776"] = {line = 168, file = "load-patch.ts"},["777"] = {line = 169, file = "load-patch.ts"},["778"] = {line = 170, file = "load-patch.ts"},["779"] = {line = 171, file = "load-patch.ts"},["781"] = {line = 173, file = "load-patch.ts"},["782"] = {line = 173, file = "load-patch.ts"},["783"] = {line = 173, file = "load-patch.ts"},["784"] = {line = 173, file = "load-patch.ts"},["785"] = {line = 173, file = "load-patch.ts"},["787"] = {line = 174, file = "load-patch.ts"},["788"] = {line = 174, file = "load-patch.ts"},["789"] = {line = 175, file = "load-patch.ts"},["790"] = {line = 175, file = "load-patch.ts"},["791"] = {line = 175, file = "load-patch.ts"},["792"] = {line = 175, file = "load-patch.ts"},["793"] = {line = 175, file = "load-patch.ts"},["794"] = {line = 176, file = "load-patch.ts"},["795"] = {line = 178, file = "load-patch.ts"},["797"] = {line = 179, file = "load-patch.ts"},["798"] = {line = 179, file = "load-patch.ts"},["799"] = {line = 180, file = "load-patch.ts"},["800"] = {line = 183, file = "load-patch.ts"},["801"] = {line = 183, file = "load-patch.ts"},["802"] = {line = 183, file = "load-patch.ts"},["803"] = {line = 183, file = "load-patch.ts"},["804"] = {line = 183, file = "load-patch.ts"},["805"] = {line = 183, file = "load-patch.ts"},["806"] = {line = 183, file = "load-patch.ts"},["807"] = {line = 179, file = "load-patch.ts"},["810"] = {line = 174, file = "load-patch.ts"},["813"] = {line = 186, file = "load-patch.ts"},["814"] = {line = 165, file = "load-patch.ts"},["824"] = {line = 1, file = "autozoom_object.ts"},["825"] = {line = 1, file = "autozoom_object.ts"},["826"] = {line = 1, file = "autozoom_object.ts"},["827"] = {line = 1, file = "autozoom_object.ts"},["828"] = {line = 2, file = "autozoom_object.ts"},["829"] = {line = 2, file = "autozoom_object.ts"},["830"] = {line = 2, file = "autozoom_object.ts"},["831"] = {line = 3, file = "autozoom_object.ts"},["832"] = {line = 3, file = "autozoom_object.ts"},["833"] = {line = 4, file = "autozoom_object.ts"},["834"] = {line = 4, file = "autozoom_object.ts"},["835"] = {line = 7, file = "autozoom_object.ts"},["836"] = {line = 7, file = "autozoom_object.ts"},["837"] = {line = 7, file = "autozoom_object.ts"},["839"] = {line = 12, file = "autozoom_object.ts"},["840"] = {line = 13, file = "autozoom_object.ts"},["841"] = {line = 193, file = "autozoom_object.ts"},["842"] = {line = 194, file = "autozoom_object.ts"},["843"] = {line = 16, file = "autozoom_object.ts"},["844"] = {line = 17, file = "autozoom_object.ts"},["845"] = {line = 18, file = "autozoom_object.ts"},["846"] = {line = 20, file = "autozoom_object.ts"},["847"] = {line = 15, file = "autozoom_object.ts"},["848"] = {line = 23, file = "autozoom_object.ts"},["849"] = {line = 24, file = "autozoom_object.ts"},["850"] = {line = 24, file = "autozoom_object.ts"},["851"] = {line = 24, file = "autozoom_object.ts"},["852"] = {line = 24, file = "autozoom_object.ts"},["853"] = {line = 24, file = "autozoom_object.ts"},["854"] = {line = 25, file = "autozoom_object.ts"},["855"] = {line = 25, file = "autozoom_object.ts"},["856"] = {line = 25, file = "autozoom_object.ts"},["857"] = {line = 25, file = "autozoom_object.ts"},["858"] = {line = 25, file = "autozoom_object.ts"},["859"] = {line = 23, file = "autozoom_object.ts"},["860"] = {line = 28, file = "autozoom_object.ts"},["861"] = {line = 29, file = "autozoom_object.ts"},["862"] = {line = 30, file = "autozoom_object.ts"},["864"] = {line = 32, file = "autozoom_object.ts"},["866"] = {line = 28, file = "autozoom_object.ts"},["867"] = {line = 35, file = "autozoom_object.ts"},["868"] = {line = 36, file = "autozoom_object.ts"},["869"] = {line = 37, file = "autozoom_object.ts"},["871"] = {line = 39, file = "autozoom_object.ts"},["872"] = {line = 40, file = "autozoom_object.ts"},["873"] = {line = 41, file = "autozoom_object.ts"},["875"] = {line = 43, file = "autozoom_object.ts"},["876"] = {line = 45, file = "autozoom_object.ts"},["877"] = {line = 35, file = "autozoom_object.ts"},["878"] = {line = 47, file = "autozoom_object.ts"},["879"] = {line = 48, file = "autozoom_object.ts"},["880"] = {line = 49, file = "autozoom_object.ts"},["881"] = {line = 51, file = "autozoom_object.ts"},["883"] = {line = 53, file = "autozoom_object.ts"},["884"] = {line = 47, file = "autozoom_object.ts"},["885"] = {line = 55, file = "autozoom_object.ts"},["886"] = {line = 56, file = "autozoom_object.ts"},["887"] = {line = 57, file = "autozoom_object.ts"},["889"] = {line = 59, file = "autozoom_object.ts"},["891"] = {line = 55, file = "autozoom_object.ts"},["892"] = {line = 62, file = "autozoom_object.ts"},["893"] = {line = 63, file = "autozoom_object.ts"},["894"] = {line = 64, file = "autozoom_object.ts"},["895"] = {line = 65, file = "autozoom_object.ts"},["896"] = {line = 66, file = "autozoom_object.ts"},["897"] = {line = 67, file = "autozoom_object.ts"},["898"] = {line = 68, file = "autozoom_object.ts"},["899"] = {line = 68, file = "autozoom_object.ts"},["900"] = {line = 68, file = "autozoom_object.ts"},["901"] = {line = 68, file = "autozoom_object.ts"},["902"] = {line = 68, file = "autozoom_object.ts"},["903"] = {line = 62, file = "autozoom_object.ts"},["904"] = {line = 71, file = "autozoom_object.ts"},["905"] = {line = 72, file = "autozoom_object.ts"},["906"] = {line = 73, file = "autozoom_object.ts"},["909"] = {line = 77, file = "autozoom_object.ts"},["910"] = {line = 78, file = "autozoom_object.ts"},["913"] = {line = 81, file = "autozoom_object.ts"},["914"] = {line = 82, file = "autozoom_object.ts"},["917"] = {line = 85, file = "autozoom_object.ts"},["918"] = {line = 86, file = "autozoom_object.ts"},["921"] = {line = 89, file = "autozoom_object.ts"},["922"] = {line = 90, file = "autozoom_object.ts"},["925"] = {line = 93, file = "autozoom_object.ts"},["926"] = {line = 94, file = "autozoom_object.ts"},["929"] = {line = 97, file = "autozoom_object.ts"},["930"] = {line = 98, file = "autozoom_object.ts"},["933"] = {line = 101, file = "autozoom_object.ts"},["934"] = {line = 102, file = "autozoom_object.ts"},["935"] = {line = 103, file = "autozoom_object.ts"},["936"] = {line = 104, file = "autozoom_object.ts"},["938"] = {line = 106, file = "autozoom_object.ts"},["939"] = {line = 107, file = "autozoom_object.ts"},["940"] = {line = 108, file = "autozoom_object.ts"},["942"] = {line = 71, file = "autozoom_object.ts"},["943"] = {line = 111, file = "autozoom_object.ts"},["944"] = {line = 112, file = "autozoom_object.ts"},["945"] = {line = 113, file = "autozoom_object.ts"},["946"] = {line = 113, file = "autozoom_object.ts"},["947"] = {line = 113, file = "autozoom_object.ts"},["948"] = {line = 113, file = "autozoom_object.ts"},["949"] = {line = 113, file = "autozoom_object.ts"},["951"] = {line = 111, file = "autozoom_object.ts"},["952"] = {line = 118, file = "autozoom_object.ts"},["953"] = {line = 122, file = "autozoom_object.ts"},["954"] = {line = 123, file = "autozoom_object.ts"},["956"] = {line = 125, file = "autozoom_object.ts"},["957"] = {line = 126, file = "autozoom_object.ts"},["960"] = {line = 129, file = "autozoom_object.ts"},["961"] = {line = 130, file = "autozoom_object.ts"},["964"] = {line = 133, file = "autozoom_object.ts"},["965"] = {line = 134, file = "autozoom_object.ts"},["966"] = {line = 135, file = "autozoom_object.ts"},["967"] = {line = 136, file = "autozoom_object.ts"},["968"] = {line = 137, file = "autozoom_object.ts"},["970"] = {line = 139, file = "autozoom_object.ts"},["971"] = {line = 139, file = "autozoom_object.ts"},["972"] = {line = 140, file = "autozoom_object.ts"},["973"] = {line = 141, file = "autozoom_object.ts"},["974"] = {line = 142, file = "autozoom_object.ts"},["975"] = {line = 143, file = "autozoom_object.ts"},["976"] = {line = 143, file = "autozoom_object.ts"},["977"] = {line = 143, file = "autozoom_object.ts"},["978"] = {line = 143, file = "autozoom_object.ts"},["979"] = {line = 143, file = "autozoom_object.ts"},["982"] = {line = 139, file = "autozoom_object.ts"},["985"] = {line = 147, file = "autozoom_object.ts"},["986"] = {line = 147, file = "autozoom_object.ts"},["987"] = {line = 148, file = "autozoom_object.ts"},["988"] = {line = 148, file = "autozoom_object.ts"},["989"] = {line = 148, file = "autozoom_object.ts"},["990"] = {line = 148, file = "autozoom_object.ts"},["991"] = {line = 148, file = "autozoom_object.ts"},["995"] = {line = 152, file = "autozoom_object.ts"},["996"] = {line = 152, file = "autozoom_object.ts"},["997"] = {line = 152, file = "autozoom_object.ts"},["998"] = {line = 152, file = "autozoom_object.ts"},["999"] = {line = 152, file = "autozoom_object.ts"},["1003"] = {line = 156, file = "autozoom_object.ts"},["1004"] = {line = 156, file = "autozoom_object.ts"},["1005"] = {line = 156, file = "autozoom_object.ts"},["1006"] = {line = 156, file = "autozoom_object.ts"},["1007"] = {line = 156, file = "autozoom_object.ts"},["1008"] = {line = 118, file = "autozoom_object.ts"},["1009"] = {line = 159, file = "autozoom_object.ts"},["1011"] = {line = 160, file = "autozoom_object.ts"},["1012"] = {line = 160, file = "autozoom_object.ts"},["1013"] = {line = 161, file = "autozoom_object.ts"},["1014"] = {line = 162, file = "autozoom_object.ts"},["1015"] = {line = 163, file = "autozoom_object.ts"},["1016"] = {line = 163, file = "autozoom_object.ts"},["1017"] = {line = 163, file = "autozoom_object.ts"},["1018"] = {line = 163, file = "autozoom_object.ts"},["1019"] = {line = 163, file = "autozoom_object.ts"},["1022"] = {line = 160, file = "autozoom_object.ts"},["1025"] = {line = 167, file = "autozoom_object.ts"},["1026"] = {line = 167, file = "autozoom_object.ts"},["1027"] = {line = 167, file = "autozoom_object.ts"},["1028"] = {line = 167, file = "autozoom_object.ts"},["1029"] = {line = 167, file = "autozoom_object.ts"},["1030"] = {line = 159, file = "autozoom_object.ts"},["1031"] = {line = 169, file = "autozoom_object.ts"},["1032"] = {line = 170, file = "autozoom_object.ts"},["1033"] = {line = 169, file = "autozoom_object.ts"},["1034"] = {line = 172, file = "autozoom_object.ts"},["1035"] = {line = 173, file = "autozoom_object.ts"},["1036"] = {line = 172, file = "autozoom_object.ts"},["1037"] = {line = 176, file = "autozoom_object.ts"},["1038"] = {line = 177, file = "autozoom_object.ts"},["1039"] = {line = 178, file = "autozoom_object.ts"},["1040"] = {line = 176, file = "autozoom_object.ts"},["1041"] = {line = 181, file = "autozoom_object.ts"},["1042"] = {line = 182, file = "autozoom_object.ts"},["1043"] = {line = 183, file = "autozoom_object.ts"},["1045"] = {line = 181, file = "autozoom_object.ts"},["1046"] = {line = 187, file = "autozoom_object.ts"},["1047"] = {line = 188, file = "autozoom_object.ts"},["1048"] = {line = 189, file = "autozoom_object.ts"},["1050"] = {line = 187, file = "autozoom_object.ts"},["1051"] = {line = 196, file = "autozoom_object.ts"},["1052"] = {line = 197, file = "autozoom_object.ts"},["1053"] = {line = 198, file = "autozoom_object.ts"},["1054"] = {line = 199, file = "autozoom_object.ts"},["1055"] = {line = 200, file = "autozoom_object.ts"},["1058"] = {line = 205, file = "autozoom_object.ts"},["1059"] = {line = 206, file = "autozoom_object.ts"},["1060"] = {line = 208, file = "autozoom_object.ts"},["1061"] = {line = 209, file = "autozoom_object.ts"},["1063"] = {line = 196, file = "autozoom_object.ts"},["1064"] = {line = 213, file = "autozoom_object.ts"},["1065"] = {line = 214, file = "autozoom_object.ts"},["1066"] = {line = 215, file = "autozoom_object.ts"},["1067"] = {line = 215, file = "autozoom_object.ts"},["1068"] = {line = 215, file = "autozoom_object.ts"},["1069"] = {line = 215, file = "autozoom_object.ts"},["1070"] = {line = 215, file = "autozoom_object.ts"},["1071"] = {line = 213, file = "autozoom_object.ts"},["1072"] = {line = 218, file = "autozoom_object.ts"},["1073"] = {line = 219, file = "autozoom_object.ts"},["1074"] = {line = 220, file = "autozoom_object.ts"},["1077"] = {line = 223, file = "autozoom_object.ts"},["1078"] = {line = 224, file = "autozoom_object.ts"},["1079"] = {line = 225, file = "autozoom_object.ts"},["1080"] = {line = 225, file = "autozoom_object.ts"},["1081"] = {line = 225, file = "autozoom_object.ts"},["1082"] = {line = 225, file = "autozoom_object.ts"},["1083"] = {line = 225, file = "autozoom_object.ts"},["1086"] = {line = 229, file = "autozoom_object.ts"},["1087"] = {line = 230, file = "autozoom_object.ts"},["1088"] = {line = 231, file = "autozoom_object.ts"},["1089"] = {line = 231, file = "autozoom_object.ts"},["1090"] = {line = 231, file = "autozoom_object.ts"},["1091"] = {line = 231, file = "autozoom_object.ts"},["1092"] = {line = 231, file = "autozoom_object.ts"},["1093"] = {line = 231, file = "autozoom_object.ts"},["1094"] = {line = 231, file = "autozoom_object.ts"},["1095"] = {line = 218, file = "autozoom_object.ts"},["1096"] = {line = 234, file = "autozoom_object.ts"},["1097"] = {line = 235, file = "autozoom_object.ts"},["1098"] = {line = 236, file = "autozoom_object.ts"},["1100"] = {line = 234, file = "autozoom_object.ts"},["1101"] = {line = 240, file = "autozoom_object.ts"},["1102"] = {line = 241, file = "autozoom_object.ts"},["1103"] = {line = 242, file = "autozoom_object.ts"},["1104"] = {line = 243, file = "autozoom_object.ts"},["1105"] = {line = 244, file = "autozoom_object.ts"},["1106"] = {line = 245, file = "autozoom_object.ts"},["1107"] = {line = 246, file = "autozoom_object.ts"},["1108"] = {line = 240, file = "autozoom_object.ts"},["1109"] = {line = 249, file = "autozoom_object.ts"},["1110"] = {line = 250, file = "autozoom_object.ts"},["1111"] = {line = 251, file = "autozoom_object.ts"},["1112"] = {line = 252, file = "autozoom_object.ts"},["1113"] = {line = 253, file = "autozoom_object.ts"},["1114"] = {line = 249, file = "autozoom_object.ts"},["1115"] = {line = 256, file = "autozoom_object.ts"},["1116"] = {line = 257, file = "autozoom_object.ts"},["1117"] = {line = 257, file = "autozoom_object.ts"},["1118"] = {line = 257, file = "autozoom_object.ts"},["1119"] = {line = 257, file = "autozoom_object.ts"},["1120"] = {line = 257, file = "autozoom_object.ts"},["1121"] = {line = 258, file = "autozoom_object.ts"},["1122"] = {line = 256, file = "autozoom_object.ts"},["1130"] = {line = 2, file = "main.ts"},["1131"] = {line = 2, file = "main.ts"},["1132"] = {line = 8, file = "main.ts"},["1133"] = {line = 10, file = "main.ts"},["1134"] = {line = 11, file = "main.ts"},["1135"] = {line = 12, file = "main.ts"},["1136"] = {line = 13, file = "main.ts"},["1138"] = {line = 15, file = "main.ts"},["1139"] = {line = 16, file = "main.ts"},["1140"] = {line = 8, file = "main.ts"},["1141"] = {line = 21, file = "main.ts"}});
return require("src.main", ...)
