/** @noSelfInFile */
import { fmtInt, fmtNum } from "../format";
import { Config } from "../store/config";

// Programmer commands for "fixture follows marker": marker and XYZ offset. Zoom/iris stay the cue's own;
// while AutoZoom drives the fixture its AZ_BASE (High) and AZ_ZOOM/AZ_IRIS (Super) sequences own them.
// Several fixtures (a group row) are selected in one command and share the same values.
export function programCommands(fids: number[], cid: number, offset: Config["offset"]): string[] {
    if (fids.length === 0) return [];
    const cmds = [selection(fids), `Attribute "XYZ_MArker" At ${fmtInt(cid)}`];
    if (offset.source === "preset" && offset.preset !== "") {
        const target = offset.preset.startsWith("DataPool") ? offset.preset : `Preset ${offset.preset}`;
        cmds.push(`Attribute "XYZ_X" Thru "XYZ_Z" At ${target}`);
    } else {
        cmds.push(`Attribute "XYZ_X" At ${fmtNum(offset.values[0])}`);
        cmds.push(`Attribute "XYZ_Y" At ${fmtNum(offset.values[1])}`);
        cmds.push(`Attribute "XYZ_Z" At ${fmtNum(offset.values[2])}`);
    }
    return cmds;
}

export function releaseCommands(fids: number[]): string[] {
    return fids.length === 0 ? [] : [`Off ${selection(fids)}`];
}

function selection(fids: number[]): string {
    return "Fixture " + fids.map(f => fmtInt(f)).join(" + ");
}
