# AutoZoom 2.0 console test checklist (grandMA3 onPC 2.5.x)

Tick each line on a copy of a real show. Note the System Monitor output for any failure.

1. [ ] Import and run the plugin: "AutoZoom 2.0.0", "Found N fixtures and M markers"; data pool AutoZoom exists with layout, AZ_ZOOM/AZ_IRIS per fixture, AZ_SIZE.
2. [ ] Layout opens in a view; header shows Running and PSN x/y; one row per XYZ fixture; marker columns by name/CID.
3. [ ] Tap an Arm cell: border turns green; tap again: grey.
4. [ ] Tap a marker cell: programmer gets XYZ_MArker, XYZ offset from Setup, zoom/iris minimum; cell shows red P; tap again releases.
5. [ ] Store a cue with that programmer, clear, play the cue: matrix cell lit green, state Tracking, zoom % changes as the performer moves.
6. [ ] Move AZ_SIZE: beam size follows; set a fixed size on one fixture: it ignores the fader.
7. [ ] Stop the PSN source: state "No PSN data", zoom holds.
8. [ ] Capture: tap, select the sequence, confirm the running cue: cue command contains `Lua "if AZ then AZ:Arm('…') end"`; disarm all, replay the cue: arms restored.
9. [ ] Capture into the running cue, and into another cue by typing its number in the prompt.
10. [ ] Setup: switch offset source to a preset, tap a marker cell: XYZ comes from the preset only.
11. [ ] Save the show, load another show, load it back, run the plugin: arms, sizes and Setup are kept.
12. [ ] Run the plugin twice: only one instance updates (no doubled System Monitor output).
13. [ ] Stop: zoom/iris return to the cue values; layout shows Offline.
14. [ ] Rescan after moving a fixture group: distances change accordingly.
15. [ ] Watch the update rate at 30 Hz with all fixtures armed: no UI stutter.
16. [ ] Layout cell glyphs (●, …, ·, —) render correctly on the console.
17. [ ] Layout macro buttons created inside DataPool 'AutoZoom' run their `Lua "if AZ then AZ:... end"` command when tapped.
18. [ ] AZ_ZOOM/AZ_IRIS Temp faders move zoom/iris smoothly (FaderTemp readback was inconclusive in the probe).
19. [ ] A marker with a resized/renamed Target space: offsets still match the programmer values.
20. [ ] PSN tracker ISONLINE value when receiving data is recognised (marker header turns green; stop the feed → No PSN data).
21. [ ] Load another show and back without running the plugin: replaying a captured cue and tapping layout buttons raise no Lua error; the AZ Start macro (`Call Plugin "GMA3 Autozoom"`) starts AutoZoom.
