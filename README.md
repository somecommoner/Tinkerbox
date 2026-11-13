# KinFolk Tweaks

An unofficial companion addon for KinFolk on WoW Forever. It makes small personal changes to KinFolk from outside, without editing KinFolk's files.

## Tweaks

- **No minimap dot for guildmates in your group.** The game already shows party and raid members on the minimap, so KinFolk's dot is a double. Dots come back when they leave the group. KinFolk's world map dots are left alone.

If a KinFolk update changes how it draws dots, the tweak turns itself off and says so once in chat.

## Install

Copy or symlink this folder into `_forever_/Interface/AddOns/KinFolk_Tweaks`. It needs KinFolk.

## Releases

Every push to `main` that changes a `.lua` or `.toc` file publishes a new release, and WowUp picks it up. The version goes up by one each time (0.1.0, 0.1.1, ...). For a bigger jump, set `## Version:` in the `.toc` to the new number in the same push.
