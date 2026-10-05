/** @noSelfInFile */

// Preset taps as they appear in CmdObj().LastCommand: anchored at the start, so "Store/Delete/Label … Preset",
// "Fixture 1 At Preset" or the plugin's own `Attribute … At Preset …` are not taps.
// Accepted: [OK:] [At|Go+|Call] [DataPool <n>] Preset <p>.<q> (case-insensitive).
export function parsePresetCommand(command: string): string | undefined {
    let s = command.trim().toLowerCase();
    [s] = string.gsub(s, "^ok:%s*", "");
    [s] = string.gsub(s, "^at%s+", "");
    [s] = string.gsub(s, "^go%+%s+", "");
    [s] = string.gsub(s, "^call%s+", "");
    const [dp, a, b] = string.match(s, "^datapool%s+(%d+)%s+preset%s+(%d+)%.(%d+)");
    if (dp !== undefined) return `DataPool ${dp} Preset ${a}.${b}`;
    const [p, q] = string.match(s, "^preset%s+(%d+)%.(%d+)");
    if (p !== undefined) return `${p}.${q}`;
    return undefined;
}

export function stripAnsi(text: string): string {
    const [out] = string.gsub(text, "\x1b%[[%d;]*m", "");
    return out;
}

function normalize(text: string): string {
    let t = stripAnsi(text).trim();
    if (t.toLowerCase().startsWith("ok:")) t = t.substring(3);
    const [collapsed] = string.gsub(t.trim(), "%s+", " ");
    return collapsed.toLowerCase();
}

const NOT_A_TAP = ["store", "delete", "copy", "move", "label", "edit", "update", "assign", "attribute"];

// Strict plain-text match: the undo entry is the tapped command itself (ANSI, "OK:", case and spacing ignored),
// or ends with it; entries that store/delete/edit/... a preset never match.
export function undoMatches(undoName: string | undefined, command: string): boolean {
    if (undoName === undefined) return false;
    const undo = normalize(undoName);
    const cmd = normalize(command);
    if (cmd === "" || undo === "") return false;
    for (const verb of NOT_A_TAP) if (undo.startsWith(verb)) return false;
    return undo === cmd || undo.endsWith(" " + cmd);
}
