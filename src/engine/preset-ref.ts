/** @noSelfInFile */

// Preset addresses typed in Setup ("Preset 2.30", "datapool 4 preset 2.30"): anchored at the start, so "Store/Delete/Label … Preset",
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
