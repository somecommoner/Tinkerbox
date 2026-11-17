-- Tinkerbox module, Game: full-screen effects and footprints, which the
-- options menu has no switches for.

local _, ns = ...

ns.CVarModule({
    key = "gameScreenEffects",
    title = "Screen effects",
    desc = "Switch off full-screen effects that wash out the picture, and footprints in snow and sand.",
    changes = "The game's own settings",
    settings = {
        { cvar = "ffxGlow", toggle = true, label = "Full-screen glow",
          desc = "The soft bloom over bright areas." },
        { cvar = "ffxDeath", toggle = true, label = "Grey screen when dead",
          desc = "The colour drained from the screen while you are dead." },
        { cvar = "ffxNether", toggle = true, label = "Nether effect",
          desc = "The full-screen nether haze some spells and places use." },
        { cvar = "showfootprintparticles", toggle = true, label = "Footprints",
          desc = "Footprints and dust left behind in snow, sand and mud." },
    },
})
