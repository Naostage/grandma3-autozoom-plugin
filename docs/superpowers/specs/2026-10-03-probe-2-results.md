# grandMA3 2.5.1.0 Probe 2 Results

Probe run on grandMA3 onPC 2.5.1.0 on 2026-10-05. Logs in `spikes/ma3-probe/2.5.1.0_26-10-05T11.19.txt`, `2.5.1.0_26-10-05T11.39.txt`, `2.5.1.0_26-10-05T11.50.txt` (untracked).

## P1

**Observed**

GetAttributeIndex XYZ_X=9, XYZ_Y=10, XYZ_Z=11, XYZ_MArker=13. The raw value is a fraction of the active space: `value = min + (max − min) × raw / 2^24` (16777216).

Examples:
- Without marker (stage space −35…35, −35…35, 0…35): X=1→8628281, Y=2→8867953, Z=0.5→239671
- With XYZ_MArker=1 (MArker 1 Target space −100…100, −100…100, 0…100): X=1→8472495, Y=2→8556379, Z=0.5→83885

**Decision**

No fixed metres-per-raw constant. Convert with the followed marker's Target space (stage space when no marker).

## P2

**Observed**

Rotating the marker does not move the beam. PSN tracker properties: TRACKERID, MARKERID, POSITIONX/Y/Z, SPEEDX/Y/Z, ROTX/ROTY/ROTZ, ISONLINE. (PSN was not configured on that computer: MARKERID=None.)

**Decision**

APPLY_MARKER_ROTATION = false. Tracker rotation properties are ROTX/ROTY/ROTZ.

## P3

**Observed**

Commands accepted ("OK"): `Fixture 101`, `Attribute "XYZ_MArker" At 1`, `Attribute "XYZ_X" At 1`, `Attribute "Zoom" At Absolute Physical 5.5`, `Attribute "Iris" At Absolute Physical 0.109`. The user confirmed on screen. Readback in the same tick is stale (programmer applies a moment later).

**Decision**

Tap-to-program syntax kept as planned.

## P4

**Observed**

`Attribute "XYZ_X" Thru "XYZ_Z" At Preset 2.30` accepted; user confirmed.

**Decision**

Preset syntax kept.

## P5

**Observed**

Commands accepted ("OK"): `Fixture 101`, `Attribute "XYZ_MArker" At 1`, `Attribute "XYZ_X" At 1`, `Attribute "Zoom" At Absolute Physical 5.5`, `Attribute "Iris" At Absolute Physical 0.109`. The user confirmed on screen. Readback in the same tick is stale (programmer applies a moment later).

**Decision**

Tap-to-program syntax kept as planned.

## P6

**Observed**

seq:CurrentChild() returns the running cue; its `no` is 1000 for "Cue 1" (cue numbers stored ×1000). SelectedSequence() works. Sequence properties include CURRENTCUE, LOADEDCUE, CUENO ("1"), CUENAME; no property exposes the cue selected in the Sequence Sheet.

**Decision**

Running cue = CurrentChild().no / 1000. SelectedCue not available (prompt pre-fills the running cue).

## P7

**Observed**

Sequence children are OffCue (no = nil), CueZero (no = 0), Cue 1 (no = 1000), cue 2 (no = 2000). A cue's first child is "Part 0". `part.Command` read/write works and runs on Go (log: "(Sequence 106 'TEST'.Cue 1.Part 0)OK: Lua ..."). `cue.Command` is nil.

**Decision**

Write the cue command on part 0. Match cues by no = cue × 1000. Skip OffCue/CueZero.

## P8

**Observed**

SelectedSequence() changes when tapping sequences in the pool (TEST → Sequence 107 observed).

**Decision**

Capture watches SelectedSequence() as planned.

## P9

**Observed**

Fixture `mode` is the string "2 Mode 2". `ModeDirect` is the mode handle. Fixture 101 POS z=3.71 inside group SPOTS (POS 0, ROT 0) — positions are relative to the parent.

**Decision**

Compose parent transforms. Mode via ModeDirect.name.

## P10

**Observed**

Element at PosY=100 is higher on screen (X right, Y up) → Y_DIR = −1 is correct. Clicking a layout element bound to a macro runs the macro (Go+). GetFader({token="FaderTemp"}) read 0 right after SetFader 33.3 — inconclusive (1.x used FaderTemp in production).

**Decision**

Keep FaderTemp. Verify on the console checklist.

## P11

**Observed**

MessageBox with inputs and selectors returns `{result=1, success=true, inputs={["Offset X (m)"]="0", ...}, selectors={["Offset source"]=2}}`.

**Decision**

setupDialog shape as planned.

## P12

**Observed**

Spaces live in Patch().Stages[i].Spaces (class Space) with properties MINX, MAXX, MINY, MAXY, MINZ, MAXZ (strings like "-35.000"). Each stage has a "Stage" space. Each marker has "MArker N Target" and "MArker N Movement" spaces. The MArker fixture property TARGETSPACE references its target space (shown as "2 'MArker 1 Target'").

**Decision**

Read stage space per fixture and target space per marker during the patch scan.
