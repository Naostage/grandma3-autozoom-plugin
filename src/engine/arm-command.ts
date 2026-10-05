/** @noSelfInFile */
import { fmtInt } from "../format";

export function normalizeFids(fids: number[]): number[] {
    const seen: { [key: string]: boolean } = {};
    const out: number[] = [];
    for (const fid of fids) {
        if (fid > 0 && Math.floor(fid) === fid && !seen[fmtInt(fid)]) {
            seen[fmtInt(fid)] = true;
            out.push(fid);
        }
    }
    out.sort((a, b) => a - b);
    return out;
}

export function parseArmList(text: string): number[] {
    const out: number[] = [];
    for (const part of text.split(",")) {
        const n = Number(part.trim());
        if (part.trim() !== "" && n === n) out.push(n);
    }
    return normalizeFids(out);
}
