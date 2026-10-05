
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

local function __TS__StringStartsWith(self, searchString, position)
    if position == nil or position < 0 then
        position = 0
    end
    return string.sub(self, position + 1, #searchString + position) == searchString
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

local function __TS__ArrayFind(self, predicate, thisArg)
    for i = 1, #self do
        local elem = self[i]
        if predicate(thisArg, elem, i - 1, self) then
            return elem
        end
    end
    return nil
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

local function __TS__ArraySome(self, callbackfn, thisArg)
    for i = 1, #self do
        if callbackfn(thisArg, self[i], i - 1, self) then
            return true
        end
    end
    return false
end

return {
  __TS__SourceMapTraceBack = __TS__SourceMapTraceBack,
  __TS__StringTrim = __TS__StringTrim,
  __TS__StringStartsWith = __TS__StringStartsWith,
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
  __TS__Iterator = __TS__Iterator,
  __TS__ObjectAssign = __TS__ObjectAssign,
  __TS__ArrayMap = __TS__ArrayMap,
  __TS__ArrayForEach = __TS__ArrayForEach,
  __TS__ArrayFind = __TS__ArrayFind,
  __TS__ArrayFilter = __TS__ArrayFilter,
  __TS__ArrayIndexOf = __TS__ArrayIndexOf,
  __TS__Class = __TS__Class,
  __TS__StringSplit = __TS__StringSplit,
  __TS__StringReplace = __TS__StringReplace,
  __TS__Delete = __TS__Delete,
  __TS__ArraySome = __TS__ArraySome
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
local __TS__StringStartsWith = ____lualib.__TS__StringStartsWith
local __TS__StringSubstring = ____lualib.__TS__StringSubstring
local __TS__StringEndsWith = ____lualib.__TS__StringEndsWith
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
function ____exports.stripAnsi(text)
    local out = string.gsub(text, "%[[%d;]*m", "")
    return out
end
local function normalize(text)
    local t = __TS__StringTrim(____exports.stripAnsi(text))
    if __TS__StringStartsWith(
        string.lower(t),
        "ok:"
    ) then
        t = __TS__StringSubstring(t, 3)
    end
    local collapsed = string.gsub(
        __TS__StringTrim(t),
        "%s+",
        " "
    )
    return string.lower(collapsed)
end
local NOT_A_TAP = {
    "store",
    "delete",
    "copy",
    "move",
    "label",
    "edit",
    "update",
    "assign",
    "attribute"
}
function ____exports.undoMatches(undoName, command)
    if undoName == nil then
        return false
    end
    local undo = normalize(undoName)
    local cmd = normalize(command)
    if cmd == "" or undo == "" then
        return false
    end
    for ____, verb in ipairs(NOT_A_TAP) do
        if __TS__StringStartsWith(undo, verb) then
            return false
        end
    end
    return undo == cmd or __TS__StringEndsWith(undo, " " .. cmd)
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
____exports.CONFIG_KEY = "AutoZoom.config"
____exports.INSTANCE_KEY = "AutoZoom.instance"
local UNREADABLE = "Saved AutoZoom settings were unreadable; defaults restored"
function ____exports.defaultConfig()
    return {
        disarmed = {},
        size = {},
        range = {0.5, 5},
        rate = 30,
        offset = {source = "values", preset = "", values = {0, 0, 0}}
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
    return {config = config}
end
function ____exports.serializeConfig(c)
    return encode({
        v = 1,
        disarmed = c.disarmed,
        size = c.size,
        range = c.range,
        rate = c.rate,
        offset = c.offset
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
local __TS__ArrayFind = ____lualib.__TS__ArrayFind
local __TS__SourceMapTraceBack = ____lualib.__TS__SourceMapTraceBack
local ____exports = {}
local ____format = require("src.format")
local fidKey = ____format.fidKey
local fmtInt = ____format.fmtInt
local fmtNum = ____format.fmtNum
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
local LABELS = {
    offline = "Offline",
    disarmed = "Disarmed",
    ["no-marker"] = "Armed · no marker",
    ["unknown-marker"] = "Unknown marker",
    ["no-psn"] = "No PSN data",
    tracking = "Tracking",
    ["too-wide"] = "Too wide",
    ["too-small"] = "Too small"
}
function ____exports.stateLabel(state)
    return LABELS[state]
end
local function signed(n)
    return (n >= 0 and "+" or "") .. fmtNum(n)
end
function ____exports.layoutCells(fixtures, markers)
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
        fixtures,
        function(____, f, row)
            local y = ____exports.Y_DIR * step * (row + 2)
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
                    local ____temp_1 = #cells + 1
                    cells[____temp_1] = {
                        key = (("mx " .. fid) .. " ") .. fmtInt(m.cid),
                        x = markerX(i),
                        y = y,
                        w = ____exports.GRID.markerW,
                        h = ____exports.GRID.h,
                        command = ((("Program(" .. fid) .. ",") .. fmtInt(m.cid)) .. ")"
                    }
                    return ____temp_1
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
local function stateColor(state)
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
local function stateAppearance(state)
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
    if header.pickSecondsLeft ~= nil then
        cell(
            "message",
            ("Tap a preset…  " .. fmtInt(header.pickSecondsLeft)) .. " s",
            "capture",
            ____exports.COLORS.accent,
            ____exports.COLORS.accent
        )
    else
        cell(
            "message",
            header.message,
            "header",
            ____exports.COLORS.idle,
            ____exports.COLORS.muted
        )
    end
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
    for ____, r in ipairs(rows) do
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
                local color = (s == "tracking" or s == "too-wide" or s == "too-small") and ____exports.COLORS.on or (s == "no-psn" and ____exports.COLORS.accent or ____exports.COLORS.muted)
                cell(
                    key,
                    "●",
                    (s == "tracking" or s == "too-wide" or s == "too-small") and "tracking" or (s == "no-psn" and "nopsn" or "idle"),
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
        commands = {{value = 1, name = "Save"}, {value = 2, name = "Pick preset…"}, {value = 0, name = "Cancel"}},
        inputs = __TS__ArrayMap(
            INPUTS,
            function(____, name, i) return {name = name, value = values[i + 1]} end
        ),
        selectors = {{name = "Offset source", selectedValue = c.offset.source == "preset" and 1 or 2, values = {Preset = 1, Values = 2}}}
    })
    if r == nil or r.result ~= 1 and r.result ~= 2 then
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
    local ____temp_7 = r.result == 2
    local ____opt_5 = r.selectors
    if ____opt_5 ~= nil then
        ____opt_5 = ____opt_5["Offset source"]
    end
    return {
        pick = ____temp_7,
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
["src.console.undo"] = function(...) 
local ____lualib = require("lualib_bundle")
local __TS__SourceMapTraceBack = ____lualib.__TS__SourceMapTraceBack
local ____exports = {}
local ____preset_2Dref = require("src.engine.preset-ref")
local stripAnsi = ____preset_2Dref.stripAnsi
local ____log = require("src.console.log")
local info = ____log.info
function ____exports.lastCommand()
    local o = CmdObj()
    local v = o.LastCommand
    local ____temp_0
    if v == nil then
        ____temp_0 = nil
    else
        ____temp_0 = tostring(v)
    end
    return ____temp_0
end
function ____exports.topUndoName()
    local o = CmdObj()
    local undos = o.Undos
    if undos == nil then
        return nil
    end
    local entry = undos[undos.UndoIndex + 1]
    local ____temp_1
    if entry == nil or entry.Name == nil then
        ____temp_1 = nil
    else
        ____temp_1 = tostring(entry.Name)
    end
    return ____temp_1
end
function ____exports.undoMark()
    local o = CmdObj()
    local undos = o.Undos
    if undos == nil then
        return "||"
    end
    local count = ""
    do
        local function ____catch(e)
            count = ""
        end
        local ____try, ____hasReturned = pcall(function()
            local c = undos:Count()
            if c ~= nil then
                count = tostring(c)
            end
        end)
        if not ____try then
            ____catch(____hasReturned)
        end
    end
    local name = ____exports.topUndoName()
    local ____tostring_3 = tostring
    local ____undos_UndoIndex_2 = undos.UndoIndex
    if ____undos_UndoIndex_2 == nil then
        ____undos_UndoIndex_2 = ""
    end
    return (((____tostring_3(____undos_UndoIndex_2) .. "|") .. count) .. "|") .. (name == nil and "" or stripAnsi(name))
end
function ____exports.undoProgrammer()
    local profile = CurrentProfile()
    local saved = profile.OopsProgrammer
    profile.OopsProgrammer = true
    do
        local function ____catch(e)
            info("Oops failed: " .. tostring(e))
        end
        local ____try, ____hasReturned = pcall(function()
            Cmd("Oops /nc")
        end)
        if not ____try then
            ____catch(____hasReturned)
        end
        do
            profile.OopsProgrammer = saved
        end
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
local ui = require("src.console.ui")
local undo = require("src.console.undo")
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
function MaDesk.prototype.lastCommand(self)
    return undo.lastCommand()
end
function MaDesk.prototype.topUndoName(self)
    return undo.topUndoName()
end
function MaDesk.prototype.undoMark(self)
    return undo.undoMark()
end
function MaDesk.prototype.undoProgrammer(self)
    undo.undoProgrammer()
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
local __TS__SourceMapTraceBack = ____lualib.__TS__SourceMapTraceBack
local ____exports = {}
local ____format = require("src.format")
local fmtInt = ____format.fmtInt
local fmtNum = ____format.fmtNum
function ____exports.programCommands(fid, cid, offset)
    local cmds = {
        "Fixture " .. fmtInt(fid),
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
function ____exports.releaseCommands(fid)
    return {"Off Fixture " .. fmtInt(fid)}
end
return ____exports
 end,
["src.runtime.autozoom"] = function(...) 
local ____lualib = require("lualib_bundle")
local __TS__Class = ____lualib.__TS__Class
local __TS__ArrayFilter = ____lualib.__TS__ArrayFilter
local __TS__ArrayMap = ____lualib.__TS__ArrayMap
local __TS__StringTrim = ____lualib.__TS__StringTrim
local __TS__StringReplace = ____lualib.__TS__StringReplace
local __TS__Delete = ____lualib.__TS__Delete
local __TS__Number = ____lualib.__TS__Number
local __TS__ObjectAssign = ____lualib.__TS__ObjectAssign
local __TS__ArraySome = ____lualib.__TS__ArraySome
local __TS__ArrayIndexOf = ____lualib.__TS__ArrayIndexOf
local __TS__ArrayFind = ____lualib.__TS__ArrayFind
local __TS__New = ____lualib.__TS__New
local __TS__SourceMapTraceBack = ____lualib.__TS__SourceMapTraceBack
local ____exports = {}
local ____arm_2Dcommand = require("src.engine.arm-command")
local normalizeFids = ____arm_2Dcommand.normalizeFids
local parseArmList = ____arm_2Dcommand.parseArmList
local ____preset_2Dref = require("src.engine.preset-ref")
local parsePresetCommand = ____preset_2Dref.parsePresetCommand
local undoMatches = ____preset_2Dref.undoMatches
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
____exports.PICK_SECONDS = 10
____exports.AutoZoom = __TS__Class()
local AutoZoom = ____exports.AutoZoom
AutoZoom.name = "AutoZoom"
function AutoZoom.prototype.____constructor(self, desk, id)
    self.desk = desk
    self.id = id
    self.config = defaultConfig()
    self.scanned = {fixtures = {}, markers = {}, problems = {}}
    self.running = false
    self.message = ""
    self.pickIgnored = {}
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
    local next = self.desk:scan()
    local kept = {}
    for ____, f in ipairs(next.fixtures) do
        kept[fidKey(f.fid)] = true
    end
    self:releaseAll(__TS__ArrayFilter(
        old,
        function(____, f) return not kept[fidKey(f.fid)] end
    ))
    self.scanned = next
    for ____, p in ipairs(self.scanned.problems) do
        self.desk:log(p)
    end
    self.config = pruneConfig(
        self.config,
        __TS__ArrayMap(
            self.scanned.fixtures,
            function(____, f) return f.fid end
        )
    )
    self.desk:install(self.scanned)
    self.desk:buildLayout(layoutCells(self.scanned.fixtures, self.scanned.markers))
    self.sent = {}
    self.results = {}
    self.desk:log(((("Found " .. fmtInt(#self.scanned.fixtures)) .. " fixtures and ") .. fmtInt(#self.scanned.markers)) .. " markers")
    self:update()
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
    local ____self_0, ____loopGen_1 = self, "loopGen"
    local ____self_loopGen_2 = ____self_0[____loopGen_1] + 1
    ____self_0[____loopGen_1] = ____self_loopGen_2
    local gen = ____self_loopGen_2
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
    if self.pickUntil ~= nil then
        self:endPick("Preset pick cancelled")
    end
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
    for ____, f in ipairs(self.scanned.fixtures) do
        local r = self.results[fidKey(f.fid)]
        self.desk:log((((("  " .. fmtInt(f.fid)) .. " ") .. f.name) .. ": ") .. (r == nil and "-" or stateLabel(r.state)))
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
        self.desk:runCommands(releaseCommands(fid))
    else
        self.desk:runCommands(programCommands(fid, cid, self.config.offset))
    end
    if self.pickUntil ~= nil then
        self.pickBaseline = self.desk:lastCommand()
        self.pickUndoMark = self.desk:undoMark()
    end
    self:update()
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
        if answers.pick then
            self.pickUntil = nil
            self.pickBaseline = nil
            self.pickUndoMark = nil
            self:startPick()
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
                goto __continue82
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
        ::__continue82::
    end
end
function AutoZoom.prototype.update(self)
    self:beforeUpdate()
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
    if self.pickUntil ~= nil then
        self:endPick("Preset pick cancelled")
        return
    end
    self:startPick()
end
function AutoZoom.prototype.startPick(self)
    if not self.running then
        self:say("Start AutoZoom to pick a preset")
        return
    end
    self.pickBaseline = self.desk:lastCommand()
    self.pickUndoMark = self.desk:undoMark()
    self.pickIgnored = {}
    self.pickUntil = self.desk:now() + ____exports.PICK_SECONDS
    self.message = "Tap the preset that holds the XYZ offset"
    self:update()
end
function AutoZoom.prototype.updatePick(self)
    if self.pickUntil == nil then
        return
    end
    if self.desk:now() > self.pickUntil then
        self:endPick("Preset pick timed out")
        return
    end
    local cmd = self.desk:lastCommand()
    if cmd == nil or cmd == self.pickBaseline then
        return
    end
    local preset = parsePresetCommand(cmd)
    if preset == nil then
        local named = string.find(
            string.lower(cmd),
            "preset",
            1,
            true
        )
        if named ~= nil and not self.pickIgnored[cmd] then
            self.pickIgnored[cmd] = true
            self.desk:log(("Preset pick ignored \"" .. cmd) .. "\"")
        end
        return
    end
    local undoName = self.desk:topUndoName()
    self.desk:log(((("Preset pick saw \"" .. cmd) .. "\", undo entry \"") .. (undoName or "")) .. "\"")
    self.config.offset = __TS__ObjectAssign({}, self.config.offset, {source = "preset", preset = preset})
    self:markDirty()
    if self.desk:undoMark() ~= self.pickUndoMark and undoMatches(undoName, cmd) then
        self.desk:undoProgrammer()
    end
    self:endPick("Offset preset " .. preset)
end
function AutoZoom.prototype.endPick(self, message)
    self.pickUntil = nil
    self.pickBaseline = nil
    self.pickUndoMark = nil
    self:say(message)
end
function AutoZoom.prototype.beforeUpdate(self)
    do
        local function ____catch(e)
            self:endPick("Preset pick failed: " .. tostring(e))
        end
        local ____try, ____hasReturned = pcall(function()
            self:updatePick()
        end)
        if not ____try then
            ____catch(____hasReturned)
        end
    end
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
function AutoZoom.prototype.render(self, markers, globalSize)
    local rows = {}
    for ____, f in ipairs(self.scanned.fixtures) do
        local key = fidKey(f.fid)
        local live = self.live[key] or ({
            cid = 0,
            programmerCid = 0,
            offset = vec(0, 0, 0)
        })
        rows[#rows + 1] = {
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
    local liveMarkers = 0
    for ____, m in ipairs(self.scanned.markers) do
        if markers[fidKey(m.cid)] ~= nil then
            liveMarkers = liveMarkers + 1
        end
    end
    local ____temp_3
    if self.pickUntil == nil then
        ____temp_3 = nil
    else
        ____temp_3 = math.max(
            0,
            math.ceil(self.pickUntil - self.desk:now())
        )
    end
    local pickLeft = ____temp_3
    self.desk:refreshLayout(buildViews(
        {
            running = self.running,
            pickSecondsLeft = pickLeft,
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
    self.config.disarmed = __TS__ArrayFilter(
        __TS__ArrayMap(
            self.scanned.fixtures,
            function(____, f) return f.fid end
        ),
        function(____, fid) return __TS__ArrayIndexOf(known, fid) < 0 end
    )
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
    Printf("[AZ] AutoZoom 2.0.0.3 by Naostage")
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
____exports.ready = true
____exports.format = format
____exports.json = json
____exports.config = config
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
return ____exports
 end,
}
local __TS__SourceMapTraceBack = require("lualib_bundle").__TS__SourceMapTraceBack
__TS__SourceMapTraceBack(debug.getinfo(1).short_src, {["562"] = {line = 5, file = "vec.ts"},["563"] = {line = 6, file = "vec.ts"},["564"] = {line = 5, file = "vec.ts"},["565"] = {line = 9, file = "vec.ts"},["566"] = {line = 10, file = "vec.ts"},["567"] = {line = 9, file = "vec.ts"},["568"] = {line = 13, file = "vec.ts"},["569"] = {line = 14, file = "vec.ts"},["570"] = {line = 14, file = "vec.ts"},["571"] = {line = 14, file = "vec.ts"},["572"] = {line = 15, file = "vec.ts"},["573"] = {line = 13, file = "vec.ts"},["574"] = {line = 19, file = "vec.ts"},["575"] = {line = 20, file = "vec.ts"},["576"] = {line = 20, file = "vec.ts"},["577"] = {line = 20, file = "vec.ts"},["578"] = {line = 21, file = "vec.ts"},["579"] = {line = 21, file = "vec.ts"},["580"] = {line = 21, file = "vec.ts"},["581"] = {line = 22, file = "vec.ts"},["582"] = {line = 22, file = "vec.ts"},["583"] = {line = 22, file = "vec.ts"},["584"] = {line = 23, file = "vec.ts"},["585"] = {line = 23, file = "vec.ts"},["586"] = {line = 23, file = "vec.ts"},["587"] = {line = 24, file = "vec.ts"},["588"] = {line = 24, file = "vec.ts"},["589"] = {line = 24, file = "vec.ts"},["590"] = {line = 25, file = "vec.ts"},["591"] = {line = 19, file = "vec.ts"},["598"] = {line = 10, file = "beam.ts"},["599"] = {line = 11, file = "beam.ts"},["600"] = {line = 11, file = "beam.ts"},["602"] = {line = 12, file = "beam.ts"},["603"] = {line = 13, file = "beam.ts"},["604"] = {line = 13, file = "beam.ts"},["605"] = {line = 13, file = "beam.ts"},["606"] = {line = 13, file = "beam.ts"},["607"] = {line = 10, file = "beam.ts"},["608"] = {line = 16, file = "beam.ts"},["609"] = {line = 17, file = "beam.ts"},["610"] = {line = 16, file = "beam.ts"},["611"] = {line = 20, file = "beam.ts"},["612"] = {line = 21, file = "beam.ts"},["613"] = {line = 22, file = "beam.ts"},["614"] = {line = 23, file = "beam.ts"},["615"] = {line = 23, file = "beam.ts"},["617"] = {line = 24, file = "beam.ts"},["618"] = {line = 25, file = "beam.ts"},["619"] = {line = 25, file = "beam.ts"},["620"] = {line = 25, file = "beam.ts"},["621"] = {line = 25, file = "beam.ts"},["622"] = {line = 25, file = "beam.ts"},["623"] = {line = 25, file = "beam.ts"},["624"] = {line = 25, file = "beam.ts"},["626"] = {line = 26, file = "beam.ts"},["627"] = {line = 26, file = "beam.ts"},["628"] = {line = 26, file = "beam.ts"},["629"] = {line = 26, file = "beam.ts"},["630"] = {line = 26, file = "beam.ts"},["631"] = {line = 26, file = "beam.ts"},["632"] = {line = 26, file = "beam.ts"},["634"] = {line = 27, file = "beam.ts"},["635"] = {line = 28, file = "beam.ts"},["636"] = {line = 28, file = "beam.ts"},["638"] = {line = 29, file = "beam.ts"},["639"] = {line = 30, file = "beam.ts"},["640"] = {line = 30, file = "beam.ts"},["642"] = {line = 31, file = "beam.ts"},["643"] = {line = 31, file = "beam.ts"},["644"] = {line = 31, file = "beam.ts"},["645"] = {line = 31, file = "beam.ts"},["646"] = {line = 31, file = "beam.ts"},["647"] = {line = 31, file = "beam.ts"},["648"] = {line = 20, file = "beam.ts"},["667"] = {line = 6, file = "preset-ref.ts"},["668"] = {line = 7, file = "preset-ref.ts"},["669"] = {line = 8, file = "preset-ref.ts"},["670"] = {line = 9, file = "preset-ref.ts"},["671"] = {line = 10, file = "preset-ref.ts"},["672"] = {line = 11, file = "preset-ref.ts"},["673"] = {line = 12, file = "preset-ref.ts"},["674"] = {line = 13, file = "preset-ref.ts"},["675"] = {line = 13, file = "preset-ref.ts"},["677"] = {line = 14, file = "preset-ref.ts"},["678"] = {line = 15, file = "preset-ref.ts"},["679"] = {line = 15, file = "preset-ref.ts"},["681"] = {line = 16, file = "preset-ref.ts"},["682"] = {line = 6, file = "preset-ref.ts"},["683"] = {line = 19, file = "preset-ref.ts"},["684"] = {line = 20, file = "preset-ref.ts"},["685"] = {line = 21, file = "preset-ref.ts"},["686"] = {line = 19, file = "preset-ref.ts"},["687"] = {line = 24, file = "preset-ref.ts"},["688"] = {line = 25, file = "preset-ref.ts"},["689"] = {line = 26, file = "preset-ref.ts"},["690"] = {line = 26, file = "preset-ref.ts"},["691"] = {line = 26, file = "preset-ref.ts"},["692"] = {line = 26, file = "preset-ref.ts"},["693"] = {line = 26, file = "preset-ref.ts"},["695"] = {line = 27, file = "preset-ref.ts"},["696"] = {line = 27, file = "preset-ref.ts"},["697"] = {line = 27, file = "preset-ref.ts"},["698"] = {line = 27, file = "preset-ref.ts"},["699"] = {line = 27, file = "preset-ref.ts"},["700"] = {line = 28, file = "preset-ref.ts"},["701"] = {line = 24, file = "preset-ref.ts"},["702"] = {line = 31, file = "preset-ref.ts"},["703"] = {line = 31, file = "preset-ref.ts"},["704"] = {line = 31, file = "preset-ref.ts"},["705"] = {line = 31, file = "preset-ref.ts"},["706"] = {line = 31, file = "preset-ref.ts"},["707"] = {line = 31, file = "preset-ref.ts"},["708"] = {line = 31, file = "preset-ref.ts"},["709"] = {line = 31, file = "preset-ref.ts"},["710"] = {line = 31, file = "preset-ref.ts"},["711"] = {line = 31, file = "preset-ref.ts"},["712"] = {line = 31, file = "preset-ref.ts"},["713"] = {line = 35, file = "preset-ref.ts"},["714"] = {line = 36, file = "preset-ref.ts"},["715"] = {line = 36, file = "preset-ref.ts"},["717"] = {line = 37, file = "preset-ref.ts"},["718"] = {line = 38, file = "preset-ref.ts"},["719"] = {line = 39, file = "preset-ref.ts"},["720"] = {line = 39, file = "preset-ref.ts"},["722"] = {line = 40, file = "preset-ref.ts"},["723"] = {line = 40, file = "preset-ref.ts"},["724"] = {line = 40, file = "preset-ref.ts"},["727"] = {line = 41, file = "preset-ref.ts"},["728"] = {line = 35, file = "preset-ref.ts"},["739"] = {line = 4, file = "format.ts"},["740"] = {line = 5, file = "format.ts"},["741"] = {line = 5, file = "format.ts"},["742"] = {line = 5, file = "format.ts"},["743"] = {line = 5, file = "format.ts"},["744"] = {line = 4, file = "format.ts"},["745"] = {line = 8, file = "format.ts"},["746"] = {line = 9, file = "format.ts"},["747"] = {line = 10, file = "format.ts"},["748"] = {line = 10, file = "format.ts"},["750"] = {line = 11, file = "format.ts"},["751"] = {line = 11, file = "format.ts"},["753"] = {line = 12, file = "format.ts"},["754"] = {line = 8, file = "format.ts"},["755"] = {line = 15, file = "format.ts"},["756"] = {line = 16, file = "format.ts"},["757"] = {line = 15, file = "format.ts"},["776"] = {line = 27, file = "json.ts"},["777"] = {line = 27, file = "json.ts"},["778"] = {line = 28, file = "json.ts"},["780"] = {line = 29, file = "json.ts"},["781"] = {line = 29, file = "json.ts"},["782"] = {line = 30, file = "json.ts"},["783"] = {line = 31, file = "json.ts"},["784"] = {line = 31, file = "json.ts"},["785"] = {line = 32, file = "json.ts"},["786"] = {line = 32, file = "json.ts"},["787"] = {line = 33, file = "json.ts"},["788"] = {line = 33, file = "json.ts"},["789"] = {line = 34, file = "json.ts"},["790"] = {line = 34, file = "json.ts"},["791"] = {line = 35, file = "json.ts"},["792"] = {line = 35, file = "json.ts"},["794"] = {line = 36, file = "json.ts"},["796"] = {line = 29, file = "json.ts"},["799"] = {line = 38, file = "json.ts"},["801"] = {line = 51, file = "json.ts"},["802"] = {line = 52, file = "json.ts"},["803"] = {line = 53, file = "json.ts"},["804"] = {line = 54, file = "json.ts"},["807"] = {line = 55, file = "json.ts"},["810"] = {line = 59, file = "json.ts"},["811"] = {line = 60, file = "json.ts"},["813"] = {line = 60, file = "json.ts"},["814"] = {line = 60, file = "json.ts"},["815"] = {line = 60, file = "json.ts"},["816"] = {line = 60, file = "json.ts"},["820"] = {line = 61, file = "json.ts"},["822"] = {line = 64, file = "json.ts"},["823"] = {line = 65, file = "json.ts"},["824"] = {line = 66, file = "json.ts"},["825"] = {line = 67, file = "json.ts"},["826"] = {line = 67, file = "json.ts"},["828"] = {line = 68, file = "json.ts"},["829"] = {line = 68, file = "json.ts"},["831"] = {line = 69, file = "json.ts"},["832"] = {line = 69, file = "json.ts"},["834"] = {line = 70, file = "json.ts"},["835"] = {line = 70, file = "json.ts"},["836"] = {line = 70, file = "json.ts"},["838"] = {line = 71, file = "json.ts"},["839"] = {line = 71, file = "json.ts"},["840"] = {line = 71, file = "json.ts"},["842"] = {line = 72, file = "json.ts"},["843"] = {line = 72, file = "json.ts"},["844"] = {line = 72, file = "json.ts"},["846"] = {line = 73, file = "json.ts"},["848"] = {line = 76, file = "json.ts"},["849"] = {line = 77, file = "json.ts"},["850"] = {line = 78, file = "json.ts"},["851"] = {line = 78, file = "json.ts"},["852"] = {line = 78, file = "json.ts"},["853"] = {line = 78, file = "json.ts"},["854"] = {line = 78, file = "json.ts"},["855"] = {line = 78, file = "json.ts"},["856"] = {line = 78, file = "json.ts"},["858"] = {line = 79, file = "json.ts"},["860"] = {line = 79, file = "json.ts"},["861"] = {line = 79, file = "json.ts"},["862"] = {line = 79, file = "json.ts"},["863"] = {line = 79, file = "json.ts"},["867"] = {line = 80, file = "json.ts"},["868"] = {line = 81, file = "json.ts"},["870"] = {line = 81, file = "json.ts"},["871"] = {line = 81, file = "json.ts"},["872"] = {line = 81, file = "json.ts"},["873"] = {line = 81, file = "json.ts"},["877"] = {line = 82, file = "json.ts"},["879"] = {line = 85, file = "json.ts"},["880"] = {line = 86, file = "json.ts"},["881"] = {line = 87, file = "json.ts"},["882"] = {line = 88, file = "json.ts"},["883"] = {line = 89, file = "json.ts"},["884"] = {line = 90, file = "json.ts"},["885"] = {line = 91, file = "json.ts"},["886"] = {line = 91, file = "json.ts"},["888"] = {line = 92, file = "json.ts"},["889"] = {line = 93, file = "json.ts"},["890"] = {line = 94, file = "json.ts"},["891"] = {line = 95, file = "json.ts"},["892"] = {line = 95, file = "json.ts"},["893"] = {line = 96, file = "json.ts"},["894"] = {line = 96, file = "json.ts"},["895"] = {line = 97, file = "json.ts"},["896"] = {line = 97, file = "json.ts"},["898"] = {line = 98, file = "json.ts"},["901"] = {line = 100, file = "json.ts"},["905"] = {line = 103, file = "json.ts"},["909"] = {line = 106, file = "json.ts"},["910"] = {line = 107, file = "json.ts"},["911"] = {line = 108, file = "json.ts"},["912"] = {line = 109, file = "json.ts"},["913"] = {line = 110, file = "json.ts"},["914"] = {line = 110, file = "json.ts"},["915"] = {line = 110, file = "json.ts"},["917"] = {line = 111, file = "json.ts"},["918"] = {line = 112, file = "json.ts"},["919"] = {line = 113, file = "json.ts"},["920"] = {line = 114, file = "json.ts"},["921"] = {line = 115, file = "json.ts"},["922"] = {line = 116, file = "json.ts"},["923"] = {line = 116, file = "json.ts"},["925"] = {line = 117, file = "json.ts"},["927"] = {line = 117, file = "json.ts"},["928"] = {line = 117, file = "json.ts"},["929"] = {line = 117, file = "json.ts"},["930"] = {line = 117, file = "json.ts"},["936"] = {line = 121, file = "json.ts"},["937"] = {line = 122, file = "json.ts"},["938"] = {line = 123, file = "json.ts"},["939"] = {line = 124, file = "json.ts"},["940"] = {line = 125, file = "json.ts"},["941"] = {line = 125, file = "json.ts"},["942"] = {line = 125, file = "json.ts"},["944"] = {line = 126, file = "json.ts"},["945"] = {line = 127, file = "json.ts"},["946"] = {line = 128, file = "json.ts"},["948"] = {line = 128, file = "json.ts"},["949"] = {line = 128, file = "json.ts"},["950"] = {line = 128, file = "json.ts"},["951"] = {line = 128, file = "json.ts"},["955"] = {line = 129, file = "json.ts"},["956"] = {line = 130, file = "json.ts"},["957"] = {line = 131, file = "json.ts"},["959"] = {line = 131, file = "json.ts"},["960"] = {line = 131, file = "json.ts"},["961"] = {line = 131, file = "json.ts"},["962"] = {line = 131, file = "json.ts"},["966"] = {line = 132, file = "json.ts"},["967"] = {line = 133, file = "json.ts"},["968"] = {line = 134, file = "json.ts"},["969"] = {line = 134, file = "json.ts"},["971"] = {line = 135, file = "json.ts"},["972"] = {line = 136, file = "json.ts"},["973"] = {line = 137, file = "json.ts"},["974"] = {line = 138, file = "json.ts"},["975"] = {line = 138, file = "json.ts"},["977"] = {line = 139, file = "json.ts"},["979"] = {line = 139, file = "json.ts"},["980"] = {line = 139, file = "json.ts"},["981"] = {line = 139, file = "json.ts"},["982"] = {line = 139, file = "json.ts"},["990"] = {line = 5, file = "json.ts"},["991"] = {line = 6, file = "json.ts"},["992"] = {line = 6, file = "json.ts"},["994"] = {line = 7, file = "json.ts"},["995"] = {line = 7, file = "json.ts"},["997"] = {line = 8, file = "json.ts"},["998"] = {line = 9, file = "json.ts"},["999"] = {line = 9, file = "json.ts"},["1001"] = {line = 10, file = "json.ts"},["1003"] = {line = 12, file = "json.ts"},["1004"] = {line = 12, file = "json.ts"},["1006"] = {line = 13, file = "json.ts"},["1007"] = {line = 14, file = "json.ts"},["1008"] = {line = 15, file = "json.ts"},["1009"] = {line = 15, file = "json.ts"},["1011"] = {line = 16, file = "json.ts"},["1013"] = {line = 18, file = "json.ts"},["1014"] = {line = 19, file = "json.ts"},["1015"] = {line = 20, file = "json.ts"},["1016"] = {line = 20, file = "json.ts"},["1018"] = {line = 21, file = "json.ts"},["1019"] = {line = 22, file = "json.ts"},["1020"] = {line = 23, file = "json.ts"},["1021"] = {line = 23, file = "json.ts"},["1023"] = {line = 24, file = "json.ts"},["1024"] = {line = 5, file = "json.ts"},["1025"] = {line = 43, file = "json.ts"},["1026"] = {line = 44, file = "json.ts"},["1027"] = {line = 45, file = "json.ts"},["1028"] = {line = 46, file = "json.ts"},["1029"] = {line = 47, file = "json.ts"},["1031"] = {line = 47, file = "json.ts"},["1032"] = {line = 47, file = "json.ts"},["1033"] = {line = 47, file = "json.ts"},["1034"] = {line = 47, file = "json.ts"},["1038"] = {line = 48, file = "json.ts"},["1039"] = {line = 43, file = "json.ts"},["1052"] = {line = 2, file = "config.ts"},["1053"] = {line = 2, file = "config.ts"},["1054"] = {line = 3, file = "config.ts"},["1055"] = {line = 3, file = "config.ts"},["1056"] = {line = 3, file = "config.ts"},["1057"] = {line = 4, file = "config.ts"},["1058"] = {line = 4, file = "config.ts"},["1059"] = {line = 4, file = "config.ts"},["1060"] = {line = 16, file = "config.ts"},["1061"] = {line = 17, file = "config.ts"},["1062"] = {line = 18, file = "config.ts"},["1063"] = {line = 20, file = "config.ts"},["1064"] = {line = 21, file = "config.ts"},["1065"] = {line = 21, file = "config.ts"},["1066"] = {line = 21, file = "config.ts"},["1067"] = {line = 21, file = "config.ts"},["1068"] = {line = 21, file = "config.ts"},["1069"] = {line = 21, file = "config.ts"},["1070"] = {line = 21, file = "config.ts"},["1071"] = {line = 20, file = "config.ts"},["1072"] = {line = 24, file = "config.ts"},["1073"] = {line = 25, file = "config.ts"},["1074"] = {line = 24, file = "config.ts"},["1075"] = {line = 28, file = "config.ts"},["1076"] = {line = 29, file = "config.ts"},["1077"] = {line = 30, file = "config.ts"},["1078"] = {line = 30, file = "config.ts"},["1080"] = {line = 31, file = "config.ts"},["1083"] = {line = 35, file = "config.ts"},["1086"] = {line = 33, file = "config.ts"},["1092"] = {line = 32, file = "config.ts"},["1095"] = {line = 37, file = "config.ts"},["1096"] = {line = 37, file = "config.ts"},["1098"] = {line = 38, file = "config.ts"},["1099"] = {line = 39, file = "config.ts"},["1100"] = {line = 39, file = "config.ts"},["1101"] = {line = 39, file = "config.ts"},["1102"] = {line = 39, file = "config.ts"},["1106"] = {line = 41, file = "config.ts"},["1107"] = {line = 42, file = "config.ts"},["1108"] = {line = 43, file = "config.ts"},["1109"] = {line = 44, file = "config.ts"},["1110"] = {line = 44, file = "config.ts"},["1114"] = {line = 47, file = "config.ts"},["1115"] = {line = 48, file = "config.ts"},["1116"] = {line = 48, file = "config.ts"},["1117"] = {line = 49, file = "config.ts"},["1118"] = {line = 49, file = "config.ts"},["1121"] = {line = 51, file = "config.ts"},["1122"] = {line = 52, file = "config.ts"},["1123"] = {line = 52, file = "config.ts"},["1125"] = {line = 53, file = "config.ts"},["1126"] = {line = 54, file = "config.ts"},["1127"] = {line = 55, file = "config.ts"},["1128"] = {line = 55, file = "config.ts"},["1130"] = {line = 56, file = "config.ts"},["1131"] = {line = 56, file = "config.ts"},["1133"] = {line = 57, file = "config.ts"},["1134"] = {line = 58, file = "config.ts"},["1135"] = {line = 58, file = "config.ts"},["1136"] = {line = 58, file = "config.ts"},["1137"] = {line = 58, file = "config.ts"},["1138"] = {line = 58, file = "config.ts"},["1141"] = {line = 61, file = "config.ts"},["1142"] = {line = 28, file = "config.ts"},["1143"] = {line = 64, file = "config.ts"},["1144"] = {line = 65, file = "config.ts"},["1145"] = {line = 65, file = "config.ts"},["1146"] = {line = 65, file = "config.ts"},["1147"] = {line = 65, file = "config.ts"},["1148"] = {line = 65, file = "config.ts"},["1149"] = {line = 65, file = "config.ts"},["1150"] = {line = 65, file = "config.ts"},["1151"] = {line = 65, file = "config.ts"},["1152"] = {line = 64, file = "config.ts"},["1153"] = {line = 68, file = "config.ts"},["1154"] = {line = 69, file = "config.ts"},["1155"] = {line = 70, file = "config.ts"},["1156"] = {line = 70, file = "config.ts"},["1158"] = {line = 71, file = "config.ts"},["1159"] = {line = 72, file = "config.ts"},["1160"] = {line = 72, file = "config.ts"},["1161"] = {line = 72, file = "config.ts"},["1164"] = {line = 75, file = "config.ts"},["1165"] = {line = 68, file = "config.ts"},["1166"] = {line = 81, file = "config.ts"},["1167"] = {line = 82, file = "config.ts"},["1168"] = {line = 83, file = "config.ts"},["1169"] = {line = 83, file = "config.ts"},["1170"] = {line = 83, file = "config.ts"},["1171"] = {line = 83, file = "config.ts"},["1172"] = {line = 83, file = "config.ts"},["1173"] = {line = 83, file = "config.ts"},["1174"] = {line = 83, file = "config.ts"},["1175"] = {line = 83, file = "config.ts"},["1176"] = {line = 83, file = "config.ts"},["1177"] = {line = 83, file = "config.ts"},["1178"] = {line = 83, file = "config.ts"},["1179"] = {line = 83, file = "config.ts"},["1180"] = {line = 84, file = "config.ts"},["1181"] = {line = 85, file = "config.ts"},["1182"] = {line = 86, file = "config.ts"},["1183"] = {line = 86, file = "config.ts"},["1184"] = {line = 86, file = "config.ts"},["1186"] = {line = 87, file = "config.ts"},["1187"] = {line = 84, file = "config.ts"},["1188"] = {line = 89, file = "config.ts"},["1189"] = {line = 89, file = "config.ts"},["1190"] = {line = 89, file = "config.ts"},["1191"] = {line = 90, file = "config.ts"},["1192"] = {line = 90, file = "config.ts"},["1194"] = {line = 91, file = "config.ts"},["1195"] = {line = 91, file = "config.ts"},["1197"] = {line = 92, file = "config.ts"},["1199"] = {line = 94, file = "config.ts"},["1200"] = {line = 95, file = "config.ts"},["1201"] = {line = 95, file = "config.ts"},["1202"] = {line = 96, file = "config.ts"},["1203"] = {line = 97, file = "config.ts"},["1204"] = {line = 97, file = "config.ts"},["1206"] = {line = 98, file = "config.ts"},["1209"] = {line = 100, file = "config.ts"},["1210"] = {line = 101, file = "config.ts"},["1211"] = {line = 102, file = "config.ts"},["1212"] = {line = 102, file = "config.ts"},["1214"] = {line = 103, file = "config.ts"},["1217"] = {line = 105, file = "config.ts"},["1218"] = {line = 81, file = "config.ts"},["1219"] = {line = 108, file = "config.ts"},["1220"] = {line = 109, file = "config.ts"},["1221"] = {line = 110, file = "config.ts"},["1222"] = {line = 111, file = "config.ts"},["1224"] = {line = 113, file = "config.ts"},["1225"] = {line = 113, file = "config.ts"},["1226"] = {line = 113, file = "config.ts"},["1227"] = {line = 113, file = "config.ts"},["1228"] = {line = 113, file = "config.ts"},["1229"] = {line = 113, file = "config.ts"},["1230"] = {line = 113, file = "config.ts"},["1231"] = {line = 108, file = "config.ts"},["1244"] = {line = 3, file = "fixture-state.ts"},["1245"] = {line = 3, file = "fixture-state.ts"},["1246"] = {line = 4, file = "fixture-state.ts"},["1247"] = {line = 4, file = "fixture-state.ts"},["1248"] = {line = 4, file = "fixture-state.ts"},["1249"] = {line = 4, file = "fixture-state.ts"},["1250"] = {line = 17, file = "fixture-state.ts"},["1251"] = {line = 19, file = "fixture-state.ts"},["1252"] = {line = 20, file = "fixture-state.ts"},["1253"] = {line = 20, file = "fixture-state.ts"},["1255"] = {line = 21, file = "fixture-state.ts"},["1256"] = {line = 21, file = "fixture-state.ts"},["1258"] = {line = 22, file = "fixture-state.ts"},["1259"] = {line = 22, file = "fixture-state.ts"},["1261"] = {line = 23, file = "fixture-state.ts"},["1262"] = {line = 23, file = "fixture-state.ts"},["1264"] = {line = 24, file = "fixture-state.ts"},["1265"] = {line = 24, file = "fixture-state.ts"},["1267"] = {line = 25, file = "fixture-state.ts"},["1268"] = {line = 26, file = "fixture-state.ts"},["1269"] = {line = 27, file = "fixture-state.ts"},["1270"] = {line = 28, file = "fixture-state.ts"},["1271"] = {line = 29, file = "fixture-state.ts"},["1272"] = {line = 30, file = "fixture-state.ts"},["1273"] = {line = 31, file = "fixture-state.ts"},["1274"] = {line = 31, file = "fixture-state.ts"},["1275"] = {line = 31, file = "fixture-state.ts"},["1276"] = {line = 31, file = "fixture-state.ts"},["1277"] = {line = 31, file = "fixture-state.ts"},["1278"] = {line = 31, file = "fixture-state.ts"},["1279"] = {line = 32, file = "fixture-state.ts"},["1280"] = {line = 30, file = "fixture-state.ts"},["1281"] = {line = 19, file = "fixture-state.ts"},["1290"] = {line = 4, file = "view-model.ts"},["1291"] = {line = 4, file = "view-model.ts"},["1292"] = {line = 4, file = "view-model.ts"},["1293"] = {line = 4, file = "view-model.ts"},["1294"] = {line = 7, file = "view-model.ts"},["1295"] = {line = 8, file = "view-model.ts"},["1296"] = {line = 8, file = "view-model.ts"},["1297"] = {line = 8, file = "view-model.ts"},["1298"] = {line = 8, file = "view-model.ts"},["1299"] = {line = 9, file = "view-model.ts"},["1300"] = {line = 9, file = "view-model.ts"},["1301"] = {line = 9, file = "view-model.ts"},["1302"] = {line = 7, file = "view-model.ts"},["1303"] = {line = 11, file = "view-model.ts"},["1304"] = {line = 12, file = "view-model.ts"},["1305"] = {line = 13, file = "view-model.ts"},["1306"] = {line = 14, file = "view-model.ts"},["1307"] = {line = 15, file = "view-model.ts"},["1308"] = {line = 16, file = "view-model.ts"},["1309"] = {line = 17, file = "view-model.ts"},["1310"] = {line = 18, file = "view-model.ts"},["1311"] = {line = 19, file = "view-model.ts"},["1312"] = {line = 20, file = "view-model.ts"},["1313"] = {line = 11, file = "view-model.ts"},["1314"] = {line = 22, file = "view-model.ts"},["1315"] = {line = 23, file = "view-model.ts"},["1316"] = {line = 31, file = "view-model.ts"},["1317"] = {line = 32, file = "view-model.ts"},["1318"] = {line = 32, file = "view-model.ts"},["1319"] = {line = 32, file = "view-model.ts"},["1320"] = {line = 32, file = "view-model.ts"},["1321"] = {line = 33, file = "view-model.ts"},["1322"] = {line = 33, file = "view-model.ts"},["1323"] = {line = 33, file = "view-model.ts"},["1324"] = {line = 33, file = "view-model.ts"},["1325"] = {line = 31, file = "view-model.ts"},["1326"] = {line = 36, file = "view-model.ts"},["1327"] = {line = 37, file = "view-model.ts"},["1328"] = {line = 36, file = "view-model.ts"},["1329"] = {line = 40, file = "view-model.ts"},["1330"] = {line = 41, file = "view-model.ts"},["1331"] = {line = 40, file = "view-model.ts"},["1332"] = {line = 44, file = "view-model.ts"},["1333"] = {line = 45, file = "view-model.ts"},["1334"] = {line = 46, file = "view-model.ts"},["1335"] = {line = 47, file = "view-model.ts"},["1336"] = {line = 48, file = "view-model.ts"},["1337"] = {line = 49, file = "view-model.ts"},["1338"] = {line = 49, file = "view-model.ts"},["1339"] = {line = 49, file = "view-model.ts"},["1340"] = {line = 49, file = "view-model.ts"},["1341"] = {line = 49, file = "view-model.ts"},["1342"] = {line = 49, file = "view-model.ts"},["1343"] = {line = 48, file = "view-model.ts"},["1344"] = {line = 51, file = "view-model.ts"},["1345"] = {line = 51, file = "view-model.ts"},["1346"] = {line = 51, file = "view-model.ts"},["1347"] = {line = 52, file = "view-model.ts"},["1348"] = {line = 53, file = "view-model.ts"},["1349"] = {line = 53, file = "view-model.ts"},["1350"] = {line = 53, file = "view-model.ts"},["1351"] = {line = 53, file = "view-model.ts"},["1352"] = {line = 53, file = "view-model.ts"},["1353"] = {line = 53, file = "view-model.ts"},["1354"] = {line = 53, file = "view-model.ts"},["1355"] = {line = 53, file = "view-model.ts"},["1356"] = {line = 54, file = "view-model.ts"},["1358"] = {line = 56, file = "view-model.ts"},["1359"] = {line = 56, file = "view-model.ts"},["1360"] = {line = 56, file = "view-model.ts"},["1361"] = {line = 57, file = "view-model.ts"},["1362"] = {line = 57, file = "view-model.ts"},["1363"] = {line = 57, file = "view-model.ts"},["1364"] = {line = 57, file = "view-model.ts"},["1365"] = {line = 57, file = "view-model.ts"},["1366"] = {line = 57, file = "view-model.ts"},["1367"] = {line = 57, file = "view-model.ts"},["1368"] = {line = 57, file = "view-model.ts"},["1369"] = {line = 57, file = "view-model.ts"},["1370"] = {line = 57, file = "view-model.ts"},["1371"] = {line = 57, file = "view-model.ts"},["1372"] = {line = 57, file = "view-model.ts"},["1373"] = {line = 57, file = "view-model.ts"},["1374"] = {line = 57, file = "view-model.ts"},["1375"] = {line = 57, file = "view-model.ts"},["1376"] = {line = 58, file = "view-model.ts"},["1377"] = {line = 59, file = "view-model.ts"},["1378"] = {line = 59, file = "view-model.ts"},["1379"] = {line = 59, file = "view-model.ts"},["1380"] = {line = 60, file = "view-model.ts"},["1381"] = {line = 61, file = "view-model.ts"},["1382"] = {line = 62, file = "view-model.ts"},["1383"] = {line = 62, file = "view-model.ts"},["1384"] = {line = 62, file = "view-model.ts"},["1385"] = {line = 62, file = "view-model.ts"},["1386"] = {line = 62, file = "view-model.ts"},["1387"] = {line = 62, file = "view-model.ts"},["1388"] = {line = 62, file = "view-model.ts"},["1389"] = {line = 62, file = "view-model.ts"},["1390"] = {line = 63, file = "view-model.ts"},["1391"] = {line = 63, file = "view-model.ts"},["1392"] = {line = 63, file = "view-model.ts"},["1393"] = {line = 63, file = "view-model.ts"},["1394"] = {line = 63, file = "view-model.ts"},["1395"] = {line = 63, file = "view-model.ts"},["1396"] = {line = 63, file = "view-model.ts"},["1397"] = {line = 63, file = "view-model.ts"},["1398"] = {line = 63, file = "view-model.ts"},["1399"] = {line = 63, file = "view-model.ts"},["1400"] = {line = 63, file = "view-model.ts"},["1401"] = {line = 63, file = "view-model.ts"},["1402"] = {line = 63, file = "view-model.ts"},["1403"] = {line = 63, file = "view-model.ts"},["1404"] = {line = 63, file = "view-model.ts"},["1405"] = {line = 64, file = "view-model.ts"},["1406"] = {line = 64, file = "view-model.ts"},["1407"] = {line = 64, file = "view-model.ts"},["1408"] = {line = 64, file = "view-model.ts"},["1409"] = {line = 64, file = "view-model.ts"},["1410"] = {line = 64, file = "view-model.ts"},["1411"] = {line = 64, file = "view-model.ts"},["1412"] = {line = 65, file = "view-model.ts"},["1413"] = {line = 66, file = "view-model.ts"},["1414"] = {line = 66, file = "view-model.ts"},["1415"] = {line = 66, file = "view-model.ts"},["1416"] = {line = 66, file = "view-model.ts"},["1417"] = {line = 67, file = "view-model.ts"},["1418"] = {line = 67, file = "view-model.ts"},["1419"] = {line = 67, file = "view-model.ts"},["1420"] = {line = 67, file = "view-model.ts"},["1421"] = {line = 67, file = "view-model.ts"},["1422"] = {line = 67, file = "view-model.ts"},["1423"] = {line = 67, file = "view-model.ts"},["1424"] = {line = 67, file = "view-model.ts"},["1425"] = {line = 68, file = "view-model.ts"},["1427"] = {line = 59, file = "view-model.ts"},["1428"] = {line = 59, file = "view-model.ts"},["1429"] = {line = 71, file = "view-model.ts"},["1430"] = {line = 44, file = "view-model.ts"},["1431"] = {line = 74, file = "view-model.ts"},["1432"] = {line = 75, file = "view-model.ts"},["1433"] = {line = 75, file = "view-model.ts"},["1435"] = {line = 76, file = "view-model.ts"},["1436"] = {line = 76, file = "view-model.ts"},["1438"] = {line = 77, file = "view-model.ts"},["1439"] = {line = 77, file = "view-model.ts"},["1441"] = {line = 78, file = "view-model.ts"},["1442"] = {line = 74, file = "view-model.ts"},["1443"] = {line = 81, file = "view-model.ts"},["1444"] = {line = 82, file = "view-model.ts"},["1445"] = {line = 82, file = "view-model.ts"},["1447"] = {line = 83, file = "view-model.ts"},["1448"] = {line = 83, file = "view-model.ts"},["1450"] = {line = 84, file = "view-model.ts"},["1451"] = {line = 84, file = "view-model.ts"},["1453"] = {line = 85, file = "view-model.ts"},["1454"] = {line = 85, file = "view-model.ts"},["1456"] = {line = 86, file = "view-model.ts"},["1457"] = {line = 81, file = "view-model.ts"},["1458"] = {line = 89, file = "view-model.ts"},["1459"] = {line = 90, file = "view-model.ts"},["1460"] = {line = 91, file = "view-model.ts"},["1461"] = {line = 91, file = "view-model.ts"},["1462"] = {line = 91, file = "view-model.ts"},["1464"] = {line = 91, file = "view-model.ts"},["1465"] = {line = 91, file = "view-model.ts"},["1467"] = {line = 91, file = "view-model.ts"},["1468"] = {line = 91, file = "view-model.ts"},["1469"] = {line = 92, file = "view-model.ts"},["1470"] = {line = 92, file = "view-model.ts"},["1471"] = {line = 92, file = "view-model.ts"},["1472"] = {line = 92, file = "view-model.ts"},["1473"] = {line = 92, file = "view-model.ts"},["1474"] = {line = 92, file = "view-model.ts"},["1475"] = {line = 93, file = "view-model.ts"},["1476"] = {line = 94, file = "view-model.ts"},["1477"] = {line = 95, file = "view-model.ts"},["1478"] = {line = 96, file = "view-model.ts"},["1479"] = {line = 96, file = "view-model.ts"},["1480"] = {line = 96, file = "view-model.ts"},["1481"] = {line = 96, file = "view-model.ts"},["1482"] = {line = 96, file = "view-model.ts"},["1483"] = {line = 97, file = "view-model.ts"},["1484"] = {line = 97, file = "view-model.ts"},["1485"] = {line = 97, file = "view-model.ts"},["1486"] = {line = 97, file = "view-model.ts"},["1487"] = {line = 97, file = "view-model.ts"},["1488"] = {line = 97, file = "view-model.ts"},["1489"] = {line = 97, file = "view-model.ts"},["1490"] = {line = 97, file = "view-model.ts"},["1492"] = {line = 98, file = "view-model.ts"},["1493"] = {line = 98, file = "view-model.ts"},["1494"] = {line = 98, file = "view-model.ts"},["1495"] = {line = 98, file = "view-model.ts"},["1496"] = {line = 98, file = "view-model.ts"},["1497"] = {line = 98, file = "view-model.ts"},["1498"] = {line = 98, file = "view-model.ts"},["1500"] = {line = 99, file = "view-model.ts"},["1501"] = {line = 100, file = "view-model.ts"},["1502"] = {line = 101, file = "view-model.ts"},["1503"] = {line = 101, file = "view-model.ts"},["1504"] = {line = 101, file = "view-model.ts"},["1505"] = {line = 101, file = "view-model.ts"},["1506"] = {line = 101, file = "view-model.ts"},["1507"] = {line = 101, file = "view-model.ts"},["1508"] = {line = 101, file = "view-model.ts"},["1510"] = {line = 103, file = "view-model.ts"},["1511"] = {line = 104, file = "view-model.ts"},["1512"] = {line = 105, file = "view-model.ts"},["1513"] = {line = 106, file = "view-model.ts"},["1514"] = {line = 107, file = "view-model.ts"},["1515"] = {line = 108, file = "view-model.ts"},["1516"] = {line = 109, file = "view-model.ts"},["1517"] = {line = 109, file = "view-model.ts"},["1518"] = {line = 109, file = "view-model.ts"},["1519"] = {line = 109, file = "view-model.ts"},["1520"] = {line = 109, file = "view-model.ts"},["1521"] = {line = 109, file = "view-model.ts"},["1522"] = {line = 109, file = "view-model.ts"},["1523"] = {line = 109, file = "view-model.ts"},["1524"] = {line = 110, file = "view-model.ts"},["1525"] = {line = 111, file = "view-model.ts"},["1526"] = {line = 112, file = "view-model.ts"},["1527"] = {line = 112, file = "view-model.ts"},["1528"] = {line = 112, file = "view-model.ts"},["1529"] = {line = 112, file = "view-model.ts"},["1530"] = {line = 112, file = "view-model.ts"},["1531"] = {line = 112, file = "view-model.ts"},["1532"] = {line = 112, file = "view-model.ts"},["1534"] = {line = 113, file = "view-model.ts"},["1537"] = {line = 115, file = "view-model.ts"},["1538"] = {line = 115, file = "view-model.ts"},["1539"] = {line = 115, file = "view-model.ts"},["1540"] = {line = 115, file = "view-model.ts"},["1541"] = {line = 116, file = "view-model.ts"},["1542"] = {line = 117, file = "view-model.ts"},["1543"] = {line = 117, file = "view-model.ts"},["1544"] = {line = 117, file = "view-model.ts"},["1545"] = {line = 117, file = "view-model.ts"},["1546"] = {line = 117, file = "view-model.ts"},["1547"] = {line = 117, file = "view-model.ts"},["1548"] = {line = 118, file = "view-model.ts"},["1549"] = {line = 118, file = "view-model.ts"},["1550"] = {line = 118, file = "view-model.ts"},["1551"] = {line = 118, file = "view-model.ts"},["1552"] = {line = 118, file = "view-model.ts"},["1553"] = {line = 119, file = "view-model.ts"},["1554"] = {line = 119, file = "view-model.ts"},["1555"] = {line = 119, file = "view-model.ts"},["1556"] = {line = 119, file = "view-model.ts"},["1557"] = {line = 119, file = "view-model.ts"},["1558"] = {line = 120, file = "view-model.ts"},["1559"] = {line = 120, file = "view-model.ts"},["1560"] = {line = 120, file = "view-model.ts"},["1561"] = {line = 120, file = "view-model.ts"},["1562"] = {line = 120, file = "view-model.ts"},["1563"] = {line = 121, file = "view-model.ts"},["1564"] = {line = 121, file = "view-model.ts"},["1565"] = {line = 121, file = "view-model.ts"},["1566"] = {line = 121, file = "view-model.ts"},["1567"] = {line = 121, file = "view-model.ts"},["1569"] = {line = 123, file = "view-model.ts"},["1570"] = {line = 89, file = "view-model.ts"},["1579"] = {line = 4, file = "handles.ts"},["1580"] = {line = 5, file = "handles.ts"},["1581"] = {line = 5, file = "handles.ts"},["1583"] = {line = 6, file = "handles.ts"},["1584"] = {line = 7, file = "handles.ts"},["1585"] = {line = 4, file = "handles.ts"},["1586"] = {line = 10, file = "handles.ts"},["1587"] = {line = 11, file = "handles.ts"},["1588"] = {line = 11, file = "handles.ts"},["1590"] = {line = 12, file = "handles.ts"},["1591"] = {line = 12, file = "handles.ts"},["1593"] = {line = 13, file = "handles.ts"},["1594"] = {line = 10, file = "handles.ts"},["1595"] = {line = 16, file = "handles.ts"},["1596"] = {line = 17, file = "handles.ts"},["1597"] = {line = 17, file = "handles.ts"},["1598"] = {line = 17, file = "handles.ts"},["1601"] = {line = 18, file = "handles.ts"},["1602"] = {line = 16, file = "handles.ts"},["1611"] = {line = 2, file = "log.ts"},["1612"] = {line = 4, file = "log.ts"},["1613"] = {line = 5, file = "log.ts"},["1614"] = {line = 4, file = "log.ts"},["1615"] = {line = 8, file = "log.ts"},["1616"] = {line = 9, file = "log.ts"},["1619"] = {line = 10, file = "log.ts"},["1620"] = {line = 11, file = "log.ts"},["1621"] = {line = 8, file = "log.ts"},["1630"] = {line = 2, file = "appearances.ts"},["1631"] = {line = 2, file = "appearances.ts"},["1632"] = {line = 3, file = "appearances.ts"},["1633"] = {line = 3, file = "appearances.ts"},["1634"] = {line = 4, file = "appearances.ts"},["1635"] = {line = 4, file = "appearances.ts"},["1636"] = {line = 4, file = "appearances.ts"},["1637"] = {line = 5, file = "appearances.ts"},["1638"] = {line = 5, file = "appearances.ts"},["1639"] = {line = 8, file = "appearances.ts"},["1640"] = {line = 10, file = "appearances.ts"},["1641"] = {line = 11, file = "appearances.ts"},["1642"] = {line = 10, file = "appearances.ts"},["1643"] = {line = 14, file = "appearances.ts"},["1644"] = {line = 15, file = "appearances.ts"},["1645"] = {line = 15, file = "appearances.ts"},["1646"] = {line = 15, file = "appearances.ts"},["1649"] = {line = 16, file = "appearances.ts"},["1650"] = {line = 14, file = "appearances.ts"},["1651"] = {line = 19, file = "appearances.ts"},["1652"] = {line = 21, file = "appearances.ts"},["1653"] = {line = 22, file = "appearances.ts"},["1654"] = {line = 23, file = "appearances.ts"},["1655"] = {line = 24, file = "appearances.ts"},["1656"] = {line = 25, file = "appearances.ts"},["1657"] = {line = 25, file = "appearances.ts"},["1660"] = {line = 27, file = "appearances.ts"},["1661"] = {line = 21, file = "appearances.ts"},["1662"] = {line = 31, file = "appearances.ts"},["1663"] = {line = 32, file = "appearances.ts"},["1664"] = {line = 33, file = "appearances.ts"},["1665"] = {line = 34, file = "appearances.ts"},["1667"] = {line = 35, file = "appearances.ts"},["1668"] = {line = 35, file = "appearances.ts"},["1670"] = {line = 36, file = "appearances.ts"},["1671"] = {line = 37, file = "appearances.ts"},["1672"] = {line = 38, file = "appearances.ts"},["1673"] = {line = 39, file = "appearances.ts"},["1675"] = {line = 41, file = "appearances.ts"},["1676"] = {line = 42, file = "appearances.ts"},["1677"] = {line = 42, file = "appearances.ts"},["1681"] = {line = 35, file = "appearances.ts"},["1684"] = {line = 44, file = "appearances.ts"},["1685"] = {line = 31, file = "appearances.ts"},["1686"] = {line = 48, file = "appearances.ts"},["1687"] = {line = 49, file = "appearances.ts"},["1688"] = {line = 50, file = "appearances.ts"},["1689"] = {line = 50, file = "appearances.ts"},["1691"] = {line = 51, file = "appearances.ts"},["1692"] = {line = 51, file = "appearances.ts"},["1693"] = {line = 51, file = "appearances.ts"},["1694"] = {line = 51, file = "appearances.ts"},["1695"] = {line = 52, file = "appearances.ts"},["1696"] = {line = 53, file = "appearances.ts"},["1697"] = {line = 48, file = "appearances.ts"},["1698"] = {line = 58, file = "appearances.ts"},["1699"] = {line = 59, file = "appearances.ts"},["1700"] = {line = 60, file = "appearances.ts"},["1701"] = {line = 60, file = "appearances.ts"},["1703"] = {line = 61, file = "appearances.ts"},["1704"] = {line = 64, file = "appearances.ts"},["1706"] = {line = 65, file = "appearances.ts"},["1707"] = {line = 66, file = "appearances.ts"},["1708"] = {line = 66, file = "appearances.ts"},["1709"] = {line = 66, file = "appearances.ts"},["1711"] = {line = 66, file = "appearances.ts"},["1713"] = {line = 66, file = "appearances.ts"},["1714"] = {line = 67, file = "appearances.ts"},["1715"] = {line = 67, file = "appearances.ts"},["1719"] = {line = 71, file = "appearances.ts"},["1720"] = {line = 71, file = "appearances.ts"},["1721"] = {line = 71, file = "appearances.ts"},["1722"] = {line = 71, file = "appearances.ts"},["1725"] = {line = 69, file = "appearances.ts"},["1734"] = {line = 74, file = "appearances.ts"},["1735"] = {line = 74, file = "appearances.ts"},["1736"] = {line = 74, file = "appearances.ts"},["1737"] = {line = 74, file = "appearances.ts"},["1738"] = {line = 75, file = "appearances.ts"},["1739"] = {line = 76, file = "appearances.ts"},["1740"] = {line = 77, file = "appearances.ts"},["1741"] = {line = 78, file = "appearances.ts"},["1742"] = {line = 79, file = "appearances.ts"},["1743"] = {line = 80, file = "appearances.ts"},["1744"] = {line = 81, file = "appearances.ts"},["1746"] = {line = 83, file = "appearances.ts"},["1747"] = {line = 83, file = "appearances.ts"},["1749"] = {line = 84, file = "appearances.ts"},["1751"] = {line = 58, file = "appearances.ts"},["1752"] = {line = 89, file = "appearances.ts"},["1753"] = {line = 90, file = "appearances.ts"},["1754"] = {line = 91, file = "appearances.ts"},["1755"] = {line = 91, file = "appearances.ts"},["1757"] = {line = 92, file = "appearances.ts"},["1758"] = {line = 92, file = "appearances.ts"},["1760"] = {line = 93, file = "appearances.ts"},["1761"] = {line = 94, file = "appearances.ts"},["1762"] = {line = 94, file = "appearances.ts"},["1763"] = {line = 94, file = "appearances.ts"},["1765"] = {line = 94, file = "appearances.ts"},["1767"] = {line = 94, file = "appearances.ts"},["1768"] = {line = 95, file = "appearances.ts"},["1769"] = {line = 95, file = "appearances.ts"},["1770"] = {line = 95, file = "appearances.ts"},["1771"] = {line = 95, file = "appearances.ts"},["1773"] = {line = 95, file = "appearances.ts"},["1775"] = {line = 95, file = "appearances.ts"},["1776"] = {line = 96, file = "appearances.ts"},["1777"] = {line = 89, file = "appearances.ts"},["1792"] = {line = 72, file = "pool.ts"},["1793"] = {line = 2, file = "pool.ts"},["1794"] = {line = 2, file = "pool.ts"},["1795"] = {line = 2, file = "pool.ts"},["1796"] = {line = 3, file = "pool.ts"},["1797"] = {line = 3, file = "pool.ts"},["1798"] = {line = 3, file = "pool.ts"},["1799"] = {line = 3, file = "pool.ts"},["1800"] = {line = 4, file = "pool.ts"},["1801"] = {line = 4, file = "pool.ts"},["1802"] = {line = 16, file = "pool.ts"},["1803"] = {line = 17, file = "pool.ts"},["1804"] = {line = 17, file = "pool.ts"},["1805"] = {line = 17, file = "pool.ts"},["1806"] = {line = 17, file = "pool.ts"},["1807"] = {line = 16, file = "pool.ts"},["1808"] = {line = 20, file = "pool.ts"},["1809"] = {line = 21, file = "pool.ts"},["1810"] = {line = 22, file = "pool.ts"},["1811"] = {line = 23, file = "pool.ts"},["1812"] = {line = 24, file = "pool.ts"},["1814"] = {line = 26, file = "pool.ts"},["1816"] = {line = 26, file = "pool.ts"},["1820"] = {line = 27, file = "pool.ts"},["1821"] = {line = 20, file = "pool.ts"},["1822"] = {line = 32, file = "pool.ts"},["1823"] = {line = 33, file = "pool.ts"},["1824"] = {line = 34, file = "pool.ts"},["1825"] = {line = 34, file = "pool.ts"},["1827"] = {line = 35, file = "pool.ts"},["1828"] = {line = 36, file = "pool.ts"},["1829"] = {line = 36, file = "pool.ts"},["1830"] = {line = 36, file = "pool.ts"},["1832"] = {line = 36, file = "pool.ts"},["1834"] = {line = 36, file = "pool.ts"},["1835"] = {line = 37, file = "pool.ts"},["1836"] = {line = 37, file = "pool.ts"},["1838"] = {line = 38, file = "pool.ts"},["1839"] = {line = 32, file = "pool.ts"},["1840"] = {line = 48, file = "pool.ts"},["1841"] = {line = 49, file = "pool.ts"},["1842"] = {line = 50, file = "pool.ts"},["1845"] = {line = 51, file = "pool.ts"},["1846"] = {line = 52, file = "pool.ts"},["1847"] = {line = 53, file = "pool.ts"},["1848"] = {line = 53, file = "pool.ts"},["1849"] = {line = 53, file = "pool.ts"},["1850"] = {line = 53, file = "pool.ts"},["1852"] = {line = 54, file = "pool.ts"},["1853"] = {line = 55, file = "pool.ts"},["1854"] = {line = 48, file = "pool.ts"},["1855"] = {line = 72, file = "pool.ts"},["1856"] = {line = 73, file = "pool.ts"},["1857"] = {line = 74, file = "pool.ts"},["1858"] = {line = 75, file = "pool.ts"},["1860"] = {line = 77, file = "pool.ts"},["1861"] = {line = 78, file = "pool.ts"},["1863"] = {line = 127, file = "pool.ts"},["1864"] = {line = 128, file = "pool.ts"},["1865"] = {line = 129, file = "pool.ts"},["1866"] = {line = 129, file = "pool.ts"},["1868"] = {line = 130, file = "pool.ts"},["1869"] = {line = 131, file = "pool.ts"},["1870"] = {line = 132, file = "pool.ts"},["1871"] = {line = 132, file = "pool.ts"},["1874"] = {line = 134, file = "pool.ts"},["1876"] = {line = 171, file = "pool.ts"},["1877"] = {line = 172, file = "pool.ts"},["1878"] = {line = 173, file = "pool.ts"},["1879"] = {line = 171, file = "pool.ts"},["1880"] = {line = 6, file = "pool.ts"},["1881"] = {line = 7, file = "pool.ts"},["1882"] = {line = 8, file = "pool.ts"},["1883"] = {line = 9, file = "pool.ts"},["1884"] = {line = 10, file = "pool.ts"},["1885"] = {line = 12, file = "pool.ts"},["1886"] = {line = 12, file = "pool.ts"},["1887"] = {line = 12, file = "pool.ts"},["1888"] = {line = 13, file = "pool.ts"},["1889"] = {line = 13, file = "pool.ts"},["1890"] = {line = 13, file = "pool.ts"},["1891"] = {line = 14, file = "pool.ts"},["1892"] = {line = 14, file = "pool.ts"},["1893"] = {line = 14, file = "pool.ts"},["1894"] = {line = 30, file = "pool.ts"},["1895"] = {line = 43, file = "pool.ts"},["1896"] = {line = 44, file = "pool.ts"},["1897"] = {line = 43, file = "pool.ts"},["1898"] = {line = 59, file = "pool.ts"},["1899"] = {line = 60, file = "pool.ts"},["1900"] = {line = 59, file = "pool.ts"},["1901"] = {line = 64, file = "pool.ts"},["1902"] = {line = 65, file = "pool.ts"},["1903"] = {line = 64, file = "pool.ts"},["1904"] = {line = 69, file = "pool.ts"},["1905"] = {line = 69, file = "pool.ts"},["1906"] = {line = 69, file = "pool.ts"},["1907"] = {line = 70, file = "pool.ts"},["1908"] = {line = 70, file = "pool.ts"},["1909"] = {line = 70, file = "pool.ts"},["1910"] = {line = 81, file = "pool.ts"},["1911"] = {line = 82, file = "pool.ts"},["1912"] = {line = 83, file = "pool.ts"},["1915"] = {line = 84, file = "pool.ts"},["1916"] = {line = 85, file = "pool.ts"},["1917"] = {line = 81, file = "pool.ts"},["1918"] = {line = 89, file = "pool.ts"},["1919"] = {line = 90, file = "pool.ts"},["1920"] = {line = 91, file = "pool.ts"},["1921"] = {line = 89, file = "pool.ts"},["1922"] = {line = 94, file = "pool.ts"},["1923"] = {line = 96, file = "pool.ts"},["1924"] = {line = 97, file = "pool.ts"},["1925"] = {line = 96, file = "pool.ts"},["1926"] = {line = 102, file = "pool.ts"},["1927"] = {line = 103, file = "pool.ts"},["1928"] = {line = 104, file = "pool.ts"},["1929"] = {line = 105, file = "pool.ts"},["1930"] = {line = 106, file = "pool.ts"},["1931"] = {line = 107, file = "pool.ts"},["1932"] = {line = 108, file = "pool.ts"},["1933"] = {line = 109, file = "pool.ts"},["1934"] = {line = 110, file = "pool.ts"},["1935"] = {line = 111, file = "pool.ts"},["1936"] = {line = 112, file = "pool.ts"},["1937"] = {line = 113, file = "pool.ts"},["1939"] = {line = 115, file = "pool.ts"},["1940"] = {line = 116, file = "pool.ts"},["1941"] = {line = 117, file = "pool.ts"},["1942"] = {line = 118, file = "pool.ts"},["1943"] = {line = 119, file = "pool.ts"},["1945"] = {line = 121, file = "pool.ts"},["1946"] = {line = 122, file = "pool.ts"},["1948"] = {line = 122, file = "pool.ts"},["1949"] = {line = 122, file = "pool.ts"},["1950"] = {line = 122, file = "pool.ts"},["1951"] = {line = 122, file = "pool.ts"},["1953"] = {line = 122, file = "pool.ts"},["1955"] = {line = 122, file = "pool.ts"},["1956"] = {line = 122, file = "pool.ts"},["1958"] = {line = 123, file = "pool.ts"},["1959"] = {line = 102, file = "pool.ts"},["1960"] = {line = 138, file = "pool.ts"},["1961"] = {line = 139, file = "pool.ts"},["1962"] = {line = 140, file = "pool.ts"},["1963"] = {line = 141, file = "pool.ts"},["1964"] = {line = 141, file = "pool.ts"},["1965"] = {line = 141, file = "pool.ts"},["1966"] = {line = 141, file = "pool.ts"},["1968"] = {line = 141, file = "pool.ts"},["1969"] = {line = 142, file = "pool.ts"},["1970"] = {line = 142, file = "pool.ts"},["1973"] = {line = 144, file = "pool.ts"},["1974"] = {line = 144, file = "pool.ts"},["1976"] = {line = 138, file = "pool.ts"},["1977"] = {line = 148, file = "pool.ts"},["1978"] = {line = 149, file = "pool.ts"},["1979"] = {line = 150, file = "pool.ts"},["1982"] = {line = 151, file = "pool.ts"},["1983"] = {line = 152, file = "pool.ts"},["1984"] = {line = 148, file = "pool.ts"},["1985"] = {line = 155, file = "pool.ts"},["1986"] = {line = 156, file = "pool.ts"},["1987"] = {line = 157, file = "pool.ts"},["1988"] = {line = 158, file = "pool.ts"},["1991"] = {line = 161, file = "pool.ts"},["1992"] = {line = 155, file = "pool.ts"},["1993"] = {line = 164, file = "pool.ts"},["1994"] = {line = 165, file = "pool.ts"},["1995"] = {line = 166, file = "pool.ts"},["1996"] = {line = 166, file = "pool.ts"},["1998"] = {line = 167, file = "pool.ts"},["1999"] = {line = 168, file = "pool.ts"},["2000"] = {line = 164, file = "pool.ts"},["2017"] = {line = 2, file = "layout.ts"},["2018"] = {line = 2, file = "layout.ts"},["2019"] = {line = 4, file = "layout.ts"},["2020"] = {line = 4, file = "layout.ts"},["2021"] = {line = 4, file = "layout.ts"},["2022"] = {line = 5, file = "layout.ts"},["2023"] = {line = 5, file = "layout.ts"},["2024"] = {line = 6, file = "layout.ts"},["2025"] = {line = 6, file = "layout.ts"},["2026"] = {line = 6, file = "layout.ts"},["2027"] = {line = 6, file = "layout.ts"},["2028"] = {line = 6, file = "layout.ts"},["2029"] = {line = 6, file = "layout.ts"},["2030"] = {line = 6, file = "layout.ts"},["2031"] = {line = 8, file = "layout.ts"},["2032"] = {line = 9, file = "layout.ts"},["2033"] = {line = 11, file = "layout.ts"},["2034"] = {line = 13, file = "layout.ts"},["2035"] = {line = 14, file = "layout.ts"},["2036"] = {line = 16, file = "layout.ts"},["2037"] = {line = 18, file = "layout.ts"},["2038"] = {line = 19, file = "layout.ts"},["2039"] = {line = 19, file = "layout.ts"},["2040"] = {line = 19, file = "layout.ts"},["2041"] = {line = 19, file = "layout.ts"},["2042"] = {line = 19, file = "layout.ts"},["2043"] = {line = 20, file = "layout.ts"},["2044"] = {line = 20, file = "layout.ts"},["2045"] = {line = 20, file = "layout.ts"},["2046"] = {line = 20, file = "layout.ts"},["2047"] = {line = 21, file = "layout.ts"},["2048"] = {line = 21, file = "layout.ts"},["2049"] = {line = 18, file = "layout.ts"},["2050"] = {line = 25, file = "layout.ts"},["2051"] = {line = 26, file = "layout.ts"},["2052"] = {line = 26, file = "layout.ts"},["2053"] = {line = 26, file = "layout.ts"},["2056"] = {line = 30, file = "layout.ts"},["2057"] = {line = 30, file = "layout.ts"},["2058"] = {line = 30, file = "layout.ts"},["2059"] = {line = 30, file = "layout.ts"},["2062"] = {line = 28, file = "layout.ts"},["2069"] = {line = 25, file = "layout.ts"},["2070"] = {line = 36, file = "layout.ts"},["2073"] = {line = 40, file = "layout.ts"},["2074"] = {line = 40, file = "layout.ts"},["2075"] = {line = 40, file = "layout.ts"},["2076"] = {line = 40, file = "layout.ts"},["2079"] = {line = 38, file = "layout.ts"},["2085"] = {line = 36, file = "layout.ts"},["2086"] = {line = 45, file = "layout.ts"},["2087"] = {line = 46, file = "layout.ts"},["2088"] = {line = 47, file = "layout.ts"},["2093"] = {line = 53, file = "layout.ts"},["2094"] = {line = 53, file = "layout.ts"},["2095"] = {line = 53, file = "layout.ts"},["2096"] = {line = 53, file = "layout.ts"},["2097"] = {line = 54, file = "layout.ts"},["2100"] = {line = 51, file = "layout.ts"},["2106"] = {line = 45, file = "layout.ts"},["2107"] = {line = 59, file = "layout.ts"},["2108"] = {line = 60, file = "layout.ts"},["2109"] = {line = 61, file = "layout.ts"},["2110"] = {line = 61, file = "layout.ts"},["2112"] = {line = 62, file = "layout.ts"},["2113"] = {line = 63, file = "layout.ts"},["2114"] = {line = 64, file = "layout.ts"},["2115"] = {line = 64, file = "layout.ts"},["2116"] = {line = 64, file = "layout.ts"},["2117"] = {line = 64, file = "layout.ts"},["2119"] = {line = 64, file = "layout.ts"},["2120"] = {line = 65, file = "layout.ts"},["2121"] = {line = 65, file = "layout.ts"},["2124"] = {line = 67, file = "layout.ts"},["2125"] = {line = 67, file = "layout.ts"},["2127"] = {line = 59, file = "layout.ts"},["2128"] = {line = 72, file = "layout.ts"},["2129"] = {line = 73, file = "layout.ts"},["2130"] = {line = 74, file = "layout.ts"},["2131"] = {line = 75, file = "layout.ts"},["2132"] = {line = 75, file = "layout.ts"},["2134"] = {line = 76, file = "layout.ts"},["2135"] = {line = 77, file = "layout.ts"},["2137"] = {line = 77, file = "layout.ts"},["2141"] = {line = 78, file = "layout.ts"},["2142"] = {line = 79, file = "layout.ts"},["2143"] = {line = 80, file = "layout.ts"},["2145"] = {line = 81, file = "layout.ts"},["2146"] = {line = 81, file = "layout.ts"},["2147"] = {line = 81, file = "layout.ts"},["2148"] = {line = 81, file = "layout.ts"},["2150"] = {line = 81, file = "layout.ts"},["2151"] = {line = 82, file = "layout.ts"},["2152"] = {line = 82, file = "layout.ts"},["2154"] = {line = 83, file = "layout.ts"},["2155"] = {line = 84, file = "layout.ts"},["2156"] = {line = 84, file = "layout.ts"},["2158"] = {line = 85, file = "layout.ts"},["2163"] = {line = 87, file = "layout.ts"},["2164"] = {line = 88, file = "layout.ts"},["2165"] = {line = 89, file = "layout.ts"},["2166"] = {line = 90, file = "layout.ts"},["2167"] = {line = 91, file = "layout.ts"},["2168"] = {line = 92, file = "layout.ts"},["2169"] = {line = 93, file = "layout.ts"},["2170"] = {line = 94, file = "layout.ts"},["2171"] = {line = 94, file = "layout.ts"},["2172"] = {line = 94, file = "layout.ts"},["2173"] = {line = 94, file = "layout.ts"},["2174"] = {line = 95, file = "layout.ts"},["2175"] = {line = 95, file = "layout.ts"},["2176"] = {line = 95, file = "layout.ts"},["2178"] = {line = 95, file = "layout.ts"},["2179"] = {line = 96, file = "layout.ts"},["2180"] = {line = 97, file = "layout.ts"},["2181"] = {line = 98, file = "layout.ts"},["2182"] = {line = 99, file = "layout.ts"},["2183"] = {line = 100, file = "layout.ts"},["2184"] = {line = 101, file = "layout.ts"},["2185"] = {line = 102, file = "layout.ts"},["2186"] = {line = 103, file = "layout.ts"},["2187"] = {line = 104, file = "layout.ts"},["2188"] = {line = 105, file = "layout.ts"},["2189"] = {line = 106, file = "layout.ts"},["2190"] = {line = 107, file = "layout.ts"},["2191"] = {line = 107, file = "layout.ts"},["2194"] = {line = 109, file = "layout.ts"},["2195"] = {line = 110, file = "layout.ts"},["2196"] = {line = 110, file = "layout.ts"},["2197"] = {line = 110, file = "layout.ts"},["2200"] = {line = 111, file = "layout.ts"},["2201"] = {line = 111, file = "layout.ts"},["2203"] = {line = 112, file = "layout.ts"},["2204"] = {line = 113, file = "layout.ts"},["2205"] = {line = 114, file = "layout.ts"},["2206"] = {line = 115, file = "layout.ts"},["2207"] = {line = 115, file = "layout.ts"},["2209"] = {line = 116, file = "layout.ts"},["2212"] = {line = 118, file = "layout.ts"},["2213"] = {line = 118, file = "layout.ts"},["2214"] = {line = 118, file = "layout.ts"},["2215"] = {line = 118, file = "layout.ts"},["2216"] = {line = 119, file = "layout.ts"},["2219"] = {line = 127, file = "layout.ts"},["2220"] = {line = 127, file = "layout.ts"},["2221"] = {line = 127, file = "layout.ts"},["2222"] = {line = 127, file = "layout.ts"},["2225"] = {line = 122, file = "layout.ts"},["2226"] = {line = 123, file = "layout.ts"},["2227"] = {line = 123, file = "layout.ts"},["2228"] = {line = 123, file = "layout.ts"},["2231"] = {line = 124, file = "layout.ts"},["2232"] = {line = 124, file = "layout.ts"},["2234"] = {line = 125, file = "layout.ts"},["2235"] = {line = 125, file = "layout.ts"},["2236"] = {line = 125, file = "layout.ts"},["2237"] = {line = 125, file = "layout.ts"},["2245"] = {line = 72, file = "layout.ts"},["2246"] = {line = 134, file = "layout.ts"},["2247"] = {line = 135, file = "layout.ts"},["2248"] = {line = 136, file = "layout.ts"},["2249"] = {line = 137, file = "layout.ts"},["2250"] = {line = 138, file = "layout.ts"},["2251"] = {line = 139, file = "layout.ts"},["2252"] = {line = 140, file = "layout.ts"},["2255"] = {line = 141, file = "layout.ts"},["2256"] = {line = 142, file = "layout.ts"},["2259"] = {line = 143, file = "layout.ts"},["2261"] = {line = 144, file = "layout.ts"},["2262"] = {line = 144, file = "layout.ts"},["2263"] = {line = 144, file = "layout.ts"},["2264"] = {line = 144, file = "layout.ts"},["2266"] = {line = 144, file = "layout.ts"},["2267"] = {line = 145, file = "layout.ts"},["2268"] = {line = 145, file = "layout.ts"},["2270"] = {line = 146, file = "layout.ts"},["2271"] = {line = 147, file = "layout.ts"},["2272"] = {line = 148, file = "layout.ts"},["2273"] = {line = 149, file = "layout.ts"},["2274"] = {line = 149, file = "layout.ts"},["2279"] = {line = 134, file = "layout.ts"},["2280"] = {line = 153, file = "layout.ts"},["2281"] = {line = 154, file = "layout.ts"},["2282"] = {line = 155, file = "layout.ts"},["2283"] = {line = 156, file = "layout.ts"},["2284"] = {line = 157, file = "layout.ts"},["2286"] = {line = 159, file = "layout.ts"},["2288"] = {line = 160, file = "layout.ts"},["2289"] = {line = 161, file = "layout.ts"},["2290"] = {line = 162, file = "layout.ts"},["2291"] = {line = 162, file = "layout.ts"},["2293"] = {line = 163, file = "layout.ts"},["2294"] = {line = 164, file = "layout.ts"},["2295"] = {line = 165, file = "layout.ts"},["2296"] = {line = 165, file = "layout.ts"},["2298"] = {line = 166, file = "layout.ts"},["2299"] = {line = 167, file = "layout.ts"},["2300"] = {line = 168, file = "layout.ts"},["2301"] = {line = 169, file = "layout.ts"},["2302"] = {line = 169, file = "layout.ts"},["2305"] = {line = 171, file = "layout.ts"},["2306"] = {line = 172, file = "layout.ts"},["2307"] = {line = 173, file = "layout.ts"},["2308"] = {line = 174, file = "layout.ts"},["2309"] = {line = 175, file = "layout.ts"},["2310"] = {line = 176, file = "layout.ts"},["2311"] = {line = 176, file = "layout.ts"},["2313"] = {line = 177, file = "layout.ts"},["2317"] = {line = 153, file = "layout.ts"},["2327"] = {line = 2, file = "live.ts"},["2328"] = {line = 2, file = "live.ts"},["2329"] = {line = 3, file = "live.ts"},["2330"] = {line = 3, file = "live.ts"},["2331"] = {line = 5, file = "live.ts"},["2332"] = {line = 5, file = "live.ts"},["2333"] = {line = 5, file = "live.ts"},["2334"] = {line = 8, file = "live.ts"},["2335"] = {line = 9, file = "live.ts"},["2336"] = {line = 10, file = "live.ts"},["2337"] = {line = 11, file = "live.ts"},["2338"] = {line = 11, file = "live.ts"},["2339"] = {line = 11, file = "live.ts"},["2340"] = {line = 11, file = "live.ts"},["2341"] = {line = 13, file = "live.ts"},["2342"] = {line = 14, file = "live.ts"},["2343"] = {line = 13, file = "live.ts"},["2344"] = {line = 17, file = "live.ts"},["2345"] = {line = 18, file = "live.ts"},["2346"] = {line = 19, file = "live.ts"},["2347"] = {line = 19, file = "live.ts"},["2348"] = {line = 19, file = "live.ts"},["2350"] = {line = 19, file = "live.ts"},["2352"] = {line = 19, file = "live.ts"},["2353"] = {line = 17, file = "live.ts"},["2354"] = {line = 22, file = "live.ts"},["2355"] = {line = 23, file = "live.ts"},["2356"] = {line = 23, file = "live.ts"},["2358"] = {line = 23, file = "live.ts"},["2360"] = {line = 23, file = "live.ts"},["2361"] = {line = 24, file = "live.ts"},["2362"] = {line = 22, file = "live.ts"},["2363"] = {line = 27, file = "live.ts"},["2364"] = {line = 28, file = "live.ts"},["2365"] = {line = 29, file = "live.ts"},["2366"] = {line = 29, file = "live.ts"},["2367"] = {line = 29, file = "live.ts"},["2368"] = {line = 29, file = "live.ts"},["2369"] = {line = 29, file = "live.ts"},["2371"] = {line = 30, file = "live.ts"},["2372"] = {line = 27, file = "live.ts"},["2373"] = {line = 33, file = "live.ts"},["2374"] = {line = 34, file = "live.ts"},["2375"] = {line = 34, file = "live.ts"},["2377"] = {line = 34, file = "live.ts"},["2379"] = {line = 34, file = "live.ts"},["2380"] = {line = 35, file = "live.ts"},["2381"] = {line = 33, file = "live.ts"},["2382"] = {line = 38, file = "live.ts"},["2383"] = {line = 39, file = "live.ts"},["2384"] = {line = 40, file = "live.ts"},["2385"] = {line = 40, file = "live.ts"},["2387"] = {line = 41, file = "live.ts"},["2388"] = {line = 42, file = "live.ts"},["2389"] = {line = 42, file = "live.ts"},["2390"] = {line = 42, file = "live.ts"},["2394"] = {line = 43, file = "live.ts"},["2395"] = {line = 44, file = "live.ts"},["2396"] = {line = 45, file = "live.ts"},["2397"] = {line = 46, file = "live.ts"},["2398"] = {line = 43, file = "live.ts"},["2399"] = {line = 38, file = "live.ts"},["2400"] = {line = 51, file = "live.ts"},["2401"] = {line = 53, file = "live.ts"},["2402"] = {line = 54, file = "live.ts"},["2403"] = {line = 54, file = "live.ts"},["2405"] = {line = 55, file = "live.ts"},["2406"] = {line = 55, file = "live.ts"},["2408"] = {line = 56, file = "live.ts"},["2409"] = {line = 56, file = "live.ts"},["2410"] = {line = 56, file = "live.ts"},["2411"] = {line = 56, file = "live.ts"},["2412"] = {line = 53, file = "live.ts"},["2413"] = {line = 59, file = "live.ts"},["2414"] = {line = 60, file = "live.ts"},["2415"] = {line = 61, file = "live.ts"},["2416"] = {line = 62, file = "live.ts"},["2418"] = {line = 63, file = "live.ts"},["2419"] = {line = 64, file = "live.ts"},["2420"] = {line = 64, file = "live.ts"},["2422"] = {line = 65, file = "live.ts"},["2423"] = {line = 65, file = "live.ts"},["2425"] = {line = 66, file = "live.ts"},["2426"] = {line = 66, file = "live.ts"},["2427"] = {line = 66, file = "live.ts"},["2428"] = {line = 66, file = "live.ts"},["2429"] = {line = 66, file = "live.ts"},["2430"] = {line = 67, file = "live.ts"},["2431"] = {line = 68, file = "live.ts"},["2432"] = {line = 68, file = "live.ts"},["2433"] = {line = 68, file = "live.ts"},["2434"] = {line = 68, file = "live.ts"},["2435"] = {line = 70, file = "live.ts"},["2440"] = {line = 73, file = "live.ts"},["2441"] = {line = 59, file = "live.ts"},["2451"] = {line = 3, file = "patch.ts"},["2452"] = {line = 3, file = "patch.ts"},["2453"] = {line = 3, file = "patch.ts"},["2454"] = {line = 3, file = "patch.ts"},["2455"] = {line = 4, file = "patch.ts"},["2456"] = {line = 4, file = "patch.ts"},["2457"] = {line = 4, file = "patch.ts"},["2458"] = {line = 6, file = "patch.ts"},["2459"] = {line = 6, file = "patch.ts"},["2460"] = {line = 6, file = "patch.ts"},["2461"] = {line = 6, file = "patch.ts"},["2462"] = {line = 7, file = "patch.ts"},["2463"] = {line = 7, file = "patch.ts"},["2464"] = {line = 10, file = "patch.ts"},["2465"] = {line = 12, file = "patch.ts"},["2466"] = {line = 13, file = "patch.ts"},["2467"] = {line = 14, file = "patch.ts"},["2468"] = {line = 15, file = "patch.ts"},["2470"] = {line = 16, file = "patch.ts"},["2471"] = {line = 17, file = "patch.ts"},["2472"] = {line = 17, file = "patch.ts"},["2474"] = {line = 18, file = "patch.ts"},["2475"] = {line = 19, file = "patch.ts"},["2476"] = {line = 19, file = "patch.ts"},["2478"] = {line = 20, file = "patch.ts"},["2479"] = {line = 20, file = "patch.ts"},["2480"] = {line = 21, file = "patch.ts"},["2481"] = {line = 21, file = "patch.ts"},["2483"] = {line = 22, file = "patch.ts"},["2484"] = {line = 22, file = "patch.ts"},["2485"] = {line = 22, file = "patch.ts"},["2486"] = {line = 22, file = "patch.ts"},["2487"] = {line = 23, file = "patch.ts"},["2488"] = {line = 23, file = "patch.ts"},["2490"] = {line = 24, file = "patch.ts"},["2491"] = {line = 24, file = "patch.ts"},["2496"] = {line = 26, file = "patch.ts"},["2497"] = {line = 26, file = "patch.ts"},["2499"] = {line = 27, file = "patch.ts"},["2500"] = {line = 12, file = "patch.ts"},["2501"] = {line = 31, file = "patch.ts"},["2502"] = {line = 32, file = "patch.ts"},["2503"] = {line = 33, file = "patch.ts"},["2504"] = {line = 34, file = "patch.ts"},["2505"] = {line = 35, file = "patch.ts"},["2507"] = {line = 36, file = "patch.ts"},["2508"] = {line = 36, file = "patch.ts"},["2510"] = {line = 37, file = "patch.ts"},["2511"] = {line = 38, file = "patch.ts"},["2512"] = {line = 38, file = "patch.ts"},["2518"] = {line = 41, file = "patch.ts"},["2519"] = {line = 31, file = "patch.ts"},["2520"] = {line = 44, file = "patch.ts"},["2521"] = {line = 45, file = "patch.ts"},["2522"] = {line = 45, file = "patch.ts"},["2523"] = {line = 45, file = "patch.ts"},["2525"] = {line = 45, file = "patch.ts"},["2526"] = {line = 46, file = "patch.ts"},["2527"] = {line = 46, file = "patch.ts"},["2529"] = {line = 47, file = "patch.ts"},["2530"] = {line = 47, file = "patch.ts"},["2532"] = {line = 48, file = "patch.ts"},["2533"] = {line = 49, file = "patch.ts"},["2534"] = {line = 44, file = "patch.ts"},["2535"] = {line = 52, file = "patch.ts"},["2536"] = {line = 53, file = "patch.ts"},["2537"] = {line = 54, file = "patch.ts"},["2539"] = {line = 55, file = "patch.ts"},["2540"] = {line = 55, file = "patch.ts"},["2541"] = {line = 56, file = "patch.ts"},["2542"] = {line = 57, file = "patch.ts"},["2543"] = {line = 57, file = "patch.ts"},["2544"] = {line = 57, file = "patch.ts"},["2546"] = {line = 57, file = "patch.ts"},["2548"] = {line = 57, file = "patch.ts"},["2549"] = {line = 58, file = "patch.ts"},["2550"] = {line = 58, file = "patch.ts"},["2552"] = {line = 55, file = "patch.ts"},["2555"] = {line = 60, file = "patch.ts"},["2556"] = {line = 52, file = "patch.ts"},["2557"] = {line = 63, file = "patch.ts"},["2558"] = {line = 64, file = "patch.ts"},["2559"] = {line = 64, file = "patch.ts"},["2560"] = {line = 64, file = "patch.ts"},["2561"] = {line = 64, file = "patch.ts"},["2562"] = {line = 64, file = "patch.ts"},["2563"] = {line = 65, file = "patch.ts"},["2564"] = {line = 65, file = "patch.ts"},["2565"] = {line = 65, file = "patch.ts"},["2566"] = {line = 65, file = "patch.ts"},["2567"] = {line = 65, file = "patch.ts"},["2568"] = {line = 67, file = "patch.ts"},["2569"] = {line = 67, file = "patch.ts"},["2570"] = {line = 67, file = "patch.ts"},["2571"] = {line = 67, file = "patch.ts"},["2572"] = {line = 67, file = "patch.ts"},["2573"] = {line = 67, file = "patch.ts"},["2574"] = {line = 67, file = "patch.ts"},["2575"] = {line = 63, file = "patch.ts"},["2576"] = {line = 70, file = "patch.ts"},["2577"] = {line = 71, file = "patch.ts"},["2578"] = {line = 71, file = "patch.ts"},["2580"] = {line = 72, file = "patch.ts"},["2581"] = {line = 72, file = "patch.ts"},["2582"] = {line = 72, file = "patch.ts"},["2583"] = {line = 73, file = "patch.ts"},["2584"] = {line = 73, file = "patch.ts"},["2585"] = {line = 73, file = "patch.ts"},["2586"] = {line = 74, file = "patch.ts"},["2587"] = {line = 74, file = "patch.ts"},["2589"] = {line = 75, file = "patch.ts"},["2590"] = {line = 75, file = "patch.ts"},["2591"] = {line = 75, file = "patch.ts"},["2592"] = {line = 75, file = "patch.ts"},["2593"] = {line = 70, file = "patch.ts"},["2594"] = {line = 79, file = "patch.ts"},["2595"] = {line = 80, file = "patch.ts"},["2596"] = {line = 81, file = "patch.ts"},["2597"] = {line = 82, file = "patch.ts"},["2598"] = {line = 82, file = "patch.ts"},["2599"] = {line = 82, file = "patch.ts"},["2600"] = {line = 82, file = "patch.ts"},["2601"] = {line = 82, file = "patch.ts"},["2602"] = {line = 82, file = "patch.ts"},["2603"] = {line = 83, file = "patch.ts"},["2604"] = {line = 83, file = "patch.ts"},["2607"] = {line = 85, file = "patch.ts"},["2608"] = {line = 79, file = "patch.ts"},["2609"] = {line = 88, file = "patch.ts"},["2610"] = {line = 89, file = "patch.ts"},["2611"] = {line = 90, file = "patch.ts"},["2612"] = {line = 90, file = "patch.ts"},["2613"] = {line = 90, file = "patch.ts"},["2614"] = {line = 90, file = "patch.ts"},["2615"] = {line = 90, file = "patch.ts"},["2616"] = {line = 90, file = "patch.ts"},["2618"] = {line = 90, file = "patch.ts"},["2620"] = {line = 90, file = "patch.ts"},["2621"] = {line = 91, file = "patch.ts"},["2622"] = {line = 92, file = "patch.ts"},["2623"] = {line = 92, file = "patch.ts"},["2624"] = {line = 92, file = "patch.ts"},["2625"] = {line = 88, file = "patch.ts"},["2626"] = {line = 96, file = "patch.ts"},["2627"] = {line = 97, file = "patch.ts"},["2628"] = {line = 98, file = "patch.ts"},["2629"] = {line = 99, file = "patch.ts"},["2630"] = {line = 100, file = "patch.ts"},["2631"] = {line = 101, file = "patch.ts"},["2632"] = {line = 101, file = "patch.ts"},["2634"] = {line = 103, file = "patch.ts"},["2635"] = {line = 104, file = "patch.ts"},["2636"] = {line = 105, file = "patch.ts"},["2637"] = {line = 106, file = "patch.ts"},["2638"] = {line = 106, file = "patch.ts"},["2639"] = {line = 106, file = "patch.ts"},["2640"] = {line = 106, file = "patch.ts"},["2641"] = {line = 106, file = "patch.ts"},["2642"] = {line = 106, file = "patch.ts"},["2643"] = {line = 106, file = "patch.ts"},["2645"] = {line = 106, file = "patch.ts"},["2646"] = {line = 106, file = "patch.ts"},["2647"] = {line = 106, file = "patch.ts"},["2648"] = {line = 106, file = "patch.ts"},["2649"] = {line = 106, file = "patch.ts"},["2653"] = {line = 109, file = "patch.ts"},["2654"] = {line = 110, file = "patch.ts"},["2655"] = {line = 110, file = "patch.ts"},["2657"] = {line = 111, file = "patch.ts"},["2658"] = {line = 112, file = "patch.ts"},["2659"] = {line = 113, file = "patch.ts"},["2662"] = {line = 114, file = "patch.ts"},["2663"] = {line = 115, file = "patch.ts"},["2666"] = {line = 116, file = "patch.ts"},["2667"] = {line = 117, file = "patch.ts"},["2668"] = {line = 118, file = "patch.ts"},["2669"] = {line = 119, file = "patch.ts"},["2670"] = {line = 119, file = "patch.ts"},["2671"] = {line = 119, file = "patch.ts"},["2673"] = {line = 119, file = "patch.ts"},["2675"] = {line = 119, file = "patch.ts"},["2676"] = {line = 120, file = "patch.ts"},["2679"] = {line = 121, file = "patch.ts"},["2681"] = {line = 123, file = "patch.ts"},["2682"] = {line = 124, file = "patch.ts"},["2683"] = {line = 124, file = "patch.ts"},["2686"] = {line = 127, file = "patch.ts"},["2687"] = {line = 127, file = "patch.ts"},["2688"] = {line = 127, file = "patch.ts"},["2689"] = {line = 127, file = "patch.ts"},["2690"] = {line = 127, file = "patch.ts"},["2691"] = {line = 127, file = "patch.ts"},["2692"] = {line = 127, file = "patch.ts"},["2693"] = {line = 127, file = "patch.ts"},["2694"] = {line = 103, file = "patch.ts"},["2695"] = {line = 130, file = "patch.ts"},["2696"] = {line = 130, file = "patch.ts"},["2697"] = {line = 130, file = "patch.ts"},["2698"] = {line = 130, file = "patch.ts"},["2699"] = {line = 131, file = "patch.ts"},["2700"] = {line = 131, file = "patch.ts"},["2701"] = {line = 131, file = "patch.ts"},["2704"] = {line = 132, file = "patch.ts"},["2705"] = {line = 132, file = "patch.ts"},["2706"] = {line = 132, file = "patch.ts"},["2707"] = {line = 132, file = "patch.ts"},["2708"] = {line = 133, file = "patch.ts"},["2709"] = {line = 133, file = "patch.ts"},["2710"] = {line = 133, file = "patch.ts"},["2711"] = {line = 133, file = "patch.ts"},["2712"] = {line = 134, file = "patch.ts"},["2713"] = {line = 96, file = "patch.ts"},["2721"] = {line = 2, file = "ui.ts"},["2722"] = {line = 2, file = "ui.ts"},["2723"] = {line = 4, file = "ui.ts"},["2724"] = {line = 4, file = "ui.ts"},["2725"] = {line = 6, file = "ui.ts"},["2726"] = {line = 7, file = "ui.ts"},["2727"] = {line = 8, file = "ui.ts"},["2728"] = {line = 8, file = "ui.ts"},["2729"] = {line = 8, file = "ui.ts"},["2731"] = {line = 8, file = "ui.ts"},["2733"] = {line = 8, file = "ui.ts"},["2734"] = {line = 6, file = "ui.ts"},["2735"] = {line = 11, file = "ui.ts"},["2736"] = {line = 11, file = "ui.ts"},["2737"] = {line = 11, file = "ui.ts"},["2738"] = {line = 11, file = "ui.ts"},["2739"] = {line = 11, file = "ui.ts"},["2740"] = {line = 11, file = "ui.ts"},["2741"] = {line = 11, file = "ui.ts"},["2742"] = {line = 11, file = "ui.ts"},["2743"] = {line = 11, file = "ui.ts"},["2744"] = {line = 13, file = "ui.ts"},["2745"] = {line = 14, file = "ui.ts"},["2746"] = {line = 14, file = "ui.ts"},["2747"] = {line = 14, file = "ui.ts"},["2748"] = {line = 14, file = "ui.ts"},["2749"] = {line = 14, file = "ui.ts"},["2750"] = {line = 15, file = "ui.ts"},["2751"] = {line = 15, file = "ui.ts"},["2752"] = {line = 15, file = "ui.ts"},["2753"] = {line = 14, file = "ui.ts"},["2754"] = {line = 16, file = "ui.ts"},["2755"] = {line = 17, file = "ui.ts"},["2756"] = {line = 18, file = "ui.ts"},["2757"] = {line = 19, file = "ui.ts"},["2758"] = {line = 20, file = "ui.ts"},["2759"] = {line = 20, file = "ui.ts"},["2760"] = {line = 20, file = "ui.ts"},["2761"] = {line = 20, file = "ui.ts"},["2762"] = {line = 21, file = "ui.ts"},["2763"] = {line = 16, file = "ui.ts"},["2764"] = {line = 23, file = "ui.ts"},["2765"] = {line = 23, file = "ui.ts"},["2767"] = {line = 24, file = "ui.ts"},["2768"] = {line = 24, file = "ui.ts"},["2769"] = {line = 24, file = "ui.ts"},["2771"] = {line = 24, file = "ui.ts"},["2773"] = {line = 24, file = "ui.ts"},["2774"] = {line = 24, file = "ui.ts"},["2775"] = {line = 24, file = "ui.ts"},["2777"] = {line = 24, file = "ui.ts"},["2778"] = {line = 24, file = "ui.ts"},["2779"] = {line = 26, file = "ui.ts"},["2780"] = {line = 27, file = "ui.ts"},["2782"] = {line = 27, file = "ui.ts"},["2784"] = {line = 25, file = "ui.ts"},["2785"] = {line = 26, file = "ui.ts"},["2786"] = {line = 27, file = "ui.ts"},["2787"] = {line = 28, file = "ui.ts"},["2788"] = {line = 28, file = "ui.ts"},["2789"] = {line = 28, file = "ui.ts"},["2790"] = {line = 28, file = "ui.ts"},["2791"] = {line = 29, file = "ui.ts"},["2792"] = {line = 29, file = "ui.ts"},["2793"] = {line = 29, file = "ui.ts"},["2794"] = {line = 25, file = "ui.ts"},["2795"] = {line = 13, file = "ui.ts"},["2796"] = {line = 34, file = "ui.ts"},["2797"] = {line = 35, file = "ui.ts"},["2798"] = {line = 35, file = "ui.ts"},["2799"] = {line = 35, file = "ui.ts"},["2800"] = {line = 35, file = "ui.ts"},["2801"] = {line = 35, file = "ui.ts"},["2802"] = {line = 34, file = "ui.ts"},["2803"] = {line = 38, file = "ui.ts"},["2804"] = {line = 39, file = "ui.ts"},["2805"] = {line = 42, file = "ui.ts"},["2806"] = {line = 47, file = "ui.ts"},["2807"] = {line = 47, file = "ui.ts"},["2808"] = {line = 48, file = "ui.ts"},["2811"] = {line = 49, file = "ui.ts"},["2814"] = {line = 53, file = "ui.ts"},["2815"] = {line = 53, file = "ui.ts"},["2816"] = {line = 53, file = "ui.ts"},["2817"] = {line = 53, file = "ui.ts"},["2820"] = {line = 51, file = "ui.ts"},["2826"] = {line = 55, file = "ui.ts"},["2827"] = {line = 55, file = "ui.ts"},["2830"] = {line = 57, file = "ui.ts"},["2831"] = {line = 58, file = "ui.ts"},["2832"] = {line = 59, file = "ui.ts"},["2834"] = {line = 43, file = "ui.ts"},["2835"] = {line = 44, file = "ui.ts"},["2836"] = {line = 45, file = "ui.ts"},["2837"] = {line = 45, file = "ui.ts"},["2838"] = {line = 45, file = "ui.ts"},["2839"] = {line = 45, file = "ui.ts"},["2840"] = {line = 46, file = "ui.ts"},["2841"] = {line = 61, file = "ui.ts"},["2842"] = {line = 62, file = "ui.ts"},["2843"] = {line = 42, file = "ui.ts"},["2844"] = {line = 65, file = "ui.ts"},["2845"] = {line = 66, file = "ui.ts"},["2846"] = {line = 67, file = "ui.ts"},["2847"] = {line = 68, file = "ui.ts"},["2848"] = {line = 69, file = "ui.ts"},["2849"] = {line = 69, file = "ui.ts"},["2851"] = {line = 65, file = "ui.ts"},["2852"] = {line = 72, file = "ui.ts"},["2853"] = {line = 73, file = "ui.ts"},["2854"] = {line = 73, file = "ui.ts"},["2856"] = {line = 72, file = "ui.ts"},["2863"] = {line = 2, file = "undo.ts"},["2864"] = {line = 2, file = "undo.ts"},["2865"] = {line = 3, file = "undo.ts"},["2866"] = {line = 3, file = "undo.ts"},["2867"] = {line = 5, file = "undo.ts"},["2868"] = {line = 6, file = "undo.ts"},["2869"] = {line = 7, file = "undo.ts"},["2870"] = {line = 8, file = "undo.ts"},["2871"] = {line = 8, file = "undo.ts"},["2872"] = {line = 8, file = "undo.ts"},["2874"] = {line = 8, file = "undo.ts"},["2876"] = {line = 8, file = "undo.ts"},["2877"] = {line = 5, file = "undo.ts"},["2878"] = {line = 11, file = "undo.ts"},["2879"] = {line = 12, file = "undo.ts"},["2880"] = {line = 13, file = "undo.ts"},["2881"] = {line = 14, file = "undo.ts"},["2882"] = {line = 14, file = "undo.ts"},["2884"] = {line = 15, file = "undo.ts"},["2885"] = {line = 16, file = "undo.ts"},["2886"] = {line = 16, file = "undo.ts"},["2887"] = {line = 16, file = "undo.ts"},["2889"] = {line = 16, file = "undo.ts"},["2891"] = {line = 16, file = "undo.ts"},["2892"] = {line = 11, file = "undo.ts"},["2893"] = {line = 21, file = "undo.ts"},["2894"] = {line = 22, file = "undo.ts"},["2895"] = {line = 23, file = "undo.ts"},["2896"] = {line = 24, file = "undo.ts"},["2897"] = {line = 24, file = "undo.ts"},["2899"] = {line = 25, file = "undo.ts"},["2902"] = {line = 30, file = "undo.ts"},["2905"] = {line = 27, file = "undo.ts"},["2906"] = {line = 28, file = "undo.ts"},["2907"] = {line = 28, file = "undo.ts"},["2914"] = {line = 32, file = "undo.ts"},["2915"] = {line = 33, file = "undo.ts"},["2916"] = {line = 33, file = "undo.ts"},["2917"] = {line = 33, file = "undo.ts"},["2918"] = {line = 33, file = "undo.ts"},["2920"] = {line = 33, file = "undo.ts"},["2921"] = {line = 21, file = "undo.ts"},["2922"] = {line = 36, file = "undo.ts"},["2923"] = {line = 37, file = "undo.ts"},["2924"] = {line = 38, file = "undo.ts"},["2925"] = {line = 39, file = "undo.ts"},["2928"] = {line = 43, file = "undo.ts"},["2931"] = {line = 41, file = "undo.ts"},["2937"] = {line = 45, file = "undo.ts"},["2940"] = {line = 36, file = "undo.ts"},["2949"] = {line = 2, file = "vars.ts"},["2950"] = {line = 3, file = "vars.ts"},["2951"] = {line = 3, file = "vars.ts"},["2952"] = {line = 3, file = "vars.ts"},["2953"] = {line = 3, file = "vars.ts"},["2954"] = {line = 4, file = "vars.ts"},["2955"] = {line = 4, file = "vars.ts"},["2956"] = {line = 4, file = "vars.ts"},["2958"] = {line = 4, file = "vars.ts"},["2960"] = {line = 4, file = "vars.ts"},["2961"] = {line = 2, file = "vars.ts"},["2962"] = {line = 7, file = "vars.ts"},["2963"] = {line = 8, file = "vars.ts"},["2964"] = {line = 8, file = "vars.ts"},["2965"] = {line = 8, file = "vars.ts"},["2966"] = {line = 8, file = "vars.ts"},["2967"] = {line = 8, file = "vars.ts"},["2968"] = {line = 7, file = "vars.ts"},["2977"] = {line = 91, file = "ma-desk.ts"},["2978"] = {line = 3, file = "ma-desk.ts"},["2979"] = {line = 3, file = "ma-desk.ts"},["2980"] = {line = 7, file = "ma-desk.ts"},["2981"] = {line = 7, file = "ma-desk.ts"},["2982"] = {line = 8, file = "ma-desk.ts"},["2983"] = {line = 9, file = "ma-desk.ts"},["2984"] = {line = 10, file = "ma-desk.ts"},["2985"] = {line = 10, file = "ma-desk.ts"},["2986"] = {line = 10, file = "ma-desk.ts"},["2987"] = {line = 11, file = "ma-desk.ts"},["2988"] = {line = 11, file = "ma-desk.ts"},["2989"] = {line = 12, file = "ma-desk.ts"},["2990"] = {line = 13, file = "ma-desk.ts"},["2991"] = {line = 14, file = "ma-desk.ts"},["2992"] = {line = 15, file = "ma-desk.ts"},["2993"] = {line = 91, file = "ma-desk.ts"},["2996"] = {line = 95, file = "ma-desk.ts"},["2997"] = {line = 95, file = "ma-desk.ts"},["2998"] = {line = 95, file = "ma-desk.ts"},["2999"] = {line = 95, file = "ma-desk.ts"},["3002"] = {line = 93, file = "ma-desk.ts"},["3009"] = {line = 17, file = "ma-desk.ts"},["3010"] = {line = 17, file = "ma-desk.ts"},["3011"] = {line = 17, file = "ma-desk.ts"},["3013"] = {line = 18, file = "ma-desk.ts"},["3014"] = {line = 19, file = "ma-desk.ts"},["3015"] = {line = 17, file = "ma-desk.ts"},["3016"] = {line = 21, file = "ma-desk.ts"},["3017"] = {line = 21, file = "ma-desk.ts"},["3018"] = {line = 21, file = "ma-desk.ts"},["3019"] = {line = 22, file = "ma-desk.ts"},["3020"] = {line = 22, file = "ma-desk.ts"},["3021"] = {line = 22, file = "ma-desk.ts"},["3022"] = {line = 23, file = "ma-desk.ts"},["3023"] = {line = 23, file = "ma-desk.ts"},["3024"] = {line = 23, file = "ma-desk.ts"},["3025"] = {line = 24, file = "ma-desk.ts"},["3026"] = {line = 24, file = "ma-desk.ts"},["3027"] = {line = 24, file = "ma-desk.ts"},["3028"] = {line = 25, file = "ma-desk.ts"},["3029"] = {line = 26, file = "ma-desk.ts"},["3030"] = {line = 27, file = "ma-desk.ts"},["3031"] = {line = 25, file = "ma-desk.ts"},["3032"] = {line = 29, file = "ma-desk.ts"},["3033"] = {line = 30, file = "ma-desk.ts"},["3036"] = {line = 34, file = "ma-desk.ts"},["3037"] = {line = 34, file = "ma-desk.ts"},["3038"] = {line = 34, file = "ma-desk.ts"},["3039"] = {line = 34, file = "ma-desk.ts"},["3042"] = {line = 32, file = "ma-desk.ts"},["3048"] = {line = 36, file = "ma-desk.ts"},["3049"] = {line = 37, file = "ma-desk.ts"},["3052"] = {line = 41, file = "ma-desk.ts"},["3053"] = {line = 41, file = "ma-desk.ts"},["3054"] = {line = 41, file = "ma-desk.ts"},["3055"] = {line = 41, file = "ma-desk.ts"},["3058"] = {line = 39, file = "ma-desk.ts"},["3064"] = {line = 43, file = "ma-desk.ts"},["3065"] = {line = 44, file = "ma-desk.ts"},["3066"] = {line = 45, file = "ma-desk.ts"},["3067"] = {line = 46, file = "ma-desk.ts"},["3068"] = {line = 46, file = "ma-desk.ts"},["3070"] = {line = 47, file = "ma-desk.ts"},["3071"] = {line = 47, file = "ma-desk.ts"},["3072"] = {line = 47, file = "ma-desk.ts"},["3073"] = {line = 47, file = "ma-desk.ts"},["3074"] = {line = 47, file = "ma-desk.ts"},["3075"] = {line = 48, file = "ma-desk.ts"},["3076"] = {line = 48, file = "ma-desk.ts"},["3077"] = {line = 48, file = "ma-desk.ts"},["3078"] = {line = 48, file = "ma-desk.ts"},["3079"] = {line = 49, file = "ma-desk.ts"},["3080"] = {line = 50, file = "ma-desk.ts"},["3081"] = {line = 50, file = "ma-desk.ts"},["3082"] = {line = 50, file = "ma-desk.ts"},["3083"] = {line = 50, file = "ma-desk.ts"},["3084"] = {line = 50, file = "ma-desk.ts"},["3085"] = {line = 50, file = "ma-desk.ts"},["3086"] = {line = 51, file = "ma-desk.ts"},["3087"] = {line = 51, file = "ma-desk.ts"},["3088"] = {line = 51, file = "ma-desk.ts"},["3089"] = {line = 51, file = "ma-desk.ts"},["3090"] = {line = 52, file = "ma-desk.ts"},["3091"] = {line = 53, file = "ma-desk.ts"},["3092"] = {line = 53, file = "ma-desk.ts"},["3093"] = {line = 53, file = "ma-desk.ts"},["3094"] = {line = 53, file = "ma-desk.ts"},["3095"] = {line = 53, file = "ma-desk.ts"},["3096"] = {line = 53, file = "ma-desk.ts"},["3097"] = {line = 54, file = "ma-desk.ts"},["3098"] = {line = 54, file = "ma-desk.ts"},["3099"] = {line = 54, file = "ma-desk.ts"},["3100"] = {line = 54, file = "ma-desk.ts"},["3103"] = {line = 29, file = "ma-desk.ts"},["3104"] = {line = 58, file = "ma-desk.ts"},["3105"] = {line = 58, file = "ma-desk.ts"},["3106"] = {line = 58, file = "ma-desk.ts"},["3107"] = {line = 59, file = "ma-desk.ts"},["3108"] = {line = 59, file = "ma-desk.ts"},["3109"] = {line = 59, file = "ma-desk.ts"},["3110"] = {line = 60, file = "ma-desk.ts"},["3111"] = {line = 60, file = "ma-desk.ts"},["3112"] = {line = 60, file = "ma-desk.ts"},["3113"] = {line = 61, file = "ma-desk.ts"},["3114"] = {line = 61, file = "ma-desk.ts"},["3115"] = {line = 61, file = "ma-desk.ts"},["3116"] = {line = 62, file = "ma-desk.ts"},["3117"] = {line = 62, file = "ma-desk.ts"},["3118"] = {line = 62, file = "ma-desk.ts"},["3119"] = {line = 64, file = "ma-desk.ts"},["3120"] = {line = 65, file = "ma-desk.ts"},["3121"] = {line = 66, file = "ma-desk.ts"},["3122"] = {line = 66, file = "ma-desk.ts"},["3124"] = {line = 67, file = "ma-desk.ts"},["3125"] = {line = 67, file = "ma-desk.ts"},["3126"] = {line = 67, file = "ma-desk.ts"},["3127"] = {line = 67, file = "ma-desk.ts"},["3128"] = {line = 68, file = "ma-desk.ts"},["3129"] = {line = 68, file = "ma-desk.ts"},["3130"] = {line = 68, file = "ma-desk.ts"},["3131"] = {line = 68, file = "ma-desk.ts"},["3132"] = {line = 68, file = "ma-desk.ts"},["3134"] = {line = 64, file = "ma-desk.ts"},["3135"] = {line = 71, file = "ma-desk.ts"},["3136"] = {line = 72, file = "ma-desk.ts"},["3137"] = {line = 73, file = "ma-desk.ts"},["3138"] = {line = 73, file = "ma-desk.ts"},["3140"] = {line = 74, file = "ma-desk.ts"},["3141"] = {line = 75, file = "ma-desk.ts"},["3142"] = {line = 71, file = "ma-desk.ts"},["3143"] = {line = 77, file = "ma-desk.ts"},["3144"] = {line = 77, file = "ma-desk.ts"},["3145"] = {line = 77, file = "ma-desk.ts"},["3146"] = {line = 78, file = "ma-desk.ts"},["3147"] = {line = 78, file = "ma-desk.ts"},["3148"] = {line = 78, file = "ma-desk.ts"},["3149"] = {line = 79, file = "ma-desk.ts"},["3150"] = {line = 79, file = "ma-desk.ts"},["3151"] = {line = 79, file = "ma-desk.ts"},["3152"] = {line = 80, file = "ma-desk.ts"},["3153"] = {line = 80, file = "ma-desk.ts"},["3154"] = {line = 80, file = "ma-desk.ts"},["3155"] = {line = 81, file = "ma-desk.ts"},["3156"] = {line = 81, file = "ma-desk.ts"},["3157"] = {line = 81, file = "ma-desk.ts"},["3158"] = {line = 82, file = "ma-desk.ts"},["3159"] = {line = 82, file = "ma-desk.ts"},["3160"] = {line = 82, file = "ma-desk.ts"},["3161"] = {line = 83, file = "ma-desk.ts"},["3162"] = {line = 83, file = "ma-desk.ts"},["3163"] = {line = 83, file = "ma-desk.ts"},["3164"] = {line = 84, file = "ma-desk.ts"},["3165"] = {line = 84, file = "ma-desk.ts"},["3166"] = {line = 84, file = "ma-desk.ts"},["3167"] = {line = 85, file = "ma-desk.ts"},["3168"] = {line = 85, file = "ma-desk.ts"},["3169"] = {line = 85, file = "ma-desk.ts"},["3170"] = {line = 86, file = "ma-desk.ts"},["3171"] = {line = 86, file = "ma-desk.ts"},["3172"] = {line = 86, file = "ma-desk.ts"},["3173"] = {line = 87, file = "ma-desk.ts"},["3174"] = {line = 87, file = "ma-desk.ts"},["3175"] = {line = 87, file = "ma-desk.ts"},["3176"] = {line = 88, file = "ma-desk.ts"},["3177"] = {line = 88, file = "ma-desk.ts"},["3178"] = {line = 88, file = "ma-desk.ts"},["3179"] = {line = 99, file = "ma-desk.ts"},["3180"] = {line = 100, file = "ma-desk.ts"},["3181"] = {line = 99, file = "ma-desk.ts"},["3192"] = {line = 2, file = "arm-command.ts"},["3193"] = {line = 2, file = "arm-command.ts"},["3194"] = {line = 4, file = "arm-command.ts"},["3195"] = {line = 5, file = "arm-command.ts"},["3196"] = {line = 6, file = "arm-command.ts"},["3197"] = {line = 7, file = "arm-command.ts"},["3198"] = {line = 8, file = "arm-command.ts"},["3199"] = {line = 9, file = "arm-command.ts"},["3200"] = {line = 10, file = "arm-command.ts"},["3203"] = {line = 13, file = "arm-command.ts"},["3204"] = {line = 13, file = "arm-command.ts"},["3205"] = {line = 13, file = "arm-command.ts"},["3206"] = {line = 13, file = "arm-command.ts"},["3207"] = {line = 14, file = "arm-command.ts"},["3208"] = {line = 4, file = "arm-command.ts"},["3209"] = {line = 17, file = "arm-command.ts"},["3210"] = {line = 18, file = "arm-command.ts"},["3211"] = {line = 19, file = "arm-command.ts"},["3212"] = {line = 20, file = "arm-command.ts"},["3213"] = {line = 21, file = "arm-command.ts"},["3214"] = {line = 21, file = "arm-command.ts"},["3217"] = {line = 23, file = "arm-command.ts"},["3218"] = {line = 17, file = "arm-command.ts"},["3226"] = {line = 2, file = "program.ts"},["3227"] = {line = 2, file = "program.ts"},["3228"] = {line = 2, file = "program.ts"},["3229"] = {line = 7, file = "program.ts"},["3230"] = {line = 8, file = "program.ts"},["3231"] = {line = 8, file = "program.ts"},["3232"] = {line = 8, file = "program.ts"},["3233"] = {line = 8, file = "program.ts"},["3234"] = {line = 9, file = "program.ts"},["3235"] = {line = 10, file = "program.ts"},["3236"] = {line = 11, file = "program.ts"},["3238"] = {line = 13, file = "program.ts"},["3239"] = {line = 14, file = "program.ts"},["3240"] = {line = 15, file = "program.ts"},["3242"] = {line = 17, file = "program.ts"},["3243"] = {line = 7, file = "program.ts"},["3244"] = {line = 20, file = "program.ts"},["3245"] = {line = 21, file = "program.ts"},["3246"] = {line = 20, file = "program.ts"},["3265"] = {line = 2, file = "autozoom.ts"},["3266"] = {line = 2, file = "autozoom.ts"},["3267"] = {line = 2, file = "autozoom.ts"},["3268"] = {line = 3, file = "autozoom.ts"},["3269"] = {line = 3, file = "autozoom.ts"},["3270"] = {line = 3, file = "autozoom.ts"},["3271"] = {line = 4, file = "autozoom.ts"},["3272"] = {line = 4, file = "autozoom.ts"},["3273"] = {line = 4, file = "autozoom.ts"},["3274"] = {line = 5, file = "autozoom.ts"},["3275"] = {line = 5, file = "autozoom.ts"},["3276"] = {line = 6, file = "autozoom.ts"},["3277"] = {line = 6, file = "autozoom.ts"},["3278"] = {line = 8, file = "autozoom.ts"},["3279"] = {line = 8, file = "autozoom.ts"},["3280"] = {line = 8, file = "autozoom.ts"},["3281"] = {line = 8, file = "autozoom.ts"},["3282"] = {line = 10, file = "autozoom.ts"},["3283"] = {line = 10, file = "autozoom.ts"},["3284"] = {line = 10, file = "autozoom.ts"},["3285"] = {line = 10, file = "autozoom.ts"},["3286"] = {line = 10, file = "autozoom.ts"},["3287"] = {line = 10, file = "autozoom.ts"},["3288"] = {line = 10, file = "autozoom.ts"},["3289"] = {line = 10, file = "autozoom.ts"},["3290"] = {line = 10, file = "autozoom.ts"},["3291"] = {line = 11, file = "autozoom.ts"},["3292"] = {line = 11, file = "autozoom.ts"},["3293"] = {line = 11, file = "autozoom.ts"},["3294"] = {line = 11, file = "autozoom.ts"},["3295"] = {line = 13, file = "autozoom.ts"},["3296"] = {line = 17, file = "autozoom.ts"},["3297"] = {line = 17, file = "autozoom.ts"},["3298"] = {line = 17, file = "autozoom.ts"},["3299"] = {line = 34, file = "autozoom.ts"},["3300"] = {line = 34, file = "autozoom.ts"},["3301"] = {line = 34, file = "autozoom.ts"},["3302"] = {line = 18, file = "autozoom.ts"},["3303"] = {line = 19, file = "autozoom.ts"},["3304"] = {line = 20, file = "autozoom.ts"},["3305"] = {line = 21, file = "autozoom.ts"},["3306"] = {line = 25, file = "autozoom.ts"},["3307"] = {line = 26, file = "autozoom.ts"},["3308"] = {line = 27, file = "autozoom.ts"},["3309"] = {line = 28, file = "autozoom.ts"},["3310"] = {line = 29, file = "autozoom.ts"},["3311"] = {line = 32, file = "autozoom.ts"},["3312"] = {line = 34, file = "autozoom.ts"},["3313"] = {line = 37, file = "autozoom.ts"},["3314"] = {line = 38, file = "autozoom.ts"},["3315"] = {line = 37, file = "autozoom.ts"},["3316"] = {line = 41, file = "autozoom.ts"},["3317"] = {line = 42, file = "autozoom.ts"},["3318"] = {line = 42, file = "autozoom.ts"},["3320"] = {line = 43, file = "autozoom.ts"},["3321"] = {line = 44, file = "autozoom.ts"},["3322"] = {line = 41, file = "autozoom.ts"},["3323"] = {line = 47, file = "autozoom.ts"},["3324"] = {line = 48, file = "autozoom.ts"},["3325"] = {line = 49, file = "autozoom.ts"},["3326"] = {line = 49, file = "autozoom.ts"},["3328"] = {line = 50, file = "autozoom.ts"},["3329"] = {line = 51, file = "autozoom.ts"},["3330"] = {line = 52, file = "autozoom.ts"},["3331"] = {line = 47, file = "autozoom.ts"},["3332"] = {line = 55, file = "autozoom.ts"},["3333"] = {line = 56, file = "autozoom.ts"},["3336"] = {line = 57, file = "autozoom.ts"},["3337"] = {line = 58, file = "autozoom.ts"},["3338"] = {line = 59, file = "autozoom.ts"},["3339"] = {line = 60, file = "autozoom.ts"},["3340"] = {line = 60, file = "autozoom.ts"},["3342"] = {line = 62, file = "autozoom.ts"},["3343"] = {line = 62, file = "autozoom.ts"},["3344"] = {line = 62, file = "autozoom.ts"},["3345"] = {line = 62, file = "autozoom.ts"},["3346"] = {line = 63, file = "autozoom.ts"},["3347"] = {line = 64, file = "autozoom.ts"},["3348"] = {line = 64, file = "autozoom.ts"},["3350"] = {line = 65, file = "autozoom.ts"},["3351"] = {line = 65, file = "autozoom.ts"},["3352"] = {line = 65, file = "autozoom.ts"},["3353"] = {line = 65, file = "autozoom.ts"},["3354"] = {line = 65, file = "autozoom.ts"},["3355"] = {line = 65, file = "autozoom.ts"},["3356"] = {line = 65, file = "autozoom.ts"},["3357"] = {line = 66, file = "autozoom.ts"},["3358"] = {line = 67, file = "autozoom.ts"},["3359"] = {line = 68, file = "autozoom.ts"},["3360"] = {line = 69, file = "autozoom.ts"},["3361"] = {line = 70, file = "autozoom.ts"},["3362"] = {line = 71, file = "autozoom.ts"},["3363"] = {line = 55, file = "autozoom.ts"},["3364"] = {line = 75, file = "autozoom.ts"},["3365"] = {line = 76, file = "autozoom.ts"},["3368"] = {line = 77, file = "autozoom.ts"},["3369"] = {line = 75, file = "autozoom.ts"},["3370"] = {line = 81, file = "autozoom.ts"},["3371"] = {line = 82, file = "autozoom.ts"},["3372"] = {line = 81, file = "autozoom.ts"},["3373"] = {line = 85, file = "autozoom.ts"},["3374"] = {line = 86, file = "autozoom.ts"},["3377"] = {line = 87, file = "autozoom.ts"},["3380"] = {line = 88, file = "autozoom.ts"},["3381"] = {line = 89, file = "autozoom.ts"},["3382"] = {line = 89, file = "autozoom.ts"},["3383"] = {line = 89, file = "autozoom.ts"},["3384"] = {line = 89, file = "autozoom.ts"},["3385"] = {line = 90, file = "autozoom.ts"},["3386"] = {line = 91, file = "autozoom.ts"},["3387"] = {line = 92, file = "autozoom.ts"},["3388"] = {line = 92, file = "autozoom.ts"},["3389"] = {line = 92, file = "autozoom.ts"},["3391"] = {line = 92, file = "autozoom.ts"},["3392"] = {line = 93, file = "autozoom.ts"},["3393"] = {line = 93, file = "autozoom.ts"},["3394"] = {line = 93, file = "autozoom.ts"},["3396"] = {line = 93, file = "autozoom.ts"},["3397"] = {line = 90, file = "autozoom.ts"},["3398"] = {line = 95, file = "autozoom.ts"},["3399"] = {line = 85, file = "autozoom.ts"},["3400"] = {line = 98, file = "autozoom.ts"},["3401"] = {line = 99, file = "autozoom.ts"},["3402"] = {line = 101, file = "autozoom.ts"},["3405"] = {line = 102, file = "autozoom.ts"},["3406"] = {line = 103, file = "autozoom.ts"},["3407"] = {line = 104, file = "autozoom.ts"},["3410"] = {line = 107, file = "autozoom.ts"},["3411"] = {line = 108, file = "autozoom.ts"},["3414"] = {line = 109, file = "autozoom.ts"},["3415"] = {line = 110, file = "autozoom.ts"},["3416"] = {line = 111, file = "autozoom.ts"},["3417"] = {line = 112, file = "autozoom.ts"},["3418"] = {line = 112, file = "autozoom.ts"},["3420"] = {line = 114, file = "autozoom.ts"},["3423"] = {line = 118, file = "autozoom.ts"},["3424"] = {line = 118, file = "autozoom.ts"},["3425"] = {line = 118, file = "autozoom.ts"},["3426"] = {line = 118, file = "autozoom.ts"},["3429"] = {line = 116, file = "autozoom.ts"},["3435"] = {line = 120, file = "autozoom.ts"},["3436"] = {line = 98, file = "autozoom.ts"},["3437"] = {line = 123, file = "autozoom.ts"},["3438"] = {line = 124, file = "autozoom.ts"},["3441"] = {line = 125, file = "autozoom.ts"},["3442"] = {line = 125, file = "autozoom.ts"},["3444"] = {line = 125, file = "autozoom.ts"},["3446"] = {line = 123, file = "autozoom.ts"},["3447"] = {line = 129, file = "autozoom.ts"},["3448"] = {line = 130, file = "autozoom.ts"},["3451"] = {line = 131, file = "autozoom.ts"},["3452"] = {line = 129, file = "autozoom.ts"},["3453"] = {line = 134, file = "autozoom.ts"},["3454"] = {line = 135, file = "autozoom.ts"},["3457"] = {line = 136, file = "autozoom.ts"},["3458"] = {line = 137, file = "autozoom.ts"},["3461"] = {line = 140, file = "autozoom.ts"},["3462"] = {line = 140, file = "autozoom.ts"},["3463"] = {line = 140, file = "autozoom.ts"},["3464"] = {line = 140, file = "autozoom.ts"},["3465"] = {line = 141, file = "autozoom.ts"},["3466"] = {line = 141, file = "autozoom.ts"},["3468"] = {line = 142, file = "autozoom.ts"},["3469"] = {line = 143, file = "autozoom.ts"},["3470"] = {line = 144, file = "autozoom.ts"},["3471"] = {line = 134, file = "autozoom.ts"},["3472"] = {line = 147, file = "autozoom.ts"},["3473"] = {line = 148, file = "autozoom.ts"},["3476"] = {line = 149, file = "autozoom.ts"},["3477"] = {line = 149, file = "autozoom.ts"},["3478"] = {line = 149, file = "autozoom.ts"},["3479"] = {line = 149, file = "autozoom.ts"},["3480"] = {line = 147, file = "autozoom.ts"},["3481"] = {line = 152, file = "autozoom.ts"},["3482"] = {line = 153, file = "autozoom.ts"},["3485"] = {line = 154, file = "autozoom.ts"},["3486"] = {line = 152, file = "autozoom.ts"},["3487"] = {line = 157, file = "autozoom.ts"},["3488"] = {line = 158, file = "autozoom.ts"},["3491"] = {line = 159, file = "autozoom.ts"},["3492"] = {line = 159, file = "autozoom.ts"},["3493"] = {line = 159, file = "autozoom.ts"},["3494"] = {line = 159, file = "autozoom.ts"},["3495"] = {line = 160, file = "autozoom.ts"},["3496"] = {line = 161, file = "autozoom.ts"},["3497"] = {line = 162, file = "autozoom.ts"},["3499"] = {line = 157, file = "autozoom.ts"},["3500"] = {line = 167, file = "autozoom.ts"},["3501"] = {line = 168, file = "autozoom.ts"},["3504"] = {line = 169, file = "autozoom.ts"},["3505"] = {line = 170, file = "autozoom.ts"},["3506"] = {line = 171, file = "autozoom.ts"},["3509"] = {line = 174, file = "autozoom.ts"},["3510"] = {line = 175, file = "autozoom.ts"},["3512"] = {line = 177, file = "autozoom.ts"},["3514"] = {line = 179, file = "autozoom.ts"},["3515"] = {line = 181, file = "autozoom.ts"},["3516"] = {line = 182, file = "autozoom.ts"},["3518"] = {line = 184, file = "autozoom.ts"},["3519"] = {line = 167, file = "autozoom.ts"},["3520"] = {line = 187, file = "autozoom.ts"},["3521"] = {line = 188, file = "autozoom.ts"},["3524"] = {line = 189, file = "autozoom.ts"},["3525"] = {line = 190, file = "autozoom.ts"},["3526"] = {line = 191, file = "autozoom.ts"},["3529"] = {line = 192, file = "autozoom.ts"},["3530"] = {line = 193, file = "autozoom.ts"},["3531"] = {line = 194, file = "autozoom.ts"},["3532"] = {line = 195, file = "autozoom.ts"},["3533"] = {line = 196, file = "autozoom.ts"},["3536"] = {line = 199, file = "autozoom.ts"},["3537"] = {line = 200, file = "autozoom.ts"},["3538"] = {line = 201, file = "autozoom.ts"},["3539"] = {line = 201, file = "autozoom.ts"},["3541"] = {line = 202, file = "autozoom.ts"},["3542"] = {line = 203, file = "autozoom.ts"},["3543"] = {line = 204, file = "autozoom.ts"},["3544"] = {line = 204, file = "autozoom.ts"},["3546"] = {line = 205, file = "autozoom.ts"},["3547"] = {line = 206, file = "autozoom.ts"},["3548"] = {line = 189, file = "autozoom.ts"},["3549"] = {line = 187, file = "autozoom.ts"},["3550"] = {line = 210, file = "autozoom.ts"},["3551"] = {line = 211, file = "autozoom.ts"},["3554"] = {line = 212, file = "autozoom.ts"},["3555"] = {line = 213, file = "autozoom.ts"},["3556"] = {line = 214, file = "autozoom.ts"},["3559"] = {line = 217, file = "autozoom.ts"},["3560"] = {line = 218, file = "autozoom.ts"},["3561"] = {line = 219, file = "autozoom.ts"},["3562"] = {line = 220, file = "autozoom.ts"},["3563"] = {line = 220, file = "autozoom.ts"},["3564"] = {line = 220, file = "autozoom.ts"},["3565"] = {line = 220, file = "autozoom.ts"},["3566"] = {line = 221, file = "autozoom.ts"},["3569"] = {line = 222, file = "autozoom.ts"},["3570"] = {line = 222, file = "autozoom.ts"},["3571"] = {line = 222, file = "autozoom.ts"},["3572"] = {line = 222, file = "autozoom.ts"},["3573"] = {line = 222, file = "autozoom.ts"},["3574"] = {line = 223, file = "autozoom.ts"},["3575"] = {line = 224, file = "autozoom.ts"},["3577"] = {line = 226, file = "autozoom.ts"},["3578"] = {line = 227, file = "autozoom.ts"},["3579"] = {line = 228, file = "autozoom.ts"},["3582"] = {line = 231, file = "autozoom.ts"},["3584"] = {line = 233, file = "autozoom.ts"},["3585"] = {line = 234, file = "autozoom.ts"},["3586"] = {line = 217, file = "autozoom.ts"},["3587"] = {line = 210, file = "autozoom.ts"},["3588"] = {line = 239, file = "autozoom.ts"},["3589"] = {line = 240, file = "autozoom.ts"},["3590"] = {line = 241, file = "autozoom.ts"},["3591"] = {line = 242, file = "autozoom.ts"},["3592"] = {line = 243, file = "autozoom.ts"},["3593"] = {line = 244, file = "autozoom.ts"},["3596"] = {line = 247, file = "autozoom.ts"},["3597"] = {line = 248, file = "autozoom.ts"},["3598"] = {line = 248, file = "autozoom.ts"},["3600"] = {line = 239, file = "autozoom.ts"},["3601"] = {line = 251, file = "autozoom.ts"},["3602"] = {line = 253, file = "autozoom.ts"},["3603"] = {line = 254, file = "autozoom.ts"},["3604"] = {line = 251, file = "autozoom.ts"},["3605"] = {line = 258, file = "autozoom.ts"},["3606"] = {line = 259, file = "autozoom.ts"},["3608"] = {line = 260, file = "autozoom.ts"},["3609"] = {line = 261, file = "autozoom.ts"},["3610"] = {line = 261, file = "autozoom.ts"},["3614"] = {line = 265, file = "autozoom.ts"},["3615"] = {line = 265, file = "autozoom.ts"},["3616"] = {line = 265, file = "autozoom.ts"},["3617"] = {line = 265, file = "autozoom.ts"},["3620"] = {line = 263, file = "autozoom.ts"},["3626"] = {line = 267, file = "autozoom.ts"},["3630"] = {line = 258, file = "autozoom.ts"},["3631"] = {line = 271, file = "autozoom.ts"},["3632"] = {line = 272, file = "autozoom.ts"},["3633"] = {line = 273, file = "autozoom.ts"},["3634"] = {line = 274, file = "autozoom.ts"},["3635"] = {line = 275, file = "autozoom.ts"},["3638"] = {line = 279, file = "autozoom.ts"},["3639"] = {line = 279, file = "autozoom.ts"},["3640"] = {line = 279, file = "autozoom.ts"},["3641"] = {line = 279, file = "autozoom.ts"},["3644"] = {line = 277, file = "autozoom.ts"},["3651"] = {line = 282, file = "autozoom.ts"},["3652"] = {line = 271, file = "autozoom.ts"},["3653"] = {line = 285, file = "autozoom.ts"},["3654"] = {line = 286, file = "autozoom.ts"},["3657"] = {line = 287, file = "autozoom.ts"},["3658"] = {line = 287, file = "autozoom.ts"},["3661"] = {line = 288, file = "autozoom.ts"},["3662"] = {line = 285, file = "autozoom.ts"},["3663"] = {line = 291, file = "autozoom.ts"},["3664"] = {line = 292, file = "autozoom.ts"},["3665"] = {line = 292, file = "autozoom.ts"},["3668"] = {line = 293, file = "autozoom.ts"},["3669"] = {line = 294, file = "autozoom.ts"},["3670"] = {line = 295, file = "autozoom.ts"},["3671"] = {line = 296, file = "autozoom.ts"},["3672"] = {line = 297, file = "autozoom.ts"},["3673"] = {line = 298, file = "autozoom.ts"},["3674"] = {line = 291, file = "autozoom.ts"},["3675"] = {line = 301, file = "autozoom.ts"},["3676"] = {line = 302, file = "autozoom.ts"},["3679"] = {line = 303, file = "autozoom.ts"},["3680"] = {line = 303, file = "autozoom.ts"},["3683"] = {line = 304, file = "autozoom.ts"},["3684"] = {line = 305, file = "autozoom.ts"},["3687"] = {line = 306, file = "autozoom.ts"},["3688"] = {line = 307, file = "autozoom.ts"},["3689"] = {line = 308, file = "autozoom.ts"},["3690"] = {line = 308, file = "autozoom.ts"},["3691"] = {line = 308, file = "autozoom.ts"},["3692"] = {line = 308, file = "autozoom.ts"},["3693"] = {line = 308, file = "autozoom.ts"},["3694"] = {line = 308, file = "autozoom.ts"},["3695"] = {line = 309, file = "autozoom.ts"},["3696"] = {line = 310, file = "autozoom.ts"},["3697"] = {line = 311, file = "autozoom.ts"},["3701"] = {line = 315, file = "autozoom.ts"},["3702"] = {line = 316, file = "autozoom.ts"},["3703"] = {line = 318, file = "autozoom.ts"},["3704"] = {line = 319, file = "autozoom.ts"},["3705"] = {line = 321, file = "autozoom.ts"},["3706"] = {line = 321, file = "autozoom.ts"},["3708"] = {line = 322, file = "autozoom.ts"},["3709"] = {line = 301, file = "autozoom.ts"},["3710"] = {line = 325, file = "autozoom.ts"},["3711"] = {line = 326, file = "autozoom.ts"},["3712"] = {line = 327, file = "autozoom.ts"},["3713"] = {line = 328, file = "autozoom.ts"},["3714"] = {line = 329, file = "autozoom.ts"},["3715"] = {line = 325, file = "autozoom.ts"},["3716"] = {line = 332, file = "autozoom.ts"},["3719"] = {line = 336, file = "autozoom.ts"},["3722"] = {line = 334, file = "autozoom.ts"},["3728"] = {line = 332, file = "autozoom.ts"},["3729"] = {line = 340, file = "autozoom.ts"},["3730"] = {line = 341, file = "autozoom.ts"},["3731"] = {line = 342, file = "autozoom.ts"},["3732"] = {line = 343, file = "autozoom.ts"},["3733"] = {line = 343, file = "autozoom.ts"},["3734"] = {line = 343, file = "autozoom.ts"},["3735"] = {line = 343, file = "autozoom.ts"},["3736"] = {line = 343, file = "autozoom.ts"},["3737"] = {line = 344, file = "autozoom.ts"},["3738"] = {line = 345, file = "autozoom.ts"},["3739"] = {line = 346, file = "autozoom.ts"},["3740"] = {line = 346, file = "autozoom.ts"},["3741"] = {line = 346, file = "autozoom.ts"},["3742"] = {line = 346, file = "autozoom.ts"},["3743"] = {line = 347, file = "autozoom.ts"},["3744"] = {line = 348, file = "autozoom.ts"},["3745"] = {line = 348, file = "autozoom.ts"},["3746"] = {line = 348, file = "autozoom.ts"},["3747"] = {line = 348, file = "autozoom.ts"},["3749"] = {line = 350, file = "autozoom.ts"},["3750"] = {line = 351, file = "autozoom.ts"},["3751"] = {line = 351, file = "autozoom.ts"},["3752"] = {line = 351, file = "autozoom.ts"},["3753"] = {line = 351, file = "autozoom.ts"},["3754"] = {line = 352, file = "autozoom.ts"},["3755"] = {line = 352, file = "autozoom.ts"},["3756"] = {line = 352, file = "autozoom.ts"},["3757"] = {line = 352, file = "autozoom.ts"},["3758"] = {line = 350, file = "autozoom.ts"},["3759"] = {line = 354, file = "autozoom.ts"},["3760"] = {line = 355, file = "autozoom.ts"},["3761"] = {line = 340, file = "autozoom.ts"},["3762"] = {line = 358, file = "autozoom.ts"},["3763"] = {line = 359, file = "autozoom.ts"},["3766"] = {line = 360, file = "autozoom.ts"},["3767"] = {line = 361, file = "autozoom.ts"},["3768"] = {line = 362, file = "autozoom.ts"},["3771"] = {line = 363, file = "autozoom.ts"},["3772"] = {line = 364, file = "autozoom.ts"},["3773"] = {line = 364, file = "autozoom.ts"},["3775"] = {line = 365, file = "autozoom.ts"},["3777"] = {line = 358, file = "autozoom.ts"},["3778"] = {line = 368, file = "autozoom.ts"},["3779"] = {line = 369, file = "autozoom.ts"},["3780"] = {line = 370, file = "autozoom.ts"},["3781"] = {line = 371, file = "autozoom.ts"},["3782"] = {line = 372, file = "autozoom.ts"},["3783"] = {line = 372, file = "autozoom.ts"},["3784"] = {line = 372, file = "autozoom.ts"},["3785"] = {line = 372, file = "autozoom.ts"},["3786"] = {line = 372, file = "autozoom.ts"},["3787"] = {line = 373, file = "autozoom.ts"},["3788"] = {line = 374, file = "autozoom.ts"},["3789"] = {line = 374, file = "autozoom.ts"},["3790"] = {line = 374, file = "autozoom.ts"},["3791"] = {line = 374, file = "autozoom.ts"},["3792"] = {line = 374, file = "autozoom.ts"},["3793"] = {line = 375, file = "autozoom.ts"},["3794"] = {line = 376, file = "autozoom.ts"},["3795"] = {line = 376, file = "autozoom.ts"},["3796"] = {line = 373, file = "autozoom.ts"},["3798"] = {line = 379, file = "autozoom.ts"},["3799"] = {line = 380, file = "autozoom.ts"},["3800"] = {line = 380, file = "autozoom.ts"},["3801"] = {line = 380, file = "autozoom.ts"},["3804"] = {line = 381, file = "autozoom.ts"},["3805"] = {line = 381, file = "autozoom.ts"},["3806"] = {line = 381, file = "autozoom.ts"},["3808"] = {line = 381, file = "autozoom.ts"},["3809"] = {line = 381, file = "autozoom.ts"},["3810"] = {line = 381, file = "autozoom.ts"},["3811"] = {line = 381, file = "autozoom.ts"},["3813"] = {line = 381, file = "autozoom.ts"},["3814"] = {line = 382, file = "autozoom.ts"},["3815"] = {line = 383, file = "autozoom.ts"},["3816"] = {line = 383, file = "autozoom.ts"},["3817"] = {line = 383, file = "autozoom.ts"},["3818"] = {line = 383, file = "autozoom.ts"},["3819"] = {line = 383, file = "autozoom.ts"},["3820"] = {line = 383, file = "autozoom.ts"},["3821"] = {line = 383, file = "autozoom.ts"},["3822"] = {line = 383, file = "autozoom.ts"},["3823"] = {line = 384, file = "autozoom.ts"},["3824"] = {line = 384, file = "autozoom.ts"},["3825"] = {line = 384, file = "autozoom.ts"},["3826"] = {line = 382, file = "autozoom.ts"},["3827"] = {line = 368, file = "autozoom.ts"},["3828"] = {line = 389, file = "autozoom.ts"},["3829"] = {line = 390, file = "autozoom.ts"},["3830"] = {line = 389, file = "autozoom.ts"},["3831"] = {line = 393, file = "autozoom.ts"},["3832"] = {line = 394, file = "autozoom.ts"},["3833"] = {line = 394, file = "autozoom.ts"},["3834"] = {line = 394, file = "autozoom.ts"},["3835"] = {line = 394, file = "autozoom.ts"},["3836"] = {line = 393, file = "autozoom.ts"},["3837"] = {line = 397, file = "autozoom.ts"},["3838"] = {line = 398, file = "autozoom.ts"},["3839"] = {line = 398, file = "autozoom.ts"},["3840"] = {line = 398, file = "autozoom.ts"},["3841"] = {line = 398, file = "autozoom.ts"},["3842"] = {line = 399, file = "autozoom.ts"},["3843"] = {line = 399, file = "autozoom.ts"},["3844"] = {line = 399, file = "autozoom.ts"},["3845"] = {line = 399, file = "autozoom.ts"},["3846"] = {line = 400, file = "autozoom.ts"},["3847"] = {line = 400, file = "autozoom.ts"},["3848"] = {line = 400, file = "autozoom.ts"},["3849"] = {line = 400, file = "autozoom.ts"},["3850"] = {line = 400, file = "autozoom.ts"},["3851"] = {line = 400, file = "autozoom.ts"},["3852"] = {line = 400, file = "autozoom.ts"},["3853"] = {line = 400, file = "autozoom.ts"},["3855"] = {line = 401, file = "autozoom.ts"},["3856"] = {line = 401, file = "autozoom.ts"},["3857"] = {line = 401, file = "autozoom.ts"},["3858"] = {line = 401, file = "autozoom.ts"},["3859"] = {line = 401, file = "autozoom.ts"},["3860"] = {line = 401, file = "autozoom.ts"},["3861"] = {line = 401, file = "autozoom.ts"},["3862"] = {line = 402, file = "autozoom.ts"},["3863"] = {line = 403, file = "autozoom.ts"},["3864"] = {line = 397, file = "autozoom.ts"},["3865"] = {line = 406, file = "autozoom.ts"},["3866"] = {line = 407, file = "autozoom.ts"},["3867"] = {line = 408, file = "autozoom.ts"},["3868"] = {line = 409, file = "autozoom.ts"},["3869"] = {line = 409, file = "autozoom.ts"},["3870"] = {line = 409, file = "autozoom.ts"},["3871"] = {line = 409, file = "autozoom.ts"},["3872"] = {line = 409, file = "autozoom.ts"},["3874"] = {line = 410, file = "autozoom.ts"},["3875"] = {line = 406, file = "autozoom.ts"},["3876"] = {line = 413, file = "autozoom.ts"},["3877"] = {line = 414, file = "autozoom.ts"},["3878"] = {line = 413, file = "autozoom.ts"},["3879"] = {line = 417, file = "autozoom.ts"},["3880"] = {line = 418, file = "autozoom.ts"},["3881"] = {line = 418, file = "autozoom.ts"},["3883"] = {line = 418, file = "autozoom.ts"},["3885"] = {line = 417, file = "autozoom.ts"},["3886"] = {line = 421, file = "autozoom.ts"},["3887"] = {line = 422, file = "autozoom.ts"},["3888"] = {line = 422, file = "autozoom.ts"},["3889"] = {line = 422, file = "autozoom.ts"},["3890"] = {line = 422, file = "autozoom.ts"},["3891"] = {line = 423, file = "autozoom.ts"},["3892"] = {line = 421, file = "autozoom.ts"},["3893"] = {line = 426, file = "autozoom.ts"},["3894"] = {line = 427, file = "autozoom.ts"},["3895"] = {line = 428, file = "autozoom.ts"},["3896"] = {line = 426, file = "autozoom.ts"},["3897"] = {line = 431, file = "autozoom.ts"},["3898"] = {line = 432, file = "autozoom.ts"},["3901"] = {line = 433, file = "autozoom.ts"},["3902"] = {line = 434, file = "autozoom.ts"},["3903"] = {line = 431, file = "autozoom.ts"},["3904"] = {line = 438, file = "autozoom.ts"},["3905"] = {line = 439, file = "autozoom.ts"},["3906"] = {line = 438, file = "autozoom.ts"},["3914"] = {line = 2, file = "main.ts"},["3915"] = {line = 2, file = "main.ts"},["3916"] = {line = 3, file = "main.ts"},["3917"] = {line = 3, file = "main.ts"},["3918"] = {line = 7, file = "main.ts"},["3919"] = {line = 8, file = "main.ts"},["3922"] = {line = 12, file = "main.ts"},["3925"] = {line = 10, file = "main.ts"},["3932"] = {line = 15, file = "main.ts"},["3933"] = {line = 15, file = "main.ts"},["3934"] = {line = 15, file = "main.ts"},["3935"] = {line = 15, file = "main.ts"},["3936"] = {line = 15, file = "main.ts"},["3937"] = {line = 16, file = "main.ts"},["3938"] = {line = 16, file = "main.ts"},["3939"] = {line = 16, file = "main.ts"},["3940"] = {line = 16, file = "main.ts"},["3941"] = {line = 16, file = "main.ts"},["3942"] = {line = 17, file = "main.ts"},["3943"] = {line = 18, file = "main.ts"},["3944"] = {line = 19, file = "main.ts"},["3945"] = {line = 7, file = "main.ts"},["3946"] = {line = 23, file = "main.ts"},["3952"] = {line = 3, file = "exports.ts"},["3953"] = {line = 4, file = "exports.ts"},["3954"] = {line = 5, file = "exports.ts"},["3955"] = {line = 6, file = "exports.ts"},["3956"] = {line = 7, file = "exports.ts"},["3957"] = {line = 8, file = "exports.ts"},["3958"] = {line = 9, file = "exports.ts"},["3959"] = {line = 10, file = "exports.ts"},["3960"] = {line = 11, file = "exports.ts"},["3961"] = {line = 12, file = "exports.ts"},["3962"] = {line = 13, file = "exports.ts"},["3963"] = {line = 14, file = "exports.ts"},["3964"] = {line = 15, file = "exports.ts"},["3965"] = {line = 16, file = "exports.ts"},["3966"] = {line = 17, file = "exports.ts"},["3967"] = {line = 19, file = "exports.ts"},["3968"] = {line = 20, file = "exports.ts"},["3969"] = {line = 20, file = "exports.ts"},["3970"] = {line = 20, file = "exports.ts"},["3971"] = {line = 20, file = "exports.ts"},["3972"] = {line = 20, file = "exports.ts"},["3973"] = {line = 20, file = "exports.ts"},["3974"] = {line = 20, file = "exports.ts"},["3975"] = {line = 20, file = "exports.ts"},["3976"] = {line = 20, file = "exports.ts"},["3977"] = {line = 20, file = "exports.ts"},["3978"] = {line = 20, file = "exports.ts"},["3979"] = {line = 20, file = "exports.ts"},["3980"] = {line = 20, file = "exports.ts"},["3981"] = {line = 20, file = "exports.ts"},["3982"] = {line = 20, file = "exports.ts"}});
return require("src.main", ...)
