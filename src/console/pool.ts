/** @noSelfInFile */
import { fmtInt, fmtNum } from "../format";
import { children, findChild } from "./handles";
import { warnOnce } from "./log";

export const POOL = "AutoZoom";
export const POOL_ADDR = `DataPool '${POOL}'`;
export const SIZE_SEQ = "AZ_SIZE";

export function zoomSeqName(fid: number): string { return "AZ_ZOOM_" + fmtInt(fid); }
export function irisSeqName(fid: number): string { return "AZ_IRIS_" + fmtInt(fid); }

export function findPool(): any {
    return findChild(ShowData().DataPools, POOL);
}

export function ensurePool(): any {
    let dp = findPool();
    if (dp === undefined) {
        Cmd(`Store ${POOL_ADDR} /nc`);
        dp = findPool();
    }
    if (dp === undefined) throw new Error("Could not create the AutoZoom data pool");
    return dp;
}

const seqCache: { [name: string]: any } = {};

export function findSequence(name: string): any {
    const cached = seqCache[name];
    if (cached !== undefined && IsObjectValid(cached)) return cached;
    const pool = findPool();
    const seq = pool === undefined ? undefined : findChild(pool.Sequences, name);
    if (seq !== undefined) seqCache[name] = seq;
    return seq;
}

// One cue with the attribute at `physical` (its maximum); the Temp fader crossfades the cue's base value to it.
// Clears the programmer: only runs when the sequence is missing.
export function ensureFaderSequence(name: string, fid: number, attribute: string, physical: number): void {
    ensurePool();
    if (findSequence(name) !== undefined) return;
    Cmd("ClearAll");
    Cmd(`Fixture ${fmtInt(fid)}`);
    Cmd(`Attribute "${attribute}" At Absolute Physical ${fmtNum(physical)}`);
    Cmd(`Store ${POOL_ADDR} Sequence '${name}' /o /nc`);
    Cmd("ClearAll");
}

export function ensureSizeSequence(): void {
    ensurePool();
    if (findSequence(SIZE_SEQ) !== undefined) return;
    Cmd("ClearAll");
    Cmd(`Store ${POOL_ADDR} Sequence '${SIZE_SEQ}' /o /nc`);
}

export function ensureMacro(name: string, luaCall: string): void {
    const pool = ensurePool();
    if (findChild(pool.Macros, name) === undefined) Cmd(`Store ${POOL_ADDR} Macro '${name}' /o /nc`);
    if (luaCall === "") return;
    Cmd(`Store ${POOL_ADDR} Macro '${name}'.1 /o /nc`);
    Cmd(`Set ${POOL_ADDR} Macro '${name}'.1 Property 'Command' 'Lua "AZ:${luaCall}"'`);
}

export function setTemp(name: string, value: number): void {
    const seq = findSequence(name);
    if (seq === undefined) {
        warnOnce("missing:" + name, `Sequence ${name} is missing; run Rescan to recreate it`);
        return;
    }
    seq.SetFader({ value, token: "FaderTemp" });
}

export function readMaster(name: string): number | undefined {
    const seq = findSequence(name);
    if (seq === undefined) return undefined;
    const v = seq.GetFader({ token: "FaderMaster" });
    return typeof v === "number" ? v : undefined;
}

export function poolChildren(kind: "Macros" | "Layouts"): any[] {
    const pool = findPool();
    return pool === undefined ? [] : children(pool[kind]);
}
