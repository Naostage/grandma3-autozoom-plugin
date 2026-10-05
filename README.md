# Auto Zoom grandma3 plugin <img src="docs/assets/naostage-logo-white.svg" alt="drawing" width="120" align="right" height="100%">

AutoZoom keeps a constant beam size on tracked performers: it reads which marker each fixture follows
(from your cues), the marker position (PSN) and the fixture position, and drives zoom and iris.

Requires grandMA3 2.5 or later.

## Installation
1. Delete any previous AutoZoom plugin from the Plugins pool (importing over an existing one can leave it unusable).
2. Copy `out/autozoom-grandma3.lua` and `out/autozoom-grandma3.xml` to `gma3_library/datapools/plugins` (USB stick) or `C:\ProgramData\MALightingTechnology\gma3_library\datapools\plugins` (onPC).
3. Import the plugin and run it. It creates the **AutoZoom** data pool with the **AutoZoom** layout, one `AZ_BASE_<fid>` / `AZ_ZOOM_<fid>` / `AZ_IRIS_<fid>` sequence per fixture and the `AZ_SIZE` sequence. Every run (and Rescan) sets `AZ_BASE_<fid>` to priority High (with OffWhenOverridden No) and `AZ_ZOOM_<fid>` / `AZ_IRIS_<fid>` to Super. These `AZ_` sequences are created only when missing: after changing a fixture type's optics (zoom/iris ranges or mode), delete that fixture's `AZ_ZOOM_` / `AZ_IRIS_` / `AZ_BASE_` sequences, then Rescan. Creating missing sequences clears the programmer.
4. Open the AutoZoom layout in a view.

After loading a show (or a reboot), run the plugin again, or the **AZ Start** macro it creates in the AutoZoom data pool (assign it where you like). The layout texts are only live while AutoZoom runs; until then they show the last values and the buttons do nothing. The AZ Start macro calls the plugin by its name (`Call Plugin "GMA3 Autozoom"`): renaming the plugin breaks it.

Fixtures appear when their fixture type mode has XYZ enabled and a Zoom channel. Set the zoom and iris physical ranges of the fixture type to the manufacturer's optical data.

## Using the layout
- **Header**: Status · Start/Stop · Setup · Rescan · AZ_SIZE · message.
- **Arm column**: fixtures are armed by default, including newly patched ones; tap to disarm (exclude) a fixture, tap again to re-arm it. Only armed fixtures are driven.
- **Marker cells**: a lit cell shows the marker the fixture currently follows (green tracking, amber no PSN data, grey disarmed). Tap a cell to put that fixture in the programmer on that marker, with the Setup XYZ offset (red **P**; zoom and iris are not touched); tap it again to send `Off Fixture <fid>`, which removes all of that fixture's values from the programmer.
- **State, Distance, Zoom, Iris**: live values. "Too wide"/"Too small" mean the beam size is outside the fixture's optics.
- **Size**: "Global" follows the `AZ_SIZE` fader (range set in Setup); tap to type a fixed size in metres.
- **Setup**: XYZ offset source (preset number or X/Y/Z values), size fader range, refresh rate. XYZ offsets are read relative to the followed marker's Target space (from the show), so they are correct whatever the space size. Marker positions come from PSN trackers (each tracker's MArker ID must be set).
  **Pick preset…** closes the dialog without applying it and waits for a preset tap (the message cell shows "Tap a preset…" with a countdown). Tap a preset within 10 s; any preset is accepted (the pool is not checked, so pick one that holds XYZ values). It becomes the offset source, shown on the Setup cell (e.g. "Preset 2.30", or "DP4 2.30" for a preset of another data pool). Only a plain tap counts: Store, Delete, Label and other commands on a preset are ignored (System Monitor: `Preset pick ignored …`). Oops undoes the tap only when the tap created a new undo entry that is exactly that preset command (e.g. it loaded the preset into the programmer of selected fixtures); otherwise nothing is undone. Works only while AutoZoom runs; Stop cancels a pick in progress (`PickOffset()` again also cancels).
- **Rescan**: re-reads the patch and rebuilds the layout (also while running).
- **Colours**: each cell is an `AZ …` sequence in the AutoZoom data pool (tapping a cell runs it, so tapped ones show as running), coloured by the AutoZoom appearances (`AZ Tracking`, `AZ Warn`, `AZ No PSN`, `AZ Error`, `AZ Programmer`, `AZ Capture`, `AZ Button`, `AZ Header`, `AZ Idle`) stored in the Appearances pool from number 9001 up; run Rescan to recreate a deleted one or reset their colours.
- **Start/Stop**: stopping releases every AutoZoom fader.

