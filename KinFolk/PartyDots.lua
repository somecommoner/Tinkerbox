-- Tinkerbox module, KinFolk: no KinFolk dot for guildmates in your group, on
-- the minimap or the world map. The game already shows party and raid
-- members on both, so KinFolk's dot on top is a double. Dots come back when
-- they leave the group, or when this is switched off.

local _, ns = ...

local M = ns.Module({
    key = "kinfolkPartyDots",
    title = "KinFolk party dots",
    desc = "Hides KinFolk's dot for guildmates in your party or raid, on the minimap and the world map."
        .. " The game already shows them there. Their dots come back when they leave the group.",
    needs = { "KinFolk" },
})
if not M then
    return
end

local Pins = ns.KinFolkPins
local grouped = {}      -- key -> true for everyone in your party or raid

Pins.AddFilter(function(dot)
    return M:IsOn() and grouped[dot.kinfolkKey] == true
end)

function M:OnToggle()
    Pins.Refilter()
end

local function RefreshGroup()
    wipe(grouped)
    local prefix, count = "party", GetNumSubgroupMembers()
    if IsInRaid() then
        prefix, count = "raid", GetNumGroupMembers()
    end
    for i = 1, count do
        local key = Pins.Key(GetUnitName(prefix .. i, true))
        if key then
            grouped[key] = true
        end
    end
    Pins.Refilter()
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        local ok, why = Pins.Start()
        if not ok then
            M:Fail(why)
            return
        end
        self:RegisterEvent("GROUP_ROSTER_UPDATE")
        self:RegisterEvent("PLAYER_ENTERING_WORLD")
        self:RegisterEvent("UNIT_NAME_UPDATE")
    end
    RefreshGroup()
end)
