/** @noSelfInFile */
import { FixtureResult, StateKind } from "../engine/fixture-state";
import { Vec3 } from "../engine/vec";
import { fidKey, fmtInt, fmtNum } from "../format";
import { AppearanceKind, CellSpec, MarkerReadings, PatchFixture, PatchMarker, Views } from "../model";

export const COLORS = {
    on: "3ECF6EFF", warn: "E8C547FF", bad: "E5534BFF", idle: "5B6573FF",
    accent: "F5A623FF", text: "E6E8EBFF", muted: "8E96A3FF",
};
export const APPEARANCES: { [kind: string]: { name: string; rgba: string } } = {
    tracking: { name: "AZ Tracking", rgba: "137A38E0" },
    warn: { name: "AZ Warn", rgba: "7A6A10D9" },
    nopsn: { name: "AZ No PSN", rgba: "85520AD9" },
    error: { name: "AZ Error", rgba: "851F1AD9" },
    programmer: { name: "AZ Programmer", rgba: "8F211CE6" },
    capture: { name: "AZ Capture", rgba: "B8650FE0" },
    button: { name: "AZ Button", rgba: "24283AE0" },
    header: { name: "AZ Header", rgba: "171C3DB8" },
    idle: { name: "AZ Idle", rgba: "10121CD9" },
};
export const GRID = { w: 130, markerW: 70, h: 64, gap: 6 };
export const Y_DIR = -1; // layout "down" direction (probe P10)

export interface HeaderState { running: boolean; captureSecondsLeft?: number; pickSecondsLeft?: number; liveMarkers: number; globalSize: number; offsetLabel: string; message: string }
export interface RowState {
    fixture: PatchFixture; armed: boolean; markerCid: number; programmerCid: number; offset: Vec3;
    result: FixtureResult; size: number; sizeFixed: boolean;
}

const LABELS: { [state: string]: string } = {
    "offline": "Offline", "disarmed": "Disarmed", "no-marker": "Armed · no marker", "unknown-marker": "Unknown marker",
    "no-psn": "No PSN data", "tracking": "Tracking", "too-wide": "Too wide", "too-small": "Too small",
};

export function stateLabel(state: StateKind): string {
    return LABELS[state];
}

function signed(n: number): string {
    return (n >= 0 ? "+" : "") + fmtNum(n);
}

export function layoutCells(fixtures: PatchFixture[], markers: PatchMarker[]): CellSpec[] {
    const cells: CellSpec[] = [];
    const step = GRID.h + GRID.gap;
    let x = 0;
    const header: [string, string][] = [
        ["status", ""], ["toggle", "Toggle()"], ["capture", "Capture()"], ["setup", "Setup()"], ["offset", "PickOffset()"],
        ["armall", "ArmAll()"], ["disarmall", "DisarmAll()"], ["size", ""], ["message", ""],
    ];
    for (const [key, command] of header) {
        const w = key === "message" ? GRID.w * 3 : GRID.w;
        cells.push({ key, x, y: 0, w, h: GRID.h, command });
        x += w + GRID.gap;
    }
    const markerX = (i: number) => GRID.w + GRID.gap + i * (GRID.markerW + GRID.gap);
    markers.forEach((m, i) => cells.push({ key: `mh ${fmtInt(m.cid)}`, x: markerX(i), y: Y_DIR * step, w: GRID.markerW, h: GRID.h, command: "" }));
    const afterMarkers = markerX(markers.length);
    fixtures.forEach((f, row) => {
        const y = Y_DIR * step * (row + 2);
        const fid = fmtInt(f.fid);
        cells.push({ key: `arm ${fid}`, x: 0, y, w: GRID.w, h: GRID.h, command: `ArmToggle(${fid})` });
        markers.forEach((m, i) => cells.push({ key: `mx ${fid} ${fmtInt(m.cid)}`, x: markerX(i), y, w: GRID.markerW, h: GRID.h, command: `Program(${fid},${fmtInt(m.cid)})` }));
        const tail: [string, number, string][] = [["st", GRID.w * 1.6, ""], ["di", GRID.w, ""], ["zo", GRID.w * 0.8, ""], ["ir", GRID.w * 0.8, ""], ["sz", GRID.w, `Size(${fid})`]];
        let cx = afterMarkers;
        for (const [prefix, w, command] of tail) {
            cells.push({ key: `${prefix} ${fid}`, x: cx, y, w, h: GRID.h, command });
            cx += w + GRID.gap;
        }
    });
    return cells;
}

