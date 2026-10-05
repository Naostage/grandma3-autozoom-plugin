/** @noSelfInFile */
export function loadText(key: string): string | undefined {
    const v = GetVar(GlobalVars(), key);
    return v === undefined ? undefined : tostring(v);
}

export function saveText(key: string, value: string): void {
    SetVar(GlobalVars(), key, value);
}
