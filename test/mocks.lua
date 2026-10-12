-- Minimal grandMA3 globals for the AutoZoom plugin.
local M = {}

local function node(children, props)
    local n = props or {}
    n.children = children or {}
    n.count = #n.children
    function n:Children() return self.children end
    return n
end

local function sequence(name)
    return {
        name = name,
        GetFader = function(self) return self.fader or 0 end,
        SetFader = function(self, args) self.fader = args.value end,
    }
end

-- Zoom 5..50 degrees, no iris
local spotType = {
    id = 1,
    Name = "Spot",
    DMXModes = {{
        Name = "Mode 1",
        XYZ = true,
        DMXChannels = {
            node({node({node({}, {physicalFrom = 5, physicalTo = 50})}, {attribute = "Zoom"})}),
        },
    }},
}

function M.reset()
    M.printed = {}
    M.timers = {}
    M.sequences = node({})
    M.trackers = node({})
    M.patchFixtures = node({})

    _G.Printf = function(msg) M.printed[#M.printed + 1] = msg end
    _G.Cmd = function() end
    _G.CmdIndirect = function() end
    _G.CmdIndirectWait = function(cmd)
        local name = cmd:match("Sequence '(.-)'")
        if name and not M.sequence(name) then M.addSequence(name) end
    end
    _G.Timer = function(fn, period, count)
        M.timers[#M.timers + 1] = {fn = fn, period = period, count = count}
    end
    _G.ShowData = function()
        return {
            DataPools = node({node({node({}, {GetClass = function() return "Macros" end}), M.sequences})}),
            PSNProtocol = node({M.trackers}),
        }
    end
    M.sequences.GetClass = function() return "Sequences" end
    _G.Patch = function()
        return {
            FixtureTypes = node({spotType}),
            Stages = node({node({}, {Fixtures = M.patchFixtures})}),
        }
    end
    _G.AZ = nil
end

function M.addSequence(name)
    local seq = sequence(name)
    table.insert(M.sequences.children, seq)
    return seq
end

function M.sequence(name)
    for _, seq in ipairs(M.sequences.children) do
        if seq.name == name then return seq end
    end
end

function M.addFixture(fid, x, y, z)
    table.insert(M.patchFixtures.children, {
        IDType = "Fixture", fid = fid, Name = "Spot " .. fid, name = "Spot " .. fid,
        FixtureType = {Name = "Spot"}, POSX = x, POSY = y, POSZ = z,
    })
    M.patchFixtures.count = #M.patchFixtures.children
end

function M.addMarker(fid, cid)
    table.insert(M.patchFixtures.children, {IDType = "MArker", fid = fid, cid = cid, name = "Marker " .. fid})
    M.patchFixtures.count = #M.patchFixtures.children
end

function M.setTracker(markerId, x, y, z)
    for _, tracker in ipairs(M.trackers.children) do
        if tracker.MARKERID == markerId then
            tracker.POSITIONX, tracker.POSITIONY, tracker.POSITIONZ = x, y, z
            return
        end
    end
    table.insert(M.trackers.children, {MARKERID = markerId, POSITIONX = x, POSITIONY = y, POSITIONZ = z})
end

-- Delivers one callback from every registered timer
function M.tick()
    for _, timer in ipairs(M.timers) do timer.fn() end
end

return M
