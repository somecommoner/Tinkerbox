-- Tinkerbox module, Game: ground clutter (grass, flowers, small stones)
-- past what the Graphics menu's Ground Clutter slider allows.
-- Ranges as tested on WoW Forever (the Graphics menu's most in brackets).

local _, ns = ...

ns.CVarModule({
    key = "gameGroundClutter",
    title = "Ground clutter",
    desc = "Grass, flowers and small stones: thicker and further out than the Graphics menu allows."
        .. " Changing the menu's Ground Clutter afterwards keeps these.",
    changes = "The game's own settings",
    settings = {
        { cvar = "groundEffectDensity", label = "Density", min = 16, max = 256, step = 8,
          desc = "How thickly it grows. The Graphics menu goes up to 48; past 256 nothing changes." },
        { cvar = "groundEffectDist", label = "Distance", min = 40, max = 500, step = 20,
          desc = "How far out it's drawn, in yards. The Graphics menu goes up to 320." },
        { cvar = "groundEffectFade", label = "Fade start", min = 0, max = 500, step = 10,
          desc = "Where it starts thinning out towards the distance. The menu always uses 70." },
    },
})