## Commands
`Lua "AZ:Start()"`, `Stop()`, `Toggle()`, `Arm('101,102')`, `ArmToggle(101)`, `ArmAll()`, `DisarmAll()`, `PickOffset()`, `Program(101, 1)`, `Setup()`, `Size(101)`, `Rescan()`, `Status()`.
Run `Rescan()` (or tap the Rescan cell) after changing the patch (fixtures, positions, optics, markers). `Arm('101,102')` arms exactly the listed fixtures and disarms the others (usable in a cue or macro as `Lua "if AZ then AZ:Arm('101,102') end"`).

## When does AutoZoom drive a fixture?
AutoZoom does not need you to tell it who a fixture is lighting: it reads what the desk is already outputting. Several times a second (30 by default, set in Setup) it checks every AutoZoom fixture:

1. **Is it an AutoZoom fixture?** Its fixture type mode has XYZ enabled and a Zoom channel (found by the patch scan at start and on Rescan).
2. **Is it aiming at a performer?** AutoZoom reads the fixture's live **`XYZ_MArker`** value, the marker your cue (or the programmer) points it at, exactly as the desk outputs it, whichever cue or playback set it. `0` means "not following a marker". Any other value is a marker's CID.
3. **Where is that performer?** The marker's position comes from the **PSN tracker** whose MArker ID is that CID. A tracker only counts while it is online (receiving data).
4. **Where exactly to aim?** The aim point is the marker position plus the fixture's live **`XYZ_X/Y/Z`** offset (read in the marker's Target space), e.g. 0.3 m above the head. The distance is measured from the fixture's patch position (including the position of the group it sits in).
5. **What beam size?** The fixture's fixed size if you set one, otherwise the `AZ_SIZE` fader mapped to the Setup range. AutoZoom computes the beam angle for that size at that distance, sets zoom, and closes the iris further when the beam must be smaller than the minimum zoom allows.

What happens, per fixture:

| Situation | State shown | AutoZoom |
|---|---|---|
| Armed, follows a marker, PSN online | Tracking (or Too wide / Too small when the size is outside the optics) | **Drives** zoom/iris: turns `AZ_BASE_<fid>` On, then sets the zoom/iris Temp faders, updating them as the performer moves |
| Armed, follows a marker, tracker offline | No PSN data | Holds the last zoom/iris |
| Armed, `XYZ_MArker` = 0 | Armed · no marker | Releases: the cue's own zoom/iris apply |
| Follows a CID that no patched MArker has | Unknown marker | Releases |
| Disarmed, or AutoZoom stopped | Disarmed / Offline | Releases |

So a cue triggers AutoZoom simply by setting a fixture's MArker: when a cue gives the fixture a marker, AutoZoom takes over its zoom and iris on the next update; when a cue sets the MArker back to 0 (or AutoZoom is stopped, or the fixture is disarmed), AutoZoom lets go and your cue's zoom and iris come back.

## How it works (zoom/iris sequences)
AutoZoom owns the zoom/iris range of each fixture it drives:
- `AZ_BASE_<fid>` (priority High) holds zoom, and iris if the fixture has one, at their physical minimum. AutoZoom turns it On when it starts driving the fixture and Off when it releases it (Stop, disarm, no marker).
- `AZ_ZOOM_<fid>` (priority Super) holds zoom at maximum; its Temp fader crossfades from the base minimum to it. `AZ_IRIS_<fid>` works the same way for iris when the beam must be smaller than the minimum zoom allows.

While AutoZoom drives a fixture, other cues can't override its zoom and iris. While the Temp fader is above 0 the Super `AZ_ZOOM`/`AZ_IRIS` sequences also win over the programmer; at the minimum only the High base holds the value, so programmer values may win there. When AutoZoom releases the fixture (Stop, disarm, no marker, removed from the patch, loop ended), the cue's own zoom/iris values apply again.

If AutoZoom ever leaves zoom/iris stuck, run the plugin again (or the AZ Start macro) — it releases everything — or switch the `AZ_ZOOM_` / `AZ_IRIS_` / `AZ_BASE_` sequences Off. Tap-to-program sets only the marker and the XYZ offset; your cues need no zoom/iris minimum.

## Developing
`npm install`, then `npm run build`. Tests: `npm test` (needs `lua` 5.3+ on the PATH; on NixOS `nix shell nixpkgs#nodejs_22 nixpkgs#lua5_4`). Design: `docs/superpowers/specs/2026-10-03-autozoom-layout-ux-design.md`. Prototype: `docs/prototype/autozoom-layout-prototype.html`.
