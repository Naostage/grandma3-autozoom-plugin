/** @noSelfInFile */
import { fmtInt, fmtNum } from "../format";
import { Config } from "../store/config";

// Programmer commands for "fixture follows marker": marker and XYZ offset. Zoom/iris stay the cue's own;
// while AutoZoom drives the fixture its AZ_BASE (High) and AZ_ZOOM/AZ_IRIS (Super) sequences own them.
export function programCommands(fid: number, cid: number, offset: Config["offset"]): string[] {
    const cmds = [`Fixture ${fmtInt(fid)}`, `Attribute "XYZ_MArker" At ${fmtInt(cid)}`];
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

export function releaseCommands(fid: number): string[] {
    return [`Off Fixture ${fmtInt(fid)}`];
}
