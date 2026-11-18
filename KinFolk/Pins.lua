-- Tinkerbox, KinFolk: shared helper, not a section (no switch of its own).
-- Keeps track of KinFolk's guildmate dots, so sections can hold some back
-- (filters, KinFolk/PartyDots.lua) or ask who has one (HasWorldDot,
-- OneForAll/GuildDots.lua).
--
-- KinFolk keeps its code private, but it draws dots through the shared
-- HereBeDragons-Pins library with the ref "KinFolkGuildMap", and sets
-- frame.kinfolkKey (lower-case "first last") on each dot first. This wraps
-- those library calls; KinFolk's own files are untouched. Zone count markers
-- have no kinfolkKey and are passed straight through.

local _, ns = ...

if not ns.Loaded("KinFolk") then
    return
end

local REF = "KinFolkGuildMap"
local LOOKS_DIFFERENT = "KinFolk's map library looks different"

local Pins = {}
ns.KinFolkPins = Pins

-- The two maps KinFolk draws dots on. For each: shown = dot -> the
-- arguments KinFolk drew it with; hidden = dots a filter is holding back.
local KINDS = {
    minimap = { add = "AddMinimapIconMap", remove = "RemoveMinimapIcon", shown = {}, hidden = {} },
    world = { add = "AddWorldMapIconMap", remove = "RemoveWorldMapIcon", shown = {}, hidden = {} },
}

local lib               -- HereBeDragons-Pins, once wrapped
local failed            -- why wrapping didn't work
local filters = {}      -- fn(dot, kindName) -> true to hold the dot back
local listeners = {}    -- fn(kindName) when a dot comes or goes

-- KinFolk's key: realm dropped, spaces tidied, lower case.
function Pins.Key(name)
    if type(name) ~= "string" or (issecretvalue and issecretvalue(name)) then
        return nil
    end
    name = name:gsub("%-.*$", ""):gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s+", " ")
    if name == "" or name == UNKNOWNOBJECT then
        return nil
    end
    return name:lower()
end

local function HeldBack(dot, kindName)
    for _, filter in ipairs(filters) do
        if filter(dot, kindName) then
            return true
        end
    end
    return false
end

local function Changed(kindName)
    for _, fn in ipairs(listeners) do
        pcall(fn, kindName)
    end
end

local function WrapKind(kindName, kind)
    local add, remove = lib[kind.add], lib[kind.remove]
    kind.original_add, kind.original_remove = add, remove

    lib[kind.add] = function(self, ref, dot, ...)
        if ref == REF and type(dot) == "table" and dot.kinfolkKey ~= nil then
            local new = kind.shown[dot] == nil
            kind.shown[dot] = { n = select("#", ...), ... }
            if new then
                Changed(kindName)
            end
            if HeldBack(dot, kindName) then
                kind.hidden[dot] = true
                return remove(self, ref, dot)
            end
            kind.hidden[dot] = nil
        end
        return add(self, ref, dot, ...)
    end

    lib[kind.remove] = function(self, ref, dot, ...)
        -- KinFolk took the dot away (offline, stale, map turned off).
        if ref == REF and dot and kind.shown[dot] then
            kind.shown[dot], kind.hidden[dot] = nil, nil
            Changed(kindName)
        end
        return remove(self, ref, dot, ...)
    end
end

-- Wraps the library, once. Modules call this at PLAYER_LOGIN, after every
-- add-on has loaded, so a newer copy of the library from another add-on
-- can't replace the wrapper afterwards. Returns true, or false and why.
function Pins.Start()
    if lib or failed then
        return lib ~= nil, failed
    end
    local found = LibStub and LibStub("HereBeDragons-Pins-2.0", true)
    if type(found) ~= "table" then
        failed = LOOKS_DIFFERENT
        return false, failed
    end
    for _, kind in pairs(KINDS) do
        if type(found[kind.add]) ~= "function" or type(found[kind.remove]) ~= "function" then
            failed = LOOKS_DIFFERENT
            return false, failed
        end
    end
    lib = found
    for kindName, kind in pairs(KINDS) do
        WrapKind(kindName, kind)
    end
    return true
end

function Pins.AddFilter(fn)
    filters[#filters + 1] = fn
end

function Pins.OnChange(fn)
    listeners[#listeners + 1] = fn
end

-- Asks the filters again for every dot KinFolk shows: holds back the ones
-- they now want hidden, and brings back the ones they let go.
function Pins.Refilter()
    if not lib then
        return
    end
    for kindName, kind in pairs(KINDS) do
        for dot, args in pairs(kind.shown) do
            if HeldBack(dot, kindName) then
                if not kind.hidden[dot] then
                    kind.hidden[dot] = true
                    kind.original_remove(lib, REF, dot)
                end
            elseif kind.hidden[dot] then
                kind.hidden[dot] = nil
                kind.original_add(lib, REF, dot, unpack(args, 1, args.n))
            end
        end
    end
end

-- Does KinFolk have a world map dot for this name? Counted even while a
-- filter holds it back.
function Pins.HasWorldDot(name)
    local key = Pins.Key(name)
    if not key then
        return false
    end
    for dot in pairs(KINDS.world.shown) do
        if dot.kinfolkKey == key then
            return true
        end
    end
    return false
end
