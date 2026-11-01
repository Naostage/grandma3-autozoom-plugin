
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

local function __TS__StringTrim(self)
    local result = string.gsub(self, "^[%s ﻿]*(.-)[%s ﻿]*$", "%1")
    return result
end

local function __TS__StringSubstring(self, start, ____end)
    if ____end ~= ____end then
        ____end = 0
    end
    if ____end ~= nil and start > ____end then
        start, ____end = ____end, start
    end
    if start >= 0 then
        start = start + 1
    else
        start = 1
    end
    if ____end ~= nil and ____end < 0 then
        ____end = 0
    end
    return string.sub(self, start, ____end)
end

local function __TS__StringEndsWith(self, searchString, endPosition)
    if endPosition == nil or endPosition > #self then
        endPosition = #self
    end
    return string.sub(self, endPosition - #searchString + 1, endPosition) == searchString
end

local function __TS__ArrayIsArray(value)
    return type(value) == "table" and (value[1] ~= nil or next(value) == nil)
end

local function __TS__ArraySort(self, compareFn)
    if compareFn ~= nil then
        table.sort(
            self,
            function(a, b) return compareFn(nil, a, b) < 0 end
        )
    else
        table.sort(self)
    end
    return self
end

local function __TS__StringCharAt(self, pos)
    if pos ~= pos then
        pos = 0
    end
    if pos < 0 then
        return ""
    end
    return string.sub(self, pos + 1, pos + 1)
end

local function __TS__New(target, ...)
    local instance = setmetatable({}, target.prototype)
    instance:____constructor(...)
    return instance
end

local function __TS__Class(self)
    local c = {prototype = {}}
    c.prototype.__index = c.prototype
    c.prototype.constructor = c
    return c
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
        elseif _VERSION == "Lua 5.1" then
            return string.sub(
                debug.traceback("", level),
                2
            )
        else
            return debug.traceback(nil, level)
        end
    end
    local function wrapErrorToString(self, getDescription)
        return function(self)
            local description = getDescription(self)
            local caller = debug.getinfo(3, "f")
            local isClassicLua = __TS__StringIncludes(_VERSION, "Lua 5.0")
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
        self.stack = getErrorStack(nil, __TS__New)
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

local function __TS__Number(value)
    local valueType = type(value)
    if valueType == "number" then
        return value
    elseif valueType == "string" then
        local numberValue = tonumber(value)
        if numberValue then
            return numberValue
        end
        if value == "Infinity" then
            return math.huge
        end
        if value == "-Infinity" then
            return -math.huge
        end
        local stringWithoutSpaces = string.gsub(value, "%s", "")
        if stringWithoutSpaces == "" then
            return 0
        end
        return 0 / 0
    elseif valueType == "boolean" then
        return value and 1 or 0
    else
        return 0 / 0
    end
end

local function __TS__ArraySome(self, callbackfn, thisArg)
    for i = 1, #self do
        if callbackfn(thisArg, self[i], i - 1, self) then
            return true
        end
    end
    return false
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

local function __TS__ArrayFind(self, predicate, thisArg)
    for i = 1, #self do
        local elem = self[i]
        if predicate(thisArg, elem, i - 1, self) then
            return elem
        end
    end
    return nil
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

local function __TS__ObjectAssign(target, ...)
    local sources = {...}
    for i = 1, #sources do
        local source = sources[i]
        for key in pairs(source) do
            target[key] = source[key]
        end
    end
    return target
end

local function __TS__ArrayMap(self, callbackfn, thisArg)
    local result = {}
    for i = 1, #self do
        result[i] = callbackfn(thisArg, self[i], i - 1, self)
    end
    return result
end

local function __TS__ArrayForEach(self, callbackFn, thisArg)
    for i = 1, #self do
        callbackFn(thisArg, self[i], i - 1, self)
    end
end

local function __TS__ArrayIndexOf(self, searchElement, fromIndex)
    if fromIndex == nil then
        fromIndex = 0
    end
    local len = #self
    if len == 0 then
        return -1
    end
    if fromIndex >= len then
        return -1
    end
    if fromIndex < 0 then
        fromIndex = len + fromIndex
        if fromIndex < 0 then
            fromIndex = 0
        end
    end
    for i = fromIndex + 1, len do
        if self[i] == searchElement then
            return i - 1
        end
    end
    return -1
end

local function __TS__StringStartsWith(self, searchString, position)
    if position == nil or position < 0 then
        position = 0
    end
    return string.sub(self, position + 1, #searchString + position) == searchString
end

local __TS__StringSplit
do
    local sub = string.sub
    local find = string.find
    function __TS__StringSplit(source, separator, limit)
        if limit == nil then
            limit = 4294967295
        end
        if limit == 0 then
            return {}
        end
        local result = {}
        local resultIndex = 1
        if separator == nil or separator == "" then
            for i = 1, #source do
                result[resultIndex] = sub(source, i, i)
                resultIndex = resultIndex + 1
            end
        else
            local currentPos = 1
            while resultIndex <= limit do
                local startPos, endPos = find(source, separator, currentPos, true)
                if not startPos then
                    break
                end
                result[resultIndex] = sub(source, currentPos, startPos - 1)
                resultIndex = resultIndex + 1
                currentPos = endPos + 1
            end
            if resultIndex <= limit then
                result[resultIndex] = sub(source, currentPos)
            end
        end
        return result
    end
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

local function __TS__ArrayEvery(self, callbackfn, thisArg)
    for i = 1, #self do
        if not callbackfn(thisArg, self[i], i - 1, self) then
            return false
        end
    end
    return true
end

local __TS__StringReplace
do
    local sub = string.sub
    function __TS__StringReplace(source, searchValue, replaceValue)
        local startPos, endPos = string.find(source, searchValue, nil, true)
        if not startPos then
            return source
        end
        local before = sub(source, 1, startPos - 1)
        local replacement = type(replaceValue) == "string" and replaceValue or replaceValue(nil, searchValue, startPos - 1, source)
        local after = sub(source, endPos + 1)
        return (before .. replacement) .. after
    end
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
  __TS__StringTrim = __TS__StringTrim,
  __TS__StringSubstring = __TS__StringSubstring,
  __TS__StringEndsWith = __TS__StringEndsWith,
  __TS__ArrayIsArray = __TS__ArrayIsArray,
  __TS__ArraySort = __TS__ArraySort,
  __TS__StringCharAt = __TS__StringCharAt,
  Error = Error,
  RangeError = RangeError,
  ReferenceError = ReferenceError,
  SyntaxError = SyntaxError,
  TypeError = TypeError,
  URIError = URIError,
  __TS__New = __TS__New,
  __TS__Number = __TS__Number,
  __TS__ArraySome = __TS__ArraySome,
  __TS__ArrayFilter = __TS__ArrayFilter,
  __TS__ArrayFind = __TS__ArrayFind,
  __TS__Iterator = __TS__Iterator,
  __TS__ObjectAssign = __TS__ObjectAssign,
  __TS__ArrayMap = __TS__ArrayMap,
  __TS__ArrayForEach = __TS__ArrayForEach,
  __TS__ArrayIndexOf = __TS__ArrayIndexOf,
  __TS__StringStartsWith = __TS__StringStartsWith,
  __TS__Class = __TS__Class,
  __TS__StringSplit = __TS__StringSplit,
  __TS__SparseArrayNew = __TS__SparseArrayNew,
  __TS__SparseArrayPush = __TS__SparseArrayPush,
  __TS__SparseArraySpread = __TS__SparseArraySpread,
  __TS__ArrayEvery = __TS__ArrayEvery,
  __TS__StringReplace = __TS__StringReplace,
  __TS__Delete = __TS__Delete
}
 end,
["src.engine.vec"] = function(...) 
local ____lualib = require("lualib_bundle")
local __TS__SourceMapTraceBack = ____lualib.__TS__SourceMapTraceBack
local ____exports = {}
function ____exports.vec(x, y, z)
    return {x = x, y = y, z = z}
end
function ____exports.add(a, b)
    return {x = a.x + b.x, y = a.y + b.y, z = a.z + b.z}
end
function ____exports.distance(a, b)
    local dx = a.x - b.x
    local dy = a.y - b.y
    local dz = a.z - b.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end
function ____exports.rotate(v, deg)
    local rx = deg.x * math.pi / 180
    local ry = deg.y * math.pi / 180
    local rz = deg.z * math.pi / 180
    local x = v.x
    local y = v.y
    local z = v.z
    local t = y * math.cos(rx) - z * math.sin(rx)
    z = y * math.sin(rx) + z * math.cos(rx)
    y = t
    t = x * math.cos(ry) + z * math.sin(ry)
    z = -x * math.sin(ry) + z * math.cos(ry)
    x = t
    t = x * math.cos(rz) - y * math.sin(rz)
    y = x * math.sin(rz) + y * math.cos(rz)
    x = t
    return {x = x, y = y, z = z}
end
return ____exports
 end,
["src.engine.beam"] = function(...) 
local ____lualib = require("lualib_bundle")
local __TS__SourceMapTraceBack = ____lualib.__TS__SourceMapTraceBack
local ____exports = {}
local function percent(value, min, max)
    if max <= min then
        return 0
    end
    local p = (value - min) / (max - min) * 100
    return math.floor(math.min(
        100,
        math.max(0, p)
    ) * 10 + 0.5) / 10
end
local function beamAt(angleDeg, distance)
    return 2 * distance * math.tan(angleDeg * math.pi / 360)
end
function ____exports.beamFor(distance, size, o)
    local hasIris = o.irisMax > o.irisMin
    local full = hasIris and 100 or nil
    if distance <= 0.001 then
        return {zoom = 100, iris = full, fit = "too-wide", achieved = 0}
    end
    local angle = math.atan(size / 2 / distance) * 360 / math.pi
    if angle > o.zoomMax then
        return {
            zoom = 100,
            iris = full,
            fit = "too-wide",
            achieved = beamAt(o.zoomMax, distance)
        }
    end
    if angle >= o.zoomMin then
        return {
            zoom = percent(angle, o.zoomMin, o.zoomMax),
            iris = full,
            fit = "ok",
            achieved = size
        }
    end
    local atMin = beamAt(o.zoomMin, distance)
    if not hasIris then
        return {zoom = 0, iris = nil, fit = "too-small", achieved = atMin}
    end
    local ratio = size / atMin
    if ratio < o.irisMin then
        return {zoom = 0, iris = 0, fit = "too-small", achieved = atMin * o.irisMin}
    end
    return {
        zoom = 0,
        iris = percent(ratio, o.irisMin, o.irisMax),
        fit = "ok",
        achieved = size
    }
end
return ____exports
 end,
["src.model"] = function(...) 
local ____lualib = require("lualib_bundle")
local __TS__SourceMapTraceBack = ____lualib.__TS__SourceMapTraceBack
local ____exports = {}
return ____exports
 end,
["src.engine.preset-ref"] = function(...) 
local ____lualib = require("lualib_bundle")
local __TS__StringTrim = ____lualib.__TS__StringTrim
local __TS__SourceMapTraceBack = ____lualib.__TS__SourceMapTraceBack
local ____exports = {}
---
-- @noSelfInFile
function ____exports.parsePresetCommand(command)
    local s = string.lower(__TS__StringTrim(command))
    s = string.gsub(s, "^ok:%s*", "")
    s = string.gsub(s, "^at%s+", "")
    s = string.gsub(s, "^go%+%s+", "")
    s = string.gsub(s, "^call%s+", "")
    local dp, a, b = string.match(s, "^datapool%s+(%d+)%s+preset%s+(%d+)%.(%d+)")
    if dp ~= nil then
        return (((("DataPool " .. dp) .. " Preset ") .. a) .. ".") .. b
    end
    local p, q = string.match(s, "^preset%s+(%d+)%.(%d+)")
    if p ~= nil then
        return (p .. ".") .. q
    end
    return nil
end
return ____exports
 end,
["src.format"] = function(...) 
local ____lualib = require("lualib_bundle")
local __TS__StringSubstring = ____lualib.__TS__StringSubstring
local __TS__StringEndsWith = ____lualib.__TS__StringEndsWith
local __TS__SourceMapTraceBack = ____lualib.__TS__SourceMapTraceBack
local ____exports = {}
---
-- @noSelfInFile
function ____exports.fmtInt(n)
    return string.format(
        "%d",
        math.floor(n + 0.5)
    )
end
function ____exports.fmtNum(n)
    local s = string.format("%.3f", n)
    while __TS__StringEndsWith(s, "0") do
        s = __TS__StringSubstring(s, 0, #s - 1)
    end
    if __TS__StringEndsWith(s, ".") then
        s = __TS__StringSubstring(s, 0, #s - 1)
    end
    return s == "-0" and "0" or s
end
function ____exports.fidKey(fid)
    return ____exports.fmtInt(fid)
end
return ____exports
 end,
["src.store.json"] = function(...) 
local ____lualib = require("lualib_bundle")
local __TS__ArrayIsArray = ____lualib.__TS__ArrayIsArray
local __TS__ArraySort = ____lualib.__TS__ArraySort
local __TS__StringCharAt = ____lualib.__TS__StringCharAt
local Error = ____lualib.Error
local RangeError = ____lualib.RangeError
local ReferenceError = ____lualib.ReferenceError
local SyntaxError = ____lualib.SyntaxError
local TypeError = ____lualib.TypeError
local URIError = ____lualib.URIError
local __TS__New = ____lualib.__TS__New
local __TS__StringSubstring = ____lualib.__TS__StringSubstring
local __TS__Number = ____lualib.__TS__Number
local __TS__SourceMapTraceBack = ____lualib.__TS__SourceMapTraceBack
local ____exports = {}
local encodeString, skipSpace, expectWord, parseValue, parseNumber, parseString, parseArray, parseObject
function encodeString(s)
    local out = "\""
    do
        local i = 0
        while i < #s do
            local c = __TS__StringCharAt(s, i)
            if c == "\"" then
                out = out .. "\\\""
            elseif c == "\\" then
                out = out .. "\\\\"
            elseif c == "\n" then
                out = out .. "\\n"
            elseif c == "\r" then
                out = out .. "\\r"
            elseif c == "\t" then
                out = out .. "\\t"
            else
                out = out .. c
            end
            i = i + 1
        end
    end
    return out .. "\""
end
function skipSpace(c)
    while c.i < #c.s do
        local ch = __TS__StringCharAt(c.s, c.i)
        if ch ~= " " and ch ~= "\n" and ch ~= "\r" and ch ~= "\t" then
            return
        end
        c.i = c.i + 1
    end
end
function expectWord(c, word)
    if __TS__StringSubstring(c.s, c.i, c.i + #word) ~= word then
        error(
            __TS__New(
                Error,
                (("expected " .. word) .. " at ") .. tostring(c.i)
            ),
            0
        )
    end
    c.i = c.i + #word
end
function parseValue(c)
    skipSpace(c)
    local ch = __TS__StringCharAt(c.s, c.i)
    if ch == "{" then
        return parseObject(c)
    end
    if ch == "[" then
        return parseArray(c)
    end
    if ch == "\"" then
        return parseString(c)
    end
    if ch == "t" then
        expectWord(c, "true")
        return true
    end
    if ch == "f" then
        expectWord(c, "false")
        return false
    end
    if ch == "n" then
        expectWord(c, "null")
        return nil
    end
    return parseNumber(c)
end
function parseNumber(c)
    local start = c.i
    while c.i < #c.s and (string.find(
        "+-0123456789.eE",
        __TS__StringCharAt(c.s, c.i),
        nil,
        true
    ) or 0) - 1 >= 0 do
        c.i = c.i + 1
    end
    if c.i == start then
        error(
            __TS__New(
                Error,
                "unexpected character at " .. tostring(start)
            ),
            0
        )
    end
    local n = __TS__Number(__TS__StringSubstring(c.s, start, c.i))
    if n ~= n then
        error(
            __TS__New(
                Error,
                "bad number at " .. tostring(start)
            ),
            0
        )
    end
    return n
end
function parseString(c)
    c.i = c.i + 1
    local out = ""
    while c.i < #c.s do
        local ch = __TS__StringCharAt(c.s, c.i)
        c.i = c.i + 1
        if ch == "\"" then
            return out
        end
        if ch == "\\" then
            local e = __TS__StringCharAt(c.s, c.i)
            c.i = c.i + 1
            if e == "n" then
                out = out .. "\n"
            elseif e == "r" then
                out = out .. "\r"
            elseif e == "t" then
                out = out .. "\t"
            else
                out = out .. e
            end
        else
            out = out .. ch
        end
    end
    error(
        __TS__New(Error, "unterminated string"),
        0
    )
end
function parseArray(c)
    c.i = c.i + 1
    local out = {}
    skipSpace(c)
    if __TS__StringCharAt(c.s, c.i) == "]" then
        c.i = c.i + 1
        return out
    end
    while true do
        out[#out + 1] = parseValue(c)
        skipSpace(c)
        local ch = __TS__StringCharAt(c.s, c.i)
        c.i = c.i + 1
        if ch == "]" then
            return out
        end
        if ch ~= "," then
            error(
                __TS__New(
                    Error,
                    "expected , or ] at " .. tostring(c.i - 1)
                ),
                0
            )
        end
    end
end
function parseObject(c)
    c.i = c.i + 1
    local out = {}
    skipSpace(c)
    if __TS__StringCharAt(c.s, c.i) == "}" then
        c.i = c.i + 1
        return out
    end
    while true do
        skipSpace(c)
        if __TS__StringCharAt(c.s, c.i) ~= "\"" then
            error(
                __TS__New(
                    Error,
                    "expected key at " .. tostring(c.i)
                ),
                0
            )
        end
        local key = parseString(c)
        skipSpace(c)
        if __TS__StringCharAt(c.s, c.i) ~= ":" then
            error(
                __TS__New(
                    Error,
                    "expected : at " .. tostring(c.i)
                ),
                0
            )
        end
        c.i = c.i + 1
        local value = parseValue(c)
        if value ~= nil then
            out[key] = value
        end
        skipSpace(c)
        local ch = __TS__StringCharAt(c.s, c.i)
        c.i = c.i + 1
        if ch == "}" then
            return out
        end
        if ch ~= "," then
            error(
                __TS__New(
                    Error,
                    "expected , or } at " .. tostring(c.i - 1)
                ),
                0
            )
        end
    end
end
---
-- @noSelfInFile
function ____exports.encode(value)
    if value == nil or value == nil then
        return "null"
    end
    if type(value) == "boolean" then
        return value and "true" or "false"
    end
    if type(value) == "number" then
        if value ~= value or value == math.huge or value == -math.huge then
            return "null"
        end
        return math.floor(value) == value and math.abs(value) < 1000000000000000 and string.format("%d", value) or string.format("%.10g", value)
    end
    if type(value) == "string" then
        return encodeString(value)
    end
    if __TS__ArrayIsArray(value) then
        local parts = {}
        for ____, item in ipairs(value) do
            parts[#parts + 1] = ____exports.encode(item)
        end
        return ("[" .. table.concat(parts, ",")) .. "]"
    end
    local obj = value
    local keys = {}
    for key in pairs(obj) do
        keys[#keys + 1] = key
    end
    __TS__ArraySort(keys)
    local parts = {}
    for ____, key in ipairs(keys) do
        parts[#parts + 1] = (encodeString(key) .. ":") .. ____exports.encode(obj[key])
    end
    return ("{" .. table.concat(parts, ",")) .. "}"
end
function ____exports.decode(text)
    local c = {s = text, i = 0}
    local value = parseValue(c)
    skipSpace(c)
    if c.i < #c.s then
        error(
            __TS__New(
                Error,
                "unexpected text at " .. tostring(c.i)
            ),
            0
        )
    end
    return value
end
return ____exports
 end,
["src.store.rows"] = function(...) 
local ____lualib = require("lualib_bundle")
local __TS__ArraySome = ____lualib.__TS__ArraySome
local __TS__ArrayFilter = ____lualib.__TS__ArrayFilter
local __TS__ArrayFind = ____lualib.__TS__ArrayFind
local __TS__ArrayIsArray = ____lualib.__TS__ArrayIsArray
local __TS__SourceMapTraceBack = ____lualib.__TS__SourceMapTraceBack
local ____exports = {}
local ____format = require("src.format")
local fidKey = ____format.fidKey
local fmtInt = ____format.fmtInt
function ____exports.sameEntry(a, b)
    if a.kind == "group" then
        return b.kind == "group" and a.no == b.no
    end
    return b.kind == "fixture" and a.fid == b.fid
end
function ____exports.addEntries(rows, add)
    local out = {table.unpack(rows)}
    for ____, e in ipairs(add) do
        if not __TS__ArraySome(
            out,
            function(____, x) return ____exports.sameEntry(x, e) end
        ) then
            out[#out + 1] = e
        end
    end
    return out
end
function ____exports.moveEntry(rows, index, delta)
    local out = {table.unpack(rows)}
    local to = index + delta
    if index < 0 or index >= #out or to < 0 or to >= #out then
        return out
    end
    local e = out[index + 1]
    out[index + 1] = out[to + 1]
    out[to + 1] = e
    return out
end
function ____exports.removeEntry(rows, index)
    return __TS__ArrayFilter(
        rows,
        function(____, _, i) return i ~= index end
    )
end
function ____exports.coverage(rows, groups)
    local fixtures = {}
    local listed = {}
    for ____, e in ipairs(rows) do
        if e.kind == "fixture" then
            fixtures[fidKey(e.fid)] = "self"
        else
            listed[fidKey(e.no)] = true
            local g = __TS__ArrayFind(
                groups,
                function(____, x) return x.no == e.no end
            )
            for ____, fid in ipairs(g and g.fids or ({})) do
                if fixtures[fidKey(fid)] == nil then
                    fixtures[fidKey(fid)] = "group"
                end
            end
        end
    end
    return {fixtures = fixtures, groups = listed}
end
function ____exports.entryLabel(e, groups, fixtureName)
    if e.kind == "group" then
        local g = __TS__ArrayFind(
            groups,
            function(____, x) return x.no == e.no end
        )
        return (("Group " .. fmtInt(e.no)) .. "  ") .. (g and g.name or e.name)
    end
    local name = fixtureName(e.fid)
    return name == nil and "Fixture " .. fmtInt(e.fid) or (("Fixture " .. fmtInt(e.fid)) .. "  ") .. name
end
local function int(v)
    return type(v) == "number" and v == v and math.floor(v) == v and v or nil
end
function ____exports.parseRows(raw)
    local out = {}
    if not __TS__ArrayIsArray(raw) then
        return out
    end
    for ____, r in ipairs(raw) do
        do
            if type(r) ~= "table" then
                goto __continue28
            end
            if r.kind == "group" and int(r.no) ~= nil and type(r.name) == "string" then
                out = ____exports.addEntries(out, {{kind = "group", no = r.no, name = r.name}})
            elseif r.kind == "fixture" and int(r.fid) ~= nil then
                out = ____exports.addEntries(out, {{kind = "fixture", fid = r.fid}})
            end
        end
        ::__continue28::
    end
    return out
end
return ____exports
 end,
["src.store.config"] = function(...) 
local ____lualib = require("lualib_bundle")
local __TS__ArrayIsArray = ____lualib.__TS__ArrayIsArray
local __TS__Iterator = ____lualib.__TS__Iterator
local __TS__ObjectAssign = ____lualib.__TS__ObjectAssign
local __TS__StringTrim = ____lualib.__TS__StringTrim
local __TS__Number = ____lualib.__TS__Number
local __TS__ArrayMap = ____lualib.__TS__ArrayMap
local __TS__SourceMapTraceBack = ____lualib.__TS__SourceMapTraceBack
local ____exports = {}
local ____preset_2Dref = require("src.engine.preset-ref")
local parsePresetCommand = ____preset_2Dref.parsePresetCommand
local ____format = require("src.format")
local fidKey = ____format.fidKey
local fmtNum = ____format.fmtNum
local ____json = require("src.store.json")
local decode = ____json.decode
local encode = ____json.encode
local ____rows = require("src.store.rows")
local parseRows = ____rows.parseRows
____exports.CONFIG_KEY = "AutoZoom.config"
____exports.INSTANCE_KEY = "AutoZoom.instance"
local UNREADABLE = "Saved AutoZoom settings were unreadable; defaults restored"
function ____exports.defaultConfig()
    return {
        disarmed = {},
        size = {},
        range = {0.5, 5},
        rate = 30,
        offset = {source = "values", preset = "", values = {0, 0, 0}},
        rows = {}
    }
end
local function num(v)
    return type(v) == "number" and v == v and v or nil
end
function ____exports.parseConfig(text)
    local config = ____exports.defaultConfig()
    if text == nil or text == "" then
        return {config = config}
    end
    local raw
    do
        local function ____catch(e)
            return true, {config = config, warning = UNREADABLE}
        end
        local ____try, ____hasReturned, ____returnValue = pcall(function()
            raw = decode(text)
        end)
        if not ____try then
            ____hasReturned, ____returnValue = ____catch(____hasReturned)
        end
        if ____hasReturned then
            return ____returnValue
        end
    end
    if type(raw) ~= "table" then
        return {config = config, warning = UNREADABLE}
    end
    if __TS__ArrayIsArray(raw.disarmed) then
        for ____, fid in __TS__Iterator(raw.disarmed) do
            if num(fid) ~= nil then
                local ____config_disarmed_0 = config.disarmed
                ____config_disarmed_0[#____config_disarmed_0 + 1] = math.floor(fid)
            end
        end
    end
    if type(raw.size) == "table" then
        for key in pairs(raw.size) do
            local v = num(raw.size[key])
            if v ~= nil and v > 0 then
                config.size[key] = v
            end
        end
    end
    if __TS__ArrayIsArray(raw.range) and raw.range.length == 2 then
        local lo = num(raw.range[0])
        local hi = num(raw.range[1])
        if lo ~= nil and hi ~= nil and lo > 0 and hi > lo then
            config.range = {lo, hi}
        end
    end
    local rate = num(raw.rate)
    if rate ~= nil and rate >= 1 and rate <= 60 then
        config.rate = rate
    end
    if type(raw.offset) == "table" then
        local o = raw.offset
        if o.source == "preset" or o.source == "values" then
            config.offset.source = o.source
        end
        if type(o.preset) == "string" then
            config.offset.preset = o.preset
        end
        if __TS__ArrayIsArray(o.values) and o.values.length == 3 then
            config.offset.values = {
                num(o.values[0]) or 0,
                num(o.values[1]) or 0,
                num(o.values[2]) or 0
            }
        end
    end
    config.rows = parseRows(raw.rows)
    return {config = config}
end
function ____exports.serializeConfig(c)
    return encode({
        v = 1,
        disarmed = c.disarmed,
        size = c.size,
        range = c.range,
        rate = c.rate,
        offset = c.offset,
        rows = c.rows
    })
end
function ____exports.pruneConfig(config, fids)
    local keep = {}
    for ____, fid in ipairs(fids) do
        keep[fidKey(fid)] = true
    end
    local size = {}
    for key in pairs(config.size) do
        if keep[key] then
            size[key] = config.size[key]
        end
    end
    return __TS__ObjectAssign({}, config, {size = size})
end
function ____exports.applySetup(current, a)
    local errors = {}
    local config = __TS__ObjectAssign(
        {},
        current,
        {
            range = {table.unpack(current.range)},
            offset = __TS__ObjectAssign(
                {},
                current.offset,
                {values = {table.unpack(current.offset.values)}}
            )
        }
    )
    local function read(label, text)
        local n = __TS__Number(__TS__StringTrim(text))
        if __TS__StringTrim(text) == "" or n ~= n then
            errors[#errors + 1] = ((label .. ": \"") .. text) .. "\" is not a number"
            return nil
        end
        return n
    end
    local x = read("Offset X", a.x)
    local y = read("Offset Y", a.y)
    local z = read("Offset Z", a.z)
    if x ~= nil and y ~= nil and z ~= nil then
        config.offset.values = {x, y, z}
    end
    if a.source == "preset" and __TS__StringTrim(a.preset) == "" then
        errors[#errors + 1] = "Offset source is Preset but no preset number was given"
    else
        config.offset.source = a.source
    end
    config.offset.preset = parsePresetCommand(a.preset) or __TS__StringTrim(a.preset)
    local lo = read("Size min", a.min)
    local hi = read("Size max", a.max)
    if lo ~= nil and hi ~= nil then
        if lo > 0 and hi > lo then
            config.range = {lo, hi}
        else
            errors[#errors + 1] = "Size range must be min > 0 and max > min"
        end
    end
    local rate = read("Refresh rate", a.rate)
    if rate ~= nil then
        if rate >= 1 and rate <= 60 then
            config.rate = rate
        else
            errors[#errors + 1] = "Refresh rate must be between 1 and 60"
        end
    end
    return {config = config, errors = errors}
end
function ____exports.offsetLabel(c)
    if c.offset.source == "preset" then
        local dp, p = string.match(c.offset.preset, "^DataPool%s+(%d+)%s+Preset%s+(.+)$")
        return dp ~= nil and (("DP" .. dp) .. " ") .. p or "Preset " .. c.offset.preset
    end
    return table.concat(
        __TS__ArrayMap(
            c.offset.values,
            function(____, v) return fmtNum(v) end
        ),
        "/"
    ) .. " m"
end
return ____exports
 end,
["src.desk"] = function(...) 
local ____lualib = require("lualib_bundle")
local __TS__SourceMapTraceBack = ____lualib.__TS__SourceMapTraceBack
local ____exports = {}
return ____exports
 end,
["src.engine.fixture-state"] = function(...) 
local ____lualib = require("lualib_bundle")
local __TS__SourceMapTraceBack = ____lualib.__TS__SourceMapTraceBack
local ____exports = {}
local ____beam = require("src.engine.beam")
local beamFor = ____beam.beamFor
local ____vec = require("src.engine.vec")
local add = ____vec.add
local distance = ____vec.distance
local rotate = ____vec.rotate
local RELEASE = {kind = "release"}
function ____exports.evaluate(i)
    if not i.running then
        return {state = "offline", output = RELEASE}
    end
    if not i.armed then
        return {state = "disarmed", output = RELEASE}
    end
    if i.markerCid == 0 then
        return {state = "no-marker", output = RELEASE}
    end
    if not i.marker then
        return {state = "unknown-marker", output = RELEASE}
    end
    if not i.marker.live then
        return {state = "no-psn", output = {kind = "hold"}}
    end
    local offset = i.marker.rot ~= nil and rotate(i.offset, i.marker.rot) or i.offset
    local aim = add(i.marker.pos, offset)
    local d = distance(i.fixturePos, aim)
    local beam = beamFor(d, i.size, i.optics)
    local state = beam.fit == "ok" and "tracking" or beam.fit
    return {
        state = state,
        aim = aim,
        distance = d,
        achieved = beam.achieved,
        zoom = beam.zoom,
        iris = beam.iris,
        output = {kind = "set", zoom = beam.zoom, iris = beam.iris}
    }
end
return ____exports
 end,
["src.ui.view-model"] = function(...) 
local ____lualib = require("lualib_bundle")
local __TS__ArrayForEach = ____lualib.__TS__ArrayForEach
local __TS__ArrayIndexOf = ____lualib.__TS__ArrayIndexOf
local __TS__ArrayFilter = ____lualib.__TS__ArrayFilter
local __TS__ArraySome = ____lualib.__TS__ArraySome
local __TS__ArrayFind = ____lualib.__TS__ArrayFind
local __TS__ArrayMap = ____lualib.__TS__ArrayMap
local __TS__SourceMapTraceBack = ____lualib.__TS__SourceMapTraceBack
local ____exports = {}
local stateColor, stateAppearance, followLook, groupViews, TRACKING, WORST_FIRST, LABELS
local ____format = require("src.format")
local fidKey = ____format.fidKey
local fmtInt = ____format.fmtInt
local fmtNum = ____format.fmtNum
function ____exports.stateLabel(state)
    return LABELS[state]
end
function stateColor(state)
    if state == "tracking" then
        return ____exports.COLORS.on
    end
    if state == "too-wide" or state == "too-small" then
        return ____exports.COLORS.warn
    end
    if state == "no-psn" or state == "unknown-marker" then
        return ____exports.COLORS.bad
    end
    return ____exports.COLORS.idle
end
function stateAppearance(state)
    if state == "tracking" then
        return "tracking"
    end
    if state == "too-wide" or state == "too-small" then
        return "warn"
    end
    if state == "no-psn" then
        return "nopsn"
    end
    if state == "unknown-marker" then
        return "error"
    end
    return "idle"
end
function ____exports.summarize(members)
    local tracking = 0
    local worst
    for ____, r in ipairs(members) do
        local s = r.result.state
        if TRACKING[s] then
            tracking = tracking + 1
        end
        if worst == nil or __TS__ArrayIndexOf(WORST_FIRST, s) < __TS__ArrayIndexOf(WORST_FIRST, worst) then
            worst = s
        end
    end
    local worstCount = #__TS__ArrayFilter(
        members,
        function(____, r) return r.result.state == worst end
    )
    return {tracking = tracking, total = #members, worst = worst, worstCount = worstCount}
end
function followLook(states)
    if __TS__ArraySome(
        states,
        function(____, s) return TRACKING[s] end
    ) then
        return {____exports.COLORS.on, "tracking"}
    end
    if __TS__ArraySome(
        states,
        function(____, s) return s == "no-psn" end
    ) then
        return {____exports.COLORS.accent, "nopsn"}
    end
    return {____exports.COLORS.muted, "idle"}
end
function groupViews(cell, g, markers)
    local no = fmtInt(g.no)
    local total = #g.members
    local armed = #__TS__ArrayFilter(
        g.members,
        function(____, r) return r.armed end
    )
    local armLook = total > 0 and armed == total and "tracking" or (armed == 0 and "idle" or "warn")
    cell(
        "garm " .. no,
        ((((((("G" .. no) .. " ") .. g.name) .. "\n") .. fmtInt(armed)) .. "/") .. fmtInt(total)) .. " armed",
        armLook,
        armLook == "tracking" and ____exports.COLORS.on or (armLook == "warn" and ____exports.COLORS.warn or ____exports.COLORS.idle)
    )
    for ____, m in ipairs(markers) do
        local key = (("gmx " .. no) .. " ") .. fmtInt(m.cid)
        local inProgrammer = #__TS__ArrayFilter(
            g.members,
            function(____, r) return r.programmerCid == m.cid end
        )
        local following = __TS__ArrayMap(
            __TS__ArrayFilter(
                g.members,
                function(____, r) return r.markerCid == m.cid end
            ),
            function(____, r) return r.result.state end
        )
        if inProgrammer > 0 then
            cell(
                key,
                inProgrammer == total and "P" or (("P " .. fmtInt(inProgrammer)) .. "/") .. fmtInt(total),
                "programmer",
                ____exports.COLORS.bad,
                ____exports.COLORS.bad
            )
        elseif #following > 0 then
            local color, look = table.unpack(
                followLook(following),
                1,
                2
            )
            cell(
                key,
                "●",
                look,
                color,
                color
            )
        else
            cell(key, "", "idle")
        end
    end
    if total == 0 then
        if g.missing then
            cell("gst " .. no, "Group missing", "error", ____exports.COLORS.bad)
        else
            cell("gst " .. no, "No XYZ fixtures", "idle")
        end
        return
    end
    local sum = ____exports.summarize(g.members)
    local worst = sum.worst or "offline"
    local first = ((fmtInt(sum.tracking) .. "/") .. fmtInt(total)) .. " tracking"
    cell(
        "gst " .. no,
        worst == "tracking" and first or (((first .. "\n") .. fmtInt(sum.worstCount)) .. " ") .. ____exports.stateLabel(worst),
        stateAppearance(worst),
        stateColor(worst)
    )
end
____exports.COLORS = {
    on = "3ECF6EFF",
    warn = "E8C547FF",
    bad = "E5534BFF",
    idle = "5B6573FF",
    accent = "F5A623FF",
    text = "E6E8EBFF",
    muted = "8E96A3FF"
}
____exports.APPEARANCES = {
    tracking = {name = "AZ Tracking", rgba = "137A38E0"},
    warn = {name = "AZ Warn", rgba = "7A6A10D9"},
    nopsn = {name = "AZ No PSN", rgba = "85520AD9"},
    error = {name = "AZ Error", rgba = "851F1AD9"},
    programmer = {name = "AZ Programmer", rgba = "8F211CE6"},
    capture = {name = "AZ Capture", rgba = "B8650FE0"},
    button = {name = "AZ Button", rgba = "24283AE0"},
    header = {name = "AZ Header", rgba = "171C3DB8"},
    idle = {name = "AZ Idle", rgba = "10121CD9"}
}
____exports.GRID = {w = 130, markerW = 70, h = 64, gap = 6}
____exports.Y_DIR = -1
TRACKING = {tracking = true, ["too-wide"] = true, ["too-small"] = true}
WORST_FIRST = {
    "unknown-marker",
    "no-psn",
    "too-wide",
    "too-small",
    "tracking",
    "no-marker",
    "disarmed",
    "offline"
}
LABELS = {
    offline = "Offline",
    disarmed = "Disarmed",
    ["no-marker"] = "Armed · no marker",
    ["unknown-marker"] = "Unknown marker",
    ["no-psn"] = "No PSN data",
    tracking = "Tracking",
    ["too-wide"] = "Too wide",
    ["too-small"] = "Too small"
}
local function signed(n)
    return (n >= 0 and "+" or "") .. fmtNum(n)
end
function ____exports.layoutCells(rows, markers)
    local cells = {}
    local step = ____exports.GRID.h + ____exports.GRID.gap
    local x = 0
    local header = {
        {"status", ""},
        {"toggle", "Toggle()"},
        {"setup", "Setup()"},
        {"rescan", "RescanLater()"},
        {"size", ""},
        {"message", ""}
    }
    for ____, ____value in ipairs(header) do
        local key = ____value[1]
        local command = ____value[2]
        local w = key == "message" and ____exports.GRID.w * 3 or ____exports.GRID.w
        cells[#cells + 1] = {
            key = key,
            x = x,
            y = 0,
            w = w,
            h = ____exports.GRID.h,
            command = command
        }
        x = x + (w + ____exports.GRID.gap)
    end
    local function markerX(i)
        return ____exports.GRID.w + ____exports.GRID.gap + i * (____exports.GRID.markerW + ____exports.GRID.gap)
    end
    __TS__ArrayForEach(
        markers,
        function(____, m, i)
            local ____temp_0 = #cells + 1
            cells[____temp_0] = {
                key = "mh " .. fmtInt(m.cid),
                x = markerX(i),
                y = ____exports.Y_DIR * step,
                w = ____exports.GRID.markerW,
                h = ____exports.GRID.h,
                command = ""
            }
            return ____temp_0
        end
    )
    local afterMarkers = markerX(#markers)
    __TS__ArrayForEach(
        rows,
        function(____, r, row)
            local y = ____exports.Y_DIR * step * (row + 2)
            if r.kind == "group" then
                local no = fmtInt(r.no)
                cells[#cells + 1] = {
                    key = "garm " .. no,
                    x = 0,
                    y = y,
                    w = ____exports.GRID.w,
                    h = ____exports.GRID.h,
                    command = ("ArmGroup(" .. no) .. ")"
                }
                __TS__ArrayForEach(
                    markers,
                    function(____, m, i)
                        local ____temp_1 = #cells + 1
                        cells[____temp_1] = {
                            key = (("gmx " .. no) .. " ") .. fmtInt(m.cid),
                            x = markerX(i),
                            y = y,
                            w = ____exports.GRID.markerW,
                            h = ____exports.GRID.h,
                            command = ((("ProgramGroup(" .. no) .. ",") .. fmtInt(m.cid)) .. ")"
                        }
                        return ____temp_1
                    end
                )
                cells[#cells + 1] = {
                    key = "gst " .. no,
                    x = afterMarkers,
                    y = y,
                    w = ____exports.GRID.w * 1.6,
                    h = ____exports.GRID.h,
                    command = ""
                }
                return
            end
            local f = r.fixture
            local fid = fmtInt(f.fid)
            cells[#cells + 1] = {
                key = "arm " .. fid,
                x = 0,
                y = y,
                w = ____exports.GRID.w,
                h = ____exports.GRID.h,
                command = ("ArmToggle(" .. fid) .. ")"
            }
            __TS__ArrayForEach(
                markers,
                function(____, m, i)
                    local ____temp_2 = #cells + 1
                    cells[____temp_2] = {
                        key = (("mx " .. fid) .. " ") .. fmtInt(m.cid),
                        x = markerX(i),
                        y = y,
                        w = ____exports.GRID.markerW,
                        h = ____exports.GRID.h,
                        command = ((("Program(" .. fid) .. ",") .. fmtInt(m.cid)) .. ")"
                    }
                    return ____temp_2
                end
            )
            local tail = {
                {"st", ____exports.GRID.w * 1.6, ""},
                {"di", ____exports.GRID.w, ""},
                {"zo", ____exports.GRID.w * 0.8, ""},
                {"ir", ____exports.GRID.w * 0.8, ""},
                {"sz", ____exports.GRID.w, ("Size(" .. fid) .. ")"}
            }
            local cx = afterMarkers
            for ____, ____value in ipairs(tail) do
                local prefix = ____value[1]
                local w = ____value[2]
                local command = ____value[3]
                cells[#cells + 1] = {
                    key = (prefix .. " ") .. fid,
                    x = cx,
                    y = y,
                    w = w,
                    h = ____exports.GRID.h,
                    command = command
                }
                cx = cx + (w + ____exports.GRID.gap)
            end
        end
    )
    return cells
end
function ____exports.buildViews(header, rows, markers, readings)
    local v = {}
    local function cell(key, text, appearance, border, textColor)
        if border == nil then
            border = ____exports.COLORS.idle
        end
        if textColor == nil then
            textColor = ____exports.COLORS.text
        end
        v[key] = {text = text, border = border, textColor = textColor, appearance = appearance}
    end
    cell(
        "status",
        ((((header.running and "Running" or "Offline") .. "\nPSN ") .. fmtInt(header.liveMarkers)) .. "/") .. fmtInt(#markers),
        header.running and "tracking" or "error",
        header.running and ____exports.COLORS.on or ____exports.COLORS.bad
    )
    cell("toggle", header.running and "Stop" or "Start", "button")
    cell("setup", "Setup\nXYZ " .. header.offsetLabel, "button")
    cell("rescan", "Rescan\npatch", "button")
    cell(
        "size",
        ("AZ_SIZE\n" .. fmtNum(header.globalSize)) .. " m",
        "header"
    )
    cell(
        "message",
        header.message,
        "header",
        ____exports.COLORS.idle,
        ____exports.COLORS.muted
    )
    for ____, m in ipairs(markers) do
        local live = readings[fidKey(m.cid)] ~= nil
        cell(
            "mh " .. fmtInt(m.cid),
            (m.name .. "\nCID ") .. fmtInt(m.cid),
            live and "tracking" or "nopsn",
            live and ____exports.COLORS.on or ____exports.COLORS.bad,
            live and ____exports.COLORS.text or ____exports.COLORS.bad
        )
    end
    for ____, row in ipairs(rows) do
        do
            if row.members ~= nil then
                groupViews(cell, row, markers)
                goto __continue39
            end
            local r = row
            local fid = fmtInt(r.fixture.fid)
            local s = r.result.state
            cell("arm " .. fid, (fid .. "\n") .. r.fixture.name, r.armed and "tracking" or "idle", r.armed and ____exports.COLORS.on or ____exports.COLORS.idle)
            for ____, m in ipairs(markers) do
                local key = (("mx " .. fid) .. " ") .. fmtInt(m.cid)
                if r.programmerCid == m.cid then
                    cell(
                        key,
                        "P",
                        "programmer",
                        ____exports.COLORS.bad,
                        ____exports.COLORS.bad
                    )
                elseif r.markerCid == m.cid then
                    local color, look = table.unpack(
                        followLook({s}),
                        1,
                        2
                    )
                    cell(
                        key,
                        "●",
                        look,
                        color,
                        color
                    )
                else
                    cell(key, "", "idle")
                end
            end
            local marker = __TS__ArrayFind(
                markers,
                function(____, m) return m.cid == r.markerCid end
            )
            local detail = marker ~= nil and (((((marker.name .. " ") .. signed(r.offset.x)) .. "/") .. signed(r.offset.y)) .. "/") .. signed(r.offset.z) or ""
            cell(
                "st " .. fid,
                detail == "" and ____exports.stateLabel(s) or (____exports.stateLabel(s) .. "\n") .. detail,
                stateAppearance(s),
                stateColor(s)
            )
            cell(
                "di " .. fid,
                r.result.distance == nil and "—" or ((fmtNum(math.floor(r.result.distance * 10 + 0.5) / 10) .. " m\nbeam ") .. fmtNum(math.floor((r.result.achieved or 0) * 100 + 0.5) / 100)) .. " m",
                "idle"
            )
            cell(
                "zo " .. fid,
                r.result.zoom == nil and "—" or fmtNum(r.result.zoom) .. " %",
                "idle"
            )
            cell(
                "ir " .. fid,
                r.result.iris == nil and "—" or fmtNum(r.result.iris) .. " %",
                "idle"
            )
            cell(
                "sz " .. fid,
                (((r.sizeFixed and "Fixed" or "Global") .. "\n") .. fmtNum(math.floor(r.size * 100 + 0.5) / 100)) .. " m",
                "button"
            )
        end
        ::__continue39::
    end
    return v
end
return ____exports
 end,
["src.console.handles"] = function(...) 
local ____lualib = require("lualib_bundle")
local __TS__SourceMapTraceBack = ____lualib.__TS__SourceMapTraceBack
local ____exports = {}
---
-- @noSelfInFile
function ____exports.children(h)
    if h == nil then
        return {}
    end
    local list = h:Children()
    return list == nil and ({}) or list
end
function ____exports.num(v)
    if type(v) == "number" then
        return v
    end
    if type(v) == "string" then
        return tonumber(v)
    end
    return nil
end
function ____exports.findChild(collection, name)
    for ____, c in ipairs(____exports.children(collection)) do
        if c.name == name then
            return c
        end
    end
    return nil
end
return ____exports
 end,
["src.console.log"] = function(...) 
local ____lualib = require("lualib_bundle")
local __TS__SourceMapTraceBack = ____lualib.__TS__SourceMapTraceBack
local ____exports = {}
---
-- @noSelfInFile
local warned = {}
function ____exports.info(message)
    Printf("[AZ] " .. message)
end
function ____exports.warnOnce(key, message)
    if warned[key] then
        return
    end
    warned[key] = true
    Printf("[AZ warning] " .. message)
end
return ____exports
 end,
["src.console.appearances"] = function(...) 
local ____lualib = require("lualib_bundle")
local __TS__ArraySort = ____lualib.__TS__ArraySort
local __TS__ArrayFilter = ____lualib.__TS__ArrayFilter
local __TS__SourceMapTraceBack = ____lualib.__TS__SourceMapTraceBack
local ____exports = {}
local ____view_2Dmodel = require("src.ui.view-model")
local APPEARANCES = ____view_2Dmodel.APPEARANCES
local ____format = require("src.format")
local fmtInt = ____format.fmtInt
local ____handles = require("src.console.handles")
local children = ____handles.children
local num = ____handles.num
local ____log = require("src.console.log")
local warnOnce = ____log.warnOnce
local cache = {}
local function pool()
    return ShowData().Appearances
end
local function findByName(name)
    for ____, a in ipairs(children(pool())) do
        if a.name == name then
            return a
        end
    end
    return nil
end
____exports.APPEARANCE_BASE = 9001
local function occupied()
    local out = {}
    for ____, a in ipairs(children(pool())) do
        local n = num(a.No)
        if n ~= nil then
            out[fmtInt(n)] = true
        end
    end
    return out
end
local function farBase(count)
    local used = occupied()
    local start = ____exports.APPEARANCE_BASE
    local run = 0
    do
        local n = ____exports.APPEARANCE_BASE
        while n < ____exports.APPEARANCE_BASE + 10000 do
            do
                if used[fmtInt(n)] then
                    run = 0
                    start = n + 1
                    goto __continue13
                end
                run = run + 1
                if run == count then
                    return start
                end
            end
            ::__continue13::
            n = n + 1
        end
    end
    return start
end
local function createAt(no, name)
    local p = pool()
    if no > p:Count() then
        p:Resize(no)
    end
    local app = p:Create(
        no,
        p:GetChildClass()
    )
    app.Name = name
    return app
end
function ____exports.ensureAppearances()
    local kinds = {}
    for kind in pairs(APPEARANCES) do
        kinds[#kinds + 1] = kind
    end
    __TS__ArraySort(kinds)
    for ____, kind in ipairs(kinds) do
        do
            local app = findByName(APPEARANCES[kind].name)
            local ____temp_0
            if app == nil then
                ____temp_0 = nil
            else
                ____temp_0 = num(app.No)
            end
            local n = ____temp_0
            if n == nil or n >= ____exports.APPEARANCE_BASE then
                goto __continue21
            end
            do
                local function ____catch(e)
                    warnOnce(
                        "appearance-delete",
                        (((("Could not move appearance " .. fmtInt(n)) .. " to ") .. fmtInt(____exports.APPEARANCE_BASE)) .. "+: ") .. tostring(e)
                    )
                end
                local ____try, ____hasReturned = pcall(function()
                    Cmd(("Delete Appearance " .. fmtInt(n)) .. " /nc")
                end)
                if not ____try then
                    ____catch(____hasReturned)
                end
            end
        end
        ::__continue21::
    end
    local missing = __TS__ArrayFilter(
        kinds,
        function(____, k) return findByName(APPEARANCES[k].name) == nil end
    )
    local next = #missing > 0 and farBase(#missing) or 0
    for ____, kind in ipairs(kinds) do
        local spec = APPEARANCES[kind]
        local app = findByName(spec.name)
        if app == nil then
            app = createAt(next, spec.name)
            next = next + 1
        end
        if app.IMAGERGBA ~= spec.rgba then
            app.IMAGERGBA = spec.rgba
        end
        cache[kind] = app
    end
end
function ____exports.appearanceHandle(kind)
    local cached = cache[kind]
    if cached == false then
        return nil
    end
    if cached ~= nil and IsObjectValid(cached) then
        return cached
    end
    local spec = APPEARANCES[kind]
    local ____temp_1
    if spec == nil then
        ____temp_1 = nil
    else
        ____temp_1 = findByName(spec.name)
    end
    local app = ____temp_1
    local ____kind_3 = kind
    local ____temp_2
    if app == nil then
        ____temp_2 = false
    else
        ____temp_2 = app
    end
    cache[____kind_3] = ____temp_2
    return app
end
return ____exports
 end,
["src.console.pool"] = function(...) 
local ____lualib = require("lualib_bundle")
local Error = ____lualib.Error
local RangeError = ____lualib.RangeError
local ReferenceError = ____lualib.ReferenceError
local SyntaxError = ____lualib.SyntaxError
local TypeError = ____lualib.TypeError
local URIError = ____lualib.URIError
local __TS__New = ____lualib.__TS__New
local __TS__StringStartsWith = ____lualib.__TS__StringStartsWith
local __TS__SourceMapTraceBack = ____lualib.__TS__SourceMapTraceBack
local ____exports = {}
local sequenceSwitch, findCueOne, seqCache
local ____format = require("src.format")
local fmtInt = ____format.fmtInt
local fmtNum = ____format.fmtNum
local ____handles = require("src.console.handles")
local children = ____handles.children
local findChild = ____handles.findChild
local num = ____handles.num
local ____log = require("src.console.log")
local warnOnce = ____log.warnOnce
function ____exports.findPool()
    return findChild(
        ShowData().DataPools,
        ____exports.POOL
    )
end
function ____exports.ensurePool()
    local dp = ____exports.findPool()
    if dp == nil then
        Cmd(("Store " .. ____exports.POOL_ADDR) .. " /nc")
        dp = ____exports.findPool()
    end
    if dp == nil then
        error(
            __TS__New(Error, "Could not create the AutoZoom data pool"),
            0
        )
    end
    return dp
end
function ____exports.findSequence(name)
    local cached = seqCache[name]
    if cached ~= nil and IsObjectValid(cached) then
        return cached
    end
    local pool = ____exports.findPool()
    local ____temp_0
    if pool == nil then
        ____temp_0 = nil
    else
        ____temp_0 = findChild(pool.Sequences, name)
    end
    local seq = ____temp_0
    if seq ~= nil then
        seqCache[name] = seq
    end
    return seq
end
function ____exports.ensureCueSequence(name, fid, values)
    ____exports.ensurePool()
    if ____exports.findSequence(name) ~= nil then
        return
    end
    Cmd("ClearAll")
    Cmd("Fixture " .. fmtInt(fid))
    for ____, ____value in ipairs(values) do
        local attribute = ____value[1]
        local physical = ____value[2]
        Cmd((("Attribute \"" .. attribute) .. "\" At Absolute Physical ") .. fmtNum(physical))
    end
    Cmd(((("Store " .. ____exports.POOL_ADDR) .. " Sequence '") .. name) .. "' /o /nc")
    Cmd("ClearAll")
end
function sequenceSwitch(verb, name)
    if ____exports.findSequence(name) == nil then
        warnOnce("missing:" .. name, ("Sequence " .. name) .. " is missing; run Rescan to recreate it")
        return false
    end
    Cmd(((((verb .. " ") .. ____exports.POOL_ADDR) .. " Sequence '") .. name) .. "'")
    return true
end
function findCueOne(seq)
    local named = seq["Cue 1"]
    if named ~= nil then
        return named
    end
    for ____, c in ipairs(children(seq)) do
        local n = num(c.no)
        if n == 1 or n == 1000 then
            return c
        end
    end
    return nil
end
function ____exports.poolChildren(kind)
    local pool = ____exports.findPool()
    return pool == nil and ({}) or children(pool[kind])
end
____exports.POOL = "AutoZoom"
____exports.POOL_ADDR = ("DataPool '" .. ____exports.POOL) .. "'"
____exports.SIZE_SEQ = "AZ_SIZE"
____exports.PLUGIN_NAME = "GMA3 Autozoom"
____exports.START_MACRO = "AZ Start"
function ____exports.zoomSeqName(fid)
    return "AZ_ZOOM_" .. fmtInt(fid)
end
function ____exports.irisSeqName(fid)
    return "AZ_IRIS_" .. fmtInt(fid)
end
function ____exports.baseSeqName(fid)
    return "AZ_BASE_" .. fmtInt(fid)
end
seqCache = {}
function ____exports.ensureFaderSequence(name, fid, attribute, physical)
    ____exports.ensureCueSequence(name, fid, {{attribute, physical}})
end
function ____exports.setPriority(name, priority)
    Cmd(((((("Set " .. ____exports.POOL_ADDR) .. " Sequence '") .. name) .. "' Property 'Priority' '") .. priority) .. "'")
end
function ____exports.setNoOffWhenOverridden(name)
    Cmd(((("Set " .. ____exports.POOL_ADDR) .. " Sequence '") .. name) .. "' Property 'OffWhenOverridden' 'No'")
end
function ____exports.sequenceOn(name)
    return sequenceSwitch("On", name)
end
function ____exports.sequenceOff(name)
    return sequenceSwitch("Off", name)
end
function ____exports.ensureSizeSequence()
    ____exports.ensurePool()
    if ____exports.findSequence(____exports.SIZE_SEQ) ~= nil then
        return
    end
    Cmd("ClearAll")
    Cmd(((("Store " .. ____exports.POOL_ADDR) .. " Sequence '") .. ____exports.SIZE_SEQ) .. "' /o /nc")
end
local function writeMacroLine(name, command)
    Cmd(((("Store " .. ____exports.POOL_ADDR) .. " Macro '") .. name) .. "'.1 /o /nc")
    Cmd(((((("Set " .. ____exports.POOL_ADDR) .. " Macro '") .. name) .. "'.1 Property 'Command' '") .. command) .. "'")
end
____exports.CELL_PREFIX = "AZ "
function ____exports.cellSequenceName(key)
    return ____exports.CELL_PREFIX .. key
end
function ____exports.ensureCellSequence(name, luaCall)
    local dp = ____exports.ensurePool()
    local command = luaCall == "" and "" or ("Lua \"if AZ then AZ:" .. luaCall) .. " end\""
    local seq = ____exports.findSequence(name)
    if seq == nil then
        seq = dp.Sequences:Acquire()
        seq.Name = name
        local cue = seq:Append()
        cue.No = 1
        local part = cue:Create(1)
        part.Command = command
        return seq
    end
    local cue = findCueOne(seq)
    if cue == nil then
        cue = seq:Append()
        cue.No = 1
        cue:Create(1)
    end
    local part = children(cue)[1]
    local ____temp_3 = part ~= nil
    if ____temp_3 then
        local ____tostring_2 = tostring
        local ____part_Command_1 = part.Command
        if ____part_Command_1 == nil then
            ____part_Command_1 = ""
        end
        ____temp_3 = ____tostring_2(____part_Command_1) ~= command
    end
    if ____temp_3 then
        part.Command = command
    end
    return seq
end
function ____exports.removeCellMacros()
    local names = {}
    for ____, m in ipairs(____exports.poolChildren("Macros")) do
        local ____tostring_5 = tostring
        local ____m_name_4 = m.name
        if ____m_name_4 == nil then
            ____m_name_4 = ""
        end
        local name = ____tostring_5(____m_name_4)
        if __TS__StringStartsWith(name, ____exports.CELL_PREFIX) and name ~= ____exports.START_MACRO then
            names[#names + 1] = name
        end
    end
    for ____, name in ipairs(names) do
        Cmd(((("Delete " .. ____exports.POOL_ADDR) .. " Macro '") .. name) .. "' /nc")
    end
end
function ____exports.ensureRawMacro(name, command)
    local pool = ____exports.ensurePool()
    if findChild(pool.Macros, name) ~= nil then
        return
    end
    Cmd(((("Store " .. ____exports.POOL_ADDR) .. " Macro '") .. name) .. "' /o /nc")
    writeMacroLine(name, command)
end
function ____exports.setTemp(name, value)
    local seq = ____exports.findSequence(name)
    if seq == nil then
        warnOnce("missing:" .. name, ("Sequence " .. name) .. " is missing; run Rescan to recreate it")
        return
    end
    seq:SetFader({value = value, token = "FaderTemp"})
end
function ____exports.readMaster(name)
    local seq = ____exports.findSequence(name)
    if seq == nil then
        return nil
    end
    local v = seq:GetFader({token = "FaderMaster"})
    return type(v) == "number" and v or nil
end
return ____exports
 end,
["src.console.layout"] = function(...) 
local ____lualib = require("lualib_bundle")
local __TS__StringStartsWith = ____lualib.__TS__StringStartsWith
local Error = ____lualib.Error
local RangeError = ____lualib.RangeError
local ReferenceError = ____lualib.ReferenceError
local SyntaxError = ____lualib.SyntaxError
local TypeError = ____lualib.TypeError
local URIError = ____lualib.URIError
local __TS__New = ____lualib.__TS__New
local __TS__StringSubstring = ____lualib.__TS__StringSubstring
local __TS__ArraySort = ____lualib.__TS__ArraySort
local __TS__SourceMapTraceBack = ____lualib.__TS__SourceMapTraceBack
local ____exports = {}
local ____appearances = require("src.console.appearances")
local appearanceHandle = ____appearances.appearanceHandle
local ____handles = require("src.console.handles")
local children = ____handles.children
local findChild = ____handles.findChild
local ____log = require("src.console.log")
local warnOnce = ____log.warnOnce
local ____pool = require("src.console.pool")
local CELL_PREFIX = ____pool.CELL_PREFIX
local cellSequenceName = ____pool.cellSequenceName
local ensureCellSequence = ____pool.ensureCellSequence
local ensurePool = ____pool.ensurePool
local findPool = ____pool.findPool
local POOL_ADDR = ____pool.POOL_ADDR
____exports.LAYOUT = "AutoZoom"
local TAG = "AZ:"
local elements = {}
local sequences = {}
local written = {}
local sentinel = nil
local HIDDEN = {
    {"VisibilityElement", true},
    {"VisibilityObjectName", false},
    {"VisibilityIcon", false},
    {"VisibilityID", false},
    {"VisibilityCID", false},
    {"VisibilityValue", false},
    {"VisibilityBar", false},
    {"VisibilityBorder", false},
    {"BorderSize", 0},
    {"CustomTextAlignmentV", "Center"},
    {"CustomTextAlignmentH", "Center"}
}
local function hideDetails(el)
    for ____, ____value in ipairs(HIDDEN) do
        local prop = ____value[1]
        local value = ____value[2]
        do
            local function ____catch(e)
                warnOnce(
                    "visibility",
                    (("Could not set layout element " .. prop) .. ": ") .. tostring(e)
                )
            end
            local ____try, ____hasReturned = pcall(function()
                el[prop] = value
            end)
            if not ____try then
                ____catch(____hasReturned)
            end
        end
    end
end
local function clearAppearance(el)
    do
        local function ____catch(e)
            warnOnce(
                "el-appearance",
                "Could not clear layout element Appearance: " .. tostring(e)
            )
        end
        local ____try, ____hasReturned = pcall(function()
            el.Appearance = nil
        end)
        if not ____try then
            ____catch(____hasReturned)
        end
    end
end
local function setAction(el, clickable)
    if clickable then
        el.Action = "Go+"
        return
    end
    do
        local function ____catch(e)
            warnOnce(
                "action",
                "Could not set layout element Action Pause: " .. tostring(e)
            )
            el.Action = "Go+"
        end
        local ____try, ____hasReturned = pcall(function()
            el.Action = "Pause"
        end)
        if not ____try then
            ____catch(____hasReturned)
        end
    end
end
local function removeStaleSequences(pool, cells)
    local wanted = {}
    for ____, cell in ipairs(cells) do
        wanted[cellSequenceName(cell.key)] = true
    end
    local stale = {}
    for ____, s in ipairs(children(pool.Sequences)) do
        local ____tostring_1 = tostring
        local ____s_name_0 = s.name
        if ____s_name_0 == nil then
            ____s_name_0 = ""
        end
        local name = ____tostring_1(____s_name_0)
        if __TS__StringStartsWith(name, CELL_PREFIX) and not wanted[name] then
            stale[#stale + 1] = name
        end
    end
    for ____, name in ipairs(stale) do
        Cmd(((("Delete " .. POOL_ADDR) .. " Sequence '") .. name) .. "' /nc")
    end
end
function ____exports.buildLayout(cells)
    local pool = ensurePool()
    removeStaleSequences(pool, cells)
    if findChild(pool.Layouts, ____exports.LAYOUT) == nil then
        Cmd(((("Store " .. POOL_ADDR) .. " Layout '") .. ____exports.LAYOUT) .. "' /o /nc")
    end
    local layout = findChild(pool.Layouts, ____exports.LAYOUT)
    if layout == nil then
        error(
            __TS__New(Error, "Could not create the AutoZoom layout"),
            0
        )
    end
    local existing = {}
    local doomedDupes = {}
    for ____, el in ipairs(children(layout)) do
        do
            local ____tostring_3 = tostring
            local ____el_Note_2 = el.Note
            if ____el_Note_2 == nil then
                ____el_Note_2 = ""
            end
            local note = ____tostring_3(____el_Note_2)
            if not __TS__StringStartsWith(note, TAG) then
                goto __continue25
            end
            local key = __TS__StringSubstring(note, #TAG)
            if existing[key] == nil then
                existing[key] = el
            else
                doomedDupes[#doomedDupes + 1] = el
            end
        end
        ::__continue25::
    end
    elements = {}
    sequences = {}
    written = {}
    sentinel = nil
    local wanted = {}
    for ____, cell in ipairs(cells) do
        wanted[cell.key] = true
        local seq = ensureCellSequence(
            cellSequenceName(cell.key),
            cell.command
        )
        local ____existing_cell_key_4 = existing[cell.key]
        if ____existing_cell_key_4 == nil then
            ____existing_cell_key_4 = layout:Append()
        end
        local el = ____existing_cell_key_4
        el.Object = seq
        clearAppearance(el)
        setAction(el, cell.command ~= "")
        el.Note = TAG .. cell.key
        el.PosX = cell.x
        el.PosY = cell.y
        el.Width = cell.w
        el.Height = cell.h
        hideDetails(el)
        elements[cell.key] = el
        sequences[cell.key] = seq
        if sentinel == nil then
            sentinel = el
        end
    end
    local doomed = {}
    for key in pairs(existing) do
        if not wanted[key] then
            doomed[#doomed + 1] = existing[key]
        end
    end
    for ____, el in ipairs(doomedDupes) do
        doomed[#doomed + 1] = el
    end
    local targets = {}
    for ____, el in ipairs(doomed) do
        local no = tonumber(el.No)
        if no == nil then
            warnOnce("layout-delete-no", "Could not delete a stale AutoZoom cell: element has no number")
        else
            targets[#targets + 1] = {no = no, el = el}
        end
    end
    __TS__ArraySort(
        targets,
        function(____, x, y) return y.no - x.no end
    )
    for ____, t in ipairs(targets) do
        do
            local function ____catch(e)
                warnOnce(
                    "layoutdelete",
                    (("Could not delete stale layout element " .. tostring(t.no)) .. ": ") .. tostring(e)
                )
            end
            local ____try, ____hasReturned = pcall(function()
                local slot = nil
                for ____, el in ipairs(children(layout)) do
                    if tonumber(el.No) == t.no then
                        slot = el
                    end
                end
                if slot == t.el then
                    layout:Delete(t.no)
                else
                    warnOnce(
                        "layout-delete",
                        ("Layout slot " .. tostring(t.no)) .. " no longer holds the stale AutoZoom cell; kept a stale AutoZoom cell"
                    )
                end
            end)
            if not ____try then
                ____catch(____hasReturned)
            end
        end
    end
end
local function findElements()
    elements = {}
    sequences = {}
    written = {}
    sentinel = nil
    local pool = findPool()
    if pool == nil then
        return
    end
    local layout = findChild(pool.Layouts, ____exports.LAYOUT)
    if layout == nil then
        return
    end
    for ____, el in ipairs(children(layout)) do
        do
            local ____tostring_6 = tostring
            local ____el_Note_5 = el.Note
            if ____el_Note_5 == nil then
                ____el_Note_5 = ""
            end
            local note = ____tostring_6(____el_Note_5)
            if not __TS__StringStartsWith(note, TAG) then
                goto __continue55
            end
            local key = __TS__StringSubstring(note, #TAG)
            elements[key] = el
            sequences[key] = el.Object
            if sentinel == nil then
                sentinel = el
            end
        end
        ::__continue55::
    end
end
function ____exports.refreshLayout(views)
    local rescanned = false
    if sentinel ~= nil and not IsObjectValid(sentinel) then
        rescanned = true
        findElements()
    end
    for key in pairs(views) do
        do
            local view = views[key]
            local signature = (((((view.text .. "|") .. view.border) .. "|") .. view.textColor) .. "|") .. view.appearance
            if written[key] == signature then
                goto __continue61
            end
            local el = elements[key]
            if el == nil or not IsObjectValid(el) then
                if rescanned then
                    goto __continue61
                end
                rescanned = true
                findElements()
                el = elements[key]
                if el == nil then
                    goto __continue61
                end
            end
            el.CustomTextText = view.text
            el.CustomTextColor = view.textColor
            el.BorderColor = view.border
            local seq = sequences[key]
            local app = appearanceHandle(view.appearance)
            if seq ~= nil and IsObjectValid(seq) and app ~= nil and seq.Appearance ~= app then
                seq.Appearance = app
            end
            written[key] = signature
        end
        ::__continue61::
    end
end
return ____exports
 end,
["src.console.live"] = function(...) 
local ____lualib = require("lualib_bundle")
local __TS__StringStartsWith = ____lualib.__TS__StringStartsWith
local __TS__StringTrim = ____lualib.__TS__StringTrim
local __TS__ArrayIndexOf = ____lualib.__TS__ArrayIndexOf
local __TS__SourceMapTraceBack = ____lualib.__TS__SourceMapTraceBack
local ____exports = {}
local ____vec = require("src.engine.vec")
local vec = ____vec.vec
local ____format = require("src.format")
local fidKey = ____format.fidKey
local ____handles = require("src.console.handles")
local children = ____handles.children
local num = ____handles.num
____exports.RAW_FULL = 16777216
____exports.APPLY_MARKER_ROTATION = false
____exports.TRACKER_ROTATION_PROPS = {"ROTX", "ROTY", "ROTZ"}
____exports.DEFAULT_TARGET_SPACE = {
    min = vec(-100, -100, 0),
    max = vec(100, 100, 100)
}
function ____exports.rawToMetres(raw, min, max)
    return min + (max - min) * raw / ____exports.RAW_FULL
end
local function rt(uich)
    local r = GetRTChannel(uich)
    local ____temp_0
    if r == nil then
        ____temp_0 = nil
    else
        ____temp_0 = r.info
    end
    return ____temp_0
end
function ____exports.readMarkerCid(f)
    local ____num_3 = num
    local ____opt_1 = rt(f.uich.marker)
    if ____opt_1 ~= nil then
        ____opt_1 = ____opt_1.value_after_master
    end
    local v = ____num_3(____opt_1)
    return v == nil and 0 or math.floor(v)
end
function ____exports.readProgrammerCid(f)
    local info = rt(f.uich.marker)
    if info == nil or not __TS__StringStartsWith(
        tostring(info.cue_part),
        "Programmer"
    ) then
        return 0
    end
    return math.floor(num(info.value_after_master) or 0)
end
local function axis(uich, min, max)
    local ____num_6 = num
    local ____opt_4 = rt(uich)
    if ____opt_4 ~= nil then
        ____opt_4 = ____opt_4.value_after_master
    end
    local raw = ____num_6(____opt_4)
    return raw == nil and 0 or ____exports.rawToMetres(raw, min, max)
end
function ____exports.readOffset(f, markers)
    local cid = ____exports.readMarkerCid(f)
    if cid == 0 then
        return vec(0, 0, 0)
    end
    local space = ____exports.DEFAULT_TARGET_SPACE
    for ____, m in ipairs(markers) do
        if m.cid == cid then
            space = m.targetSpace
            break
        end
    end
    return vec(
        axis(f.uich.x, space.min.x, space.max.x),
        axis(f.uich.y, space.min.y, space.max.y),
        axis(f.uich.z, space.min.z, space.max.z)
    )
end
local ONLINE_WORDS = {"yes", "on", "true", "1"}
function ____exports.isOnline(v)
    if v == true or v == 1 then
        return true
    end
    if type(v) ~= "string" then
        return false
    end
    return __TS__ArrayIndexOf(
        ONLINE_WORDS,
        string.lower(__TS__StringTrim(v))
    ) >= 0
end
function ____exports.readMarkers()
    local out = {}
    for ____, system in ipairs(children(ShowData().PSNProtocol)) do
        for ____, tracker in ipairs(children(system)) do
            do
                local cid = num(tracker.MARKERID)
                if cid == nil or cid == 0 then
                    goto __continue18
                end
                if not ____exports.isOnline(tracker.ISONLINE) then
                    goto __continue18
                end
                local pos = vec(
                    num(tracker.POSITIONX) or 0,
                    num(tracker.POSITIONY) or 0,
                    num(tracker.POSITIONZ) or 0
                )
                local rot = ____exports.APPLY_MARKER_ROTATION and vec(
                    num(tracker[____exports.TRACKER_ROTATION_PROPS[1]]) or 0,
                    num(tracker[____exports.TRACKER_ROTATION_PROPS[2]]) or 0,
                    num(tracker[____exports.TRACKER_ROTATION_PROPS[3]]) or 0
                ) or nil
                out[fidKey(cid)] = {pos = pos, rot = rot}
            end
            ::__continue18::
        end
    end
    return out
end
return ____exports
 end,
["src.console.patch"] = function(...) 
local ____lualib = require("lualib_bundle")
local __TS__StringSubstring = ____lualib.__TS__StringSubstring
local __TS__StringTrim = ____lualib.__TS__StringTrim
local __TS__ArraySort = ____lualib.__TS__ArraySort
local __TS__SourceMapTraceBack = ____lualib.__TS__SourceMapTraceBack
local ____exports = {}
local ____vec = require("src.engine.vec")
local add = ____vec.add
local rotate = ____vec.rotate
local vec = ____vec.vec
local ____format = require("src.format")
local fidKey = ____format.fidKey
local fmtInt = ____format.fmtInt
local ____handles = require("src.console.handles")
local children = ____handles.children
local findChild = ____handles.findChild
local num = ____handles.num
local ____live = require("src.console.live")
local DEFAULT_TARGET_SPACE = ____live.DEFAULT_TARGET_SPACE
local XYZ_ATTRIBUTES = {"XYZ_MArker", "XYZ_X", "XYZ_Y", "XYZ_Z"}
local function readOptics(mode)
    local zoom
    local iris
    for ____, channel in ipairs(children(mode.DMXChannels)) do
        do
            local logical = children(channel)[1]
            if logical == nil then
                goto __continue3
            end
            local fn = children(logical)[1]
            if fn == nil then
                goto __continue3
            end
            local from = num(fn.physicalFrom)
            local to = num(fn.physicalTo)
            if from == nil or to == nil then
                goto __continue3
            end
            local range = {
                math.min(from, to),
                math.max(from, to)
            }
            if logical.attribute == "Zoom" then
                zoom = range
            end
            if logical.attribute == "Iris" then
                iris = range
            end
        end
        ::__continue3::
    end
    if zoom == nil then
        return nil
    end
    return {zoomMin = zoom[1], zoomMax = zoom[2], irisMin = iris == nil and 0 or iris[1], irisMax = iris == nil and 0 or iris[2]}
end
local function xyzModes()
    local out = {}
    local patch = Patch()
    for ____, ft in ipairs(children(patch.FixtureTypes)) do
        for ____, mode in ipairs(children(ft.DMXModes)) do
            do
                if mode.XYZ ~= true then
                    goto __continue13
                end
                local optics = readOptics(mode)
                if optics ~= nil then
                    out[(tostring(ft.name) .. "|") .. tostring(mode.name)] = optics
                end
            end
            ::__continue13::
        end
    end
    return out
end
local function modeName(node)
    local ____node_ModeDirect_0 = node.ModeDirect
    if ____node_ModeDirect_0 == nil then
        ____node_ModeDirect_0 = node.Mode
    end
    local m = ____node_ModeDirect_0
    if m == nil then
        return nil
    end
    if type(m) ~= "string" then
        return m.name
    end
    local space = (string.find(m, " ", nil, true) or 0) - 1
    return space > 0 and num(__TS__StringSubstring(m, 0, space)) ~= nil and __TS__StringSubstring(m, space + 1) or m
end
local function subfixtureIndexes()
    local out = {}
    local count = GetSubfixtureCount()
    do
        local i = 0
        while i <= count do
            local sf = GetSubfixture(i)
            local ____temp_1
            if sf == nil then
                ____temp_1 = nil
            else
                ____temp_1 = num(sf.fid)
            end
            local fid = ____temp_1
            if fid ~= nil and out[fidKey(fid)] == nil then
                out[fidKey(fid)] = i
            end
            i = i + 1
        end
    end
    return out
end
local function transformOf(node, parent)
    local pos = vec(
        num(node.POSX) or 0,
        num(node.POSY) or 0,
        num(node.POSZ) or 0
    )
    local rot = vec(
        num(node.ROTX) or 0,
        num(node.ROTY) or 0,
        num(node.ROTZ) or 0
    )
    return {
        pos = add(
            parent.pos,
            rotate(pos, parent.rot)
        ),
        rot = add(parent.rot, rot)
    }
end
local function readSpace(h)
    if h == nil or type(h) == "string" or type(h) == "number" or type(h) == "boolean" then
        return nil
    end
    local minX = num(h.MINX)
    local minY = num(h.MINY)
    local minZ = num(h.MINZ)
    local maxX = num(h.MAXX)
    local maxY = num(h.MAXY)
    local maxZ = num(h.MAXZ)
    if minX == nil or minY == nil or minZ == nil or maxX == nil or maxY == nil or maxZ == nil then
        return nil
    end
    return {
        min = vec(minX, minY, minZ),
        max = vec(maxX, maxY, maxZ)
    }
end
local function nameFromRef(ref)
    local a = (string.find(ref, "'", nil, true) or 0) - 1
    if a >= 0 then
        local b = (string.find(
            ref,
            "'",
            math.max(a + 1 + 1, 1),
            true
        ) or 0) - 1
        if b >= 0 then
            return __TS__StringSubstring(ref, a + 1, b)
        end
    end
    return __TS__StringTrim(ref)
end
local function targetSpaceOf(marker, stage)
    local ref = marker.TARGETSPACE
    local ____temp_2
    if type(ref) == "string" then
        ____temp_2 = readSpace(findChild(
            stage.Spaces,
            nameFromRef(ref)
        ))
    else
        ____temp_2 = readSpace(ref)
    end
    local byRef = ____temp_2
    return byRef or readSpace(findChild(
        stage.Spaces,
        tostring(marker.name) .. " Target"
    )) or DEFAULT_TARGET_SPACE
end
function ____exports.scanPatch()
    local scan = {fixtures = {}, markers = {}, problems = {}}
    local modes = xyzModes()
    local subIndex = subfixtureIndexes()
    local attrIndex = {}
    for ____, a in ipairs(XYZ_ATTRIBUTES) do
        attrIndex[#attrIndex + 1] = GetAttributeIndex(a) or -1
    end
    local function walk(node, parent, stage)
        if node.IDType == "MArker" then
            local cid = num(node.cid)
            if cid ~= nil then
                local ____scan_markers_6 = scan.markers
                local ____cid_5 = cid
                local ____tostring_4 = tostring
                local ____node_name_3 = node.name
                if ____node_name_3 == nil then
                    ____node_name_3 = "Marker " .. fmtInt(cid)
                end
                ____scan_markers_6[#____scan_markers_6 + 1] = {
                    cid = ____cid_5,
                    name = ____tostring_4(____node_name_3),
                    targetSpace = targetSpaceOf(node, stage)
                }
            end
            return
        end
        local t = transformOf(node, parent)
        for ____, child in ipairs(children(node)) do
            walk(child, t, stage)
        end
        local fid = num(node.fid)
        local ft = node.FixtureType
        if fid == nil or ft == nil then
            return
        end
        local optics = modes[(tostring(ft.name) .. "|") .. tostring(modeName(node))]
        if optics == nil then
            return
        end
        local sub = subIndex[fidKey(fid)]
        local ui = {}
        for ____, a in ipairs(attrIndex) do
            local ____temp_7
            if sub == nil or a < 0 then
                ____temp_7 = nil
            else
                ____temp_7 = GetUIChannelIndex(sub, a)
            end
            local u = ____temp_7
            if u == nil then
                break
            end
            ui[#ui + 1] = u
        end
        if #ui < 4 then
            local ____scan_problems_8 = scan.problems
            ____scan_problems_8[#____scan_problems_8 + 1] = ("Fixture " .. fmtInt(fid)) .. ": XYZ attributes not found, skipped"
            return
        end
        local ____scan_fixtures_9 = scan.fixtures
        ____scan_fixtures_9[#____scan_fixtures_9 + 1] = {
            fid = fid,
            name = tostring(node.name),
            position = t.pos,
            optics = optics,
            uich = {marker = ui[1], x = ui[2], y = ui[3], z = ui[4]}
        }
    end
    local origin = {
        pos = vec(0, 0, 0),
        rot = vec(0, 0, 0)
    }
    for ____, stage in ipairs(children(Patch().Stages)) do
        for ____, node in ipairs(children(stage.Fixtures)) do
            walk(node, origin, stage)
        end
    end
    __TS__ArraySort(
        scan.fixtures,
        function(____, a, b) return a.fid - b.fid end
    )
    __TS__ArraySort(
        scan.markers,
        function(____, a, b) return a.cid - b.cid end
    )
    return scan
end
return ____exports
 end,
["src.console.window"] = function(...) 
local ____lualib = require("lualib_bundle")
local __TS__ArrayForEach = ____lualib.__TS__ArrayForEach
local __TS__SourceMapTraceBack = ____lualib.__TS__SourceMapTraceBack
local ____exports = {}
---
-- @noSelfInFile
local SCROLLBAR_WIDTH = 30
local signalTable = {}
local pluginHandle
function ____exports.setPlugin(signals, handle)
    local ____signals_0 = signals
    if ____signals_0 == nil then
        ____signals_0 = {}
    end
    signalTable = ____signals_0
    pluginHandle = handle
end
function ____exports.color(group, name)
    local ok, c = pcall(function() return Root().ColorTheme.ColorGroups[group][name] end)
    local ____ok_1
    if ok then
        ____ok_1 = c
    else
        ____ok_1 = nil
    end
    return ____ok_1
end
local function screenOverlay()
    local idx = Obj:Index(GetFocusDisplay())
    if idx > 5 then
        idx = 1
    end
    return GetDisplayByIndex(idx).ScreenOverlay
end
local function set(obj, key, value)
    pcall(function()
        obj[key] = value
    end)
end
function ____exports.buildBase(title, width)
    local overlay = screenOverlay()
    overlay:ClearUIChildren()
    local base = overlay:Append("BaseInput")
    base.Name = title
    base.W = width
    base.Rows = 2
    base[1][1].SizePolicy = "Fixed"
    base[1][1].Size = "60"
    base[1][2].SizePolicy = "Content"
    local titleBar = base:Append("TitleBar")
    titleBar.Columns = 2
    titleBar.Anchors = "0,0"
    titleBar[2][2].SizePolicy = "Fixed"
    titleBar[2][2].Size = "50"
    set(titleBar, "Texture", "corner2")
    local titleBtn = titleBar:Append("TitleButton")
    titleBtn.Text = title
    set(titleBtn, "Texture", "corner1")
    titleBtn.Anchors = "0,0"
    set(titleBtn, "Icon", "wizard")
    local closeBtn = titleBar:Append("CloseButton")
    closeBtn.Anchors = "1,0"
    set(closeBtn, "Texture", "corner2")
    local body = base:Append("DialogFrame")
    body.H = "100%"
    body.W = "100%"
    body.Anchors = "0,1"
    set(body, "Margin", "2,5")
    return body
end
function ____exports.fixedRows(body, sizes)
    body.Columns = 1
    body.Rows = #sizes
    __TS__ArrayForEach(
        sizes,
        function(____, s, i)
            body[1][i + 1].SizePolicy = "Fixed"
            body[1][i + 1].Size = tostring(s)
        end
    )
end
function ____exports.row(parent, anchorRow)
    local r = parent:Append("AutoLayout")
    r.Anchors = "0," .. tostring(anchorRow)
    r.W = "100%"
    r.H = "100%"
    r.Direction = "Horizontal"
    r.Content = "Yes"
    set(r, "Margin", "5,5,5,5")
    return r
end
function ____exports.label(parent, text, w, h)
    local b = parent:Append("Button")
    b.W = w
    b.H = h
    b.Text = text
    set(b, "Texture", "corner5")
    set(b, "TextAlignmentH", "Left")
    set(b, "TextAlignmentV", "Centre")
    set(b, "Padding", "15,5,15,5")
    set(b, "Font", "Medium20")
    set(b, "Focus", "Never")
    set(b, "HasHover", "No")
    return b
end
function ____exports.button(parent, text, w, h, signal, fn)
    local b = parent:Append("Button")
    b.W = w
    b.H = h
    b.Text = text
    set(b, "Texture", "corner15")
    set(b, "TextAlignmentH", "Centre")
    set(b, "TextAlignmentV", "Centre")
    set(b, "Focus", "Never")
    set(b, "HasHover", "Yes")
    set(b, "Margin", "0,0,5,0")
    b.PluginComponent = pluginHandle
    b.Clicked = signal
    signalTable[signal] = fn
    return b
end
function ____exports.scrollGrid(parent, anchorRow, width, contentHeight, columns, rows)
    local frame = parent:Append("AutoLayout")
    frame.Anchors = "0," .. tostring(anchorRow)
    frame.W = "100%"
    frame.H = "100%"
    frame.Direction = "Horizontal"
    frame.Content = "Yes"
    local box = frame:Append("ScrollBox")
    box.W = width - SCROLLBAR_WIDTH - 20
    box.H = "100%"
    local bar = frame:Append("ScrollBarV")
    bar.W = SCROLLBAR_WIDTH
    bar.H = "100%"
    bar.ScrollTarget = box
    local grid = box:Append("UILayoutGrid")
    grid.Anchors = "0,0"
    grid.W = "100%"
    grid.H = contentHeight
    grid.Columns = columns
    grid.Rows = rows
    return grid
end
function ____exports.paint(obj, c)
    if c ~= nil then
        set(obj, "BackColor", c)
    end
end
function ____exports.closeWindow()
    screenOverlay():ClearUIChildren()
end
function ____exports.ask(title, message)
    local r = MessageBox({title = title, message = message, commands = {{value = 1, name = "Yes"}, {value = 0, name = "No"}}})
    return r ~= nil and r.result == 1
end
return ____exports
 end,
["src.console.preset-picker"] = function(...) 
local ____lualib = require("lualib_bundle")
local __TS__ArraySort = ____lualib.__TS__ArraySort
local __TS__StringStartsWith = ____lualib.__TS__StringStartsWith
local __TS__ArrayFind = ____lualib.__TS__ArrayFind
local __TS__ArrayForEach = ____lualib.__TS__ArrayForEach
local __TS__SourceMapTraceBack = ____lualib.__TS__SourceMapTraceBack
local ____exports = {}
local ____window = require("src.console.window")
local button = ____window.button
local buildBase = ____window.buildBase
local closeWindow = ____window.closeWindow
local color = ____window.color
local fixedRows = ____window.fixedRows
local label = ____window.label
local paint = ____window.paint
local row = ____window.row
local scrollGrid = ____window.scrollGrid
local WIDTH = 1100
local COLUMNS = 4
local TILE_HEIGHT = 70
local MAX_HEIGHT = 520
local TAB_HEIGHT = 70
local HINT_HEIGHT = 60
local FOOTER_HEIGHT = 70
local SCROLLBAR_WIDTH = 30
local function listPools()
    local out = {}
    local ok, pools = pcall(function() return DataPool().PresetPools:Children() end)
    if not ok or type(pools) ~= "table" then
        return out
    end
    for ____, pool in ipairs(pools) do
        local okPool, presets = pcall(function() return pool:Children() end)
        local list = {}
        local ____okPool_4
        if okPool then
            ____okPool_4 = presets
        else
            ____okPool_4 = {}
        end
        for ____, p in ipairs(____okPool_4) do
            local no = tonumber(p.no)
            if no ~= nil then
                local ____temp_2 = (tostring(pool.no) .. ".") .. tostring(no)
                local ____no_3 = no
                local ____tostring_1 = tostring
                local ____p_name_0 = p.name
                if ____p_name_0 == nil then
                    ____p_name_0 = ""
                end
                list[#list + 1] = {
                    addr = ____temp_2,
                    no = ____no_3,
                    name = ____tostring_1(____p_name_0),
                    handle = p
                }
            end
        end
        __TS__ArraySort(
            list,
            function(____, a, b) return a.no - b.no end
        )
        local poolNo = tonumber(pool.no)
        if #list > 0 and poolNo ~= nil then
            local ____tostring_6 = tostring
            local ____pool_name_5 = pool.name
            if ____pool_name_5 == nil then
                ____pool_name_5 = ""
            end
            out[#out + 1] = {
                no = poolNo,
                name = ____tostring_6(____pool_name_5),
                presets = list
            }
        end
    end
    __TS__ArraySort(
        out,
        function(____, a, b) return a.no - b.no end
    )
    return out
end
local function hasXYZ(preset)
    local ok, data = pcall(function() return GetPresetData(preset, false, true) end)
    if not ok or type(data) ~= "table" or type(data.by_fixtures) ~= "table" then
        return false
    end
    for ____, attrs in pairs(data.by_fixtures) do
        do
            if type(attrs) ~= "table" then
                goto __continue17
            end
            for name in pairs(attrs) do
                if __TS__StringStartsWith(
                    string.upper(tostring(name)),
                    "XYZ_"
                ) then
                    return true
                end
            end
        end
        ::__continue17::
    end
    return false
end
function ____exports.openPresetPicker(current, onPick)
    local pools = listPools()
    local poolOfCurrent = string.match(current, "^(%d+)%.")
    local xyz = {}
    local shown = tonumber(poolOfCurrent) or 2
    local function draw()
        local body = buildBase("AutoZoom — choose the XYZ offset preset", WIDTH)
        local pool = __TS__ArrayFind(
            pools,
            function(____, p) return p.no == shown end
        ) or pools[1]
        local presets = pool and pool.presets or ({})
        local rows = math.max(
            1,
            math.ceil(#presets / COLUMNS)
        )
        local content = rows * TILE_HEIGHT + 10
        fixedRows(
            body,
            {
                TAB_HEIGHT,
                HINT_HEIGHT,
                math.min(content, MAX_HEIGHT),
                FOOTER_HEIGHT
            }
        )
        local tabs = row(body, 0)
        local tabW = math.min(
            180,
            math.floor((WIDTH - 20) / math.max(#pools, 1)) - 5
        )
        __TS__ArrayForEach(
            pools,
            function(____, p, i)
                local b = button(
                    tabs,
                    (tostring(p.no) .. "\n") .. p.name,
                    tabW,
                    TAB_HEIGHT - 10,
                    "AZW_PickPool_" .. tostring(i + 1),
                    function()
                        shown = p.no
                        draw()
                    end
                )
                if pool ~= nil and p.no == pool.no then
                    paint(
                        b,
                        color("ProgLayer", "Absolute")
                    )
                end
            end
        )
        label(
            row(body, 1),
            "Tap the preset that holds the XYZ offset. Greyed: no XYZ values.",
            WIDTH - 30,
            HINT_HEIGHT - 10
        )
        local grid = scrollGrid(
            body,
            2,
            WIDTH,
            content,
            COLUMNS,
            rows
        )
        local tileW = math.floor((WIDTH - SCROLLBAR_WIDTH - 40) / COLUMNS)
        if #presets == 0 then
            label(grid, "No presets in the show.", WIDTH - 80, TILE_HEIGHT - 6).Anchors = "0,0"
        end
        __TS__ArrayForEach(
            presets,
            function(____, p, i)
                if xyz[p.addr] == nil then
                    xyz[p.addr] = hasXYZ(p.handle)
                end
                local usable = xyz[p.addr]
                local tile = button(
                    grid,
                    (((p.addr .. "  ") .. p.name) .. "\n") .. (usable and "XYZ" or "no XYZ"),
                    tileW,
                    TILE_HEIGHT - 6,
                    "AZW_PickTile_" .. tostring(i + 1),
                    function()
                        closeWindow()
                        onPick(p.addr)
                    end
                )
                tile.Anchors = (tostring(i % COLUMNS) .. ",") .. tostring(math.floor(i / COLUMNS))
                pcall(function()
                    tile.TextAlignmentH = "Left"
                    tile.Margin = "3,3,3,3"
                    tile.Texture = "corner5"
                end)
                if p.addr == current then
                    paint(
                        tile,
                        color("ProgLayer", "Absolute")
                    )
                end
                if not usable then
                    pcall(function()
                        tile.Enabled = "No"
                    end)
                end
            end
        )
        button(
            row(body, 3),
            "Cancel",
            200,
            FOOTER_HEIGHT - 20,
            "AZW_PickCancel",
            function() return closeWindow() end
        )
    end
    draw()
end
return ____exports
 end,
["src.console.ui"] = function(...) 
local ____lualib = require("lualib_bundle")
local __TS__ArrayMap = ____lualib.__TS__ArrayMap
local __TS__SourceMapTraceBack = ____lualib.__TS__SourceMapTraceBack
local ____exports = {}
local ____format = require("src.format")
local fmtNum = ____format.fmtNum
local ____log = require("src.console.log")
local warnOnce = ____log.warnOnce
function ____exports.prompt(title, value)
    local answer = TextInput(title, value)
    local ____temp_0
    if answer == nil then
        ____temp_0 = nil
    else
        ____temp_0 = tostring(answer)
    end
    return ____temp_0
end
local INPUTS = {
    "Offset preset",
    "Offset X (m)",
    "Offset Y (m)",
    "Offset Z (m)",
    "Size min (m)",
    "Size max (m)",
    "Refresh rate (Hz)"
}
function ____exports.setupDialog(c)
    local values = {
        c.offset.preset,
        fmtNum(c.offset.values[1]),
        fmtNum(c.offset.values[2]),
        fmtNum(c.offset.values[3]),
        fmtNum(c.range[1]),
        fmtNum(c.range[2]),
        fmtNum(c.rate)
    }
    local r = MessageBox({
        title = "AutoZoom setup",
        message = "XYZ offset applied when you tap a marker cell, size fader range and refresh rate.",
        commands = {{value = 1, name = "Save"}, {value = 2, name = "Pick preset…"}, {value = 3, name = "Layout rows…"}, {value = 0, name = "Cancel"}},
        inputs = __TS__ArrayMap(
            INPUTS,
            function(____, name, i) return {name = name, value = values[i + 1]} end
        ),
        selectors = {{name = "Offset source", selectedValue = c.offset.source == "preset" and 1 or 2, values = {Preset = 1, Values = 2}}}
    })
    if r == nil or r.result ~= 1 and r.result ~= 2 and r.result ~= 3 then
        return nil
    end
    local function input(name)
        local ____tostring_4 = tostring
        local ____opt_1 = r.inputs
        if ____opt_1 ~= nil then
            ____opt_1 = ____opt_1[name]
        end
        local ____opt_1_3 = ____opt_1
        if ____opt_1_3 == nil then
            ____opt_1_3 = ""
        end
        return ____tostring_4(____opt_1_3)
    end
    local ____temp_7 = r.result == 2 and "pick" or (r.result == 3 and "rows" or "save")
    local ____opt_5 = r.selectors
    if ____opt_5 ~= nil then
        ____opt_5 = ____opt_5["Offset source"]
    end
    return {
        action = ____temp_7,
        source = ____opt_5 == 1 and "preset" or "values",
        preset = input(INPUTS[1]),
        x = input(INPUTS[2]),
        y = input(INPUTS[3]),
        z = input(INPUTS[4]),
        min = input(INPUTS[5]),
        max = input(INPUTS[6]),
        rate = input(INPUTS[7])
    }
end
function ____exports.later(fn)
    Timer(
        function() return fn() end,
        0,
        1
    )
end
local generation = 0
local activeCleanup
function ____exports.startLoop(rate, tick, cleanup)
    local step, arm, gen, batch, left
    function step()
        if gen ~= generation then
            return
        end
        left = left - 1
        do
            local function ____catch(e)
                warnOnce(
                    "loop:" .. tostring(e),
                    "Update failed: " .. tostring(e)
                )
            end
            local ____try, ____hasReturned = pcall(function()
                tick()
            end)
            if not ____try then
                ____catch(____hasReturned)
            end
        end
        if left <= 0 and gen == generation then
            arm()
        end
    end
    function arm()
        left = batch
        Timer(step, 1 / rate, batch)
    end
    generation = generation + 1
    gen = generation
    batch = math.max(
        1,
        math.floor(rate * 10)
    )
    left = 0
    activeCleanup = cleanup
    arm()
end
function ____exports.stopLoop()
    generation = generation + 1
    local cleanup = activeCleanup
    activeCleanup = nil
    if cleanup ~= nil then
        cleanup()
    end
end
function ____exports.runCommands(commands)
    for ____, c in ipairs(commands) do
        Cmd(c)
    end
end
return ____exports
 end,
["src.console.vars"] = function(...) 
local ____lualib = require("lualib_bundle")
local __TS__SourceMapTraceBack = ____lualib.__TS__SourceMapTraceBack
local ____exports = {}
---
-- @noSelfInFile
function ____exports.loadText(key)
    local v = GetVar(
        GlobalVars(),
        key
    )
    local ____temp_0
    if v == nil then
        ____temp_0 = nil
    else
        ____temp_0 = tostring(v)
    end
    return ____temp_0
end
function ____exports.saveText(key, value)
    SetVar(
        GlobalVars(),
        key,
        value
    )
end
return ____exports
 end,
["src.console.ma-desk"] = function(...) 
local ____lualib = require("lualib_bundle")
local __TS__Class = ____lualib.__TS__Class
local __TS__New = ____lualib.__TS__New
local __TS__SourceMapTraceBack = ____lualib.__TS__SourceMapTraceBack
local ____exports = {}
local releaseTemp
local ____format = require("src.format")
local fidKey = ____format.fidKey
local ____appearances = require("src.console.appearances")
local ensureAppearances = ____appearances.ensureAppearances
local layout = require("src.console.layout")
local live = require("src.console.live")
local ____log = require("src.console.log")
local info = ____log.info
local warnOnce = ____log.warnOnce
local ____patch = require("src.console.patch")
local scanPatch = ____patch.scanPatch
local pool = require("src.console.pool")
local ____preset_2Dpicker = require("src.console.preset-picker")
local openPresetPicker = ____preset_2Dpicker.openPresetPicker
local ui = require("src.console.ui")
local vars = require("src.console.vars")
function releaseTemp(name)
    do
        local function ____catch(e)
            warnOnce(
                (("release:" .. name) .. ":") .. tostring(e),
                (("Could not release " .. name) .. ": ") .. tostring(e)
            )
        end
        local ____try, ____hasReturned = pcall(function()
            pool.setTemp(name, 0)
        end)
        if not ____try then
            ____catch(____hasReturned)
        end
    end
end
____exports.MaDesk = __TS__Class()
local MaDesk = ____exports.MaDesk
MaDesk.name = "MaDesk"
function MaDesk.prototype.____constructor(self)
    self.lastScan = {fixtures = {}, markers = {}, problems = {}}
    self.engaged = {}
end
function MaDesk.prototype.now(self)
    return Time()
end
function MaDesk.prototype.log(self, message)
    info(message)
end
function MaDesk.prototype.loadText(self, key)
    return vars.loadText(key)
end
function MaDesk.prototype.saveText(self, key, value)
    vars.saveText(key, value)
end
function MaDesk.prototype.scan(self)
    self.lastScan = scanPatch()
    return self.lastScan
end
function MaDesk.prototype.listGroups(self)
    return {}
end
function MaDesk.prototype.install(self, scan)
    pool.ensurePool()
    do
        local function ____catch(e)
            warnOnce(
                "appearances",
                "Could not create the AutoZoom appearances: " .. tostring(e)
            )
        end
        local ____try, ____hasReturned = pcall(function()
            ensureAppearances()
        end)
        if not ____try then
            ____catch(____hasReturned)
        end
    end
    pool.ensureSizeSequence()
    pool.ensureRawMacro(pool.START_MACRO, ("Call Plugin \"" .. pool.PLUGIN_NAME) .. "\"")
    do
        local function ____catch(e)
            warnOnce(
                "cell-macros",
                "Could not remove the old layout macros: " .. tostring(e)
            )
        end
        local ____try, ____hasReturned = pcall(function()
            pool.removeCellMacros()
        end)
        if not ____try then
            ____catch(____hasReturned)
        end
    end
    for ____, f in ipairs(scan.fixtures) do
        local hasIris = f.optics.irisMax > f.optics.irisMin
        local base = {{"Zoom", f.optics.zoomMin}}
        if hasIris then
            base[#base + 1] = {"Iris", f.optics.irisMin}
        end
        pool.ensureCueSequence(
            pool.baseSeqName(f.fid),
            f.fid,
            base
        )
        pool.setPriority(
            pool.baseSeqName(f.fid),
            "High"
        )
        pool.setNoOffWhenOverridden(pool.baseSeqName(f.fid))
        pool.ensureFaderSequence(
            pool.zoomSeqName(f.fid),
            f.fid,
            "Zoom",
            f.optics.zoomMax
        )
        pool.setPriority(
            pool.zoomSeqName(f.fid),
            "Super"
        )
        if hasIris then
            pool.ensureFaderSequence(
                pool.irisSeqName(f.fid),
                f.fid,
                "Iris",
                f.optics.irisMax
            )
            pool.setPriority(
                pool.irisSeqName(f.fid),
                "Super"
            )
        end
    end
end
function MaDesk.prototype.readMarkerCid(self, f)
    return live.readMarkerCid(f)
end
function MaDesk.prototype.readOffset(self, f)
    return live.readOffset(f, self.lastScan.markers)
end
function MaDesk.prototype.readProgrammerCid(self, f)
    return live.readProgrammerCid(f)
end
function MaDesk.prototype.readMarkers(self)
    return live.readMarkers()
end
function MaDesk.prototype.readSizeFader(self)
    return pool.readMaster(pool.SIZE_SEQ)
end
function MaDesk.prototype.setFaders(self, f, zoom, iris)
    local key = fidKey(f.fid)
    if not self.engaged[key] and pool.sequenceOn(pool.baseSeqName(f.fid)) then
        self.engaged[key] = true
    end
    pool.setTemp(
        pool.zoomSeqName(f.fid),
        zoom
    )
    if iris ~= nil and f.optics.irisMax > f.optics.irisMin then
        pool.setTemp(
            pool.irisSeqName(f.fid),
            iris
        )
    end
end
function MaDesk.prototype.releaseFaders(self, f)
    releaseTemp(pool.zoomSeqName(f.fid))
    if f.optics.irisMax > f.optics.irisMin then
        releaseTemp(pool.irisSeqName(f.fid))
    end
    self.engaged[fidKey(f.fid)] = false
    pool.sequenceOff(pool.baseSeqName(f.fid))
end
function MaDesk.prototype.buildLayout(self, cells)
    layout.buildLayout(cells)
end
function MaDesk.prototype.refreshLayout(self, views)
    layout.refreshLayout(views)
end
function MaDesk.prototype.startLoop(self, rate, tick, cleanup)
    ui.startLoop(rate, tick, cleanup)
end
function MaDesk.prototype.stopLoop(self)
    ui.stopLoop()
end
function MaDesk.prototype.later(self, fn)
    ui.later(fn)
end
function MaDesk.prototype.prompt(self, title, value)
    return ui.prompt(title, value)
end
function MaDesk.prototype.setupDialog(self, current)
    return ui.setupDialog(current)
end
function MaDesk.prototype.runCommands(self, commands)
    ui.runCommands(commands)
end
function MaDesk.prototype.openPresetPicker(self, current, onPick)
    openPresetPicker(current, onPick)
end
function ____exports.createMaDesk()
    return __TS__New(____exports.MaDesk)
end
return ____exports
 end,
["src.engine.arm-command"] = function(...) 
local ____lualib = require("lualib_bundle")
local __TS__ArraySort = ____lualib.__TS__ArraySort
local __TS__StringTrim = ____lualib.__TS__StringTrim
local __TS__Number = ____lualib.__TS__Number
local __TS__StringSplit = ____lualib.__TS__StringSplit
local __TS__SourceMapTraceBack = ____lualib.__TS__SourceMapTraceBack
local ____exports = {}
local ____format = require("src.format")
local fmtInt = ____format.fmtInt
function ____exports.normalizeFids(fids)
    local seen = {}
    local out = {}
    for ____, fid in ipairs(fids) do
        if fid > 0 and math.floor(fid) == fid and not seen[fmtInt(fid)] then
            seen[fmtInt(fid)] = true
            out[#out + 1] = fid
        end
    end
    __TS__ArraySort(
        out,
        function(____, a, b) return a - b end
    )
    return out
end
function ____exports.parseArmList(text)
    local out = {}
    for ____, part in ipairs(__TS__StringSplit(text, ",")) do
        local n = __TS__Number(__TS__StringTrim(part))
        if __TS__StringTrim(part) ~= "" and n == n then
            out[#out + 1] = n
        end
    end
    return ____exports.normalizeFids(out)
end
return ____exports
 end,
["src.engine.program"] = function(...) 
local ____lualib = require("lualib_bundle")
local __TS__StringStartsWith = ____lualib.__TS__StringStartsWith
local __TS__ArrayMap = ____lualib.__TS__ArrayMap
local __TS__SourceMapTraceBack = ____lualib.__TS__SourceMapTraceBack
local ____exports = {}
local selection
local ____format = require("src.format")
local fmtInt = ____format.fmtInt
local fmtNum = ____format.fmtNum
function selection(fids)
    return "Fixture " .. table.concat(
        __TS__ArrayMap(
            fids,
            function(____, f) return fmtInt(f) end
        ),
        " + "
    )
end
function ____exports.programCommands(fids, cid, offset)
    if #fids == 0 then
        return {}
    end
    local cmds = {
        selection(fids),
        "Attribute \"XYZ_MArker\" At " .. fmtInt(cid)
    }
    if offset.source == "preset" and offset.preset ~= "" then
        local target = __TS__StringStartsWith(offset.preset, "DataPool") and offset.preset or "Preset " .. offset.preset
        cmds[#cmds + 1] = "Attribute \"XYZ_X\" Thru \"XYZ_Z\" At " .. target
    else
        cmds[#cmds + 1] = "Attribute \"XYZ_X\" At " .. fmtNum(offset.values[1])
        cmds[#cmds + 1] = "Attribute \"XYZ_Y\" At " .. fmtNum(offset.values[2])
        cmds[#cmds + 1] = "Attribute \"XYZ_Z\" At " .. fmtNum(offset.values[3])
    end
    return cmds
end
function ____exports.releaseCommands(fids)
    return #fids == 0 and ({}) or ({"Off " .. selection(fids)})
end
return ____exports
 end,
["src.runtime.autozoom"] = function(...) 
local ____lualib = require("lualib_bundle")
local __TS__Class = ____lualib.__TS__Class
local __TS__ArrayFilter = ____lualib.__TS__ArrayFilter
local __TS__ObjectAssign = ____lualib.__TS__ObjectAssign
local __TS__ArrayMap = ____lualib.__TS__ArrayMap
local __TS__ArraySome = ____lualib.__TS__ArraySome
local __TS__ArrayFind = ____lualib.__TS__ArrayFind
local __TS__ArrayIndexOf = ____lualib.__TS__ArrayIndexOf
local __TS__SparseArrayNew = ____lualib.__TS__SparseArrayNew
local __TS__SparseArrayPush = ____lualib.__TS__SparseArrayPush
local __TS__SparseArraySpread = ____lualib.__TS__SparseArraySpread
local __TS__ArrayEvery = ____lualib.__TS__ArrayEvery
local __TS__StringTrim = ____lualib.__TS__StringTrim
local __TS__StringReplace = ____lualib.__TS__StringReplace
local __TS__Delete = ____lualib.__TS__Delete
local __TS__Number = ____lualib.__TS__Number
local __TS__New = ____lualib.__TS__New
local __TS__SourceMapTraceBack = ____lualib.__TS__SourceMapTraceBack
local ____exports = {}
local ____arm_2Dcommand = require("src.engine.arm-command")
local normalizeFids = ____arm_2Dcommand.normalizeFids
local parseArmList = ____arm_2Dcommand.parseArmList
local ____program = require("src.engine.program")
local programCommands = ____program.programCommands
local releaseCommands = ____program.releaseCommands
local ____fixture_2Dstate = require("src.engine.fixture-state")
local evaluate = ____fixture_2Dstate.evaluate
local ____vec = require("src.engine.vec")
local vec = ____vec.vec
local ____format = require("src.format")
local fidKey = ____format.fidKey
local fmtInt = ____format.fmtInt
local fmtNum = ____format.fmtNum
local ____config = require("src.store.config")
local applySetup = ____config.applySetup
local CONFIG_KEY = ____config.CONFIG_KEY
local defaultConfig = ____config.defaultConfig
local INSTANCE_KEY = ____config.INSTANCE_KEY
local offsetLabel = ____config.offsetLabel
local parseConfig = ____config.parseConfig
local pruneConfig = ____config.pruneConfig
local serializeConfig = ____config.serializeConfig
local ____view_2Dmodel = require("src.ui.view-model")
local buildViews = ____view_2Dmodel.buildViews
local layoutCells = ____view_2Dmodel.layoutCells
local stateLabel = ____view_2Dmodel.stateLabel
local summarize = ____view_2Dmodel.summarize
____exports.AutoZoom = __TS__Class()
local AutoZoom = ____exports.AutoZoom
AutoZoom.name = "AutoZoom"
function AutoZoom.prototype.____constructor(self, desk, id)
    self.desk = desk
    self.id = id
    self.config = defaultConfig()
    self.patch = {fixtures = {}, markers = {}, problems = {}}
    self.scanned = {fixtures = {}, markers = {}, problems = {}}
    self.layoutRows = {}
    self.running = false
    self.message = ""
    self.results = {}
    self.live = {}
    self.sent = {}
    self.warned = {}
    self.loopGen = 0
end
function AutoZoom.prototype.isCurrent(self)
    return self.desk:loadText(INSTANCE_KEY) == self.id
end
function AutoZoom.prototype.ensureCurrent(self)
    if self:isCurrent() then
        return true
    end
    self.desk:log("Run the AutoZoom plugin for this show")
    return false
end
function AutoZoom.prototype.Install(self)
    local loaded = parseConfig(self.desk:loadText(CONFIG_KEY))
    if loaded.warning ~= nil then
        self.desk:log(loaded.warning)
    end
    self.config = loaded.config
    self.desk:saveText(INSTANCE_KEY, self.id)
    self:Rescan()
end
function AutoZoom.prototype.Rescan(self)
    if not self:ensureCurrent() then
        return
    end
    local old = self.scanned.fixtures
    self.patch = self.desk:scan()
    for ____, p in ipairs(self.patch.problems) do
        self.desk:log(p)
    end
    self.layoutRows = self:resolveRows()
    local managed = self:managedFixtures()
    local kept = {}
    for ____, f in ipairs(managed) do
        kept[fidKey(f.fid)] = true
    end
    self:releaseAll(__TS__ArrayFilter(
        old,
        function(____, f) return not kept[fidKey(f.fid)] end
    ))
    self.scanned = __TS__ObjectAssign({}, self.patch, {fixtures = managed})
    self.config = pruneConfig(
        self.config,
        __TS__ArrayMap(
            self.patch.fixtures,
            function(____, f) return f.fid end
        )
    )
    self.desk:install(self.scanned)
    self.desk:buildLayout(layoutCells(self.layoutRows, self.scanned.markers))
    self.sent = {}
    self.results = {}
    self.desk:log(((("Found " .. fmtInt(#self.scanned.fixtures)) .. " fixtures and ") .. fmtInt(#self.scanned.markers)) .. " markers")
    self:update()
end
function AutoZoom.prototype.resolveRows(self)
    local byFid = {}
    for ____, f in ipairs(self.patch.fixtures) do
        byFid[fidKey(f.fid)] = f
    end
    if #self.config.rows == 0 then
        return __TS__ArrayMap(
            self.patch.fixtures,
            function(____, f) return {kind = "fixture", fixture = f} end
        )
    end
    local groups = __TS__ArraySome(
        self.config.rows,
        function(____, e) return e.kind == "group" end
    ) and self.desk:listGroups() or ({})
    local rows = {}
    for ____, e in ipairs(self.config.rows) do
        do
            if e.kind == "fixture" then
                local f = byFid[fidKey(e.fid)]
                if f == nil then
                    self.desk:log(("Fixture " .. fmtInt(e.fid)) .. " in the layout rows is not an XYZ fixture")
                else
                    rows[#rows + 1] = {kind = "fixture", fixture = f}
                end
                goto __continue22
            end
            local g = __TS__ArrayFind(
                groups,
                function(____, x) return x.no == e.no end
            )
            local members = {}
            for ____, fid in ipairs(g and g.fids or ({})) do
                members[fidKey(fid)] = true
            end
            rows[#rows + 1] = {
                kind = "group",
                no = e.no,
                name = g and g.name or e.name,
                missing = g == nil,
                fixtures = __TS__ArrayFilter(
                    self.patch.fixtures,
                    function(____, f) return members[fidKey(f.fid)] end
                )
            }
        end
        ::__continue22::
    end
    return rows
end
function AutoZoom.prototype.managedFixtures(self)
    local reached = {}
    for ____, r in ipairs(self.layoutRows) do
        if r.kind == "fixture" then
            reached[fidKey(r.fixture.fid)] = true
        else
            for ____, f in ipairs(r.fixtures) do
                reached[fidKey(f.fid)] = true
            end
        end
    end
    return __TS__ArrayFilter(
        self.patch.fixtures,
        function(____, f) return reached[fidKey(f.fid)] end
    )
end
function AutoZoom.prototype.groupRow(self, no)
    for ____, r in ipairs(self.layoutRows) do
        if r.kind == "group" and r.no == no then
            return r
        end
    end
    return nil
end
function AutoZoom.prototype.RescanLater(self)
    if not self:ensureCurrent() then
        return
    end
    self.desk:later(function() return self:Rescan() end)
end
function AutoZoom.prototype.Capture(self)
    self.desk:log("Capture was removed in 2.0.0.2")
end
function AutoZoom.prototype.Start(self)
    if not self:ensureCurrent() then
        return
    end
    if self.running then
        return
    end
    self.running = true
    local ____self_4, ____loopGen_5 = self, "loopGen"
    local ____self_loopGen_6 = ____self_4[____loopGen_5] + 1
    ____self_4[____loopGen_5] = ____self_loopGen_6
    local gen = ____self_loopGen_6
    self.desk:startLoop(
        self.config.rate,
        function()
            if gen == self.loopGen then
                self:tick()
            end
        end,
        function()
            if gen == self.loopGen then
                self:onLoopStopped()
            end
        end
    )
    self:say("AutoZoom started")
end
function AutoZoom.prototype.Stop(self)
    if not self:isCurrent() then
        if not self.running then
            return
        end
        self.running = false
        self.loopGen = self.loopGen + 1
        self.desk:stopLoop()
        return
    end
    self:saveConfig()
    if not self.running then
        return
    end
    self.running = false
    self.loopGen = self.loopGen + 1
    self.desk:stopLoop()
    self:releaseAll(self.scanned.fixtures)
    do
        local function ____catch(e)
            self:warnOnce(
                "stop:" .. tostring(e),
                "Refresh after stop failed: " .. tostring(e)
            )
        end
        local ____try, ____hasReturned = pcall(function()
            self:update()
        end)
        if not ____try then
            ____catch(____hasReturned)
        end
    end
    self:say("AutoZoom stopped")
end
function AutoZoom.prototype.Toggle(self)
    if not self:ensureCurrent() then
        return
    end
    if self.running then
        self:Stop()
    else
        self:Start()
    end
end
function AutoZoom.prototype.Arm(self, list)
    if not self:ensureCurrent() then
        return
    end
    self:setArmed(parseArmList(list))
end
function AutoZoom.prototype.ArmToggle(self, fid)
    if not self:ensureCurrent() then
        return
    end
    if self:fixture(fid) == nil then
        self.desk:log("Not AutoZoom fixtures, ignored: " .. fmtInt(fid))
        return
    end
    local disarmed = __TS__ArrayFilter(
        self.config.disarmed,
        function(____, f) return f ~= fid end
    )
    if #disarmed == #self.config.disarmed then
        disarmed[#disarmed + 1] = fid
    end
    self.config.disarmed = disarmed
    self:markDirty()
    self:update()
end
function AutoZoom.prototype.ArmGroup(self, no)
    if not self:ensureCurrent() then
        return
    end
    local fids = self:groupFids(no)
    if fids == nil then
        return
    end
    local anyDisarmed = __TS__ArraySome(
        fids,
        function(____, fid) return not self:isArmed(fid) end
    )
    local rest = __TS__ArrayFilter(
        self.config.disarmed,
        function(____, fid) return __TS__ArrayIndexOf(fids, fid) < 0 end
    )
    local ____self_config_9 = self.config
    local ____anyDisarmed_8
    if anyDisarmed then
        ____anyDisarmed_8 = rest
    else
        local ____array_7 = __TS__SparseArrayNew(table.unpack(rest))
        __TS__SparseArrayPush(
            ____array_7,
            table.unpack(fids)
        )
        ____anyDisarmed_8 = {__TS__SparseArraySpread(____array_7)}
    end
    ____self_config_9.disarmed = ____anyDisarmed_8
    self:markDirty()
    self:update()
end
function AutoZoom.prototype.ArmAll(self)
    if not self:ensureCurrent() then
        return
    end
    self:setArmed(__TS__ArrayMap(
        self.scanned.fixtures,
        function(____, f) return f.fid end
    ))
end
function AutoZoom.prototype.DisarmAll(self)
    if not self:ensureCurrent() then
        return
    end
    self:setArmed({})
end
function AutoZoom.prototype.Status(self)
    if not self:ensureCurrent() then
        return
    end
    self.desk:log(((("AutoZoom " .. (self.running and "running" or "stopped")) .. ", ") .. fmtInt(#__TS__ArrayFilter(
        self.scanned.fixtures,
        function(____, f) return self:isArmed(f.fid) end
    ))) .. " armed")
    for ____, row in ipairs(self:rowStates(self:globalSize())) do
        if row.members ~= nil then
            local sum = summarize(row.members)
            self.desk:log(((((((("  G" .. fmtInt(row.no)) .. " ") .. row.name) .. ": ") .. fmtInt(sum.tracking)) .. "/") .. fmtInt(sum.total)) .. " tracking")
        else
            local r = self.results[fidKey(row.fixture.fid)]
            self.desk:log((((("  " .. fmtInt(row.fixture.fid)) .. " ") .. row.fixture.name) .. ": ") .. (r == nil and "-" or stateLabel(r.state)))
        end
    end
end
function AutoZoom.prototype.Program(self, fid, cid)
    if not self:ensureCurrent() then
        return
    end
    local f = self:fixture(fid)
    if f == nil then
        self.desk:log(("Fixture " .. fmtInt(fid)) .. " is not an AutoZoom fixture")
        return
    end
    if self.desk:readProgrammerCid(f) == cid then
        self.desk:runCommands(releaseCommands({fid}))
    else
        self.desk:runCommands(programCommands({fid}, cid, self.config.offset))
    end
    self:update()
end
function AutoZoom.prototype.ProgramGroup(self, no, cid)
    if not self:ensureCurrent() then
        return
    end
    local fids = self:groupFids(no)
    if fids == nil then
        return
    end
    local all = __TS__ArrayEvery(
        __TS__ArrayFilter(
            self.scanned.fixtures,
            function(____, f) return __TS__ArrayIndexOf(fids, f.fid) >= 0 end
        ),
        function(____, f) return self.desk:readProgrammerCid(f) == cid end
    )
    self.desk:runCommands(all and releaseCommands(fids) or programCommands(fids, cid, self.config.offset))
    self:update()
end
function AutoZoom.prototype.groupFids(self, no)
    local ____opt_10 = self:groupRow(no)
    local fids = __TS__ArrayMap(
        ____opt_10 and ____opt_10.fixtures or ({}),
        function(____, f) return f.fid end
    )
    if #fids > 0 then
        return fids
    end
    self.desk:log(("Group " .. fmtInt(no)) .. " has no XYZ fixtures")
    return nil
end
function AutoZoom.prototype.Setup(self)
    if not self:ensureCurrent() then
        return
    end
    self.desk:later(function()
        local answers = self.desk:setupDialog(self.config)
        if answers == nil then
            return
        end
        if answers.action == "pick" then
            self:openPicker()
            return
        end
        if answers.action ~= "save" then
            return
        end
        local rate = self.config.rate
        local result = applySetup(self.config, answers)
        for ____, e in ipairs(result.errors) do
            self.desk:log(e)
        end
        self.config = result.config
        self:markDirty()
        if self.config.rate ~= rate and self.running then
            self.desk:log("The new refresh rate applies after Stop and Start")
        end
        self:say("Setup saved")
        self:update()
    end)
end
function AutoZoom.prototype.Size(self, fid)
    if not self:ensureCurrent() then
        return
    end
    local f = self:fixture(fid)
    if f == nil then
        self.desk:log(("Fixture " .. fmtInt(fid)) .. " is not an AutoZoom fixture")
        return
    end
    self.desk:later(function()
        local key = fidKey(fid)
        local current = self.config.size[key]
        local answer = self.desk:prompt(
            ("Beam size of " .. fmtInt(fid)) .. " in metres (empty = global fader)",
            current == nil and "" or fmtNum(current)
        )
        if answer == nil then
            return
        end
        local text = __TS__StringReplace(
            __TS__StringTrim(answer),
            ",",
            "."
        )
        if text == "" then
            __TS__Delete(self.config.size, key)
        else
            local n = __TS__Number(text)
            if n ~= n or n <= 0 then
                self.desk:log("Size must be a number of metres above 0")
                return
            end
            self.config.size[key] = n
        end
        self:markDirty()
        self:update()
    end)
end
function AutoZoom.prototype.tick(self)
    if not self:isCurrent() then
        self.desk:log("Another AutoZoom instance took over; this one stops")
        self.running = false
        self.loopGen = self.loopGen + 1
        self.desk:stopLoop()
        return
    end
    self:update()
    if self.dirtyAt ~= nil and self.desk:now() - self.dirtyAt >= 1 then
        self:saveConfig()
    end
end
function AutoZoom.prototype.onLoopStopped(self)
    self.running = false
    self:releaseAll(self.scanned.fixtures)
end
function AutoZoom.prototype.releaseAll(self, fixtures)
    for ____, f in ipairs(fixtures) do
        do
            local key = fidKey(f.fid)
            if self.sent[key] == "release" then
                goto __continue123
            end
            do
                local function ____catch(e)
                    self:warnOnce(
                        (("release:" .. key) .. ":") .. tostring(e),
                        (("Fixture " .. fmtInt(f.fid)) .. ": release failed: ") .. tostring(e)
                    )
                end
                local ____try, ____hasReturned = pcall(function()
                    self.desk:releaseFaders(f)
                end)
                if not ____try then
                    ____catch(____hasReturned)
                end
            end
            self.sent[key] = "release"
        end
        ::__continue123::
    end
end
function AutoZoom.prototype.update(self)
    local markers = self.desk:readMarkers()
    local globalSize = self:globalSize()
    for ____, f in ipairs(self.scanned.fixtures) do
        do
            local function ____catch(e)
                self:warnOnce(
                    (fmtInt(f.fid) .. ":") .. tostring(e),
                    (("Fixture " .. fmtInt(f.fid)) .. ": ") .. tostring(e)
                )
            end
            local ____try, ____hasReturned = pcall(function()
                self:updateFixture(f, markers, globalSize)
            end)
            if not ____try then
                ____catch(____hasReturned)
            end
        end
    end
    self:render(markers, globalSize)
end
function AutoZoom.prototype.PickOffset(self)
    if not self:ensureCurrent() then
        return
    end
    self:openPicker()
end
function AutoZoom.prototype.openPicker(self)
    self.desk:openPresetPicker(
        self.config.offset.preset,
        function(preset)
            if not self:ensureCurrent() then
                return
            end
            self.config.offset = __TS__ObjectAssign({}, self.config.offset, {source = "preset", preset = preset})
            self:markDirty()
            self:say("Offset preset " .. preset)
            self:update()
        end
    )
end
function AutoZoom.prototype.updateFixture(self, f, markers, globalSize)
    local key = fidKey(f.fid)
    local cid = self.desk:readMarkerCid(f)
    local live = {
        cid = cid,
        programmerCid = self.desk:readProgrammerCid(f),
        offset = self.desk:readOffset(f)
    }
    self.live[key] = live
    local marker
    if cid ~= 0 and __TS__ArraySome(
        self.scanned.markers,
        function(____, m) return m.cid == cid end
    ) then
        local reading = markers[fidKey(cid)]
        marker = reading ~= nil and ({pos = reading.pos, rot = reading.rot, live = true}) or ({
            pos = vec(0, 0, 0),
            live = false
        })
    end
    local result = evaluate({
        running = self.running,
        armed = self:isArmed(f.fid),
        markerCid = cid,
        offset = live.offset,
        fixturePos = f.position,
        optics = f.optics,
        size = self:sizeFor(f.fid, globalSize),
        marker = marker
    })
    self.results[key] = result
    self:apply(f, result.output)
end
function AutoZoom.prototype.apply(self, f, out)
    if out.kind == "hold" then
        return
    end
    local key = fidKey(f.fid)
    local signature = out.kind == "release" and "release" or (tostring(out.zoom) .. "|") .. tostring(out.iris)
    if self.sent[key] == signature then
        return
    end
    self.sent[key] = signature
    if out.kind == "release" then
        self.desk:releaseFaders(f)
    else
        self.desk:setFaders(f, out.zoom, out.iris)
    end
end
function AutoZoom.prototype.rowState(self, f, globalSize)
    local key = fidKey(f.fid)
    local live = self.live[key] or ({
        cid = 0,
        programmerCid = 0,
        offset = vec(0, 0, 0)
    })
    return {
        fixture = f,
        armed = self:isArmed(f.fid),
        markerCid = live.cid,
        programmerCid = live.programmerCid,
        offset = live.offset,
        result = self.results[key] or ({state = "offline", output = {kind = "release"}}),
        size = self:sizeFor(f.fid, globalSize),
        sizeFixed = self.config.size[key] ~= nil
    }
end
function AutoZoom.prototype.rowStates(self, globalSize)
    return __TS__ArrayMap(
        self.layoutRows,
        function(____, r) return r.kind == "fixture" and self:rowState(r.fixture, globalSize) or ({
            no = r.no,
            name = r.name,
            missing = r.missing,
            members = __TS__ArrayMap(
                r.fixtures,
                function(____, f) return self:rowState(f, globalSize) end
            )
        }) end
    )
end
function AutoZoom.prototype.render(self, markers, globalSize)
    local rows = self:rowStates(globalSize)
    local liveMarkers = 0
    for ____, m in ipairs(self.scanned.markers) do
        if markers[fidKey(m.cid)] ~= nil then
            liveMarkers = liveMarkers + 1
        end
    end
    self.desk:refreshLayout(buildViews(
        {
            running = self.running,
            liveMarkers = liveMarkers,
            globalSize = globalSize,
            offsetLabel = offsetLabel(self.config),
            message = self.message
        },
        rows,
        self.scanned.markers,
        markers
    ))
end
function AutoZoom.prototype.isArmed(self, fid)
    return __TS__ArrayIndexOf(self.config.disarmed, fid) < 0
end
function AutoZoom.prototype.fixture(self, fid)
    return __TS__ArrayFind(
        self.scanned.fixtures,
        function(____, f) return f.fid == fid end
    )
end
function AutoZoom.prototype.setArmed(self, fids)
    local known = __TS__ArrayFilter(
        normalizeFids(fids),
        function(____, fid) return self:fixture(fid) ~= nil end
    )
    local unknown = __TS__ArrayFilter(
        normalizeFids(fids),
        function(____, fid) return self:fixture(fid) == nil end
    )
    if #unknown > 0 then
        self.desk:log("Not AutoZoom fixtures, ignored: " .. table.concat(
            __TS__ArrayMap(
                unknown,
                function(____, f) return fmtInt(f) end
            ),
            ", "
        ))
    end
    local outside = __TS__ArrayFilter(
        self.config.disarmed,
        function(____, fid) return self:fixture(fid) == nil end
    )
    local ____self_config_13 = self.config
    local ____array_12 = __TS__SparseArrayNew(table.unpack(outside))
    __TS__SparseArrayPush(
        ____array_12,
        table.unpack(__TS__ArrayFilter(
            __TS__ArrayMap(
                self.scanned.fixtures,
                function(____, f) return f.fid end
            ),
            function(____, fid) return __TS__ArrayIndexOf(known, fid) < 0 end
        ))
    )
    ____self_config_13.disarmed = {__TS__SparseArraySpread(____array_12)}
    self:markDirty()
    self:update()
end
function AutoZoom.prototype.globalSize(self)
    local min, max = self.config.range[1], self.config.range[2]
    local fader = self.desk:readSizeFader()
    if fader ~= nil then
        self.lastSize = min + (max - min) * math.min(
            100,
            math.max(0, fader)
        ) / 100
    end
    return self.lastSize or min
end
function AutoZoom.prototype.sizeFor(self, fid, globalSize)
    return self.config.size[fidKey(fid)] or globalSize
end
function AutoZoom.prototype.markDirty(self)
    if self.running then
        self.dirtyAt = self.desk:now()
    else
        self:saveConfig()
    end
end
function AutoZoom.prototype.saveConfig(self)
    self.desk:saveText(
        CONFIG_KEY,
        serializeConfig(self.config)
    )
    self.dirtyAt = nil
end
function AutoZoom.prototype.say(self, message)
    self.message = message
    self.desk:log(message)
end
function AutoZoom.prototype.warnOnce(self, key, message)
    if self.warned[key] then
        return
    end
    self.warned[key] = true
    self.desk:log(message)
end
function ____exports.createAutoZoom(desk, id)
    return __TS__New(____exports.AutoZoom, desk, id)
end
return ____exports
 end,
["src.main"] = function(...) 
local ____lualib = require("lualib_bundle")
local __TS__New = ____lualib.__TS__New
local __TS__SourceMapTraceBack = ____lualib.__TS__SourceMapTraceBack
local ____exports = {}
local ____ma_2Ddesk = require("src.console.ma-desk")
local MaDesk = ____ma_2Ddesk.MaDesk
local ____autozoom = require("src.runtime.autozoom")
local AutoZoom = ____autozoom.AutoZoom
local ____window = require("src.console.window")
local setPlugin = ____window.setPlugin
local ____, ____, signals, handle = ...
setPlugin(signals, handle)
local function main(_display, _args)
    if AZ ~= nil then
        do
            local function ____catch(e)
                Printf("[AZ] The previous AutoZoom instance did not stop cleanly: " .. tostring(e))
            end
            local ____try, ____hasReturned = pcall(function()
                AZ:Stop()
            end)
            if not ____try then
                ____catch(____hasReturned)
            end
        end
    end
    local id = string.format(
        "%d-%d",
        os.time(),
        math.random(1, 1000000)
    )
    AZ = __TS__New(
        AutoZoom,
        __TS__New(MaDesk),
        id
    )
    Printf("[AZ] AutoZoom 2.1.0.0 by Naostage")
    AZ:Install()
    AZ:Start()
end
return main
 end,
["src.testing.exports"] = function(...) 
local ____lualib = require("lualib_bundle")
local __TS__SourceMapTraceBack = ____lualib.__TS__SourceMapTraceBack
local ____exports = {}
local format = require("src.format")
local json = require("src.store.json")
local config = require("src.store.config")
local rows = require("src.store.rows")
local vec = require("src.engine.vec")
local beam = require("src.engine.beam")
local state = require("src.engine.fixture-state")
local arm = require("src.engine.arm-command")
local program = require("src.engine.program")
local preset = require("src.engine.preset-ref")
local view = require("src.ui.view-model")
local runtime = require("src.runtime.autozoom")
local patch = require("src.console.patch")
local live = require("src.console.live")
local vars = require("src.console.vars")
local madesk = require("src.console.ma-desk")
local window = require("src.console.window")
____exports.ready = true
____exports.format = format
____exports.json = json
____exports.config = config
____exports.rows = rows
____exports.vec = vec
____exports.beam = beam
____exports.state = state
____exports.arm = arm
____exports.program = program
____exports.preset = preset
____exports.view = view
____exports.runtime = runtime
____exports.patch = patch
____exports.live = live
____exports.vars = vars
____exports.madesk = madesk
____exports.window = window
return ____exports
 end,
}
local __TS__SourceMapTraceBack = require("lualib_bundle").__TS__SourceMapTraceBack
__TS__SourceMapTraceBack(debug.getinfo(1).short_src, {["600"] = {line = 5, file = "vec.ts"},["601"] = {line = 6, file = "vec.ts"},["602"] = {line = 5, file = "vec.ts"},["603"] = {line = 9, file = "vec.ts"},["604"] = {line = 10, file = "vec.ts"},["605"] = {line = 9, file = "vec.ts"},["606"] = {line = 13, file = "vec.ts"},["607"] = {line = 14, file = "vec.ts"},["608"] = {line = 14, file = "vec.ts"},["609"] = {line = 14, file = "vec.ts"},["610"] = {line = 15, file = "vec.ts"},["611"] = {line = 13, file = "vec.ts"},["612"] = {line = 19, file = "vec.ts"},["613"] = {line = 20, file = "vec.ts"},["614"] = {line = 20, file = "vec.ts"},["615"] = {line = 20, file = "vec.ts"},["616"] = {line = 21, file = "vec.ts"},["617"] = {line = 21, file = "vec.ts"},["618"] = {line = 21, file = "vec.ts"},["619"] = {line = 22, file = "vec.ts"},["620"] = {line = 22, file = "vec.ts"},["621"] = {line = 22, file = "vec.ts"},["622"] = {line = 23, file = "vec.ts"},["623"] = {line = 23, file = "vec.ts"},["624"] = {line = 23, file = "vec.ts"},["625"] = {line = 24, file = "vec.ts"},["626"] = {line = 24, file = "vec.ts"},["627"] = {line = 24, file = "vec.ts"},["628"] = {line = 25, file = "vec.ts"},["629"] = {line = 19, file = "vec.ts"},["636"] = {line = 10, file = "beam.ts"},["637"] = {line = 11, file = "beam.ts"},["638"] = {line = 11, file = "beam.ts"},["640"] = {line = 12, file = "beam.ts"},["641"] = {line = 13, file = "beam.ts"},["642"] = {line = 13, file = "beam.ts"},["643"] = {line = 13, file = "beam.ts"},["644"] = {line = 13, file = "beam.ts"},["645"] = {line = 10, file = "beam.ts"},["646"] = {line = 16, file = "beam.ts"},["647"] = {line = 17, file = "beam.ts"},["648"] = {line = 16, file = "beam.ts"},["649"] = {line = 20, file = "beam.ts"},["650"] = {line = 21, file = "beam.ts"},["651"] = {line = 22, file = "beam.ts"},["652"] = {line = 23, file = "beam.ts"},["653"] = {line = 23, file = "beam.ts"},["655"] = {line = 24, file = "beam.ts"},["656"] = {line = 25, file = "beam.ts"},["657"] = {line = 25, file = "beam.ts"},["658"] = {line = 25, file = "beam.ts"},["659"] = {line = 25, file = "beam.ts"},["660"] = {line = 25, file = "beam.ts"},["661"] = {line = 25, file = "beam.ts"},["662"] = {line = 25, file = "beam.ts"},["664"] = {line = 26, file = "beam.ts"},["665"] = {line = 26, file = "beam.ts"},["666"] = {line = 26, file = "beam.ts"},["667"] = {line = 26, file = "beam.ts"},["668"] = {line = 26, file = "beam.ts"},["669"] = {line = 26, file = "beam.ts"},["670"] = {line = 26, file = "beam.ts"},["672"] = {line = 27, file = "beam.ts"},["673"] = {line = 28, file = "beam.ts"},["674"] = {line = 28, file = "beam.ts"},["676"] = {line = 29, file = "beam.ts"},["677"] = {line = 30, file = "beam.ts"},["678"] = {line = 30, file = "beam.ts"},["680"] = {line = 31, file = "beam.ts"},["681"] = {line = 31, file = "beam.ts"},["682"] = {line = 31, file = "beam.ts"},["683"] = {line = 31, file = "beam.ts"},["684"] = {line = 31, file = "beam.ts"},["685"] = {line = 31, file = "beam.ts"},["686"] = {line = 20, file = "beam.ts"},["702"] = {line = 6, file = "preset-ref.ts"},["703"] = {line = 7, file = "preset-ref.ts"},["704"] = {line = 8, file = "preset-ref.ts"},["705"] = {line = 9, file = "preset-ref.ts"},["706"] = {line = 10, file = "preset-ref.ts"},["707"] = {line = 11, file = "preset-ref.ts"},["708"] = {line = 12, file = "preset-ref.ts"},["709"] = {line = 13, file = "preset-ref.ts"},["710"] = {line = 13, file = "preset-ref.ts"},["712"] = {line = 14, file = "preset-ref.ts"},["713"] = {line = 15, file = "preset-ref.ts"},["714"] = {line = 15, file = "preset-ref.ts"},["716"] = {line = 16, file = "preset-ref.ts"},["717"] = {line = 6, file = "preset-ref.ts"},["728"] = {line = 4, file = "format.ts"},["729"] = {line = 5, file = "format.ts"},["730"] = {line = 5, file = "format.ts"},["731"] = {line = 5, file = "format.ts"},["732"] = {line = 5, file = "format.ts"},["733"] = {line = 4, file = "format.ts"},["734"] = {line = 8, file = "format.ts"},["735"] = {line = 9, file = "format.ts"},["736"] = {line = 10, file = "format.ts"},["737"] = {line = 10, file = "format.ts"},["739"] = {line = 11, file = "format.ts"},["740"] = {line = 11, file = "format.ts"},["742"] = {line = 12, file = "format.ts"},["743"] = {line = 8, file = "format.ts"},["744"] = {line = 15, file = "format.ts"},["745"] = {line = 16, file = "format.ts"},["746"] = {line = 15, file = "format.ts"},["765"] = {line = 27, file = "json.ts"},["766"] = {line = 27, file = "json.ts"},["767"] = {line = 28, file = "json.ts"},["769"] = {line = 29, file = "json.ts"},["770"] = {line = 29, file = "json.ts"},["771"] = {line = 30, file = "json.ts"},["772"] = {line = 31, file = "json.ts"},["773"] = {line = 31, file = "json.ts"},["774"] = {line = 32, file = "json.ts"},["775"] = {line = 32, file = "json.ts"},["776"] = {line = 33, file = "json.ts"},["777"] = {line = 33, file = "json.ts"},["778"] = {line = 34, file = "json.ts"},["779"] = {line = 34, file = "json.ts"},["780"] = {line = 35, file = "json.ts"},["781"] = {line = 35, file = "json.ts"},["783"] = {line = 36, file = "json.ts"},["785"] = {line = 29, file = "json.ts"},["788"] = {line = 38, file = "json.ts"},["790"] = {line = 51, file = "json.ts"},["791"] = {line = 52, file = "json.ts"},["792"] = {line = 53, file = "json.ts"},["793"] = {line = 54, file = "json.ts"},["796"] = {line = 55, file = "json.ts"},["799"] = {line = 59, file = "json.ts"},["800"] = {line = 60, file = "json.ts"},["802"] = {line = 60, file = "json.ts"},["803"] = {line = 60, file = "json.ts"},["804"] = {line = 60, file = "json.ts"},["805"] = {line = 60, file = "json.ts"},["809"] = {line = 61, file = "json.ts"},["811"] = {line = 64, file = "json.ts"},["812"] = {line = 65, file = "json.ts"},["813"] = {line = 66, file = "json.ts"},["814"] = {line = 67, file = "json.ts"},["815"] = {line = 67, file = "json.ts"},["817"] = {line = 68, file = "json.ts"},["818"] = {line = 68, file = "json.ts"},["820"] = {line = 69, file = "json.ts"},["821"] = {line = 69, file = "json.ts"},["823"] = {line = 70, file = "json.ts"},["824"] = {line = 70, file = "json.ts"},["825"] = {line = 70, file = "json.ts"},["827"] = {line = 71, file = "json.ts"},["828"] = {line = 71, file = "json.ts"},["829"] = {line = 71, file = "json.ts"},["831"] = {line = 72, file = "json.ts"},["832"] = {line = 72, file = "json.ts"},["833"] = {line = 72, file = "json.ts"},["835"] = {line = 73, file = "json.ts"},["837"] = {line = 76, file = "json.ts"},["838"] = {line = 77, file = "json.ts"},["839"] = {line = 78, file = "json.ts"},["840"] = {line = 78, file = "json.ts"},["841"] = {line = 78, file = "json.ts"},["842"] = {line = 78, file = "json.ts"},["843"] = {line = 78, file = "json.ts"},["844"] = {line = 78, file = "json.ts"},["845"] = {line = 78, file = "json.ts"},["847"] = {line = 79, file = "json.ts"},["849"] = {line = 79, file = "json.ts"},["850"] = {line = 79, file = "json.ts"},["851"] = {line = 79, file = "json.ts"},["852"] = {line = 79, file = "json.ts"},["856"] = {line = 80, file = "json.ts"},["857"] = {line = 81, file = "json.ts"},["859"] = {line = 81, file = "json.ts"},["860"] = {line = 81, file = "json.ts"},["861"] = {line = 81, file = "json.ts"},["862"] = {line = 81, file = "json.ts"},["866"] = {line = 82, file = "json.ts"},["868"] = {line = 85, file = "json.ts"},["869"] = {line = 86, file = "json.ts"},["870"] = {line = 87, file = "json.ts"},["871"] = {line = 88, file = "json.ts"},["872"] = {line = 89, file = "json.ts"},["873"] = {line = 90, file = "json.ts"},["874"] = {line = 91, file = "json.ts"},["875"] = {line = 91, file = "json.ts"},["877"] = {line = 92, file = "json.ts"},["878"] = {line = 93, file = "json.ts"},["879"] = {line = 94, file = "json.ts"},["880"] = {line = 95, file = "json.ts"},["881"] = {line = 95, file = "json.ts"},["882"] = {line = 96, file = "json.ts"},["883"] = {line = 96, file = "json.ts"},["884"] = {line = 97, file = "json.ts"},["885"] = {line = 97, file = "json.ts"},["887"] = {line = 98, file = "json.ts"},["890"] = {line = 100, file = "json.ts"},["894"] = {line = 103, file = "json.ts"},["898"] = {line = 106, file = "json.ts"},["899"] = {line = 107, file = "json.ts"},["900"] = {line = 108, file = "json.ts"},["901"] = {line = 109, file = "json.ts"},["902"] = {line = 110, file = "json.ts"},["903"] = {line = 110, file = "json.ts"},["904"] = {line = 110, file = "json.ts"},["906"] = {line = 111, file = "json.ts"},["907"] = {line = 112, file = "json.ts"},["908"] = {line = 113, file = "json.ts"},["909"] = {line = 114, file = "json.ts"},["910"] = {line = 115, file = "json.ts"},["911"] = {line = 116, file = "json.ts"},["912"] = {line = 116, file = "json.ts"},["914"] = {line = 117, file = "json.ts"},["916"] = {line = 117, file = "json.ts"},["917"] = {line = 117, file = "json.ts"},["918"] = {line = 117, file = "json.ts"},["919"] = {line = 117, file = "json.ts"},["925"] = {line = 121, file = "json.ts"},["926"] = {line = 122, file = "json.ts"},["927"] = {line = 123, file = "json.ts"},["928"] = {line = 124, file = "json.ts"},["929"] = {line = 125, file = "json.ts"},["930"] = {line = 125, file = "json.ts"},["931"] = {line = 125, file = "json.ts"},["933"] = {line = 126, file = "json.ts"},["934"] = {line = 127, file = "json.ts"},["935"] = {line = 128, file = "json.ts"},["937"] = {line = 128, file = "json.ts"},["938"] = {line = 128, file = "json.ts"},["939"] = {line = 128, file = "json.ts"},["940"] = {line = 128, file = "json.ts"},["944"] = {line = 129, file = "json.ts"},["945"] = {line = 130, file = "json.ts"},["946"] = {line = 131, file = "json.ts"},["948"] = {line = 131, file = "json.ts"},["949"] = {line = 131, file = "json.ts"},["950"] = {line = 131, file = "json.ts"},["951"] = {line = 131, file = "json.ts"},["955"] = {line = 132, file = "json.ts"},["956"] = {line = 133, file = "json.ts"},["957"] = {line = 134, file = "json.ts"},["958"] = {line = 134, file = "json.ts"},["960"] = {line = 135, file = "json.ts"},["961"] = {line = 136, file = "json.ts"},["962"] = {line = 137, file = "json.ts"},["963"] = {line = 138, file = "json.ts"},["964"] = {line = 138, file = "json.ts"},["966"] = {line = 139, file = "json.ts"},["968"] = {line = 139, file = "json.ts"},["969"] = {line = 139, file = "json.ts"},["970"] = {line = 139, file = "json.ts"},["971"] = {line = 139, file = "json.ts"},["979"] = {line = 5, file = "json.ts"},["980"] = {line = 6, file = "json.ts"},["981"] = {line = 6, file = "json.ts"},["983"] = {line = 7, file = "json.ts"},["984"] = {line = 7, file = "json.ts"},["986"] = {line = 8, file = "json.ts"},["987"] = {line = 9, file = "json.ts"},["988"] = {line = 9, file = "json.ts"},["990"] = {line = 10, file = "json.ts"},["992"] = {line = 12, file = "json.ts"},["993"] = {line = 12, file = "json.ts"},["995"] = {line = 13, file = "json.ts"},["996"] = {line = 14, file = "json.ts"},["997"] = {line = 15, file = "json.ts"},["998"] = {line = 15, file = "json.ts"},["1000"] = {line = 16, file = "json.ts"},["1002"] = {line = 18, file = "json.ts"},["1003"] = {line = 19, file = "json.ts"},["1004"] = {line = 20, file = "json.ts"},["1005"] = {line = 20, file = "json.ts"},["1007"] = {line = 21, file = "json.ts"},["1008"] = {line = 22, file = "json.ts"},["1009"] = {line = 23, file = "json.ts"},["1010"] = {line = 23, file = "json.ts"},["1012"] = {line = 24, file = "json.ts"},["1013"] = {line = 5, file = "json.ts"},["1014"] = {line = 43, file = "json.ts"},["1015"] = {line = 44, file = "json.ts"},["1016"] = {line = 45, file = "json.ts"},["1017"] = {line = 46, file = "json.ts"},["1018"] = {line = 47, file = "json.ts"},["1020"] = {line = 47, file = "json.ts"},["1021"] = {line = 47, file = "json.ts"},["1022"] = {line = 47, file = "json.ts"},["1023"] = {line = 47, file = "json.ts"},["1027"] = {line = 48, file = "json.ts"},["1028"] = {line = 43, file = "json.ts"},["1039"] = {line = 2, file = "rows.ts"},["1040"] = {line = 2, file = "rows.ts"},["1041"] = {line = 2, file = "rows.ts"},["1042"] = {line = 9, file = "rows.ts"},["1043"] = {line = 10, file = "rows.ts"},["1044"] = {line = 10, file = "rows.ts"},["1046"] = {line = 11, file = "rows.ts"},["1047"] = {line = 9, file = "rows.ts"},["1048"] = {line = 14, file = "rows.ts"},["1049"] = {line = 15, file = "rows.ts"},["1050"] = {line = 16, file = "rows.ts"},["1051"] = {line = 16, file = "rows.ts"},["1052"] = {line = 16, file = "rows.ts"},["1053"] = {line = 16, file = "rows.ts"},["1054"] = {line = 16, file = "rows.ts"},["1055"] = {line = 16, file = "rows.ts"},["1058"] = {line = 17, file = "rows.ts"},["1059"] = {line = 14, file = "rows.ts"},["1060"] = {line = 20, file = "rows.ts"},["1061"] = {line = 21, file = "rows.ts"},["1062"] = {line = 22, file = "rows.ts"},["1063"] = {line = 23, file = "rows.ts"},["1064"] = {line = 23, file = "rows.ts"},["1066"] = {line = 24, file = "rows.ts"},["1067"] = {line = 25, file = "rows.ts"},["1068"] = {line = 26, file = "rows.ts"},["1069"] = {line = 27, file = "rows.ts"},["1070"] = {line = 20, file = "rows.ts"},["1071"] = {line = 30, file = "rows.ts"},["1072"] = {line = 31, file = "rows.ts"},["1073"] = {line = 31, file = "rows.ts"},["1074"] = {line = 31, file = "rows.ts"},["1075"] = {line = 31, file = "rows.ts"},["1076"] = {line = 30, file = "rows.ts"},["1077"] = {line = 35, file = "rows.ts"},["1078"] = {line = 36, file = "rows.ts"},["1079"] = {line = 37, file = "rows.ts"},["1080"] = {line = 38, file = "rows.ts"},["1081"] = {line = 39, file = "rows.ts"},["1082"] = {line = 40, file = "rows.ts"},["1084"] = {line = 42, file = "rows.ts"},["1085"] = {line = 43, file = "rows.ts"},["1086"] = {line = 43, file = "rows.ts"},["1087"] = {line = 43, file = "rows.ts"},["1088"] = {line = 43, file = "rows.ts"},["1089"] = {line = 44, file = "rows.ts"},["1090"] = {line = 44, file = "rows.ts"},["1091"] = {line = 44, file = "rows.ts"},["1096"] = {line = 47, file = "rows.ts"},["1097"] = {line = 35, file = "rows.ts"},["1098"] = {line = 50, file = "rows.ts"},["1099"] = {line = 51, file = "rows.ts"},["1100"] = {line = 52, file = "rows.ts"},["1101"] = {line = 52, file = "rows.ts"},["1102"] = {line = 52, file = "rows.ts"},["1103"] = {line = 52, file = "rows.ts"},["1104"] = {line = 53, file = "rows.ts"},["1106"] = {line = 55, file = "rows.ts"},["1107"] = {line = 56, file = "rows.ts"},["1108"] = {line = 50, file = "rows.ts"},["1109"] = {line = 59, file = "rows.ts"},["1110"] = {line = 60, file = "rows.ts"},["1111"] = {line = 59, file = "rows.ts"},["1112"] = {line = 64, file = "rows.ts"},["1113"] = {line = 65, file = "rows.ts"},["1114"] = {line = 66, file = "rows.ts"},["1115"] = {line = 66, file = "rows.ts"},["1117"] = {line = 67, file = "rows.ts"},["1119"] = {line = 68, file = "rows.ts"},["1120"] = {line = 68, file = "rows.ts"},["1122"] = {line = 69, file = "rows.ts"},["1123"] = {line = 70, file = "rows.ts"},["1124"] = {line = 71, file = "rows.ts"},["1125"] = {line = 72, file = "rows.ts"},["1130"] = {line = 75, file = "rows.ts"},["1131"] = {line = 64, file = "rows.ts"},["1144"] = {line = 2, file = "config.ts"},["1145"] = {line = 2, file = "config.ts"},["1146"] = {line = 3, file = "config.ts"},["1147"] = {line = 3, file = "config.ts"},["1148"] = {line = 3, file = "config.ts"},["1149"] = {line = 4, file = "config.ts"},["1150"] = {line = 4, file = "config.ts"},["1151"] = {line = 4, file = "config.ts"},["1152"] = {line = 5, file = "config.ts"},["1153"] = {line = 5, file = "config.ts"},["1154"] = {line = 18, file = "config.ts"},["1155"] = {line = 19, file = "config.ts"},["1156"] = {line = 20, file = "config.ts"},["1157"] = {line = 22, file = "config.ts"},["1158"] = {line = 23, file = "config.ts"},["1159"] = {line = 23, file = "config.ts"},["1160"] = {line = 23, file = "config.ts"},["1161"] = {line = 23, file = "config.ts"},["1162"] = {line = 23, file = "config.ts"},["1163"] = {line = 23, file = "config.ts"},["1164"] = {line = 23, file = "config.ts"},["1165"] = {line = 23, file = "config.ts"},["1166"] = {line = 22, file = "config.ts"},["1167"] = {line = 26, file = "config.ts"},["1168"] = {line = 27, file = "config.ts"},["1169"] = {line = 26, file = "config.ts"},["1170"] = {line = 30, file = "config.ts"},["1171"] = {line = 31, file = "config.ts"},["1172"] = {line = 32, file = "config.ts"},["1173"] = {line = 32, file = "config.ts"},["1175"] = {line = 33, file = "config.ts"},["1178"] = {line = 37, file = "config.ts"},["1181"] = {line = 35, file = "config.ts"},["1187"] = {line = 34, file = "config.ts"},["1190"] = {line = 39, file = "config.ts"},["1191"] = {line = 39, file = "config.ts"},["1193"] = {line = 40, file = "config.ts"},["1194"] = {line = 41, file = "config.ts"},["1195"] = {line = 41, file = "config.ts"},["1196"] = {line = 41, file = "config.ts"},["1197"] = {line = 41, file = "config.ts"},["1201"] = {line = 43, file = "config.ts"},["1202"] = {line = 44, file = "config.ts"},["1203"] = {line = 45, file = "config.ts"},["1204"] = {line = 46, file = "config.ts"},["1205"] = {line = 46, file = "config.ts"},["1209"] = {line = 49, file = "config.ts"},["1210"] = {line = 50, file = "config.ts"},["1211"] = {line = 50, file = "config.ts"},["1212"] = {line = 51, file = "config.ts"},["1213"] = {line = 51, file = "config.ts"},["1216"] = {line = 53, file = "config.ts"},["1217"] = {line = 54, file = "config.ts"},["1218"] = {line = 54, file = "config.ts"},["1220"] = {line = 55, file = "config.ts"},["1221"] = {line = 56, file = "config.ts"},["1222"] = {line = 57, file = "config.ts"},["1223"] = {line = 57, file = "config.ts"},["1225"] = {line = 58, file = "config.ts"},["1226"] = {line = 58, file = "config.ts"},["1228"] = {line = 59, file = "config.ts"},["1229"] = {line = 60, file = "config.ts"},["1230"] = {line = 60, file = "config.ts"},["1231"] = {line = 60, file = "config.ts"},["1232"] = {line = 60, file = "config.ts"},["1233"] = {line = 60, file = "config.ts"},["1236"] = {line = 63, file = "config.ts"},["1237"] = {line = 64, file = "config.ts"},["1238"] = {line = 30, file = "config.ts"},["1239"] = {line = 67, file = "config.ts"},["1240"] = {line = 68, file = "config.ts"},["1241"] = {line = 68, file = "config.ts"},["1242"] = {line = 68, file = "config.ts"},["1243"] = {line = 68, file = "config.ts"},["1244"] = {line = 68, file = "config.ts"},["1245"] = {line = 68, file = "config.ts"},["1246"] = {line = 68, file = "config.ts"},["1247"] = {line = 68, file = "config.ts"},["1248"] = {line = 68, file = "config.ts"},["1249"] = {line = 67, file = "config.ts"},["1250"] = {line = 71, file = "config.ts"},["1251"] = {line = 72, file = "config.ts"},["1252"] = {line = 73, file = "config.ts"},["1253"] = {line = 73, file = "config.ts"},["1255"] = {line = 74, file = "config.ts"},["1256"] = {line = 75, file = "config.ts"},["1257"] = {line = 75, file = "config.ts"},["1258"] = {line = 75, file = "config.ts"},["1261"] = {line = 78, file = "config.ts"},["1262"] = {line = 71, file = "config.ts"},["1263"] = {line = 85, file = "config.ts"},["1264"] = {line = 86, file = "config.ts"},["1265"] = {line = 87, file = "config.ts"},["1266"] = {line = 87, file = "config.ts"},["1267"] = {line = 87, file = "config.ts"},["1268"] = {line = 87, file = "config.ts"},["1269"] = {line = 87, file = "config.ts"},["1270"] = {line = 87, file = "config.ts"},["1271"] = {line = 87, file = "config.ts"},["1272"] = {line = 87, file = "config.ts"},["1273"] = {line = 87, file = "config.ts"},["1274"] = {line = 87, file = "config.ts"},["1275"] = {line = 87, file = "config.ts"},["1276"] = {line = 87, file = "config.ts"},["1277"] = {line = 88, file = "config.ts"},["1278"] = {line = 89, file = "config.ts"},["1279"] = {line = 90, file = "config.ts"},["1280"] = {line = 90, file = "config.ts"},["1281"] = {line = 90, file = "config.ts"},["1283"] = {line = 91, file = "config.ts"},["1284"] = {line = 88, file = "config.ts"},["1285"] = {line = 93, file = "config.ts"},["1286"] = {line = 93, file = "config.ts"},["1287"] = {line = 93, file = "config.ts"},["1288"] = {line = 94, file = "config.ts"},["1289"] = {line = 94, file = "config.ts"},["1291"] = {line = 95, file = "config.ts"},["1292"] = {line = 95, file = "config.ts"},["1294"] = {line = 96, file = "config.ts"},["1296"] = {line = 98, file = "config.ts"},["1297"] = {line = 99, file = "config.ts"},["1298"] = {line = 99, file = "config.ts"},["1299"] = {line = 100, file = "config.ts"},["1300"] = {line = 101, file = "config.ts"},["1301"] = {line = 101, file = "config.ts"},["1303"] = {line = 102, file = "config.ts"},["1306"] = {line = 104, file = "config.ts"},["1307"] = {line = 105, file = "config.ts"},["1308"] = {line = 106, file = "config.ts"},["1309"] = {line = 106, file = "config.ts"},["1311"] = {line = 107, file = "config.ts"},["1314"] = {line = 109, file = "config.ts"},["1315"] = {line = 85, file = "config.ts"},["1316"] = {line = 112, file = "config.ts"},["1317"] = {line = 113, file = "config.ts"},["1318"] = {line = 114, file = "config.ts"},["1319"] = {line = 115, file = "config.ts"},["1321"] = {line = 117, file = "config.ts"},["1322"] = {line = 117, file = "config.ts"},["1323"] = {line = 117, file = "config.ts"},["1324"] = {line = 117, file = "config.ts"},["1325"] = {line = 117, file = "config.ts"},["1326"] = {line = 117, file = "config.ts"},["1327"] = {line = 117, file = "config.ts"},["1328"] = {line = 112, file = "config.ts"},["1341"] = {line = 3, file = "fixture-state.ts"},["1342"] = {line = 3, file = "fixture-state.ts"},["1343"] = {line = 4, file = "fixture-state.ts"},["1344"] = {line = 4, file = "fixture-state.ts"},["1345"] = {line = 4, file = "fixture-state.ts"},["1346"] = {line = 4, file = "fixture-state.ts"},["1347"] = {line = 17, file = "fixture-state.ts"},["1348"] = {line = 19, file = "fixture-state.ts"},["1349"] = {line = 20, file = "fixture-state.ts"},["1350"] = {line = 20, file = "fixture-state.ts"},["1352"] = {line = 21, file = "fixture-state.ts"},["1353"] = {line = 21, file = "fixture-state.ts"},["1355"] = {line = 22, file = "fixture-state.ts"},["1356"] = {line = 22, file = "fixture-state.ts"},["1358"] = {line = 23, file = "fixture-state.ts"},["1359"] = {line = 23, file = "fixture-state.ts"},["1361"] = {line = 24, file = "fixture-state.ts"},["1362"] = {line = 24, file = "fixture-state.ts"},["1364"] = {line = 25, file = "fixture-state.ts"},["1365"] = {line = 26, file = "fixture-state.ts"},["1366"] = {line = 27, file = "fixture-state.ts"},["1367"] = {line = 28, file = "fixture-state.ts"},["1368"] = {line = 29, file = "fixture-state.ts"},["1369"] = {line = 30, file = "fixture-state.ts"},["1370"] = {line = 31, file = "fixture-state.ts"},["1371"] = {line = 31, file = "fixture-state.ts"},["1372"] = {line = 31, file = "fixture-state.ts"},["1373"] = {line = 31, file = "fixture-state.ts"},["1374"] = {line = 31, file = "fixture-state.ts"},["1375"] = {line = 31, file = "fixture-state.ts"},["1376"] = {line = 32, file = "fixture-state.ts"},["1377"] = {line = 30, file = "fixture-state.ts"},["1378"] = {line = 19, file = "fixture-state.ts"},["1391"] = {line = 86, file = "view-model.ts"},["1392"] = {line = 4, file = "view-model.ts"},["1393"] = {line = 4, file = "view-model.ts"},["1394"] = {line = 4, file = "view-model.ts"},["1395"] = {line = 4, file = "view-model.ts"},["1396"] = {line = 40, file = "view-model.ts"},["1397"] = {line = 41, file = "view-model.ts"},["1398"] = {line = 40, file = "view-model.ts"},["1399"] = {line = 86, file = "view-model.ts"},["1400"] = {line = 87, file = "view-model.ts"},["1401"] = {line = 87, file = "view-model.ts"},["1403"] = {line = 88, file = "view-model.ts"},["1404"] = {line = 88, file = "view-model.ts"},["1406"] = {line = 89, file = "view-model.ts"},["1407"] = {line = 89, file = "view-model.ts"},["1409"] = {line = 90, file = "view-model.ts"},["1411"] = {line = 93, file = "view-model.ts"},["1412"] = {line = 94, file = "view-model.ts"},["1413"] = {line = 94, file = "view-model.ts"},["1415"] = {line = 95, file = "view-model.ts"},["1416"] = {line = 95, file = "view-model.ts"},["1418"] = {line = 96, file = "view-model.ts"},["1419"] = {line = 96, file = "view-model.ts"},["1421"] = {line = 97, file = "view-model.ts"},["1422"] = {line = 97, file = "view-model.ts"},["1424"] = {line = 98, file = "view-model.ts"},["1426"] = {line = 101, file = "view-model.ts"},["1427"] = {line = 102, file = "view-model.ts"},["1428"] = {line = 103, file = "view-model.ts"},["1429"] = {line = 104, file = "view-model.ts"},["1430"] = {line = 105, file = "view-model.ts"},["1431"] = {line = 106, file = "view-model.ts"},["1432"] = {line = 106, file = "view-model.ts"},["1434"] = {line = 107, file = "view-model.ts"},["1435"] = {line = 107, file = "view-model.ts"},["1438"] = {line = 109, file = "view-model.ts"},["1439"] = {line = 109, file = "view-model.ts"},["1440"] = {line = 109, file = "view-model.ts"},["1441"] = {line = 109, file = "view-model.ts"},["1442"] = {line = 110, file = "view-model.ts"},["1443"] = {line = 101, file = "view-model.ts"},["1444"] = {line = 114, file = "view-model.ts"},["1445"] = {line = 115, file = "view-model.ts"},["1446"] = {line = 115, file = "view-model.ts"},["1447"] = {line = 115, file = "view-model.ts"},["1448"] = {line = 115, file = "view-model.ts"},["1449"] = {line = 115, file = "view-model.ts"},["1451"] = {line = 116, file = "view-model.ts"},["1452"] = {line = 116, file = "view-model.ts"},["1453"] = {line = 116, file = "view-model.ts"},["1454"] = {line = 116, file = "view-model.ts"},["1455"] = {line = 116, file = "view-model.ts"},["1457"] = {line = 117, file = "view-model.ts"},["1459"] = {line = 163, file = "view-model.ts"},["1460"] = {line = 164, file = "view-model.ts"},["1461"] = {line = 165, file = "view-model.ts"},["1462"] = {line = 166, file = "view-model.ts"},["1463"] = {line = 166, file = "view-model.ts"},["1464"] = {line = 166, file = "view-model.ts"},["1465"] = {line = 166, file = "view-model.ts"},["1466"] = {line = 167, file = "view-model.ts"},["1467"] = {line = 168, file = "view-model.ts"},["1468"] = {line = 168, file = "view-model.ts"},["1469"] = {line = 168, file = "view-model.ts"},["1470"] = {line = 168, file = "view-model.ts"},["1471"] = {line = 169, file = "view-model.ts"},["1472"] = {line = 168, file = "view-model.ts"},["1473"] = {line = 170, file = "view-model.ts"},["1474"] = {line = 171, file = "view-model.ts"},["1475"] = {line = 172, file = "view-model.ts"},["1476"] = {line = 172, file = "view-model.ts"},["1477"] = {line = 172, file = "view-model.ts"},["1478"] = {line = 172, file = "view-model.ts"},["1479"] = {line = 173, file = "view-model.ts"},["1480"] = {line = 173, file = "view-model.ts"},["1481"] = {line = 173, file = "view-model.ts"},["1482"] = {line = 173, file = "view-model.ts"},["1483"] = {line = 173, file = "view-model.ts"},["1484"] = {line = 173, file = "view-model.ts"},["1485"] = {line = 173, file = "view-model.ts"},["1486"] = {line = 174, file = "view-model.ts"},["1487"] = {line = 174, file = "view-model.ts"},["1488"] = {line = 174, file = "view-model.ts"},["1489"] = {line = 174, file = "view-model.ts"},["1490"] = {line = 174, file = "view-model.ts"},["1491"] = {line = 174, file = "view-model.ts"},["1492"] = {line = 174, file = "view-model.ts"},["1493"] = {line = 174, file = "view-model.ts"},["1494"] = {line = 175, file = "view-model.ts"},["1495"] = {line = 176, file = "view-model.ts"},["1496"] = {line = 176, file = "view-model.ts"},["1497"] = {line = 176, file = "view-model.ts"},["1498"] = {line = 176, file = "view-model.ts"},["1499"] = {line = 176, file = "view-model.ts"},["1500"] = {line = 177, file = "view-model.ts"},["1501"] = {line = 177, file = "view-model.ts"},["1502"] = {line = 177, file = "view-model.ts"},["1503"] = {line = 177, file = "view-model.ts"},["1504"] = {line = 177, file = "view-model.ts"},["1505"] = {line = 177, file = "view-model.ts"},["1506"] = {line = 177, file = "view-model.ts"},["1508"] = {line = 178, file = "view-model.ts"},["1511"] = {line = 180, file = "view-model.ts"},["1512"] = {line = 181, file = "view-model.ts"},["1513"] = {line = 181, file = "view-model.ts"},["1515"] = {line = 182, file = "view-model.ts"},["1519"] = {line = 185, file = "view-model.ts"},["1520"] = {line = 186, file = "view-model.ts"},["1521"] = {line = 187, file = "view-model.ts"},["1522"] = {line = 188, file = "view-model.ts"},["1523"] = {line = 188, file = "view-model.ts"},["1524"] = {line = 188, file = "view-model.ts"},["1525"] = {line = 188, file = "view-model.ts"},["1526"] = {line = 188, file = "view-model.ts"},["1527"] = {line = 188, file = "view-model.ts"},["1529"] = {line = 7, file = "view-model.ts"},["1530"] = {line = 8, file = "view-model.ts"},["1531"] = {line = 8, file = "view-model.ts"},["1532"] = {line = 8, file = "view-model.ts"},["1533"] = {line = 8, file = "view-model.ts"},["1534"] = {line = 9, file = "view-model.ts"},["1535"] = {line = 9, file = "view-model.ts"},["1536"] = {line = 9, file = "view-model.ts"},["1537"] = {line = 7, file = "view-model.ts"},["1538"] = {line = 11, file = "view-model.ts"},["1539"] = {line = 12, file = "view-model.ts"},["1540"] = {line = 13, file = "view-model.ts"},["1541"] = {line = 14, file = "view-model.ts"},["1542"] = {line = 15, file = "view-model.ts"},["1543"] = {line = 16, file = "view-model.ts"},["1544"] = {line = 17, file = "view-model.ts"},["1545"] = {line = 18, file = "view-model.ts"},["1546"] = {line = 19, file = "view-model.ts"},["1547"] = {line = 20, file = "view-model.ts"},["1548"] = {line = 11, file = "view-model.ts"},["1549"] = {line = 22, file = "view-model.ts"},["1550"] = {line = 23, file = "view-model.ts"},["1551"] = {line = 32, file = "view-model.ts"},["1552"] = {line = 33, file = "view-model.ts"},["1553"] = {line = 33, file = "view-model.ts"},["1554"] = {line = 33, file = "view-model.ts"},["1555"] = {line = 33, file = "view-model.ts"},["1556"] = {line = 33, file = "view-model.ts"},["1557"] = {line = 33, file = "view-model.ts"},["1558"] = {line = 33, file = "view-model.ts"},["1559"] = {line = 33, file = "view-model.ts"},["1560"] = {line = 33, file = "view-model.ts"},["1561"] = {line = 33, file = "view-model.ts"},["1562"] = {line = 35, file = "view-model.ts"},["1563"] = {line = 36, file = "view-model.ts"},["1564"] = {line = 36, file = "view-model.ts"},["1565"] = {line = 36, file = "view-model.ts"},["1566"] = {line = 36, file = "view-model.ts"},["1567"] = {line = 37, file = "view-model.ts"},["1568"] = {line = 37, file = "view-model.ts"},["1569"] = {line = 37, file = "view-model.ts"},["1570"] = {line = 37, file = "view-model.ts"},["1571"] = {line = 35, file = "view-model.ts"},["1572"] = {line = 44, file = "view-model.ts"},["1573"] = {line = 45, file = "view-model.ts"},["1574"] = {line = 44, file = "view-model.ts"},["1575"] = {line = 48, file = "view-model.ts"},["1576"] = {line = 49, file = "view-model.ts"},["1577"] = {line = 50, file = "view-model.ts"},["1578"] = {line = 51, file = "view-model.ts"},["1579"] = {line = 52, file = "view-model.ts"},["1580"] = {line = 53, file = "view-model.ts"},["1581"] = {line = 53, file = "view-model.ts"},["1582"] = {line = 53, file = "view-model.ts"},["1583"] = {line = 53, file = "view-model.ts"},["1584"] = {line = 53, file = "view-model.ts"},["1585"] = {line = 53, file = "view-model.ts"},["1586"] = {line = 52, file = "view-model.ts"},["1587"] = {line = 55, file = "view-model.ts"},["1588"] = {line = 55, file = "view-model.ts"},["1589"] = {line = 55, file = "view-model.ts"},["1590"] = {line = 56, file = "view-model.ts"},["1591"] = {line = 57, file = "view-model.ts"},["1592"] = {line = 57, file = "view-model.ts"},["1593"] = {line = 57, file = "view-model.ts"},["1594"] = {line = 57, file = "view-model.ts"},["1595"] = {line = 57, file = "view-model.ts"},["1596"] = {line = 57, file = "view-model.ts"},["1597"] = {line = 57, file = "view-model.ts"},["1598"] = {line = 57, file = "view-model.ts"},["1599"] = {line = 58, file = "view-model.ts"},["1601"] = {line = 60, file = "view-model.ts"},["1602"] = {line = 60, file = "view-model.ts"},["1603"] = {line = 60, file = "view-model.ts"},["1604"] = {line = 61, file = "view-model.ts"},["1605"] = {line = 61, file = "view-model.ts"},["1606"] = {line = 61, file = "view-model.ts"},["1607"] = {line = 61, file = "view-model.ts"},["1608"] = {line = 61, file = "view-model.ts"},["1609"] = {line = 61, file = "view-model.ts"},["1610"] = {line = 61, file = "view-model.ts"},["1611"] = {line = 61, file = "view-model.ts"},["1612"] = {line = 61, file = "view-model.ts"},["1613"] = {line = 61, file = "view-model.ts"},["1614"] = {line = 61, file = "view-model.ts"},["1615"] = {line = 61, file = "view-model.ts"},["1616"] = {line = 61, file = "view-model.ts"},["1617"] = {line = 61, file = "view-model.ts"},["1618"] = {line = 61, file = "view-model.ts"},["1619"] = {line = 62, file = "view-model.ts"},["1620"] = {line = 63, file = "view-model.ts"},["1621"] = {line = 63, file = "view-model.ts"},["1622"] = {line = 63, file = "view-model.ts"},["1623"] = {line = 64, file = "view-model.ts"},["1624"] = {line = 65, file = "view-model.ts"},["1625"] = {line = 66, file = "view-model.ts"},["1626"] = {line = 67, file = "view-model.ts"},["1627"] = {line = 67, file = "view-model.ts"},["1628"] = {line = 67, file = "view-model.ts"},["1629"] = {line = 67, file = "view-model.ts"},["1630"] = {line = 67, file = "view-model.ts"},["1631"] = {line = 67, file = "view-model.ts"},["1632"] = {line = 67, file = "view-model.ts"},["1633"] = {line = 67, file = "view-model.ts"},["1634"] = {line = 68, file = "view-model.ts"},["1635"] = {line = 68, file = "view-model.ts"},["1636"] = {line = 68, file = "view-model.ts"},["1637"] = {line = 68, file = "view-model.ts"},["1638"] = {line = 68, file = "view-model.ts"},["1639"] = {line = 68, file = "view-model.ts"},["1640"] = {line = 68, file = "view-model.ts"},["1641"] = {line = 68, file = "view-model.ts"},["1642"] = {line = 68, file = "view-model.ts"},["1643"] = {line = 68, file = "view-model.ts"},["1644"] = {line = 68, file = "view-model.ts"},["1645"] = {line = 68, file = "view-model.ts"},["1646"] = {line = 68, file = "view-model.ts"},["1647"] = {line = 68, file = "view-model.ts"},["1648"] = {line = 68, file = "view-model.ts"},["1649"] = {line = 69, file = "view-model.ts"},["1650"] = {line = 69, file = "view-model.ts"},["1651"] = {line = 69, file = "view-model.ts"},["1652"] = {line = 69, file = "view-model.ts"},["1653"] = {line = 69, file = "view-model.ts"},["1654"] = {line = 69, file = "view-model.ts"},["1655"] = {line = 69, file = "view-model.ts"},["1656"] = {line = 69, file = "view-model.ts"},["1659"] = {line = 72, file = "view-model.ts"},["1660"] = {line = 73, file = "view-model.ts"},["1661"] = {line = 74, file = "view-model.ts"},["1662"] = {line = 74, file = "view-model.ts"},["1663"] = {line = 74, file = "view-model.ts"},["1664"] = {line = 74, file = "view-model.ts"},["1665"] = {line = 74, file = "view-model.ts"},["1666"] = {line = 74, file = "view-model.ts"},["1667"] = {line = 74, file = "view-model.ts"},["1668"] = {line = 74, file = "view-model.ts"},["1669"] = {line = 75, file = "view-model.ts"},["1670"] = {line = 75, file = "view-model.ts"},["1671"] = {line = 75, file = "view-model.ts"},["1672"] = {line = 75, file = "view-model.ts"},["1673"] = {line = 75, file = "view-model.ts"},["1674"] = {line = 75, file = "view-model.ts"},["1675"] = {line = 75, file = "view-model.ts"},["1676"] = {line = 75, file = "view-model.ts"},["1677"] = {line = 75, file = "view-model.ts"},["1678"] = {line = 75, file = "view-model.ts"},["1679"] = {line = 75, file = "view-model.ts"},["1680"] = {line = 75, file = "view-model.ts"},["1681"] = {line = 75, file = "view-model.ts"},["1682"] = {line = 75, file = "view-model.ts"},["1683"] = {line = 75, file = "view-model.ts"},["1684"] = {line = 76, file = "view-model.ts"},["1685"] = {line = 76, file = "view-model.ts"},["1686"] = {line = 76, file = "view-model.ts"},["1687"] = {line = 76, file = "view-model.ts"},["1688"] = {line = 76, file = "view-model.ts"},["1689"] = {line = 76, file = "view-model.ts"},["1690"] = {line = 76, file = "view-model.ts"},["1691"] = {line = 77, file = "view-model.ts"},["1692"] = {line = 78, file = "view-model.ts"},["1693"] = {line = 78, file = "view-model.ts"},["1694"] = {line = 78, file = "view-model.ts"},["1695"] = {line = 78, file = "view-model.ts"},["1696"] = {line = 79, file = "view-model.ts"},["1697"] = {line = 79, file = "view-model.ts"},["1698"] = {line = 79, file = "view-model.ts"},["1699"] = {line = 79, file = "view-model.ts"},["1700"] = {line = 79, file = "view-model.ts"},["1701"] = {line = 79, file = "view-model.ts"},["1702"] = {line = 79, file = "view-model.ts"},["1703"] = {line = 79, file = "view-model.ts"},["1704"] = {line = 80, file = "view-model.ts"},["1706"] = {line = 63, file = "view-model.ts"},["1707"] = {line = 63, file = "view-model.ts"},["1708"] = {line = 83, file = "view-model.ts"},["1709"] = {line = 48, file = "view-model.ts"},["1710"] = {line = 120, file = "view-model.ts"},["1711"] = {line = 121, file = "view-model.ts"},["1712"] = {line = 122, file = "view-model.ts"},["1713"] = {line = 122, file = "view-model.ts"},["1714"] = {line = 122, file = "view-model.ts"},["1716"] = {line = 122, file = "view-model.ts"},["1717"] = {line = 122, file = "view-model.ts"},["1719"] = {line = 122, file = "view-model.ts"},["1720"] = {line = 122, file = "view-model.ts"},["1721"] = {line = 123, file = "view-model.ts"},["1722"] = {line = 123, file = "view-model.ts"},["1723"] = {line = 123, file = "view-model.ts"},["1724"] = {line = 123, file = "view-model.ts"},["1725"] = {line = 123, file = "view-model.ts"},["1726"] = {line = 123, file = "view-model.ts"},["1727"] = {line = 124, file = "view-model.ts"},["1728"] = {line = 125, file = "view-model.ts"},["1729"] = {line = 126, file = "view-model.ts"},["1730"] = {line = 127, file = "view-model.ts"},["1731"] = {line = 127, file = "view-model.ts"},["1732"] = {line = 127, file = "view-model.ts"},["1733"] = {line = 127, file = "view-model.ts"},["1734"] = {line = 127, file = "view-model.ts"},["1735"] = {line = 128, file = "view-model.ts"},["1736"] = {line = 128, file = "view-model.ts"},["1737"] = {line = 128, file = "view-model.ts"},["1738"] = {line = 128, file = "view-model.ts"},["1739"] = {line = 128, file = "view-model.ts"},["1740"] = {line = 128, file = "view-model.ts"},["1741"] = {line = 128, file = "view-model.ts"},["1742"] = {line = 129, file = "view-model.ts"},["1743"] = {line = 130, file = "view-model.ts"},["1744"] = {line = 131, file = "view-model.ts"},["1745"] = {line = 131, file = "view-model.ts"},["1746"] = {line = 131, file = "view-model.ts"},["1747"] = {line = 131, file = "view-model.ts"},["1748"] = {line = 131, file = "view-model.ts"},["1749"] = {line = 131, file = "view-model.ts"},["1750"] = {line = 131, file = "view-model.ts"},["1752"] = {line = 133, file = "view-model.ts"},["1754"] = {line = 134, file = "view-model.ts"},["1755"] = {line = 135, file = "view-model.ts"},["1756"] = {line = 136, file = "view-model.ts"},["1758"] = {line = 138, file = "view-model.ts"},["1759"] = {line = 139, file = "view-model.ts"},["1760"] = {line = 140, file = "view-model.ts"},["1761"] = {line = 141, file = "view-model.ts"},["1762"] = {line = 142, file = "view-model.ts"},["1763"] = {line = 143, file = "view-model.ts"},["1764"] = {line = 144, file = "view-model.ts"},["1765"] = {line = 144, file = "view-model.ts"},["1766"] = {line = 144, file = "view-model.ts"},["1767"] = {line = 144, file = "view-model.ts"},["1768"] = {line = 144, file = "view-model.ts"},["1769"] = {line = 144, file = "view-model.ts"},["1770"] = {line = 144, file = "view-model.ts"},["1771"] = {line = 144, file = "view-model.ts"},["1772"] = {line = 145, file = "view-model.ts"},["1773"] = {line = 146, file = "view-model.ts"},["1774"] = {line = 146, file = "view-model.ts"},["1775"] = {line = 146, file = "view-model.ts"},["1776"] = {line = 146, file = "view-model.ts"},["1777"] = {line = 146, file = "view-model.ts"},["1778"] = {line = 147, file = "view-model.ts"},["1779"] = {line = 147, file = "view-model.ts"},["1780"] = {line = 147, file = "view-model.ts"},["1781"] = {line = 147, file = "view-model.ts"},["1782"] = {line = 147, file = "view-model.ts"},["1783"] = {line = 147, file = "view-model.ts"},["1784"] = {line = 147, file = "view-model.ts"},["1786"] = {line = 148, file = "view-model.ts"},["1789"] = {line = 150, file = "view-model.ts"},["1790"] = {line = 150, file = "view-model.ts"},["1791"] = {line = 150, file = "view-model.ts"},["1792"] = {line = 150, file = "view-model.ts"},["1793"] = {line = 151, file = "view-model.ts"},["1794"] = {line = 152, file = "view-model.ts"},["1795"] = {line = 152, file = "view-model.ts"},["1796"] = {line = 152, file = "view-model.ts"},["1797"] = {line = 152, file = "view-model.ts"},["1798"] = {line = 152, file = "view-model.ts"},["1799"] = {line = 152, file = "view-model.ts"},["1800"] = {line = 153, file = "view-model.ts"},["1801"] = {line = 153, file = "view-model.ts"},["1802"] = {line = 153, file = "view-model.ts"},["1803"] = {line = 153, file = "view-model.ts"},["1804"] = {line = 153, file = "view-model.ts"},["1805"] = {line = 154, file = "view-model.ts"},["1806"] = {line = 154, file = "view-model.ts"},["1807"] = {line = 154, file = "view-model.ts"},["1808"] = {line = 154, file = "view-model.ts"},["1809"] = {line = 154, file = "view-model.ts"},["1810"] = {line = 155, file = "view-model.ts"},["1811"] = {line = 155, file = "view-model.ts"},["1812"] = {line = 155, file = "view-model.ts"},["1813"] = {line = 155, file = "view-model.ts"},["1814"] = {line = 155, file = "view-model.ts"},["1815"] = {line = 156, file = "view-model.ts"},["1816"] = {line = 156, file = "view-model.ts"},["1817"] = {line = 156, file = "view-model.ts"},["1818"] = {line = 156, file = "view-model.ts"},["1819"] = {line = 156, file = "view-model.ts"},["1823"] = {line = 158, file = "view-model.ts"},["1824"] = {line = 120, file = "view-model.ts"},["1833"] = {line = 4, file = "handles.ts"},["1834"] = {line = 5, file = "handles.ts"},["1835"] = {line = 5, file = "handles.ts"},["1837"] = {line = 6, file = "handles.ts"},["1838"] = {line = 7, file = "handles.ts"},["1839"] = {line = 4, file = "handles.ts"},["1840"] = {line = 10, file = "handles.ts"},["1841"] = {line = 11, file = "handles.ts"},["1842"] = {line = 11, file = "handles.ts"},["1844"] = {line = 12, file = "handles.ts"},["1845"] = {line = 12, file = "handles.ts"},["1847"] = {line = 13, file = "handles.ts"},["1848"] = {line = 10, file = "handles.ts"},["1849"] = {line = 16, file = "handles.ts"},["1850"] = {line = 17, file = "handles.ts"},["1851"] = {line = 17, file = "handles.ts"},["1852"] = {line = 17, file = "handles.ts"},["1855"] = {line = 18, file = "handles.ts"},["1856"] = {line = 16, file = "handles.ts"},["1865"] = {line = 2, file = "log.ts"},["1866"] = {line = 4, file = "log.ts"},["1867"] = {line = 5, file = "log.ts"},["1868"] = {line = 4, file = "log.ts"},["1869"] = {line = 8, file = "log.ts"},["1870"] = {line = 9, file = "log.ts"},["1873"] = {line = 10, file = "log.ts"},["1874"] = {line = 11, file = "log.ts"},["1875"] = {line = 8, file = "log.ts"},["1884"] = {line = 2, file = "appearances.ts"},["1885"] = {line = 2, file = "appearances.ts"},["1886"] = {line = 3, file = "appearances.ts"},["1887"] = {line = 3, file = "appearances.ts"},["1888"] = {line = 4, file = "appearances.ts"},["1889"] = {line = 4, file = "appearances.ts"},["1890"] = {line = 4, file = "appearances.ts"},["1891"] = {line = 5, file = "appearances.ts"},["1892"] = {line = 5, file = "appearances.ts"},["1893"] = {line = 8, file = "appearances.ts"},["1894"] = {line = 10, file = "appearances.ts"},["1895"] = {line = 11, file = "appearances.ts"},["1896"] = {line = 10, file = "appearances.ts"},["1897"] = {line = 14, file = "appearances.ts"},["1898"] = {line = 15, file = "appearances.ts"},["1899"] = {line = 15, file = "appearances.ts"},["1900"] = {line = 15, file = "appearances.ts"},["1903"] = {line = 16, file = "appearances.ts"},["1904"] = {line = 14, file = "appearances.ts"},["1905"] = {line = 19, file = "appearances.ts"},["1906"] = {line = 21, file = "appearances.ts"},["1907"] = {line = 22, file = "appearances.ts"},["1908"] = {line = 23, file = "appearances.ts"},["1909"] = {line = 24, file = "appearances.ts"},["1910"] = {line = 25, file = "appearances.ts"},["1911"] = {line = 25, file = "appearances.ts"},["1914"] = {line = 27, file = "appearances.ts"},["1915"] = {line = 21, file = "appearances.ts"},["1916"] = {line = 31, file = "appearances.ts"},["1917"] = {line = 32, file = "appearances.ts"},["1918"] = {line = 33, file = "appearances.ts"},["1919"] = {line = 34, file = "appearances.ts"},["1921"] = {line = 35, file = "appearances.ts"},["1922"] = {line = 35, file = "appearances.ts"},["1924"] = {line = 36, file = "appearances.ts"},["1925"] = {line = 37, file = "appearances.ts"},["1926"] = {line = 38, file = "appearances.ts"},["1927"] = {line = 39, file = "appearances.ts"},["1929"] = {line = 41, file = "appearances.ts"},["1930"] = {line = 42, file = "appearances.ts"},["1931"] = {line = 42, file = "appearances.ts"},["1935"] = {line = 35, file = "appearances.ts"},["1938"] = {line = 44, file = "appearances.ts"},["1939"] = {line = 31, file = "appearances.ts"},["1940"] = {line = 48, file = "appearances.ts"},["1941"] = {line = 49, file = "appearances.ts"},["1942"] = {line = 50, file = "appearances.ts"},["1943"] = {line = 50, file = "appearances.ts"},["1945"] = {line = 51, file = "appearances.ts"},["1946"] = {line = 51, file = "appearances.ts"},["1947"] = {line = 51, file = "appearances.ts"},["1948"] = {line = 51, file = "appearances.ts"},["1949"] = {line = 52, file = "appearances.ts"},["1950"] = {line = 53, file = "appearances.ts"},["1951"] = {line = 48, file = "appearances.ts"},["1952"] = {line = 58, file = "appearances.ts"},["1953"] = {line = 59, file = "appearances.ts"},["1954"] = {line = 60, file = "appearances.ts"},["1955"] = {line = 60, file = "appearances.ts"},["1957"] = {line = 61, file = "appearances.ts"},["1958"] = {line = 64, file = "appearances.ts"},["1960"] = {line = 65, file = "appearances.ts"},["1961"] = {line = 66, file = "appearances.ts"},["1962"] = {line = 66, file = "appearances.ts"},["1963"] = {line = 66, file = "appearances.ts"},["1965"] = {line = 66, file = "appearances.ts"},["1967"] = {line = 66, file = "appearances.ts"},["1968"] = {line = 67, file = "appearances.ts"},["1969"] = {line = 67, file = "appearances.ts"},["1973"] = {line = 71, file = "appearances.ts"},["1974"] = {line = 71, file = "appearances.ts"},["1975"] = {line = 71, file = "appearances.ts"},["1976"] = {line = 71, file = "appearances.ts"},["1979"] = {line = 69, file = "appearances.ts"},["1988"] = {line = 74, file = "appearances.ts"},["1989"] = {line = 74, file = "appearances.ts"},["1990"] = {line = 74, file = "appearances.ts"},["1991"] = {line = 74, file = "appearances.ts"},["1992"] = {line = 75, file = "appearances.ts"},["1993"] = {line = 76, file = "appearances.ts"},["1994"] = {line = 77, file = "appearances.ts"},["1995"] = {line = 78, file = "appearances.ts"},["1996"] = {line = 79, file = "appearances.ts"},["1997"] = {line = 80, file = "appearances.ts"},["1998"] = {line = 81, file = "appearances.ts"},["2000"] = {line = 83, file = "appearances.ts"},["2001"] = {line = 83, file = "appearances.ts"},["2003"] = {line = 84, file = "appearances.ts"},["2005"] = {line = 58, file = "appearances.ts"},["2006"] = {line = 89, file = "appearances.ts"},["2007"] = {line = 90, file = "appearances.ts"},["2008"] = {line = 91, file = "appearances.ts"},["2009"] = {line = 91, file = "appearances.ts"},["2011"] = {line = 92, file = "appearances.ts"},["2012"] = {line = 92, file = "appearances.ts"},["2014"] = {line = 93, file = "appearances.ts"},["2015"] = {line = 94, file = "appearances.ts"},["2016"] = {line = 94, file = "appearances.ts"},["2017"] = {line = 94, file = "appearances.ts"},["2019"] = {line = 94, file = "appearances.ts"},["2021"] = {line = 94, file = "appearances.ts"},["2022"] = {line = 95, file = "appearances.ts"},["2023"] = {line = 95, file = "appearances.ts"},["2024"] = {line = 95, file = "appearances.ts"},["2025"] = {line = 95, file = "appearances.ts"},["2027"] = {line = 95, file = "appearances.ts"},["2029"] = {line = 95, file = "appearances.ts"},["2030"] = {line = 96, file = "appearances.ts"},["2031"] = {line = 89, file = "appearances.ts"},["2046"] = {line = 72, file = "pool.ts"},["2047"] = {line = 2, file = "pool.ts"},["2048"] = {line = 2, file = "pool.ts"},["2049"] = {line = 2, file = "pool.ts"},["2050"] = {line = 3, file = "pool.ts"},["2051"] = {line = 3, file = "pool.ts"},["2052"] = {line = 3, file = "pool.ts"},["2053"] = {line = 3, file = "pool.ts"},["2054"] = {line = 4, file = "pool.ts"},["2055"] = {line = 4, file = "pool.ts"},["2056"] = {line = 16, file = "pool.ts"},["2057"] = {line = 17, file = "pool.ts"},["2058"] = {line = 17, file = "pool.ts"},["2059"] = {line = 17, file = "pool.ts"},["2060"] = {line = 17, file = "pool.ts"},["2061"] = {line = 16, file = "pool.ts"},["2062"] = {line = 20, file = "pool.ts"},["2063"] = {line = 21, file = "pool.ts"},["2064"] = {line = 22, file = "pool.ts"},["2065"] = {line = 23, file = "pool.ts"},["2066"] = {line = 24, file = "pool.ts"},["2068"] = {line = 26, file = "pool.ts"},["2070"] = {line = 26, file = "pool.ts"},["2074"] = {line = 27, file = "pool.ts"},["2075"] = {line = 20, file = "pool.ts"},["2076"] = {line = 32, file = "pool.ts"},["2077"] = {line = 33, file = "pool.ts"},["2078"] = {line = 34, file = "pool.ts"},["2079"] = {line = 34, file = "pool.ts"},["2081"] = {line = 35, file = "pool.ts"},["2082"] = {line = 36, file = "pool.ts"},["2083"] = {line = 36, file = "pool.ts"},["2084"] = {line = 36, file = "pool.ts"},["2086"] = {line = 36, file = "pool.ts"},["2088"] = {line = 36, file = "pool.ts"},["2089"] = {line = 37, file = "pool.ts"},["2090"] = {line = 37, file = "pool.ts"},["2092"] = {line = 38, file = "pool.ts"},["2093"] = {line = 32, file = "pool.ts"},["2094"] = {line = 48, file = "pool.ts"},["2095"] = {line = 49, file = "pool.ts"},["2096"] = {line = 50, file = "pool.ts"},["2099"] = {line = 51, file = "pool.ts"},["2100"] = {line = 52, file = "pool.ts"},["2101"] = {line = 53, file = "pool.ts"},["2102"] = {line = 53, file = "pool.ts"},["2103"] = {line = 53, file = "pool.ts"},["2104"] = {line = 53, file = "pool.ts"},["2106"] = {line = 54, file = "pool.ts"},["2107"] = {line = 55, file = "pool.ts"},["2108"] = {line = 48, file = "pool.ts"},["2109"] = {line = 72, file = "pool.ts"},["2110"] = {line = 73, file = "pool.ts"},["2111"] = {line = 74, file = "pool.ts"},["2112"] = {line = 75, file = "pool.ts"},["2114"] = {line = 77, file = "pool.ts"},["2115"] = {line = 78, file = "pool.ts"},["2117"] = {line = 127, file = "pool.ts"},["2118"] = {line = 128, file = "pool.ts"},["2119"] = {line = 129, file = "pool.ts"},["2120"] = {line = 129, file = "pool.ts"},["2122"] = {line = 130, file = "pool.ts"},["2123"] = {line = 131, file = "pool.ts"},["2124"] = {line = 132, file = "pool.ts"},["2125"] = {line = 132, file = "pool.ts"},["2128"] = {line = 134, file = "pool.ts"},["2130"] = {line = 171, file = "pool.ts"},["2131"] = {line = 172, file = "pool.ts"},["2132"] = {line = 173, file = "pool.ts"},["2133"] = {line = 171, file = "pool.ts"},["2134"] = {line = 6, file = "pool.ts"},["2135"] = {line = 7, file = "pool.ts"},["2136"] = {line = 8, file = "pool.ts"},["2137"] = {line = 9, file = "pool.ts"},["2138"] = {line = 10, file = "pool.ts"},["2139"] = {line = 12, file = "pool.ts"},["2140"] = {line = 12, file = "pool.ts"},["2141"] = {line = 12, file = "pool.ts"},["2142"] = {line = 13, file = "pool.ts"},["2143"] = {line = 13, file = "pool.ts"},["2144"] = {line = 13, file = "pool.ts"},["2145"] = {line = 14, file = "pool.ts"},["2146"] = {line = 14, file = "pool.ts"},["2147"] = {line = 14, file = "pool.ts"},["2148"] = {line = 30, file = "pool.ts"},["2149"] = {line = 43, file = "pool.ts"},["2150"] = {line = 44, file = "pool.ts"},["2151"] = {line = 43, file = "pool.ts"},["2152"] = {line = 59, file = "pool.ts"},["2153"] = {line = 60, file = "pool.ts"},["2154"] = {line = 59, file = "pool.ts"},["2155"] = {line = 64, file = "pool.ts"},["2156"] = {line = 65, file = "pool.ts"},["2157"] = {line = 64, file = "pool.ts"},["2158"] = {line = 69, file = "pool.ts"},["2159"] = {line = 69, file = "pool.ts"},["2160"] = {line = 69, file = "pool.ts"},["2161"] = {line = 70, file = "pool.ts"},["2162"] = {line = 70, file = "pool.ts"},["2163"] = {line = 70, file = "pool.ts"},["2164"] = {line = 81, file = "pool.ts"},["2165"] = {line = 82, file = "pool.ts"},["2166"] = {line = 83, file = "pool.ts"},["2169"] = {line = 84, file = "pool.ts"},["2170"] = {line = 85, file = "pool.ts"},["2171"] = {line = 81, file = "pool.ts"},["2172"] = {line = 89, file = "pool.ts"},["2173"] = {line = 90, file = "pool.ts"},["2174"] = {line = 91, file = "pool.ts"},["2175"] = {line = 89, file = "pool.ts"},["2176"] = {line = 94, file = "pool.ts"},["2177"] = {line = 96, file = "pool.ts"},["2178"] = {line = 97, file = "pool.ts"},["2179"] = {line = 96, file = "pool.ts"},["2180"] = {line = 102, file = "pool.ts"},["2181"] = {line = 103, file = "pool.ts"},["2182"] = {line = 104, file = "pool.ts"},["2183"] = {line = 105, file = "pool.ts"},["2184"] = {line = 106, file = "pool.ts"},["2185"] = {line = 107, file = "pool.ts"},["2186"] = {line = 108, file = "pool.ts"},["2187"] = {line = 109, file = "pool.ts"},["2188"] = {line = 110, file = "pool.ts"},["2189"] = {line = 111, file = "pool.ts"},["2190"] = {line = 112, file = "pool.ts"},["2191"] = {line = 113, file = "pool.ts"},["2193"] = {line = 115, file = "pool.ts"},["2194"] = {line = 116, file = "pool.ts"},["2195"] = {line = 117, file = "pool.ts"},["2196"] = {line = 118, file = "pool.ts"},["2197"] = {line = 119, file = "pool.ts"},["2199"] = {line = 121, file = "pool.ts"},["2200"] = {line = 122, file = "pool.ts"},["2202"] = {line = 122, file = "pool.ts"},["2203"] = {line = 122, file = "pool.ts"},["2204"] = {line = 122, file = "pool.ts"},["2205"] = {line = 122, file = "pool.ts"},["2207"] = {line = 122, file = "pool.ts"},["2209"] = {line = 122, file = "pool.ts"},["2210"] = {line = 122, file = "pool.ts"},["2212"] = {line = 123, file = "pool.ts"},["2213"] = {line = 102, file = "pool.ts"},["2214"] = {line = 138, file = "pool.ts"},["2215"] = {line = 139, file = "pool.ts"},["2216"] = {line = 140, file = "pool.ts"},["2217"] = {line = 141, file = "pool.ts"},["2218"] = {line = 141, file = "pool.ts"},["2219"] = {line = 141, file = "pool.ts"},["2220"] = {line = 141, file = "pool.ts"},["2222"] = {line = 141, file = "pool.ts"},["2223"] = {line = 142, file = "pool.ts"},["2224"] = {line = 142, file = "pool.ts"},["2227"] = {line = 144, file = "pool.ts"},["2228"] = {line = 144, file = "pool.ts"},["2230"] = {line = 138, file = "pool.ts"},["2231"] = {line = 148, file = "pool.ts"},["2232"] = {line = 149, file = "pool.ts"},["2233"] = {line = 150, file = "pool.ts"},["2236"] = {line = 151, file = "pool.ts"},["2237"] = {line = 152, file = "pool.ts"},["2238"] = {line = 148, file = "pool.ts"},["2239"] = {line = 155, file = "pool.ts"},["2240"] = {line = 156, file = "pool.ts"},["2241"] = {line = 157, file = "pool.ts"},["2242"] = {line = 158, file = "pool.ts"},["2245"] = {line = 161, file = "pool.ts"},["2246"] = {line = 155, file = "pool.ts"},["2247"] = {line = 164, file = "pool.ts"},["2248"] = {line = 165, file = "pool.ts"},["2249"] = {line = 166, file = "pool.ts"},["2250"] = {line = 166, file = "pool.ts"},["2252"] = {line = 167, file = "pool.ts"},["2253"] = {line = 168, file = "pool.ts"},["2254"] = {line = 164, file = "pool.ts"},["2271"] = {line = 2, file = "layout.ts"},["2272"] = {line = 2, file = "layout.ts"},["2273"] = {line = 4, file = "layout.ts"},["2274"] = {line = 4, file = "layout.ts"},["2275"] = {line = 4, file = "layout.ts"},["2276"] = {line = 5, file = "layout.ts"},["2277"] = {line = 5, file = "layout.ts"},["2278"] = {line = 6, file = "layout.ts"},["2279"] = {line = 6, file = "layout.ts"},["2280"] = {line = 6, file = "layout.ts"},["2281"] = {line = 6, file = "layout.ts"},["2282"] = {line = 6, file = "layout.ts"},["2283"] = {line = 6, file = "layout.ts"},["2284"] = {line = 6, file = "layout.ts"},["2285"] = {line = 8, file = "layout.ts"},["2286"] = {line = 9, file = "layout.ts"},["2287"] = {line = 11, file = "layout.ts"},["2288"] = {line = 13, file = "layout.ts"},["2289"] = {line = 14, file = "layout.ts"},["2290"] = {line = 16, file = "layout.ts"},["2291"] = {line = 18, file = "layout.ts"},["2292"] = {line = 19, file = "layout.ts"},["2293"] = {line = 19, file = "layout.ts"},["2294"] = {line = 19, file = "layout.ts"},["2295"] = {line = 19, file = "layout.ts"},["2296"] = {line = 19, file = "layout.ts"},["2297"] = {line = 20, file = "layout.ts"},["2298"] = {line = 20, file = "layout.ts"},["2299"] = {line = 20, file = "layout.ts"},["2300"] = {line = 20, file = "layout.ts"},["2301"] = {line = 21, file = "layout.ts"},["2302"] = {line = 21, file = "layout.ts"},["2303"] = {line = 18, file = "layout.ts"},["2304"] = {line = 25, file = "layout.ts"},["2305"] = {line = 26, file = "layout.ts"},["2306"] = {line = 26, file = "layout.ts"},["2307"] = {line = 26, file = "layout.ts"},["2310"] = {line = 30, file = "layout.ts"},["2311"] = {line = 30, file = "layout.ts"},["2312"] = {line = 30, file = "layout.ts"},["2313"] = {line = 30, file = "layout.ts"},["2316"] = {line = 28, file = "layout.ts"},["2323"] = {line = 25, file = "layout.ts"},["2324"] = {line = 36, file = "layout.ts"},["2327"] = {line = 40, file = "layout.ts"},["2328"] = {line = 40, file = "layout.ts"},["2329"] = {line = 40, file = "layout.ts"},["2330"] = {line = 40, file = "layout.ts"},["2333"] = {line = 38, file = "layout.ts"},["2339"] = {line = 36, file = "layout.ts"},["2340"] = {line = 45, file = "layout.ts"},["2341"] = {line = 46, file = "layout.ts"},["2342"] = {line = 47, file = "layout.ts"},["2347"] = {line = 53, file = "layout.ts"},["2348"] = {line = 53, file = "layout.ts"},["2349"] = {line = 53, file = "layout.ts"},["2350"] = {line = 53, file = "layout.ts"},["2351"] = {line = 54, file = "layout.ts"},["2354"] = {line = 51, file = "layout.ts"},["2360"] = {line = 45, file = "layout.ts"},["2361"] = {line = 59, file = "layout.ts"},["2362"] = {line = 60, file = "layout.ts"},["2363"] = {line = 61, file = "layout.ts"},["2364"] = {line = 61, file = "layout.ts"},["2366"] = {line = 62, file = "layout.ts"},["2367"] = {line = 63, file = "layout.ts"},["2368"] = {line = 64, file = "layout.ts"},["2369"] = {line = 64, file = "layout.ts"},["2370"] = {line = 64, file = "layout.ts"},["2371"] = {line = 64, file = "layout.ts"},["2373"] = {line = 64, file = "layout.ts"},["2374"] = {line = 65, file = "layout.ts"},["2375"] = {line = 65, file = "layout.ts"},["2378"] = {line = 67, file = "layout.ts"},["2379"] = {line = 67, file = "layout.ts"},["2381"] = {line = 59, file = "layout.ts"},["2382"] = {line = 72, file = "layout.ts"},["2383"] = {line = 73, file = "layout.ts"},["2384"] = {line = 74, file = "layout.ts"},["2385"] = {line = 75, file = "layout.ts"},["2386"] = {line = 75, file = "layout.ts"},["2388"] = {line = 76, file = "layout.ts"},["2389"] = {line = 77, file = "layout.ts"},["2391"] = {line = 77, file = "layout.ts"},["2395"] = {line = 78, file = "layout.ts"},["2396"] = {line = 79, file = "layout.ts"},["2397"] = {line = 80, file = "layout.ts"},["2399"] = {line = 81, file = "layout.ts"},["2400"] = {line = 81, file = "layout.ts"},["2401"] = {line = 81, file = "layout.ts"},["2402"] = {line = 81, file = "layout.ts"},["2404"] = {line = 81, file = "layout.ts"},["2405"] = {line = 82, file = "layout.ts"},["2406"] = {line = 82, file = "layout.ts"},["2408"] = {line = 83, file = "layout.ts"},["2409"] = {line = 84, file = "layout.ts"},["2410"] = {line = 84, file = "layout.ts"},["2412"] = {line = 85, file = "layout.ts"},["2417"] = {line = 87, file = "layout.ts"},["2418"] = {line = 88, file = "layout.ts"},["2419"] = {line = 89, file = "layout.ts"},["2420"] = {line = 90, file = "layout.ts"},["2421"] = {line = 91, file = "layout.ts"},["2422"] = {line = 92, file = "layout.ts"},["2423"] = {line = 93, file = "layout.ts"},["2424"] = {line = 94, file = "layout.ts"},["2425"] = {line = 94, file = "layout.ts"},["2426"] = {line = 94, file = "layout.ts"},["2427"] = {line = 94, file = "layout.ts"},["2428"] = {line = 95, file = "layout.ts"},["2429"] = {line = 95, file = "layout.ts"},["2430"] = {line = 95, file = "layout.ts"},["2432"] = {line = 95, file = "layout.ts"},["2433"] = {line = 96, file = "layout.ts"},["2434"] = {line = 97, file = "layout.ts"},["2435"] = {line = 98, file = "layout.ts"},["2436"] = {line = 99, file = "layout.ts"},["2437"] = {line = 100, file = "layout.ts"},["2438"] = {line = 101, file = "layout.ts"},["2439"] = {line = 102, file = "layout.ts"},["2440"] = {line = 103, file = "layout.ts"},["2441"] = {line = 104, file = "layout.ts"},["2442"] = {line = 105, file = "layout.ts"},["2443"] = {line = 106, file = "layout.ts"},["2444"] = {line = 107, file = "layout.ts"},["2445"] = {line = 107, file = "layout.ts"},["2448"] = {line = 109, file = "layout.ts"},["2449"] = {line = 110, file = "layout.ts"},["2450"] = {line = 110, file = "layout.ts"},["2451"] = {line = 110, file = "layout.ts"},["2454"] = {line = 111, file = "layout.ts"},["2455"] = {line = 111, file = "layout.ts"},["2457"] = {line = 112, file = "layout.ts"},["2458"] = {line = 113, file = "layout.ts"},["2459"] = {line = 114, file = "layout.ts"},["2460"] = {line = 115, file = "layout.ts"},["2461"] = {line = 115, file = "layout.ts"},["2463"] = {line = 116, file = "layout.ts"},["2466"] = {line = 118, file = "layout.ts"},["2467"] = {line = 118, file = "layout.ts"},["2468"] = {line = 118, file = "layout.ts"},["2469"] = {line = 118, file = "layout.ts"},["2470"] = {line = 119, file = "layout.ts"},["2473"] = {line = 127, file = "layout.ts"},["2474"] = {line = 127, file = "layout.ts"},["2475"] = {line = 127, file = "layout.ts"},["2476"] = {line = 127, file = "layout.ts"},["2479"] = {line = 122, file = "layout.ts"},["2480"] = {line = 123, file = "layout.ts"},["2481"] = {line = 123, file = "layout.ts"},["2482"] = {line = 123, file = "layout.ts"},["2485"] = {line = 124, file = "layout.ts"},["2486"] = {line = 124, file = "layout.ts"},["2488"] = {line = 125, file = "layout.ts"},["2489"] = {line = 125, file = "layout.ts"},["2490"] = {line = 125, file = "layout.ts"},["2491"] = {line = 125, file = "layout.ts"},["2499"] = {line = 72, file = "layout.ts"},["2500"] = {line = 134, file = "layout.ts"},["2501"] = {line = 135, file = "layout.ts"},["2502"] = {line = 136, file = "layout.ts"},["2503"] = {line = 137, file = "layout.ts"},["2504"] = {line = 138, file = "layout.ts"},["2505"] = {line = 139, file = "layout.ts"},["2506"] = {line = 140, file = "layout.ts"},["2509"] = {line = 141, file = "layout.ts"},["2510"] = {line = 142, file = "layout.ts"},["2513"] = {line = 143, file = "layout.ts"},["2515"] = {line = 144, file = "layout.ts"},["2516"] = {line = 144, file = "layout.ts"},["2517"] = {line = 144, file = "layout.ts"},["2518"] = {line = 144, file = "layout.ts"},["2520"] = {line = 144, file = "layout.ts"},["2521"] = {line = 145, file = "layout.ts"},["2522"] = {line = 145, file = "layout.ts"},["2524"] = {line = 146, file = "layout.ts"},["2525"] = {line = 147, file = "layout.ts"},["2526"] = {line = 148, file = "layout.ts"},["2527"] = {line = 149, file = "layout.ts"},["2528"] = {line = 149, file = "layout.ts"},["2533"] = {line = 134, file = "layout.ts"},["2534"] = {line = 153, file = "layout.ts"},["2535"] = {line = 154, file = "layout.ts"},["2536"] = {line = 155, file = "layout.ts"},["2537"] = {line = 156, file = "layout.ts"},["2538"] = {line = 157, file = "layout.ts"},["2540"] = {line = 159, file = "layout.ts"},["2542"] = {line = 160, file = "layout.ts"},["2543"] = {line = 161, file = "layout.ts"},["2544"] = {line = 162, file = "layout.ts"},["2545"] = {line = 162, file = "layout.ts"},["2547"] = {line = 163, file = "layout.ts"},["2548"] = {line = 164, file = "layout.ts"},["2549"] = {line = 165, file = "layout.ts"},["2550"] = {line = 165, file = "layout.ts"},["2552"] = {line = 166, file = "layout.ts"},["2553"] = {line = 167, file = "layout.ts"},["2554"] = {line = 168, file = "layout.ts"},["2555"] = {line = 169, file = "layout.ts"},["2556"] = {line = 169, file = "layout.ts"},["2559"] = {line = 171, file = "layout.ts"},["2560"] = {line = 172, file = "layout.ts"},["2561"] = {line = 173, file = "layout.ts"},["2562"] = {line = 174, file = "layout.ts"},["2563"] = {line = 175, file = "layout.ts"},["2564"] = {line = 176, file = "layout.ts"},["2565"] = {line = 176, file = "layout.ts"},["2567"] = {line = 177, file = "layout.ts"},["2571"] = {line = 153, file = "layout.ts"},["2581"] = {line = 2, file = "live.ts"},["2582"] = {line = 2, file = "live.ts"},["2583"] = {line = 3, file = "live.ts"},["2584"] = {line = 3, file = "live.ts"},["2585"] = {line = 5, file = "live.ts"},["2586"] = {line = 5, file = "live.ts"},["2587"] = {line = 5, file = "live.ts"},["2588"] = {line = 8, file = "live.ts"},["2589"] = {line = 9, file = "live.ts"},["2590"] = {line = 10, file = "live.ts"},["2591"] = {line = 11, file = "live.ts"},["2592"] = {line = 11, file = "live.ts"},["2593"] = {line = 11, file = "live.ts"},["2594"] = {line = 11, file = "live.ts"},["2595"] = {line = 13, file = "live.ts"},["2596"] = {line = 14, file = "live.ts"},["2597"] = {line = 13, file = "live.ts"},["2598"] = {line = 17, file = "live.ts"},["2599"] = {line = 18, file = "live.ts"},["2600"] = {line = 19, file = "live.ts"},["2601"] = {line = 19, file = "live.ts"},["2602"] = {line = 19, file = "live.ts"},["2604"] = {line = 19, file = "live.ts"},["2606"] = {line = 19, file = "live.ts"},["2607"] = {line = 17, file = "live.ts"},["2608"] = {line = 22, file = "live.ts"},["2609"] = {line = 23, file = "live.ts"},["2610"] = {line = 23, file = "live.ts"},["2612"] = {line = 23, file = "live.ts"},["2614"] = {line = 23, file = "live.ts"},["2615"] = {line = 24, file = "live.ts"},["2616"] = {line = 22, file = "live.ts"},["2617"] = {line = 27, file = "live.ts"},["2618"] = {line = 28, file = "live.ts"},["2619"] = {line = 29, file = "live.ts"},["2620"] = {line = 29, file = "live.ts"},["2621"] = {line = 29, file = "live.ts"},["2622"] = {line = 29, file = "live.ts"},["2623"] = {line = 29, file = "live.ts"},["2625"] = {line = 30, file = "live.ts"},["2626"] = {line = 27, file = "live.ts"},["2627"] = {line = 33, file = "live.ts"},["2628"] = {line = 34, file = "live.ts"},["2629"] = {line = 34, file = "live.ts"},["2631"] = {line = 34, file = "live.ts"},["2633"] = {line = 34, file = "live.ts"},["2634"] = {line = 35, file = "live.ts"},["2635"] = {line = 33, file = "live.ts"},["2636"] = {line = 38, file = "live.ts"},["2637"] = {line = 39, file = "live.ts"},["2638"] = {line = 40, file = "live.ts"},["2639"] = {line = 40, file = "live.ts"},["2641"] = {line = 41, file = "live.ts"},["2642"] = {line = 42, file = "live.ts"},["2643"] = {line = 42, file = "live.ts"},["2644"] = {line = 42, file = "live.ts"},["2648"] = {line = 43, file = "live.ts"},["2649"] = {line = 44, file = "live.ts"},["2650"] = {line = 45, file = "live.ts"},["2651"] = {line = 46, file = "live.ts"},["2652"] = {line = 43, file = "live.ts"},["2653"] = {line = 38, file = "live.ts"},["2654"] = {line = 51, file = "live.ts"},["2655"] = {line = 53, file = "live.ts"},["2656"] = {line = 54, file = "live.ts"},["2657"] = {line = 54, file = "live.ts"},["2659"] = {line = 55, file = "live.ts"},["2660"] = {line = 55, file = "live.ts"},["2662"] = {line = 56, file = "live.ts"},["2663"] = {line = 56, file = "live.ts"},["2664"] = {line = 56, file = "live.ts"},["2665"] = {line = 56, file = "live.ts"},["2666"] = {line = 53, file = "live.ts"},["2667"] = {line = 59, file = "live.ts"},["2668"] = {line = 60, file = "live.ts"},["2669"] = {line = 61, file = "live.ts"},["2670"] = {line = 62, file = "live.ts"},["2672"] = {line = 63, file = "live.ts"},["2673"] = {line = 64, file = "live.ts"},["2674"] = {line = 64, file = "live.ts"},["2676"] = {line = 65, file = "live.ts"},["2677"] = {line = 65, file = "live.ts"},["2679"] = {line = 66, file = "live.ts"},["2680"] = {line = 66, file = "live.ts"},["2681"] = {line = 66, file = "live.ts"},["2682"] = {line = 66, file = "live.ts"},["2683"] = {line = 66, file = "live.ts"},["2684"] = {line = 67, file = "live.ts"},["2685"] = {line = 68, file = "live.ts"},["2686"] = {line = 68, file = "live.ts"},["2687"] = {line = 68, file = "live.ts"},["2688"] = {line = 68, file = "live.ts"},["2689"] = {line = 70, file = "live.ts"},["2694"] = {line = 73, file = "live.ts"},["2695"] = {line = 59, file = "live.ts"},["2705"] = {line = 3, file = "patch.ts"},["2706"] = {line = 3, file = "patch.ts"},["2707"] = {line = 3, file = "patch.ts"},["2708"] = {line = 3, file = "patch.ts"},["2709"] = {line = 4, file = "patch.ts"},["2710"] = {line = 4, file = "patch.ts"},["2711"] = {line = 4, file = "patch.ts"},["2712"] = {line = 6, file = "patch.ts"},["2713"] = {line = 6, file = "patch.ts"},["2714"] = {line = 6, file = "patch.ts"},["2715"] = {line = 6, file = "patch.ts"},["2716"] = {line = 7, file = "patch.ts"},["2717"] = {line = 7, file = "patch.ts"},["2718"] = {line = 10, file = "patch.ts"},["2719"] = {line = 12, file = "patch.ts"},["2720"] = {line = 13, file = "patch.ts"},["2721"] = {line = 14, file = "patch.ts"},["2722"] = {line = 15, file = "patch.ts"},["2724"] = {line = 16, file = "patch.ts"},["2725"] = {line = 17, file = "patch.ts"},["2726"] = {line = 17, file = "patch.ts"},["2728"] = {line = 18, file = "patch.ts"},["2729"] = {line = 19, file = "patch.ts"},["2730"] = {line = 19, file = "patch.ts"},["2732"] = {line = 20, file = "patch.ts"},["2733"] = {line = 20, file = "patch.ts"},["2734"] = {line = 21, file = "patch.ts"},["2735"] = {line = 21, file = "patch.ts"},["2737"] = {line = 22, file = "patch.ts"},["2738"] = {line = 22, file = "patch.ts"},["2739"] = {line = 22, file = "patch.ts"},["2740"] = {line = 22, file = "patch.ts"},["2741"] = {line = 23, file = "patch.ts"},["2742"] = {line = 23, file = "patch.ts"},["2744"] = {line = 24, file = "patch.ts"},["2745"] = {line = 24, file = "patch.ts"},["2750"] = {line = 26, file = "patch.ts"},["2751"] = {line = 26, file = "patch.ts"},["2753"] = {line = 27, file = "patch.ts"},["2754"] = {line = 12, file = "patch.ts"},["2755"] = {line = 31, file = "patch.ts"},["2756"] = {line = 32, file = "patch.ts"},["2757"] = {line = 33, file = "patch.ts"},["2758"] = {line = 34, file = "patch.ts"},["2759"] = {line = 35, file = "patch.ts"},["2761"] = {line = 36, file = "patch.ts"},["2762"] = {line = 36, file = "patch.ts"},["2764"] = {line = 37, file = "patch.ts"},["2765"] = {line = 38, file = "patch.ts"},["2766"] = {line = 38, file = "patch.ts"},["2772"] = {line = 41, file = "patch.ts"},["2773"] = {line = 31, file = "patch.ts"},["2774"] = {line = 44, file = "patch.ts"},["2775"] = {line = 45, file = "patch.ts"},["2776"] = {line = 45, file = "patch.ts"},["2777"] = {line = 45, file = "patch.ts"},["2779"] = {line = 45, file = "patch.ts"},["2780"] = {line = 46, file = "patch.ts"},["2781"] = {line = 46, file = "patch.ts"},["2783"] = {line = 47, file = "patch.ts"},["2784"] = {line = 47, file = "patch.ts"},["2786"] = {line = 48, file = "patch.ts"},["2787"] = {line = 49, file = "patch.ts"},["2788"] = {line = 44, file = "patch.ts"},["2789"] = {line = 52, file = "patch.ts"},["2790"] = {line = 53, file = "patch.ts"},["2791"] = {line = 54, file = "patch.ts"},["2793"] = {line = 55, file = "patch.ts"},["2794"] = {line = 55, file = "patch.ts"},["2795"] = {line = 56, file = "patch.ts"},["2796"] = {line = 57, file = "patch.ts"},["2797"] = {line = 57, file = "patch.ts"},["2798"] = {line = 57, file = "patch.ts"},["2800"] = {line = 57, file = "patch.ts"},["2802"] = {line = 57, file = "patch.ts"},["2803"] = {line = 58, file = "patch.ts"},["2804"] = {line = 58, file = "patch.ts"},["2806"] = {line = 55, file = "patch.ts"},["2809"] = {line = 60, file = "patch.ts"},["2810"] = {line = 52, file = "patch.ts"},["2811"] = {line = 63, file = "patch.ts"},["2812"] = {line = 64, file = "patch.ts"},["2813"] = {line = 64, file = "patch.ts"},["2814"] = {line = 64, file = "patch.ts"},["2815"] = {line = 64, file = "patch.ts"},["2816"] = {line = 64, file = "patch.ts"},["2817"] = {line = 65, file = "patch.ts"},["2818"] = {line = 65, file = "patch.ts"},["2819"] = {line = 65, file = "patch.ts"},["2820"] = {line = 65, file = "patch.ts"},["2821"] = {line = 65, file = "patch.ts"},["2822"] = {line = 67, file = "patch.ts"},["2823"] = {line = 67, file = "patch.ts"},["2824"] = {line = 67, file = "patch.ts"},["2825"] = {line = 67, file = "patch.ts"},["2826"] = {line = 67, file = "patch.ts"},["2827"] = {line = 67, file = "patch.ts"},["2828"] = {line = 67, file = "patch.ts"},["2829"] = {line = 63, file = "patch.ts"},["2830"] = {line = 70, file = "patch.ts"},["2831"] = {line = 71, file = "patch.ts"},["2832"] = {line = 71, file = "patch.ts"},["2834"] = {line = 72, file = "patch.ts"},["2835"] = {line = 72, file = "patch.ts"},["2836"] = {line = 72, file = "patch.ts"},["2837"] = {line = 73, file = "patch.ts"},["2838"] = {line = 73, file = "patch.ts"},["2839"] = {line = 73, file = "patch.ts"},["2840"] = {line = 74, file = "patch.ts"},["2841"] = {line = 74, file = "patch.ts"},["2843"] = {line = 75, file = "patch.ts"},["2844"] = {line = 75, file = "patch.ts"},["2845"] = {line = 75, file = "patch.ts"},["2846"] = {line = 75, file = "patch.ts"},["2847"] = {line = 70, file = "patch.ts"},["2848"] = {line = 79, file = "patch.ts"},["2849"] = {line = 80, file = "patch.ts"},["2850"] = {line = 81, file = "patch.ts"},["2851"] = {line = 82, file = "patch.ts"},["2852"] = {line = 82, file = "patch.ts"},["2853"] = {line = 82, file = "patch.ts"},["2854"] = {line = 82, file = "patch.ts"},["2855"] = {line = 82, file = "patch.ts"},["2856"] = {line = 82, file = "patch.ts"},["2857"] = {line = 83, file = "patch.ts"},["2858"] = {line = 83, file = "patch.ts"},["2861"] = {line = 85, file = "patch.ts"},["2862"] = {line = 79, file = "patch.ts"},["2863"] = {line = 88, file = "patch.ts"},["2864"] = {line = 89, file = "patch.ts"},["2865"] = {line = 90, file = "patch.ts"},["2866"] = {line = 90, file = "patch.ts"},["2867"] = {line = 90, file = "patch.ts"},["2868"] = {line = 90, file = "patch.ts"},["2869"] = {line = 90, file = "patch.ts"},["2870"] = {line = 90, file = "patch.ts"},["2872"] = {line = 90, file = "patch.ts"},["2874"] = {line = 90, file = "patch.ts"},["2875"] = {line = 91, file = "patch.ts"},["2876"] = {line = 92, file = "patch.ts"},["2877"] = {line = 92, file = "patch.ts"},["2878"] = {line = 92, file = "patch.ts"},["2879"] = {line = 88, file = "patch.ts"},["2880"] = {line = 96, file = "patch.ts"},["2881"] = {line = 97, file = "patch.ts"},["2882"] = {line = 98, file = "patch.ts"},["2883"] = {line = 99, file = "patch.ts"},["2884"] = {line = 100, file = "patch.ts"},["2885"] = {line = 101, file = "patch.ts"},["2886"] = {line = 101, file = "patch.ts"},["2888"] = {line = 103, file = "patch.ts"},["2889"] = {line = 104, file = "patch.ts"},["2890"] = {line = 105, file = "patch.ts"},["2891"] = {line = 106, file = "patch.ts"},["2892"] = {line = 106, file = "patch.ts"},["2893"] = {line = 106, file = "patch.ts"},["2894"] = {line = 106, file = "patch.ts"},["2895"] = {line = 106, file = "patch.ts"},["2896"] = {line = 106, file = "patch.ts"},["2897"] = {line = 106, file = "patch.ts"},["2899"] = {line = 106, file = "patch.ts"},["2900"] = {line = 106, file = "patch.ts"},["2901"] = {line = 106, file = "patch.ts"},["2902"] = {line = 106, file = "patch.ts"},["2903"] = {line = 106, file = "patch.ts"},["2907"] = {line = 109, file = "patch.ts"},["2908"] = {line = 110, file = "patch.ts"},["2909"] = {line = 110, file = "patch.ts"},["2911"] = {line = 111, file = "patch.ts"},["2912"] = {line = 112, file = "patch.ts"},["2913"] = {line = 113, file = "patch.ts"},["2916"] = {line = 114, file = "patch.ts"},["2917"] = {line = 115, file = "patch.ts"},["2920"] = {line = 116, file = "patch.ts"},["2921"] = {line = 117, file = "patch.ts"},["2922"] = {line = 118, file = "patch.ts"},["2923"] = {line = 119, file = "patch.ts"},["2924"] = {line = 119, file = "patch.ts"},["2925"] = {line = 119, file = "patch.ts"},["2927"] = {line = 119, file = "patch.ts"},["2929"] = {line = 119, file = "patch.ts"},["2930"] = {line = 120, file = "patch.ts"},["2933"] = {line = 121, file = "patch.ts"},["2935"] = {line = 123, file = "patch.ts"},["2936"] = {line = 124, file = "patch.ts"},["2937"] = {line = 124, file = "patch.ts"},["2940"] = {line = 127, file = "patch.ts"},["2941"] = {line = 127, file = "patch.ts"},["2942"] = {line = 127, file = "patch.ts"},["2943"] = {line = 127, file = "patch.ts"},["2944"] = {line = 127, file = "patch.ts"},["2945"] = {line = 127, file = "patch.ts"},["2946"] = {line = 127, file = "patch.ts"},["2947"] = {line = 127, file = "patch.ts"},["2948"] = {line = 103, file = "patch.ts"},["2949"] = {line = 130, file = "patch.ts"},["2950"] = {line = 130, file = "patch.ts"},["2951"] = {line = 130, file = "patch.ts"},["2952"] = {line = 130, file = "patch.ts"},["2953"] = {line = 131, file = "patch.ts"},["2954"] = {line = 131, file = "patch.ts"},["2955"] = {line = 131, file = "patch.ts"},["2958"] = {line = 132, file = "patch.ts"},["2959"] = {line = 132, file = "patch.ts"},["2960"] = {line = 132, file = "patch.ts"},["2961"] = {line = 132, file = "patch.ts"},["2962"] = {line = 133, file = "patch.ts"},["2963"] = {line = 133, file = "patch.ts"},["2964"] = {line = 133, file = "patch.ts"},["2965"] = {line = 133, file = "patch.ts"},["2966"] = {line = 134, file = "patch.ts"},["2967"] = {line = 96, file = "patch.ts"},["2977"] = {line = 5, file = "window.ts"},["2978"] = {line = 7, file = "window.ts"},["2979"] = {line = 8, file = "window.ts"},["2980"] = {line = 10, file = "window.ts"},["2981"] = {line = 11, file = "window.ts"},["2982"] = {line = 11, file = "window.ts"},["2983"] = {line = 11, file = "window.ts"},["2985"] = {line = 11, file = "window.ts"},["2986"] = {line = 12, file = "window.ts"},["2987"] = {line = 10, file = "window.ts"},["2988"] = {line = 15, file = "window.ts"},["2989"] = {line = 16, file = "window.ts"},["2990"] = {line = 17, file = "window.ts"},["2991"] = {line = 17, file = "window.ts"},["2992"] = {line = 17, file = "window.ts"},["2994"] = {line = 17, file = "window.ts"},["2996"] = {line = 17, file = "window.ts"},["2997"] = {line = 15, file = "window.ts"},["2998"] = {line = 20, file = "window.ts"},["2999"] = {line = 21, file = "window.ts"},["3000"] = {line = 22, file = "window.ts"},["3001"] = {line = 22, file = "window.ts"},["3003"] = {line = 23, file = "window.ts"},["3004"] = {line = 20, file = "window.ts"},["3005"] = {line = 27, file = "window.ts"},["3006"] = {line = 28, file = "window.ts"},["3007"] = {line = 28, file = "window.ts"},["3008"] = {line = 28, file = "window.ts"},["3009"] = {line = 27, file = "window.ts"},["3010"] = {line = 31, file = "window.ts"},["3011"] = {line = 32, file = "window.ts"},["3012"] = {line = 33, file = "window.ts"},["3013"] = {line = 35, file = "window.ts"},["3014"] = {line = 36, file = "window.ts"},["3015"] = {line = 37, file = "window.ts"},["3016"] = {line = 38, file = "window.ts"},["3017"] = {line = 39, file = "window.ts"},["3018"] = {line = 40, file = "window.ts"},["3019"] = {line = 41, file = "window.ts"},["3020"] = {line = 43, file = "window.ts"},["3021"] = {line = 44, file = "window.ts"},["3022"] = {line = 45, file = "window.ts"},["3023"] = {line = 46, file = "window.ts"},["3024"] = {line = 47, file = "window.ts"},["3025"] = {line = 48, file = "window.ts"},["3026"] = {line = 50, file = "window.ts"},["3027"] = {line = 51, file = "window.ts"},["3028"] = {line = 52, file = "window.ts"},["3029"] = {line = 53, file = "window.ts"},["3030"] = {line = 54, file = "window.ts"},["3031"] = {line = 56, file = "window.ts"},["3032"] = {line = 57, file = "window.ts"},["3033"] = {line = 58, file = "window.ts"},["3034"] = {line = 60, file = "window.ts"},["3035"] = {line = 61, file = "window.ts"},["3036"] = {line = 62, file = "window.ts"},["3037"] = {line = 63, file = "window.ts"},["3038"] = {line = 64, file = "window.ts"},["3039"] = {line = 65, file = "window.ts"},["3040"] = {line = 31, file = "window.ts"},["3041"] = {line = 68, file = "window.ts"},["3042"] = {line = 69, file = "window.ts"},["3043"] = {line = 70, file = "window.ts"},["3044"] = {line = 71, file = "window.ts"},["3045"] = {line = 71, file = "window.ts"},["3046"] = {line = 71, file = "window.ts"},["3047"] = {line = 72, file = "window.ts"},["3048"] = {line = 73, file = "window.ts"},["3049"] = {line = 71, file = "window.ts"},["3050"] = {line = 71, file = "window.ts"},["3051"] = {line = 68, file = "window.ts"},["3052"] = {line = 77, file = "window.ts"},["3053"] = {line = 78, file = "window.ts"},["3054"] = {line = 79, file = "window.ts"},["3055"] = {line = 80, file = "window.ts"},["3056"] = {line = 81, file = "window.ts"},["3057"] = {line = 82, file = "window.ts"},["3058"] = {line = 83, file = "window.ts"},["3059"] = {line = 84, file = "window.ts"},["3060"] = {line = 85, file = "window.ts"},["3061"] = {line = 77, file = "window.ts"},["3062"] = {line = 88, file = "window.ts"},["3063"] = {line = 89, file = "window.ts"},["3064"] = {line = 90, file = "window.ts"},["3065"] = {line = 91, file = "window.ts"},["3066"] = {line = 92, file = "window.ts"},["3067"] = {line = 93, file = "window.ts"},["3068"] = {line = 94, file = "window.ts"},["3069"] = {line = 95, file = "window.ts"},["3070"] = {line = 96, file = "window.ts"},["3071"] = {line = 97, file = "window.ts"},["3072"] = {line = 98, file = "window.ts"},["3073"] = {line = 99, file = "window.ts"},["3074"] = {line = 100, file = "window.ts"},["3075"] = {line = 88, file = "window.ts"},["3076"] = {line = 103, file = "window.ts"},["3077"] = {line = 104, file = "window.ts"},["3078"] = {line = 105, file = "window.ts"},["3079"] = {line = 106, file = "window.ts"},["3080"] = {line = 107, file = "window.ts"},["3081"] = {line = 108, file = "window.ts"},["3082"] = {line = 109, file = "window.ts"},["3083"] = {line = 110, file = "window.ts"},["3084"] = {line = 111, file = "window.ts"},["3085"] = {line = 112, file = "window.ts"},["3086"] = {line = 113, file = "window.ts"},["3087"] = {line = 114, file = "window.ts"},["3088"] = {line = 115, file = "window.ts"},["3089"] = {line = 116, file = "window.ts"},["3090"] = {line = 117, file = "window.ts"},["3091"] = {line = 103, file = "window.ts"},["3092"] = {line = 120, file = "window.ts"},["3093"] = {line = 121, file = "window.ts"},["3094"] = {line = 122, file = "window.ts"},["3095"] = {line = 123, file = "window.ts"},["3096"] = {line = 124, file = "window.ts"},["3097"] = {line = 125, file = "window.ts"},["3098"] = {line = 126, file = "window.ts"},["3099"] = {line = 127, file = "window.ts"},["3100"] = {line = 128, file = "window.ts"},["3101"] = {line = 129, file = "window.ts"},["3102"] = {line = 130, file = "window.ts"},["3103"] = {line = 131, file = "window.ts"},["3104"] = {line = 132, file = "window.ts"},["3105"] = {line = 133, file = "window.ts"},["3106"] = {line = 134, file = "window.ts"},["3107"] = {line = 135, file = "window.ts"},["3108"] = {line = 136, file = "window.ts"},["3109"] = {line = 137, file = "window.ts"},["3110"] = {line = 138, file = "window.ts"},["3111"] = {line = 139, file = "window.ts"},["3112"] = {line = 140, file = "window.ts"},["3113"] = {line = 120, file = "window.ts"},["3114"] = {line = 143, file = "window.ts"},["3115"] = {line = 144, file = "window.ts"},["3116"] = {line = 144, file = "window.ts"},["3118"] = {line = 143, file = "window.ts"},["3119"] = {line = 147, file = "window.ts"},["3120"] = {line = 148, file = "window.ts"},["3121"] = {line = 147, file = "window.ts"},["3122"] = {line = 151, file = "window.ts"},["3123"] = {line = 152, file = "window.ts"},["3124"] = {line = 153, file = "window.ts"},["3125"] = {line = 151, file = "window.ts"},["3136"] = {line = 4, file = "preset-picker.ts"},["3137"] = {line = 4, file = "preset-picker.ts"},["3138"] = {line = 4, file = "preset-picker.ts"},["3139"] = {line = 4, file = "preset-picker.ts"},["3140"] = {line = 4, file = "preset-picker.ts"},["3141"] = {line = 4, file = "preset-picker.ts"},["3142"] = {line = 4, file = "preset-picker.ts"},["3143"] = {line = 4, file = "preset-picker.ts"},["3144"] = {line = 4, file = "preset-picker.ts"},["3145"] = {line = 4, file = "preset-picker.ts"},["3146"] = {line = 6, file = "preset-picker.ts"},["3147"] = {line = 7, file = "preset-picker.ts"},["3148"] = {line = 8, file = "preset-picker.ts"},["3149"] = {line = 9, file = "preset-picker.ts"},["3150"] = {line = 10, file = "preset-picker.ts"},["3151"] = {line = 11, file = "preset-picker.ts"},["3152"] = {line = 12, file = "preset-picker.ts"},["3153"] = {line = 13, file = "preset-picker.ts"},["3154"] = {line = 18, file = "preset-picker.ts"},["3155"] = {line = 19, file = "preset-picker.ts"},["3156"] = {line = 20, file = "preset-picker.ts"},["3157"] = {line = 21, file = "preset-picker.ts"},["3158"] = {line = 21, file = "preset-picker.ts"},["3160"] = {line = 22, file = "preset-picker.ts"},["3161"] = {line = 23, file = "preset-picker.ts"},["3162"] = {line = 24, file = "preset-picker.ts"},["3163"] = {line = 25, file = "preset-picker.ts"},["3164"] = {line = 25, file = "preset-picker.ts"},["3165"] = {line = 25, file = "preset-picker.ts"},["3167"] = {line = 25, file = "preset-picker.ts"},["3169"] = {line = 25, file = "preset-picker.ts"},["3170"] = {line = 26, file = "preset-picker.ts"},["3171"] = {line = 27, file = "preset-picker.ts"},["3172"] = {line = 27, file = "preset-picker.ts"},["3173"] = {line = 27, file = "preset-picker.ts"},["3174"] = {line = 27, file = "preset-picker.ts"},["3175"] = {line = 27, file = "preset-picker.ts"},["3176"] = {line = 27, file = "preset-picker.ts"},["3177"] = {line = 27, file = "preset-picker.ts"},["3179"] = {line = 27, file = "preset-picker.ts"},["3180"] = {line = 27, file = "preset-picker.ts"},["3181"] = {line = 27, file = "preset-picker.ts"},["3182"] = {line = 27, file = "preset-picker.ts"},["3183"] = {line = 27, file = "preset-picker.ts"},["3184"] = {line = 27, file = "preset-picker.ts"},["3187"] = {line = 29, file = "preset-picker.ts"},["3188"] = {line = 29, file = "preset-picker.ts"},["3189"] = {line = 29, file = "preset-picker.ts"},["3190"] = {line = 29, file = "preset-picker.ts"},["3191"] = {line = 30, file = "preset-picker.ts"},["3192"] = {line = 31, file = "preset-picker.ts"},["3193"] = {line = 31, file = "preset-picker.ts"},["3194"] = {line = 31, file = "preset-picker.ts"},["3195"] = {line = 31, file = "preset-picker.ts"},["3196"] = {line = 31, file = "preset-picker.ts"},["3198"] = {line = 31, file = "preset-picker.ts"},["3199"] = {line = 31, file = "preset-picker.ts"},["3200"] = {line = 31, file = "preset-picker.ts"},["3201"] = {line = 31, file = "preset-picker.ts"},["3202"] = {line = 31, file = "preset-picker.ts"},["3205"] = {line = 33, file = "preset-picker.ts"},["3206"] = {line = 33, file = "preset-picker.ts"},["3207"] = {line = 33, file = "preset-picker.ts"},["3208"] = {line = 33, file = "preset-picker.ts"},["3209"] = {line = 34, file = "preset-picker.ts"},["3210"] = {line = 18, file = "preset-picker.ts"},["3211"] = {line = 37, file = "preset-picker.ts"},["3212"] = {line = 38, file = "preset-picker.ts"},["3213"] = {line = 39, file = "preset-picker.ts"},["3214"] = {line = 39, file = "preset-picker.ts"},["3216"] = {line = 40, file = "preset-picker.ts"},["3218"] = {line = 41, file = "preset-picker.ts"},["3219"] = {line = 41, file = "preset-picker.ts"},["3221"] = {line = 42, file = "preset-picker.ts"},["3222"] = {line = 43, file = "preset-picker.ts"},["3223"] = {line = 43, file = "preset-picker.ts"},["3224"] = {line = 43, file = "preset-picker.ts"},["3225"] = {line = 43, file = "preset-picker.ts"},["3226"] = {line = 43, file = "preset-picker.ts"},["3232"] = {line = 46, file = "preset-picker.ts"},["3233"] = {line = 37, file = "preset-picker.ts"},["3234"] = {line = 49, file = "preset-picker.ts"},["3235"] = {line = 50, file = "preset-picker.ts"},["3236"] = {line = 51, file = "preset-picker.ts"},["3237"] = {line = 52, file = "preset-picker.ts"},["3238"] = {line = 53, file = "preset-picker.ts"},["3239"] = {line = 55, file = "preset-picker.ts"},["3240"] = {line = 56, file = "preset-picker.ts"},["3241"] = {line = 57, file = "preset-picker.ts"},["3242"] = {line = 57, file = "preset-picker.ts"},["3243"] = {line = 57, file = "preset-picker.ts"},["3244"] = {line = 57, file = "preset-picker.ts"},["3245"] = {line = 58, file = "preset-picker.ts"},["3246"] = {line = 59, file = "preset-picker.ts"},["3247"] = {line = 59, file = "preset-picker.ts"},["3248"] = {line = 59, file = "preset-picker.ts"},["3249"] = {line = 59, file = "preset-picker.ts"},["3250"] = {line = 60, file = "preset-picker.ts"},["3251"] = {line = 61, file = "preset-picker.ts"},["3252"] = {line = 61, file = "preset-picker.ts"},["3253"] = {line = 61, file = "preset-picker.ts"},["3254"] = {line = 61, file = "preset-picker.ts"},["3255"] = {line = 61, file = "preset-picker.ts"},["3256"] = {line = 61, file = "preset-picker.ts"},["3257"] = {line = 61, file = "preset-picker.ts"},["3258"] = {line = 61, file = "preset-picker.ts"},["3259"] = {line = 61, file = "preset-picker.ts"},["3260"] = {line = 63, file = "preset-picker.ts"},["3261"] = {line = 64, file = "preset-picker.ts"},["3262"] = {line = 64, file = "preset-picker.ts"},["3263"] = {line = 64, file = "preset-picker.ts"},["3264"] = {line = 64, file = "preset-picker.ts"},["3265"] = {line = 65, file = "preset-picker.ts"},["3266"] = {line = 65, file = "preset-picker.ts"},["3267"] = {line = 65, file = "preset-picker.ts"},["3268"] = {line = 66, file = "preset-picker.ts"},["3269"] = {line = 66, file = "preset-picker.ts"},["3270"] = {line = 66, file = "preset-picker.ts"},["3271"] = {line = 66, file = "preset-picker.ts"},["3272"] = {line = 66, file = "preset-picker.ts"},["3273"] = {line = 66, file = "preset-picker.ts"},["3274"] = {line = 66, file = "preset-picker.ts"},["3275"] = {line = 66, file = "preset-picker.ts"},["3276"] = {line = 66, file = "preset-picker.ts"},["3277"] = {line = 66, file = "preset-picker.ts"},["3278"] = {line = 66, file = "preset-picker.ts"},["3279"] = {line = 67, file = "preset-picker.ts"},["3280"] = {line = 67, file = "preset-picker.ts"},["3281"] = {line = 67, file = "preset-picker.ts"},["3282"] = {line = 67, file = "preset-picker.ts"},["3283"] = {line = 67, file = "preset-picker.ts"},["3285"] = {line = 65, file = "preset-picker.ts"},["3286"] = {line = 65, file = "preset-picker.ts"},["3287"] = {line = 70, file = "preset-picker.ts"},["3288"] = {line = 70, file = "preset-picker.ts"},["3289"] = {line = 70, file = "preset-picker.ts"},["3290"] = {line = 70, file = "preset-picker.ts"},["3291"] = {line = 70, file = "preset-picker.ts"},["3292"] = {line = 70, file = "preset-picker.ts"},["3293"] = {line = 72, file = "preset-picker.ts"},["3294"] = {line = 72, file = "preset-picker.ts"},["3295"] = {line = 72, file = "preset-picker.ts"},["3296"] = {line = 72, file = "preset-picker.ts"},["3297"] = {line = 72, file = "preset-picker.ts"},["3298"] = {line = 72, file = "preset-picker.ts"},["3299"] = {line = 72, file = "preset-picker.ts"},["3300"] = {line = 72, file = "preset-picker.ts"},["3301"] = {line = 73, file = "preset-picker.ts"},["3302"] = {line = 74, file = "preset-picker.ts"},["3303"] = {line = 74, file = "preset-picker.ts"},["3305"] = {line = 75, file = "preset-picker.ts"},["3306"] = {line = 75, file = "preset-picker.ts"},["3307"] = {line = 75, file = "preset-picker.ts"},["3308"] = {line = 76, file = "preset-picker.ts"},["3309"] = {line = 76, file = "preset-picker.ts"},["3311"] = {line = 77, file = "preset-picker.ts"},["3312"] = {line = 78, file = "preset-picker.ts"},["3313"] = {line = 78, file = "preset-picker.ts"},["3314"] = {line = 78, file = "preset-picker.ts"},["3315"] = {line = 78, file = "preset-picker.ts"},["3316"] = {line = 78, file = "preset-picker.ts"},["3317"] = {line = 78, file = "preset-picker.ts"},["3318"] = {line = 78, file = "preset-picker.ts"},["3319"] = {line = 79, file = "preset-picker.ts"},["3320"] = {line = 80, file = "preset-picker.ts"},["3321"] = {line = 78, file = "preset-picker.ts"},["3322"] = {line = 78, file = "preset-picker.ts"},["3323"] = {line = 82, file = "preset-picker.ts"},["3324"] = {line = 83, file = "preset-picker.ts"},["3325"] = {line = 83, file = "preset-picker.ts"},["3326"] = {line = 83, file = "preset-picker.ts"},["3327"] = {line = 83, file = "preset-picker.ts"},["3328"] = {line = 83, file = "preset-picker.ts"},["3329"] = {line = 84, file = "preset-picker.ts"},["3330"] = {line = 84, file = "preset-picker.ts"},["3331"] = {line = 84, file = "preset-picker.ts"},["3332"] = {line = 84, file = "preset-picker.ts"},["3333"] = {line = 84, file = "preset-picker.ts"},["3335"] = {line = 85, file = "preset-picker.ts"},["3336"] = {line = 85, file = "preset-picker.ts"},["3337"] = {line = 85, file = "preset-picker.ts"},["3338"] = {line = 85, file = "preset-picker.ts"},["3340"] = {line = 75, file = "preset-picker.ts"},["3341"] = {line = 75, file = "preset-picker.ts"},["3342"] = {line = 88, file = "preset-picker.ts"},["3343"] = {line = 88, file = "preset-picker.ts"},["3344"] = {line = 88, file = "preset-picker.ts"},["3345"] = {line = 88, file = "preset-picker.ts"},["3346"] = {line = 88, file = "preset-picker.ts"},["3347"] = {line = 88, file = "preset-picker.ts"},["3348"] = {line = 88, file = "preset-picker.ts"},["3349"] = {line = 88, file = "preset-picker.ts"},["3350"] = {line = 55, file = "preset-picker.ts"},["3351"] = {line = 90, file = "preset-picker.ts"},["3352"] = {line = 49, file = "preset-picker.ts"},["3360"] = {line = 2, file = "ui.ts"},["3361"] = {line = 2, file = "ui.ts"},["3362"] = {line = 4, file = "ui.ts"},["3363"] = {line = 4, file = "ui.ts"},["3364"] = {line = 6, file = "ui.ts"},["3365"] = {line = 7, file = "ui.ts"},["3366"] = {line = 8, file = "ui.ts"},["3367"] = {line = 8, file = "ui.ts"},["3368"] = {line = 8, file = "ui.ts"},["3370"] = {line = 8, file = "ui.ts"},["3372"] = {line = 8, file = "ui.ts"},["3373"] = {line = 6, file = "ui.ts"},["3374"] = {line = 11, file = "ui.ts"},["3375"] = {line = 11, file = "ui.ts"},["3376"] = {line = 11, file = "ui.ts"},["3377"] = {line = 11, file = "ui.ts"},["3378"] = {line = 11, file = "ui.ts"},["3379"] = {line = 11, file = "ui.ts"},["3380"] = {line = 11, file = "ui.ts"},["3381"] = {line = 11, file = "ui.ts"},["3382"] = {line = 11, file = "ui.ts"},["3383"] = {line = 13, file = "ui.ts"},["3384"] = {line = 14, file = "ui.ts"},["3385"] = {line = 14, file = "ui.ts"},["3386"] = {line = 14, file = "ui.ts"},["3387"] = {line = 14, file = "ui.ts"},["3388"] = {line = 14, file = "ui.ts"},["3389"] = {line = 15, file = "ui.ts"},["3390"] = {line = 15, file = "ui.ts"},["3391"] = {line = 15, file = "ui.ts"},["3392"] = {line = 14, file = "ui.ts"},["3393"] = {line = 16, file = "ui.ts"},["3394"] = {line = 17, file = "ui.ts"},["3395"] = {line = 18, file = "ui.ts"},["3396"] = {line = 19, file = "ui.ts"},["3397"] = {line = 20, file = "ui.ts"},["3398"] = {line = 20, file = "ui.ts"},["3399"] = {line = 20, file = "ui.ts"},["3400"] = {line = 20, file = "ui.ts"},["3401"] = {line = 21, file = "ui.ts"},["3402"] = {line = 16, file = "ui.ts"},["3403"] = {line = 23, file = "ui.ts"},["3404"] = {line = 23, file = "ui.ts"},["3406"] = {line = 24, file = "ui.ts"},["3407"] = {line = 24, file = "ui.ts"},["3408"] = {line = 24, file = "ui.ts"},["3410"] = {line = 24, file = "ui.ts"},["3412"] = {line = 24, file = "ui.ts"},["3413"] = {line = 24, file = "ui.ts"},["3414"] = {line = 24, file = "ui.ts"},["3416"] = {line = 24, file = "ui.ts"},["3417"] = {line = 24, file = "ui.ts"},["3418"] = {line = 26, file = "ui.ts"},["3419"] = {line = 27, file = "ui.ts"},["3421"] = {line = 27, file = "ui.ts"},["3423"] = {line = 25, file = "ui.ts"},["3424"] = {line = 26, file = "ui.ts"},["3425"] = {line = 27, file = "ui.ts"},["3426"] = {line = 28, file = "ui.ts"},["3427"] = {line = 28, file = "ui.ts"},["3428"] = {line = 28, file = "ui.ts"},["3429"] = {line = 28, file = "ui.ts"},["3430"] = {line = 29, file = "ui.ts"},["3431"] = {line = 29, file = "ui.ts"},["3432"] = {line = 29, file = "ui.ts"},["3433"] = {line = 25, file = "ui.ts"},["3434"] = {line = 13, file = "ui.ts"},["3435"] = {line = 34, file = "ui.ts"},["3436"] = {line = 35, file = "ui.ts"},["3437"] = {line = 35, file = "ui.ts"},["3438"] = {line = 35, file = "ui.ts"},["3439"] = {line = 35, file = "ui.ts"},["3440"] = {line = 35, file = "ui.ts"},["3441"] = {line = 34, file = "ui.ts"},["3442"] = {line = 38, file = "ui.ts"},["3443"] = {line = 39, file = "ui.ts"},["3444"] = {line = 42, file = "ui.ts"},["3445"] = {line = 47, file = "ui.ts"},["3446"] = {line = 47, file = "ui.ts"},["3447"] = {line = 48, file = "ui.ts"},["3450"] = {line = 49, file = "ui.ts"},["3453"] = {line = 53, file = "ui.ts"},["3454"] = {line = 53, file = "ui.ts"},["3455"] = {line = 53, file = "ui.ts"},["3456"] = {line = 53, file = "ui.ts"},["3459"] = {line = 51, file = "ui.ts"},["3465"] = {line = 55, file = "ui.ts"},["3466"] = {line = 55, file = "ui.ts"},["3469"] = {line = 57, file = "ui.ts"},["3470"] = {line = 58, file = "ui.ts"},["3471"] = {line = 59, file = "ui.ts"},["3473"] = {line = 43, file = "ui.ts"},["3474"] = {line = 44, file = "ui.ts"},["3475"] = {line = 45, file = "ui.ts"},["3476"] = {line = 45, file = "ui.ts"},["3477"] = {line = 45, file = "ui.ts"},["3478"] = {line = 45, file = "ui.ts"},["3479"] = {line = 46, file = "ui.ts"},["3480"] = {line = 61, file = "ui.ts"},["3481"] = {line = 62, file = "ui.ts"},["3482"] = {line = 42, file = "ui.ts"},["3483"] = {line = 65, file = "ui.ts"},["3484"] = {line = 66, file = "ui.ts"},["3485"] = {line = 67, file = "ui.ts"},["3486"] = {line = 68, file = "ui.ts"},["3487"] = {line = 69, file = "ui.ts"},["3488"] = {line = 69, file = "ui.ts"},["3490"] = {line = 65, file = "ui.ts"},["3491"] = {line = 72, file = "ui.ts"},["3492"] = {line = 73, file = "ui.ts"},["3493"] = {line = 73, file = "ui.ts"},["3495"] = {line = 72, file = "ui.ts"},["3504"] = {line = 2, file = "vars.ts"},["3505"] = {line = 3, file = "vars.ts"},["3506"] = {line = 3, file = "vars.ts"},["3507"] = {line = 3, file = "vars.ts"},["3508"] = {line = 3, file = "vars.ts"},["3509"] = {line = 4, file = "vars.ts"},["3510"] = {line = 4, file = "vars.ts"},["3511"] = {line = 4, file = "vars.ts"},["3513"] = {line = 4, file = "vars.ts"},["3515"] = {line = 4, file = "vars.ts"},["3516"] = {line = 2, file = "vars.ts"},["3517"] = {line = 7, file = "vars.ts"},["3518"] = {line = 8, file = "vars.ts"},["3519"] = {line = 8, file = "vars.ts"},["3520"] = {line = 8, file = "vars.ts"},["3521"] = {line = 8, file = "vars.ts"},["3522"] = {line = 8, file = "vars.ts"},["3523"] = {line = 7, file = "vars.ts"},["3532"] = {line = 90, file = "ma-desk.ts"},["3533"] = {line = 3, file = "ma-desk.ts"},["3534"] = {line = 3, file = "ma-desk.ts"},["3535"] = {line = 8, file = "ma-desk.ts"},["3536"] = {line = 8, file = "ma-desk.ts"},["3537"] = {line = 9, file = "ma-desk.ts"},["3538"] = {line = 10, file = "ma-desk.ts"},["3539"] = {line = 11, file = "ma-desk.ts"},["3540"] = {line = 11, file = "ma-desk.ts"},["3541"] = {line = 11, file = "ma-desk.ts"},["3542"] = {line = 12, file = "ma-desk.ts"},["3543"] = {line = 12, file = "ma-desk.ts"},["3544"] = {line = 13, file = "ma-desk.ts"},["3545"] = {line = 14, file = "ma-desk.ts"},["3546"] = {line = 14, file = "ma-desk.ts"},["3547"] = {line = 15, file = "ma-desk.ts"},["3548"] = {line = 16, file = "ma-desk.ts"},["3549"] = {line = 90, file = "ma-desk.ts"},["3552"] = {line = 94, file = "ma-desk.ts"},["3553"] = {line = 94, file = "ma-desk.ts"},["3554"] = {line = 94, file = "ma-desk.ts"},["3555"] = {line = 94, file = "ma-desk.ts"},["3558"] = {line = 92, file = "ma-desk.ts"},["3565"] = {line = 18, file = "ma-desk.ts"},["3566"] = {line = 18, file = "ma-desk.ts"},["3567"] = {line = 18, file = "ma-desk.ts"},["3569"] = {line = 19, file = "ma-desk.ts"},["3570"] = {line = 20, file = "ma-desk.ts"},["3571"] = {line = 18, file = "ma-desk.ts"},["3572"] = {line = 22, file = "ma-desk.ts"},["3573"] = {line = 22, file = "ma-desk.ts"},["3574"] = {line = 22, file = "ma-desk.ts"},["3575"] = {line = 23, file = "ma-desk.ts"},["3576"] = {line = 23, file = "ma-desk.ts"},["3577"] = {line = 23, file = "ma-desk.ts"},["3578"] = {line = 24, file = "ma-desk.ts"},["3579"] = {line = 24, file = "ma-desk.ts"},["3580"] = {line = 24, file = "ma-desk.ts"},["3581"] = {line = 25, file = "ma-desk.ts"},["3582"] = {line = 25, file = "ma-desk.ts"},["3583"] = {line = 25, file = "ma-desk.ts"},["3584"] = {line = 26, file = "ma-desk.ts"},["3585"] = {line = 27, file = "ma-desk.ts"},["3586"] = {line = 28, file = "ma-desk.ts"},["3587"] = {line = 26, file = "ma-desk.ts"},["3588"] = {line = 30, file = "ma-desk.ts"},["3589"] = {line = 30, file = "ma-desk.ts"},["3590"] = {line = 30, file = "ma-desk.ts"},["3591"] = {line = 31, file = "ma-desk.ts"},["3592"] = {line = 32, file = "ma-desk.ts"},["3595"] = {line = 36, file = "ma-desk.ts"},["3596"] = {line = 36, file = "ma-desk.ts"},["3597"] = {line = 36, file = "ma-desk.ts"},["3598"] = {line = 36, file = "ma-desk.ts"},["3601"] = {line = 34, file = "ma-desk.ts"},["3607"] = {line = 38, file = "ma-desk.ts"},["3608"] = {line = 39, file = "ma-desk.ts"},["3611"] = {line = 43, file = "ma-desk.ts"},["3612"] = {line = 43, file = "ma-desk.ts"},["3613"] = {line = 43, file = "ma-desk.ts"},["3614"] = {line = 43, file = "ma-desk.ts"},["3617"] = {line = 41, file = "ma-desk.ts"},["3623"] = {line = 45, file = "ma-desk.ts"},["3624"] = {line = 46, file = "ma-desk.ts"},["3625"] = {line = 47, file = "ma-desk.ts"},["3626"] = {line = 48, file = "ma-desk.ts"},["3627"] = {line = 48, file = "ma-desk.ts"},["3629"] = {line = 49, file = "ma-desk.ts"},["3630"] = {line = 49, file = "ma-desk.ts"},["3631"] = {line = 49, file = "ma-desk.ts"},["3632"] = {line = 49, file = "ma-desk.ts"},["3633"] = {line = 49, file = "ma-desk.ts"},["3634"] = {line = 50, file = "ma-desk.ts"},["3635"] = {line = 50, file = "ma-desk.ts"},["3636"] = {line = 50, file = "ma-desk.ts"},["3637"] = {line = 50, file = "ma-desk.ts"},["3638"] = {line = 51, file = "ma-desk.ts"},["3639"] = {line = 52, file = "ma-desk.ts"},["3640"] = {line = 52, file = "ma-desk.ts"},["3641"] = {line = 52, file = "ma-desk.ts"},["3642"] = {line = 52, file = "ma-desk.ts"},["3643"] = {line = 52, file = "ma-desk.ts"},["3644"] = {line = 52, file = "ma-desk.ts"},["3645"] = {line = 53, file = "ma-desk.ts"},["3646"] = {line = 53, file = "ma-desk.ts"},["3647"] = {line = 53, file = "ma-desk.ts"},["3648"] = {line = 53, file = "ma-desk.ts"},["3649"] = {line = 54, file = "ma-desk.ts"},["3650"] = {line = 55, file = "ma-desk.ts"},["3651"] = {line = 55, file = "ma-desk.ts"},["3652"] = {line = 55, file = "ma-desk.ts"},["3653"] = {line = 55, file = "ma-desk.ts"},["3654"] = {line = 55, file = "ma-desk.ts"},["3655"] = {line = 55, file = "ma-desk.ts"},["3656"] = {line = 56, file = "ma-desk.ts"},["3657"] = {line = 56, file = "ma-desk.ts"},["3658"] = {line = 56, file = "ma-desk.ts"},["3659"] = {line = 56, file = "ma-desk.ts"},["3662"] = {line = 31, file = "ma-desk.ts"},["3663"] = {line = 60, file = "ma-desk.ts"},["3664"] = {line = 60, file = "ma-desk.ts"},["3665"] = {line = 60, file = "ma-desk.ts"},["3666"] = {line = 61, file = "ma-desk.ts"},["3667"] = {line = 61, file = "ma-desk.ts"},["3668"] = {line = 61, file = "ma-desk.ts"},["3669"] = {line = 62, file = "ma-desk.ts"},["3670"] = {line = 62, file = "ma-desk.ts"},["3671"] = {line = 62, file = "ma-desk.ts"},["3672"] = {line = 63, file = "ma-desk.ts"},["3673"] = {line = 63, file = "ma-desk.ts"},["3674"] = {line = 63, file = "ma-desk.ts"},["3675"] = {line = 64, file = "ma-desk.ts"},["3676"] = {line = 64, file = "ma-desk.ts"},["3677"] = {line = 64, file = "ma-desk.ts"},["3678"] = {line = 66, file = "ma-desk.ts"},["3679"] = {line = 67, file = "ma-desk.ts"},["3680"] = {line = 68, file = "ma-desk.ts"},["3681"] = {line = 68, file = "ma-desk.ts"},["3683"] = {line = 69, file = "ma-desk.ts"},["3684"] = {line = 69, file = "ma-desk.ts"},["3685"] = {line = 69, file = "ma-desk.ts"},["3686"] = {line = 69, file = "ma-desk.ts"},["3687"] = {line = 70, file = "ma-desk.ts"},["3688"] = {line = 70, file = "ma-desk.ts"},["3689"] = {line = 70, file = "ma-desk.ts"},["3690"] = {line = 70, file = "ma-desk.ts"},["3691"] = {line = 70, file = "ma-desk.ts"},["3693"] = {line = 66, file = "ma-desk.ts"},["3694"] = {line = 73, file = "ma-desk.ts"},["3695"] = {line = 74, file = "ma-desk.ts"},["3696"] = {line = 75, file = "ma-desk.ts"},["3697"] = {line = 75, file = "ma-desk.ts"},["3699"] = {line = 76, file = "ma-desk.ts"},["3700"] = {line = 77, file = "ma-desk.ts"},["3701"] = {line = 73, file = "ma-desk.ts"},["3702"] = {line = 79, file = "ma-desk.ts"},["3703"] = {line = 79, file = "ma-desk.ts"},["3704"] = {line = 79, file = "ma-desk.ts"},["3705"] = {line = 80, file = "ma-desk.ts"},["3706"] = {line = 80, file = "ma-desk.ts"},["3707"] = {line = 80, file = "ma-desk.ts"},["3708"] = {line = 81, file = "ma-desk.ts"},["3709"] = {line = 81, file = "ma-desk.ts"},["3710"] = {line = 81, file = "ma-desk.ts"},["3711"] = {line = 82, file = "ma-desk.ts"},["3712"] = {line = 82, file = "ma-desk.ts"},["3713"] = {line = 82, file = "ma-desk.ts"},["3714"] = {line = 83, file = "ma-desk.ts"},["3715"] = {line = 83, file = "ma-desk.ts"},["3716"] = {line = 83, file = "ma-desk.ts"},["3717"] = {line = 84, file = "ma-desk.ts"},["3718"] = {line = 84, file = "ma-desk.ts"},["3719"] = {line = 84, file = "ma-desk.ts"},["3720"] = {line = 85, file = "ma-desk.ts"},["3721"] = {line = 85, file = "ma-desk.ts"},["3722"] = {line = 85, file = "ma-desk.ts"},["3723"] = {line = 86, file = "ma-desk.ts"},["3724"] = {line = 86, file = "ma-desk.ts"},["3725"] = {line = 86, file = "ma-desk.ts"},["3726"] = {line = 87, file = "ma-desk.ts"},["3727"] = {line = 87, file = "ma-desk.ts"},["3728"] = {line = 87, file = "ma-desk.ts"},["3729"] = {line = 98, file = "ma-desk.ts"},["3730"] = {line = 99, file = "ma-desk.ts"},["3731"] = {line = 98, file = "ma-desk.ts"},["3742"] = {line = 2, file = "arm-command.ts"},["3743"] = {line = 2, file = "arm-command.ts"},["3744"] = {line = 4, file = "arm-command.ts"},["3745"] = {line = 5, file = "arm-command.ts"},["3746"] = {line = 6, file = "arm-command.ts"},["3747"] = {line = 7, file = "arm-command.ts"},["3748"] = {line = 8, file = "arm-command.ts"},["3749"] = {line = 9, file = "arm-command.ts"},["3750"] = {line = 10, file = "arm-command.ts"},["3753"] = {line = 13, file = "arm-command.ts"},["3754"] = {line = 13, file = "arm-command.ts"},["3755"] = {line = 13, file = "arm-command.ts"},["3756"] = {line = 13, file = "arm-command.ts"},["3757"] = {line = 14, file = "arm-command.ts"},["3758"] = {line = 4, file = "arm-command.ts"},["3759"] = {line = 17, file = "arm-command.ts"},["3760"] = {line = 18, file = "arm-command.ts"},["3761"] = {line = 19, file = "arm-command.ts"},["3762"] = {line = 20, file = "arm-command.ts"},["3763"] = {line = 21, file = "arm-command.ts"},["3764"] = {line = 21, file = "arm-command.ts"},["3767"] = {line = 23, file = "arm-command.ts"},["3768"] = {line = 17, file = "arm-command.ts"},["3777"] = {line = 26, file = "program.ts"},["3778"] = {line = 2, file = "program.ts"},["3779"] = {line = 2, file = "program.ts"},["3780"] = {line = 2, file = "program.ts"},["3781"] = {line = 26, file = "program.ts"},["3782"] = {line = 27, file = "program.ts"},["3783"] = {line = 27, file = "program.ts"},["3784"] = {line = 27, file = "program.ts"},["3785"] = {line = 27, file = "program.ts"},["3786"] = {line = 27, file = "program.ts"},["3787"] = {line = 27, file = "program.ts"},["3788"] = {line = 27, file = "program.ts"},["3790"] = {line = 8, file = "program.ts"},["3791"] = {line = 9, file = "program.ts"},["3792"] = {line = 9, file = "program.ts"},["3794"] = {line = 10, file = "program.ts"},["3795"] = {line = 10, file = "program.ts"},["3796"] = {line = 10, file = "program.ts"},["3797"] = {line = 10, file = "program.ts"},["3798"] = {line = 11, file = "program.ts"},["3799"] = {line = 12, file = "program.ts"},["3800"] = {line = 13, file = "program.ts"},["3802"] = {line = 15, file = "program.ts"},["3803"] = {line = 16, file = "program.ts"},["3804"] = {line = 17, file = "program.ts"},["3806"] = {line = 19, file = "program.ts"},["3807"] = {line = 8, file = "program.ts"},["3808"] = {line = 22, file = "program.ts"},["3809"] = {line = 23, file = "program.ts"},["3810"] = {line = 22, file = "program.ts"},["3833"] = {line = 2, file = "autozoom.ts"},["3834"] = {line = 2, file = "autozoom.ts"},["3835"] = {line = 2, file = "autozoom.ts"},["3836"] = {line = 3, file = "autozoom.ts"},["3837"] = {line = 3, file = "autozoom.ts"},["3838"] = {line = 3, file = "autozoom.ts"},["3839"] = {line = 4, file = "autozoom.ts"},["3840"] = {line = 4, file = "autozoom.ts"},["3841"] = {line = 5, file = "autozoom.ts"},["3842"] = {line = 5, file = "autozoom.ts"},["3843"] = {line = 7, file = "autozoom.ts"},["3844"] = {line = 7, file = "autozoom.ts"},["3845"] = {line = 7, file = "autozoom.ts"},["3846"] = {line = 7, file = "autozoom.ts"},["3847"] = {line = 9, file = "autozoom.ts"},["3848"] = {line = 9, file = "autozoom.ts"},["3849"] = {line = 9, file = "autozoom.ts"},["3850"] = {line = 9, file = "autozoom.ts"},["3851"] = {line = 9, file = "autozoom.ts"},["3852"] = {line = 9, file = "autozoom.ts"},["3853"] = {line = 9, file = "autozoom.ts"},["3854"] = {line = 9, file = "autozoom.ts"},["3855"] = {line = 9, file = "autozoom.ts"},["3856"] = {line = 10, file = "autozoom.ts"},["3857"] = {line = 10, file = "autozoom.ts"},["3858"] = {line = 10, file = "autozoom.ts"},["3859"] = {line = 10, file = "autozoom.ts"},["3860"] = {line = 10, file = "autozoom.ts"},["3861"] = {line = 14, file = "autozoom.ts"},["3862"] = {line = 14, file = "autozoom.ts"},["3863"] = {line = 14, file = "autozoom.ts"},["3864"] = {line = 29, file = "autozoom.ts"},["3865"] = {line = 29, file = "autozoom.ts"},["3866"] = {line = 29, file = "autozoom.ts"},["3867"] = {line = 15, file = "autozoom.ts"},["3868"] = {line = 16, file = "autozoom.ts"},["3869"] = {line = 17, file = "autozoom.ts"},["3870"] = {line = 18, file = "autozoom.ts"},["3871"] = {line = 19, file = "autozoom.ts"},["3872"] = {line = 20, file = "autozoom.ts"},["3873"] = {line = 21, file = "autozoom.ts"},["3874"] = {line = 22, file = "autozoom.ts"},["3875"] = {line = 23, file = "autozoom.ts"},["3876"] = {line = 24, file = "autozoom.ts"},["3877"] = {line = 27, file = "autozoom.ts"},["3878"] = {line = 29, file = "autozoom.ts"},["3879"] = {line = 32, file = "autozoom.ts"},["3880"] = {line = 33, file = "autozoom.ts"},["3881"] = {line = 32, file = "autozoom.ts"},["3882"] = {line = 36, file = "autozoom.ts"},["3883"] = {line = 37, file = "autozoom.ts"},["3884"] = {line = 37, file = "autozoom.ts"},["3886"] = {line = 38, file = "autozoom.ts"},["3887"] = {line = 39, file = "autozoom.ts"},["3888"] = {line = 36, file = "autozoom.ts"},["3889"] = {line = 42, file = "autozoom.ts"},["3890"] = {line = 43, file = "autozoom.ts"},["3891"] = {line = 44, file = "autozoom.ts"},["3892"] = {line = 44, file = "autozoom.ts"},["3894"] = {line = 45, file = "autozoom.ts"},["3895"] = {line = 46, file = "autozoom.ts"},["3896"] = {line = 47, file = "autozoom.ts"},["3897"] = {line = 42, file = "autozoom.ts"},["3898"] = {line = 50, file = "autozoom.ts"},["3899"] = {line = 51, file = "autozoom.ts"},["3902"] = {line = 52, file = "autozoom.ts"},["3903"] = {line = 53, file = "autozoom.ts"},["3904"] = {line = 54, file = "autozoom.ts"},["3905"] = {line = 54, file = "autozoom.ts"},["3907"] = {line = 55, file = "autozoom.ts"},["3908"] = {line = 56, file = "autozoom.ts"},["3909"] = {line = 57, file = "autozoom.ts"},["3910"] = {line = 58, file = "autozoom.ts"},["3911"] = {line = 58, file = "autozoom.ts"},["3913"] = {line = 60, file = "autozoom.ts"},["3914"] = {line = 60, file = "autozoom.ts"},["3915"] = {line = 60, file = "autozoom.ts"},["3916"] = {line = 60, file = "autozoom.ts"},["3917"] = {line = 61, file = "autozoom.ts"},["3918"] = {line = 62, file = "autozoom.ts"},["3919"] = {line = 62, file = "autozoom.ts"},["3920"] = {line = 62, file = "autozoom.ts"},["3921"] = {line = 62, file = "autozoom.ts"},["3922"] = {line = 62, file = "autozoom.ts"},["3923"] = {line = 62, file = "autozoom.ts"},["3924"] = {line = 62, file = "autozoom.ts"},["3925"] = {line = 63, file = "autozoom.ts"},["3926"] = {line = 64, file = "autozoom.ts"},["3927"] = {line = 65, file = "autozoom.ts"},["3928"] = {line = 66, file = "autozoom.ts"},["3929"] = {line = 67, file = "autozoom.ts"},["3930"] = {line = 68, file = "autozoom.ts"},["3931"] = {line = 50, file = "autozoom.ts"},["3932"] = {line = 72, file = "autozoom.ts"},["3933"] = {line = 73, file = "autozoom.ts"},["3934"] = {line = 74, file = "autozoom.ts"},["3935"] = {line = 74, file = "autozoom.ts"},["3937"] = {line = 75, file = "autozoom.ts"},["3938"] = {line = 75, file = "autozoom.ts"},["3939"] = {line = 75, file = "autozoom.ts"},["3940"] = {line = 75, file = "autozoom.ts"},["3941"] = {line = 75, file = "autozoom.ts"},["3943"] = {line = 76, file = "autozoom.ts"},["3944"] = {line = 76, file = "autozoom.ts"},["3945"] = {line = 76, file = "autozoom.ts"},["3946"] = {line = 76, file = "autozoom.ts"},["3947"] = {line = 77, file = "autozoom.ts"},["3948"] = {line = 78, file = "autozoom.ts"},["3950"] = {line = 79, file = "autozoom.ts"},["3951"] = {line = 80, file = "autozoom.ts"},["3952"] = {line = 81, file = "autozoom.ts"},["3953"] = {line = 81, file = "autozoom.ts"},["3955"] = {line = 82, file = "autozoom.ts"},["3957"] = {line = 83, file = "autozoom.ts"},["3959"] = {line = 85, file = "autozoom.ts"},["3960"] = {line = 85, file = "autozoom.ts"},["3961"] = {line = 85, file = "autozoom.ts"},["3962"] = {line = 85, file = "autozoom.ts"},["3963"] = {line = 86, file = "autozoom.ts"},["3964"] = {line = 87, file = "autozoom.ts"},["3965"] = {line = 87, file = "autozoom.ts"},["3967"] = {line = 88, file = "autozoom.ts"},["3968"] = {line = 89, file = "autozoom.ts"},["3969"] = {line = 89, file = "autozoom.ts"},["3970"] = {line = 89, file = "autozoom.ts"},["3971"] = {line = 89, file = "autozoom.ts"},["3972"] = {line = 90, file = "autozoom.ts"},["3973"] = {line = 90, file = "autozoom.ts"},["3974"] = {line = 90, file = "autozoom.ts"},["3975"] = {line = 90, file = "autozoom.ts"},["3976"] = {line = 88, file = "autozoom.ts"},["3980"] = {line = 93, file = "autozoom.ts"},["3981"] = {line = 72, file = "autozoom.ts"},["3982"] = {line = 97, file = "autozoom.ts"},["3983"] = {line = 98, file = "autozoom.ts"},["3984"] = {line = 99, file = "autozoom.ts"},["3985"] = {line = 100, file = "autozoom.ts"},["3986"] = {line = 100, file = "autozoom.ts"},["3988"] = {line = 101, file = "autozoom.ts"},["3989"] = {line = 101, file = "autozoom.ts"},["3993"] = {line = 103, file = "autozoom.ts"},["3994"] = {line = 103, file = "autozoom.ts"},["3995"] = {line = 103, file = "autozoom.ts"},["3996"] = {line = 103, file = "autozoom.ts"},["3997"] = {line = 97, file = "autozoom.ts"},["3998"] = {line = 106, file = "autozoom.ts"},["3999"] = {line = 107, file = "autozoom.ts"},["4000"] = {line = 107, file = "autozoom.ts"},["4001"] = {line = 107, file = "autozoom.ts"},["4004"] = {line = 108, file = "autozoom.ts"},["4005"] = {line = 106, file = "autozoom.ts"},["4006"] = {line = 112, file = "autozoom.ts"},["4007"] = {line = 113, file = "autozoom.ts"},["4010"] = {line = 114, file = "autozoom.ts"},["4011"] = {line = 112, file = "autozoom.ts"},["4012"] = {line = 118, file = "autozoom.ts"},["4013"] = {line = 119, file = "autozoom.ts"},["4014"] = {line = 118, file = "autozoom.ts"},["4015"] = {line = 122, file = "autozoom.ts"},["4016"] = {line = 123, file = "autozoom.ts"},["4019"] = {line = 124, file = "autozoom.ts"},["4022"] = {line = 125, file = "autozoom.ts"},["4023"] = {line = 126, file = "autozoom.ts"},["4024"] = {line = 126, file = "autozoom.ts"},["4025"] = {line = 126, file = "autozoom.ts"},["4026"] = {line = 126, file = "autozoom.ts"},["4027"] = {line = 127, file = "autozoom.ts"},["4028"] = {line = 128, file = "autozoom.ts"},["4029"] = {line = 129, file = "autozoom.ts"},["4030"] = {line = 129, file = "autozoom.ts"},["4031"] = {line = 129, file = "autozoom.ts"},["4033"] = {line = 129, file = "autozoom.ts"},["4034"] = {line = 130, file = "autozoom.ts"},["4035"] = {line = 130, file = "autozoom.ts"},["4036"] = {line = 130, file = "autozoom.ts"},["4038"] = {line = 130, file = "autozoom.ts"},["4039"] = {line = 127, file = "autozoom.ts"},["4040"] = {line = 132, file = "autozoom.ts"},["4041"] = {line = 122, file = "autozoom.ts"},["4042"] = {line = 135, file = "autozoom.ts"},["4043"] = {line = 136, file = "autozoom.ts"},["4044"] = {line = 138, file = "autozoom.ts"},["4047"] = {line = 139, file = "autozoom.ts"},["4048"] = {line = 140, file = "autozoom.ts"},["4049"] = {line = 141, file = "autozoom.ts"},["4052"] = {line = 144, file = "autozoom.ts"},["4053"] = {line = 145, file = "autozoom.ts"},["4056"] = {line = 146, file = "autozoom.ts"},["4057"] = {line = 147, file = "autozoom.ts"},["4058"] = {line = 148, file = "autozoom.ts"},["4059"] = {line = 150, file = "autozoom.ts"},["4062"] = {line = 154, file = "autozoom.ts"},["4063"] = {line = 154, file = "autozoom.ts"},["4064"] = {line = 154, file = "autozoom.ts"},["4065"] = {line = 154, file = "autozoom.ts"},["4068"] = {line = 152, file = "autozoom.ts"},["4074"] = {line = 156, file = "autozoom.ts"},["4075"] = {line = 135, file = "autozoom.ts"},["4076"] = {line = 159, file = "autozoom.ts"},["4077"] = {line = 160, file = "autozoom.ts"},["4080"] = {line = 161, file = "autozoom.ts"},["4081"] = {line = 161, file = "autozoom.ts"},["4083"] = {line = 161, file = "autozoom.ts"},["4085"] = {line = 159, file = "autozoom.ts"},["4086"] = {line = 165, file = "autozoom.ts"},["4087"] = {line = 166, file = "autozoom.ts"},["4090"] = {line = 167, file = "autozoom.ts"},["4091"] = {line = 165, file = "autozoom.ts"},["4092"] = {line = 170, file = "autozoom.ts"},["4093"] = {line = 171, file = "autozoom.ts"},["4096"] = {line = 172, file = "autozoom.ts"},["4097"] = {line = 173, file = "autozoom.ts"},["4100"] = {line = 176, file = "autozoom.ts"},["4101"] = {line = 176, file = "autozoom.ts"},["4102"] = {line = 176, file = "autozoom.ts"},["4103"] = {line = 176, file = "autozoom.ts"},["4104"] = {line = 177, file = "autozoom.ts"},["4105"] = {line = 177, file = "autozoom.ts"},["4107"] = {line = 178, file = "autozoom.ts"},["4108"] = {line = 179, file = "autozoom.ts"},["4109"] = {line = 180, file = "autozoom.ts"},["4110"] = {line = 170, file = "autozoom.ts"},["4111"] = {line = 184, file = "autozoom.ts"},["4112"] = {line = 185, file = "autozoom.ts"},["4115"] = {line = 186, file = "autozoom.ts"},["4116"] = {line = 187, file = "autozoom.ts"},["4119"] = {line = 188, file = "autozoom.ts"},["4120"] = {line = 188, file = "autozoom.ts"},["4121"] = {line = 188, file = "autozoom.ts"},["4122"] = {line = 188, file = "autozoom.ts"},["4123"] = {line = 189, file = "autozoom.ts"},["4124"] = {line = 189, file = "autozoom.ts"},["4125"] = {line = 189, file = "autozoom.ts"},["4126"] = {line = 189, file = "autozoom.ts"},["4127"] = {line = 190, file = "autozoom.ts"},["4128"] = {line = 190, file = "autozoom.ts"},["4129"] = {line = 190, file = "autozoom.ts"},["4130"] = {line = 190, file = "autozoom.ts"},["4132"] = {line = 190, file = "autozoom.ts"},["4135"] = {line = 190, file = "autozoom.ts"},["4137"] = {line = 190, file = "autozoom.ts"},["4139"] = {line = 190, file = "autozoom.ts"},["4140"] = {line = 191, file = "autozoom.ts"},["4141"] = {line = 192, file = "autozoom.ts"},["4142"] = {line = 184, file = "autozoom.ts"},["4143"] = {line = 195, file = "autozoom.ts"},["4144"] = {line = 196, file = "autozoom.ts"},["4147"] = {line = 197, file = "autozoom.ts"},["4148"] = {line = 197, file = "autozoom.ts"},["4149"] = {line = 197, file = "autozoom.ts"},["4150"] = {line = 197, file = "autozoom.ts"},["4151"] = {line = 195, file = "autozoom.ts"},["4152"] = {line = 200, file = "autozoom.ts"},["4153"] = {line = 201, file = "autozoom.ts"},["4156"] = {line = 202, file = "autozoom.ts"},["4157"] = {line = 200, file = "autozoom.ts"},["4158"] = {line = 205, file = "autozoom.ts"},["4159"] = {line = 206, file = "autozoom.ts"},["4162"] = {line = 207, file = "autozoom.ts"},["4163"] = {line = 207, file = "autozoom.ts"},["4164"] = {line = 207, file = "autozoom.ts"},["4165"] = {line = 207, file = "autozoom.ts"},["4166"] = {line = 208, file = "autozoom.ts"},["4167"] = {line = 209, file = "autozoom.ts"},["4168"] = {line = 210, file = "autozoom.ts"},["4169"] = {line = 211, file = "autozoom.ts"},["4171"] = {line = 213, file = "autozoom.ts"},["4172"] = {line = 214, file = "autozoom.ts"},["4175"] = {line = 205, file = "autozoom.ts"},["4176"] = {line = 220, file = "autozoom.ts"},["4177"] = {line = 221, file = "autozoom.ts"},["4180"] = {line = 222, file = "autozoom.ts"},["4181"] = {line = 223, file = "autozoom.ts"},["4182"] = {line = 224, file = "autozoom.ts"},["4185"] = {line = 227, file = "autozoom.ts"},["4186"] = {line = 228, file = "autozoom.ts"},["4188"] = {line = 230, file = "autozoom.ts"},["4190"] = {line = 232, file = "autozoom.ts"},["4191"] = {line = 220, file = "autozoom.ts"},["4192"] = {line = 236, file = "autozoom.ts"},["4193"] = {line = 237, file = "autozoom.ts"},["4196"] = {line = 238, file = "autozoom.ts"},["4197"] = {line = 239, file = "autozoom.ts"},["4200"] = {line = 240, file = "autozoom.ts"},["4201"] = {line = 240, file = "autozoom.ts"},["4202"] = {line = 240, file = "autozoom.ts"},["4203"] = {line = 240, file = "autozoom.ts"},["4204"] = {line = 240, file = "autozoom.ts"},["4205"] = {line = 240, file = "autozoom.ts"},["4206"] = {line = 240, file = "autozoom.ts"},["4207"] = {line = 241, file = "autozoom.ts"},["4208"] = {line = 242, file = "autozoom.ts"},["4209"] = {line = 236, file = "autozoom.ts"},["4210"] = {line = 246, file = "autozoom.ts"},["4211"] = {line = 247, file = "autozoom.ts"},["4212"] = {line = 247, file = "autozoom.ts"},["4213"] = {line = 247, file = "autozoom.ts"},["4214"] = {line = 247, file = "autozoom.ts"},["4215"] = {line = 247, file = "autozoom.ts"},["4216"] = {line = 248, file = "autozoom.ts"},["4217"] = {line = 248, file = "autozoom.ts"},["4219"] = {line = 249, file = "autozoom.ts"},["4220"] = {line = 250, file = "autozoom.ts"},["4221"] = {line = 246, file = "autozoom.ts"},["4222"] = {line = 253, file = "autozoom.ts"},["4223"] = {line = 254, file = "autozoom.ts"},["4226"] = {line = 255, file = "autozoom.ts"},["4227"] = {line = 256, file = "autozoom.ts"},["4228"] = {line = 257, file = "autozoom.ts"},["4231"] = {line = 258, file = "autozoom.ts"},["4232"] = {line = 259, file = "autozoom.ts"},["4235"] = {line = 262, file = "autozoom.ts"},["4238"] = {line = 263, file = "autozoom.ts"},["4239"] = {line = 264, file = "autozoom.ts"},["4240"] = {line = 265, file = "autozoom.ts"},["4241"] = {line = 265, file = "autozoom.ts"},["4243"] = {line = 266, file = "autozoom.ts"},["4244"] = {line = 267, file = "autozoom.ts"},["4245"] = {line = 268, file = "autozoom.ts"},["4246"] = {line = 268, file = "autozoom.ts"},["4248"] = {line = 269, file = "autozoom.ts"},["4249"] = {line = 270, file = "autozoom.ts"},["4250"] = {line = 255, file = "autozoom.ts"},["4251"] = {line = 253, file = "autozoom.ts"},["4252"] = {line = 274, file = "autozoom.ts"},["4253"] = {line = 275, file = "autozoom.ts"},["4256"] = {line = 276, file = "autozoom.ts"},["4257"] = {line = 277, file = "autozoom.ts"},["4258"] = {line = 278, file = "autozoom.ts"},["4261"] = {line = 281, file = "autozoom.ts"},["4262"] = {line = 282, file = "autozoom.ts"},["4263"] = {line = 283, file = "autozoom.ts"},["4264"] = {line = 284, file = "autozoom.ts"},["4265"] = {line = 284, file = "autozoom.ts"},["4266"] = {line = 284, file = "autozoom.ts"},["4267"] = {line = 284, file = "autozoom.ts"},["4268"] = {line = 285, file = "autozoom.ts"},["4271"] = {line = 286, file = "autozoom.ts"},["4272"] = {line = 286, file = "autozoom.ts"},["4273"] = {line = 286, file = "autozoom.ts"},["4274"] = {line = 286, file = "autozoom.ts"},["4275"] = {line = 286, file = "autozoom.ts"},["4276"] = {line = 287, file = "autozoom.ts"},["4277"] = {line = 288, file = "autozoom.ts"},["4279"] = {line = 290, file = "autozoom.ts"},["4280"] = {line = 291, file = "autozoom.ts"},["4281"] = {line = 292, file = "autozoom.ts"},["4284"] = {line = 295, file = "autozoom.ts"},["4286"] = {line = 297, file = "autozoom.ts"},["4287"] = {line = 298, file = "autozoom.ts"},["4288"] = {line = 281, file = "autozoom.ts"},["4289"] = {line = 274, file = "autozoom.ts"},["4290"] = {line = 303, file = "autozoom.ts"},["4291"] = {line = 304, file = "autozoom.ts"},["4292"] = {line = 305, file = "autozoom.ts"},["4293"] = {line = 306, file = "autozoom.ts"},["4294"] = {line = 307, file = "autozoom.ts"},["4295"] = {line = 308, file = "autozoom.ts"},["4298"] = {line = 311, file = "autozoom.ts"},["4299"] = {line = 312, file = "autozoom.ts"},["4300"] = {line = 312, file = "autozoom.ts"},["4302"] = {line = 303, file = "autozoom.ts"},["4303"] = {line = 315, file = "autozoom.ts"},["4304"] = {line = 317, file = "autozoom.ts"},["4305"] = {line = 318, file = "autozoom.ts"},["4306"] = {line = 315, file = "autozoom.ts"},["4307"] = {line = 322, file = "autozoom.ts"},["4308"] = {line = 323, file = "autozoom.ts"},["4310"] = {line = 324, file = "autozoom.ts"},["4311"] = {line = 325, file = "autozoom.ts"},["4312"] = {line = 325, file = "autozoom.ts"},["4316"] = {line = 329, file = "autozoom.ts"},["4317"] = {line = 329, file = "autozoom.ts"},["4318"] = {line = 329, file = "autozoom.ts"},["4319"] = {line = 329, file = "autozoom.ts"},["4322"] = {line = 327, file = "autozoom.ts"},["4328"] = {line = 331, file = "autozoom.ts"},["4332"] = {line = 322, file = "autozoom.ts"},["4333"] = {line = 335, file = "autozoom.ts"},["4334"] = {line = 336, file = "autozoom.ts"},["4335"] = {line = 337, file = "autozoom.ts"},["4336"] = {line = 338, file = "autozoom.ts"},["4339"] = {line = 342, file = "autozoom.ts"},["4340"] = {line = 342, file = "autozoom.ts"},["4341"] = {line = 342, file = "autozoom.ts"},["4342"] = {line = 342, file = "autozoom.ts"},["4345"] = {line = 340, file = "autozoom.ts"},["4352"] = {line = 345, file = "autozoom.ts"},["4353"] = {line = 335, file = "autozoom.ts"},["4354"] = {line = 348, file = "autozoom.ts"},["4355"] = {line = 349, file = "autozoom.ts"},["4358"] = {line = 350, file = "autozoom.ts"},["4359"] = {line = 348, file = "autozoom.ts"},["4360"] = {line = 353, file = "autozoom.ts"},["4361"] = {line = 354, file = "autozoom.ts"},["4362"] = {line = 354, file = "autozoom.ts"},["4363"] = {line = 354, file = "autozoom.ts"},["4364"] = {line = 355, file = "autozoom.ts"},["4367"] = {line = 356, file = "autozoom.ts"},["4368"] = {line = 357, file = "autozoom.ts"},["4369"] = {line = 358, file = "autozoom.ts"},["4370"] = {line = 359, file = "autozoom.ts"},["4371"] = {line = 354, file = "autozoom.ts"},["4372"] = {line = 354, file = "autozoom.ts"},["4373"] = {line = 353, file = "autozoom.ts"},["4374"] = {line = 363, file = "autozoom.ts"},["4375"] = {line = 364, file = "autozoom.ts"},["4376"] = {line = 365, file = "autozoom.ts"},["4377"] = {line = 366, file = "autozoom.ts"},["4378"] = {line = 366, file = "autozoom.ts"},["4379"] = {line = 366, file = "autozoom.ts"},["4380"] = {line = 366, file = "autozoom.ts"},["4381"] = {line = 366, file = "autozoom.ts"},["4382"] = {line = 367, file = "autozoom.ts"},["4383"] = {line = 368, file = "autozoom.ts"},["4384"] = {line = 369, file = "autozoom.ts"},["4385"] = {line = 369, file = "autozoom.ts"},["4386"] = {line = 369, file = "autozoom.ts"},["4387"] = {line = 369, file = "autozoom.ts"},["4388"] = {line = 370, file = "autozoom.ts"},["4389"] = {line = 371, file = "autozoom.ts"},["4390"] = {line = 371, file = "autozoom.ts"},["4391"] = {line = 371, file = "autozoom.ts"},["4392"] = {line = 371, file = "autozoom.ts"},["4394"] = {line = 373, file = "autozoom.ts"},["4395"] = {line = 374, file = "autozoom.ts"},["4396"] = {line = 374, file = "autozoom.ts"},["4397"] = {line = 374, file = "autozoom.ts"},["4398"] = {line = 374, file = "autozoom.ts"},["4399"] = {line = 375, file = "autozoom.ts"},["4400"] = {line = 375, file = "autozoom.ts"},["4401"] = {line = 375, file = "autozoom.ts"},["4402"] = {line = 375, file = "autozoom.ts"},["4403"] = {line = 373, file = "autozoom.ts"},["4404"] = {line = 377, file = "autozoom.ts"},["4405"] = {line = 378, file = "autozoom.ts"},["4406"] = {line = 363, file = "autozoom.ts"},["4407"] = {line = 381, file = "autozoom.ts"},["4408"] = {line = 382, file = "autozoom.ts"},["4411"] = {line = 383, file = "autozoom.ts"},["4412"] = {line = 384, file = "autozoom.ts"},["4413"] = {line = 385, file = "autozoom.ts"},["4416"] = {line = 386, file = "autozoom.ts"},["4417"] = {line = 387, file = "autozoom.ts"},["4418"] = {line = 387, file = "autozoom.ts"},["4420"] = {line = 388, file = "autozoom.ts"},["4422"] = {line = 381, file = "autozoom.ts"},["4423"] = {line = 391, file = "autozoom.ts"},["4424"] = {line = 392, file = "autozoom.ts"},["4425"] = {line = 393, file = "autozoom.ts"},["4426"] = {line = 393, file = "autozoom.ts"},["4427"] = {line = 393, file = "autozoom.ts"},["4428"] = {line = 393, file = "autozoom.ts"},["4429"] = {line = 393, file = "autozoom.ts"},["4430"] = {line = 394, file = "autozoom.ts"},["4431"] = {line = 395, file = "autozoom.ts"},["4432"] = {line = 395, file = "autozoom.ts"},["4433"] = {line = 395, file = "autozoom.ts"},["4434"] = {line = 395, file = "autozoom.ts"},["4435"] = {line = 395, file = "autozoom.ts"},["4436"] = {line = 396, file = "autozoom.ts"},["4437"] = {line = 397, file = "autozoom.ts"},["4438"] = {line = 397, file = "autozoom.ts"},["4439"] = {line = 394, file = "autozoom.ts"},["4440"] = {line = 391, file = "autozoom.ts"},["4441"] = {line = 401, file = "autozoom.ts"},["4442"] = {line = 402, file = "autozoom.ts"},["4443"] = {line = 402, file = "autozoom.ts"},["4444"] = {line = 402, file = "autozoom.ts"},["4445"] = {line = 404, file = "autozoom.ts"},["4446"] = {line = 404, file = "autozoom.ts"},["4447"] = {line = 404, file = "autozoom.ts"},["4448"] = {line = 404, file = "autozoom.ts"},["4449"] = {line = 404, file = "autozoom.ts"},["4450"] = {line = 404, file = "autozoom.ts"},["4451"] = {line = 404, file = "autozoom.ts"},["4452"] = {line = 404, file = "autozoom.ts"},["4453"] = {line = 402, file = "autozoom.ts"},["4454"] = {line = 401, file = "autozoom.ts"},["4455"] = {line = 407, file = "autozoom.ts"},["4456"] = {line = 408, file = "autozoom.ts"},["4457"] = {line = 409, file = "autozoom.ts"},["4458"] = {line = 410, file = "autozoom.ts"},["4459"] = {line = 410, file = "autozoom.ts"},["4460"] = {line = 410, file = "autozoom.ts"},["4463"] = {line = 411, file = "autozoom.ts"},["4464"] = {line = 412, file = "autozoom.ts"},["4465"] = {line = 412, file = "autozoom.ts"},["4466"] = {line = 412, file = "autozoom.ts"},["4467"] = {line = 412, file = "autozoom.ts"},["4468"] = {line = 412, file = "autozoom.ts"},["4469"] = {line = 412, file = "autozoom.ts"},["4470"] = {line = 412, file = "autozoom.ts"},["4471"] = {line = 413, file = "autozoom.ts"},["4472"] = {line = 413, file = "autozoom.ts"},["4473"] = {line = 413, file = "autozoom.ts"},["4474"] = {line = 411, file = "autozoom.ts"},["4475"] = {line = 407, file = "autozoom.ts"},["4476"] = {line = 418, file = "autozoom.ts"},["4477"] = {line = 419, file = "autozoom.ts"},["4478"] = {line = 418, file = "autozoom.ts"},["4479"] = {line = 422, file = "autozoom.ts"},["4480"] = {line = 423, file = "autozoom.ts"},["4481"] = {line = 423, file = "autozoom.ts"},["4482"] = {line = 423, file = "autozoom.ts"},["4483"] = {line = 423, file = "autozoom.ts"},["4484"] = {line = 422, file = "autozoom.ts"},["4485"] = {line = 426, file = "autozoom.ts"},["4486"] = {line = 427, file = "autozoom.ts"},["4487"] = {line = 427, file = "autozoom.ts"},["4488"] = {line = 427, file = "autozoom.ts"},["4489"] = {line = 427, file = "autozoom.ts"},["4490"] = {line = 428, file = "autozoom.ts"},["4491"] = {line = 428, file = "autozoom.ts"},["4492"] = {line = 428, file = "autozoom.ts"},["4493"] = {line = 428, file = "autozoom.ts"},["4494"] = {line = 429, file = "autozoom.ts"},["4495"] = {line = 429, file = "autozoom.ts"},["4496"] = {line = 429, file = "autozoom.ts"},["4497"] = {line = 429, file = "autozoom.ts"},["4498"] = {line = 429, file = "autozoom.ts"},["4499"] = {line = 429, file = "autozoom.ts"},["4500"] = {line = 429, file = "autozoom.ts"},["4501"] = {line = 429, file = "autozoom.ts"},["4503"] = {line = 431, file = "autozoom.ts"},["4504"] = {line = 431, file = "autozoom.ts"},["4505"] = {line = 431, file = "autozoom.ts"},["4506"] = {line = 431, file = "autozoom.ts"},["4507"] = {line = 432, file = "autozoom.ts"},["4508"] = {line = 432, file = "autozoom.ts"},["4511"] = {line = 432, file = "autozoom.ts"},["4512"] = {line = 432, file = "autozoom.ts"},["4513"] = {line = 432, file = "autozoom.ts"},["4514"] = {line = 432, file = "autozoom.ts"},["4515"] = {line = 432, file = "autozoom.ts"},["4516"] = {line = 432, file = "autozoom.ts"},["4517"] = {line = 432, file = "autozoom.ts"},["4519"] = {line = 432, file = "autozoom.ts"},["4520"] = {line = 433, file = "autozoom.ts"},["4521"] = {line = 434, file = "autozoom.ts"},["4522"] = {line = 426, file = "autozoom.ts"},["4523"] = {line = 437, file = "autozoom.ts"},["4524"] = {line = 438, file = "autozoom.ts"},["4525"] = {line = 439, file = "autozoom.ts"},["4526"] = {line = 440, file = "autozoom.ts"},["4527"] = {line = 440, file = "autozoom.ts"},["4528"] = {line = 440, file = "autozoom.ts"},["4529"] = {line = 440, file = "autozoom.ts"},["4530"] = {line = 440, file = "autozoom.ts"},["4532"] = {line = 441, file = "autozoom.ts"},["4533"] = {line = 437, file = "autozoom.ts"},["4534"] = {line = 444, file = "autozoom.ts"},["4535"] = {line = 445, file = "autozoom.ts"},["4536"] = {line = 444, file = "autozoom.ts"},["4537"] = {line = 448, file = "autozoom.ts"},["4538"] = {line = 449, file = "autozoom.ts"},["4539"] = {line = 449, file = "autozoom.ts"},["4541"] = {line = 449, file = "autozoom.ts"},["4543"] = {line = 448, file = "autozoom.ts"},["4544"] = {line = 452, file = "autozoom.ts"},["4545"] = {line = 453, file = "autozoom.ts"},["4546"] = {line = 453, file = "autozoom.ts"},["4547"] = {line = 453, file = "autozoom.ts"},["4548"] = {line = 453, file = "autozoom.ts"},["4549"] = {line = 454, file = "autozoom.ts"},["4550"] = {line = 452, file = "autozoom.ts"},["4551"] = {line = 457, file = "autozoom.ts"},["4552"] = {line = 458, file = "autozoom.ts"},["4553"] = {line = 459, file = "autozoom.ts"},["4554"] = {line = 457, file = "autozoom.ts"},["4555"] = {line = 462, file = "autozoom.ts"},["4556"] = {line = 463, file = "autozoom.ts"},["4559"] = {line = 464, file = "autozoom.ts"},["4560"] = {line = 465, file = "autozoom.ts"},["4561"] = {line = 462, file = "autozoom.ts"},["4562"] = {line = 469, file = "autozoom.ts"},["4563"] = {line = 470, file = "autozoom.ts"},["4564"] = {line = 469, file = "autozoom.ts"},["4572"] = {line = 3, file = "main.ts"},["4573"] = {line = 3, file = "main.ts"},["4574"] = {line = 4, file = "main.ts"},["4575"] = {line = 4, file = "main.ts"},["4576"] = {line = 5, file = "main.ts"},["4577"] = {line = 5, file = "main.ts"},["4578"] = {line = 10, file = "main.ts"},["4579"] = {line = 11, file = "main.ts"},["4580"] = {line = 13, file = "main.ts"},["4581"] = {line = 14, file = "main.ts"},["4584"] = {line = 18, file = "main.ts"},["4587"] = {line = 16, file = "main.ts"},["4594"] = {line = 21, file = "main.ts"},["4595"] = {line = 21, file = "main.ts"},["4596"] = {line = 21, file = "main.ts"},["4597"] = {line = 21, file = "main.ts"},["4598"] = {line = 21, file = "main.ts"},["4599"] = {line = 22, file = "main.ts"},["4600"] = {line = 22, file = "main.ts"},["4601"] = {line = 22, file = "main.ts"},["4602"] = {line = 22, file = "main.ts"},["4603"] = {line = 22, file = "main.ts"},["4604"] = {line = 23, file = "main.ts"},["4605"] = {line = 24, file = "main.ts"},["4606"] = {line = 25, file = "main.ts"},["4607"] = {line = 13, file = "main.ts"},["4608"] = {line = 29, file = "main.ts"},["4614"] = {line = 3, file = "exports.ts"},["4615"] = {line = 4, file = "exports.ts"},["4616"] = {line = 5, file = "exports.ts"},["4617"] = {line = 6, file = "exports.ts"},["4618"] = {line = 7, file = "exports.ts"},["4619"] = {line = 8, file = "exports.ts"},["4620"] = {line = 9, file = "exports.ts"},["4621"] = {line = 10, file = "exports.ts"},["4622"] = {line = 11, file = "exports.ts"},["4623"] = {line = 12, file = "exports.ts"},["4624"] = {line = 13, file = "exports.ts"},["4625"] = {line = 14, file = "exports.ts"},["4626"] = {line = 15, file = "exports.ts"},["4627"] = {line = 16, file = "exports.ts"},["4628"] = {line = 17, file = "exports.ts"},["4629"] = {line = 18, file = "exports.ts"},["4630"] = {line = 19, file = "exports.ts"},["4631"] = {line = 21, file = "exports.ts"},["4632"] = {line = 22, file = "exports.ts"},["4633"] = {line = 22, file = "exports.ts"},["4634"] = {line = 22, file = "exports.ts"},["4635"] = {line = 22, file = "exports.ts"},["4636"] = {line = 22, file = "exports.ts"},["4637"] = {line = 22, file = "exports.ts"},["4638"] = {line = 22, file = "exports.ts"},["4639"] = {line = 22, file = "exports.ts"},["4640"] = {line = 22, file = "exports.ts"},["4641"] = {line = 22, file = "exports.ts"},["4642"] = {line = 22, file = "exports.ts"},["4643"] = {line = 22, file = "exports.ts"},["4644"] = {line = 22, file = "exports.ts"},["4645"] = {line = 22, file = "exports.ts"},["4646"] = {line = 22, file = "exports.ts"},["4647"] = {line = 22, file = "exports.ts"},["4648"] = {line = 22, file = "exports.ts"}});
return require("src.main", ...)
