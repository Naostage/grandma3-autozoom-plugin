-- AutoZoom — group probe: how to read a Group's fixtures, program several fixtures at once,
-- read the attribute names of an XYZ preset, and list the theme colour names (tick colours).
--
-- SETUP: a Group holding a few XYZ fixtures, those fixtures' IDs, a marker CID and an XYZ preset.
-- The probe clears the programmer (ClearAll) twice. Send back the whole command line feedback
-- (every line starting with [AZP]).

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

local function children(o)
    local ok, list = pcall(function() return o:Children() end)
    if ok and type(list) == "table" then return list end
    return {}
end

local function fids(list)
    local out = {}
    for f in string.gmatch(list, "%d+") do out[#out + 1] = tonumber(f) end
    return out
end

local function selection()
    local out = {}
    local i = SelectionFirst()
    while i do
        local sf = GetSubfixture(i)
        out[#out + 1] = sf and tonumber(sf.fid) or ("?" .. tostring(i))
        i = SelectionNext(i)
    end
    return out
end

local function join(t) local s = {} for _, v in ipairs(t) do s[#s + 1] = tostring(v) end return table.concat(s, " + ") end

local function subIndex(fid)
    for i = 0, GetSubfixtureCount() do
        local sf = GetSubfixture(i)
        if sf and tonumber(sf.fid) == fid then return i end
    end
end

local function prog(ui)
    local ok, t = pcall(GetProgPhaser, ui, false)
    if not ok then return "<error> " .. tostring(t) end
    if type(t) ~= "table" then return tostring(t) end
    return tostring(t[1] and t[1].absolute) .. " (" .. #t .. " steps)"
end

return function()
    P("================ AutoZoomGroupProbe v0.2 ================")
    local box = MessageBox({
        title = "AutoZoom group probe",
        commands = { { value = 1, name = "Run" }, { value = 0, name = "Cancel" } },
        inputs = {
            { name = "Group", value = "1" },
            { name = "Fixtures", value = "101 + 102" },
            { name = "Marker CID", value = "1" },
            { name = "XYZ preset", value = "2.30" },
        },
    })
    if not box or box.result ~= 1 then P("cancelled") return end
    local gno = tonumber(box.inputs["Group"])
    local list = fids(box.inputs["Fixtures"] or "")
    local cid = box.inputs["Marker CID"]
    local preset = box.inputs["XYZ preset"]
    P("inputs: group " .. tostring(gno) .. ", fixtures " .. join(list) .. ", cid " .. tostring(cid) .. ", preset " .. tostring(preset))

    run("G0", function()
        local kids = children(DataPool().Groups)
        P("G0: " .. #kids .. " groups")
        for i, g in ipairs(kids) do
            if i > 10 then P("G0:   ...") break end
            P("G0:   no " .. tostring(field(g, "no")) .. ", name " .. tostring(field(g, "name")))
        end
    end)

    run("G1", function()
        local g = DataPool().Groups[gno]
        if not g then P("G1: DataPool().Groups[" .. tostring(gno) .. "] is nil") return end
        P("G1: name " .. tostring(field(g, "name")) .. ", class " .. tostring(field(g, "GetClass") and g:GetClass()))
        for _, k in ipairs({ "SelectionData", "Selection", "Fixtures", "Count", "no" }) do
            local v = field(g, k)
            P("G1: ." .. k .. " = " .. tostring(v) .. " (" .. type(v) .. ")")
        end
        local kids = children(g)
        P("G1: " .. #kids .. " children")
        for i, c in ipairs(kids) do
            P("G1:   child " .. i .. " class " .. tostring(c:GetClass()) .. ", name " .. tostring(field(c, "name")) ..
                ", fid " .. tostring(field(c, "fid")) .. ", no " .. tostring(field(c, "no")))
        end
    end)

    run("G2", function()
        local l = ObjectList("Group " .. tostring(gno))
        if not l then P("G2: ObjectList returned nil") return end
        P("G2: " .. #l .. " objects")
        for i, o in ipairs(l) do
            P("G2:   " .. i .. " class " .. tostring(o:GetClass()) .. ", fid " .. tostring(field(o, "fid")) ..
                ", name " .. tostring(field(o, "name")))
        end
    end)

    run("G3", function()
        local saved = selection()
        P("G3: saved selection " .. (#saved > 0 and join(saved) or "(empty)"))
        Cmd("SelFix Group " .. tostring(gno))
        P("G3: group selection " .. join(selection()))
        Cmd("ClearSelection")
        if #saved > 0 then Cmd("Fixture " .. join(saved)) end
        local back = selection()
        P("G3: restored " .. (#back > 0 and join(back) or "(empty)") .. " -> " ..
            (join(back) == join(saved) and "EXACT" or "DIFFERENT"))
    end)

    run("P1", function()
        Cmd("ClearAll")
        Cmd("Fixture " .. join(list))
        Cmd('Attribute "XYZ_MArker" At ' .. tostring(cid))
        Cmd('Attribute "XYZ_X" Thru "XYZ_Z" At Preset ' .. tostring(preset))
        local am, ax = GetAttributeIndex("XYZ_MArker"), GetAttributeIndex("XYZ_X")
        for _, f in ipairs(list) do
            local s = subIndex(f)
            if not s then
                P("P1: fixture " .. f .. " not found")
            else
                P("P1: fixture " .. f .. " marker " .. prog(GetUIChannelIndex(s, am)) .. ", X " .. prog(GetUIChannelIndex(s, ax)))
            end
        end
        Cmd("ClearAll")
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
    run("C1", function()
        local groups = Root().ColorTheme.ColorGroups
        for _, gname in ipairs({ "Global", "ProgLayer" }) do
            local names = {}
            for _, c in ipairs(children(groups[gname])) do names[#names + 1] = tostring(field(c, "name")) end
            P("C1: " .. gname .. ": " .. table.concat(names, ", "))
        end
    end)
    P("================ done ================")
end