function stateColor(state: StateKind): string {
    if (state === "tracking") return COLORS.on;
    if (state === "too-wide" || state === "too-small") return COLORS.warn;
    if (state === "no-psn" || state === "unknown-marker") return COLORS.bad;
    return COLORS.idle;
}

function stateAppearance(state: StateKind): AppearanceKind {
    if (state === "tracking") return "tracking";
    if (state === "too-wide" || state === "too-small") return "warn";
    if (state === "no-psn") return "nopsn";
    if (state === "unknown-marker") return "error";
    return "idle";
}

export function buildViews(header: HeaderState, rows: RowState[], markers: PatchMarker[], readings: MarkerReadings): Views {
    const v: Views = {};
    const cell = (key: string, text: string, appearance: AppearanceKind, border: string = COLORS.idle, textColor: string = COLORS.text) => { v[key] = { text, border, textColor, appearance }; };
    cell("status", `${header.running ? "Running" : "Offline"}\nPSN ${fmtInt(header.liveMarkers)}/${fmtInt(markers.length)}`, header.running ? "tracking" : "error", header.running ? COLORS.on : COLORS.bad);
    cell("toggle", header.running ? "Stop" : "Start", "button");
    if (header.captureSecondsLeft !== undefined) cell("capture", `Select a sequence…\n${fmtInt(header.captureSecondsLeft)} s · tap to cancel`, "capture", COLORS.accent, COLORS.accent);
    else cell("capture", "Capture\narms → cue", "button");
    cell("setup", `Setup\nXYZ ${header.offsetLabel}`, "button");
    if (header.pickSecondsLeft !== undefined) cell("offset", `Tap a preset…\n${fmtInt(header.pickSecondsLeft)} s · tap to cancel`, "capture", COLORS.accent, COLORS.accent);
    else cell("offset", `Offset\n${header.offsetLabel}`, "button");
    cell("armall", "Arm all", "button");
    cell("disarmall", "Disarm all", "button");
    cell("size", `AZ_SIZE\n${fmtNum(header.globalSize)} m`, "header");
    cell("message", header.message, "header", COLORS.idle, COLORS.muted);
    for (const m of markers) {
        const live = readings[fidKey(m.cid)] !== undefined;
        cell(`mh ${fmtInt(m.cid)}`, `${m.name}\nCID ${fmtInt(m.cid)}`, live ? "tracking" : "nopsn", live ? COLORS.on : COLORS.bad, live ? COLORS.text : COLORS.bad);
    }
    for (const r of rows) {
        const fid = fmtInt(r.fixture.fid);
        const s = r.result.state;
        cell(`arm ${fid}`, `${fid}\n${r.fixture.name}`, r.armed ? "tracking" : "idle", r.armed ? COLORS.on : COLORS.idle);
        for (const m of markers) {
            const key = `mx ${fid} ${fmtInt(m.cid)}`;
            if (r.programmerCid === m.cid) cell(key, "P", "programmer", COLORS.bad, COLORS.bad);
            else if (r.markerCid === m.cid) {
                const color = s === "tracking" || s === "too-wide" || s === "too-small" ? COLORS.on : s === "no-psn" ? COLORS.accent : COLORS.muted;
                cell(key, "●", s === "tracking" || s === "too-wide" || s === "too-small" ? "tracking" : s === "no-psn" ? "nopsn" : "idle", color, color);
            } else cell(key, "", "idle");
        }
        const marker = markers.find(m => m.cid === r.markerCid);
        const detail = marker !== undefined ? `${marker.name} ${signed(r.offset.x)}/${signed(r.offset.y)}/${signed(r.offset.z)}` : "";
        cell(`st ${fid}`, detail === "" ? stateLabel(s) : `${stateLabel(s)}\n${detail}`, stateAppearance(s), stateColor(s));
        cell(`di ${fid}`, r.result.distance === undefined ? "—" : `${fmtNum(Math.round(r.result.distance * 10) / 10)} m\nbeam ${fmtNum(Math.round((r.result.achieved ?? 0) * 100) / 100)} m`, "idle");
        cell(`zo ${fid}`, r.result.zoom === undefined ? "—" : `${fmtNum(r.result.zoom)} %`, "idle");
        cell(`ir ${fid}`, r.result.iris === undefined ? "—" : `${fmtNum(r.result.iris)} %`, "idle");
        cell(`sz ${fid}`, `${r.sizeFixed ? "Fixed" : "Global"}\n${fmtNum(Math.round(r.size * 100) / 100)} m`, "button");
    }
    return v;
}
