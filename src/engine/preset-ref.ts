/** @noSelfInFile */

// Preset taps as they appear in CmdObj().LastCommand (FXMAker/BounceMAker 2.5 match the same two forms).
export function parsePresetCommand(command: string): string | undefined {
    const lower = command.toLowerCase();
    const [dpStart, , dp, a, b] = string.find(lower, "datapool%s+(%d+)%s+preset%s+(%d+)%.(%d+)");
    if (dpStart !== undefined) return `DataPool ${dp} Preset ${a}.${b}`;
    const [pStart, , p, q] = string.find(lower, "preset%s+(%d+)%.(%d+)");
    if (pStart !== undefined) return `${p}.${q}`;
    return undefined;
}

export function stripAnsi(text: string): string {
    const [out] = string.gsub(text, "\x1b%[[%d;]*m", "");
    return out;
}

// Plain-text containment: the undo entry name contains the command (without a leading "OK:").
export function undoMatches(undoName: string | undefined, command: string): boolean {
    if (undoName === undefined) return false;
    let cmd = command.trim();
    if (cmd.startsWith("OK:")) cmd = cmd.substring(3).trim();
    if (cmd === "") return false;
    const [found] = string.find(stripAnsi(undoName), cmd, 1, true);
    return found !== undefined;
}
