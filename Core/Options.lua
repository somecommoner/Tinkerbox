-- Tinkerbox settings: Options > AddOns > Tinkerbox.
-- The Tinkerbox page is an overview of every module and its state. Each
-- module that can run gets its own page under it: an Enabled switch, what it
-- does, and the module's own options if it has any (M:BuildOptions).
-- Registered like other add-ons in this client (Settings canvas pages),
-- with the older InterfaceOptions calls as a fallback. /tinkerbox opens it.

local _, ns = ...

local TITLE = "Tinkerbox"

local category, mainPanel
local refreshers = {}

local function Refresh()
    for _, fn in ipairs(refreshers) do
        fn()
    end
    for _, m in ipairs(ns.modules) do
        if m.RefreshOptions then
            m.RefreshOptions()
        end
    end
end

local function Status(m)
    if not m.available then
        return "|cff909090Needs " .. table.concat(m.missing, ", ") .. "|r"
    elseif m.failed then
        return "|cffff6060Not working: " .. m.failed .. "|r"
    elseif m:IsOn() then
        return "|cff40ff40On|r"
    end
    return "|cff909090Off|r"
end

local function Heading(panel, title, text)
    local head = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    head:SetPoint("TOPLEFT", 16, -16)
    head:SetText(title)
    local sub = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    sub:SetPoint("TOPLEFT", head, "BOTTOMLEFT", 0, -8)
    sub:SetPoint("RIGHT", panel, "RIGHT", -16, 0)
    sub:SetJustifyH("LEFT")
    sub:SetText(text)
    return sub
end

-- The Tinkerbox page: one line per module with its state.
local function BuildMain()
    local panel = CreateFrame("Frame")
    panel.name = TITLE
    local below = Heading(panel, TITLE, "Small fixes for WoW Forever and other add-ons, made from outside them."
        .. " Each module has its own page below, and only runs when the add-ons it changes are installed.")
    local previous = below
    for _, m in ipairs(ns.modules) do
        local name = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        name:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, previous == below and -16 or -10)
        name:SetText(m.title)
        local state = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        state:SetPoint("LEFT", name, "LEFT", 260, 0)
        refreshers[#refreshers + 1] = function() state:SetText(Status(m)) end
        previous = name
    end
    panel:SetScript("OnShow", Refresh)
    return panel
end

-- A module's own page.
local function BuildModule(m)
    local panel = CreateFrame("Frame")
    panel.name = m.title
    panel.parent = TITLE
    local below = Heading(panel, m.title, m.desc or "")

    local changes = panel:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    changes:SetPoint("TOPLEFT", below, "BOTTOMLEFT", 0, -6)
    changes:SetText("Changes: " .. (m.changes or table.concat(m.needs, ", ")))

    local check = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    check:SetPoint("TOPLEFT", changes, "BOTTOMLEFT", -4, -10)
    check:SetScript("OnClick", function(self)
        m:SetOn(self:GetChecked() and true or false)
        Refresh()
    end)
    local label = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    label:SetPoint("LEFT", check, "RIGHT", 4, 1)
    label:SetText("Enabled")
    local state = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    state:SetPoint("LEFT", label, "RIGHT", 16, 0)

    refreshers[#refreshers + 1] = function()
        check:SetChecked(m:IsSwitchedOn())
        check:SetEnabled(not m.failed)
        state:SetText(Status(m))
    end

    panel:SetScript("OnShow", Refresh)
    if m.BuildOptions then
        local ok, err = pcall(m.BuildOptions, m, panel, check)
        if not ok then
            ns.Print(m.title .. ": its options could not be shown (" .. tostring(err) .. ").")
        end
    end
    return panel
end

local function Register()
    mainPanel = BuildMain()
    local modern = Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterCanvasLayoutSubcategory
    if modern then
        category = Settings.RegisterCanvasLayoutCategory(mainPanel, TITLE)
        Settings.RegisterAddOnCategory(category)
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(mainPanel)
    end
    for _, m in ipairs(ns.modules) do
        if m.available then
            local panel = BuildModule(m)
            if modern then
                Settings.RegisterAddOnCategory(Settings.RegisterCanvasLayoutSubcategory(category, panel, m.title))
            elseif InterfaceOptions_AddCategory then
                InterfaceOptions_AddCategory(panel)
            end
        end
    end
    Refresh()
end

local function Open()
    if category and Settings and Settings.OpenToCategory then
        Settings.OpenToCategory(category.GetID and category:GetID() or category.ID)
    elseif mainPanel and InterfaceOptionsFrame_OpenToCategory then
        -- the old window needs two calls the first time
        InterfaceOptionsFrame_OpenToCategory(mainPanel)
        InterfaceOptionsFrame_OpenToCategory(mainPanel)
    end
end

SLASH_TINKERBOX1 = "/tinkerbox"
SlashCmdList.TINKERBOX = Open

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function()
    local ok, err = pcall(Register)
    if not ok then
        ns.Print("The settings pages could not be made (" .. tostring(err) .. ").")
    end
end)
