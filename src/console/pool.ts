/** @noSelfInFile */
import { fmtInt, fmtNum } from "../format";
import { children, findChild, num } from "./handles";
import { warnOnce } from "./log";

export const POOL = "AutoZoom";
export const POOL_ADDR = `DataPool '${POOL}'`;
export const SIZE_SEQ = "AZ_SIZE";
export const PLUGIN_NAME = "GMA3 Autozoom";          // package.json plugin_name: renaming the plugin breaks the AZ Start macro
export const START_MACRO = "AZ Start";

export function zoomSeqName(fid: number): string { return "AZ_ZOOM_" + fmtInt(fid); }
export function irisSeqName(fid: number): string { return "AZ_IRIS_" + fmtInt(fid); }
export function baseSeqName(fid: number): string { return "AZ_BASE_" + fmtInt(fid); }

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

// One cue with the attribute at `physical` (its maximum); the Temp fader crossfades from the AZ_BASE value to it.
// Clears the programmer: only runs when the sequence is missing.
export function ensureFaderSequence(name: string, fid: number, attribute: string, physical: number): void {
    ensureCueSequence(name, fid, [[attribute, physical]]);
}

// One cue holding each [attribute, physical value] for the fixture. Only runs when the sequence is missing.
export function ensureCueSequence(name: string, fid: number, values: [string, number][]): void {
    ensurePool();
    if (findSequence(name) !== undefined) return;
    Cmd("ClearAll");
    Cmd(`Fixture ${fmtInt(fid)}`);
    for (const [attribute, physical] of values) Cmd(`Attribute "${attribute}" At Absolute Physical ${fmtNum(physical)}`);
    Cmd(`Store ${POOL_ADDR} Sequence '${name}' /o /nc`);
    Cmd("ClearAll");
}

// Probe 4 (2.5.1.0): a High sequence beats normal cues; a Super Temp-fader sequence stays above a re-activated High base.
export function setPriority(name: string, priority: "High" | "Super"): void {
    Cmd(`Set ${POOL_ADDR} Sequence '${name}' Property 'Priority' '${priority}'`);
}

export function sequenceOn(name: string): void { Cmd(`On ${POOL_ADDR} Sequence '${name}'`); }
export function sequenceOff(name: string): void { Cmd(`Off ${POOL_ADDR} Sequence '${name}'`); }

export function ensureSizeSequence(): void {
    ensurePool();
    if (findSequence(SIZE_SEQ) !== undefined) return;
    Cmd("ClearAll");
    Cmd(`Store ${POOL_ADDR} Sequence '${SIZE_SEQ}' /o /nc`);
}

// Macro line commands are set inside '…', so they must not contain single quotes.
function writeMacroLine(name: string, command: string): void {
    Cmd(`Store ${POOL_ADDR} Macro '${name}'.1 /o /nc`);
    Cmd(`Set ${POOL_ADDR} Macro '${name}'.1 Property 'Command' '${command}'`);
}

export const CELL_PREFIX = "AZ ";

export function cellSequenceName(key: string): string {
    return CELL_PREFIX + key;
}

// Layout cell = sequence (BeatGrid ensureSeq): cue 1 part 0 runs AZ:<luaCall> only while an AutoZoom instance
// exists (no Lua error after a show load); display-only cells have no command.
export function ensureCellSequence(name: string, luaCall: string): any {
    const dp = ensurePool();
    const command = luaCall === "" ? "" : `Lua "if AZ then AZ:${luaCall} end"`;
    let seq = findSequence(name);
    if (seq === undefined) {
        seq = dp.Sequences.Acquire();
        seq.Name = name;
        const cue = seq.Append();
        cue.No = 1;
        const part = cue.Create(1);
        part.Command = command;
        return seq;
    }
    let cue = findCueOne(seq);
    if (cue === undefined) {
        cue = seq.Append();
        cue.No = 1;
        cue.Create(1);
    }
    const part = children(cue)[0];
    if (part !== undefined && tostring(part.Command ?? "") !== command) part.Command = command;
    return seq;
}

// Cue 1 by name (BeatGrid), else by number (read back x1000); never OffCue/CueZero.
function findCueOne(seq: any): any {
    const named = seq["Cue 1"];
    if (named !== undefined) return named;
    for (const c of children(seq)) {
        const n = num(c.no);
        if (n === 1 || n === 1000) return c;
    }
    return undefined;
}

// 2.0.0.1 bound layout cells to `AZ <key>` macros; cells are sequences now. AZ Start is kept.
export function removeCellMacros(): void {
    const names: string[] = [];
    for (const m of poolChildren("Macros")) {
        const name = tostring(m.name ?? "");
        if (name.startsWith(CELL_PREFIX) && name !== START_MACRO) names.push(name);
    }
    for (const name of names) Cmd(`Delete ${POOL_ADDR} Macro '${name}' /nc`);
}

// Macro with a raw command line, created once: an existing macro is left as the operator has it.
export function ensureRawMacro(name: string, command: string): void {
    const pool = ensurePool();
    if (findChild(pool.Macros, name) !== undefined) return;
    Cmd(`Store ${POOL_ADDR} Macro '${name}' /o /nc`);
    writeMacroLine(name, command);
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
