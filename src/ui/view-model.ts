/** @noSelfInFile */
import { FixtureResult, StateKind } from "../engine/fixture-state";
import { Vec3 } from "../engine/vec";
import { fidKey, fmtInt, fmtNum } from "../format";
import { AppearanceKind, CellSpec, LayoutRow, MarkerReadings, PatchFixture, PatchMarker, Views } from "../model";

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

export interface HeaderState { running: boolean; liveMarkers: number; globalSize: number; offsetLabel: string; message: string }
export interface RowState {
    fixture: PatchFixture; armed: boolean; markerCid: number; programmerCid: number; offset: Vec3;
    result: FixtureResult; size: number; sizeFixed: boolean;
}
export interface GroupRowState { no: number; name: string; missing: boolean; members: RowState[] }

const TRACKING: { [state: string]: boolean } = { "tracking": true, "too-wide": true, "too-small": true };
const WORST_FIRST: StateKind[] = ["unknown-marker", "no-psn", "too-wide", "too-small", "tracking", "no-marker", "disarmed", "offline"];

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

export function layoutCells(rows: LayoutRow[], markers: PatchMarker[]): CellSpec[] {
    const cells: CellSpec[] = [];
    const step = GRID.h + GRID.gap;
    let x = 0;
    const header: [string, string][] = [
        ["status", ""], ["toggle", "Toggle()"], ["setup", "Setup()"], ["rescan", "RescanLater()"], ["size", ""], ["message", ""],
    ];
    for (const [key, command] of header) {
        const w = key === "message" ? GRID.w * 3 : GRID.w;
        cells.push({ key, x, y: 0, w, h: GRID.h, command });
        x += w + GRID.gap;
    }
    const markerX = (i: number) => GRID.w + GRID.gap + i * (GRID.markerW + GRID.gap);
    markers.forEach((m, i) => cells.push({ key: `mh ${fmtInt(m.cid)}`, x: markerX(i), y: Y_DIR * step, w: GRID.markerW, h: GRID.h, command: "" }));
    const afterMarkers = markerX(markers.length);
    rows.forEach((r, row) => {
        const y = Y_DIR * step * (row + 2);
        if (r.kind === "group") {
            const no = fmtInt(r.no);
            cells.push({ key: `garm ${no}`, x: 0, y, w: GRID.w, h: GRID.h, command: `ArmGroup(${no})` });
            markers.forEach((m, i) => cells.push({ key: `gmx ${no} ${fmtInt(m.cid)}`, x: markerX(i), y, w: GRID.markerW, h: GRID.h, command: `ProgramGroup(${no},${fmtInt(m.cid)})` }));
            cells.push({ key: `gst ${no}`, x: afterMarkers, y, w: GRID.w * 1.6, h: GRID.h, command: "" });
            return;
        }
        const f = r.fixture;
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

export function summarize(members: RowState[]): { tracking: number; total: number; worst: StateKind | undefined; worstCount: number } {
    let tracking = 0;
    let worst: StateKind | undefined;
    for (const r of members) {
        const s = r.result.state;
        if (TRACKING[s]) tracking++;
        if (worst === undefined || WORST_FIRST.indexOf(s) < WORST_FIRST.indexOf(worst)) worst = s;
    }
    const worstCount = members.filter(r => r.result.state === worst).length;
    return { tracking, total: members.length, worst, worstCount };
}

// Colour of a marker cell for the fixtures following it: driven (green), waiting for PSN (orange), else muted.
function followLook(states: StateKind[]): [string, AppearanceKind] {
    if (states.some(s => TRACKING[s])) return [COLORS.on, "tracking"];
    if (states.some(s => s === "no-psn")) return [COLORS.accent, "nopsn"];
    return [COLORS.muted, "idle"];
}

export function buildViews(header: HeaderState, rows: (RowState | GroupRowState)[], markers: PatchMarker[], readings: MarkerReadings): Views {
    const v: Views = {};
    const cell = (key: string, text: string, appearance: AppearanceKind, border: string = COLORS.idle, textColor: string = COLORS.text) => { v[key] = { text, border, textColor, appearance }; };
    cell("status", `${header.running ? "Running" : "Offline"}\nPSN ${fmtInt(header.liveMarkers)}/${fmtInt(markers.length)}`, header.running ? "tracking" : "error", header.running ? COLORS.on : COLORS.bad);
    cell("toggle", header.running ? "Stop" : "Start", "button");
    cell("setup", `Setup\nXYZ ${header.offsetLabel}`, "button");
    cell("rescan", "Rescan\npatch", "button");
    cell("size", `AZ_SIZE\n${fmtNum(header.globalSize)} m`, "header");
    cell("message", header.message, "header", COLORS.idle, COLORS.muted);
    for (const m of markers) {
        const live = readings[fidKey(m.cid)] !== undefined;
        cell(`mh ${fmtInt(m.cid)}`, `${m.name}\nCID ${fmtInt(m.cid)}`, live ? "tracking" : "nopsn", live ? COLORS.on : COLORS.bad, live ? COLORS.text : COLORS.bad);
    }
    for (const row of rows) {
        if ("members" in row) {
            groupViews(cell, row, markers);
            continue;
        }
        const r = row;
        const fid = fmtInt(r.fixture.fid);
        const s = r.result.state;
        cell(`arm ${fid}`, `${fid}\n${r.fixture.name}`, r.armed ? "tracking" : "idle", r.armed ? COLORS.on : COLORS.idle);
        for (const m of markers) {
            const key = `mx ${fid} ${fmtInt(m.cid)}`;
            if (r.programmerCid === m.cid) cell(key, "P", "programmer", COLORS.bad, COLORS.bad);
            else if (r.markerCid === m.cid) {
                const [color, look] = followLook([s]);
                cell(key, "●", look, color, color);
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

type CellFn = (key: string, text: string, appearance: AppearanceKind, border?: string, textColor?: string) => void;

function groupViews(cell: CellFn, g: GroupRowState, markers: PatchMarker[]): void {
    const no = fmtInt(g.no);
    const total = g.members.length;
    const armed = g.members.filter(r => r.armed).length;
    const armLook: AppearanceKind = total > 0 && armed === total ? "tracking" : armed === 0 ? "idle" : "warn";
    cell(`garm ${no}`, `G${no} ${g.name}\n${fmtInt(armed)}/${fmtInt(total)} armed`, armLook,
        armLook === "tracking" ? COLORS.on : armLook === "warn" ? COLORS.warn : COLORS.idle);
    for (const m of markers) {
        const key = `gmx ${no} ${fmtInt(m.cid)}`;
        const inProgrammer = g.members.filter(r => r.programmerCid === m.cid).length;
        const following = g.members.filter(r => r.markerCid === m.cid).map(r => r.result.state);
        if (inProgrammer > 0) cell(key, inProgrammer === total ? "P" : `P ${fmtInt(inProgrammer)}/${fmtInt(total)}`, "programmer", COLORS.bad, COLORS.bad);
        else if (following.length > 0) {
            const [color, look] = followLook(following);
            cell(key, "●", look, color, color);
        } else cell(key, "", "idle");
    }
    if (total === 0) {
        if (g.missing) cell(`gst ${no}`, "Group missing", "error", COLORS.bad);
        else cell(`gst ${no}`, "No XYZ fixtures", "idle");
        return;
    }
    const sum = summarize(g.members);
    const worst = sum.worst ?? "offline";
    const first = `${fmtInt(sum.tracking)}/${fmtInt(total)} tracking`;
    cell(`gst ${no}`, worst === "tracking" ? first : `${first}\n${fmtInt(sum.worstCount)} ${stateLabel(worst)}`, stateAppearance(worst), stateColor(worst));
}
