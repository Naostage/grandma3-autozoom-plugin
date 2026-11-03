/** @noSelfInFile */
// Console groups and their fixtures, read without touching the operator's selection: a Group's
// SelectionData lists its members as { sf_index, grid } (group probe S1, onPC 2.5.1.1) and
// GetSubfixture(sf_index).fid is the member's FID. Members without a fid are skipped (exact FID match).
import { fidKey } from "../format";
import { GroupInfo } from "../store/rows";

function fidsOf(group: any): number[] {
    const out: number[] = [];
    const seen: { [fid: string]: boolean } = {};
    const [ok, data] = pcall(() => group.SelectionData);
    if (!ok || type(data) !== "table") return out;
    for (const entry of data as any[]) {
        const index = type(entry) === "table" ? tonumber(entry.sf_index) : undefined;
        if (index === undefined) continue;
        const [okSub, sf] = pcall(() => GetSubfixture(index));
        const fid = okSub && sf !== undefined ? tonumber(sf.fid) : undefined;
        if (fid === undefined || seen[fidKey(fid)]) continue;
        seen[fidKey(fid)] = true;
        out.push(fid);
    }
    return out;
}

export function listGroups(): GroupInfo[] {
    const out: GroupInfo[] = [];
    const [ok, groups] = pcall(() => (DataPool() as any).Groups.Children());
    if (!ok || type(groups) !== "table") return out;
    for (const g of groups as any[]) {
        const no = tonumber(g.no);
        if (no !== undefined) out.push({ no, name: tostring(g.name ?? ""), fids: fidsOf(g) });
    }
    out.sort((a, b) => a.no - b.no);
    return out;
}
