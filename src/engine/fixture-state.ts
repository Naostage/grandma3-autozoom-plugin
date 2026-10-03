/** @noSelfInFile */

import { beamFor, Optics } from "./beam";
import { add, distance, rotate, Vec3 } from "./vec";

export type StateKind = "offline" | "disarmed" | "no-marker" | "unknown-marker" | "no-psn" | "tracking" | "too-wide" | "too-small";
export type FaderOutput = { kind: "release" } | { kind: "hold" } | { kind: "set"; zoom: number; iris?: number };
export interface MarkerSample { pos: Vec3; rot?: Vec3; live: boolean }
export interface FixtureInput {
    running: boolean; armed: boolean; markerCid: number; offset: Vec3;
    fixturePos: Vec3; optics: Optics; size: number; marker?: MarkerSample;
}
export interface FixtureResult {
    state: StateKind; output: FaderOutput; aim?: Vec3; distance?: number; achieved?: number; zoom?: number; iris?: number;
}

const RELEASE: FaderOutput = { kind: "release" };

export function evaluate(i: FixtureInput): FixtureResult {
    if (!i.running) return { state: "offline", output: RELEASE };
    if (!i.armed) return { state: "disarmed", output: RELEASE };
    if (i.markerCid === 0) return { state: "no-marker", output: RELEASE };
    if (!i.marker) return { state: "unknown-marker", output: RELEASE };
    if (!i.marker.live) return { state: "no-psn", output: { kind: "hold" } };
    const offset = i.marker.rot !== undefined ? rotate(i.offset, i.marker.rot) : i.offset;
    const aim = add(i.marker.pos, offset);
    const d = distance(i.fixturePos, aim);
    const beam = beamFor(d, i.size, i.optics);
    const state: StateKind = beam.fit === "ok" ? "tracking" : beam.fit;
    return {
        state, aim, distance: d, achieved: beam.achieved, zoom: beam.zoom, iris: beam.iris,
        output: { kind: "set", zoom: beam.zoom, iris: beam.iris },
    };
}
