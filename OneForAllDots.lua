-- KinFolk Tweaks: no OneForAll guild dot on the world map for a guildmate
-- KinFolk already shows there. Both add-ons draw guildmates on the world map,
-- each only for people who run it, so someone with both showed twice. The
-- KinFolk dot stays; OneForAll still shows guildmates who only have
-- OneForAll (or OpenMap), so you see as many people as possible.
--
-- OneForAll keeps its guild map list in OneForAll.MapGuild._members (and
-- _openMap for OpenMap users) and draws it in MapGuild.Refresh. This wraps
-- Refresh: guildmates with a KinFolk dot are taken out of those lists while
-- it draws and put straight back, so nothing else in OneForAll changes.
-- If OneForAll isn't there or looks different, this does nothing.

local _, ns = ...

local GM = type(OneForAll) == "table" and OneForAll.MapGuild
if type(GM) ~= "table" or type(GM.Refresh) ~= "function" or type(GM._members) ~= "table" then
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
    if ns.KinFolkWorldDot then
        for _, list in ipairs(lists) do
            if type(list) == "table" then
                for name, entry in pairs(list) do
                    if ns.KinFolkWorldDot(name) then
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

-- A KinFolk dot came or went while the map is open: redraw OneForAll's dots
-- once, so a double never lingers until OneForAll's next 5 second tick.
local pending = false
ns.OnKinFolkWorldDotsChanged(function()
    if pending or not (WorldMapFrame and WorldMapFrame:IsShown()) then
        return
    end
    pending = true
    C_Timer.After(0, function()
        pending = false
        GM.Refresh()
    end)
end)
