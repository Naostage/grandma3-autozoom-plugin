/** @noSelfInFile */
// Number formatting for command lines, layout texts and config keys.

export function fmtInt(n: number): string {
    return string.format("%d", Math.floor(n + 0.5));
}

export function fmtNum(n: number): string {
    let s = string.format("%.3f", n);
    while (s.endsWith("0")) s = s.substring(0, s.length - 1);
    if (s.endsWith(".")) s = s.substring(0, s.length - 1);
    return s === "-0" ? "0" : s;
}

export function fidKey(fid: number): string {
    return fmtInt(fid);
}
