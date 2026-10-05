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

export function formatArmList(fids: number[]): string {
    return normalizeFids(fids).map(f => fmtInt(f)).join(",");
}

export function armCommand(fids: number[]): string {
    return `Lua "if AZ then AZ:Arm('${formatArmList(fids)}') end"`;
}

export function parseArmList(text: string): number[] {
    const out: number[] = [];
    for (const part of text.split(",")) {
        const n = Number(part.trim());
        if (part.trim() !== "" && n === n) out.push(n);
    }
    return normalizeFids(out);
}

// Cue commands are separated by ";". A ";" inside a quoted user command would be split too.
export function rewriteCueCommand(existing: string | undefined, armLine: string): string {
    const kept: string[] = [];
    if (existing !== undefined) {
        for (const raw of existing.split(";")) {
            const part = raw.trim();
            if (part !== "" && part.indexOf("AZ:Arm(") < 0) kept.push(part);
        }
    }
    kept.push(armLine);
    return kept.join("; ");
}
