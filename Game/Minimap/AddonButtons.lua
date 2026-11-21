-- Tinkerbox section, Minimap: no add-on buttons on the minimap.
--
-- Add-on buttons (LibDBIcon ones and others) are moved into a hidden frame
-- of ours, so they're gone however their add-on shows them. Only their
-- parent changes: switched off, each goes back to the frame it came from,
-- in the same place. Nothing is written to the add-ons' own settings.
--
-- Which frames count, like OneForAll's minimap button collector: named
-- children of the minimap that are buttons about the size of one. Every
-- LibDBIcon button counts. Others count only if an add-on made them (their
-- global name isn't secure), which leaves the game's own minimap parts
-- alone, and not if they look like a map pin (HandyNotes, GatherMate,
-- TomTom, Questie ...). Buttons another add-on has already gathered off the
-- minimap (OneForAll's collector) aren't touched.
--
-- Add-ons that load late or make their button late are caught by looking
-- again after each add-on loads and a few times after login.

local _, ns = ...

local S = ns.Section({
    module = "minimap",
    key = "minimapHideAddonButtons",
    title = "Hide add-on buttons",
    desc = "Removes every add-on's button from the minimap (LibDBIcon buttons and the like)."
        .. " The game's own minimap buttons, map pins and dots stay."
        .. " Switch this off to put them all back where they were.",
})
if not S then
    return
end

local hidden = CreateFrame("Frame", "TinkerboxHiddenMinimapButtons", UIParent)
hidden:Hide()

local taken = {}     -- button -> the parent it had
local hooked = {}    -- buttons with our SetParent hook
local placing = false

-- Map pins and the like, never taken (from OneForAll's collector).
local SKIP_WORD = { "Pin", "Questie", "HandyNotes", "GatherMate", "TomTom", "^TTMinimapButton", "Arrow", "Ping",
    "Blip", "Node", "Icon%d+$" }

local function MadeByAddon(name)
    if not issecurevariable then
        return true
    end
    local ok, secure = pcall(issecurevariable, name)
    return ok and not secure
end

local function IsAddonButton(f)
    if taken[f] or f == hidden then
        return false
    end
    if (f.IsForbidden and f:IsForbidden()) or (f.IsProtected and f:IsProtected()) then
        return false
    end
    local name = f.GetName and f:GetName()
    if type(name) ~= "string" or name == "" then
        return false
    end
    if name:find("^LibDBIcon10_") then
        return true
    end
    if name:find("^MinimapButton_") and name:find("LibDBIcon", 1, true) then
        return true
    end
    if not MadeByAddon(name) then
        return false
    end
    for _, word in ipairs(SKIP_WORD) do
        if name:find(word) then
            return false
        end
    end
    local clickable = (f.IsObjectType and f:IsObjectType("Button"))
        or (f.HasScript and f:HasScript("OnMouseUp") and f:GetScript("OnMouseUp"))
    if not clickable then
        return false
    end
    local w, h = f:GetWidth() or 0, f:GetHeight() or 0
    return w >= 18 and w <= 48 and h >= 18 and h <= 48 and math.abs(w - h) <= 10
end

local function Hook(f)
    if hooked[f] then
        return
    end
    hooked[f] = true
    -- Its add-on moving it back onto the minimap: hide it again, and give it
    -- back to that parent when switched off.
    hooksecurefunc(f, "SetParent", function(self, parent)
        if taken[self] and not placing and parent ~= hidden then
            taken[self] = parent
            placing = true
            self:SetParent(hidden)
            placing = false
        end
    end)
end

local function Take(f)
    taken[f] = f:GetParent()
    Hook(f)
    placing = true
    f:SetParent(hidden)
    placing = false
end

local function Scan()
    if not S:IsOn() then
        return
    end
    for _, parent in ipairs({ _G.Minimap, _G.MinimapBackdrop, _G.MinimapCluster }) do
        if type(parent) == "table" and parent.GetChildren then
            for _, f in ipairs({ parent:GetChildren() }) do
                if IsAddonButton(f) then
                    Take(f)
                end
            end
        end
    end
end

local function GiveBack()
    for f, parent in pairs(taken) do
        taken[f] = nil
        placing = true
        f:SetParent(parent or _G.Minimap)
        placing = false
    end
end

-- Events ----------------------------------------------------------------

local frame = CreateFrame("Frame")
local pending = false

local function ScanSoon(seconds)
    if pending then
        return
    end
    pending = true
    C_Timer.After(seconds, function()
        pending = false
        Scan()
    end)
end

frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        Scan()
        C_Timer.After(1, Scan)
        C_Timer.After(5, Scan)
        C_Timer.After(15, Scan)
    elseif S:IsOn() then
        ScanSoon(2)
    end
end)

function S:OnToggle(on)
    if on then
        Scan()
    else
        GiveBack()
    end
end

-- Options ---------------------------------------------------------------

function S:BuildOptions(body, below)
    local list = ns.UI.Text(body, "GameFontDisableSmall")
    list:SetPoint("TOPLEFT", below, "BOTTOMLEFT", 0, -8)
    list:SetWidth(500)
    body:HookScript("OnShow", function()
        local names = {}
        for f in pairs(taken) do
            names[#names + 1] = (f:GetName():gsub("^LibDBIcon10_", ""))
        end
        table.sort(names)
        list:SetText(#names > 0 and ("Hidden now: " .. table.concat(names, ", ")) or "Hidden now: none")
    end)
    return 8 + 24
end
