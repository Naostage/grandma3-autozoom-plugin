/** @noSelfInFile */
import { SeqRef } from "../model";
import { children, num } from "./handles";

// Probe P6/P7: cue numbers are stored x1000 (Cue 2.5 -> 2500); OffCue has no number and CueZero is 0.
export const CUE_SCALE = 1000;

export function selectedSequence(): SeqRef | undefined {
    const h = SelectedSequence();
    if (h === undefined) return undefined;
    return { id: HandleToStr(h), no: num(h.no) ?? 0, name: tostring(h.name) };
}

function handleOf(seq: SeqRef): any {
    const h = StrToHandle(seq.id);
    return h !== undefined && IsObjectValid(h) ? h : undefined;
}

function cueHandle(seq: SeqRef, no: number): any {
    if (no <= 0) return undefined;
    const stored = Math.round(no * CUE_SCALE);
    for (const cue of children(handleOf(seq))) if (num(cue.no) === stored) return cue;
    return undefined;
}

export function runningCue(seq: SeqRef): number | undefined {
    const h = handleOf(seq);
    if (h === undefined) return undefined;
    const cue = h.CurrentChild();
    if (cue === undefined) return undefined;
    const stored = num(cue.no);
    return stored === undefined || stored <= 0 ? undefined : stored / CUE_SCALE;
}

// Probe P6 found no property for the cue selected in the Sequence Sheet, so this is always undefined:
// the Capture prompt pre-fills the running cue and the user types another number.
export function selectedCue(_seq: SeqRef): number | undefined {
    return undefined;
}

export function readCueCommand(seq: SeqRef, no: number): string | undefined {
    const cue = cueHandle(seq, no);
    if (cue === undefined) return undefined;
    const part = children(cue)[0];
    return part === undefined ? "" : tostring(part.Command ?? "");
}

export function writeCueCommand(seq: SeqRef, no: number, text: string): boolean {
    const cue = cueHandle(seq, no);
    if (cue === undefined) return false;
    const part = children(cue)[0];
    if (part === undefined) return false;
    part.Command = text;
    return true;
}
