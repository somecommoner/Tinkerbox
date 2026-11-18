-- Tinkerbox module: Graphics. The game's own graphics settings (CVars) that
-- its Graphics menu doesn't show, or doesn't go far enough on. Its sections
-- are the other files in this folder.

local _, ns = ...

ns.Module({
    key = "graphics",
    title = "Graphics",
    desc = "Graphics settings the game's Graphics menu doesn't show, or doesn't go far enough on."
        .. " Nothing changes until you move a setting, and Reset puts back the game's own.",
})
