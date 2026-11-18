-- Tinkerbox, Game: shared helper, not a section. Makes a section out of a
-- list of the game's own settings (CVars), most of them ones its options
-- menu doesn't show. Used by the Graphics and Game settings modules.
--
-- How a setting behaves:
--   * Left alone, it's the game's own: its slider shows what the game has,
--     and nothing is written.
--   * Moved, it's ours: the game's own value is noted first ("before"),
--     then ours is written, and kept: the game's Graphics menu rewrites many
--     of these when it changes, so after any graphics setting changes ours
--     is put back (and the menu's new value noted as the game's own).
--   * Reset, or the section (or its module) switched off: the game's own
--     is written back.
-- Settings this client doesn't have are left off the page. Ones the game
-- won't change in a fight (secure) wait for it to end.
--
-- def = ns.Section's fields (module = "graphics", ...), plus settings = { {
--   cvar = "groundEffectDensity", label = "Density", desc = "...",
--   min = 16, max = 256, step = 8, decimals = 0,   -- a slider, or
--   values = { 512, 1024, 2048 },                  -- a slider over these, or
--   toggle = true,                                 -- a checkbox (1 on, 0 off)
--   also = { "farclip" },   -- raised to at least the same value with it
--   secure = true,          -- not in a fight
-- }, ... }

local _, ns = ...

local function Get(cvar)
    if C_CVar and C_CVar.GetCVar then
        return C_CVar.GetCVar(cvar)
    end
    return GetCVar(cvar)
end

local function Default(cvar)
    local fn = (C_CVar and C_CVar.GetCVarDefault) or GetCVarDefault
    return fn and fn(cvar)
end

local writing = false
local function Write(cvar, value)
    writing = true
    local fn = (C_CVar and C_CVar.SetCVar) or SetCVar
    pcall(fn, cvar, tostring(value))
    writing = false
end

local function Same(a, b)
    if tonumber(a) and tonumber(b) then
        return math.abs(tonumber(a) - tonumber(b)) < 1e-6
    end
    return tostring(a) == tostring(b)
end

local function Format(value, decimals)
    value = tonumber(value)
    if not value then
        return "?"
    end
    return string.format("%." .. (decimals or 0) .. "f", value)
end

local modules = {}      -- every CVar section, for the shared watcher

