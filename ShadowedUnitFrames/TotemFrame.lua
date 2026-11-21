-- Tinkerbox section, Shadowed Unit Frames: the game's own totem bar (each
-- totem's time left, right-click to destroy it) back on screen.
--
-- SUF hides the game's player frame by moving it into a hidden frame of its
-- own, and the totem bar (TotemFrame) is inside the player frame, so it goes
-- too. This moves TotemFrame out into a holder frame of ours, placed under
-- SUF's player frame until you move it. Only its parent and position are
-- changed: the game still runs it, so its timers and right-click work as
-- before. Switched off, it goes back where it was.
--
-- The game may call layout methods on the totem bar's parent (the player
-- frame's containers have them), so the holder has empty ones. Its position
-- is only ever changed out of combat.

local _, ns = ...

local M = ns.Section({
    module = "suf",
    key = "sufTotemFrame",
    title = "Default totem bar",
    desc = "Shows the game's own totem bar (time left on each totem, right-click to destroy it),"
        .. " which goes when Shadowed Unit Frames hides the game's player frame. It starts under SUF's player frame;"
        .. " unlock it below to drag it somewhere else.",
})
if not M then
    return
end

local holder = CreateFrame("Frame", "TinkerboxTotemHolder", UIParent)
holder:SetSize(140, 40)
holder:SetMovable(true)
holder:SetClampedToScreen(true)
holder:RegisterForDrag("LeftButton")
holder:Hide()
-- (What the game may call on the totem bar's parent: nothing to lay out here.)
for _, method in ipairs({ "Layout", "MarkDirty", "MarkClean", "UpdateLayout" }) do
    holder[method] = function() end
end

local overlay = holder:CreateTexture(nil, "OVERLAY")
overlay:SetAllPoints()
overlay:SetColorTexture(0.2, 0.8, 0.3, 0.35)
local overlayText = holder:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
overlayText:SetPoint("CENTER")
overlayText:SetText("Totem bar: drag me")
overlay:Hide()
overlayText:Hide()

local taken = false      -- TotemFrame is in our holder
local placing = false    -- we're moving it ourselves (the hooks ignore that)
local waiting = false    -- something to do once combat ends
local original           -- { parent, points } to give it back

local function Totem()
    return _G.TotemFrame
end

local function Blocked(frame)
    return InCombatLockdown() and frame and frame.IsProtected and frame:IsProtected()
end

-- Where the holder goes: where you dragged it, or under SUF's player frame.
local function PlaceHolder()
    if InCombatLockdown() then
        return false
    end
    holder:ClearAllPoints()
    local pos = M:Get("pos")
    if type(pos) == "table" and pos[1] then
        holder:SetPoint(pos[1], UIParent, pos[2] or pos[1], pos[3] or 0, pos[4] or 0)
        return true
    end
    -- (Worked out once from SUF's frame, not anchored to it: that one is
    -- protected, and anchoring would make the holder unmovable in combat.)
    local suf = _G.SUFUnitplayer
    local left, bottom = suf and suf:GetLeft(), suf and suf:GetBottom()
    if left and bottom then
        local scale = suf:GetEffectiveScale() / UIParent:GetEffectiveScale()
        holder:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left * scale, bottom * scale - 4)
    else
        holder:SetPoint("CENTER", UIParent, "CENTER", 0, -180)
    end
    return true
end

local function Attach(totem)
    placing = true
    totem:SetParent(holder)
    totem:ClearAllPoints()
    totem:SetPoint("TOPLEFT", holder, "TOPLEFT", 0, 0)
    placing = false
end

local Take

local frame = CreateFrame("Frame")
local function WaitForCombat()
    waiting = true
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
end

