import { PrintEcho } from "./utils";

export function moveFaderGMA3(faderName: string, level: number){
    PrintEcho("Moving fader " + faderName + " to " + level, 0)   
    // CmdIndirect("FaderMaster " + faderName + " At " + level);
    let seq = getSeqHandleFromName(faderName);
    if (seq == null){
        PrintEcho("Fader not found", 3); // Error
        return;
    }
    seq.SetFader({"value":level, "token":"FaderTemp"});

}


export function getSeqHandleFromName(seqName: string): any{
    for (let i = 0; i < ShowData().DataPools.Count(); i++){
        let datapool = ShowData().DataPools[i];
        for (let j = 0; j < datapool[6].Count(); j++){
            let seq = datapool[6][j];
            //@ts-expect-error
            if (seq.Name == seqName){
                return seq;
            }
        }
        return null;
    }
}


export function getFixtureSizeFaderValue(fid : number) : number{
    let seqName = "AZ_SIZE_"+fid;
    let seq = getSeqHandleFromName(seqName);
    return seq.GetFader({"token":"FaderMaster"});
}


export function getGlobalSizeFaderValue() : number {
    let seqName = "AZ_SIZE";
    let seq = getSeqHandleFromName(seqName);
    return seq.GetFader({"token":"FaderMaster"});
}