# Tinkerbox

Small personal fixes for WoW Forever and for other add-ons, made from outside them, without editing anyone else's files.

It's split into **modules**: one for the game's graphics, one for its other settings, and one for each add-on it changes. Options > AddOns > Tinkerbox (`/tinkerbox` opens it) lists every module with its on/off switch and whether the add-ons it changes are loaded. Each module has its own page under that, made of **sections**: one per tweak, each with its own on/off switch, which expand to show what they do and their settings. A section runs only while both it and its module are on.

## Modules

### Graphics

The game's own graphics settings (CVars) that its Graphics menu doesn't show, or doesn't go far enough on. Nothing changes until you move a setting. A moved setting is kept: the Graphics menu rewrites many of these when it changes, and Tinkerbox puts yours back. **Reset** on a row, or switching the section or module off, puts back what the game had. Settings this client doesn't have are left off the page.

- **Ground clutter.** Grass density, distance and fade start.
- **View distance.** How far the world is drawn (`farclip` is raised along with it, never lowered), and land and building detail distance.
- **Objects and creatures.** Object detail and fade, the small-object cut-off, creature detail distance.
- **Shadows.** Shadow resolution up to 4096.
- **Sharpening.** Always run the FSR sharpening pass, and its strength.
- **Screen effects.** Full-screen glow, the grey screen when dead, the nether effect, footprints.
- **HDR.** HDR output, peak brightness (nits), intensity and brightness, from the forum fix for washed-out HDR, fog and light. Intensity and "Use brightness" are either/or.

### Game settings

The game's other settings past what its options menu allows. They work like the Graphics ones.

- **Camera.** Max camera zoom (up to 4).
- **Nameplates.** Nameplate distance (up to 100 yards; waits for combat to end).
- **Spell queue and looting.** Spell queue window and auto loot delay.

### KinFolk

- **Party dots.** No KinFolk dot for guildmates in your group. The game already shows party and raid members on the minimap and world map, so KinFolk's dot is a double. This applies to both maps, and dots come back when they leave the group. KinFolk's zone count markers on the world map are left alone.

### OneForAll

- **Guild dots** (uses KinFolk). OneForAll's "Guild members" option also puts guildmates on the world map, so anyone running both add-ons showed twice. Their OneForAll dot is left out and the KinFolk one stays. Guildmates who only have OneForAll (or OpenMap) still show through OneForAll.

If a KinFolk or OneForAll update changes what these rely on, they turn themselves off and say so once in chat and on their settings page.

## Design rules

1. **Modules and sections.** A module is one area Tinkerbox changes: the game's graphics, the game's other settings, or one add-on. Its files live in a folder named after what it changes (`Game/Graphics/`, `Game/Settings/`, `KinFolk/`, `OneForAll/`): the module file (`ns.Module{ key, title, desc, tweaks }`), then its sections, one tweak per file (`ns.Section{ module, key, title, desc, needs }`). Sections don't reach into each other. Code that several sections share goes in a helper file with no switch of its own (`KinFolk/Pins.lua`, or `Game/CVars.lua`, which turns a list of CVars into a section with its settings). Shared page widgets are in `Core/Widgets.lua`.
2. **Its own page.** Every module gets a page under Options > AddOns > Tinkerbox, with its switch and its sections, each collapsible with its own switch and room for its settings (`BuildOptions`, `S:Get`, `S:Set`). The Tinkerbox page lists every module, its switch, the add-ons it changes and uses and whether they're loaded.
3. **Only when its add-ons are loaded.** A module's `tweaks` lists the add-ons it changes; a section's `needs` lists any others it uses. `ns.Section` returns nil when any of them is missing, and the section stops; it's still listed, as needing them. Those add-ons also go in `## OptionalDeps` in `Tinkerbox.toc`, so they load first. Tinkerbox itself requires nothing.
4. **Switches apply at once.** `OnToggle` must turn the tweak on or off without a reload, and is called for the section's own switch and its module's. Wrappers check `S:IsOn()` each time they run.
5. **Never edit other add-ons' files.** Change them from outside (their globals, shared libraries, hooks). If one looks different after an update, `S:Fail(why)` turns that section off and says so once in chat and on its page.

## Adding a section

1. Make `Folder/Name.lua` in its module's folder, starting with `local S = ns.Section({ module = "...", ... })` and `if not S then return end`.
2. List the file in `Tinkerbox.toc` (after its module file and any helper it uses), and add any new add-ons to `## OptionalDeps`.
3. Give it an `OnToggle`, and `BuildOptions(self, body, below)` (returning its height) if it has settings beyond on and off.

For a new module, add a folder with a module file (`ns.Module{ ... }`) first.

## Install

In WowUp, "Install from URL" with this repo's URL. Or copy or symlink this folder into `_forever_/Interface/AddOns/Tinkerbox`.

## Releases

Every push to `main` that changes a `.lua` or `.toc` file publishes a new release, and WowUp picks it up. The version goes up by one each time (0.2.0, 0.2.1, ...). For a bigger jump, set `## Version:` in the `.toc` to the new number in the same push.
