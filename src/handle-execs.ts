import { PrintEcho } from "./utils";

export function moveFaderGMA3(faderName: string, level: number){
    PrintEcho("Moving fader " + faderName + " to " + level, 0)   
    // CmdIndirect("FaderMaster " + faderName + " At " + level);
    let seq = getSeqHandleFromName(faderName);
    seq.SetFader({"value":level});

}


function getSeqHandleFromName(seqName: string): any{
    for (let datapool of ShowData().DataPools){
        //@ts-expect-error
        for (let seq of datapool.Sequences){
            if (seq.Name == seqName){
                return seq;
            }
        }
        return null;
    }
}