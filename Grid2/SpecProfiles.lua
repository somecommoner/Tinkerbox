-- Tinkerbox section, Grid2: a Grid2 profile for each dual spec. Grid2 can
-- do this itself on newer clients ("Enable profiles by Specialization"),
-- but hides the option on 1.x ones like Forever's, so this does it: pick a
-- profile for each talent spec, and switching spec loads it.
--
-- Picks are kept per character, by profile name; a deleted profile reads as
-- None. Grid2's frames are secure and can't be rebuilt in combat, so a
-- switch then waits until it ends. The active spec's profile is also loaded
-- at login and when you pick it, so what you see always matches the pick.

local _, ns = ...

local M = ns.Section({
    module = "grid2",
    key = "grid2SpecProfiles",
    title = "Profile per spec",
    desc = "Pick a Grid2 profile for each of your talent specs. Switching spec loads that profile."
        .. " Picks are saved for each character.",
})
if not M then
    return
end

local NUM_SPECS = 2

-- Grid2's AceDB profiles, or nil (and the section turned off) if Grid2 no
-- longer looks the way this expects.
local function DB()
    local db = type(Grid2) == "table" and Grid2.db
    if type(db) ~= "table" or type(db.SetProfile) ~= "function" or type(db.GetProfiles) ~= "function"
        or type(db.GetCurrentProfile) ~= "function" then
        M:Fail("Grid2's profiles look different")
        return nil
    end
    return db
end

local function Profiles()
    local db = DB()
    local list = db and db:GetProfiles({}) or {}
    table.sort(list, function(a, b) return a:lower() < b:lower() end)
    return list
end

local function Exists(name)
    for _, profile in ipairs(Profiles()) do
        if profile == name then
            return true
        end
    end
    return false
end

local function CharKey()
    local name, realm = UnitFullName("player")
    return (name or "?") .. "-" .. (realm or GetRealmName() or "?")
end

-- This character's picks: [spec] = profile name.
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

-- The profile picked for a spec, if it still exists.
local function Picked(spec)
    local name = Picks()[spec]
    if type(name) == "string" and Exists(name) then
        return name
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

-- Loading -----------------------------------------------------------------

local frame = CreateFrame("Frame")
local waiting = false   -- a load is due once combat ends

-- Load the active spec's profile, if it has one and it isn't loaded.
-- quiet: no chat line (login).
local function Apply(quiet)
    waiting = false
    frame:UnregisterEvent("PLAYER_REGEN_ENABLED")
    if not M:IsOn() then
        return
    end
    local spec = ActiveSpec()
    local name = Picked(spec)
    local db = DB()
    if not name or not db or db:GetCurrentProfile() == name then
        return
    end
    if InCombatLockdown() then
        waiting = true
        frame:RegisterEvent("PLAYER_REGEN_ENABLED")
        ns.Print("Will load Grid2 profile " .. name .. " when combat ends.")
        return
    end
    db:SetProfile(name)
    if not quiet then
        ns.Print("Loaded Grid2 profile " .. name .. " for " .. SpecName(spec) .. ".")
    end
end

frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
frame:SetScript("OnEvent", function(_, event, isLogin, isReload)
    if event == "PLAYER_ENTERING_WORLD" then
        if isLogin or isReload then
            Apply(true)
        end
    elseif event == "ACTIVE_TALENT_GROUP_CHANGED" then
        Apply()
    elseif event == "PLAYER_REGEN_ENABLED" and waiting then
        Apply()
    end
end)

function M:OnToggle(on)
    if on then
        Apply()
    elseif waiting then
        waiting = false
        frame:UnregisterEvent("PLAYER_REGEN_ENABLED")
    end
end

-- Options -----------------------------------------------------------------

-- A drop-down of Grid2's profiles, or a button that opens the same list on
-- a client without the drop-down template.
local function ProfilePicker(parent, spec, OnPick)
    local function Fill(root)
        root:CreateRadio("None", function() return Picked(spec) == nil end, function()
            Picks()[spec] = nil
            OnPick(spec)
        end)
        for _, name in ipairs(Profiles()) do
            root:CreateRadio(name, function() return Picked(spec) == name end, function()
                Picks()[spec] = name
                OnPick(spec)
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
        button:SetText(Picked(spec) or "None")
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
    -- Picking the active spec's profile loads it straight away.
    local function OnPick(spec)
        if spec == ActiveSpec() then
            Apply()
        end
        UpdateAll()
    end

    local anchor, height = below, 0
    local labels = {}
    for spec = 1, NUM_SPECS do
        local label = UI.Text(body, "GameFontNormal")
        label:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", anchor == below and 4 or 0, -16)
        label:SetWidth(170)
        labels[spec] = label
        local picker, update = ProfilePicker(body, spec, OnPick)
        picker:SetPoint("LEFT", label, "RIGHT", 8, 0)
        updates[#updates + 1] = update
        anchor = label
        height = height + 16 + 14
    end

    local note = UI.Text(body, "GameFontHighlightSmall")
    note:SetTextColor(0.7, 0.7, 0.7)
    note:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -12)
    note:SetWidth(460)
    height = height + 12 + 28

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
        else
            note:SetText("Make or copy profiles on Grid2's Profiles page (/grid2). In combat, a switch waits until the fight ends.")
        end
    end

    body:HookScript("OnShow", UpdateAll)
    frame:HookScript("OnEvent", function()
        if body:IsVisible() then
            UpdateAll()
        end
    end)
    UpdateAll()
    return height
end
