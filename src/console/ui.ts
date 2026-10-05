/** @noSelfInFile */
import { fmtNum } from "../format";
import { Config, SetupAnswers } from "../store/config";
import { warnOnce } from "./log";

export function prompt(title: string, value: string): string | undefined {
    const answer = TextInput(title, value);
    return answer === undefined ? undefined : tostring(answer);
}

const INPUTS = ["Offset preset", "Offset X (m)", "Offset Y (m)", "Offset Z (m)", "Size min (m)", "Size max (m)", "Refresh rate (Hz)"];

export function setupDialog(c: Config): SetupAnswers | undefined {
    const values = [c.offset.preset, fmtNum(c.offset.values[0]), fmtNum(c.offset.values[1]), fmtNum(c.offset.values[2]),
        fmtNum(c.range[0]), fmtNum(c.range[1]), fmtNum(c.rate)];
    const r: any = MessageBox({
        title: "AutoZoom setup",
        message: "XYZ offset applied when you tap a marker cell, size fader range and refresh rate.",
        commands: [{ value: 1, name: "Save" }, { value: 2, name: "Pick preset…" }, { value: 0, name: "Cancel" }],
        inputs: INPUTS.map((name, i) => ({ name, value: values[i] })),
        selectors: [{ name: "Offset source", selectedValue: c.offset.source === "preset" ? 1 : 2, values: { Preset: 1, Values: 2 } }],
    } as any);
    if (r === undefined || (r.result !== 1 && r.result !== 2)) return undefined;
    const input = (name: string) => tostring(r.inputs?.[name] ?? "");
    return {
        pick: r.result === 2,
        source: r.selectors?.["Offset source"] === 1 ? "preset" : "values",
        preset: input(INPUTS[0]), x: input(INPUTS[1]), y: input(INPUTS[2]), z: input(INPUTS[3]),
        min: input(INPUTS[4]), max: input(INPUTS[5]), rate: input(INPUTS[6]),
    };
}

// Runs fn in its own Timer coroutine, so a prompt it opens does not pause the update loop.
export function later(fn: () => void): void {
    Timer(() => fn(), 0, 1);
}

let generation = 0;
let activeCleanup: (() => void) | undefined;

// Batches of rate*10 timer calls re-armed by the last call; a generation number makes stale batches no-ops.
export function startLoop(rate: number, tick: () => void, cleanup: () => void): void {
    generation++;
    const gen = generation;
    const batch = Math.max(1, Math.floor(rate * 10));
    let left = 0;
    function step(): void {
        if (gen !== generation) return;
        left--;
        try {
            tick();
        } catch (e) {
            warnOnce("loop:" + tostring(e), "Update failed: " + tostring(e));
        }
        if (left <= 0 && gen === generation) arm();
    }
    function arm(): void {
        left = batch;
        Timer(step, 1 / rate, batch);
    }
    activeCleanup = cleanup;
    arm();
}

export function stopLoop(): void {
    generation++;
    const cleanup = activeCleanup;
    activeCleanup = undefined;
    if (cleanup !== undefined) cleanup();
}

export function runCommands(commands: string[]): void {
    for (const c of commands) Cmd(c);
}
