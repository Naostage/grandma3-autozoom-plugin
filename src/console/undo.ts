/** @noSelfInFile */
import { stripAnsi } from "../engine/preset-ref";
import { info } from "./log";

export function lastCommand(): string | undefined {
    const o: any = CmdObj();
    const v = o.LastCommand;
    return v === undefined ? undefined : tostring(v);
}

export function topUndoName(): string | undefined {
    const o: any = CmdObj();
    const undos: any = o.Undos;
    if (undos === undefined) return undefined;
    const entry = undos[undos.UndoIndex + 1];   // the console's own indexing (as FXMAker 2.5)
    return entry === undefined || entry.Name === undefined ? undefined : tostring(entry.Name);
}

// "<UndoIndex>|<entry count>|<top entry name>": any new undo entry changes it (count or name, even when UndoIndex
// stays put). Parts that cannot be read are empty.
export function undoMark(): string {
    const o: any = CmdObj();
    const undos: any = o.Undos;
    if (undos === undefined) return "||";
    let count = "";
    try {
        const c = undos.Count();
        if (c !== undefined) count = tostring(c);
    } catch (e) {
        count = "";
    }
    const name = topUndoName();
    return `${tostring(undos.UndoIndex ?? "")}|${count}|${name === undefined ? "" : stripAnsi(name)}`;
}

export function undoProgrammer(): void {
    const profile: any = CurrentProfile();
    const saved = profile.OopsProgrammer;
    profile.OopsProgrammer = true;
    try {
        Cmd("Oops /nc");
    } catch (e) {
        info("Oops failed: " + tostring(e));
    } finally {
        profile.OopsProgrammer = saved;
    }
}
