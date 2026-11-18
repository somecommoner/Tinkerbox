-- Tinkerbox section, Game settings: spell queueing and auto loot speed.

local _, ns = ...

ns.CVarSection({
    module = "game",
    key = "gameGameplay",
    title = "Spell queue and looting",
    desc = "How early the next spell can be queued, and how fast auto loot takes items.",
    settings = {
        { cvar = "SpellQueueWindow", label = "Spell queue window", min = 0, max = 400, step = 10,
          desc = "How early (milliseconds) you can press the next spell before the current one ends."
              .. " Lower feels more responsive but leaves less room for lag." },
        { cvar = "autoLootRate", label = "Auto loot delay", min = 0, max = 300, step = 10,
          desc = "Milliseconds between items when auto looting. Lower is faster." },
    },
})
