-- Tinkerbox core: chat output, "is this add-on loaded", saved settings, and
-- the modules and sections the settings pages are built from
-- (Core/Options.lua).
--
-- Two levels:
--   * A module is one area Tinkerbox changes: the game's graphics, the
--     game's other settings, or one add-on (KinFolk, OneForAll, ...). It has
--     an on/off switch on the Tinkerbox page and its own settings page.
--     Defined with ns.Module in a file named after it, in a folder named
--     after what it changes (Game/Graphics/Graphics.lua, KinFolk/KinFolk.lua).
--   * A section is one tweak inside a module, in its own file next to the
--     module's. It has its own on/off switch and options, shown as a
--     collapsible part of the module's page. Defined with ns.Section; if an
--     add-on it needs isn't loaded it gets nil back and stops there.
-- A section runs only while both its own switch and its module's are on.

local _, ns = ...

ns.modules = {}         -- in .toc order
local moduleByKey = {}
local sectionByKey = {}

function ns.Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99Tinkerbox|r: " .. message)
end

-- Add-ons named in the .toc's OptionalDeps load before Tinkerbox, so this
-- is already right while Tinkerbox's own files run.
function ns.Loaded(addon)
    local isLoaded = (C_AddOns and C_AddOns.IsAddOnLoaded) or IsAddOnLoaded
    return isLoaded ~= nil and isLoaded(addon) and true or false
end

-- Saved settings (TinkerboxDB):
--   modules[key]  = { enabled = false }  a module's switch
--   sections[key] = { enabled = false, ... }  a section's switch and options
--   open[key]     = true                 a section left expanded
-- They arrive after Tinkerbox's files have run, so everything reads them
-- when it acts (IsOn(), Get()), never once at load.
local DB_VERSION = 2

-- Before version 2 each tweak was a module of its own: TinkerboxDB.modules
-- held what are now sections, under the same keys.
local function Upgrade(db)
    if db.version == nil and type(db.modules) == "table" then
        db.sections = db.modules
        db.modules = {}
        -- "Camera and nameplates" became two sections.
        local camera = db.sections.gameCamera
        if type(camera) == "table" and db.sections.gameNameplates == nil then
            local plates = { enabled = camera.enabled }
            for _, name in ipairs({ "values", "before", "written" }) do
                if type(camera[name]) == "table" and camera[name].nameplateMaxDistance ~= nil then
                    plates[name] = { nameplateMaxDistance = camera[name].nameplateMaxDistance }
                    camera[name].nameplateMaxDistance = nil
                end
            end
            db.sections.gameNameplates = plates
        end
    end
    db.version = DB_VERSION
end

local function DB()
    if type(TinkerboxDB) ~= "table" then
        TinkerboxDB = {}
    end
    local db = TinkerboxDB
    if db.version ~= DB_VERSION then
        Upgrade(db)
    end
    for _, name in ipairs({ "modules", "sections", "open" }) do
        if type(db[name]) ~= "table" then
            db[name] = {}
        end
    end
    return db
end

local function Saved(kind, key)
    local list = DB()[kind]
    if type(list[key]) ~= "table" then
        list[key] = {}
    end
    return list[key]
end

-- Expanded on its module's page (sections start collapsed).
function ns.IsOpen(key)
    return DB().open[key] == true
end

function ns.SetOpen(key, open)
    DB().open[key] = open or nil
end

