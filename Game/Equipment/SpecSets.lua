-- Tinkerbox section, Equipment: put on an equipment set when you change
-- dual spec. Forever's Equipment Manager can't tie a set to a spec (its cog
-- only renames and changes the icon), so this does it: pick a set for each
-- talent spec, and switching spec equips it.
--
-- Picks are kept per character (sets belong to one character), by set ID,
-- so renaming a set keeps the pick. A deleted set reads as None.
-- Gear can't be changed in combat, so a switch then waits until it ends.

local _, ns = ...

local M = ns.Section({
    module = "equipment",
    key = "equipmentSpecSets",
    title = "Equipment set per spec",
    desc = "Pick an equipment set for each of your talent specs. Switching spec puts that set on."
        .. " Picks are saved for each character.",
})
if not M then
    return
end

local NUM_SPECS = 2

local function CharKey()
    local name, realm = UnitFullName("player")
    return (name or "?") .. "-" .. (realm or GetRealmName() or "?")
end

-- This character's picks: [spec] = set ID.
local function Picks()
    local chars = M:Get("chars")
    if type(chars) ~= "table" then
        chars = {}
        M:Set("chars", chars)
    end
    local key = CharKey()
    if type(chars[key]) ~= "table" then
        chars[key] = {}
    end
    return chars[key]
end

local function SetName(id)
    if id == nil then
        return nil
    end
    local name = C_EquipmentSet.GetEquipmentSetInfo(id)
    return name
end

-- The set picked for a spec, if it still exists.
local function PickedSet(spec)
    local id = Picks()[spec]
    if id ~= nil and SetName(id) then
        return id
    end
    return nil
end

local function SpecCount()
    return GetNumSpecGroups and GetNumSpecGroups() or 1
end

local function ActiveSpec()
    return C_SpecializationInfo and C_SpecializationInfo.GetActiveSpecGroup
        and C_SpecializationInfo.GetActiveSpecGroup() or 1
end

local function SpecName(spec)
    if spec == 1 then
        return TALENT_SPEC_PRIMARY or "Primary talents"
    end
    return TALENT_SPEC_SECONDARY or "Secondary talents"
end

-- Equipping -------------------------------------------------------------

local frame = CreateFrame("Frame")
local waiting = false   -- a switch happened in combat

local function EquipForSpec()
    waiting = false
    frame:UnregisterEvent("PLAYER_REGEN_ENABLED")
    if not M:IsOn() then
        return
    end
    local spec = ActiveSpec()
    local id = PickedSet(spec)
    if not id then
        return
    end
    local name, _, _, isEquipped = C_EquipmentSet.GetEquipmentSetInfo(id)
    if isEquipped then
        return
    end
    if InCombatLockdown() then
        waiting = true
        frame:RegisterEvent("PLAYER_REGEN_ENABLED")
        ns.Print("Will put on " .. name .. " when combat ends.")
        return
    end
    C_EquipmentSet.UseEquipmentSet(id)
    ns.Print("Put on " .. name .. " for " .. SpecName(spec) .. ".")
end

frame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
frame:SetScript("OnEvent", function(_, event)
    if event == "ACTIVE_TALENT_GROUP_CHANGED" or (event == "PLAYER_REGEN_ENABLED" and waiting) then
        EquipForSpec()
    end
end)

function M:OnToggle(on)
    if not on and waiting then
        waiting = false
        frame:UnregisterEvent("PLAYER_REGEN_ENABLED")
    end
end

-- Options ---------------------------------------------------------------

local function SetList()
    local list = {}
    for _, id in ipairs(C_EquipmentSet.GetEquipmentSetIDs() or {}) do
        local name = SetName(id)
        if name then
            list[#list + 1] = { id = id, name = name }
        end
    end
    table.sort(list, function(a, b) return a.name:lower() < b.name:lower() end)
    return list
end

-- A drop-down of this character's sets, or a button that opens the same
-- list on a client without the drop-down template.
local function SetPicker(parent, spec, OnPick)
    local function Fill(root)
        root:CreateRadio("None", function() return PickedSet(spec) == nil end, function()
            Picks()[spec] = nil
            OnPick()
        end)
        for _, set in ipairs(SetList()) do
            root:CreateRadio(set.name, function() return PickedSet(spec) == set.id end, function()
                Picks()[spec] = set.id
                OnPick()
            end)
        end
    end
    local ok, dropdown = pcall(CreateFrame, "DropdownButton", nil, parent, "WowStyle1DropdownTemplate")
    if ok and dropdown and dropdown.SetupMenu then
        dropdown:SetWidth(200)
        dropdown:SetupMenu(function(_, root) Fill(root) end)
        return dropdown, function() dropdown:GenerateMenu() end
    end
    local button = ns.UI.Button(parent, "None", 200)
    local function Update()
        button:SetText(SetName(PickedSet(spec)) or "None")
    end
    button:SetScript("OnClick", function(self)
        MenuUtil.CreateContextMenu(self, function(_, root) Fill(root) end)
    end)
    return button, Update
end

function M:BuildOptions(body, below)
    local UI = ns.UI
    local updates = {}
    local function UpdateAll()
        for _, fn in ipairs(updates) do
            fn()
        end
    end

    local anchor, height = below, 0
    local labels = {}
    for spec = 1, NUM_SPECS do
        local label = UI.Text(body, "GameFontNormal")
        label:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", anchor == below and 4 or 0, -16)
        label:SetWidth(170)
        labels[spec] = label
        local picker, update = SetPicker(body, spec, UpdateAll)
        picker:SetPoint("LEFT", label, "RIGHT", 8, 0)
        updates[#updates + 1] = update
        anchor = label
        height = height + 16 + 14
    end

    local note = UI.Text(body, "GameFontHighlightSmall")
    note:SetTextColor(0.7, 0.7, 0.7)
    note:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -16)
    note:SetWidth(460)
    height = height + 16 + 28

    updates[#updates + 1] = function()
        local active, count = ActiveSpec(), SpecCount()
        for spec, label in ipairs(labels) do
            local text = SpecName(spec)
            if count > 1 and spec == active then
                text = text .. " |cff33ff99(active)|r"
            end
            label:SetText(text)
        end
        if count < 2 then
            note:SetText("This character hasn't learned dual spec yet, so only the first pick does anything for now.")
        elseif #SetList() == 0 then
            note:SetText("This character has no equipment sets yet. Make them in the Equipment Manager on your character window.")
        else
            note:SetText("Sets are put on when you switch spec, not when you log in. In combat, it waits until the fight ends.")
        end
    end

    -- Sets and the active spec can change while the page is closed.
    body:HookScript("OnShow", UpdateAll)
    frame:HookScript("OnEvent", function()
        if body:IsVisible() then
            UpdateAll()
        end
    end)
    UpdateAll()
    return height
end
