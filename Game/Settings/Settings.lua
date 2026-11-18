-- Tinkerbox module: Game settings. The game's own non-graphics settings
-- (CVars) past what its options menu allows. Its sections are the other
-- files in this folder.

local _, ns = ...

ns.Module({
    key = "game",
    title = "Game settings",
    desc = "Camera, nameplate, spell queue and looting settings past what the options menu allows."
        .. " Nothing changes until you move a setting, and Reset puts back the game's own.",
})
