# Auto Zoom grandma3 plugin <img src="docs/assets/naostage-logo-white.svg" alt="drawing" width="120" align="right" height="100%">

AutoZoom keeps a constant beam size on tracked performers: it reads which marker each fixture follows
(from your cues), the marker position (PSN) and the fixture position, and drives zoom and iris.

Requires grandMA3 2.5 or later.

## Installation
1. Copy `out/autozoom-grandma3.lua` and `out/autozoom-grandma3.xml` to `gma3_library/datapools/plugins` (USB stick) or `C:\ProgramData\MALightingTechnology\gma3_library\datapools\plugins` (onPC).
2. Import the plugin and run it. It creates the **AutoZoom** data pool with the **AutoZoom** layout, one `AZ_ZOOM_<fid>` / `AZ_IRIS_<fid>` sequence per fixture and the `AZ_SIZE` sequence. Creating missing sequences clears the programmer.
3. Open the AutoZoom layout in a view.

After loading a show (or a reboot), run the plugin again, or the **AZ Start** macro it creates in the AutoZoom data pool (assign it where you like). The layout texts are only live while AutoZoom runs; until then they show the last values and the buttons do nothing. The AZ Start macro calls the plugin by its name (`Call Plugin "GMA3 Autozoom"`): renaming the plugin breaks it.

Fixtures appear when their fixture type mode has XYZ enabled and a Zoom channel. Set the zoom and iris physical ranges of the fixture type to the manufacturer's optical data.

## Using the layout
- **Arm column**: tap to arm/disarm a fixture. Only armed fixtures are driven.
- **Marker cells**: a lit cell shows the marker the fixture currently follows (green tracking, amber no PSN data, grey disarmed). Tap a cell to put that fixture in the programmer on that marker, with the Setup XYZ offset and zoom/iris at minimum (red **P**); tap it again to send `Off Fixture <fid>`, which removes all of that fixture's values from the programmer.
- **State, Distance, Zoom, Iris**: live values. "Too wide"/"Too small" mean the beam size is outside the fixture's optics.
- **Size**: "Global" follows the `AZ_SIZE` fader (range set in Setup); tap to type a fixed size in metres.
- **Capture**: tap, then select a sequence (pool tile or executor Select key). Confirm the cue number (pre-filled with the running cue). Type another cue number to store elsewhere. The current arms are written into that cue as `Lua "if AZ then AZ:Arm('101,102') end"`; replaying the cue restores them (and does nothing while AutoZoom is not running). If the target sequence is already selected, select another sequence first. Capture works only while AutoZoom is running; it is refused when stopped, and Stop cancels a capture in progress.
- **Setup**: XYZ offset source (preset number or X/Y/Z values), size fader range, refresh rate. XYZ offsets are read relative to the followed marker's Target space (from the show), so they are correct whatever the space size. Marker positions come from PSN trackers (each tracker's MArker ID must be set).
- **Offset**: tap to wait for a preset pick (cell shows "Tap a preset…" with a countdown). Tap a preset within 10 s; any preset is accepted (the pool is not checked, so pick one that holds XYZ values). The cell shows it (e.g. "Preset 2.30", or "DP4 2.30" for a preset of another data pool) and becomes the offset source. Only a plain tap counts: Store, Delete, Label and other commands on a preset are ignored (System Monitor: `Preset pick ignored …`). Oops undoes the tap only when the tap created a new undo entry that is exactly that preset command (e.g. it loaded the preset into the programmer of selected fixtures); otherwise nothing is undone. Tap Offset again to cancel. Works only while AutoZoom runs; Stop also cancels.
- **Colours**: cells are coloured by the AutoZoom appearances (`AZ Tracking`, `AZ Warn`, `AZ No PSN`, `AZ Error`, `AZ Programmer`, `AZ Capture`, `AZ Button`, `AZ Header`, `AZ Idle` in the Appearances pool); run Rescan to recreate a deleted one or reset their colours.
- **Start/Stop**: stopping releases every AutoZoom fader.

## Commands
`Lua "AZ:Start()"`, `Stop()`, `Toggle()`, `Arm('101,102')`, `ArmToggle(101)`, `ArmAll()`, `DisarmAll()`, `Capture()`, `Program(101, 1)`, `Setup()`, `Size(101)`, `Rescan()`, `Status()`.
Run `Rescan()` after changing the patch (fixtures, positions, optics, markers).

## How it works
Each `AZ_ZOOM_<fid>` sequence holds zoom at maximum; its Temp fader crossfades from the cue's zoom (minimum) to it. Iris works the same way when the beam must be smaller than the minimum zoom allows.

## Developing
`npm install`, then `npm run build`. Tests: `npm test` (needs `lua` 5.3+ on the PATH; on NixOS `nix shell nixpkgs#nodejs_22 nixpkgs#lua5_4`). Design: `docs/superpowers/specs/2026-10-03-autozoom-layout-ux-design.md`. Prototype: `docs/prototype/autozoom-layout-prototype.html`.
