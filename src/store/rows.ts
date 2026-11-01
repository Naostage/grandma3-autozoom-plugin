/** @noSelfInFile */
import { fidKey, fmtInt } from "../format";

// One layout row: a console Group (all its XYZ fixtures) or a single fixture. Indexes are 0-based.
export type RowEntry = { kind: "group"; no: number; name: string } | { kind: "fixture"; fid: number };

export interface GroupInfo { no: number; name: string; fids: number[] }

// What the add picker offers: console groups and the scanned XYZ fixtures.
export interface Catalog { groups: GroupInfo[]; fixtures: { fid: number; name: string }[] }

export function sameEntry(a: RowEntry, b: RowEntry): boolean {
    if (a.kind === "group") return b.kind === "group" && a.no === b.no;
    return b.kind === "fixture" && a.fid === b.fid;
}

export function addEntries(rows: RowEntry[], add: RowEntry[]): RowEntry[] {
    const out = [...rows];
    for (const e of add) if (!out.some(x => sameEntry(x, e))) out.push(e);
    return out;
}

export function moveEntry(rows: RowEntry[], index: number, delta: -1 | 1): RowEntry[] {
    const out = [...rows];
    const to = index + delta;
    if (index < 0 || index >= out.length || to < 0 || to >= out.length) return out;
    const e = out[index];
    out[index] = out[to];
    out[to] = e;
    return out;
}

export function removeEntry(rows: RowEntry[], index: number): RowEntry[] {
    return rows.filter((_, i) => i !== index);
}

// Which fixtures the rows already cover ("self" = their own row, wins over "group") and which groups are listed.
export function coverage(rows: RowEntry[], groups: GroupInfo[]): { fixtures: { [fid: string]: "self" | "group" }; groups: { [no: string]: boolean } } {
    const fixtures: { [fid: string]: "self" | "group" } = {};
    const listed: { [no: string]: boolean } = {};
    for (const e of rows) {
        if (e.kind === "fixture") {
            fixtures[fidKey(e.fid)] = "self";
        } else {
            listed[fidKey(e.no)] = true;
            const g = groups.find(x => x.no === e.no);
            for (const fid of g?.fids ?? []) if (fixtures[fidKey(fid)] === undefined) fixtures[fidKey(fid)] = "group";
        }
    }
    return { fixtures, groups: listed };
}

export function entryLabel(e: RowEntry, groups: GroupInfo[], fixtureName: (fid: number) => string | undefined): string {
    if (e.kind === "group") {
        const g = groups.find(x => x.no === e.no);
        return `Group ${fmtInt(e.no)}  ${g?.name ?? e.name}`;
    }
    const name = fixtureName(e.fid);
    return name === undefined ? `Fixture ${fmtInt(e.fid)}` : `Fixture ${fmtInt(e.fid)}  ${name}`;
}

function int(v: unknown): number | undefined {
    return typeof v === "number" && v === v && Math.floor(v) === v ? v : undefined;
}

// Saved rows: malformed entries and duplicates are dropped silently.
export function parseRows(raw: unknown): RowEntry[] {
    let out: RowEntry[] = [];
    if (!Array.isArray(raw)) return out;
    for (const r of raw) {
        if (typeof r !== "object") continue;
        if (r.kind === "group" && int(r.no) !== undefined && typeof r.name === "string") {
            out = addEntries(out, [{ kind: "group", no: r.no, name: r.name }]);
        } else if (r.kind === "fixture" && int(r.fid) !== undefined) {
            out = addEntries(out, [{ kind: "fixture", fid: r.fid }]);
        }
    }
    return out;
}
