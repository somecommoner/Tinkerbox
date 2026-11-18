-- Tinkerbox settings: Options > AddOns > Tinkerbox.
--
-- The Tinkerbox page lists every module: its on/off switch, the add-ons it
-- changes (and uses) and whether they're loaded, its state, and a button to
-- its page. Each module whose add-ons are loaded gets its own page under
-- Tinkerbox: its switch, then its sections, each a header (click to expand
-- or collapse, with the section's own switch) over its description and
-- options (Section:BuildOptions). Sections start collapsed; the ones you
-- open stay open.
--
-- Registered like other add-ons in this client (Settings canvas pages),
-- with the older InterfaceOptions calls as a fallback. /tinkerbox opens it.

local _, ns = ...

local TITLE = "Tinkerbox"
local GREEN, GREY, RED = "|cff40ff40", "|cff909090", "|cffff6060"
local YES = "|TInterface\\RaidFrame\\ReadyCheck-Ready:14|t"
local NO = "|TInterface\\RaidFrame\\ReadyCheck-NotReady:14|t"

local category, mainPanel
local pages = {}        -- module key -> { panel, category }
local refreshers = {}

local function Refresh()
    for _, fn in ipairs(refreshers) do
        fn()
    end
    for _, m in ipairs(ns.modules) do
        for _, s in ipairs(m.sections) do
            if s.RefreshOptions then
                s.RefreshOptions()
            end
        end
    end
end

local function Addons(addons)
    local parts = {}
    for _, addon in ipairs(addons) do
        if ns.Loaded(addon) then
            parts[#parts + 1] = YES .. " " .. addon
        else
            parts[#parts + 1] = NO .. " " .. GREY .. addon .. " (not loaded)|r"
        end
    end
    return table.concat(parts, "   ")
end

-- "Changes: KinFolk   Uses: ..." with a tick or cross for each add-on.
local function Changes(m)
    local text = "Changes: " .. (#m.tweaks == 0 and "the game" or Addons(m.tweaks))
    local uses = m:Uses()
    if #uses > 0 then
        text = text .. "      Uses: " .. Addons(uses)
    end
    return text
end

local function ModuleStatus(m)
    if not m.available then
        return GREY .. "Needs " .. table.concat(m.missing, ", ") .. "|r"
    elseif not m:IsSwitchedOn() then
        return GREY .. "Off|r"
    end
    local on, broken = 0, 0
    for _, s in ipairs(m.sections) do
        if s.failed then
            broken = broken + 1
        elseif s:IsOn() then
            on = on + 1
        end
    end
    local text = GREEN .. "On|r  " .. GREY .. on .. " of " .. #m.sections .. " sections on|r"
    if broken > 0 then
        text = text .. "  " .. RED .. broken .. " not working|r"
    end
    return text
end

local function SectionStatus(s)
    if not s.available then
        return GREY .. "Needs " .. table.concat(s.missing, ", ") .. "|r"
    elseif s.failed then
        return RED .. "Not working|r"
    elseif not s.module:IsOn() then
        return GREY .. "Module off|r"
    elseif s:IsOn() then
        return GREEN .. "On|r"
    end
    return GREY .. "Off|r"
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

local function OpenPage(m)
    local page = pages[m.key]
    if not page then
        return
    end
    if page.category then
        if SettingsPanel and SettingsPanel.SelectCategory and SettingsPanel:IsShown()
            and pcall(SettingsPanel.SelectCategory, SettingsPanel, page.category, true) then
            return
        end
        if Settings and Settings.OpenToCategory then
            Settings.OpenToCategory(page.category.GetID and page.category:GetID() or page.category.ID)
        end
    elseif InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory(page.panel)
    end
end

-- The Tinkerbox page ----------------------------------------------------

local function BuildMain()
    local panel = CreateFrame("Frame")
    panel.name = TITLE
    local below = Heading(panel, TITLE, "Small fixes for WoW Forever and other add-ons, made from outside them."
        .. " Switch modules on or off here. Each module has its own page below Tinkerbox,"
        .. " where its sections can be switched and set one by one.")

    local previous = below
    for _, m in ipairs(ns.modules) do
        local row = CreateFrame("Frame", nil, panel)
        row:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, previous == below and -16 or -8)
        row:SetPoint("RIGHT", panel, "RIGHT", -16, 0)
        row:SetHeight(44)

        local check = ns.UI.Check(row)
        check:SetPoint("TOPLEFT", row, "TOPLEFT", -4, 2)
        check:SetScript("OnClick", function(self)
            m:SetOn(self:GetChecked() and true or false)
            Refresh()
        end)
        local name = ns.UI.Text(row, "GameFontNormal", m.title)
        name:SetPoint("LEFT", check, "RIGHT", 2, 1)
        local changes = ns.UI.Text(row, "GameFontHighlightSmall")
        changes:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -6)

        local open = ns.UI.Button(row, "Settings", 80)
        open:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, 0)
        open:SetScript("OnClick", function()
            OpenPage(m)
        end)
        local state = ns.UI.Text(row, "GameFontHighlightSmall")
        state:SetPoint("RIGHT", open, "LEFT", -12, 0)

        refreshers[#refreshers + 1] = function()
            check:SetChecked(m:IsSwitchedOn())
            check:SetEnabled(m.available)
            name:SetTextColor(m.available and 1 or 0.5, m.available and 0.82 or 0.5, m.available and 0 or 0.5)
            changes:SetText(Changes(m))
            state:SetText(ModuleStatus(m))
            open:SetShown(pages[m.key] ~= nil)
        end
        previous = row
    end
    panel:SetScript("OnShow", Refresh)
    return panel
end

-- A module's page -------------------------------------------------------

local HEADER = 26

-- One section: a header and, while open, its body. Returns the block and
-- a function that gives its height for the current width.
local function BuildSection(s, parent, Relayout)
    local block = CreateFrame("Frame", nil, parent)

    local header = CreateFrame("Button", nil, block)
    header:SetPoint("TOPLEFT", block, "TOPLEFT", 0, 0)
    header:SetPoint("RIGHT", block, "RIGHT", 0, 0)
    header:SetHeight(HEADER)
    local bg = header:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(1, 1, 1, 0.05)
    local hover = header:CreateTexture(nil, "HIGHLIGHT")
    hover:SetAllPoints()
    hover:SetColorTexture(1, 1, 1, 0.07)
    local icon = header:CreateTexture(nil, "ARTWORK")
    icon:SetSize(14, 14)
    icon:SetPoint("LEFT", header, "LEFT", 6, 0)
    local title = ns.UI.Text(header, "GameFontNormal", s.title)
    title:SetPoint("LEFT", icon, "RIGHT", 6, 0)
    local check = ns.UI.Check(header)
    check:SetSize(24, 24)
    check:SetPoint("RIGHT", header, "RIGHT", -2, 0)
    local state = ns.UI.Text(header, "GameFontHighlightSmall")
    state:SetPoint("RIGHT", check, "LEFT", -6, 0)

    local body = CreateFrame("Frame", nil, block)
    body:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, 0)
    body:SetPoint("RIGHT", block, "RIGHT", 0, 0)
    local desc = ns.UI.Text(body, "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", body, "TOPLEFT", 26, -8)
    desc:SetWidth(500)

    local optionsHeight = 0
    if s.available and s.BuildOptions then
        local ok, height = pcall(s.BuildOptions, s, body, desc)
        if ok then
            optionsHeight = tonumber(height) or 0
        else
            ns.Print(s.title .. ": its options could not be shown (" .. tostring(height) .. ").")
        end
    end

    header:SetScript("OnClick", function()
        ns.SetOpen(s.key, not ns.IsOpen(s.key))
        Relayout()
    end)
    check:SetScript("OnClick", function(self)
        s:SetOn(self:GetChecked() and true or false)
        Refresh()
    end)

    refreshers[#refreshers + 1] = function()
        local open = ns.IsOpen(s.key)
        icon:SetTexture(open and "Interface\\Buttons\\UI-MinusButton-Up" or "Interface\\Buttons\\UI-PlusButton-Up")
        body:SetShown(open)
        check:SetChecked(s:IsSwitchedOn())
        check:SetEnabled(s.available and not s.failed and s.module:IsOn())
        if s:IsOn() then
            title:SetTextColor(1, 0.82, 0)
        else
            title:SetTextColor(0.6, 0.6, 0.6)
        end
        state:SetText(SectionStatus(s))
        local text = s.desc or ""
        if not s.available then
            text = text .. "\n\n" .. GREY .. "Needs " .. table.concat(s.missing, ", ") .. ", which isn't loaded.|r"
        elseif s.failed then
            text = text .. "\n\n" .. RED .. "Not working: " .. s.failed .. "|r"
        end
        desc:SetText(text)
    end

    local function Height(width)
        if not ns.IsOpen(s.key) then
            return HEADER
        end
        desc:SetWidth(math.max(width - 42, 100))
        return HEADER + 8 + (desc:GetStringHeight() or 0) + optionsHeight + 14
    end
    return block, Height
end

local function BuildModule(m)
    local panel = CreateFrame("Frame")
    panel.name = m.title
    panel.parent = TITLE
    local below = Heading(panel, m.title, m.desc or "")

    local changes = ns.UI.Text(panel, "GameFontHighlightSmall")
    changes:SetPoint("TOPLEFT", below, "BOTTOMLEFT", 0, -8)

    local check = ns.UI.Check(panel)
    check:SetPoint("TOPLEFT", changes, "BOTTOMLEFT", -4, -8)
    check:SetScript("OnClick", function(self)
        m:SetOn(self:GetChecked() and true or false)
        Refresh()
    end)
    local label = ns.UI.Text(panel, "GameFontHighlight", "Enabled")
    label:SetPoint("LEFT", check, "RIGHT", 4, 1)
    local state = ns.UI.Text(panel, "GameFontHighlightSmall")
    state:SetPoint("LEFT", label, "RIGHT", 16, 0)

    local scroll = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", check, "BOTTOMLEFT", 4, -10)
    scroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -30, 10)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(560, 1)
    scroll:SetScrollChild(content)

    local blocks, width = {}, 560
    local function Layout()
        local y = 0
        for _, b in ipairs(blocks) do
            local height = b.Height(width)
            b.frame:ClearAllPoints()
            b.frame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -y)
            b.frame:SetPoint("RIGHT", content, "RIGHT", 0, 0)
            b.frame:SetHeight(height)
            y = y + height + 6
        end
        content:SetHeight(math.max(y, 1))
    end
    local function Relayout()
        Refresh()
        Layout()
    end

    for _, s in ipairs(m.sections) do
        local frame, Height = BuildSection(s, content, Relayout)
        blocks[#blocks + 1] = { frame = frame, Height = Height }
    end
    if #blocks == 0 then
        local none = ns.UI.Text(content, "GameFontDisable", "This module has no sections yet.")
        none:SetPoint("TOPLEFT", content, "TOPLEFT", 4, -4)
    end

    scroll:SetScript("OnSizeChanged", function(_, w)
        if w and w > 0 then
            width = w
            content:SetWidth(w)
            Layout()
        end
    end)

    refreshers[#refreshers + 1] = function()
        changes:SetText(Changes(m))
        check:SetChecked(m:IsSwitchedOn())
        state:SetText(ModuleStatus(m))
        Layout()
    end
    panel:SetScript("OnShow", Refresh)
    return panel
end

-- Registering -----------------------------------------------------------

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
            local ok, panel = pcall(BuildModule, m)
            if not ok then
                ns.Print(m.title .. ": its page could not be made (" .. tostring(panel) .. ").")
            else
                local page = { panel = panel }
                if modern then
                    page.category = Settings.RegisterCanvasLayoutSubcategory(category, panel, m.title)
                    Settings.RegisterAddOnCategory(page.category)
                elseif InterfaceOptions_AddCategory then
                    InterfaceOptions_AddCategory(panel)
                end
                pages[m.key] = page
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
