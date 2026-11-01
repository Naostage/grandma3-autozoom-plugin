/** @noSelfInFile */
// Preset picker window for the XYZ offset preset: pool tabs, one tile per preset, presets without
// XYZ attributes greyed out. Tapping a tile closes the window and hands back "<pool>.<no>".
import { button, buildBase, closeWindow, color, fixedRows, label, paint, row, scrollGrid } from "./window";

const WIDTH = 1100;
const COLUMNS = 4;
const TILE_HEIGHT = 70;
const MAX_HEIGHT = 520;
const TAB_HEIGHT = 70;
const HINT_HEIGHT = 60;
const FOOTER_HEIGHT = 70;
const SCROLLBAR_WIDTH = 30;

interface PresetItem { addr: string; no: number; name: string; handle: any }
interface PoolItem { no: number; name: string; presets: PresetItem[] }

function listPools(): PoolItem[] {
    const out: PoolItem[] = [];
    const [ok, pools] = pcall(() => (DataPool() as any).PresetPools.Children());
    if (!ok || type(pools) !== "table") return out;
    for (const pool of pools as any[]) {
        const [okPool, presets] = pcall(() => pool.Children());
        const list: PresetItem[] = [];
        for (const p of (okPool ? presets : []) as any[]) {
            const no = tonumber(p.no);
            if (no !== undefined) list.push({ addr: `${tostring(pool.no)}.${tostring(no)}`, no, name: tostring(p.name ?? ""), handle: p });
        }
        list.sort((a, b) => a.no - b.no);
        const poolNo = tonumber(pool.no);
        if (list.length > 0 && poolNo !== undefined) out.push({ no: poolNo, name: tostring(pool.name ?? ""), presets: list });
    }
    out.sort((a, b) => a.no - b.no);
    return out;
}

function hasXYZ(preset: any): boolean {
    const [ok, data] = pcall(() => GetPresetData(preset, false, true));
    if (!ok || type(data) !== "table" || type(data.by_fixtures) !== "table") return false;
    for (const [, attrs] of pairs(data.by_fixtures as any)) {
        if (type(attrs) !== "table") continue;
        for (const [name] of pairs(attrs as any)) {
            if (tostring(name).toUpperCase().startsWith("XYZ_")) return true;
        }
    }
    return false;
}

export function openPresetPicker(current: string, onPick: (preset: string) => void): void {
    const pools = listPools();
    const [poolOfCurrent] = string.match(current, "^(%d+)%.");
    const xyz: { [addr: string]: boolean } = {};
    let shown = tonumber(poolOfCurrent) ?? 2;

    function draw(): void {
        const body = buildBase("AutoZoom — choose the XYZ offset preset", WIDTH);
        const pool = pools.find(p => p.no === shown) ?? pools[0];
        const presets = pool?.presets ?? [];
        const rows = Math.max(1, Math.ceil(presets.length / COLUMNS));
        const content = rows * TILE_HEIGHT + 10;
        fixedRows(body, [TAB_HEIGHT, HINT_HEIGHT, Math.min(content, MAX_HEIGHT), FOOTER_HEIGHT]);

        const tabs = row(body, 0);
        const tabW = Math.min(180, Math.floor((WIDTH - 20) / Math.max(pools.length, 1)) - 5);
        pools.forEach((p, i) => {
            const b = button(tabs, `${p.no}\n${p.name}`, tabW, TAB_HEIGHT - 10, `AZW_PickPool_${i + 1}`, () => { shown = p.no; draw(); });
            if (pool !== undefined && p.no === pool.no) paint(b, color("ProgLayer", "Absolute"));
        });

        label(row(body, 1), "Tap the preset that holds the XYZ offset. Greyed: no XYZ values.", WIDTH - 30, HINT_HEIGHT - 10);

        const grid = scrollGrid(body, 2, WIDTH, content, COLUMNS, rows);
        const tileW = Math.floor((WIDTH - SCROLLBAR_WIDTH - 40) / COLUMNS);
        if (presets.length === 0) label(grid, "No presets in the show.", WIDTH - 80, TILE_HEIGHT - 6).Anchors = "0,0";
        presets.forEach((p, i) => {
            if (xyz[p.addr] === undefined) xyz[p.addr] = hasXYZ(p.handle);
            const usable = xyz[p.addr];
            const tile = button(grid, `${p.addr}  ${p.name}\n${usable ? "XYZ" : "no XYZ"}`, tileW, TILE_HEIGHT - 6, `AZW_PickTile_${i + 1}`, () => {
                closeWindow();
                onPick(p.addr);
            });
            tile.Anchors = `${i % COLUMNS},${Math.floor(i / COLUMNS)}`;
            pcall(() => { tile.TextAlignmentH = "Left"; tile.Margin = "3,3,3,3"; tile.Texture = "corner5"; });
            if (p.addr === current) paint(tile, color("ProgLayer", "Absolute"));
            if (!usable) pcall(() => { tile.Enabled = "No"; });
        });

        button(row(body, 3), "Cancel", 200, FOOTER_HEIGHT - 20, "AZW_PickCancel", () => closeWindow());
    }
    draw();
}
