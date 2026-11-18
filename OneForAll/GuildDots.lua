-- Tinkerbox section, OneForAll: no OneForAll guild dot on the world
-- map for a guildmate KinFolk already shows there. Both add-ons draw
-- guildmates on the world map, each only for people who run it, so someone
-- with both showed twice. The KinFolk dot stays; OneForAll still shows
-- guildmates who only have OneForAll (or OpenMap).
--
-- OneForAll keeps its guild map list in OneForAll.MapGuild._members (and
-- _openMap for OpenMap users) and draws it in MapGuild.Refresh. This wraps
-- Refresh: guildmates with a KinFolk dot are taken out of those lists while
-- it draws and put straight back, so nothing else in OneForAll changes.

local _, ns = ...

local M = ns.Section({
    module = "oneforall",
    key = "kinfolkOneForAllDots",   -- its key from before it moved here
    title = "Guild dots",
    desc = "Guildmates who run both KinFolk and OneForAll showed twice on the world map."
        .. " This keeps their KinFolk dot and leaves out the OneForAll one."
        .. " Guildmates with only OneForAll (or OpenMap) still show through OneForAll.",
    needs = { "KinFolk" },  -- reads KinFolk's dots (KinFolk/Pins.lua)
})
if not M then
    return
end

local Pins = ns.KinFolkPins
local GM = type(OneForAll) == "table" and OneForAll.MapGuild
if type(GM) ~= "table" or type(GM.Refresh) ~= "function" or type(GM._members) ~= "table" then
    M:Fail("OneForAll's guild map looks different")
    return
end

local original = GM.Refresh
local lists = { GM._members, GM._openMap }
local set_aside = {}    -- list, name, entry, list, name, entry, ...

local function Restore()
    for i = 1, #set_aside, 3 do
        set_aside[i][set_aside[i + 1]] = set_aside[i + 2]
    end
    wipe(set_aside)
end

-- Replaced now, while add-ons load: OneForAll hooks the world map with
-- GM.Refresh at login, so it picks this up.
GM.Refresh = function(...)
    if M:IsOn() then
        for _, list in ipairs(lists) do
            if type(list) == "table" then
                for name, entry in pairs(list) do
                    if Pins.HasWorldDot(name) then
                        set_aside[#set_aside + 1] = list
                        set_aside[#set_aside + 1] = name
                        set_aside[#set_aside + 1] = entry
                        list[name] = nil
                    end
                end
            end
        end
    end
    local ok, err = pcall(original, ...)
    Restore()
    if not ok then
        error(err, 0)
    end
end

-- Redraw OneForAll's dots once, soon, if the map is open: after a switch,
-- or when a KinFolk dot comes or goes (so a double never lingers until
-- OneForAll's next 5 second tick).
local pending = false
local function Redraw()
    if pending or not (WorldMapFrame and WorldMapFrame:IsShown()) then
        return
    end
    pending = true
    C_Timer.After(0, function()
        pending = false
        GM.Refresh()
    end)
end

function M:OnToggle()
    Redraw()
end

Pins.OnChange(function(kindName)
    if kindName == "world" and M:IsOn() then
        Redraw()
    end
end)

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function()
    local ok, why = Pins.Start()
    if not ok then
        M:Fail(why)
    end
end)