local hooked = false
local function Hook(totem)
    if hooked then
        return
    end
    hooked = true
    -- The game moving it back under the player frame (or re-anchoring it):
    -- put it back in the holder, now or after combat.
    hooksecurefunc(totem, "SetParent", function(_, parent)
        if taken and not placing and parent ~= holder then
            if Blocked(totem) then
                WaitForCombat()
            else
                Attach(totem)
            end
        end
    end)
    hooksecurefunc(totem, "SetPoint", function()
        if taken and not placing then
            if Blocked(totem) then
                WaitForCombat()
            else
                Attach(totem)
            end
        end
    end)
end

function Take()
    local totem = Totem()
    if not totem then
        M:Fail("this client has no TotemFrame")
        return
    end
    if InCombatLockdown() then
        WaitForCombat()
        return
    end
    if not taken then
        local points = {}
        for i = 1, totem:GetNumPoints() do
            points[i] = { totem:GetPoint(i) }
        end
        original = { parent = totem:GetParent(), points = points }
    end
    PlaceHolder()
    holder:Show()
    Hook(totem)
    taken = true
    Attach(totem)
end

local function GiveBack()
    local totem = Totem()
    if not taken or not totem then
        holder:Hide()
        return
    end
    if InCombatLockdown() then
        WaitForCombat()
        return
    end
    taken = false
    placing = true
    totem:SetParent(original and original.parent or UIParent)
    totem:ClearAllPoints()
    for _, p in ipairs(original and original.points or {}) do
        totem:SetPoint(unpack(p))
    end
    placing = false
    holder:Hide()
end

-- Moving it -------------------------------------------------------------

local unlocked = false

local function SetUnlocked(on)
    unlocked = on and M:IsOn() and not InCombatLockdown()
    overlay:SetShown(unlocked)
    overlayText:SetShown(unlocked)
    holder:EnableMouse(unlocked)
end

holder:SetScript("OnDragStart", function(self)
    if unlocked and not InCombatLockdown() then
        self:StartMoving()
    end
end)
holder:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relPoint, x, y = self:GetPoint(1)
    if point then
        M:Set("pos", { point, relPoint, x, y })
    end
end)

-- Events ----------------------------------------------------------------

local function Update()
    if M:IsOn() then
        Take()
    else
        SetUnlocked(false)
        GiveBack()
    end
end

frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_REGEN_ENABLED" then
        if not waiting then
            return
        end
        waiting = false
        frame:UnregisterEvent("PLAYER_REGEN_ENABLED")
        Update()
    elseif event == "PLAYER_LOGIN" then
        -- (After SUF has hidden the player frame and made its own.)
        C_Timer.After(1, Update)
    else
        Update()
    end
end)

function M:OnToggle()
    Update()
end

-- Options ---------------------------------------------------------------

function M:BuildOptions(body, below)
    local UI = ns.UI
    local unlock = UI.Check(body)
    unlock:SetPoint("TOPLEFT", below, "BOTTOMLEFT", 0, -10)
    local unlockLabel = UI.Text(body, "GameFontHighlight", "Unlock to move (drag the green box)")
    unlockLabel:SetPoint("LEFT", unlock, "RIGHT", 2, 0)
    unlock:SetScript("OnClick", function(self)
        SetUnlocked(self:GetChecked())
        self:SetChecked(unlocked)
    end)

    local reset = UI.Button(body, "Put back under SUF's player frame", 240)
    reset:SetPoint("TOPLEFT", unlock, "BOTTOMLEFT", 4, -6)
    reset:SetScript("OnClick", function()
        M:Set("pos", nil)
        if taken then
            PlaceHolder()
        end
    end)

    -- (Locked again when the settings close, so the box doesn't stay up.)
    body:HookScript("OnHide", function()
        SetUnlocked(false)
        unlock:SetChecked(false)
    end)
    body:HookScript("OnShow", function()
        unlock:SetChecked(unlocked)
        unlock:SetEnabled(M:IsOn())
        reset:SetEnabled(M:IsOn())
    end)
    return 10 + 26 + 6 + 20 + 4
end
