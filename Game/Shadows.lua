-- Tinkerbox module, Game: shadow resolution past the Graphics menu's.

local _, ns = ...

ns.CVarModule({
    key = "gameShadows",
    title = "Shadows",
    desc = "Sharper shadow edges than the Graphics menu's Shadow Quality gives. 4096 costs video memory.",
    changes = "The game's own settings",
    settings = {
        { cvar = "shadowTextureSize", label = "Shadow resolution", values = { 512, 1024, 1536, 2048, 4096 },
          desc = "The Graphics menu goes up to 2048." },
    },
})
