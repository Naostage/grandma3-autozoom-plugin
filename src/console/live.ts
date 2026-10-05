/** @noSelfInFile */
import { vec, Vec3 } from "../engine/vec";
import { fidKey } from "../format";
import { MarkerReadings, PatchFixture, PatchMarker, Space } from "../model";
import { children, num } from "./handles";

// Raw XYZ_X/Y/Z readback is a fraction of the active space (probe P1): metres = min + (max - min) * raw / 2^24.
export const RAW_FULL = 16777216;
export const APPLY_MARKER_ROTATION = false;                       // probe P2: rotation has no effect
export const TRACKER_ROTATION_PROPS = ["ROTX", "ROTY", "ROTZ"];   // probe P2
export const DEFAULT_TARGET_SPACE: Space = { min: vec(-100, -100, 0), max: vec(100, 100, 100) };

export function rawToMetres(raw: number, min: number, max: number): number {
    return min + (max - min) * raw / RAW_FULL;
}

function rt(uich: number): any {
    const r = GetRTChannel(uich);
    return r === undefined ? undefined : r.info;
}

export function readMarkerCid(f: PatchFixture): number {
    const v = num(rt(f.uich.marker)?.value_after_master);
    return v === undefined ? 0 : Math.floor(v);
}

export function readProgrammerCid(f: PatchFixture): number {
    const info = rt(f.uich.marker);
    if (info === undefined || !tostring(info.cue_part).startsWith("Programmer")) return 0;
    return Math.floor(num(info.value_after_master) ?? 0);
}

function axis(uich: number, min: number, max: number): number {
    const raw = num(rt(uich)?.value_after_master);
    return raw === undefined ? 0 : rawToMetres(raw, min, max);
}

export function readOffset(f: PatchFixture, markers: PatchMarker[]): Vec3 {
    const cid = readMarkerCid(f);
    if (cid === 0) return vec(0, 0, 0);
    let space = DEFAULT_TARGET_SPACE;
    for (const m of markers) if (m.cid === cid) { space = m.targetSpace; break; }
    return vec(
        axis(f.uich.x, space.min.x, space.max.x),
        axis(f.uich.y, space.min.y, space.max.y),
        axis(f.uich.z, space.min.z, space.max.z),
    );
}

// Trackers persist while the PSN feed is down; ISONLINE is "" when offline (probe 2 dump).
const ONLINE_WORDS = ["yes", "on", "true", "1"];

export function isOnline(v: unknown): boolean {
    if (v === true || v === 1) return true;
    if (typeof v !== "string") return false;
    return ONLINE_WORDS.indexOf(v.trim().toLowerCase()) >= 0;
}

export function readMarkers(): MarkerReadings {
    const out: MarkerReadings = {};
    for (const system of children(ShowData().PSNProtocol)) {
        for (const tracker of children(system)) {
            const cid = num(tracker.MARKERID);
            if (cid === undefined || cid === 0) continue;
            if (!isOnline(tracker.ISONLINE)) continue;
            const pos = vec(num(tracker.POSITIONX) ?? 0, num(tracker.POSITIONY) ?? 0, num(tracker.POSITIONZ) ?? 0);
            const rot = APPLY_MARKER_ROTATION
                ? vec(num(tracker[TRACKER_ROTATION_PROPS[0]]) ?? 0, num(tracker[TRACKER_ROTATION_PROPS[1]]) ?? 0, num(tracker[TRACKER_ROTATION_PROPS[2]]) ?? 0)
                : undefined;
            out[fidKey(cid)] = { pos, rot };
        }
    }
    return out;
}
