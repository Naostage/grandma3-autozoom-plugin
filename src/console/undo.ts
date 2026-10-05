/** @noSelfInFile */
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

export function undoProgrammer(): void {
    const profile: any = CurrentProfile();
    const saved = profile.OopsProgrammer;
    profile.OopsProgrammer = true;
    try {
        Cmd("Oops /nc");
    } finally {
        profile.OopsProgrammer = saved;
    }
}
