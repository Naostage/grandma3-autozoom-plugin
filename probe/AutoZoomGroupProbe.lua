-- AutoZoom — group probe v0.3: what a Group object's SelectionData / Selection hold (to read its
-- fixtures without touching the selection), and the attribute names of an XYZ preset.
--
-- SETUP: a Group holding a few XYZ fixtures and an XYZ preset (pool.number, e.g. 2.37). Nothing is
-- selected or programmed. Send back every line starting with [AZP].

local function P(s) Printf("[AZP] " .. s) end

local function run(label, fn)
    local ok, err = pcall(fn)
    if not ok then P(label .. ": <error> " .. tostring(err)) end
end

local function field(o, k)
    local ok, v = pcall(function() return o[k] end)
    if ok then return v end
    return "<err>"
end

local function show(v)
    if type(v) ~= "userdata" then return tostring(v) .. " (" .. type(v) .. ")" end
    local ok, cls = pcall(function() return v:GetClass() end)
    local name = field(v, "name")
    return "<" .. (ok and tostring(cls) or "userdata") .. " " .. tostring(name) .. " fid " .. tostring(field(v, "fid")) .. ">"
end

-- Prints a table's entries (max 12 per level) down to `depth` levels.
local function dump(label, t, depth, indent)
    indent = indent or ""
    if type(t) ~= "table" then P(label .. ": " .. indent .. show(t)) return end
    local n = 0
    for k, v in pairs(t) do
        n = n + 1
        if n > 12 then P(label .. ": " .. indent .. "...") break end
        P(label .. ": " .. indent .. "[" .. tostring(k) .. "] = " .. (type(v) == "table" and "table" or show(v)))
        if type(v) == "table" and depth > 1 then dump(label, v, depth - 1, indent .. "    ") end
    end
    if n == 0 then P(label .. ": " .. indent .. "(empty table)") end
end

return function()
    P("================ AutoZoomGroupProbe v0.3 ================")
    local box = MessageBox({
        title = "AutoZoom group probe v0.3",
        commands = { { value = 1, name = "Run" }, { value = 0, name = "Cancel" } },
        inputs = { { name = "Group", value = "10" }, { name = "XYZ preset", value = "2.37" } },
    })
    if not box or box.result ~= 1 then P("cancelled") return end
    local gno = tonumber(box.inputs["Group"])
    local preset = box.inputs["XYZ preset"]
    P("inputs: group " .. tostring(gno) .. ", preset " .. tostring(preset))
    local g = DataPool().Groups[gno]
    if not g then P("group not found") return end

    run("S1", function() dump("S1 SelectionData", field(g, "SelectionData"), 3) end)
    run("S2", function() dump("S2 Selection", field(g, "Selection"), 3) end)
    run("S3", function() P("S3: Count() = " .. tostring(g:Count())) end)
    run("S4", function()
        local sd = field(g, "SelectionData")
        if type(sd) == "table" and type(sd[1]) == "userdata" then
            local s = sd[1]
            P("S4: first entry " .. show(s) .. ", no " .. tostring(field(s, "no")) .. ", id " .. tostring(field(s, "id")) ..
                ", sub " .. tostring(field(s, "sub")))
        end
    end)

    run("X1", function()
        local p = ObjectList("Preset " .. tostring(preset))
        p = p and p[1]
        if not p then P("X1: preset not found") return end
        local d = GetPresetData(p, false, true)
        for fid, attrs in pairs(d.by_fixtures or {}) do
            local names = {}
            for a in pairs(attrs) do names[#names + 1] = tostring(a) end
            table.sort(names)
            P("X1: fixture " .. tostring(fid) .. ": " .. table.concat(names, ", "))
            break
        end
    end)
    P("================ done ================")
end
