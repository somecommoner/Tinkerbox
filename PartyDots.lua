-- KinFolk Tweaks: no KinFolk dot for guildmates in your group, on the minimap
-- or the world map. The game already shows party and raid members on both,
-- so KinFolk's dot on top is a double. KinFolk's zone count markers on the
-- world map are left alone.
--
-- KinFolk keeps its code private, but it draws dots through the shared
-- HereBeDragons-Pins library with the ref "KinFolkGuildMap", and sets
-- frame.kinfolkKey (lower-case "first last") on each dot first. This wraps
-- those library calls; KinFolk's own files are untouched. If any of that
-- changes, the tweak does nothing and says so once.

local _, ns = ...

local REF = "KinFolkGuildMap"

-- The two maps KinFolk draws dots on, and the library calls for each.
local KINDS = {
    { add = "AddMinimapIconMap", remove = "RemoveMinimapIcon" },
    { add = "AddWorldMapIconMap", remove = "RemoveWorldMapIcon" },
}

local function Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99KinFolk Tweaks|r: " .. message)
end

-- KinFolk's key: realm dropped, spaces tidied, lower case.
local function Key(name)
    if type(name) ~= "string" or (issecretvalue and issecretvalue(name)) then
        return nil
    end
    name = name:gsub("%-.*$", ""):gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s+", " ")
    if name == "" or name == UNKNOWNOBJECT then
        return nil
    end
    return name:lower()
end
ns.Key = Key

local grouped = {}      -- key -> true for everyone in your party or raid

local function InGroup(icon)
    return icon.kinfolkKey ~= nil and grouped[icon.kinfolkKey] == true
end

local pins

-- Wraps one map's add and remove calls. Each kind keeps its own lists:
-- shown = KinFolk dot -> the arguments it was drawn with,
-- hidden = dots this tweak is holding back.
local function WrapKind(kind)
    local add, remove = pins[kind.add], pins[kind.remove]
    kind.original_add, kind.original_remove = add, remove
    kind.shown, kind.hidden = {}, {}

    pins[kind.add] = function(self, ref, icon, ...)
        -- Only KinFolk's player dots carry a kinfolkKey; zone markers don't.
        if ref == REF and type(icon) == "table" and icon.kinfolkKey ~= nil then
            local new = kind.shown[icon] == nil
            kind.shown[icon] = { n = select("#", ...), ... }
            if new and kind.changed then
                kind.changed()
            end
            if InGroup(icon) then
                kind.hidden[icon] = true
                return remove(self, ref, icon)
            end
            kind.hidden[icon] = nil
        end
        return add(self, ref, icon, ...)
    end

    pins[kind.remove] = function(self, ref, icon, ...)
        -- KinFolk took the dot away (offline, stale, map turned off).
        if ref == REF and icon and kind.shown[icon] then
            kind.shown[icon], kind.hidden[icon] = nil, nil
            if kind.changed then
                kind.changed()
            end
        end
        return remove(self, ref, icon, ...)
    end
end

-- For OneForAllDots.lua: does KinFolk have a world map dot for this name?
-- (Counted even while held back above for a group member.)
local world = KINDS[2]
function ns.KinFolkWorldDot(name)
    local key, shown = Key(name), world.shown
    if not key or not shown then
        return false
    end
    for icon in pairs(shown) do
        if icon.kinfolkKey == key then
            return true
        end
    end
    return false
end
-- OneForAllDots.lua sets this to hear when a world map dot comes or goes.
function ns.OnKinFolkWorldDotsChanged(fn)
    world.changed = fn
end

local function Wrap()
    pins = LibStub and LibStub("HereBeDragons-Pins-2.0", true)
    if type(pins) ~= "table" then
        Print("KinFolk's map library looks different, so party dots are left as they are.")
        return false
    end
    for _, kind in ipairs(KINDS) do
        if type(pins[kind.add]) ~= "function" or type(pins[kind.remove]) ~= "function" then
            Print("KinFolk's map library looks different, so party dots are left as they are.")
            return false
        end
    end
    for _, kind in ipairs(KINDS) do
        WrapKind(kind)
    end
    return true
end

local function RefreshGroup()
    wipe(grouped)
    local prefix, count = "party", GetNumSubgroupMembers()
    if IsInRaid() then
        prefix, count = "raid", GetNumGroupMembers()
    end
    for i = 1, count do
        local key = Key(GetUnitName(prefix .. i, true))
        if key then
            grouped[key] = true
        end
    end
    -- Hide dots for people who joined; bring back dots for people who left.
    for _, kind in ipairs(KINDS) do
        for icon, args in pairs(kind.shown) do
            if InGroup(icon) then
                if not kind.hidden[icon] then
                    kind.hidden[icon] = true
                    kind.original_remove(pins, REF, icon)
                end
            elseif kind.hidden[icon] then
                kind.hidden[icon] = nil
                kind.original_add(pins, REF, icon, unpack(args, 1, args.n))
            end
        end
    end
end

-- Wrapped at login, after every add-on has loaded, so a newer copy of the
-- library from another add-on cannot replace the wrapper afterwards.
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        if not Wrap() then
            return
        end
        self:RegisterEvent("GROUP_ROSTER_UPDATE")
        self:RegisterEvent("PLAYER_ENTERING_WORLD")
        self:RegisterEvent("UNIT_NAME_UPDATE")
    end
    RefreshGroup()
end)
