-- Tinkerbox module, Game: the FSR sharpening pass, which the game only runs
-- while upscaling (Render Scale below 100%) unless told to.

local _, ns = ...

ns.CVarModule({
    key = "gameSharpening",
    title = "Sharpening",
    desc = "Crisper edges and textures, at full Render Scale too. It sharpens what's there; it doesn't add detail.",
    changes = "The game's own settings",
    settings = {
        { cvar = "ResampleAlwaysSharpen", toggle = true, label = "Always sharpen",
          desc = "Run the sharpening pass even when not upscaling." },
        { cvar = "ResampleSharpness", label = "Sharpness", min = 0, max = 2, step = 0.1, decimals = 1,
          desc = "Lower is sharper: 0 is full strength, 2 the least." },
    },
})
