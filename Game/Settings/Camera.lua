-- Tinkerbox section, Game settings: camera zoom past the options menu's limit.

local _, ns = ...

ns.CVarSection({
    module = "game",
    key = "gameCamera",
    title = "Camera",
    desc = "Zoom further out. Other add-ons that change the camera (like Cinematic) may move the zoom limit too.",
    settings = {
        { cvar = "cameraDistanceMaxZoomFactor", label = "Max camera zoom", min = 1, max = 4, step = 0.1, decimals = 1,
          desc = "Times the game's base zoom distance. The options menu goes up to 2.6." },
    },
})
