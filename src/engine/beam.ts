/** @noSelfInFile */

// Zoom/iris needed for a beam of `size` metres diameter at `distance` metres.
// Zoom range = full beam angle in degrees; iris range = fraction of the open diameter (GDTF 0..1).

export interface Optics { zoomMin: number; zoomMax: number; irisMin: number; irisMax: number }
export type BeamFit = "ok" | "too-wide" | "too-small";
export interface BeamResult { zoom: number; iris?: number; fit: BeamFit; achieved: number }

function percent(value: number, min: number, max: number): number {
    if (max <= min) return 0;
    const p = (value - min) / (max - min) * 100;
    return Math.round(Math.min(100, Math.max(0, p)) * 10) / 10;
}

function beamAt(angleDeg: number, distance: number): number {
    return 2 * distance * Math.tan(angleDeg * Math.PI / 360);
}

export function beamFor(distance: number, size: number, o: Optics): BeamResult {
    const hasIris = o.irisMax > o.irisMin;
    const full = hasIris ? 100 : undefined;
    if (distance <= 0.001) return { zoom: 100, iris: full, fit: "too-wide", achieved: 0 };
    const angle = Math.atan(size / 2 / distance) * 360 / Math.PI;
    if (angle > o.zoomMax) return { zoom: 100, iris: full, fit: "too-wide", achieved: beamAt(o.zoomMax, distance) };
    if (angle >= o.zoomMin) return { zoom: percent(angle, o.zoomMin, o.zoomMax), iris: full, fit: "ok", achieved: size };
    const atMin = beamAt(o.zoomMin, distance);
    if (!hasIris) return { zoom: 0, iris: undefined, fit: "too-small", achieved: atMin };
    const ratio = size / atMin;
    if (ratio < o.irisMin) return { zoom: 0, iris: 0, fit: "too-small", achieved: atMin * o.irisMin };
    return { zoom: 0, iris: percent(ratio, o.irisMin, o.irisMax), fit: "ok", achieved: size };
}
