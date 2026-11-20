-- Tinkerbox helper, Equipment: shared by its sections. Set names, saving
-- what you wear into a set, and which set you last put on.

local _, ns = ...

local Sets = {}
ns.EquipmentSets = Sets

-- A set's name, or nil if there's no such set (deleted).
function Sets.Name(id)
    if id == nil then
        return nil
    end
    local name = C_EquipmentSet.GetEquipmentSetInfo(id)
    return name
end

-- Save what you're wearing into a set, keeping the slots that set ignores
-- ignored (the game's save uses whatever slots were last flagged for it).
-- Returns true if it saved.
function Sets.Save(id)
    local api = C_EquipmentSet
    local name = Sets.Name(id)
    if not name or not api.SaveEquipmentSet or InCombatLockdown() then
        return false
    end
    if api.ClearIgnoredSlotsForSave and api.GetIgnoredSlots and api.IgnoreSlotForSave then
        api.ClearIgnoredSlotsForSave()
        for slot, ignored in pairs(api.GetIgnoredSlots(id) or {}) do
            if ignored then
                api.IgnoreSlotForSave(slot)
            end
        end
    end
    api.SaveEquipmentSet(id)
    ns.Print("Saved your gear to " .. name .. ".")
    return true
end

-- The set you last put on, however you did it (the Equipment Manager, a
-- macro, Tinkerbox). At login: the set that matches what you're wearing.
local current

function Sets.Current()
    if current and Sets.Name(current) then
        return current
    end
    return nil
end

local function FindWorn()
    for _, id in ipairs(C_EquipmentSet.GetEquipmentSetIDs() or {}) do
        local _, _, _, isEquipped = C_EquipmentSet.GetEquipmentSetInfo(id)
        if isEquipped then
            return id
        end
    end
    return nil
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("EQUIPMENT_SWAP_FINISHED")
frame:SetScript("OnEvent", function(_, event, result, setID)
    if event == "EQUIPMENT_SWAP_FINISHED" then
        if result and setID then
            current = setID
        end
    elseif not Sets.Current() then
        current = FindWorn()
    end
end)
