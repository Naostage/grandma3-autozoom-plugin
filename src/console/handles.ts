/** @noSelfInFile */
// Helpers for grandMA3 object handles. Always iterate Children(); never index collections by number.

export function children(h: any): any[] {
    if (h === undefined) return [];
    const list = h.Children();
    return list === undefined ? [] : list;
}

export function num(v: unknown): number | undefined {
    if (typeof v === "number") return v;
    if (typeof v === "string") return tonumber(v);
    return undefined;
}

export function findChild(collection: any, name: string): any {
    for (const c of children(collection)) if (c.name === name) return c;
    return undefined;
}
