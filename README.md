# Tinkerbox

Small personal fixes for WoW Forever and for other add-ons, made from outside them, without editing anyone else's files. Each module has its own page in Options > AddOns > Tinkerbox (`/tinkerbox` opens it), and only runs when the add-ons it changes are loaded.

## Tweaks

### Game

The game's own settings (CVars) that its options menu doesn't show, or doesn't go far enough on. Nothing changes until you move a slider. A moved setting is kept: the Graphics menu rewrites many of these when it changes, and Tinkerbox puts yours back. **Reset** on a row, or switching the module off, puts back what the game had. Settings this client doesn't have are left off the page.

- **Ground clutter.** Grass density, distance and fade start.
- **View distance.** How far the world is drawn (`farclip` is raised along with it, never lowered), and land and building detail distance.
- **Objects and creatures.** Object detail and fade, the small-object cut-off, creature detail distance.
- **Shadows.** Shadow resolution up to 4096.
- **Sharpening.** Always run the FSR sharpening pass, and its strength.
- **Screen effects.** Full-screen glow, the grey screen when dead, the nether effect, footprints.
- **Camera and nameplates.** Max camera zoom (up to 4) and nameplate distance (up to 100 yards; waits for combat to end).
- **Spell queue and looting.** Spell queue window and auto loot delay.

### KinFolk

- **KinFolk party dots.** No KinFolk dot for guildmates in your group. The game already shows party and raid members on the minimap and world map, so KinFolk's dot is a double. This applies to both maps, and dots come back when they leave the group. KinFolk's zone count markers on the world map are left alone.
- **KinFolk + OneForAll dots.** OneForAll's "Guild members" option also puts guildmates on the world map, so anyone running both add-ons showed twice. Their OneForAll dot is left out and the KinFolk one stays. Guildmates who only have OneForAll (or OpenMap) still show through OneForAll.

If a KinFolk or OneForAll update changes what these rely on, they turn themselves off and say so once in chat and on their settings page.

## Design rules

1. **Modular.** Each tweak is a module in its own file, in a folder named after the add-on it changes (`KinFolk/`, ...; `Game/` for WoW itself). Modules don't reach into each other. Code that several modules for the same add-on share goes in a helper file in that folder (like `KinFolk/Pins.lua`, or `Game/CVars.lua`, which turns a list of CVars into a module with its page), with no switch of its own. Shared page widgets are in `Core/Widgets.lua`.
2. **Its own settings page.** Every module registers with `ns.Module{ key, title, desc, needs }` and gets its own page under Options > AddOns > Tinkerbox, with an Enabled switch and room for its own options (`BuildOptions`, `M:Get`, `M:Set`). The Tinkerbox page lists every module and its state.
3. **Only when its add-ons are loaded.** `needs` lists the add-ons a module changes, and `ns.Module` returns nil when any of them is missing; the module then stops. Those add-ons also go in `## OptionalDeps` in `Tinkerbox.toc`, so they load first. Tinkerbox itself requires nothing.
4. **Switches apply at once.** `OnToggle` must turn the tweak on or off without a reload. Wrappers check `M:IsOn()` each time they run.
5. **Never edit other add-ons' files.** Change them from outside (their globals, shared libraries, hooks). If one looks different after an update, `M:Fail(why)` turns that module off and says so once in chat and on its page.

## Adding a module

1. Make `Folder/Name.lua`, starting with `local M = ns.Module({ ... })` and `if not M then return end`.
2. List the file in `Tinkerbox.toc` (after any helper it uses), and add its add-ons to `## OptionalDeps`.
3. Give it an `OnToggle`, and `BuildOptions` if it has settings beyond on and off.

## Install

In WowUp, "Install from URL" with this repo's URL. Or copy or symlink this folder into `_forever_/Interface/AddOns/Tinkerbox`.

## Releases

Every push to `main` that changes a `.lua` or `.toc` file publishes a new release, and WowUp picks it up. The version goes up by one each time (0.2.0, 0.2.1, ...). For a bigger jump, set `## Version:` in the `.toc` to the new number in the same push.
