import { PrintEcho } from "./utils";

export function moveFaderGMA3(faderName: string, level: number){
    PrintEcho("Trying to move fader " + faderName + " to " + level + "force", 0)   
    CmdIndirect("FaderMaster " + faderName + " At " + level);
}