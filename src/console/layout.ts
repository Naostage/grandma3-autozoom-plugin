/** @noSelfInFile */
import { appearanceHandle } from "./appearances";
import { CellSpec, Views } from "../model";
import { children, findChild } from "./handles";
import { ensureMacro, ensurePool, findPool, POOL_ADDR } from "./pool";

export const LAYOUT = "AutoZoom";
const TAG = "AZ:";

export function macroName(key: string): string {
    return "AZ " + key;
}

let elements: { [key: string]: any } = {};
let written: { [key: string]: string } = {};
// One element checked every refresh: a reloaded/replaced layout invalidates it even when no view changed.
let sentinel: any = undefined;

export function buildLayout(cells: CellSpec[]): void {
    const pool = ensurePool();
    if (findChild(pool.Layouts, LAYOUT) !== undefined) Cmd(`Delete ${POOL_ADDR} Layout '${LAYOUT}' /nc`);
    Cmd(`Store ${POOL_ADDR} Layout '${LAYOUT}' /o /nc`);
    const layout = findChild(pool.Layouts, LAYOUT);
    if (layout === undefined) throw new Error("Could not create the AutoZoom layout");
    elements = {};
    written = {};
    sentinel = undefined;
    for (const cell of cells) {
        ensureMacro(macroName(cell.key), cell.command);
        const el = layout.Append();
        el.Object = findChild(pool.Macros, macroName(cell.key));
        el.Action = "Go+";
        el.Note = TAG + cell.key;
        el.PosX = cell.x;
        el.PosY = cell.y;
        el.Width = cell.w;
        el.Height = cell.h;
        el.VisibilityObjectName = false;
        el.VisibilityIcon = false;
        el.VisibilityID = false;
        el.VisibilityCID = false;
        el.VisibilityValue = false;
        el.VisibilityBar = false;
        el.VisibilityBorder = false;
        el.BorderSize = 0;
        elements[cell.key] = el;
        if (sentinel === undefined) sentinel = el;
    }
}

// Never creates anything: if the pool or layout is gone, elements stays empty.
// Forgets what was written: the elements found may be new objects (layout reloaded) without our texts.
function findElements(): void {
    elements = {};
    written = {};
    sentinel = undefined;
    const pool = findPool();
    if (pool === undefined) return;
    const layout = findChild(pool.Layouts, LAYOUT);
    if (layout === undefined) return;
    for (const el of children(layout)) {
        const note = tostring(el.Note ?? "");
        if (!note.startsWith(TAG)) continue;
        elements[note.substring(TAG.length)] = el;
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
        const app = appearanceHandle(view.appearance);
        if (app !== undefined) el.Appearance = app;
        written[key] = signature;
    }
}
