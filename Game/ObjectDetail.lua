-- Tinkerbox module, Game: how long objects (trees, fences, crates) and
-- creatures keep their detail, and how soon small things pop out.

local _, ns = ...

ns.CVarModule({
    key = "gameObjectDetail",
    title = "Objects and creatures",
    desc = "Less pop-in: objects and creatures keep their detail further out, and small things stay visible longer.",
    changes = "The game's own settings",
    settings = {
        { cvar = "doodadLodScale", label = "Object detail", min = 50, max = 300, step = 10,
          desc = "How far out trees, fences and crates keep full detail. The Graphics menu goes up to 150." },
        { cvar = "lodObjectFadeScale", label = "Object fade", min = 50, max = 600, step = 25,
          desc = "How far out objects fade away. The Graphics menu goes up to 150." },
        { cvar = "lodObjectCullSize", label = "Small object cut-off", min = 4, max = 30, step = 1,
          desc = "Lower keeps small distant objects visible longer. Guides suggest 8." },
        { cvar = "entityLodDist", label = "Creature detail", min = 5, max = 1000, step = 5,
          desc = "How far out creatures and players keep full detail. The Graphics menu uses 10." },
    },
})
