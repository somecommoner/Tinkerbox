-- KinFolk Tweaks: no KinFolk minimap dot for guildmates in your group.
-- The game already draws party and raid members on the minimap, so KinFolk's
-- dot on top is a double. World map dots are left alone.
--
-- KinFolk keeps its code private, but it draws dots through the shared
-- HereBeDragons-Pins library with the ref "KinFolkGuildMap", and sets
-- frame.kinfolkKey (lower-case "first last") on each dot first. This wraps
-- that library call; KinFolk's own files are untouched. If any of that
-- changes, the tweak does nothing and says so once.

local REF = "KinFolkGuildMap"

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

local grouped = {}      -- key -> true for everyone in your party or raid
local shown = {}        -- KinFolk minimap dot -> the arguments it was drawn with
local hidden = {}       -- dots this tweak is holding back

local function InGroup(icon)
    return icon.kinfolkKey ~= nil and grouped[icon.kinfolkKey] == true
end

local pins, add, remove

local function Wrap()
    pins = LibStub and LibStub("HereBeDragons-Pins-2.0", true)
    if type(pins) ~= "table" or type(pins.AddMinimapIconMap) ~= "function"
        or type(pins.RemoveMinimapIcon) ~= "function" then
        Print("KinFolk's map library looks different, so party dots are left as they are.")
        return false
    end
    add, remove = pins.AddMinimapIconMap, pins.RemoveMinimapIcon

    pins.AddMinimapIconMap = function(self, ref, icon, ...)
        if ref == REF and type(icon) == "table" then
            shown[icon] = { n = select("#", ...), ... }
            if InGroup(icon) then
                hidden[icon] = true
                return remove(self, ref, icon)
            end
            hidden[icon] = nil
        end
        return add(self, ref, icon, ...)
    end

    pins.RemoveMinimapIcon = function(self, ref, icon, ...)
        -- KinFolk took the dot away (offline, stale, map turned off).
        if ref == REF and icon then
            shown[icon], hidden[icon] = nil, nil
        end
        return remove(self, ref, icon, ...)
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
    for icon, args in pairs(shown) do
        if InGroup(icon) then
            if not hidden[icon] then
                hidden[icon] = true
                remove(pins, REF, icon)
            end
        elseif hidden[icon] then
            hidden[icon] = nil
            add(pins, REF, icon, unpack(args, 1, args.n))
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
