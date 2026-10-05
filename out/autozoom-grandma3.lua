
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

local function __TS__StringTrim(self)
    local result = string.gsub(self, "^[%s ﻿]*(.-)[%s ﻿]*$", "%1")
    return result
end

local function __TS__ArrayMap(self, callbackfn, thisArg)
    local result = {}
    for i = 1, #self do
        result[i] = callbackfn(thisArg, self[i], i - 1, self)
    end
    return result
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

return {
  __TS__SourceMapTraceBack = __TS__SourceMapTraceBack,
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
  __TS__StringTrim = __TS__StringTrim,
  __TS__ArrayMap = __TS__ArrayMap,
  __TS__StringStartsWith = __TS__StringStartsWith,
  __TS__Class = __TS__Class,
  __TS__StringSplit = __TS__StringSplit,
  __TS__ArrayForEach = __TS__ArrayForEach,
  __TS__ArrayFind = __TS__ArrayFind,
  __TS__ArrayFilter = __TS__ArrayFilter,
  __TS__StringReplace = __TS__StringReplace,
  __TS__Delete = __TS__Delete,
  __TS__ArraySome = __TS__ArraySome,
  __TS__ArrayIndexOf = __TS__ArrayIndexOf
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
        armed = {},
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
    if __TS__ArrayIsArray(raw.armed) then
        for ____, fid in __TS__Iterator(raw.armed) do
            if num(fid) ~= nil then
                local ____config_armed_0 = config.armed
                ____config_armed_0[#____config_armed_0 + 1] = math.floor(fid)
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
        armed = c.armed,
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
    local armed = {}
    for ____, fid in ipairs(config.armed) do
        if keep[fidKey(fid)] then
            armed[#armed + 1] = fid
        end
    end
    local size = {}
    for key in pairs(config.size) do
        if keep[key] then
            size[key] = config.size[key]
        end
    end
    return __TS__ObjectAssign({}, config, {armed = armed, size = size})
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
    config.offset.preset = __TS__StringTrim(a.preset)
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
        return "preset " .. c.offset.preset
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
["src.console.cues"] = function(...) 
local ____lualib = require("lualib_bundle")
local __TS__SourceMapTraceBack = ____lualib.__TS__SourceMapTraceBack
local ____exports = {}
local ____handles = require("src.console.handles")
local children = ____handles.children
local num = ____handles.num
____exports.CUE_SCALE = 1000
function ____exports.selectedSequence()
    local h = SelectedSequence()
    if h == nil then
        return nil
    end
    return {
        id = HandleToStr(h),
        no = num(h.no) or 0,
        name = tostring(h.name)
    }
end
local function handleOf(seq)
    local h = StrToHandle(seq.id)
    local ____temp_0
    if h ~= nil and IsObjectValid(h) then
        ____temp_0 = h
    else
        ____temp_0 = nil
    end
    return ____temp_0
end
local function cueHandle(seq, no)
    if no <= 0 then
        return nil
    end
    local stored = math.floor(no * ____exports.CUE_SCALE + 0.5)
    for ____, cue in ipairs(children(handleOf(seq))) do
        if num(cue.no) == stored then
            return cue
        end
    end
    return nil
end
function ____exports.runningCue(seq)
    local h = handleOf(seq)
    if h == nil then
        return nil
    end
    local cue = h:CurrentChild()
    if cue == nil then
        return nil
    end
    local stored = num(cue.no)
    local ____temp_1
    if stored == nil or stored <= 0 then
        ____temp_1 = nil
    else
        ____temp_1 = stored / ____exports.CUE_SCALE
    end
    return ____temp_1
end
function ____exports.selectedCue(_seq)
    return nil
end
function ____exports.readCueCommand(seq, no)
    local cue = cueHandle(seq, no)
    if cue == nil then
        return nil
    end
    local part = children(cue)[1]
    local ____temp_4
    if part == nil then
        ____temp_4 = ""
    else
        local ____tostring_3 = tostring
        local ____part_Command_2 = part.Command
        if ____part_Command_2 == nil then
            ____part_Command_2 = ""
        end
        ____temp_4 = ____tostring_3(____part_Command_2)
    end
    return ____temp_4
end
function ____exports.writeCueCommand(seq, no, text)
    local cue = cueHandle(seq, no)
    if cue == nil then
        return false
    end
    local part = children(cue)[1]
    if part == nil then
        return false
    end
    part.Command = text
    return true
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
["src.console.pool"] = function(...) 
local ____lualib = require("lualib_bundle")
local Error = ____lualib.Error
local RangeError = ____lualib.RangeError
local ReferenceError = ____lualib.ReferenceError
local SyntaxError = ____lualib.SyntaxError
local TypeError = ____lualib.TypeError
local URIError = ____lualib.URIError
local __TS__New = ____lualib.__TS__New
local __TS__SourceMapTraceBack = ____lualib.__TS__SourceMapTraceBack
local ____exports = {}
local ____format = require("src.format")
local fmtInt = ____format.fmtInt
local fmtNum = ____format.fmtNum
local ____handles = require("src.console.handles")
local children = ____handles.children
local findChild = ____handles.findChild
local ____log = require("src.console.log")
local warnOnce = ____log.warnOnce
____exports.POOL = "AutoZoom"
____exports.POOL_ADDR = ("DataPool '" .. ____exports.POOL) .. "'"
____exports.SIZE_SEQ = "AZ_SIZE"
function ____exports.zoomSeqName(fid)
    return "AZ_ZOOM_" .. fmtInt(fid)
end
function ____exports.irisSeqName(fid)
    return "AZ_IRIS_" .. fmtInt(fid)
end
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
local seqCache = {}
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
function ____exports.ensureFaderSequence(name, fid, attribute, physical)
    ____exports.ensurePool()
    if ____exports.findSequence(name) ~= nil then
        return
    end
    Cmd("ClearAll")
    Cmd("Fixture " .. fmtInt(fid))
    Cmd((("Attribute \"" .. attribute) .. "\" At Absolute Physical ") .. fmtNum(physical))
    Cmd(((("Store " .. ____exports.POOL_ADDR) .. " Sequence '") .. name) .. "' /o /nc")
    Cmd("ClearAll")
end
function ____exports.ensureSizeSequence()
    ____exports.ensurePool()
    if ____exports.findSequence(____exports.SIZE_SEQ) ~= nil then
        return
    end
    Cmd("ClearAll")
    Cmd(((("Store " .. ____exports.POOL_ADDR) .. " Sequence '") .. ____exports.SIZE_SEQ) .. "' /o /nc")
end
function ____exports.ensureMacro(name, luaCall)
    local pool = ____exports.ensurePool()
    if findChild(pool.Macros, name) == nil then
        Cmd(((("Store " .. ____exports.POOL_ADDR) .. " Macro '") .. name) .. "' /o /nc")
    end
    if luaCall == "" then
        return
    end
    Cmd(((("Store " .. ____exports.POOL_ADDR) .. " Macro '") .. name) .. "'.1 /o /nc")
    Cmd(((((("Set " .. ____exports.POOL_ADDR) .. " Macro '") .. name) .. "'.1 Property 'Command' 'Lua \"AZ:") .. luaCall) .. "\"'")
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
function ____exports.poolChildren(kind)
    local pool = ____exports.findPool()
    return pool == nil and ({}) or children(pool[kind])
end
return ____exports
 end,
["src.console.layout"] = function(...) 
local ____lualib = require("lualib_bundle")
local Error = ____lualib.Error
local RangeError = ____lualib.RangeError
local ReferenceError = ____lualib.ReferenceError
local SyntaxError = ____lualib.SyntaxError
local TypeError = ____lualib.TypeError
local URIError = ____lualib.URIError
local __TS__New = ____lualib.__TS__New
local __TS__StringStartsWith = ____lualib.__TS__StringStartsWith
local __TS__StringSubstring = ____lualib.__TS__StringSubstring
local __TS__SourceMapTraceBack = ____lualib.__TS__SourceMapTraceBack
local ____exports = {}
local ____handles = require("src.console.handles")
local children = ____handles.children
local findChild = ____handles.findChild
local ____pool = require("src.console.pool")
local ensureMacro = ____pool.ensureMacro
local ensurePool = ____pool.ensurePool
local findPool = ____pool.findPool
local POOL_ADDR = ____pool.POOL_ADDR
____exports.LAYOUT = "AutoZoom"
local TAG = "AZ:"
function ____exports.macroName(key)
    return "AZ " .. key
end
local elements = {}
local written = {}
function ____exports.buildLayout(cells)
    local pool = ensurePool()
    if findChild(pool.Layouts, ____exports.LAYOUT) ~= nil then
        Cmd(((("Delete " .. POOL_ADDR) .. " Layout '") .. ____exports.LAYOUT) .. "' /nc")
    end
    Cmd(((("Store " .. POOL_ADDR) .. " Layout '") .. ____exports.LAYOUT) .. "' /o /nc")
    local layout = findChild(pool.Layouts, ____exports.LAYOUT)
    if layout == nil then
        error(
            __TS__New(Error, "Could not create the AutoZoom layout"),
            0
        )
    end
    elements = {}
    written = {}
    for ____, cell in ipairs(cells) do
        ensureMacro(
            ____exports.macroName(cell.key),
            cell.command
        )
        local el = layout:Append()
        el.Object = findChild(
            pool.Macros,
            ____exports.macroName(cell.key)
        )
        el.Action = "Go+"
        el.Note = TAG .. cell.key
        el.PosX = cell.x
        el.PosY = cell.y
        el.Width = cell.w
        el.Height = cell.h
        el.VisibilityObjectName = "Hidden"
        el.VisibilityIcon = "Hidden"
        el.VisibilityBorder = "Visible"
        elements[cell.key] = el
    end
end
local function findElements()
    elements = {}
    local pool = findPool()
    if pool == nil then
        return
    end
    local layout = findChild(pool.Layouts, ____exports.LAYOUT)
    if layout == nil then
        return
    end
    for ____, el in ipairs(children(layout)) do
        local ____tostring_1 = tostring
        local ____el_Note_0 = el.Note
        if ____el_Note_0 == nil then
            ____el_Note_0 = ""
        end
        local note = ____tostring_1(____el_Note_0)
        if __TS__StringStartsWith(note, TAG) then
            elements[__TS__StringSubstring(note, #TAG)] = el
        end
    end
end
function ____exports.refreshLayout(views)
    local rescanned = false
    for key in pairs(views) do
        do
            local view = views[key]
            local signature = (((view.text .. "|") .. view.border) .. "|") .. view.textColor
            if written[key] == signature then
                goto __continue15
            end
            local el = elements[key]
            if el == nil or not IsObjectValid(el) then
                if rescanned then
                    goto __continue15
                end
                rescanned = true
                findElements()
                el = elements[key]
                if el == nil then
                    goto __continue15
                end
            end
            el.CustomTextText = view.text
            el.CustomTextColor = view.textColor
            el.BorderColor = view.border
            written[key] = signature
        end
        ::__continue15::
    end
end
return ____exports
 end,
["src.console.live"] = function(...) 
local ____lualib = require("lualib_bundle")
local __TS__StringStartsWith = ____lualib.__TS__StringStartsWith
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
function ____exports.readMarkers()
    local out = {}
    for ____, system in ipairs(children(ShowData().PSNProtocol)) do
        for ____, tracker in ipairs(children(system)) do
            do
                local cid = num(tracker.MARKERID)
                if cid == nil or cid == 0 then
                    goto __continue15
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
            ::__continue15::
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
        commands = {{value = 1, name = "Save"}, {value = 0, name = "Cancel"}},
        inputs = __TS__ArrayMap(
            INPUTS,
            function(____, name, i) return {name = name, value = values[i + 1]} end
        ),
        selectors = {{name = "Offset source", selectedValue = c.offset.source == "preset" and 1 or 2, values = {Preset = 1, Values = 2}}}
    })
    if r == nil or r.result ~= 1 then
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
    local ____opt_5 = r.selectors
    if ____opt_5 ~= nil then
        ____opt_5 = ____opt_5["Offset source"]
    end
    return {
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
local cues = require("src.console.cues")
local layout = require("src.console.layout")
local live = require("src.console.live")
local ____log = require("src.console.log")
local info = ____log.info
local ____patch = require("src.console.patch")
local scanPatch = ____patch.scanPatch
local pool = require("src.console.pool")
local ui = require("src.console.ui")
local vars = require("src.console.vars")
____exports.MaDesk = __TS__Class()
local MaDesk = ____exports.MaDesk
MaDesk.name = "MaDesk"
function MaDesk.prototype.____constructor(self)
    self.lastScan = {fixtures = {}, markers = {}, problems = {}}
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
    pool.ensureSizeSequence()
    for ____, f in ipairs(scan.fixtures) do
        pool.ensureFaderSequence(
            pool.zoomSeqName(f.fid),
            f.fid,
            "Zoom",
            f.optics.zoomMax
        )
        if f.optics.irisMax > f.optics.irisMin then
            pool.ensureFaderSequence(
                pool.irisSeqName(f.fid),
                f.fid,
                "Iris",
                f.optics.irisMax
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
    pool.setTemp(
        pool.zoomSeqName(f.fid),
        0
    )
    if f.optics.irisMax > f.optics.irisMin then
        pool.setTemp(
            pool.irisSeqName(f.fid),
            0
        )
    end
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
function MaDesk.prototype.selectedSequence(self)
    return cues.selectedSequence()
end
function MaDesk.prototype.runningCue(self, seq)
    return cues.runningCue(seq)
end
function MaDesk.prototype.selectedCue(self, seq)
    return cues.selectedCue(seq)
end
function MaDesk.prototype.readCueCommand(self, seq, cue)
    return cues.readCueCommand(seq, cue)
end
function MaDesk.prototype.writeCueCommand(self, seq, cue, text)
    return cues.writeCueCommand(seq, cue, text)
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
function ____exports.createMaDesk()
    return __TS__New(____exports.MaDesk)
end
return ____exports
 end,
["src.engine.arm-command"] = function(...) 
local ____lualib = require("lualib_bundle")
local __TS__ArraySort = ____lualib.__TS__ArraySort
local __TS__ArrayMap = ____lualib.__TS__ArrayMap
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
function ____exports.formatArmList(fids)
    return table.concat(
        __TS__ArrayMap(
            ____exports.normalizeFids(fids),
            function(____, f) return fmtInt(f) end
        ),
        ","
    )
end
function ____exports.armCommand(fids)
    return ("Lua \"AZ:Arm('" .. ____exports.formatArmList(fids)) .. "')\""
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
function ____exports.rewriteCueCommand(existing, armLine)
    local kept = {}
    if existing ~= nil then
        for ____, raw in ipairs(__TS__StringSplit(existing, ";")) do
            local part = __TS__StringTrim(raw)
            if part ~= "" and (string.find(part, "AZ:Arm(", nil, true) or 0) - 1 < 0 then
                kept[#kept + 1] = part
            end
        end
    end
    kept[#kept + 1] = armLine
    return table.concat(kept, "; ")
end
return ____exports
 end,
["src.engine.program"] = function(...) 
local ____lualib = require("lualib_bundle")
local __TS__SourceMapTraceBack = ____lualib.__TS__SourceMapTraceBack
local ____exports = {}
local ____format = require("src.format")
local fmtInt = ____format.fmtInt
local fmtNum = ____format.fmtNum
function ____exports.programCommands(fid, cid, optics, offset)
    local cmds = {
        "Fixture " .. fmtInt(fid),
        "Attribute \"XYZ_MArker\" At " .. fmtInt(cid)
    }
    if offset.source == "preset" and offset.preset ~= "" then
        cmds[#cmds + 1] = "Attribute \"XYZ_X\" Thru \"XYZ_Z\" At Preset " .. offset.preset
    else
        cmds[#cmds + 1] = "Attribute \"XYZ_X\" At " .. fmtNum(offset.values[1])
        cmds[#cmds + 1] = "Attribute \"XYZ_Y\" At " .. fmtNum(offset.values[2])
        cmds[#cmds + 1] = "Attribute \"XYZ_Z\" At " .. fmtNum(offset.values[3])
    end
    cmds[#cmds + 1] = "Attribute \"Zoom\" At Absolute Physical " .. fmtNum(optics.zoomMin)
    if optics.irisMax > optics.irisMin then
        cmds[#cmds + 1] = "Attribute \"Iris\" At Absolute Physical " .. fmtNum(optics.irisMin)
    end
    return cmds
end
function ____exports.releaseCommands(fid)
    return {"Off Fixture " .. fmtInt(fid)}
end
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
        {"capture", "Capture()"},
        {"setup", "Setup()"},
        {"armall", "ArmAll()"},
        {"disarmall", "DisarmAll()"},
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
function ____exports.buildViews(header, rows, markers, readings)
    local v = {}
    local function cell(key, text, border, textColor)
        if border == nil then
            border = ____exports.COLORS.idle
        end
        if textColor == nil then
            textColor = ____exports.COLORS.text
        end
        v[key] = {text = text, border = border, textColor = textColor}
    end
    cell(
        "status",
        ((((header.running and "Running" or "Offline") .. "\nPSN ") .. fmtInt(header.liveMarkers)) .. "/") .. fmtInt(#markers),
        header.running and ____exports.COLORS.on or ____exports.COLORS.bad
    )
    cell("toggle", header.running and "Stop" or "Start")
    if header.captureSecondsLeft ~= nil then
        cell(
            "capture",
            ("Select a sequence…\n" .. fmtInt(header.captureSecondsLeft)) .. " s · tap to cancel",
            ____exports.COLORS.accent,
            ____exports.COLORS.accent
        )
    else
        cell("capture", "Capture\narms → cue")
    end
    cell("setup", "Setup\nXYZ " .. header.offsetLabel)
    cell("armall", "Arm all")
    cell("disarmall", "Disarm all")
    cell(
        "size",
        ("AZ_SIZE\n" .. fmtNum(header.globalSize)) .. " m"
    )
    cell("message", header.message, ____exports.COLORS.idle, ____exports.COLORS.muted)
    for ____, m in ipairs(markers) do
        local live = readings[fidKey(m.cid)] ~= nil
        cell(
            "mh " .. fmtInt(m.cid),
            (m.name .. "\nCID ") .. fmtInt(m.cid),
            live and ____exports.COLORS.on or ____exports.COLORS.bad,
            live and ____exports.COLORS.text or ____exports.COLORS.bad
        )
    end
    for ____, r in ipairs(rows) do
        local fid = fmtInt(r.fixture.fid)
        local s = r.result.state
        cell("arm " .. fid, (fid .. "\n") .. r.fixture.name, r.armed and ____exports.COLORS.on or ____exports.COLORS.idle)
        for ____, m in ipairs(markers) do
            local key = (("mx " .. fid) .. " ") .. fmtInt(m.cid)
            if r.programmerCid == m.cid then
                cell(key, "P", ____exports.COLORS.bad, ____exports.COLORS.bad)
            elseif r.markerCid == m.cid then
                local color = (s == "tracking" or s == "too-wide" or s == "too-small") and ____exports.COLORS.on or (s == "no-psn" and ____exports.COLORS.accent or ____exports.COLORS.muted)
                cell(key, "●", color, color)
            else
                cell(key, "")
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
            stateColor(s)
        )
        cell(
            "di " .. fid,
            r.result.distance == nil and "—" or ((fmtNum(math.floor(r.result.distance * 10 + 0.5) / 10) .. " m\nbeam ") .. fmtNum(math.floor((r.result.achieved or 0) * 100 + 0.5) / 100)) .. " m"
        )
        cell(
            "zo " .. fid,
            r.result.zoom == nil and "—" or fmtNum(r.result.zoom) .. " %"
        )
        cell(
            "ir " .. fid,
            r.result.iris == nil and "—" or fmtNum(r.result.iris) .. " %"
        )
        cell(
            "sz " .. fid,
            (((r.sizeFixed and "Fixed" or "Global") .. "\n") .. fmtNum(math.floor(r.size * 100 + 0.5) / 100)) .. " m"
        )
    end
    return v
end
return ____exports
 end,
["src.runtime.autozoom"] = function(...) 
local ____lualib = require("lualib_bundle")
local __TS__Class = ____lualib.__TS__Class
local __TS__ArrayMap = ____lualib.__TS__ArrayMap
local __TS__ArrayFilter = ____lualib.__TS__ArrayFilter
local __TS__StringTrim = ____lualib.__TS__StringTrim
local __TS__StringReplace = ____lualib.__TS__StringReplace
local __TS__Delete = ____lualib.__TS__Delete
local __TS__Number = ____lualib.__TS__Number
local __TS__ArraySome = ____lualib.__TS__ArraySome
local __TS__ArrayIndexOf = ____lualib.__TS__ArrayIndexOf
local __TS__ArrayFind = ____lualib.__TS__ArrayFind
local __TS__New = ____lualib.__TS__New
local __TS__SourceMapTraceBack = ____lualib.__TS__SourceMapTraceBack
local ____exports = {}
local ____arm_2Dcommand = require("src.engine.arm-command")
local armCommand = ____arm_2Dcommand.armCommand
local normalizeFids = ____arm_2Dcommand.normalizeFids
local parseArmList = ____arm_2Dcommand.parseArmList
local rewriteCueCommand = ____arm_2Dcommand.rewriteCueCommand
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
____exports.CAPTURE_SECONDS = 15
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
    self.results = {}
    self.live = {}
    self.sent = {}
    self.warned = {}
    self.loopGen = 0
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
    self.scanned = self.desk:scan()
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
function AutoZoom.prototype.Start(self)
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
    self:saveConfig()
    if not self.running then
        return
    end
    self.running = false
    self.loopGen = self.loopGen + 1
    self.desk:stopLoop()
    if self.captureUntil ~= nil then
        self:endCapture("Capture cancelled")
    end
    self:update()
    for ____, f in ipairs(self.scanned.fixtures) do
        do
            local key = fidKey(f.fid)
            if self.sent[key] == "release" then
                goto __continue18
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
        ::__continue18::
    end
    self:say("AutoZoom stopped")
end
function AutoZoom.prototype.Toggle(self)
    if self.running then
        self:Stop()
    else
        self:Start()
    end
end
function AutoZoom.prototype.Arm(self, list)
    self:setArmed(parseArmList(list))
end
function AutoZoom.prototype.ArmToggle(self, fid)
    local armed = __TS__ArrayFilter(
        self.config.armed,
        function(____, f) return f ~= fid end
    )
    if #armed == #self.config.armed then
        armed[#armed + 1] = fid
    end
    self:setArmed(armed)
end
function AutoZoom.prototype.ArmAll(self)
    self:setArmed(__TS__ArrayMap(
        self.scanned.fixtures,
        function(____, f) return f.fid end
    ))
end
function AutoZoom.prototype.DisarmAll(self)
    self:setArmed({})
end
function AutoZoom.prototype.Status(self)
    self.desk:log(((("AutoZoom " .. (self.running and "running" or "stopped")) .. ", ") .. fmtInt(#self.config.armed)) .. " armed")
    for ____, f in ipairs(self.scanned.fixtures) do
        local r = self.results[fidKey(f.fid)]
        self.desk:log((((("  " .. fmtInt(f.fid)) .. " ") .. f.name) .. ": ") .. (r == nil and "-" or stateLabel(r.state)))
    end
end
function AutoZoom.prototype.Program(self, fid, cid)
    local f = self:fixture(fid)
    if f == nil then
        self.desk:log(("Fixture " .. fmtInt(fid)) .. " is not an AutoZoom fixture")
        return
    end
    if self.desk:readProgrammerCid(f) == cid then
        self.desk:runCommands(releaseCommands(fid))
    else
        self.desk:runCommands(programCommands(fid, cid, f.optics, self.config.offset))
    end
    self:update()
end
function AutoZoom.prototype.Setup(self)
    self.desk:later(function()
        local answers = self.desk:setupDialog(self.config)
        if answers == nil then
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
    if self.desk:loadText(INSTANCE_KEY) ~= self.id then
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
function AutoZoom.prototype.Capture(self)
    if self.captureUntil ~= nil then
        self:endCapture("Capture cancelled")
        return
    end
    if not self.running then
        self:say("Start AutoZoom to use Capture")
        return
    end
    local current = self.desk:selectedSequence()
    self.captureStartId = current and current.id
    self.captureUntil = self.desk:now() + ____exports.CAPTURE_SECONDS
    self.message = current == nil and "Select the sequence to store the arms in" or ("Select the sequence to store the arms in (to use Seq " .. fmtInt(current.no)) .. ", select another sequence first, then it)"
    self:update()
end
function AutoZoom.prototype.beforeUpdate(self)
    if self.captureUntil == nil then
        return
    end
    if self.desk:now() > self.captureUntil then
        self:endCapture("Capture timed out")
        return
    end
    local seq = self.desk:selectedSequence()
    if seq == nil or seq.id == self.captureStartId then
        return
    end
    self.captureUntil = nil
    self.desk:later(function() return self:storeArms(seq) end)
end
function AutoZoom.prototype.storeArms(self, seq)
    local suggested = self.desk:selectedCue(seq) or self.desk:runningCue(seq)
    local answer = self.desk:prompt(
        ((("Store AutoZoom arms in Seq " .. fmtInt(seq.no)) .. " '") .. seq.name) .. "': cue number",
        suggested == nil and "" or fmtNum(suggested)
    )
    if answer == nil then
        self:endCapture("Capture cancelled")
        return
    end
    local cue = __TS__Number(__TS__StringTrim(answer))
    local ____temp_5
    if __TS__StringTrim(answer) ~= "" and cue == cue then
        ____temp_5 = self.desk:readCueCommand(seq, cue)
    else
        ____temp_5 = nil
    end
    local existing = ____temp_5
    if existing == nil then
        self:endCapture(((("Seq " .. fmtInt(seq.no)) .. " has no cue ") .. __TS__StringTrim(answer)) .. "; nothing stored")
        return
    end
    local ok = self.desk:writeCueCommand(
        seq,
        cue,
        rewriteCueCommand(
            existing,
            armCommand(self.config.armed)
        )
    )
    self:endCapture(ok and (((("Stored in Seq " .. fmtInt(seq.no)) .. " '") .. seq.name) .. "' cue ") .. fmtNum(cue) or (("Could not write the command of Seq " .. fmtInt(seq.no)) .. " cue ") .. fmtNum(cue))
end
function AutoZoom.prototype.endCapture(self, message)
    self.captureUntil = nil
    self.captureStartId = nil
    self:say(message)
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
    local ____temp_6
    if self.captureUntil == nil then
        ____temp_6 = nil
    else
        ____temp_6 = math.max(
            0,
            math.ceil(self.captureUntil - self.desk:now())
        )
    end
    local left = ____temp_6
    self.desk:refreshLayout(buildViews(
        {
            running = self.running,
            captureSecondsLeft = left,
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
    return __TS__ArrayIndexOf(self.config.armed, fid) >= 0
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
    self.config.armed = known
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
    Printf("[AZ] AutoZoom 2.0.0 by Naostage")
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
__TS__SourceMapTraceBack(debug.getinfo(1).short_src, {["562"] = {line = 5, file = "vec.ts"},["563"] = {line = 6, file = "vec.ts"},["564"] = {line = 5, file = "vec.ts"},["565"] = {line = 9, file = "vec.ts"},["566"] = {line = 10, file = "vec.ts"},["567"] = {line = 9, file = "vec.ts"},["568"] = {line = 13, file = "vec.ts"},["569"] = {line = 14, file = "vec.ts"},["570"] = {line = 14, file = "vec.ts"},["571"] = {line = 14, file = "vec.ts"},["572"] = {line = 15, file = "vec.ts"},["573"] = {line = 13, file = "vec.ts"},["574"] = {line = 19, file = "vec.ts"},["575"] = {line = 20, file = "vec.ts"},["576"] = {line = 20, file = "vec.ts"},["577"] = {line = 20, file = "vec.ts"},["578"] = {line = 21, file = "vec.ts"},["579"] = {line = 21, file = "vec.ts"},["580"] = {line = 21, file = "vec.ts"},["581"] = {line = 22, file = "vec.ts"},["582"] = {line = 22, file = "vec.ts"},["583"] = {line = 22, file = "vec.ts"},["584"] = {line = 23, file = "vec.ts"},["585"] = {line = 23, file = "vec.ts"},["586"] = {line = 23, file = "vec.ts"},["587"] = {line = 24, file = "vec.ts"},["588"] = {line = 24, file = "vec.ts"},["589"] = {line = 24, file = "vec.ts"},["590"] = {line = 25, file = "vec.ts"},["591"] = {line = 19, file = "vec.ts"},["598"] = {line = 10, file = "beam.ts"},["599"] = {line = 11, file = "beam.ts"},["600"] = {line = 11, file = "beam.ts"},["602"] = {line = 12, file = "beam.ts"},["603"] = {line = 13, file = "beam.ts"},["604"] = {line = 13, file = "beam.ts"},["605"] = {line = 13, file = "beam.ts"},["606"] = {line = 13, file = "beam.ts"},["607"] = {line = 10, file = "beam.ts"},["608"] = {line = 16, file = "beam.ts"},["609"] = {line = 17, file = "beam.ts"},["610"] = {line = 16, file = "beam.ts"},["611"] = {line = 20, file = "beam.ts"},["612"] = {line = 21, file = "beam.ts"},["613"] = {line = 22, file = "beam.ts"},["614"] = {line = 23, file = "beam.ts"},["615"] = {line = 23, file = "beam.ts"},["617"] = {line = 24, file = "beam.ts"},["618"] = {line = 25, file = "beam.ts"},["619"] = {line = 25, file = "beam.ts"},["620"] = {line = 25, file = "beam.ts"},["621"] = {line = 25, file = "beam.ts"},["622"] = {line = 25, file = "beam.ts"},["623"] = {line = 25, file = "beam.ts"},["624"] = {line = 25, file = "beam.ts"},["626"] = {line = 26, file = "beam.ts"},["627"] = {line = 26, file = "beam.ts"},["628"] = {line = 26, file = "beam.ts"},["629"] = {line = 26, file = "beam.ts"},["630"] = {line = 26, file = "beam.ts"},["631"] = {line = 26, file = "beam.ts"},["632"] = {line = 26, file = "beam.ts"},["634"] = {line = 27, file = "beam.ts"},["635"] = {line = 28, file = "beam.ts"},["636"] = {line = 28, file = "beam.ts"},["638"] = {line = 29, file = "beam.ts"},["639"] = {line = 30, file = "beam.ts"},["640"] = {line = 30, file = "beam.ts"},["642"] = {line = 31, file = "beam.ts"},["643"] = {line = 31, file = "beam.ts"},["644"] = {line = 31, file = "beam.ts"},["645"] = {line = 31, file = "beam.ts"},["646"] = {line = 31, file = "beam.ts"},["647"] = {line = 31, file = "beam.ts"},["648"] = {line = 20, file = "beam.ts"},["665"] = {line = 4, file = "format.ts"},["666"] = {line = 5, file = "format.ts"},["667"] = {line = 5, file = "format.ts"},["668"] = {line = 5, file = "format.ts"},["669"] = {line = 5, file = "format.ts"},["670"] = {line = 4, file = "format.ts"},["671"] = {line = 8, file = "format.ts"},["672"] = {line = 9, file = "format.ts"},["673"] = {line = 10, file = "format.ts"},["674"] = {line = 10, file = "format.ts"},["676"] = {line = 11, file = "format.ts"},["677"] = {line = 11, file = "format.ts"},["679"] = {line = 12, file = "format.ts"},["680"] = {line = 8, file = "format.ts"},["681"] = {line = 15, file = "format.ts"},["682"] = {line = 16, file = "format.ts"},["683"] = {line = 15, file = "format.ts"},["702"] = {line = 27, file = "json.ts"},["703"] = {line = 27, file = "json.ts"},["704"] = {line = 28, file = "json.ts"},["706"] = {line = 29, file = "json.ts"},["707"] = {line = 29, file = "json.ts"},["708"] = {line = 30, file = "json.ts"},["709"] = {line = 31, file = "json.ts"},["710"] = {line = 31, file = "json.ts"},["711"] = {line = 32, file = "json.ts"},["712"] = {line = 32, file = "json.ts"},["713"] = {line = 33, file = "json.ts"},["714"] = {line = 33, file = "json.ts"},["715"] = {line = 34, file = "json.ts"},["716"] = {line = 34, file = "json.ts"},["717"] = {line = 35, file = "json.ts"},["718"] = {line = 35, file = "json.ts"},["720"] = {line = 36, file = "json.ts"},["722"] = {line = 29, file = "json.ts"},["725"] = {line = 38, file = "json.ts"},["727"] = {line = 51, file = "json.ts"},["728"] = {line = 52, file = "json.ts"},["729"] = {line = 53, file = "json.ts"},["730"] = {line = 54, file = "json.ts"},["733"] = {line = 55, file = "json.ts"},["736"] = {line = 59, file = "json.ts"},["737"] = {line = 60, file = "json.ts"},["739"] = {line = 60, file = "json.ts"},["740"] = {line = 60, file = "json.ts"},["741"] = {line = 60, file = "json.ts"},["742"] = {line = 60, file = "json.ts"},["746"] = {line = 61, file = "json.ts"},["748"] = {line = 64, file = "json.ts"},["749"] = {line = 65, file = "json.ts"},["750"] = {line = 66, file = "json.ts"},["751"] = {line = 67, file = "json.ts"},["752"] = {line = 67, file = "json.ts"},["754"] = {line = 68, file = "json.ts"},["755"] = {line = 68, file = "json.ts"},["757"] = {line = 69, file = "json.ts"},["758"] = {line = 69, file = "json.ts"},["760"] = {line = 70, file = "json.ts"},["761"] = {line = 70, file = "json.ts"},["762"] = {line = 70, file = "json.ts"},["764"] = {line = 71, file = "json.ts"},["765"] = {line = 71, file = "json.ts"},["766"] = {line = 71, file = "json.ts"},["768"] = {line = 72, file = "json.ts"},["769"] = {line = 72, file = "json.ts"},["770"] = {line = 72, file = "json.ts"},["772"] = {line = 73, file = "json.ts"},["774"] = {line = 76, file = "json.ts"},["775"] = {line = 77, file = "json.ts"},["776"] = {line = 78, file = "json.ts"},["777"] = {line = 78, file = "json.ts"},["778"] = {line = 78, file = "json.ts"},["779"] = {line = 78, file = "json.ts"},["780"] = {line = 78, file = "json.ts"},["781"] = {line = 78, file = "json.ts"},["782"] = {line = 78, file = "json.ts"},["784"] = {line = 79, file = "json.ts"},["786"] = {line = 79, file = "json.ts"},["787"] = {line = 79, file = "json.ts"},["788"] = {line = 79, file = "json.ts"},["789"] = {line = 79, file = "json.ts"},["793"] = {line = 80, file = "json.ts"},["794"] = {line = 81, file = "json.ts"},["796"] = {line = 81, file = "json.ts"},["797"] = {line = 81, file = "json.ts"},["798"] = {line = 81, file = "json.ts"},["799"] = {line = 81, file = "json.ts"},["803"] = {line = 82, file = "json.ts"},["805"] = {line = 85, file = "json.ts"},["806"] = {line = 86, file = "json.ts"},["807"] = {line = 87, file = "json.ts"},["808"] = {line = 88, file = "json.ts"},["809"] = {line = 89, file = "json.ts"},["810"] = {line = 90, file = "json.ts"},["811"] = {line = 91, file = "json.ts"},["812"] = {line = 91, file = "json.ts"},["814"] = {line = 92, file = "json.ts"},["815"] = {line = 93, file = "json.ts"},["816"] = {line = 94, file = "json.ts"},["817"] = {line = 95, file = "json.ts"},["818"] = {line = 95, file = "json.ts"},["819"] = {line = 96, file = "json.ts"},["820"] = {line = 96, file = "json.ts"},["821"] = {line = 97, file = "json.ts"},["822"] = {line = 97, file = "json.ts"},["824"] = {line = 98, file = "json.ts"},["827"] = {line = 100, file = "json.ts"},["831"] = {line = 103, file = "json.ts"},["835"] = {line = 106, file = "json.ts"},["836"] = {line = 107, file = "json.ts"},["837"] = {line = 108, file = "json.ts"},["838"] = {line = 109, file = "json.ts"},["839"] = {line = 110, file = "json.ts"},["840"] = {line = 110, file = "json.ts"},["841"] = {line = 110, file = "json.ts"},["843"] = {line = 111, file = "json.ts"},["844"] = {line = 112, file = "json.ts"},["845"] = {line = 113, file = "json.ts"},["846"] = {line = 114, file = "json.ts"},["847"] = {line = 115, file = "json.ts"},["848"] = {line = 116, file = "json.ts"},["849"] = {line = 116, file = "json.ts"},["851"] = {line = 117, file = "json.ts"},["853"] = {line = 117, file = "json.ts"},["854"] = {line = 117, file = "json.ts"},["855"] = {line = 117, file = "json.ts"},["856"] = {line = 117, file = "json.ts"},["862"] = {line = 121, file = "json.ts"},["863"] = {line = 122, file = "json.ts"},["864"] = {line = 123, file = "json.ts"},["865"] = {line = 124, file = "json.ts"},["866"] = {line = 125, file = "json.ts"},["867"] = {line = 125, file = "json.ts"},["868"] = {line = 125, file = "json.ts"},["870"] = {line = 126, file = "json.ts"},["871"] = {line = 127, file = "json.ts"},["872"] = {line = 128, file = "json.ts"},["874"] = {line = 128, file = "json.ts"},["875"] = {line = 128, file = "json.ts"},["876"] = {line = 128, file = "json.ts"},["877"] = {line = 128, file = "json.ts"},["881"] = {line = 129, file = "json.ts"},["882"] = {line = 130, file = "json.ts"},["883"] = {line = 131, file = "json.ts"},["885"] = {line = 131, file = "json.ts"},["886"] = {line = 131, file = "json.ts"},["887"] = {line = 131, file = "json.ts"},["888"] = {line = 131, file = "json.ts"},["892"] = {line = 132, file = "json.ts"},["893"] = {line = 133, file = "json.ts"},["894"] = {line = 134, file = "json.ts"},["895"] = {line = 134, file = "json.ts"},["897"] = {line = 135, file = "json.ts"},["898"] = {line = 136, file = "json.ts"},["899"] = {line = 137, file = "json.ts"},["900"] = {line = 138, file = "json.ts"},["901"] = {line = 138, file = "json.ts"},["903"] = {line = 139, file = "json.ts"},["905"] = {line = 139, file = "json.ts"},["906"] = {line = 139, file = "json.ts"},["907"] = {line = 139, file = "json.ts"},["908"] = {line = 139, file = "json.ts"},["916"] = {line = 5, file = "json.ts"},["917"] = {line = 6, file = "json.ts"},["918"] = {line = 6, file = "json.ts"},["920"] = {line = 7, file = "json.ts"},["921"] = {line = 7, file = "json.ts"},["923"] = {line = 8, file = "json.ts"},["924"] = {line = 9, file = "json.ts"},["925"] = {line = 9, file = "json.ts"},["927"] = {line = 10, file = "json.ts"},["929"] = {line = 12, file = "json.ts"},["930"] = {line = 12, file = "json.ts"},["932"] = {line = 13, file = "json.ts"},["933"] = {line = 14, file = "json.ts"},["934"] = {line = 15, file = "json.ts"},["935"] = {line = 15, file = "json.ts"},["937"] = {line = 16, file = "json.ts"},["939"] = {line = 18, file = "json.ts"},["940"] = {line = 19, file = "json.ts"},["941"] = {line = 20, file = "json.ts"},["942"] = {line = 20, file = "json.ts"},["944"] = {line = 21, file = "json.ts"},["945"] = {line = 22, file = "json.ts"},["946"] = {line = 23, file = "json.ts"},["947"] = {line = 23, file = "json.ts"},["949"] = {line = 24, file = "json.ts"},["950"] = {line = 5, file = "json.ts"},["951"] = {line = 43, file = "json.ts"},["952"] = {line = 44, file = "json.ts"},["953"] = {line = 45, file = "json.ts"},["954"] = {line = 46, file = "json.ts"},["955"] = {line = 47, file = "json.ts"},["957"] = {line = 47, file = "json.ts"},["958"] = {line = 47, file = "json.ts"},["959"] = {line = 47, file = "json.ts"},["960"] = {line = 47, file = "json.ts"},["964"] = {line = 48, file = "json.ts"},["965"] = {line = 43, file = "json.ts"},["978"] = {line = 2, file = "config.ts"},["979"] = {line = 2, file = "config.ts"},["980"] = {line = 2, file = "config.ts"},["981"] = {line = 3, file = "config.ts"},["982"] = {line = 3, file = "config.ts"},["983"] = {line = 3, file = "config.ts"},["984"] = {line = 15, file = "config.ts"},["985"] = {line = 16, file = "config.ts"},["986"] = {line = 17, file = "config.ts"},["987"] = {line = 19, file = "config.ts"},["988"] = {line = 20, file = "config.ts"},["989"] = {line = 20, file = "config.ts"},["990"] = {line = 20, file = "config.ts"},["991"] = {line = 20, file = "config.ts"},["992"] = {line = 20, file = "config.ts"},["993"] = {line = 20, file = "config.ts"},["994"] = {line = 20, file = "config.ts"},["995"] = {line = 19, file = "config.ts"},["996"] = {line = 23, file = "config.ts"},["997"] = {line = 24, file = "config.ts"},["998"] = {line = 23, file = "config.ts"},["999"] = {line = 27, file = "config.ts"},["1000"] = {line = 28, file = "config.ts"},["1001"] = {line = 29, file = "config.ts"},["1002"] = {line = 29, file = "config.ts"},["1004"] = {line = 30, file = "config.ts"},["1007"] = {line = 34, file = "config.ts"},["1010"] = {line = 32, file = "config.ts"},["1016"] = {line = 31, file = "config.ts"},["1019"] = {line = 36, file = "config.ts"},["1020"] = {line = 36, file = "config.ts"},["1022"] = {line = 37, file = "config.ts"},["1023"] = {line = 38, file = "config.ts"},["1024"] = {line = 38, file = "config.ts"},["1025"] = {line = 38, file = "config.ts"},["1026"] = {line = 38, file = "config.ts"},["1030"] = {line = 40, file = "config.ts"},["1031"] = {line = 41, file = "config.ts"},["1032"] = {line = 42, file = "config.ts"},["1033"] = {line = 43, file = "config.ts"},["1034"] = {line = 43, file = "config.ts"},["1038"] = {line = 46, file = "config.ts"},["1039"] = {line = 47, file = "config.ts"},["1040"] = {line = 47, file = "config.ts"},["1041"] = {line = 48, file = "config.ts"},["1042"] = {line = 48, file = "config.ts"},["1045"] = {line = 50, file = "config.ts"},["1046"] = {line = 51, file = "config.ts"},["1047"] = {line = 51, file = "config.ts"},["1049"] = {line = 52, file = "config.ts"},["1050"] = {line = 53, file = "config.ts"},["1051"] = {line = 54, file = "config.ts"},["1052"] = {line = 54, file = "config.ts"},["1054"] = {line = 55, file = "config.ts"},["1055"] = {line = 55, file = "config.ts"},["1057"] = {line = 56, file = "config.ts"},["1058"] = {line = 57, file = "config.ts"},["1059"] = {line = 57, file = "config.ts"},["1060"] = {line = 57, file = "config.ts"},["1061"] = {line = 57, file = "config.ts"},["1062"] = {line = 57, file = "config.ts"},["1065"] = {line = 60, file = "config.ts"},["1066"] = {line = 27, file = "config.ts"},["1067"] = {line = 63, file = "config.ts"},["1068"] = {line = 64, file = "config.ts"},["1069"] = {line = 64, file = "config.ts"},["1070"] = {line = 64, file = "config.ts"},["1071"] = {line = 64, file = "config.ts"},["1072"] = {line = 64, file = "config.ts"},["1073"] = {line = 64, file = "config.ts"},["1074"] = {line = 64, file = "config.ts"},["1075"] = {line = 64, file = "config.ts"},["1076"] = {line = 63, file = "config.ts"},["1077"] = {line = 67, file = "config.ts"},["1078"] = {line = 68, file = "config.ts"},["1079"] = {line = 69, file = "config.ts"},["1080"] = {line = 69, file = "config.ts"},["1082"] = {line = 70, file = "config.ts"},["1083"] = {line = 71, file = "config.ts"},["1084"] = {line = 71, file = "config.ts"},["1085"] = {line = 71, file = "config.ts"},["1088"] = {line = 72, file = "config.ts"},["1089"] = {line = 73, file = "config.ts"},["1090"] = {line = 73, file = "config.ts"},["1091"] = {line = 73, file = "config.ts"},["1094"] = {line = 74, file = "config.ts"},["1095"] = {line = 67, file = "config.ts"},["1096"] = {line = 79, file = "config.ts"},["1097"] = {line = 80, file = "config.ts"},["1098"] = {line = 81, file = "config.ts"},["1099"] = {line = 81, file = "config.ts"},["1100"] = {line = 81, file = "config.ts"},["1101"] = {line = 81, file = "config.ts"},["1102"] = {line = 81, file = "config.ts"},["1103"] = {line = 81, file = "config.ts"},["1104"] = {line = 81, file = "config.ts"},["1105"] = {line = 81, file = "config.ts"},["1106"] = {line = 81, file = "config.ts"},["1107"] = {line = 81, file = "config.ts"},["1108"] = {line = 81, file = "config.ts"},["1109"] = {line = 81, file = "config.ts"},["1110"] = {line = 82, file = "config.ts"},["1111"] = {line = 83, file = "config.ts"},["1112"] = {line = 84, file = "config.ts"},["1113"] = {line = 84, file = "config.ts"},["1114"] = {line = 84, file = "config.ts"},["1116"] = {line = 85, file = "config.ts"},["1117"] = {line = 82, file = "config.ts"},["1118"] = {line = 87, file = "config.ts"},["1119"] = {line = 87, file = "config.ts"},["1120"] = {line = 87, file = "config.ts"},["1121"] = {line = 88, file = "config.ts"},["1122"] = {line = 88, file = "config.ts"},["1124"] = {line = 89, file = "config.ts"},["1125"] = {line = 89, file = "config.ts"},["1127"] = {line = 90, file = "config.ts"},["1129"] = {line = 91, file = "config.ts"},["1130"] = {line = 92, file = "config.ts"},["1131"] = {line = 92, file = "config.ts"},["1132"] = {line = 93, file = "config.ts"},["1133"] = {line = 94, file = "config.ts"},["1134"] = {line = 94, file = "config.ts"},["1136"] = {line = 95, file = "config.ts"},["1139"] = {line = 97, file = "config.ts"},["1140"] = {line = 98, file = "config.ts"},["1141"] = {line = 99, file = "config.ts"},["1142"] = {line = 99, file = "config.ts"},["1144"] = {line = 100, file = "config.ts"},["1147"] = {line = 102, file = "config.ts"},["1148"] = {line = 79, file = "config.ts"},["1149"] = {line = 105, file = "config.ts"},["1150"] = {line = 106, file = "config.ts"},["1151"] = {line = 106, file = "config.ts"},["1153"] = {line = 107, file = "config.ts"},["1154"] = {line = 107, file = "config.ts"},["1155"] = {line = 107, file = "config.ts"},["1156"] = {line = 107, file = "config.ts"},["1157"] = {line = 107, file = "config.ts"},["1158"] = {line = 107, file = "config.ts"},["1159"] = {line = 107, file = "config.ts"},["1160"] = {line = 105, file = "config.ts"},["1175"] = {line = 4, file = "handles.ts"},["1176"] = {line = 5, file = "handles.ts"},["1177"] = {line = 5, file = "handles.ts"},["1179"] = {line = 6, file = "handles.ts"},["1180"] = {line = 7, file = "handles.ts"},["1181"] = {line = 4, file = "handles.ts"},["1182"] = {line = 10, file = "handles.ts"},["1183"] = {line = 11, file = "handles.ts"},["1184"] = {line = 11, file = "handles.ts"},["1186"] = {line = 12, file = "handles.ts"},["1187"] = {line = 12, file = "handles.ts"},["1189"] = {line = 13, file = "handles.ts"},["1190"] = {line = 10, file = "handles.ts"},["1191"] = {line = 16, file = "handles.ts"},["1192"] = {line = 17, file = "handles.ts"},["1193"] = {line = 17, file = "handles.ts"},["1194"] = {line = 17, file = "handles.ts"},["1197"] = {line = 18, file = "handles.ts"},["1198"] = {line = 16, file = "handles.ts"},["1205"] = {line = 3, file = "cues.ts"},["1206"] = {line = 3, file = "cues.ts"},["1207"] = {line = 3, file = "cues.ts"},["1208"] = {line = 6, file = "cues.ts"},["1209"] = {line = 8, file = "cues.ts"},["1210"] = {line = 9, file = "cues.ts"},["1211"] = {line = 10, file = "cues.ts"},["1212"] = {line = 10, file = "cues.ts"},["1214"] = {line = 11, file = "cues.ts"},["1215"] = {line = 11, file = "cues.ts"},["1216"] = {line = 11, file = "cues.ts"},["1217"] = {line = 11, file = "cues.ts"},["1218"] = {line = 11, file = "cues.ts"},["1219"] = {line = 8, file = "cues.ts"},["1220"] = {line = 14, file = "cues.ts"},["1221"] = {line = 15, file = "cues.ts"},["1222"] = {line = 16, file = "cues.ts"},["1223"] = {line = 16, file = "cues.ts"},["1224"] = {line = 16, file = "cues.ts"},["1226"] = {line = 16, file = "cues.ts"},["1228"] = {line = 16, file = "cues.ts"},["1229"] = {line = 14, file = "cues.ts"},["1230"] = {line = 19, file = "cues.ts"},["1231"] = {line = 20, file = "cues.ts"},["1232"] = {line = 20, file = "cues.ts"},["1234"] = {line = 21, file = "cues.ts"},["1235"] = {line = 22, file = "cues.ts"},["1236"] = {line = 22, file = "cues.ts"},["1237"] = {line = 22, file = "cues.ts"},["1240"] = {line = 23, file = "cues.ts"},["1241"] = {line = 19, file = "cues.ts"},["1242"] = {line = 26, file = "cues.ts"},["1243"] = {line = 27, file = "cues.ts"},["1244"] = {line = 28, file = "cues.ts"},["1245"] = {line = 28, file = "cues.ts"},["1247"] = {line = 29, file = "cues.ts"},["1248"] = {line = 30, file = "cues.ts"},["1249"] = {line = 30, file = "cues.ts"},["1251"] = {line = 31, file = "cues.ts"},["1252"] = {line = 32, file = "cues.ts"},["1253"] = {line = 32, file = "cues.ts"},["1254"] = {line = 32, file = "cues.ts"},["1256"] = {line = 32, file = "cues.ts"},["1258"] = {line = 32, file = "cues.ts"},["1259"] = {line = 26, file = "cues.ts"},["1260"] = {line = 37, file = "cues.ts"},["1261"] = {line = 38, file = "cues.ts"},["1262"] = {line = 37, file = "cues.ts"},["1263"] = {line = 41, file = "cues.ts"},["1264"] = {line = 42, file = "cues.ts"},["1265"] = {line = 43, file = "cues.ts"},["1266"] = {line = 43, file = "cues.ts"},["1268"] = {line = 44, file = "cues.ts"},["1269"] = {line = 45, file = "cues.ts"},["1270"] = {line = 45, file = "cues.ts"},["1271"] = {line = 45, file = "cues.ts"},["1273"] = {line = 45, file = "cues.ts"},["1274"] = {line = 45, file = "cues.ts"},["1275"] = {line = 45, file = "cues.ts"},["1276"] = {line = 45, file = "cues.ts"},["1278"] = {line = 45, file = "cues.ts"},["1280"] = {line = 45, file = "cues.ts"},["1281"] = {line = 41, file = "cues.ts"},["1282"] = {line = 48, file = "cues.ts"},["1283"] = {line = 49, file = "cues.ts"},["1284"] = {line = 50, file = "cues.ts"},["1285"] = {line = 50, file = "cues.ts"},["1287"] = {line = 51, file = "cues.ts"},["1288"] = {line = 52, file = "cues.ts"},["1289"] = {line = 52, file = "cues.ts"},["1291"] = {line = 53, file = "cues.ts"},["1292"] = {line = 54, file = "cues.ts"},["1293"] = {line = 48, file = "cues.ts"},["1302"] = {line = 2, file = "log.ts"},["1303"] = {line = 4, file = "log.ts"},["1304"] = {line = 5, file = "log.ts"},["1305"] = {line = 4, file = "log.ts"},["1306"] = {line = 8, file = "log.ts"},["1307"] = {line = 9, file = "log.ts"},["1310"] = {line = 10, file = "log.ts"},["1311"] = {line = 11, file = "log.ts"},["1312"] = {line = 8, file = "log.ts"},["1326"] = {line = 2, file = "pool.ts"},["1327"] = {line = 2, file = "pool.ts"},["1328"] = {line = 2, file = "pool.ts"},["1329"] = {line = 3, file = "pool.ts"},["1330"] = {line = 3, file = "pool.ts"},["1331"] = {line = 3, file = "pool.ts"},["1332"] = {line = 4, file = "pool.ts"},["1333"] = {line = 4, file = "pool.ts"},["1334"] = {line = 6, file = "pool.ts"},["1335"] = {line = 7, file = "pool.ts"},["1336"] = {line = 8, file = "pool.ts"},["1337"] = {line = 10, file = "pool.ts"},["1338"] = {line = 10, file = "pool.ts"},["1339"] = {line = 10, file = "pool.ts"},["1340"] = {line = 11, file = "pool.ts"},["1341"] = {line = 11, file = "pool.ts"},["1342"] = {line = 11, file = "pool.ts"},["1343"] = {line = 13, file = "pool.ts"},["1344"] = {line = 14, file = "pool.ts"},["1345"] = {line = 14, file = "pool.ts"},["1346"] = {line = 14, file = "pool.ts"},["1347"] = {line = 14, file = "pool.ts"},["1348"] = {line = 13, file = "pool.ts"},["1349"] = {line = 17, file = "pool.ts"},["1350"] = {line = 18, file = "pool.ts"},["1351"] = {line = 19, file = "pool.ts"},["1352"] = {line = 20, file = "pool.ts"},["1353"] = {line = 21, file = "pool.ts"},["1355"] = {line = 23, file = "pool.ts"},["1357"] = {line = 23, file = "pool.ts"},["1361"] = {line = 24, file = "pool.ts"},["1362"] = {line = 17, file = "pool.ts"},["1363"] = {line = 27, file = "pool.ts"},["1364"] = {line = 29, file = "pool.ts"},["1365"] = {line = 30, file = "pool.ts"},["1366"] = {line = 31, file = "pool.ts"},["1367"] = {line = 31, file = "pool.ts"},["1369"] = {line = 32, file = "pool.ts"},["1370"] = {line = 33, file = "pool.ts"},["1371"] = {line = 33, file = "pool.ts"},["1372"] = {line = 33, file = "pool.ts"},["1374"] = {line = 33, file = "pool.ts"},["1376"] = {line = 33, file = "pool.ts"},["1377"] = {line = 34, file = "pool.ts"},["1378"] = {line = 34, file = "pool.ts"},["1380"] = {line = 35, file = "pool.ts"},["1381"] = {line = 29, file = "pool.ts"},["1382"] = {line = 40, file = "pool.ts"},["1383"] = {line = 41, file = "pool.ts"},["1384"] = {line = 42, file = "pool.ts"},["1387"] = {line = 43, file = "pool.ts"},["1388"] = {line = 44, file = "pool.ts"},["1389"] = {line = 45, file = "pool.ts"},["1390"] = {line = 46, file = "pool.ts"},["1391"] = {line = 47, file = "pool.ts"},["1392"] = {line = 40, file = "pool.ts"},["1393"] = {line = 50, file = "pool.ts"},["1394"] = {line = 51, file = "pool.ts"},["1395"] = {line = 52, file = "pool.ts"},["1398"] = {line = 53, file = "pool.ts"},["1399"] = {line = 54, file = "pool.ts"},["1400"] = {line = 50, file = "pool.ts"},["1401"] = {line = 57, file = "pool.ts"},["1402"] = {line = 58, file = "pool.ts"},["1403"] = {line = 59, file = "pool.ts"},["1404"] = {line = 59, file = "pool.ts"},["1406"] = {line = 60, file = "pool.ts"},["1409"] = {line = 61, file = "pool.ts"},["1410"] = {line = 62, file = "pool.ts"},["1411"] = {line = 57, file = "pool.ts"},["1412"] = {line = 65, file = "pool.ts"},["1413"] = {line = 66, file = "pool.ts"},["1414"] = {line = 67, file = "pool.ts"},["1415"] = {line = 68, file = "pool.ts"},["1418"] = {line = 71, file = "pool.ts"},["1419"] = {line = 65, file = "pool.ts"},["1420"] = {line = 74, file = "pool.ts"},["1421"] = {line = 75, file = "pool.ts"},["1422"] = {line = 76, file = "pool.ts"},["1423"] = {line = 76, file = "pool.ts"},["1425"] = {line = 77, file = "pool.ts"},["1426"] = {line = 78, file = "pool.ts"},["1427"] = {line = 74, file = "pool.ts"},["1428"] = {line = 81, file = "pool.ts"},["1429"] = {line = 82, file = "pool.ts"},["1430"] = {line = 83, file = "pool.ts"},["1431"] = {line = 81, file = "pool.ts"},["1447"] = {line = 3, file = "layout.ts"},["1448"] = {line = 3, file = "layout.ts"},["1449"] = {line = 3, file = "layout.ts"},["1450"] = {line = 4, file = "layout.ts"},["1451"] = {line = 4, file = "layout.ts"},["1452"] = {line = 4, file = "layout.ts"},["1453"] = {line = 4, file = "layout.ts"},["1454"] = {line = 4, file = "layout.ts"},["1455"] = {line = 6, file = "layout.ts"},["1456"] = {line = 7, file = "layout.ts"},["1457"] = {line = 9, file = "layout.ts"},["1458"] = {line = 10, file = "layout.ts"},["1459"] = {line = 9, file = "layout.ts"},["1460"] = {line = 13, file = "layout.ts"},["1461"] = {line = 14, file = "layout.ts"},["1462"] = {line = 16, file = "layout.ts"},["1463"] = {line = 17, file = "layout.ts"},["1464"] = {line = 18, file = "layout.ts"},["1465"] = {line = 18, file = "layout.ts"},["1467"] = {line = 19, file = "layout.ts"},["1468"] = {line = 20, file = "layout.ts"},["1469"] = {line = 21, file = "layout.ts"},["1471"] = {line = 21, file = "layout.ts"},["1475"] = {line = 22, file = "layout.ts"},["1476"] = {line = 23, file = "layout.ts"},["1477"] = {line = 24, file = "layout.ts"},["1478"] = {line = 25, file = "layout.ts"},["1479"] = {line = 25, file = "layout.ts"},["1480"] = {line = 25, file = "layout.ts"},["1481"] = {line = 25, file = "layout.ts"},["1482"] = {line = 26, file = "layout.ts"},["1483"] = {line = 27, file = "layout.ts"},["1484"] = {line = 27, file = "layout.ts"},["1485"] = {line = 27, file = "layout.ts"},["1486"] = {line = 27, file = "layout.ts"},["1487"] = {line = 28, file = "layout.ts"},["1488"] = {line = 29, file = "layout.ts"},["1489"] = {line = 30, file = "layout.ts"},["1490"] = {line = 31, file = "layout.ts"},["1491"] = {line = 32, file = "layout.ts"},["1492"] = {line = 33, file = "layout.ts"},["1493"] = {line = 34, file = "layout.ts"},["1494"] = {line = 35, file = "layout.ts"},["1495"] = {line = 36, file = "layout.ts"},["1496"] = {line = 37, file = "layout.ts"},["1498"] = {line = 16, file = "layout.ts"},["1499"] = {line = 42, file = "layout.ts"},["1500"] = {line = 43, file = "layout.ts"},["1501"] = {line = 44, file = "layout.ts"},["1502"] = {line = 45, file = "layout.ts"},["1505"] = {line = 46, file = "layout.ts"},["1506"] = {line = 47, file = "layout.ts"},["1509"] = {line = 48, file = "layout.ts"},["1510"] = {line = 49, file = "layout.ts"},["1511"] = {line = 49, file = "layout.ts"},["1512"] = {line = 49, file = "layout.ts"},["1513"] = {line = 49, file = "layout.ts"},["1515"] = {line = 49, file = "layout.ts"},["1516"] = {line = 50, file = "layout.ts"},["1517"] = {line = 50, file = "layout.ts"},["1520"] = {line = 42, file = "layout.ts"},["1521"] = {line = 54, file = "layout.ts"},["1522"] = {line = 55, file = "layout.ts"},["1523"] = {line = 56, file = "layout.ts"},["1525"] = {line = 57, file = "layout.ts"},["1526"] = {line = 58, file = "layout.ts"},["1527"] = {line = 59, file = "layout.ts"},["1528"] = {line = 59, file = "layout.ts"},["1530"] = {line = 60, file = "layout.ts"},["1531"] = {line = 61, file = "layout.ts"},["1532"] = {line = 62, file = "layout.ts"},["1533"] = {line = 62, file = "layout.ts"},["1535"] = {line = 63, file = "layout.ts"},["1536"] = {line = 64, file = "layout.ts"},["1537"] = {line = 65, file = "layout.ts"},["1538"] = {line = 66, file = "layout.ts"},["1539"] = {line = 66, file = "layout.ts"},["1542"] = {line = 68, file = "layout.ts"},["1543"] = {line = 69, file = "layout.ts"},["1544"] = {line = 70, file = "layout.ts"},["1545"] = {line = 71, file = "layout.ts"},["1549"] = {line = 54, file = "layout.ts"},["1557"] = {line = 2, file = "live.ts"},["1558"] = {line = 2, file = "live.ts"},["1559"] = {line = 3, file = "live.ts"},["1560"] = {line = 3, file = "live.ts"},["1561"] = {line = 5, file = "live.ts"},["1562"] = {line = 5, file = "live.ts"},["1563"] = {line = 5, file = "live.ts"},["1564"] = {line = 8, file = "live.ts"},["1565"] = {line = 9, file = "live.ts"},["1566"] = {line = 10, file = "live.ts"},["1567"] = {line = 11, file = "live.ts"},["1568"] = {line = 11, file = "live.ts"},["1569"] = {line = 11, file = "live.ts"},["1570"] = {line = 11, file = "live.ts"},["1571"] = {line = 13, file = "live.ts"},["1572"] = {line = 14, file = "live.ts"},["1573"] = {line = 13, file = "live.ts"},["1574"] = {line = 17, file = "live.ts"},["1575"] = {line = 18, file = "live.ts"},["1576"] = {line = 19, file = "live.ts"},["1577"] = {line = 19, file = "live.ts"},["1578"] = {line = 19, file = "live.ts"},["1580"] = {line = 19, file = "live.ts"},["1582"] = {line = 19, file = "live.ts"},["1583"] = {line = 17, file = "live.ts"},["1584"] = {line = 22, file = "live.ts"},["1585"] = {line = 23, file = "live.ts"},["1586"] = {line = 23, file = "live.ts"},["1588"] = {line = 23, file = "live.ts"},["1590"] = {line = 23, file = "live.ts"},["1591"] = {line = 24, file = "live.ts"},["1592"] = {line = 22, file = "live.ts"},["1593"] = {line = 27, file = "live.ts"},["1594"] = {line = 28, file = "live.ts"},["1595"] = {line = 29, file = "live.ts"},["1596"] = {line = 29, file = "live.ts"},["1597"] = {line = 29, file = "live.ts"},["1598"] = {line = 29, file = "live.ts"},["1599"] = {line = 29, file = "live.ts"},["1601"] = {line = 30, file = "live.ts"},["1602"] = {line = 27, file = "live.ts"},["1603"] = {line = 33, file = "live.ts"},["1604"] = {line = 34, file = "live.ts"},["1605"] = {line = 34, file = "live.ts"},["1607"] = {line = 34, file = "live.ts"},["1609"] = {line = 34, file = "live.ts"},["1610"] = {line = 35, file = "live.ts"},["1611"] = {line = 33, file = "live.ts"},["1612"] = {line = 38, file = "live.ts"},["1613"] = {line = 39, file = "live.ts"},["1614"] = {line = 40, file = "live.ts"},["1615"] = {line = 40, file = "live.ts"},["1617"] = {line = 41, file = "live.ts"},["1618"] = {line = 42, file = "live.ts"},["1619"] = {line = 42, file = "live.ts"},["1620"] = {line = 42, file = "live.ts"},["1624"] = {line = 43, file = "live.ts"},["1625"] = {line = 44, file = "live.ts"},["1626"] = {line = 45, file = "live.ts"},["1627"] = {line = 46, file = "live.ts"},["1628"] = {line = 43, file = "live.ts"},["1629"] = {line = 38, file = "live.ts"},["1630"] = {line = 50, file = "live.ts"},["1631"] = {line = 51, file = "live.ts"},["1632"] = {line = 52, file = "live.ts"},["1633"] = {line = 53, file = "live.ts"},["1635"] = {line = 54, file = "live.ts"},["1636"] = {line = 55, file = "live.ts"},["1637"] = {line = 55, file = "live.ts"},["1639"] = {line = 56, file = "live.ts"},["1640"] = {line = 56, file = "live.ts"},["1641"] = {line = 56, file = "live.ts"},["1642"] = {line = 56, file = "live.ts"},["1643"] = {line = 56, file = "live.ts"},["1644"] = {line = 57, file = "live.ts"},["1645"] = {line = 58, file = "live.ts"},["1646"] = {line = 58, file = "live.ts"},["1647"] = {line = 58, file = "live.ts"},["1648"] = {line = 58, file = "live.ts"},["1649"] = {line = 60, file = "live.ts"},["1654"] = {line = 63, file = "live.ts"},["1655"] = {line = 50, file = "live.ts"},["1665"] = {line = 3, file = "patch.ts"},["1666"] = {line = 3, file = "patch.ts"},["1667"] = {line = 3, file = "patch.ts"},["1668"] = {line = 3, file = "patch.ts"},["1669"] = {line = 4, file = "patch.ts"},["1670"] = {line = 4, file = "patch.ts"},["1671"] = {line = 4, file = "patch.ts"},["1672"] = {line = 6, file = "patch.ts"},["1673"] = {line = 6, file = "patch.ts"},["1674"] = {line = 6, file = "patch.ts"},["1675"] = {line = 6, file = "patch.ts"},["1676"] = {line = 7, file = "patch.ts"},["1677"] = {line = 7, file = "patch.ts"},["1678"] = {line = 10, file = "patch.ts"},["1679"] = {line = 12, file = "patch.ts"},["1680"] = {line = 13, file = "patch.ts"},["1681"] = {line = 14, file = "patch.ts"},["1682"] = {line = 15, file = "patch.ts"},["1684"] = {line = 16, file = "patch.ts"},["1685"] = {line = 17, file = "patch.ts"},["1686"] = {line = 17, file = "patch.ts"},["1688"] = {line = 18, file = "patch.ts"},["1689"] = {line = 19, file = "patch.ts"},["1690"] = {line = 19, file = "patch.ts"},["1692"] = {line = 20, file = "patch.ts"},["1693"] = {line = 20, file = "patch.ts"},["1694"] = {line = 21, file = "patch.ts"},["1695"] = {line = 21, file = "patch.ts"},["1697"] = {line = 22, file = "patch.ts"},["1698"] = {line = 22, file = "patch.ts"},["1699"] = {line = 22, file = "patch.ts"},["1700"] = {line = 22, file = "patch.ts"},["1701"] = {line = 23, file = "patch.ts"},["1702"] = {line = 23, file = "patch.ts"},["1704"] = {line = 24, file = "patch.ts"},["1705"] = {line = 24, file = "patch.ts"},["1710"] = {line = 26, file = "patch.ts"},["1711"] = {line = 26, file = "patch.ts"},["1713"] = {line = 27, file = "patch.ts"},["1714"] = {line = 12, file = "patch.ts"},["1715"] = {line = 31, file = "patch.ts"},["1716"] = {line = 32, file = "patch.ts"},["1717"] = {line = 33, file = "patch.ts"},["1718"] = {line = 34, file = "patch.ts"},["1719"] = {line = 35, file = "patch.ts"},["1721"] = {line = 36, file = "patch.ts"},["1722"] = {line = 36, file = "patch.ts"},["1724"] = {line = 37, file = "patch.ts"},["1725"] = {line = 38, file = "patch.ts"},["1726"] = {line = 38, file = "patch.ts"},["1732"] = {line = 41, file = "patch.ts"},["1733"] = {line = 31, file = "patch.ts"},["1734"] = {line = 44, file = "patch.ts"},["1735"] = {line = 45, file = "patch.ts"},["1736"] = {line = 45, file = "patch.ts"},["1737"] = {line = 45, file = "patch.ts"},["1739"] = {line = 45, file = "patch.ts"},["1740"] = {line = 46, file = "patch.ts"},["1741"] = {line = 46, file = "patch.ts"},["1743"] = {line = 47, file = "patch.ts"},["1744"] = {line = 47, file = "patch.ts"},["1746"] = {line = 48, file = "patch.ts"},["1747"] = {line = 49, file = "patch.ts"},["1748"] = {line = 44, file = "patch.ts"},["1749"] = {line = 52, file = "patch.ts"},["1750"] = {line = 53, file = "patch.ts"},["1751"] = {line = 54, file = "patch.ts"},["1753"] = {line = 55, file = "patch.ts"},["1754"] = {line = 55, file = "patch.ts"},["1755"] = {line = 56, file = "patch.ts"},["1756"] = {line = 57, file = "patch.ts"},["1757"] = {line = 57, file = "patch.ts"},["1758"] = {line = 57, file = "patch.ts"},["1760"] = {line = 57, file = "patch.ts"},["1762"] = {line = 57, file = "patch.ts"},["1763"] = {line = 58, file = "patch.ts"},["1764"] = {line = 58, file = "patch.ts"},["1766"] = {line = 55, file = "patch.ts"},["1769"] = {line = 60, file = "patch.ts"},["1770"] = {line = 52, file = "patch.ts"},["1771"] = {line = 63, file = "patch.ts"},["1772"] = {line = 64, file = "patch.ts"},["1773"] = {line = 64, file = "patch.ts"},["1774"] = {line = 64, file = "patch.ts"},["1775"] = {line = 64, file = "patch.ts"},["1776"] = {line = 64, file = "patch.ts"},["1777"] = {line = 65, file = "patch.ts"},["1778"] = {line = 65, file = "patch.ts"},["1779"] = {line = 65, file = "patch.ts"},["1780"] = {line = 65, file = "patch.ts"},["1781"] = {line = 65, file = "patch.ts"},["1782"] = {line = 67, file = "patch.ts"},["1783"] = {line = 67, file = "patch.ts"},["1784"] = {line = 67, file = "patch.ts"},["1785"] = {line = 67, file = "patch.ts"},["1786"] = {line = 67, file = "patch.ts"},["1787"] = {line = 67, file = "patch.ts"},["1788"] = {line = 67, file = "patch.ts"},["1789"] = {line = 63, file = "patch.ts"},["1790"] = {line = 70, file = "patch.ts"},["1791"] = {line = 71, file = "patch.ts"},["1792"] = {line = 71, file = "patch.ts"},["1794"] = {line = 72, file = "patch.ts"},["1795"] = {line = 72, file = "patch.ts"},["1796"] = {line = 72, file = "patch.ts"},["1797"] = {line = 73, file = "patch.ts"},["1798"] = {line = 73, file = "patch.ts"},["1799"] = {line = 73, file = "patch.ts"},["1800"] = {line = 74, file = "patch.ts"},["1801"] = {line = 74, file = "patch.ts"},["1803"] = {line = 75, file = "patch.ts"},["1804"] = {line = 75, file = "patch.ts"},["1805"] = {line = 75, file = "patch.ts"},["1806"] = {line = 75, file = "patch.ts"},["1807"] = {line = 70, file = "patch.ts"},["1808"] = {line = 79, file = "patch.ts"},["1809"] = {line = 80, file = "patch.ts"},["1810"] = {line = 81, file = "patch.ts"},["1811"] = {line = 82, file = "patch.ts"},["1812"] = {line = 82, file = "patch.ts"},["1813"] = {line = 82, file = "patch.ts"},["1814"] = {line = 82, file = "patch.ts"},["1815"] = {line = 82, file = "patch.ts"},["1816"] = {line = 82, file = "patch.ts"},["1817"] = {line = 83, file = "patch.ts"},["1818"] = {line = 83, file = "patch.ts"},["1821"] = {line = 85, file = "patch.ts"},["1822"] = {line = 79, file = "patch.ts"},["1823"] = {line = 88, file = "patch.ts"},["1824"] = {line = 89, file = "patch.ts"},["1825"] = {line = 90, file = "patch.ts"},["1826"] = {line = 90, file = "patch.ts"},["1827"] = {line = 90, file = "patch.ts"},["1828"] = {line = 90, file = "patch.ts"},["1829"] = {line = 90, file = "patch.ts"},["1830"] = {line = 90, file = "patch.ts"},["1832"] = {line = 90, file = "patch.ts"},["1834"] = {line = 90, file = "patch.ts"},["1835"] = {line = 91, file = "patch.ts"},["1836"] = {line = 92, file = "patch.ts"},["1837"] = {line = 92, file = "patch.ts"},["1838"] = {line = 92, file = "patch.ts"},["1839"] = {line = 88, file = "patch.ts"},["1840"] = {line = 96, file = "patch.ts"},["1841"] = {line = 97, file = "patch.ts"},["1842"] = {line = 98, file = "patch.ts"},["1843"] = {line = 99, file = "patch.ts"},["1844"] = {line = 100, file = "patch.ts"},["1845"] = {line = 101, file = "patch.ts"},["1846"] = {line = 101, file = "patch.ts"},["1848"] = {line = 103, file = "patch.ts"},["1849"] = {line = 104, file = "patch.ts"},["1850"] = {line = 105, file = "patch.ts"},["1851"] = {line = 106, file = "patch.ts"},["1852"] = {line = 106, file = "patch.ts"},["1853"] = {line = 106, file = "patch.ts"},["1854"] = {line = 106, file = "patch.ts"},["1855"] = {line = 106, file = "patch.ts"},["1856"] = {line = 106, file = "patch.ts"},["1857"] = {line = 106, file = "patch.ts"},["1859"] = {line = 106, file = "patch.ts"},["1860"] = {line = 106, file = "patch.ts"},["1861"] = {line = 106, file = "patch.ts"},["1862"] = {line = 106, file = "patch.ts"},["1863"] = {line = 106, file = "patch.ts"},["1867"] = {line = 109, file = "patch.ts"},["1868"] = {line = 110, file = "patch.ts"},["1869"] = {line = 110, file = "patch.ts"},["1871"] = {line = 111, file = "patch.ts"},["1872"] = {line = 112, file = "patch.ts"},["1873"] = {line = 113, file = "patch.ts"},["1876"] = {line = 114, file = "patch.ts"},["1877"] = {line = 115, file = "patch.ts"},["1880"] = {line = 116, file = "patch.ts"},["1881"] = {line = 117, file = "patch.ts"},["1882"] = {line = 118, file = "patch.ts"},["1883"] = {line = 119, file = "patch.ts"},["1884"] = {line = 119, file = "patch.ts"},["1885"] = {line = 119, file = "patch.ts"},["1887"] = {line = 119, file = "patch.ts"},["1889"] = {line = 119, file = "patch.ts"},["1890"] = {line = 120, file = "patch.ts"},["1893"] = {line = 121, file = "patch.ts"},["1895"] = {line = 123, file = "patch.ts"},["1896"] = {line = 124, file = "patch.ts"},["1897"] = {line = 124, file = "patch.ts"},["1900"] = {line = 127, file = "patch.ts"},["1901"] = {line = 127, file = "patch.ts"},["1902"] = {line = 127, file = "patch.ts"},["1903"] = {line = 127, file = "patch.ts"},["1904"] = {line = 127, file = "patch.ts"},["1905"] = {line = 127, file = "patch.ts"},["1906"] = {line = 127, file = "patch.ts"},["1907"] = {line = 127, file = "patch.ts"},["1908"] = {line = 103, file = "patch.ts"},["1909"] = {line = 130, file = "patch.ts"},["1910"] = {line = 130, file = "patch.ts"},["1911"] = {line = 130, file = "patch.ts"},["1912"] = {line = 130, file = "patch.ts"},["1913"] = {line = 131, file = "patch.ts"},["1914"] = {line = 131, file = "patch.ts"},["1915"] = {line = 131, file = "patch.ts"},["1918"] = {line = 132, file = "patch.ts"},["1919"] = {line = 132, file = "patch.ts"},["1920"] = {line = 132, file = "patch.ts"},["1921"] = {line = 132, file = "patch.ts"},["1922"] = {line = 133, file = "patch.ts"},["1923"] = {line = 133, file = "patch.ts"},["1924"] = {line = 133, file = "patch.ts"},["1925"] = {line = 133, file = "patch.ts"},["1926"] = {line = 134, file = "patch.ts"},["1927"] = {line = 96, file = "patch.ts"},["1935"] = {line = 2, file = "ui.ts"},["1936"] = {line = 2, file = "ui.ts"},["1937"] = {line = 4, file = "ui.ts"},["1938"] = {line = 4, file = "ui.ts"},["1939"] = {line = 6, file = "ui.ts"},["1940"] = {line = 7, file = "ui.ts"},["1941"] = {line = 8, file = "ui.ts"},["1942"] = {line = 8, file = "ui.ts"},["1943"] = {line = 8, file = "ui.ts"},["1945"] = {line = 8, file = "ui.ts"},["1947"] = {line = 8, file = "ui.ts"},["1948"] = {line = 6, file = "ui.ts"},["1949"] = {line = 11, file = "ui.ts"},["1950"] = {line = 11, file = "ui.ts"},["1951"] = {line = 11, file = "ui.ts"},["1952"] = {line = 11, file = "ui.ts"},["1953"] = {line = 11, file = "ui.ts"},["1954"] = {line = 11, file = "ui.ts"},["1955"] = {line = 11, file = "ui.ts"},["1956"] = {line = 11, file = "ui.ts"},["1957"] = {line = 11, file = "ui.ts"},["1958"] = {line = 13, file = "ui.ts"},["1959"] = {line = 14, file = "ui.ts"},["1960"] = {line = 14, file = "ui.ts"},["1961"] = {line = 14, file = "ui.ts"},["1962"] = {line = 14, file = "ui.ts"},["1963"] = {line = 14, file = "ui.ts"},["1964"] = {line = 15, file = "ui.ts"},["1965"] = {line = 15, file = "ui.ts"},["1966"] = {line = 15, file = "ui.ts"},["1967"] = {line = 14, file = "ui.ts"},["1968"] = {line = 16, file = "ui.ts"},["1969"] = {line = 17, file = "ui.ts"},["1970"] = {line = 18, file = "ui.ts"},["1971"] = {line = 19, file = "ui.ts"},["1972"] = {line = 20, file = "ui.ts"},["1973"] = {line = 20, file = "ui.ts"},["1974"] = {line = 20, file = "ui.ts"},["1975"] = {line = 20, file = "ui.ts"},["1976"] = {line = 21, file = "ui.ts"},["1977"] = {line = 16, file = "ui.ts"},["1978"] = {line = 23, file = "ui.ts"},["1979"] = {line = 23, file = "ui.ts"},["1981"] = {line = 24, file = "ui.ts"},["1982"] = {line = 24, file = "ui.ts"},["1983"] = {line = 24, file = "ui.ts"},["1985"] = {line = 24, file = "ui.ts"},["1987"] = {line = 24, file = "ui.ts"},["1988"] = {line = 24, file = "ui.ts"},["1989"] = {line = 24, file = "ui.ts"},["1991"] = {line = 24, file = "ui.ts"},["1992"] = {line = 24, file = "ui.ts"},["1993"] = {line = 26, file = "ui.ts"},["1995"] = {line = 26, file = "ui.ts"},["1997"] = {line = 25, file = "ui.ts"},["1998"] = {line = 26, file = "ui.ts"},["1999"] = {line = 27, file = "ui.ts"},["2000"] = {line = 27, file = "ui.ts"},["2001"] = {line = 27, file = "ui.ts"},["2002"] = {line = 27, file = "ui.ts"},["2003"] = {line = 28, file = "ui.ts"},["2004"] = {line = 28, file = "ui.ts"},["2005"] = {line = 28, file = "ui.ts"},["2006"] = {line = 25, file = "ui.ts"},["2007"] = {line = 13, file = "ui.ts"},["2008"] = {line = 33, file = "ui.ts"},["2009"] = {line = 34, file = "ui.ts"},["2010"] = {line = 34, file = "ui.ts"},["2011"] = {line = 34, file = "ui.ts"},["2012"] = {line = 34, file = "ui.ts"},["2013"] = {line = 34, file = "ui.ts"},["2014"] = {line = 33, file = "ui.ts"},["2015"] = {line = 37, file = "ui.ts"},["2016"] = {line = 38, file = "ui.ts"},["2017"] = {line = 41, file = "ui.ts"},["2018"] = {line = 46, file = "ui.ts"},["2019"] = {line = 46, file = "ui.ts"},["2020"] = {line = 47, file = "ui.ts"},["2023"] = {line = 48, file = "ui.ts"},["2026"] = {line = 52, file = "ui.ts"},["2027"] = {line = 52, file = "ui.ts"},["2028"] = {line = 52, file = "ui.ts"},["2029"] = {line = 52, file = "ui.ts"},["2032"] = {line = 50, file = "ui.ts"},["2038"] = {line = 54, file = "ui.ts"},["2039"] = {line = 54, file = "ui.ts"},["2042"] = {line = 56, file = "ui.ts"},["2043"] = {line = 57, file = "ui.ts"},["2044"] = {line = 58, file = "ui.ts"},["2046"] = {line = 42, file = "ui.ts"},["2047"] = {line = 43, file = "ui.ts"},["2048"] = {line = 44, file = "ui.ts"},["2049"] = {line = 44, file = "ui.ts"},["2050"] = {line = 44, file = "ui.ts"},["2051"] = {line = 44, file = "ui.ts"},["2052"] = {line = 45, file = "ui.ts"},["2053"] = {line = 60, file = "ui.ts"},["2054"] = {line = 61, file = "ui.ts"},["2055"] = {line = 41, file = "ui.ts"},["2056"] = {line = 64, file = "ui.ts"},["2057"] = {line = 65, file = "ui.ts"},["2058"] = {line = 66, file = "ui.ts"},["2059"] = {line = 67, file = "ui.ts"},["2060"] = {line = 68, file = "ui.ts"},["2061"] = {line = 68, file = "ui.ts"},["2063"] = {line = 64, file = "ui.ts"},["2064"] = {line = 71, file = "ui.ts"},["2065"] = {line = 72, file = "ui.ts"},["2066"] = {line = 72, file = "ui.ts"},["2068"] = {line = 71, file = "ui.ts"},["2077"] = {line = 2, file = "vars.ts"},["2078"] = {line = 3, file = "vars.ts"},["2079"] = {line = 3, file = "vars.ts"},["2080"] = {line = 3, file = "vars.ts"},["2081"] = {line = 3, file = "vars.ts"},["2082"] = {line = 4, file = "vars.ts"},["2083"] = {line = 4, file = "vars.ts"},["2084"] = {line = 4, file = "vars.ts"},["2086"] = {line = 4, file = "vars.ts"},["2088"] = {line = 4, file = "vars.ts"},["2089"] = {line = 2, file = "vars.ts"},["2090"] = {line = 7, file = "vars.ts"},["2091"] = {line = 8, file = "vars.ts"},["2092"] = {line = 8, file = "vars.ts"},["2093"] = {line = 8, file = "vars.ts"},["2094"] = {line = 8, file = "vars.ts"},["2095"] = {line = 8, file = "vars.ts"},["2096"] = {line = 7, file = "vars.ts"},["2105"] = {line = 6, file = "ma-desk.ts"},["2106"] = {line = 7, file = "ma-desk.ts"},["2107"] = {line = 8, file = "ma-desk.ts"},["2108"] = {line = 9, file = "ma-desk.ts"},["2109"] = {line = 9, file = "ma-desk.ts"},["2110"] = {line = 10, file = "ma-desk.ts"},["2111"] = {line = 10, file = "ma-desk.ts"},["2112"] = {line = 11, file = "ma-desk.ts"},["2113"] = {line = 12, file = "ma-desk.ts"},["2114"] = {line = 13, file = "ma-desk.ts"},["2115"] = {line = 15, file = "ma-desk.ts"},["2116"] = {line = 15, file = "ma-desk.ts"},["2117"] = {line = 15, file = "ma-desk.ts"},["2119"] = {line = 16, file = "ma-desk.ts"},["2120"] = {line = 15, file = "ma-desk.ts"},["2121"] = {line = 18, file = "ma-desk.ts"},["2122"] = {line = 18, file = "ma-desk.ts"},["2123"] = {line = 18, file = "ma-desk.ts"},["2124"] = {line = 19, file = "ma-desk.ts"},["2125"] = {line = 19, file = "ma-desk.ts"},["2126"] = {line = 19, file = "ma-desk.ts"},["2127"] = {line = 20, file = "ma-desk.ts"},["2128"] = {line = 20, file = "ma-desk.ts"},["2129"] = {line = 20, file = "ma-desk.ts"},["2130"] = {line = 21, file = "ma-desk.ts"},["2131"] = {line = 21, file = "ma-desk.ts"},["2132"] = {line = 21, file = "ma-desk.ts"},["2133"] = {line = 22, file = "ma-desk.ts"},["2134"] = {line = 23, file = "ma-desk.ts"},["2135"] = {line = 24, file = "ma-desk.ts"},["2136"] = {line = 22, file = "ma-desk.ts"},["2137"] = {line = 26, file = "ma-desk.ts"},["2138"] = {line = 27, file = "ma-desk.ts"},["2139"] = {line = 28, file = "ma-desk.ts"},["2140"] = {line = 29, file = "ma-desk.ts"},["2141"] = {line = 30, file = "ma-desk.ts"},["2142"] = {line = 30, file = "ma-desk.ts"},["2143"] = {line = 30, file = "ma-desk.ts"},["2144"] = {line = 30, file = "ma-desk.ts"},["2145"] = {line = 30, file = "ma-desk.ts"},["2146"] = {line = 30, file = "ma-desk.ts"},["2147"] = {line = 31, file = "ma-desk.ts"},["2148"] = {line = 31, file = "ma-desk.ts"},["2149"] = {line = 31, file = "ma-desk.ts"},["2150"] = {line = 31, file = "ma-desk.ts"},["2151"] = {line = 31, file = "ma-desk.ts"},["2152"] = {line = 31, file = "ma-desk.ts"},["2153"] = {line = 31, file = "ma-desk.ts"},["2156"] = {line = 26, file = "ma-desk.ts"},["2157"] = {line = 34, file = "ma-desk.ts"},["2158"] = {line = 34, file = "ma-desk.ts"},["2159"] = {line = 34, file = "ma-desk.ts"},["2160"] = {line = 35, file = "ma-desk.ts"},["2161"] = {line = 35, file = "ma-desk.ts"},["2162"] = {line = 35, file = "ma-desk.ts"},["2163"] = {line = 36, file = "ma-desk.ts"},["2164"] = {line = 36, file = "ma-desk.ts"},["2165"] = {line = 36, file = "ma-desk.ts"},["2166"] = {line = 37, file = "ma-desk.ts"},["2167"] = {line = 37, file = "ma-desk.ts"},["2168"] = {line = 37, file = "ma-desk.ts"},["2169"] = {line = 38, file = "ma-desk.ts"},["2170"] = {line = 38, file = "ma-desk.ts"},["2171"] = {line = 38, file = "ma-desk.ts"},["2172"] = {line = 39, file = "ma-desk.ts"},["2173"] = {line = 40, file = "ma-desk.ts"},["2174"] = {line = 40, file = "ma-desk.ts"},["2175"] = {line = 40, file = "ma-desk.ts"},["2176"] = {line = 40, file = "ma-desk.ts"},["2177"] = {line = 41, file = "ma-desk.ts"},["2178"] = {line = 41, file = "ma-desk.ts"},["2179"] = {line = 41, file = "ma-desk.ts"},["2180"] = {line = 41, file = "ma-desk.ts"},["2181"] = {line = 41, file = "ma-desk.ts"},["2183"] = {line = 39, file = "ma-desk.ts"},["2184"] = {line = 43, file = "ma-desk.ts"},["2185"] = {line = 44, file = "ma-desk.ts"},["2186"] = {line = 44, file = "ma-desk.ts"},["2187"] = {line = 44, file = "ma-desk.ts"},["2188"] = {line = 44, file = "ma-desk.ts"},["2189"] = {line = 45, file = "ma-desk.ts"},["2190"] = {line = 45, file = "ma-desk.ts"},["2191"] = {line = 45, file = "ma-desk.ts"},["2192"] = {line = 45, file = "ma-desk.ts"},["2193"] = {line = 45, file = "ma-desk.ts"},["2195"] = {line = 43, file = "ma-desk.ts"},["2196"] = {line = 47, file = "ma-desk.ts"},["2197"] = {line = 47, file = "ma-desk.ts"},["2198"] = {line = 47, file = "ma-desk.ts"},["2199"] = {line = 48, file = "ma-desk.ts"},["2200"] = {line = 48, file = "ma-desk.ts"},["2201"] = {line = 48, file = "ma-desk.ts"},["2202"] = {line = 49, file = "ma-desk.ts"},["2203"] = {line = 49, file = "ma-desk.ts"},["2204"] = {line = 49, file = "ma-desk.ts"},["2205"] = {line = 50, file = "ma-desk.ts"},["2206"] = {line = 50, file = "ma-desk.ts"},["2207"] = {line = 50, file = "ma-desk.ts"},["2208"] = {line = 51, file = "ma-desk.ts"},["2209"] = {line = 51, file = "ma-desk.ts"},["2210"] = {line = 51, file = "ma-desk.ts"},["2211"] = {line = 52, file = "ma-desk.ts"},["2212"] = {line = 52, file = "ma-desk.ts"},["2213"] = {line = 52, file = "ma-desk.ts"},["2214"] = {line = 53, file = "ma-desk.ts"},["2215"] = {line = 53, file = "ma-desk.ts"},["2216"] = {line = 53, file = "ma-desk.ts"},["2217"] = {line = 54, file = "ma-desk.ts"},["2218"] = {line = 54, file = "ma-desk.ts"},["2219"] = {line = 54, file = "ma-desk.ts"},["2220"] = {line = 55, file = "ma-desk.ts"},["2221"] = {line = 55, file = "ma-desk.ts"},["2222"] = {line = 55, file = "ma-desk.ts"},["2223"] = {line = 56, file = "ma-desk.ts"},["2224"] = {line = 56, file = "ma-desk.ts"},["2225"] = {line = 56, file = "ma-desk.ts"},["2226"] = {line = 57, file = "ma-desk.ts"},["2227"] = {line = 57, file = "ma-desk.ts"},["2228"] = {line = 57, file = "ma-desk.ts"},["2229"] = {line = 58, file = "ma-desk.ts"},["2230"] = {line = 58, file = "ma-desk.ts"},["2231"] = {line = 58, file = "ma-desk.ts"},["2232"] = {line = 59, file = "ma-desk.ts"},["2233"] = {line = 59, file = "ma-desk.ts"},["2234"] = {line = 59, file = "ma-desk.ts"},["2235"] = {line = 62, file = "ma-desk.ts"},["2236"] = {line = 63, file = "ma-desk.ts"},["2237"] = {line = 62, file = "ma-desk.ts"},["2249"] = {line = 2, file = "arm-command.ts"},["2250"] = {line = 2, file = "arm-command.ts"},["2251"] = {line = 4, file = "arm-command.ts"},["2252"] = {line = 5, file = "arm-command.ts"},["2253"] = {line = 6, file = "arm-command.ts"},["2254"] = {line = 7, file = "arm-command.ts"},["2255"] = {line = 8, file = "arm-command.ts"},["2256"] = {line = 9, file = "arm-command.ts"},["2257"] = {line = 10, file = "arm-command.ts"},["2260"] = {line = 13, file = "arm-command.ts"},["2261"] = {line = 13, file = "arm-command.ts"},["2262"] = {line = 13, file = "arm-command.ts"},["2263"] = {line = 13, file = "arm-command.ts"},["2264"] = {line = 14, file = "arm-command.ts"},["2265"] = {line = 4, file = "arm-command.ts"},["2266"] = {line = 17, file = "arm-command.ts"},["2267"] = {line = 18, file = "arm-command.ts"},["2268"] = {line = 18, file = "arm-command.ts"},["2269"] = {line = 18, file = "arm-command.ts"},["2270"] = {line = 18, file = "arm-command.ts"},["2271"] = {line = 18, file = "arm-command.ts"},["2272"] = {line = 18, file = "arm-command.ts"},["2273"] = {line = 18, file = "arm-command.ts"},["2274"] = {line = 17, file = "arm-command.ts"},["2275"] = {line = 21, file = "arm-command.ts"},["2276"] = {line = 22, file = "arm-command.ts"},["2277"] = {line = 21, file = "arm-command.ts"},["2278"] = {line = 25, file = "arm-command.ts"},["2279"] = {line = 26, file = "arm-command.ts"},["2280"] = {line = 27, file = "arm-command.ts"},["2281"] = {line = 28, file = "arm-command.ts"},["2282"] = {line = 29, file = "arm-command.ts"},["2283"] = {line = 29, file = "arm-command.ts"},["2286"] = {line = 31, file = "arm-command.ts"},["2287"] = {line = 25, file = "arm-command.ts"},["2288"] = {line = 35, file = "arm-command.ts"},["2289"] = {line = 36, file = "arm-command.ts"},["2290"] = {line = 37, file = "arm-command.ts"},["2291"] = {line = 38, file = "arm-command.ts"},["2292"] = {line = 39, file = "arm-command.ts"},["2293"] = {line = 40, file = "arm-command.ts"},["2294"] = {line = 40, file = "arm-command.ts"},["2298"] = {line = 43, file = "arm-command.ts"},["2299"] = {line = 44, file = "arm-command.ts"},["2300"] = {line = 35, file = "arm-command.ts"},["2307"] = {line = 2, file = "program.ts"},["2308"] = {line = 2, file = "program.ts"},["2309"] = {line = 2, file = "program.ts"},["2310"] = {line = 7, file = "program.ts"},["2311"] = {line = 8, file = "program.ts"},["2312"] = {line = 8, file = "program.ts"},["2313"] = {line = 8, file = "program.ts"},["2314"] = {line = 8, file = "program.ts"},["2315"] = {line = 9, file = "program.ts"},["2316"] = {line = 10, file = "program.ts"},["2318"] = {line = 12, file = "program.ts"},["2319"] = {line = 13, file = "program.ts"},["2320"] = {line = 14, file = "program.ts"},["2322"] = {line = 16, file = "program.ts"},["2323"] = {line = 17, file = "program.ts"},["2324"] = {line = 17, file = "program.ts"},["2326"] = {line = 18, file = "program.ts"},["2327"] = {line = 7, file = "program.ts"},["2328"] = {line = 21, file = "program.ts"},["2329"] = {line = 22, file = "program.ts"},["2330"] = {line = 21, file = "program.ts"},["2337"] = {line = 3, file = "fixture-state.ts"},["2338"] = {line = 3, file = "fixture-state.ts"},["2339"] = {line = 4, file = "fixture-state.ts"},["2340"] = {line = 4, file = "fixture-state.ts"},["2341"] = {line = 4, file = "fixture-state.ts"},["2342"] = {line = 4, file = "fixture-state.ts"},["2343"] = {line = 17, file = "fixture-state.ts"},["2344"] = {line = 19, file = "fixture-state.ts"},["2345"] = {line = 20, file = "fixture-state.ts"},["2346"] = {line = 20, file = "fixture-state.ts"},["2348"] = {line = 21, file = "fixture-state.ts"},["2349"] = {line = 21, file = "fixture-state.ts"},["2351"] = {line = 22, file = "fixture-state.ts"},["2352"] = {line = 22, file = "fixture-state.ts"},["2354"] = {line = 23, file = "fixture-state.ts"},["2355"] = {line = 23, file = "fixture-state.ts"},["2357"] = {line = 24, file = "fixture-state.ts"},["2358"] = {line = 24, file = "fixture-state.ts"},["2360"] = {line = 25, file = "fixture-state.ts"},["2361"] = {line = 26, file = "fixture-state.ts"},["2362"] = {line = 27, file = "fixture-state.ts"},["2363"] = {line = 28, file = "fixture-state.ts"},["2364"] = {line = 29, file = "fixture-state.ts"},["2365"] = {line = 30, file = "fixture-state.ts"},["2366"] = {line = 31, file = "fixture-state.ts"},["2367"] = {line = 31, file = "fixture-state.ts"},["2368"] = {line = 31, file = "fixture-state.ts"},["2369"] = {line = 31, file = "fixture-state.ts"},["2370"] = {line = 31, file = "fixture-state.ts"},["2371"] = {line = 31, file = "fixture-state.ts"},["2372"] = {line = 32, file = "fixture-state.ts"},["2373"] = {line = 30, file = "fixture-state.ts"},["2374"] = {line = 19, file = "fixture-state.ts"},["2383"] = {line = 4, file = "view-model.ts"},["2384"] = {line = 4, file = "view-model.ts"},["2385"] = {line = 4, file = "view-model.ts"},["2386"] = {line = 4, file = "view-model.ts"},["2387"] = {line = 7, file = "view-model.ts"},["2388"] = {line = 8, file = "view-model.ts"},["2389"] = {line = 8, file = "view-model.ts"},["2390"] = {line = 8, file = "view-model.ts"},["2391"] = {line = 8, file = "view-model.ts"},["2392"] = {line = 9, file = "view-model.ts"},["2393"] = {line = 9, file = "view-model.ts"},["2394"] = {line = 9, file = "view-model.ts"},["2395"] = {line = 7, file = "view-model.ts"},["2396"] = {line = 11, file = "view-model.ts"},["2397"] = {line = 12, file = "view-model.ts"},["2398"] = {line = 20, file = "view-model.ts"},["2399"] = {line = 21, file = "view-model.ts"},["2400"] = {line = 21, file = "view-model.ts"},["2401"] = {line = 21, file = "view-model.ts"},["2402"] = {line = 21, file = "view-model.ts"},["2403"] = {line = 22, file = "view-model.ts"},["2404"] = {line = 22, file = "view-model.ts"},["2405"] = {line = 22, file = "view-model.ts"},["2406"] = {line = 22, file = "view-model.ts"},["2407"] = {line = 20, file = "view-model.ts"},["2408"] = {line = 25, file = "view-model.ts"},["2409"] = {line = 26, file = "view-model.ts"},["2410"] = {line = 25, file = "view-model.ts"},["2411"] = {line = 29, file = "view-model.ts"},["2412"] = {line = 30, file = "view-model.ts"},["2413"] = {line = 29, file = "view-model.ts"},["2414"] = {line = 33, file = "view-model.ts"},["2415"] = {line = 34, file = "view-model.ts"},["2416"] = {line = 35, file = "view-model.ts"},["2417"] = {line = 36, file = "view-model.ts"},["2418"] = {line = 37, file = "view-model.ts"},["2419"] = {line = 38, file = "view-model.ts"},["2420"] = {line = 38, file = "view-model.ts"},["2421"] = {line = 38, file = "view-model.ts"},["2422"] = {line = 38, file = "view-model.ts"},["2423"] = {line = 39, file = "view-model.ts"},["2424"] = {line = 39, file = "view-model.ts"},["2425"] = {line = 39, file = "view-model.ts"},["2426"] = {line = 39, file = "view-model.ts"},["2427"] = {line = 37, file = "view-model.ts"},["2428"] = {line = 41, file = "view-model.ts"},["2429"] = {line = 41, file = "view-model.ts"},["2430"] = {line = 41, file = "view-model.ts"},["2431"] = {line = 42, file = "view-model.ts"},["2432"] = {line = 43, file = "view-model.ts"},["2433"] = {line = 43, file = "view-model.ts"},["2434"] = {line = 43, file = "view-model.ts"},["2435"] = {line = 43, file = "view-model.ts"},["2436"] = {line = 43, file = "view-model.ts"},["2437"] = {line = 43, file = "view-model.ts"},["2438"] = {line = 43, file = "view-model.ts"},["2439"] = {line = 43, file = "view-model.ts"},["2440"] = {line = 44, file = "view-model.ts"},["2442"] = {line = 46, file = "view-model.ts"},["2443"] = {line = 46, file = "view-model.ts"},["2444"] = {line = 46, file = "view-model.ts"},["2445"] = {line = 47, file = "view-model.ts"},["2446"] = {line = 47, file = "view-model.ts"},["2447"] = {line = 47, file = "view-model.ts"},["2448"] = {line = 47, file = "view-model.ts"},["2449"] = {line = 47, file = "view-model.ts"},["2450"] = {line = 47, file = "view-model.ts"},["2451"] = {line = 47, file = "view-model.ts"},["2452"] = {line = 47, file = "view-model.ts"},["2453"] = {line = 47, file = "view-model.ts"},["2454"] = {line = 47, file = "view-model.ts"},["2455"] = {line = 47, file = "view-model.ts"},["2456"] = {line = 47, file = "view-model.ts"},["2457"] = {line = 47, file = "view-model.ts"},["2458"] = {line = 47, file = "view-model.ts"},["2459"] = {line = 47, file = "view-model.ts"},["2460"] = {line = 48, file = "view-model.ts"},["2461"] = {line = 49, file = "view-model.ts"},["2462"] = {line = 49, file = "view-model.ts"},["2463"] = {line = 49, file = "view-model.ts"},["2464"] = {line = 50, file = "view-model.ts"},["2465"] = {line = 51, file = "view-model.ts"},["2466"] = {line = 52, file = "view-model.ts"},["2467"] = {line = 52, file = "view-model.ts"},["2468"] = {line = 52, file = "view-model.ts"},["2469"] = {line = 52, file = "view-model.ts"},["2470"] = {line = 52, file = "view-model.ts"},["2471"] = {line = 52, file = "view-model.ts"},["2472"] = {line = 52, file = "view-model.ts"},["2473"] = {line = 52, file = "view-model.ts"},["2474"] = {line = 53, file = "view-model.ts"},["2475"] = {line = 53, file = "view-model.ts"},["2476"] = {line = 53, file = "view-model.ts"},["2477"] = {line = 53, file = "view-model.ts"},["2478"] = {line = 53, file = "view-model.ts"},["2479"] = {line = 53, file = "view-model.ts"},["2480"] = {line = 53, file = "view-model.ts"},["2481"] = {line = 53, file = "view-model.ts"},["2482"] = {line = 53, file = "view-model.ts"},["2483"] = {line = 53, file = "view-model.ts"},["2484"] = {line = 53, file = "view-model.ts"},["2485"] = {line = 53, file = "view-model.ts"},["2486"] = {line = 53, file = "view-model.ts"},["2487"] = {line = 53, file = "view-model.ts"},["2488"] = {line = 53, file = "view-model.ts"},["2489"] = {line = 54, file = "view-model.ts"},["2490"] = {line = 54, file = "view-model.ts"},["2491"] = {line = 54, file = "view-model.ts"},["2492"] = {line = 54, file = "view-model.ts"},["2493"] = {line = 54, file = "view-model.ts"},["2494"] = {line = 54, file = "view-model.ts"},["2495"] = {line = 54, file = "view-model.ts"},["2496"] = {line = 55, file = "view-model.ts"},["2497"] = {line = 56, file = "view-model.ts"},["2498"] = {line = 56, file = "view-model.ts"},["2499"] = {line = 56, file = "view-model.ts"},["2500"] = {line = 56, file = "view-model.ts"},["2501"] = {line = 57, file = "view-model.ts"},["2502"] = {line = 57, file = "view-model.ts"},["2503"] = {line = 57, file = "view-model.ts"},["2504"] = {line = 57, file = "view-model.ts"},["2505"] = {line = 57, file = "view-model.ts"},["2506"] = {line = 57, file = "view-model.ts"},["2507"] = {line = 57, file = "view-model.ts"},["2508"] = {line = 57, file = "view-model.ts"},["2509"] = {line = 58, file = "view-model.ts"},["2511"] = {line = 49, file = "view-model.ts"},["2512"] = {line = 49, file = "view-model.ts"},["2513"] = {line = 61, file = "view-model.ts"},["2514"] = {line = 33, file = "view-model.ts"},["2515"] = {line = 64, file = "view-model.ts"},["2516"] = {line = 65, file = "view-model.ts"},["2517"] = {line = 65, file = "view-model.ts"},["2519"] = {line = 66, file = "view-model.ts"},["2520"] = {line = 66, file = "view-model.ts"},["2522"] = {line = 67, file = "view-model.ts"},["2523"] = {line = 67, file = "view-model.ts"},["2525"] = {line = 68, file = "view-model.ts"},["2526"] = {line = 64, file = "view-model.ts"},["2527"] = {line = 71, file = "view-model.ts"},["2528"] = {line = 72, file = "view-model.ts"},["2529"] = {line = 73, file = "view-model.ts"},["2530"] = {line = 73, file = "view-model.ts"},["2531"] = {line = 73, file = "view-model.ts"},["2533"] = {line = 73, file = "view-model.ts"},["2534"] = {line = 73, file = "view-model.ts"},["2536"] = {line = 73, file = "view-model.ts"},["2537"] = {line = 73, file = "view-model.ts"},["2538"] = {line = 74, file = "view-model.ts"},["2539"] = {line = 74, file = "view-model.ts"},["2540"] = {line = 74, file = "view-model.ts"},["2541"] = {line = 74, file = "view-model.ts"},["2542"] = {line = 74, file = "view-model.ts"},["2543"] = {line = 75, file = "view-model.ts"},["2544"] = {line = 76, file = "view-model.ts"},["2545"] = {line = 76, file = "view-model.ts"},["2546"] = {line = 76, file = "view-model.ts"},["2547"] = {line = 76, file = "view-model.ts"},["2548"] = {line = 76, file = "view-model.ts"},["2549"] = {line = 76, file = "view-model.ts"},["2550"] = {line = 76, file = "view-model.ts"},["2552"] = {line = 77, file = "view-model.ts"},["2554"] = {line = 78, file = "view-model.ts"},["2555"] = {line = 79, file = "view-model.ts"},["2556"] = {line = 80, file = "view-model.ts"},["2557"] = {line = 81, file = "view-model.ts"},["2558"] = {line = 81, file = "view-model.ts"},["2559"] = {line = 81, file = "view-model.ts"},["2560"] = {line = 81, file = "view-model.ts"},["2561"] = {line = 82, file = "view-model.ts"},["2562"] = {line = 83, file = "view-model.ts"},["2563"] = {line = 84, file = "view-model.ts"},["2564"] = {line = 85, file = "view-model.ts"},["2565"] = {line = 85, file = "view-model.ts"},["2566"] = {line = 85, file = "view-model.ts"},["2567"] = {line = 85, file = "view-model.ts"},["2568"] = {line = 85, file = "view-model.ts"},["2569"] = {line = 85, file = "view-model.ts"},["2571"] = {line = 87, file = "view-model.ts"},["2572"] = {line = 88, file = "view-model.ts"},["2573"] = {line = 89, file = "view-model.ts"},["2574"] = {line = 90, file = "view-model.ts"},["2575"] = {line = 91, file = "view-model.ts"},["2576"] = {line = 92, file = "view-model.ts"},["2577"] = {line = 93, file = "view-model.ts"},["2578"] = {line = 93, file = "view-model.ts"},["2579"] = {line = 94, file = "view-model.ts"},["2580"] = {line = 95, file = "view-model.ts"},["2581"] = {line = 96, file = "view-model.ts"},["2583"] = {line = 97, file = "view-model.ts"},["2586"] = {line = 99, file = "view-model.ts"},["2587"] = {line = 99, file = "view-model.ts"},["2588"] = {line = 99, file = "view-model.ts"},["2589"] = {line = 99, file = "view-model.ts"},["2590"] = {line = 100, file = "view-model.ts"},["2591"] = {line = 101, file = "view-model.ts"},["2592"] = {line = 101, file = "view-model.ts"},["2593"] = {line = 101, file = "view-model.ts"},["2594"] = {line = 101, file = "view-model.ts"},["2595"] = {line = 101, file = "view-model.ts"},["2596"] = {line = 102, file = "view-model.ts"},["2597"] = {line = 102, file = "view-model.ts"},["2598"] = {line = 102, file = "view-model.ts"},["2599"] = {line = 102, file = "view-model.ts"},["2600"] = {line = 103, file = "view-model.ts"},["2601"] = {line = 103, file = "view-model.ts"},["2602"] = {line = 103, file = "view-model.ts"},["2603"] = {line = 103, file = "view-model.ts"},["2604"] = {line = 104, file = "view-model.ts"},["2605"] = {line = 104, file = "view-model.ts"},["2606"] = {line = 104, file = "view-model.ts"},["2607"] = {line = 104, file = "view-model.ts"},["2608"] = {line = 105, file = "view-model.ts"},["2609"] = {line = 105, file = "view-model.ts"},["2610"] = {line = 105, file = "view-model.ts"},["2611"] = {line = 105, file = "view-model.ts"},["2613"] = {line = 107, file = "view-model.ts"},["2614"] = {line = 71, file = "view-model.ts"},["2632"] = {line = 2, file = "autozoom.ts"},["2633"] = {line = 2, file = "autozoom.ts"},["2634"] = {line = 2, file = "autozoom.ts"},["2635"] = {line = 2, file = "autozoom.ts"},["2636"] = {line = 2, file = "autozoom.ts"},["2637"] = {line = 3, file = "autozoom.ts"},["2638"] = {line = 3, file = "autozoom.ts"},["2639"] = {line = 3, file = "autozoom.ts"},["2640"] = {line = 4, file = "autozoom.ts"},["2641"] = {line = 4, file = "autozoom.ts"},["2642"] = {line = 5, file = "autozoom.ts"},["2643"] = {line = 5, file = "autozoom.ts"},["2644"] = {line = 7, file = "autozoom.ts"},["2645"] = {line = 7, file = "autozoom.ts"},["2646"] = {line = 7, file = "autozoom.ts"},["2647"] = {line = 7, file = "autozoom.ts"},["2648"] = {line = 9, file = "autozoom.ts"},["2649"] = {line = 9, file = "autozoom.ts"},["2650"] = {line = 9, file = "autozoom.ts"},["2651"] = {line = 9, file = "autozoom.ts"},["2652"] = {line = 9, file = "autozoom.ts"},["2653"] = {line = 9, file = "autozoom.ts"},["2654"] = {line = 9, file = "autozoom.ts"},["2655"] = {line = 9, file = "autozoom.ts"},["2656"] = {line = 9, file = "autozoom.ts"},["2657"] = {line = 10, file = "autozoom.ts"},["2658"] = {line = 10, file = "autozoom.ts"},["2659"] = {line = 10, file = "autozoom.ts"},["2660"] = {line = 10, file = "autozoom.ts"},["2661"] = {line = 12, file = "autozoom.ts"},["2662"] = {line = 16, file = "autozoom.ts"},["2663"] = {line = 16, file = "autozoom.ts"},["2664"] = {line = 16, file = "autozoom.ts"},["2665"] = {line = 31, file = "autozoom.ts"},["2666"] = {line = 31, file = "autozoom.ts"},["2667"] = {line = 31, file = "autozoom.ts"},["2668"] = {line = 17, file = "autozoom.ts"},["2669"] = {line = 18, file = "autozoom.ts"},["2670"] = {line = 19, file = "autozoom.ts"},["2671"] = {line = 20, file = "autozoom.ts"},["2672"] = {line = 23, file = "autozoom.ts"},["2673"] = {line = 24, file = "autozoom.ts"},["2674"] = {line = 25, file = "autozoom.ts"},["2675"] = {line = 26, file = "autozoom.ts"},["2676"] = {line = 29, file = "autozoom.ts"},["2677"] = {line = 31, file = "autozoom.ts"},["2678"] = {line = 34, file = "autozoom.ts"},["2679"] = {line = 35, file = "autozoom.ts"},["2680"] = {line = 36, file = "autozoom.ts"},["2681"] = {line = 36, file = "autozoom.ts"},["2683"] = {line = 37, file = "autozoom.ts"},["2684"] = {line = 38, file = "autozoom.ts"},["2685"] = {line = 39, file = "autozoom.ts"},["2686"] = {line = 34, file = "autozoom.ts"},["2687"] = {line = 42, file = "autozoom.ts"},["2688"] = {line = 43, file = "autozoom.ts"},["2689"] = {line = 44, file = "autozoom.ts"},["2690"] = {line = 44, file = "autozoom.ts"},["2692"] = {line = 45, file = "autozoom.ts"},["2693"] = {line = 45, file = "autozoom.ts"},["2694"] = {line = 45, file = "autozoom.ts"},["2695"] = {line = 45, file = "autozoom.ts"},["2696"] = {line = 45, file = "autozoom.ts"},["2697"] = {line = 45, file = "autozoom.ts"},["2698"] = {line = 45, file = "autozoom.ts"},["2699"] = {line = 46, file = "autozoom.ts"},["2700"] = {line = 47, file = "autozoom.ts"},["2701"] = {line = 48, file = "autozoom.ts"},["2702"] = {line = 49, file = "autozoom.ts"},["2703"] = {line = 50, file = "autozoom.ts"},["2704"] = {line = 51, file = "autozoom.ts"},["2705"] = {line = 42, file = "autozoom.ts"},["2706"] = {line = 54, file = "autozoom.ts"},["2707"] = {line = 55, file = "autozoom.ts"},["2710"] = {line = 56, file = "autozoom.ts"},["2711"] = {line = 57, file = "autozoom.ts"},["2712"] = {line = 57, file = "autozoom.ts"},["2713"] = {line = 57, file = "autozoom.ts"},["2714"] = {line = 57, file = "autozoom.ts"},["2715"] = {line = 58, file = "autozoom.ts"},["2716"] = {line = 59, file = "autozoom.ts"},["2717"] = {line = 60, file = "autozoom.ts"},["2718"] = {line = 60, file = "autozoom.ts"},["2719"] = {line = 60, file = "autozoom.ts"},["2721"] = {line = 60, file = "autozoom.ts"},["2722"] = {line = 61, file = "autozoom.ts"},["2723"] = {line = 61, file = "autozoom.ts"},["2724"] = {line = 61, file = "autozoom.ts"},["2726"] = {line = 61, file = "autozoom.ts"},["2727"] = {line = 58, file = "autozoom.ts"},["2728"] = {line = 63, file = "autozoom.ts"},["2729"] = {line = 54, file = "autozoom.ts"},["2730"] = {line = 66, file = "autozoom.ts"},["2731"] = {line = 67, file = "autozoom.ts"},["2732"] = {line = 68, file = "autozoom.ts"},["2735"] = {line = 69, file = "autozoom.ts"},["2736"] = {line = 70, file = "autozoom.ts"},["2737"] = {line = 71, file = "autozoom.ts"},["2738"] = {line = 72, file = "autozoom.ts"},["2739"] = {line = 72, file = "autozoom.ts"},["2741"] = {line = 73, file = "autozoom.ts"},["2742"] = {line = 74, file = "autozoom.ts"},["2744"] = {line = 75, file = "autozoom.ts"},["2745"] = {line = 76, file = "autozoom.ts"},["2746"] = {line = 76, file = "autozoom.ts"},["2750"] = {line = 80, file = "autozoom.ts"},["2751"] = {line = 80, file = "autozoom.ts"},["2752"] = {line = 80, file = "autozoom.ts"},["2753"] = {line = 80, file = "autozoom.ts"},["2756"] = {line = 78, file = "autozoom.ts"},["2762"] = {line = 82, file = "autozoom.ts"},["2766"] = {line = 84, file = "autozoom.ts"},["2767"] = {line = 66, file = "autozoom.ts"},["2768"] = {line = 87, file = "autozoom.ts"},["2769"] = {line = 88, file = "autozoom.ts"},["2770"] = {line = 88, file = "autozoom.ts"},["2772"] = {line = 88, file = "autozoom.ts"},["2774"] = {line = 87, file = "autozoom.ts"},["2775"] = {line = 92, file = "autozoom.ts"},["2776"] = {line = 93, file = "autozoom.ts"},["2777"] = {line = 92, file = "autozoom.ts"},["2778"] = {line = 96, file = "autozoom.ts"},["2779"] = {line = 97, file = "autozoom.ts"},["2780"] = {line = 97, file = "autozoom.ts"},["2781"] = {line = 97, file = "autozoom.ts"},["2782"] = {line = 97, file = "autozoom.ts"},["2783"] = {line = 98, file = "autozoom.ts"},["2784"] = {line = 98, file = "autozoom.ts"},["2786"] = {line = 99, file = "autozoom.ts"},["2787"] = {line = 96, file = "autozoom.ts"},["2788"] = {line = 102, file = "autozoom.ts"},["2789"] = {line = 103, file = "autozoom.ts"},["2790"] = {line = 103, file = "autozoom.ts"},["2791"] = {line = 103, file = "autozoom.ts"},["2792"] = {line = 103, file = "autozoom.ts"},["2793"] = {line = 102, file = "autozoom.ts"},["2794"] = {line = 106, file = "autozoom.ts"},["2795"] = {line = 107, file = "autozoom.ts"},["2796"] = {line = 106, file = "autozoom.ts"},["2797"] = {line = 110, file = "autozoom.ts"},["2798"] = {line = 111, file = "autozoom.ts"},["2799"] = {line = 112, file = "autozoom.ts"},["2800"] = {line = 113, file = "autozoom.ts"},["2801"] = {line = 114, file = "autozoom.ts"},["2803"] = {line = 110, file = "autozoom.ts"},["2804"] = {line = 119, file = "autozoom.ts"},["2805"] = {line = 120, file = "autozoom.ts"},["2806"] = {line = 121, file = "autozoom.ts"},["2807"] = {line = 122, file = "autozoom.ts"},["2810"] = {line = 125, file = "autozoom.ts"},["2811"] = {line = 126, file = "autozoom.ts"},["2813"] = {line = 128, file = "autozoom.ts"},["2815"] = {line = 130, file = "autozoom.ts"},["2816"] = {line = 119, file = "autozoom.ts"},["2817"] = {line = 133, file = "autozoom.ts"},["2818"] = {line = 134, file = "autozoom.ts"},["2819"] = {line = 135, file = "autozoom.ts"},["2820"] = {line = 136, file = "autozoom.ts"},["2823"] = {line = 137, file = "autozoom.ts"},["2824"] = {line = 138, file = "autozoom.ts"},["2825"] = {line = 139, file = "autozoom.ts"},["2826"] = {line = 139, file = "autozoom.ts"},["2828"] = {line = 140, file = "autozoom.ts"},["2829"] = {line = 141, file = "autozoom.ts"},["2830"] = {line = 142, file = "autozoom.ts"},["2831"] = {line = 142, file = "autozoom.ts"},["2833"] = {line = 143, file = "autozoom.ts"},["2834"] = {line = 144, file = "autozoom.ts"},["2835"] = {line = 134, file = "autozoom.ts"},["2836"] = {line = 133, file = "autozoom.ts"},["2837"] = {line = 148, file = "autozoom.ts"},["2838"] = {line = 149, file = "autozoom.ts"},["2839"] = {line = 150, file = "autozoom.ts"},["2840"] = {line = 151, file = "autozoom.ts"},["2843"] = {line = 154, file = "autozoom.ts"},["2844"] = {line = 155, file = "autozoom.ts"},["2845"] = {line = 156, file = "autozoom.ts"},["2846"] = {line = 157, file = "autozoom.ts"},["2847"] = {line = 157, file = "autozoom.ts"},["2848"] = {line = 157, file = "autozoom.ts"},["2849"] = {line = 157, file = "autozoom.ts"},["2850"] = {line = 158, file = "autozoom.ts"},["2853"] = {line = 159, file = "autozoom.ts"},["2854"] = {line = 159, file = "autozoom.ts"},["2855"] = {line = 159, file = "autozoom.ts"},["2856"] = {line = 159, file = "autozoom.ts"},["2857"] = {line = 159, file = "autozoom.ts"},["2858"] = {line = 160, file = "autozoom.ts"},["2859"] = {line = 161, file = "autozoom.ts"},["2861"] = {line = 163, file = "autozoom.ts"},["2862"] = {line = 164, file = "autozoom.ts"},["2863"] = {line = 165, file = "autozoom.ts"},["2866"] = {line = 168, file = "autozoom.ts"},["2868"] = {line = 170, file = "autozoom.ts"},["2869"] = {line = 171, file = "autozoom.ts"},["2870"] = {line = 154, file = "autozoom.ts"},["2871"] = {line = 148, file = "autozoom.ts"},["2872"] = {line = 176, file = "autozoom.ts"},["2873"] = {line = 177, file = "autozoom.ts"},["2874"] = {line = 178, file = "autozoom.ts"},["2875"] = {line = 179, file = "autozoom.ts"},["2876"] = {line = 180, file = "autozoom.ts"},["2877"] = {line = 181, file = "autozoom.ts"},["2880"] = {line = 184, file = "autozoom.ts"},["2881"] = {line = 185, file = "autozoom.ts"},["2882"] = {line = 185, file = "autozoom.ts"},["2884"] = {line = 176, file = "autozoom.ts"},["2885"] = {line = 188, file = "autozoom.ts"},["2886"] = {line = 190, file = "autozoom.ts"},["2887"] = {line = 188, file = "autozoom.ts"},["2888"] = {line = 193, file = "autozoom.ts"},["2889"] = {line = 194, file = "autozoom.ts"},["2890"] = {line = 195, file = "autozoom.ts"},["2891"] = {line = 196, file = "autozoom.ts"},["2892"] = {line = 197, file = "autozoom.ts"},["2895"] = {line = 201, file = "autozoom.ts"},["2896"] = {line = 201, file = "autozoom.ts"},["2897"] = {line = 201, file = "autozoom.ts"},["2898"] = {line = 201, file = "autozoom.ts"},["2901"] = {line = 199, file = "autozoom.ts"},["2908"] = {line = 204, file = "autozoom.ts"},["2909"] = {line = 193, file = "autozoom.ts"},["2910"] = {line = 207, file = "autozoom.ts"},["2911"] = {line = 208, file = "autozoom.ts"},["2912"] = {line = 209, file = "autozoom.ts"},["2915"] = {line = 212, file = "autozoom.ts"},["2916"] = {line = 213, file = "autozoom.ts"},["2919"] = {line = 216, file = "autozoom.ts"},["2920"] = {line = 217, file = "autozoom.ts"},["2921"] = {line = 218, file = "autozoom.ts"},["2922"] = {line = 219, file = "autozoom.ts"},["2923"] = {line = 222, file = "autozoom.ts"},["2924"] = {line = 207, file = "autozoom.ts"},["2925"] = {line = 225, file = "autozoom.ts"},["2926"] = {line = 226, file = "autozoom.ts"},["2929"] = {line = 227, file = "autozoom.ts"},["2930"] = {line = 228, file = "autozoom.ts"},["2933"] = {line = 231, file = "autozoom.ts"},["2934"] = {line = 232, file = "autozoom.ts"},["2937"] = {line = 233, file = "autozoom.ts"},["2938"] = {line = 234, file = "autozoom.ts"},["2939"] = {line = 225, file = "autozoom.ts"},["2940"] = {line = 237, file = "autozoom.ts"},["2941"] = {line = 238, file = "autozoom.ts"},["2942"] = {line = 239, file = "autozoom.ts"},["2943"] = {line = 239, file = "autozoom.ts"},["2944"] = {line = 239, file = "autozoom.ts"},["2945"] = {line = 239, file = "autozoom.ts"},["2946"] = {line = 240, file = "autozoom.ts"},["2947"] = {line = 241, file = "autozoom.ts"},["2950"] = {line = 244, file = "autozoom.ts"},["2951"] = {line = 245, file = "autozoom.ts"},["2952"] = {line = 245, file = "autozoom.ts"},["2953"] = {line = 245, file = "autozoom.ts"},["2955"] = {line = 245, file = "autozoom.ts"},["2957"] = {line = 245, file = "autozoom.ts"},["2958"] = {line = 246, file = "autozoom.ts"},["2959"] = {line = 247, file = "autozoom.ts"},["2962"] = {line = 250, file = "autozoom.ts"},["2963"] = {line = 250, file = "autozoom.ts"},["2964"] = {line = 250, file = "autozoom.ts"},["2965"] = {line = 250, file = "autozoom.ts"},["2966"] = {line = 250, file = "autozoom.ts"},["2967"] = {line = 250, file = "autozoom.ts"},["2968"] = {line = 250, file = "autozoom.ts"},["2969"] = {line = 250, file = "autozoom.ts"},["2970"] = {line = 251, file = "autozoom.ts"},["2971"] = {line = 237, file = "autozoom.ts"},["2972"] = {line = 254, file = "autozoom.ts"},["2973"] = {line = 255, file = "autozoom.ts"},["2974"] = {line = 256, file = "autozoom.ts"},["2975"] = {line = 257, file = "autozoom.ts"},["2976"] = {line = 254, file = "autozoom.ts"},["2977"] = {line = 260, file = "autozoom.ts"},["2978"] = {line = 261, file = "autozoom.ts"},["2979"] = {line = 262, file = "autozoom.ts"},["2980"] = {line = 263, file = "autozoom.ts"},["2981"] = {line = 263, file = "autozoom.ts"},["2982"] = {line = 263, file = "autozoom.ts"},["2983"] = {line = 263, file = "autozoom.ts"},["2984"] = {line = 263, file = "autozoom.ts"},["2985"] = {line = 264, file = "autozoom.ts"},["2986"] = {line = 265, file = "autozoom.ts"},["2987"] = {line = 266, file = "autozoom.ts"},["2988"] = {line = 266, file = "autozoom.ts"},["2989"] = {line = 266, file = "autozoom.ts"},["2990"] = {line = 266, file = "autozoom.ts"},["2991"] = {line = 267, file = "autozoom.ts"},["2992"] = {line = 268, file = "autozoom.ts"},["2993"] = {line = 268, file = "autozoom.ts"},["2994"] = {line = 268, file = "autozoom.ts"},["2995"] = {line = 268, file = "autozoom.ts"},["2997"] = {line = 270, file = "autozoom.ts"},["2998"] = {line = 271, file = "autozoom.ts"},["2999"] = {line = 271, file = "autozoom.ts"},["3000"] = {line = 271, file = "autozoom.ts"},["3001"] = {line = 271, file = "autozoom.ts"},["3002"] = {line = 272, file = "autozoom.ts"},["3003"] = {line = 272, file = "autozoom.ts"},["3004"] = {line = 272, file = "autozoom.ts"},["3005"] = {line = 272, file = "autozoom.ts"},["3006"] = {line = 270, file = "autozoom.ts"},["3007"] = {line = 274, file = "autozoom.ts"},["3008"] = {line = 275, file = "autozoom.ts"},["3009"] = {line = 260, file = "autozoom.ts"},["3010"] = {line = 278, file = "autozoom.ts"},["3011"] = {line = 279, file = "autozoom.ts"},["3014"] = {line = 280, file = "autozoom.ts"},["3015"] = {line = 281, file = "autozoom.ts"},["3016"] = {line = 282, file = "autozoom.ts"},["3019"] = {line = 283, file = "autozoom.ts"},["3020"] = {line = 284, file = "autozoom.ts"},["3021"] = {line = 284, file = "autozoom.ts"},["3023"] = {line = 285, file = "autozoom.ts"},["3025"] = {line = 278, file = "autozoom.ts"},["3026"] = {line = 288, file = "autozoom.ts"},["3027"] = {line = 289, file = "autozoom.ts"},["3028"] = {line = 290, file = "autozoom.ts"},["3029"] = {line = 291, file = "autozoom.ts"},["3030"] = {line = 292, file = "autozoom.ts"},["3031"] = {line = 292, file = "autozoom.ts"},["3032"] = {line = 292, file = "autozoom.ts"},["3033"] = {line = 292, file = "autozoom.ts"},["3034"] = {line = 292, file = "autozoom.ts"},["3035"] = {line = 293, file = "autozoom.ts"},["3036"] = {line = 294, file = "autozoom.ts"},["3037"] = {line = 294, file = "autozoom.ts"},["3038"] = {line = 294, file = "autozoom.ts"},["3039"] = {line = 294, file = "autozoom.ts"},["3040"] = {line = 294, file = "autozoom.ts"},["3041"] = {line = 295, file = "autozoom.ts"},["3042"] = {line = 296, file = "autozoom.ts"},["3043"] = {line = 296, file = "autozoom.ts"},["3044"] = {line = 293, file = "autozoom.ts"},["3046"] = {line = 299, file = "autozoom.ts"},["3047"] = {line = 300, file = "autozoom.ts"},["3048"] = {line = 300, file = "autozoom.ts"},["3049"] = {line = 300, file = "autozoom.ts"},["3052"] = {line = 301, file = "autozoom.ts"},["3053"] = {line = 301, file = "autozoom.ts"},["3054"] = {line = 301, file = "autozoom.ts"},["3056"] = {line = 301, file = "autozoom.ts"},["3057"] = {line = 301, file = "autozoom.ts"},["3058"] = {line = 301, file = "autozoom.ts"},["3059"] = {line = 301, file = "autozoom.ts"},["3061"] = {line = 301, file = "autozoom.ts"},["3062"] = {line = 302, file = "autozoom.ts"},["3063"] = {line = 303, file = "autozoom.ts"},["3064"] = {line = 303, file = "autozoom.ts"},["3065"] = {line = 303, file = "autozoom.ts"},["3066"] = {line = 303, file = "autozoom.ts"},["3067"] = {line = 303, file = "autozoom.ts"},["3068"] = {line = 303, file = "autozoom.ts"},["3069"] = {line = 303, file = "autozoom.ts"},["3070"] = {line = 303, file = "autozoom.ts"},["3071"] = {line = 304, file = "autozoom.ts"},["3072"] = {line = 304, file = "autozoom.ts"},["3073"] = {line = 304, file = "autozoom.ts"},["3074"] = {line = 302, file = "autozoom.ts"},["3075"] = {line = 288, file = "autozoom.ts"},["3076"] = {line = 309, file = "autozoom.ts"},["3077"] = {line = 310, file = "autozoom.ts"},["3078"] = {line = 309, file = "autozoom.ts"},["3079"] = {line = 313, file = "autozoom.ts"},["3080"] = {line = 314, file = "autozoom.ts"},["3081"] = {line = 314, file = "autozoom.ts"},["3082"] = {line = 314, file = "autozoom.ts"},["3083"] = {line = 314, file = "autozoom.ts"},["3084"] = {line = 313, file = "autozoom.ts"},["3085"] = {line = 317, file = "autozoom.ts"},["3086"] = {line = 318, file = "autozoom.ts"},["3087"] = {line = 318, file = "autozoom.ts"},["3088"] = {line = 318, file = "autozoom.ts"},["3089"] = {line = 318, file = "autozoom.ts"},["3090"] = {line = 319, file = "autozoom.ts"},["3091"] = {line = 319, file = "autozoom.ts"},["3092"] = {line = 319, file = "autozoom.ts"},["3093"] = {line = 319, file = "autozoom.ts"},["3094"] = {line = 320, file = "autozoom.ts"},["3095"] = {line = 320, file = "autozoom.ts"},["3096"] = {line = 320, file = "autozoom.ts"},["3097"] = {line = 320, file = "autozoom.ts"},["3098"] = {line = 320, file = "autozoom.ts"},["3099"] = {line = 320, file = "autozoom.ts"},["3100"] = {line = 320, file = "autozoom.ts"},["3101"] = {line = 320, file = "autozoom.ts"},["3103"] = {line = 321, file = "autozoom.ts"},["3104"] = {line = 322, file = "autozoom.ts"},["3105"] = {line = 323, file = "autozoom.ts"},["3106"] = {line = 317, file = "autozoom.ts"},["3107"] = {line = 326, file = "autozoom.ts"},["3108"] = {line = 327, file = "autozoom.ts"},["3109"] = {line = 328, file = "autozoom.ts"},["3110"] = {line = 329, file = "autozoom.ts"},["3111"] = {line = 329, file = "autozoom.ts"},["3112"] = {line = 329, file = "autozoom.ts"},["3113"] = {line = 329, file = "autozoom.ts"},["3114"] = {line = 329, file = "autozoom.ts"},["3116"] = {line = 330, file = "autozoom.ts"},["3117"] = {line = 326, file = "autozoom.ts"},["3118"] = {line = 333, file = "autozoom.ts"},["3119"] = {line = 334, file = "autozoom.ts"},["3120"] = {line = 333, file = "autozoom.ts"},["3121"] = {line = 337, file = "autozoom.ts"},["3122"] = {line = 338, file = "autozoom.ts"},["3123"] = {line = 338, file = "autozoom.ts"},["3125"] = {line = 338, file = "autozoom.ts"},["3127"] = {line = 337, file = "autozoom.ts"},["3128"] = {line = 341, file = "autozoom.ts"},["3129"] = {line = 342, file = "autozoom.ts"},["3130"] = {line = 342, file = "autozoom.ts"},["3131"] = {line = 342, file = "autozoom.ts"},["3132"] = {line = 342, file = "autozoom.ts"},["3133"] = {line = 343, file = "autozoom.ts"},["3134"] = {line = 341, file = "autozoom.ts"},["3135"] = {line = 346, file = "autozoom.ts"},["3136"] = {line = 347, file = "autozoom.ts"},["3137"] = {line = 348, file = "autozoom.ts"},["3138"] = {line = 346, file = "autozoom.ts"},["3139"] = {line = 351, file = "autozoom.ts"},["3140"] = {line = 352, file = "autozoom.ts"},["3143"] = {line = 353, file = "autozoom.ts"},["3144"] = {line = 354, file = "autozoom.ts"},["3145"] = {line = 351, file = "autozoom.ts"},["3146"] = {line = 358, file = "autozoom.ts"},["3147"] = {line = 359, file = "autozoom.ts"},["3148"] = {line = 358, file = "autozoom.ts"},["3156"] = {line = 2, file = "main.ts"},["3157"] = {line = 2, file = "main.ts"},["3158"] = {line = 3, file = "main.ts"},["3159"] = {line = 3, file = "main.ts"},["3160"] = {line = 7, file = "main.ts"},["3161"] = {line = 8, file = "main.ts"},["3164"] = {line = 12, file = "main.ts"},["3167"] = {line = 10, file = "main.ts"},["3174"] = {line = 15, file = "main.ts"},["3175"] = {line = 15, file = "main.ts"},["3176"] = {line = 15, file = "main.ts"},["3177"] = {line = 15, file = "main.ts"},["3178"] = {line = 15, file = "main.ts"},["3179"] = {line = 16, file = "main.ts"},["3180"] = {line = 16, file = "main.ts"},["3181"] = {line = 16, file = "main.ts"},["3182"] = {line = 16, file = "main.ts"},["3183"] = {line = 16, file = "main.ts"},["3184"] = {line = 17, file = "main.ts"},["3185"] = {line = 18, file = "main.ts"},["3186"] = {line = 19, file = "main.ts"},["3187"] = {line = 7, file = "main.ts"},["3188"] = {line = 23, file = "main.ts"},["3194"] = {line = 3, file = "exports.ts"},["3195"] = {line = 4, file = "exports.ts"},["3196"] = {line = 5, file = "exports.ts"},["3197"] = {line = 6, file = "exports.ts"},["3198"] = {line = 7, file = "exports.ts"},["3199"] = {line = 8, file = "exports.ts"},["3200"] = {line = 9, file = "exports.ts"},["3201"] = {line = 10, file = "exports.ts"},["3202"] = {line = 11, file = "exports.ts"},["3203"] = {line = 12, file = "exports.ts"},["3204"] = {line = 13, file = "exports.ts"},["3205"] = {line = 14, file = "exports.ts"},["3206"] = {line = 15, file = "exports.ts"},["3207"] = {line = 16, file = "exports.ts"},["3208"] = {line = 18, file = "exports.ts"},["3209"] = {line = 19, file = "exports.ts"},["3210"] = {line = 19, file = "exports.ts"},["3211"] = {line = 19, file = "exports.ts"},["3212"] = {line = 19, file = "exports.ts"},["3213"] = {line = 19, file = "exports.ts"},["3214"] = {line = 19, file = "exports.ts"},["3215"] = {line = 19, file = "exports.ts"},["3216"] = {line = 19, file = "exports.ts"},["3217"] = {line = 19, file = "exports.ts"},["3218"] = {line = 19, file = "exports.ts"},["3219"] = {line = 19, file = "exports.ts"},["3220"] = {line = 19, file = "exports.ts"},["3221"] = {line = 19, file = "exports.ts"},["3222"] = {line = 19, file = "exports.ts"}});
return require("src.main", ...)
