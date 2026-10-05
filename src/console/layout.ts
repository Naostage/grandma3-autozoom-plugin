/** @noSelfInFile */
import { appearanceHandle } from "./appearances";
import { CellSpec, Views } from "../model";
import { children, findChild } from "./handles";
import { warnOnce } from "./log";
import { CELL_PREFIX, cellSequenceName, ensureCellSequence, ensurePool, findPool, POOL_ADDR } from "./pool";

export const LAYOUT = "AutoZoom";
const TAG = "AZ:";

let elements: { [key: string]: any } = {};
// Cell sequences carry the cell colour (seq.Appearance); the element's own Appearance stays empty (BeatGrid model).
let sequences: { [key: string]: any } = {};
let written: { [key: string]: string } = {};
// One element checked every refresh: a reloaded/replaced layout invalidates it even when no view changed.
let sentinel: any = undefined;

const HIDDEN: [string, boolean | number | string][] = [
    ["VisibilityElement", true], ["VisibilityObjectName", false], ["VisibilityIcon", false], ["VisibilityID", false], ["VisibilityCID", false],
    ["VisibilityValue", false], ["VisibilityBar", false], ["VisibilityBorder", false], ["BorderSize", 0],
    ["CustomTextAlignmentV", "Center"], ["CustomTextAlignmentH", "Center"],
];

// Cosmetic: a property this console version does not know must not abort the layout build.
function hideDetails(el: any): void {
    for (const [prop, value] of HIDDEN) {
        try {
            el[prop] = value;
        } catch (e) {
            warnOnce("visibility", `Could not set layout element ${prop}: ${tostring(e)}`);
        }
    }
}

// Elements that reject Pause (unknown action on this version) fall back to Go+ on the command-less sequence.
function setAction(el: any, clickable: boolean): void {
    if (clickable) {
        el.Action = "Go+";
        return;
    }
    try {
        el.Action = "Pause";       // BeatGrid: Pause for non-clickable cells
    } catch (e) {
        warnOnce("action", `Could not set layout element Action Pause: ${tostring(e)}`);
        el.Action = "Go+";
    }
}

// Cell sequences of cells that no longer exist (fixture removed). Fader sequences are AZ_…, never matched.
function removeStaleSequences(pool: any, cells: CellSpec[]): void {
    const wanted: { [name: string]: boolean } = {};
    for (const cell of cells) wanted[cellSequenceName(cell.key)] = true;
    const stale: string[] = [];
    for (const s of children(pool.Sequences)) {
        const name = tostring(s.name ?? "");
        if (name.startsWith(CELL_PREFIX) && !wanted[name]) stale.push(name);
    }
    for (const name of stale) Cmd(`Delete ${POOL_ADDR} Sequence '${name}' /nc`);
}

export function buildLayout(cells: CellSpec[]): void {
    const pool = ensurePool();
    removeStaleSequences(pool, cells);
    if (findChild(pool.Layouts, LAYOUT) !== undefined) Cmd(`Delete ${POOL_ADDR} Layout '${LAYOUT}' /nc`);
    Cmd(`Store ${POOL_ADDR} Layout '${LAYOUT}' /o /nc`);
    const layout = findChild(pool.Layouts, LAYOUT);
    if (layout === undefined) throw new Error("Could not create the AutoZoom layout");
    elements = {};
    sequences = {};
    written = {};
    sentinel = undefined;
    for (const cell of cells) {
        const seq = ensureCellSequence(cellSequenceName(cell.key), cell.command);
        const el = layout.Append();
        el.Object = seq;
        setAction(el, cell.command !== "");
        el.Note = TAG + cell.key;
        el.PosX = cell.x;
        el.PosY = cell.y;
        el.Width = cell.w;
        el.Height = cell.h;
        hideDetails(el);
        elements[cell.key] = el;
        sequences[cell.key] = seq;
        if (sentinel === undefined) sentinel = el;
    }
}

// Never creates anything: if the pool or layout is gone, elements stays empty.
// Forgets what was written: the elements found may be new objects (layout reloaded) without our texts.
function findElements(): void {
    elements = {};
    sequences = {};
    written = {};
    sentinel = undefined;
    const pool = findPool();
    if (pool === undefined) return;
    const layout = findChild(pool.Layouts, LAYOUT);
    if (layout === undefined) return;
    for (const el of children(layout)) {
        const note = tostring(el.Note ?? "");
        if (!note.startsWith(TAG)) continue;
        const key = note.substring(TAG.length);
        elements[key] = el;
        sequences[key] = el.Object;
        if (sentinel === undefined) sentinel = el;
    }
}

export function refreshLayout(views: Views): void {
    let rescanned = false;
    if (sentinel !== undefined && !IsObjectValid(sentinel)) {
        rescanned = true;
        findElements();
    }
    for (const key in views) {
        const view = views[key];
        const signature = `${view.text}|${view.border}|${view.textColor}|${view.appearance}`;
        if (written[key] === signature) continue;
        let el = elements[key];
        if (el === undefined || !IsObjectValid(el)) {
            if (rescanned) continue;
            rescanned = true;
            findElements();
            el = elements[key];
            if (el === undefined) continue;     // user deleted it; Rescan recreates it
        }
        el.CustomTextText = view.text;
        el.CustomTextColor = view.textColor;
        el.BorderColor = view.border;
        const seq = sequences[key];
        const app = appearanceHandle(view.appearance);
        if (seq !== undefined && IsObjectValid(seq) && app !== undefined && seq.Appearance !== app) seq.Appearance = app;
        written[key] = signature;
    }
}
