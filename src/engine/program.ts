/** @noSelfInFile */
import { fmtInt, fmtNum } from "../format";
import { Config } from "../store/config";
import { Optics } from "./beam";

// Programmer commands for "fixture follows marker": marker, XYZ offset, zoom/iris at the AutoZoom base (minimum).
export function programCommands(fid: number, cid: number, optics: Optics, offset: Config["offset"]): string[] {
    const cmds = [`Fixture ${fmtInt(fid)}`, `Attribute "XYZ_MArker" At ${fmtInt(cid)}`];
    if (offset.source === "preset" && offset.preset !== "") {
        const target = offset.preset.startsWith("DataPool") ? offset.preset : `Preset ${offset.preset}`;
        cmds.push(`Attribute "XYZ_X" Thru "XYZ_Z" At ${target}`);
    } else {
        cmds.push(`Attribute "XYZ_X" At ${fmtNum(offset.values[0])}`);
        cmds.push(`Attribute "XYZ_Y" At ${fmtNum(offset.values[1])}`);
        cmds.push(`Attribute "XYZ_Z" At ${fmtNum(offset.values[2])}`);
    }
    cmds.push(`Attribute "Zoom" At Absolute Physical ${fmtNum(optics.zoomMin)}`);
    if (optics.irisMax > optics.irisMin) cmds.push(`Attribute "Iris" At Absolute Physical ${fmtNum(optics.irisMin)}`);
    return cmds;
}

export function releaseCommands(fid: number): string[] {
    return [`Off Fixture ${fmtInt(fid)}`];
}
