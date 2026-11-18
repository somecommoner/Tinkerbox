-- Tinkerbox section, Graphics: shadow resolution past the Graphics menu's.

local _, ns = ...

ns.CVarSection({
    module = "graphics",
    key = "gameShadows",
    title = "Shadows",
    desc = "Sharper shadow edges than the Graphics menu's Shadow Quality gives. 4096 costs video memory.",
    settings = {
        { cvar = "shadowTextureSize", label = "Shadow resolution", values = { 512, 1024, 1536, 2048, 4096 },
          desc = "The Graphics menu goes up to 2048." },
    },
})
