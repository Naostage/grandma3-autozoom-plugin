/** @noSelfInFile */
import { CellSpec, Views } from "../model";
import { children, findChild } from "./handles";
import { ensureMacro, ensurePool, POOL_ADDR } from "./pool";

export const LAYOUT = "AutoZoom";
const TAG = "AZ:";

export function macroName(key: string): string {
    return "AZ " + key;
}

let elements: { [key: string]: any } = {};
let written: { [key: string]: string } = {};

export function buildLayout(cells: CellSpec[]): void {
    const pool = ensurePool();
    if (findChild(pool.Layouts, LAYOUT) !== undefined) Cmd(`Delete ${POOL_ADDR} Layout '${LAYOUT}' /nc`);
    Cmd(`Store ${POOL_ADDR} Layout '${LAYOUT}' /o /nc`);
    const layout = findChild(pool.Layouts, LAYOUT);
    if (layout === undefined) throw new Error("Could not create the AutoZoom layout");
    elements = {};
    written = {};
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
        el.VisibilityObjectName = "Hidden";
        el.VisibilityIcon = "Hidden";
        el.VisibilityBorder = "Visible";
        elements[cell.key] = el;
    }
}

function findElements(): void {
    const pool = ensurePool();
    elements = {};
    for (const el of children(findChild(pool.Layouts, LAYOUT))) {
        const note = tostring(el.Note ?? "");
        if (note.startsWith(TAG)) elements[note.substring(TAG.length)] = el;
    }
}

export function refreshLayout(views: Views): void {
    for (const key in views) {
        const view = views[key];
        const signature = `${view.text}|${view.border}|${view.textColor}`;
        if (written[key] === signature) continue;
        let el = elements[key];
        if (el === undefined || !IsObjectValid(el)) {
            findElements();
            el = elements[key];
            if (el === undefined) continue;     // user deleted it; Rescan recreates it
        }
        el.CustomTextText = view.text;
        el.CustomTextColor = view.textColor;
        el.BorderColor = view.border;
        written[key] = signature;
    }
}
