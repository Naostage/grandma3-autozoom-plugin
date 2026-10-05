/** @noSelfInFile */
import { Optics } from "../engine/beam";
import { add, rotate, vec, Vec3 } from "../engine/vec";
import { fidKey, fmtInt } from "../format";
import { PatchScan, Space } from "../model";
import { children, findChild, num } from "./handles";
import { DEFAULT_TARGET_SPACE } from "./live";

interface Transform { pos: Vec3; rot: Vec3 }
const XYZ_ATTRIBUTES = ["XYZ_MArker", "XYZ_X", "XYZ_Y", "XYZ_Z"];

function readOptics(mode: any): Optics | undefined {
    let zoom: number[] | undefined;
    let iris: number[] | undefined;
    for (const channel of children(mode.DMXChannels)) {
        const logical = children(channel)[0];
        if (logical === undefined) continue;
        const fn = children(logical)[0];
        if (fn === undefined) continue;
        const from = num(fn.physicalFrom), to = num(fn.physicalTo);
        if (from === undefined || to === undefined) continue;
        const range = [Math.min(from, to), Math.max(from, to)];
        if (logical.attribute === "Zoom") zoom = range;
        if (logical.attribute === "Iris") iris = range;
    }
    if (zoom === undefined) return undefined;
    return { zoomMin: zoom[0], zoomMax: zoom[1], irisMin: iris === undefined ? 0 : iris[0], irisMax: iris === undefined ? 0 : iris[1] };
}

// "<fixture type>|<mode>" -> optics, for XYZ-enabled modes with a Zoom channel
function xyzModes(): { [key: string]: Optics } {
    const out: { [key: string]: Optics } = {};
    const patch: any = Patch();
    for (const ft of children(patch.FixtureTypes)) {
        for (const mode of children(ft.DMXModes)) {
            if (mode.XYZ !== true) continue;
            const optics = readOptics(mode);
            if (optics !== undefined) out[`${ft.name}|${mode.name}`] = optics;
        }
    }
    return out;
}

function modeName(node: any): string | undefined {
    const m = node.ModeDirect ?? node.Mode;
    if (m === undefined) return undefined;
    if (typeof m !== "string") return m.name;
    const space = m.indexOf(" ");                       // "2 Mode 2" -> "Mode 2"
    return space > 0 && num(m.substring(0, space)) !== undefined ? m.substring(space + 1) : m;
}

function subfixtureIndexes(): { [fid: string]: number } {
    const out: { [fid: string]: number } = {};
    const count = GetSubfixtureCount();
    for (let i = 0; i <= count; i++) {
        const sf = GetSubfixture(i);
        const fid = sf === undefined ? undefined : num(sf.fid);
        if (fid !== undefined && out[fidKey(fid)] === undefined) out[fidKey(fid)] = i;
    }
    return out;
}

function transformOf(node: any, parent: Transform): Transform {
    const pos = vec(num(node.POSX) ?? 0, num(node.POSY) ?? 0, num(node.POSZ) ?? 0);
    const rot = vec(num(node.ROTX) ?? 0, num(node.ROTY) ?? 0, num(node.ROTZ) ?? 0);
    // Rotations are summed per axis: exact for single-axis (yaw) rigs, an approximation otherwise.
    return { pos: add(parent.pos, rotate(pos, parent.rot)), rot: add(parent.rot, rot) };
}

function readSpace(h: any): Space | undefined {
    if (h === undefined || typeof h === "string" || typeof h === "number" || typeof h === "boolean") return undefined;   // handles are tables (mock) or userdata (console)
    const minX = num(h.MINX), minY = num(h.MINY), minZ = num(h.MINZ);
    const maxX = num(h.MAXX), maxY = num(h.MAXY), maxZ = num(h.MAXZ);
    if (minX === undefined || minY === undefined || minZ === undefined || maxX === undefined || maxY === undefined || maxZ === undefined) return undefined;
    return { min: vec(minX, minY, minZ), max: vec(maxX, maxY, maxZ) };
}

// "2 'MArker 1 Target'" -> "MArker 1 Target"; without quotes the whole trimmed string
function nameFromRef(ref: string): string {
    const a = ref.indexOf("'");
    if (a >= 0) {
        const b = ref.indexOf("'", a + 1);
        if (b >= 0) return ref.substring(a + 1, b);
    }
    return ref.trim();
}

function targetSpaceOf(marker: any, stage: any): Space {
    const ref = marker.TARGETSPACE;
    const byRef = typeof ref === "string" ? readSpace(findChild(stage.Spaces, nameFromRef(ref))) : readSpace(ref);
    return byRef
        ?? readSpace(findChild(stage.Spaces, `${tostring(marker.name)} Target`))
        ?? DEFAULT_TARGET_SPACE;
}

export function scanPatch(): PatchScan {
    const scan: PatchScan = { fixtures: [], markers: [], problems: [] };
    const modes = xyzModes();
    const subIndex = subfixtureIndexes();
    const attrIndex: number[] = [];
    for (const a of XYZ_ATTRIBUTES) attrIndex.push(GetAttributeIndex(a) ?? -1);   // -1 = missing (no holes in Lua arrays)

    function walk(node: any, parent: Transform, stage: any): void {
        if (node.IDType === "MArker") {
            const cid = num(node.cid);
            if (cid !== undefined) scan.markers.push({ cid, name: tostring(node.name ?? `Marker ${fmtInt(cid)}`), targetSpace: targetSpaceOf(node, stage) });
            return;
        }
        const t = transformOf(node, parent);
        for (const child of children(node)) walk(child, t, stage);   // groups and sub-fixtures
        const fid = num(node.fid);
        const ft = node.FixtureType;
        if (fid === undefined || ft === undefined) return;
        const optics = modes[`${ft.name}|${modeName(node)}`];
        if (optics === undefined) return;                    // not XYZ-enabled, or no zoom
        const sub = subIndex[fidKey(fid)];
        const ui: number[] = [];
        for (const a of attrIndex) {
            const u = sub === undefined || a < 0 ? undefined : GetUIChannelIndex(sub, a);
            if (u === undefined) break;
            ui.push(u);
        }
        if (ui.length < 4) {
            scan.problems.push(`Fixture ${fmtInt(fid)}: XYZ attributes not found, skipped`);
            return;
        }
        scan.fixtures.push({ fid, name: tostring(node.name), position: t.pos, optics, uich: { marker: ui[0], x: ui[1], y: ui[2], z: ui[3] } });
    }

    const origin: Transform = { pos: vec(0, 0, 0), rot: vec(0, 0, 0) };
    for (const stage of children((Patch() as any).Stages)) for (const node of children(stage.Fixtures)) walk(node, origin, stage);
    scan.fixtures.sort((a, b) => a.fid - b.fid);
    scan.markers.sort((a, b) => a.cid - b.cid);
    return scan;
}
