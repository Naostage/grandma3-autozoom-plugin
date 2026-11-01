/** @noSelfInFile */
// Layout rows editor: one line per entry with /\ \/ and a trash button, + opens the add picker
// (Groups / Fixtures tabs, tiles toggled in tap order). Every edit goes to onChange right away.
import { fidKey, fmtInt } from "../format";
import { addEntries, Catalog, coverage, entryLabel, moveEntry, removeEntry, RowEntry, sameEntry } from "../store/rows";
import { ask, button, buildBase, closeWindow, color, fixedRows, label, paint, row, scrollGrid, textColor, tickColor } from "./window";

const WIDTH = 1000;
const LINE_HEIGHT = 70;
const MAX_HEIGHT = 520;
const TAB_HEIGHT = 70;
const FOOTER_HEIGHT = 70;
const ARROW_WIDTH = 90;
const COLUMNS = 4;
const TILE_HEIGHT = 70;
const SCROLLBAR_WIDTH = 30;

interface Tile { entry: RowEntry; text: string; tick: "self" | "group" | undefined }

function disable(obj: any): void {
    pcall(() => { obj.Enabled = "No"; });
}

export function openRowsEditor(rows: RowEntry[], catalog: Catalog, onChange: (rows: RowEntry[]) => void, onClose: (changed: boolean) => void): void {
    let current = [...rows];
    let changed = false;
    let tab = 1;
    let picked: RowEntry[] = [];
    const fixtureName = (fid: number) => catalog.fixtures.find(f => f.fid === fid)?.name;
    const labelOf = (e: RowEntry) => entryLabel(e, catalog.groups, fixtureName);

    function commit(next: RowEntry[]): void {
        current = next;
        changed = true;
        onChange(current);
        drawEditor();
    }

    function drawEditor(): void {
        const body = buildBase("AutoZoom — layout rows", WIDTH);
        const lines = Math.max(1, current.length);
        const content = lines * LINE_HEIGHT + 10;
        fixedRows(body, [Math.min(content, MAX_HEIGHT), FOOTER_HEIGHT]);
        const grid = scrollGrid(body, 0, WIDTH, content, 1, lines);
        const labelW = WIDTH - SCROLLBAR_WIDTH - 60 - 3 * (ARROW_WIDTH + 5);
        if (current.length === 0) label(grid, "Empty: every XYZ fixture gets its own row", labelW, LINE_HEIGHT - 10).Anchors = "0,0";
        current.forEach((e, i) => {
            const line = row(grid, i);
            const text = labelOf(e);
            label(line, text, labelW, LINE_HEIGHT - 10);
            const up = button(line, "/\\", ARROW_WIDTH, LINE_HEIGHT - 10, `AZW_RowUp_${i + 1}`, () => commit(moveEntry(current, i, -1)));
            const down = button(line, "\\/", ARROW_WIDTH, LINE_HEIGHT - 10, `AZW_RowDown_${i + 1}`, () => commit(moveEntry(current, i, 1)));
            const del = button(line, "Trash", ARROW_WIDTH, LINE_HEIGHT - 10, `AZW_RowDel_${i + 1}`, () => {
                if (ask("Remove line", `Remove ${text}?`)) commit(removeEntry(current, i));
            });
            pcall(() => { del.Icon = "trash"; });
            if (i === 0) disable(up);
            if (i === current.length - 1) disable(down);
        });
        const footer = row(body, 1);
        button(footer, "+", 120, FOOTER_HEIGHT - 20, "AZW_RowAdd", () => { picked = []; drawAdd(); });
        button(footer, "Close", 200, FOOTER_HEIGHT - 20, "AZW_RowClose", () => {
            closeWindow();
            onClose(changed);
        });
    }

    function tiles(): Tile[] {
        const cov = coverage(current, catalog.groups);
        if (tab === 1) {
            return catalog.groups.map(g => ({
                entry: { kind: "group", no: g.no, name: g.name } as RowEntry,
                text: `${fmtInt(g.no)}  ${g.name}`, tick: cov.groups[fidKey(g.no)] ? "self" : undefined,
            }));
        }
        return catalog.fixtures.map(f => ({
            entry: { kind: "fixture", fid: f.fid } as RowEntry, text: `${fmtInt(f.fid)}  ${f.name}`, tick: cov.fixtures[fidKey(f.fid)],
        }));
    }

    function drawAdd(): void {
        const body = buildBase("AutoZoom — add layout rows", WIDTH);
        const list = tiles();
        const lines = Math.max(1, Math.ceil(list.length / COLUMNS));
        const content = lines * TILE_HEIGHT + 10;
        fixedRows(body, [TAB_HEIGHT, Math.min(content, MAX_HEIGHT), FOOTER_HEIGHT]);

        const tabs = row(body, 0);
        (["Groups", "Fixtures"] as const).forEach((name, i) => {
            const b = button(tabs, name, 200, TAB_HEIGHT - 10, `AZW_AddTab_${i + 1}`, () => { tab = i + 1; drawAdd(); });
            if (tab === i + 1) paint(b, color("ProgLayer", "Absolute"));
        });

        const grid = scrollGrid(body, 1, WIDTH, content, COLUMNS, lines);
        const tileW = Math.floor((WIDTH - SCROLLBAR_WIDTH - 40) / COLUMNS);
        if (list.length === 0) label(grid, tab === 1 ? "No groups in the show." : "No XYZ fixtures in the patch.", WIDTH - 80, TILE_HEIGHT - 6).Anchors = "0,0";
        list.forEach((t, i) => {
            const order = picked.findIndex(p => sameEntry(p, t.entry));
            const text = `${t.text}${t.tick !== undefined ? "  ✔" : ""}${order >= 0 ? `\n${fmtInt(order + 1)}` : ""}`;
            const b = button(grid, text, tileW, TILE_HEIGHT - 6, `AZW_AddTile_${i + 1}`, () => {
                picked = order >= 0 ? picked.filter(p => !sameEntry(p, t.entry)) : [...picked, t.entry];
                drawAdd();
            });
            b.Anchors = `${i % COLUMNS},${Math.floor(i / COLUMNS)}`;
            pcall(() => { b.TextAlignmentH = "Left"; b.Margin = "3,3,3,3"; b.Texture = "corner5"; });
            if (order >= 0) paint(b, color("ProgLayer", "Absolute"));
            if (t.tick !== undefined) textColor(b, tickColor(t.tick));
            if (t.tick === "self") disable(b);         // already in the list by itself: no duplicate entries
        });

        const footer = row(body, 2);
        button(footer, `Add ${fmtInt(picked.length)}`, 200, FOOTER_HEIGHT - 20, "AZW_AddOk", () => {
            const next = addEntries(current, picked);
            picked = [];
            if (next.length !== current.length) commit(next); else drawEditor();
        });
        button(footer, "Cancel", 200, FOOTER_HEIGHT - 20, "AZW_AddCancel", () => { picked = []; drawEditor(); });
    }

    drawEditor();
}
