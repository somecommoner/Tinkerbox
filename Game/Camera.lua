-- Tinkerbox module, Game: camera zoom and nameplate distance past the
-- options menu's limits.

local _, ns = ...

ns.CVarModule({
    key = "gameCamera",
    title = "Camera and nameplates",
    desc = "Zoom further out, and see nameplates from further away."
        .. " Other add-ons that change the camera (like Cinematic) may move the zoom limit too.",
    changes = "The game's own settings",
    settings = {
        { cvar = "cameraDistanceMaxZoomFactor", label = "Max camera zoom", min = 1, max = 4, step = 0.1, decimals = 1,
          desc = "Times the game's base zoom distance. The options menu goes up to 2.6." },
        { cvar = "nameplateMaxDistance", label = "Nameplate distance", min = 10, max = 100, step = 5, secure = true,
          desc = "How far away nameplates show, in yards. Can't change in combat; it waits." },
    },
})
