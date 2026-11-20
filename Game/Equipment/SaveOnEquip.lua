-- Tinkerbox section, Equipment: pressing Equip on a set in the Equipment
-- Manager first saves what you're wearing into the set you last put on, so
-- changes you made to your gear are kept.
--
-- Only the Equipment Manager's Equip button does this (macros and action
-- bar set buttons don't). Its PreClick runs before the game's own click,
-- so nothing of the game's is replaced. Equipping the set you already have
-- on doesn't save first, so it still puts that set back as it was.

local _, ns = ...

local M = ns.Section({
    module = "equipment",
    key = "equipmentSaveOnEquip",
    title = "Save before changing sets",
    desc = "When you press Equip on another set in the Equipment Manager, what you're wearing is saved"
        .. " to the set you last put on first. Equipping the set you already have on puts it back as it was, without saving.",
})
if not M then
    return
end

local Sets = ns.EquipmentSets

local function Pane()
    return PaperDollFrame and PaperDollFrame.EquipmentManagerPane or _G.PaperDollEquipmentManagerPane
end

local function EquipButton()
    local pane = Pane()
    return _G.PaperDollEquipmentManagerPaneEquipSet or (pane and pane.EquipSet)
end

local function BeforeEquip()
    if not M:IsOn() or InCombatLockdown() then
        return
    end
    local pane = Pane()
    local picked = pane and pane.selectedSetID
    local current = Sets.Current()
    -- (No picked set known: don't guess, as saving over the set you're
    -- about to put back would lose it.)
    if picked == nil or current == nil or picked == current then
        return
    end
    local _, _, _, isEquipped = C_EquipmentSet.GetEquipmentSetInfo(current)
    if not isEquipped then
        Sets.Save(current)
    end
end

local hooked = false
local function Hook()
    if hooked then
        return true
    end
    local button = EquipButton()
    if not button or not button.HookScript then
        return false
    end
    button:HookScript("PreClick", BeforeEquip)
    hooked = true
    return true
end

-- The character window may load after Tinkerbox, so try again when it
-- shows; say so only if it's open and the button still isn't there.
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function()
    if Hook() then
        return
    end
    if CharacterFrame and CharacterFrame.HookScript then
        CharacterFrame:HookScript("OnShow", function()
            if not Hook() then
                M:Fail("couldn't find the Equipment Manager's Equip button")
            end
        end)
    else
        M:Fail("couldn't find the character window")
    end
end)
