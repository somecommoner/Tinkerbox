-- Tinkerbox section, Game settings: nameplate distance past the options
-- menu's limit. (Was part of "Camera and nameplates"; Core moves its saved
-- value over.)

local _, ns = ...

ns.CVarSection({
    module = "game",
    key = "gameNameplates",
    title = "Nameplates",
    desc = "See nameplates from further away.",
    settings = {
        { cvar = "nameplateMaxDistance", label = "Nameplate distance", min = 10, max = 100, step = 5, secure = true,
          desc = "How far away nameplates show, in yards. Can't change in combat; it waits." },
    },
})
