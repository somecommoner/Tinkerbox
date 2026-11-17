-- Tinkerbox core: chat output, "is this add-on loaded", saved settings, and
-- the module list the settings pages are built from (Core/Options.lua).
--
-- A module is one tweak in its own file, in a folder named after the add-on
-- it changes (KinFolk/, ...; Game/ for WoW itself). It registers with
-- ns.Module first; if an add-on it needs isn't loaded it gets nil back and
-- stops there, and the overview page says what it needs.

local _, ns = ...

ns.modules = {}         -- in .toc order
local byKey = {}

function ns.Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99Tinkerbox|r: " .. message)
end

-- Add-ons named in the .toc's OptionalDeps load before Tinkerbox, so this
-- is already right while Tinkerbox's own files run.
function ns.Loaded(addon)
    local isLoaded = (C_AddOns and C_AddOns.IsAddOnLoaded) or IsAddOnLoaded
    return isLoaded ~= nil and isLoaded(addon) and true or false
end

-- Saved settings, one table per module: TinkerboxDB.modules[key]. They
-- arrive after Tinkerbox's files have run, so modules read them when they
-- act (M:IsOn(), M:Get()), never once at load.
local function Saved(key)
    if type(TinkerboxDB) ~= "table" then
        TinkerboxDB = {}
    end
    if type(TinkerboxDB.modules) ~= "table" then
        TinkerboxDB.modules = {}
    end
    local saved = TinkerboxDB.modules[key]
    if type(saved) ~= "table" then
        saved = {}
        TinkerboxDB.modules[key] = saved
    end
    return saved
end

local Module = {}
Module.__index = Module

-- Switched on (every module starts on), and able to run.
function Module:IsOn()
    return self.available and not self.failed and Saved(self.key).enabled ~= false
end

function Module:IsSwitchedOn()
    return Saved(self.key).enabled ~= false
end

-- From the module's settings page. OnToggle(self, on) must apply the change
-- at once: every module has to switch on and off without a reload.
function Module:SetOn(on)
    Saved(self.key).enabled = on and true or false
    if self.available and not self.failed and self.OnToggle then
        local ok, err = pcall(self.OnToggle, self, self:IsOn())
        if not ok then
            self:Fail(tostring(err))
        end
    end
end

-- A module's own options (shown on its settings page by its BuildOptions).
function Module:Get(name, default)
    local value = Saved(self.key)[name]
    if value == nil then
        return default
    end
    return value
end

function Module:Set(name, value)
    Saved(self.key)[name] = value
end

-- The add-on it changes looks different (after an update): stop, say so
-- once in chat, and show it on the settings pages.
function Module:Fail(why)
    if self.failed then
        return
    end
    self.failed = why or "the add-on it changes looks different"
    ns.Print(self.title .. " is off: " .. self.failed .. ".")
end

-- def = {
--   key = "kinfolkPartyDots",       -- saved settings key, never change it
--   title = "KinFolk party dots",   -- its page name under Tinkerbox
--   desc = "What it does, in a sentence or two.",
--   needs = { "KinFolk" },          -- add-ons that must be loaded
--   changes = "The game's settings", -- shown on its page (default: needs)
--   OnToggle = function(self, on) end,         -- apply on / off at once
--   BuildOptions = function(self, page, below) end, -- optional extra options
-- }
-- Returns the module, or nil when an add-on it needs isn't loaded.
function ns.Module(def)
    assert(type(def.key) == "string" and not byKey[def.key], "Tinkerbox: missing or repeated module key")
    local m = setmetatable(def, Module)
    m.needs = m.needs or {}
    m.missing = {}
    for _, addon in ipairs(m.needs) do
        if not ns.Loaded(addon) then
            m.missing[#m.missing + 1] = addon
        end
    end
    m.available = #m.missing == 0
    byKey[m.key] = m
    ns.modules[#ns.modules + 1] = m
    return m.available and m or nil
end
