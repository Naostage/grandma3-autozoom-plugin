# AutoZoom 2.1 console test checklist (grandMA3 onPC 2.5.x)

Tick each line on a copy of a real show. Note the System Monitor output for any failure.

1. [ ] Import and run the plugin: "AutoZoom 2.1.0.0 by Naostage", "Found N fixtures and M markers"; data pool AutoZoom exists with layout, AZ_BASE/AZ_ZOOM/AZ_IRIS per fixture (AZ_BASE priority High, AZ_ZOOM/AZ_IRIS Super), AZ_SIZE.
2. [ ] Layout opens in a view; header shows Running and PSN x/y; one row per XYZ fixture; marker columns by name/CID.
3. [ ] Tap an Arm cell: border turns grey (disarmed); tap again: green.
4. [ ] Tap a marker cell: programmer gets XYZ_MArker, XYZ offset from Setup (no Zoom/Iris values); cell shows red P; tap again releases.
5. [ ] Store a cue with that programmer, clear, play the cue: matrix cell lit green, state Tracking, zoom % changes as the performer moves.
6. [ ] Move AZ_SIZE: beam size follows; set a fixed size on one fixture: it ignores the fader.
7. [ ] Stop the PSN source: state "No PSN data", zoom holds.
8. [ ] Setup: switch offset source to a preset, tap a marker cell: XYZ comes from the preset only.
9. [ ] Save the show, load another show, load it back, run the plugin: arms, sizes and Setup are kept.
10. [ ] Run the plugin twice: only one instance updates (no doubled System Monitor output).
11. [ ] Stop: zoom/iris return to the cue values; layout shows Offline.
12. [ ] Rescan after moving a fixture group: distances change accordingly.
13. [ ] Watch the update rate at 30 Hz with all fixtures armed: no UI stutter.
14. [ ] Layout cell glyphs (●, …, ·, —) render correctly on the console.
15. [ ] Layout cell sequences created inside DataPool 'AutoZoom' run their `Lua "if AZ then AZ:... end"` command when tapped.
    - [ ] Tap the same cell twice: its command runs both times (cell sequences stay running after a tap).
16. [ ] AZ_ZOOM/AZ_IRIS Temp faders move zoom/iris smoothly (FaderTemp readback was inconclusive in the probe).
17. [ ] A marker with a resized/renamed Target space: offsets still match the programmer values.
18. [ ] PSN tracker ISONLINE value when receiving data is recognised (marker header turns green; stop the feed → No PSN data).
19. [ ] Load another show and back without running the plugin: replaying a cue containing `AZ:Arm('…')` and tapping layout buttons raise no Lua error; the AZ Start macro (`Call Plugin "GMA3 Autozoom"`) starts AutoZoom.
20. [ ] Cells show tinted fills (no paper icon); colours follow state (arm, tracking, no PSN, programmer P).
21. [ ] Appearances pool holds the nine AZ appearances at 9001+ once; Rescan neither duplicates nor moves them again.
22. [ ] Setup → Pick preset… opens the preset picker, both while running and while stopped; the first tab is the pool of the current offset preset (else pool 2) and the current preset tile is highlighted.
23. [ ] In the picker, presets without XYZ values are greyed (status "no XYZ") and cannot be tapped.
24. [ ] Tapping an XYZ tile closes the picker and the Setup cell shows "Preset X.Y"; the programmer and the fixture selection are untouched.
25. [ ] Cancel in the picker closes it and changes nothing.
26. [ ] Rescan cell rebuilds the layout while running (no duplicate cells, AutoZoom keeps running).
27. [ ] New fixtures are armed by default: patch a new XYZ fixture, tap Rescan: its Arm cell is green.
28. [ ] The picker's pool tabs switch pools; a pool with many presets scrolls.
29. [ ] Rescan and plugin re-run keep the AutoZoom layout object: a view showing it stays intact; elements you added to the layout yourself are kept.
30. [ ] With AutoZoom off/released, the fixture's zoom and iris are the cue's own values (no forced minimum).
31. [ ] While tracking, firing another cue with zoom/iris values doesn't override AutoZoom.
32. [ ] Disarm a tracking fixture: zoom/iris return to the cue values.
33. [ ] Hold a fixture at a mid zoom (Temp around 50) for a minute: AZ_BASE_<fid> stays On and the zoom stays between min and max.
34. [ ] While tracking, set zoom in the programmer: note whether it overrides (expected: no while the computed zoom is above minimum).
35. [ ] Setup → Layout rows… opens the editor; /\ and \/ reorder lines (disabled at the ends); the trash asks "Remove …?" and No keeps the line.
36. [ ] + opens the picker: Groups and Fixtures tabs, several tiles numbered in tap order, Add appends them in that order; Cancel adds nothing.
37. [ ] Ticks: a fixture listed by itself has a green tick (tile disabled); a fixture only in a listed group has a yellow tick; a listed group has a green tick.
38. [ ] Each change (add, reorder, remove) rebuilds the layout at once, also while running: group rows and fixture rows in list order, group rows without Distance/Zoom/Iris/Size. Closing with the title-bar X keeps the changes.
39. [ ] Tap a marker cell of a group row: every XYZ fixture of the group is in the programmer on that marker with the XYZ offset (check each fixture in the Fixture sheet); the cell shows P; tap again releases them all.
40. [ ] Group Arm cell: shows n/m armed; with one member disarmed a tap arms all, then a tap disarms all.
41. [ ] A fixture left out of the list stops being driven: its zoom/iris return to the cue values.
42. [ ] Delete the group on the console, tap Rescan: the row shows "Group missing" and its taps do nothing (System Monitor: "Group N has no XYZ fixtures").
43. [ ] Remove every line: after Close the layout shows one row per XYZ fixture again.
44. [ ] Change a group's members on the console, tap Rescan: the group row follows (exact fixture IDs).