local function Missing(addons)
    local missing = {}
    for _, addon in ipairs(addons) do
        if not ns.Loaded(addon) then
            missing[#missing + 1] = addon
        end
    end
    return missing
end

-- Modules ---------------------------------------------------------------

local Module = {}
Module.__index = Module

-- Switched on (every module starts on), and its add-ons are loaded.
function Module:IsOn()
    return self.available and Saved("modules", self.key).enabled ~= false
end

function Module:IsSwitchedOn()
    return Saved("modules", self.key).enabled ~= false
end

-- From the Tinkerbox page or the module's own. Every section switches with
-- it at once (each keeps its own switch for when the module comes back).
function Module:SetOn(on)
    Saved("modules", self.key).enabled = on and true or false
    for _, s in ipairs(self.sections) do
        s:Toggled()
    end
end

-- Add-ons its sections use besides the ones it tweaks (shown as "Uses").
function Module:Uses()
    local uses, seen = {}, {}
    for _, addon in ipairs(self.tweaks) do
        seen[addon] = true
    end
    for _, s in ipairs(self.sections) do
        for _, addon in ipairs(s.needs) do
            if not seen[addon] then
                seen[addon] = true
                uses[#uses + 1] = addon
            end
        end
    end
    return uses
end

-- def = {
--   key = "kinfolk",               -- saved settings key, never change it
--   title = "KinFolk",             -- its name and page name
--   desc = "What it's for, in a sentence.",
--   tweaks = { "KinFolk" },        -- the add-ons it changes (none: the game)
-- }
-- Always returns the module: one whose add-ons are missing is still listed
-- on the Tinkerbox page, as needing them.
function ns.Module(def)
    assert(type(def.key) == "string" and not moduleByKey[def.key], "Tinkerbox: missing or repeated module key")
    local m = setmetatable(def, Module)
    m.tweaks = m.tweaks or {}
    m.missing = Missing(m.tweaks)
    m.available = #m.missing == 0
    m.sections = {}
    moduleByKey[m.key] = m
    ns.modules[#ns.modules + 1] = m
    return m
end

-- Sections --------------------------------------------------------------

local Section = {}
Section.__index = Section

-- Its own switch and its module's are on, and it can run.
function Section:IsOn()
    return self.available and not self.failed and self.module:IsOn()
        and Saved("sections", self.key).enabled ~= false
end

function Section:IsSwitchedOn()
    return Saved("sections", self.key).enabled ~= false
end

-- Tell the section its state may have changed. OnToggle(self, on) must
-- apply it at once: everything switches on and off without a reload.
function Section:Toggled()
    if self.available and not self.failed and self.OnToggle then
        local ok, err = pcall(self.OnToggle, self, self:IsOn())
        if not ok then
            self:Fail(tostring(err))
        end
    end
end

function Section:SetOn(on)
    Saved("sections", self.key).enabled = on and true or false
    self:Toggled()
end

-- The section's own options (shown by its BuildOptions).
function Section:Get(name, default)
    local value = Saved("sections", self.key)[name]
    if value == nil then
        return default
    end
    return value
end

function Section:Set(name, value)
    Saved("sections", self.key)[name] = value
end

-- The add-on it changes looks different (after an update): stop, say so
-- once in chat, and show it on the settings page.
function Section:Fail(why)
    if self.failed then
        return
    end
    self.failed = why or "the add-on it changes looks different"
    ns.Print(self.module.title .. ", " .. self.title .. " is off: " .. self.failed .. ".")
end

-- def = {
--   module = "kinfolk",             -- the module it belongs to (defined first)
--   key = "kinfolkPartyDots",       -- saved settings key, never change it
--   title = "Party dots",           -- its header on the module's page
--   desc = "What it does, in a sentence or two.",
--   needs = { "KinFolk" },          -- add-ons it uses besides its module's
--   OnToggle = function(self, on) end,              -- apply on / off at once
--   BuildOptions = function(self, body, below) return height end, -- optional
-- }
-- Returns the section, or nil when its module's add-ons or its own needs
-- aren't loaded.
function ns.Section(def)
    local m = moduleByKey[def.module]
    assert(m, "Tinkerbox: section for an unknown module")
    assert(type(def.key) == "string" and not sectionByKey[def.key], "Tinkerbox: missing or repeated section key")
    local s = setmetatable(def, Section)
    s.module = m
    s.needs = s.needs or {}
    s.missing = Missing(s.needs)
    s.available = m.available and #s.missing == 0
    sectionByKey[s.key] = s
    m.sections[#m.sections + 1] = s
    return s.available and s or nil
end
