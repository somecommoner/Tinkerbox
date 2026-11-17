-- Tinkerbox: small widgets for module settings pages (BuildOptions).

local _, ns = ...

local UI = {}
ns.UI = UI

local count = 0

-- A horizontal slider with no labels of its own. OptionsSliderTemplate,
-- or a plain slider on a client without it.
function UI.Slider(parent, width)
    count = count + 1
    local name = "TinkerboxSlider" .. count
    local ok, slider = pcall(CreateFrame, "Slider", name, parent, "OptionsSliderTemplate")
    if not ok then
        slider = CreateFrame("Slider", name, parent)
        slider:SetOrientation("HORIZONTAL")
        slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
        local track = slider:CreateTexture(nil, "BACKGROUND")
        track:SetColorTexture(0, 0, 0, 0.5)
        track:SetPoint("LEFT")
        track:SetPoint("RIGHT")
        track:SetHeight(6)
    end
    for _, suffix in ipairs({ "Low", "High", "Text" }) do
        local text = rawget(slider, suffix) or _G[name .. suffix]
        if type(text) == "table" and text.Hide then
            text:Hide()
        end
    end
    slider:SetSize(width or 220, 16)
    if slider.SetObeyStepOnDrag then
        slider:SetObeyStepOnDrag(true)
    end
    return slider
end

function UI.Check(parent)
    return CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
end

function UI.Button(parent, text, width)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width or 80, 20)
    button:SetText(text)
    return button
end

function UI.Text(parent, font, text)
    local fs = parent:CreateFontString(nil, "ARTWORK", font or "GameFontHighlightSmall")
    fs:SetJustifyH("LEFT")
    if text then
        fs:SetText(text)
    end
    return fs
end