function ns.CVarSection(def)
    local settings = def.settings
    def.settings = nil
    local M = ns.Section(def)
    if not M then
        return nil
    end
    M.settings = settings
    modules[#modules + 1] = M

    local function Table(name)
        local t = M:Get(name)
        if type(t) ~= "table" then
            t = {}
            M:Set(name, t)
        end
        return t
    end

    -- Which settings this client has, worked out once at login.
    local present
    local function Present()
        if not present then
            present = {}
            for _, s in ipairs(settings) do
                if Get(s.cvar) ~= nil then
                    present[#present + 1] = s
                end
            end
        end
        return present
    end

    -- One CVar as it should be. wanted: our value, or nil for the game's own.
    -- raiseOnly: written only when above the game's own.
    local function ApplyOne(cvar, wanted, raiseOnly)
        local before, written = Table("before"), Table("written")
        local now = Get(cvar)
        if now == nil then
            return
        end
        if before[cvar] ~= nil and written[cvar] ~= nil and not Same(now, written[cvar]) then
            -- Changed since we wrote it (the Graphics menu): the game's own now.
            before[cvar] = now
        end
        if wanted ~= nil then
            if before[cvar] == nil then
                before[cvar] = now
            end
            if raiseOnly and (tonumber(wanted) or 0) <= (tonumber(before[cvar]) or 0) then
                wanted = nil
            end
        end
        if wanted ~= nil then
            if not Same(now, wanted) then
                Write(cvar, wanted)
            end
            written[cvar] = Get(cvar)   -- what the game kept (it may cap it)
        elseif before[cvar] ~= nil then
            if not Same(now, before[cvar]) then
                Write(cvar, before[cvar])
            end
            before[cvar], written[cvar] = nil, nil
        end
    end

    local waiting = false   -- a secure one is waiting for the fight to end
    function M:Apply()
        local values = Table("values")
        waiting = false
        for _, s in ipairs(Present()) do
            if s.secure and InCombatLockdown() then
                waiting = true
            else
                local wanted = M:IsOn() and values[s.cvar] or nil
                ApplyOne(s.cvar, wanted, false)
                for _, other in ipairs(s.also or {}) do
                    ApplyOne(other, wanted, true)
                end
            end
        end
    end

    function M:Waiting()
        return waiting
    end

    function M:OnToggle()
        M:Apply()
    end

    -- Our value, or nil while it's the game's own.
    function M:Value(s)
        return Table("values")[s.cvar]
    end

    function M:SetValue(s, value)
        Table("values")[s.cvar] = value
        M:Apply()
    end

    function M:Watches(name)
        for _, s in ipairs(settings) do
            if s.cvar:lower() == name then
                return true
            end
            for _, other in ipairs(s.also or {}) do
                if other:lower() == name then
                    return true
                end
            end
        end
        return false
    end

    M.BuildOptions = function(self, page, below)
        return ns.BuildCVarRows(self, page, below, Present(), Get, Default, Format)
    end

    return M
end

-- The rows in a CVar section: label, value, slider or checkbox, and a Reset
-- button while the value is ours. Returns their height.
function ns.BuildCVarRows(M, page, below, list, Get, Default, Format)
    local UI = ns.UI
    local refreshers = {}
    local function RefreshAll()
        for _, fn in ipairs(refreshers) do
            fn()
        end
    end

    local anchor, gap = below, -18
    local height = 0
    if #list == 0 then
        local none = UI.Text(page, "GameFontDisable", "This client has none of these settings.")
        none:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 4, gap)
        return -gap + 14
    end
    for _, s in ipairs(list) do
        local row = CreateFrame("Frame", nil, page)
        row:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", anchor == below and 4 or 0, gap)
        row:SetPoint("RIGHT", page, "RIGHT", -16, 0)
        row:SetHeight(s.toggle and 40 or 52)

        local label = UI.Text(row, "GameFontNormal", s.label)
        local value = UI.Text(row, "GameFontHighlight")
        local reset = UI.Button(row, "Reset", 70)
        reset:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, 2)
        local desc = UI.Text(row, "GameFontHighlightSmall")
        desc:SetTextColor(0.7, 0.7, 0.7)
        desc:SetPoint("RIGHT", reset, "LEFT", -12, 0)
        local default = Default(s.cvar)
        local defaultText = default and ("Game default: " .. (s.toggle and (tonumber(default) == 1 and "on" or "off")
            or Format(default, s.decimals))) or ""
        desc:SetText((s.desc or "") .. (defaultText ~= "" and ("  |cff909090" .. defaultText .. "|r") or ""))

        local Refresh
        if s.toggle then
            local check = ns.UI.Check(row)
            check:SetPoint("TOPLEFT", row, "TOPLEFT", -4, 4)
            label:SetPoint("LEFT", check, "RIGHT", 2, 1)
            desc:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -4)
            check:SetScript("OnClick", function(self)
                M:SetValue(s, self:GetChecked() and 1 or 0)
                RefreshAll()
            end)
            Refresh = function()
                local v = M:Value(s)
                if v == nil then
                    v = Get(s.cvar)
                end
                check:SetChecked(tonumber(v) == 1)
                check:SetEnabled(M:IsOn())
            end
        else
            label:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
            value:SetPoint("LEFT", label, "RIGHT", 8, 0)
            local slider = UI.Slider(row, 240)
            slider:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 2, -8)
            desc:SetPoint("TOPLEFT", slider, "TOPRIGHT", 16, 4)
            local values = s.values
            if values then
                slider:SetMinMaxValues(1, #values)
                slider:SetValueStep(1)
            else
                slider:SetMinMaxValues(s.min, s.max)
                slider:SetValueStep(s.step)
            end
            local function Shown(v)
                v = tonumber(v)
                if values and v then
                    local best = 1
                    for i, option in ipairs(values) do
                        if math.abs(option - v) < math.abs(values[best] - v) then
                            best = i
                        end
                    end
                    return best
                end
                return v
            end
            local quiet = false
            slider:SetScript("OnValueChanged", function(_, raw, userInput)
                if quiet or userInput == false then
                    return
                end
                local v
                if values then
                    v = values[math.floor(raw + 0.5)]
                else
                    v = math.floor(raw / s.step + 0.5) * s.step
                    v = tonumber(Format(v, s.decimals))
                end
                value:SetText(Format(v, s.decimals))
                M:SetValue(s, v)
                reset:Show()
            end)
            Refresh = function()
                local v = M:Value(s)
                if v == nil then
                    v = Get(s.cvar)
                end
                quiet = true
                slider:SetValue(Shown(v) or s.min or 1)
                quiet = false
                value:SetText(Format(v, s.decimals))
                slider:SetEnabled(M:IsOn())
            end
        end

        reset:SetScript("OnClick", function()
            M:SetValue(s, nil)
            RefreshAll()
        end)
        local inner = Refresh
        Refresh = function()
            inner()
            local ours = M:Value(s) ~= nil
            reset:SetShown(ours)
            value:SetTextColor(ours and 0.4 or 1, ours and 1 or 1, ours and 0.4 or 1)
        end
        refreshers[#refreshers + 1] = Refresh
        height = height - gap + (s.toggle and 40 or 52)
        anchor, gap = row, -12
    end
    page:HookScript("OnShow", RefreshAll)
    M.RefreshOptions = RefreshAll
    RefreshAll()
    return height
end

-- One watcher for every CVar section: at login, after a fight (for the ones
-- that waited), and shortly after a graphics setting or one of ours changes
-- (the Graphics menu writes several at once), put ours back.
local pending = false
local function ApplyAll()
    pending = false
    for _, M in ipairs(modules) do
        if M.available and not M.failed then
            local ok, err = pcall(M.Apply, M)
            if not ok then
                M:Fail(tostring(err))
            end
        end
    end
end

local function Changed(name)
    if writing or pending or type(name) ~= "string" then
        return
    end
    name = name:lower()
    local ours = name:find("^graphics") ~= nil
    if not ours then
        for _, M in ipairs(modules) do
            if M:Watches(name) then
                ours = true
                break
            end
        end
    end
    if ours then
        pending = true
        C_Timer.After(0.5, ApplyAll)
    end
end

if C_CVar and C_CVar.SetCVar then
    hooksecurefunc(C_CVar, "SetCVar", Changed)
end
if SetCVar then
    hooksecurefunc("SetCVar", Changed)
end

local watcher = CreateFrame("Frame")
watcher:RegisterEvent("PLAYER_LOGIN")
watcher:RegisterEvent("PLAYER_REGEN_ENABLED")
watcher:RegisterEvent("CVAR_UPDATE")
watcher:SetScript("OnEvent", function(_, event, name)
    if event == "CVAR_UPDATE" then
        Changed(name)
    elseif event == "PLAYER_REGEN_ENABLED" then
        for _, M in ipairs(modules) do
            if M:Waiting() then
                ApplyAll()
                return
            end
        end
    else
        ApplyAll()
    end
end)
