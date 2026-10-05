/** @noSelfInFile */
import { APPEARANCES } from "../ui/view-model";
import { fmtInt } from "../format";
import { children, num } from "./handles";

// false = looked up and missing: no pool scan per changed cell until the next ensureAppearances().
const cache: { [kind: string]: any } = {};

function pool(): any {
    return (ShowData() as any).Appearances;
}

function findByName(name: string): any {
    for (const a of children(pool())) if (a.name === name) return a;
    return undefined;
}

export const APPEARANCE_BASE = 9001;

function occupied(): { [no: string]: boolean } {
    const out: { [no: string]: boolean } = {};
    for (const a of children(pool())) {
        const n = num(a.No);
        if (n !== undefined) out[fmtInt(n)] = true;
    }
    return out;
}

// First run of `count` free numbers at or above APPEARANCE_BASE (BeatGrid's findContiguousBase, started far up).
function farBase(count: number): number {
    const used = occupied();
    let start = APPEARANCE_BASE;
    let run = 0;
    for (let n = APPEARANCE_BASE; n < APPEARANCE_BASE + 10000; n++) {
        if (used[fmtInt(n)]) {
            run = 0;
            start = n + 1;
            continue;
        }
        run++;
        if (run === count) return start;
    }
    return start;
}

// BeatGrid's createAppearanceAt: grow the pool to `no`, then create the appearance in that slot.
function createAt(no: number, name: string): any {
    const p = pool();
    if (no > p.Count()) p.Resize(no);
    const app = p.Create(no, p.GetChildClass());
    app.Name = name;
    return app;
}

// Creates missing AutoZoom appearances in a contiguous far block and reapplies their colours
// (operator edits are reset on install).
export function ensureAppearances(): void {
    const kinds: string[] = [];
    for (const kind in APPEARANCES) kinds.push(kind);
    kinds.sort();
    // AZ appearances created below the far block (2.0.0.1 build) are removed and recreated far up.
    for (const kind of kinds) {
        const app = findByName(APPEARANCES[kind].name);
        const n = app === undefined ? undefined : num(app.No);
        if (app !== undefined && n !== undefined && n < APPEARANCE_BASE) pool().Delete(n);
    }
    const missing = kinds.filter(k => findByName(APPEARANCES[k].name) === undefined);
    let next = missing.length > 0 ? farBase(missing.length) : 0;
    for (const kind of kinds) {
        const spec = APPEARANCES[kind];
        let app = findByName(spec.name);
        if (app === undefined) {
            app = createAt(next, spec.name);
            next++;
        }
        if (app.IMAGERGBA !== spec.rgba) app.IMAGERGBA = spec.rgba;
        cache[kind] = app;
    }
}

// Never creates: a deleted appearance returns undefined until the next install.
export function appearanceHandle(kind: string): any {
    const cached = cache[kind];
    if (cached === false) return undefined;
    if (cached !== undefined && IsObjectValid(cached)) return cached;
    const spec = APPEARANCES[kind];
    const app = spec === undefined ? undefined : findByName(spec.name);
    cache[kind] = app === undefined ? false : app;
    return app;
}
