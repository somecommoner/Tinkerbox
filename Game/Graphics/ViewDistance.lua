-- Tinkerbox section, Graphics: how far the land and buildings are drawn, and in
-- how much detail, past the Graphics menu's View Distance.

local _, ns = ...

ns.CVarSection({
    module = "graphics",
    key = "gameViewDistance",
    title = "View distance",
    desc = "How far the world is drawn, and how far out land and buildings keep their full detail."
        .. " Higher costs frame rate, most of all in cities.",
    settings = {
        -- farclip (the far edge of everything) is raised with it, never lowered.
        { cvar = "horizonStart", also = { "farclip" }, label = "View distance", min = 400, max = 24000, step = 400,
          desc = "Where the land gives way to the low-detail horizon. The Graphics menu goes up to 4000." },
        { cvar = "terrainLodDist", label = "Land detail", min = 200, max = 2000, step = 50,
          desc = "How far out the ground keeps its full shape. The Graphics menu goes up to 650." },
        { cvar = "wmoLodDist", label = "Building detail", min = 250, max = 2000, step = 50,
          desc = "How far out buildings keep their full detail. The Graphics menu goes up to 400." },
    },
})
