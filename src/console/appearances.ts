/** @noSelfInFile */
import { APPEARANCES } from "../ui/view-model";
import { children } from "./handles";

// false = looked up and missing: no pool scan per changed cell until the next ensureAppearances().
const cache: { [kind: string]: any } = {};

function pool(): any {
    return (ShowData() as any).Appearances;
}

function findByName(name: string): any {
    for (const a of children(pool())) if (a.name === name) return a;
    return undefined;
}

// Creates missing AutoZoom appearances and reapplies their colours (operator edits are reset on install).
export function ensureAppearances(): void {
    for (const kind in APPEARANCES) {
        const spec = APPEARANCES[kind];
        let app = findByName(spec.name);
        if (app === undefined) {
            app = pool().Acquire();
            app.Name = spec.name;
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
