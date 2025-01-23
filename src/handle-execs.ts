import { AZ_EnabledFixture, AZ_Fixture } from "./types";
import { ClearAll, PrintEcho } from "./utils";

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
        for (let j = 1; j <= datapool[6].Count(); j++){
            let seq = datapool[6][j];
            //@ts-expect-error
            if (seq.Name == seqName){
                return seq;
            }
        }
    }
    return null;
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


function storeTrackingCue(enabledFixture : AZ_EnabledFixture,) : void {
    // ClearAll();
    // We need in the programmer :
    // - X Y Z at 0
    // - StageMarker set to the marker cid
    // - Zoom at min
    // - Iris at min
    // TODO : V2
    PrintEcho("Not implemented yet", 3);
}


function createAZDatapool() : void {
    for (let i = 0; i < ShowData().DataPools.Count(); i++){
        let datapool = ShowData().DataPools[i];
        if (datapool.name == "AZ"){
            return;
        }
    }
    Cmd("Store DataPool 'AZ'");
}


function createTrackingSequence(fixtureid: number) : void {
    // ClearAll();
    // let command : string = "Store Sequence 'AZ_TRACK_" + fixtureid + "' Cue 0.5";
    // Cmd(command);
    PrintEcho("Not implemented yet", 3);
}

function createZoomIrisSequence(fixture : AZ_Fixture, useAZDatapool : boolean) : void {
    if (useAZDatapool){
        createAZDatapool();
    }
    ClearAll();
    Cmd("Fixture " + fixture.fid)
    Cmd("Attribute Zoom At " + fixture.fixtureType.opticalParameters.zoom.max);
    if (useAZDatapool){
        CmdIndirectWait("Store Datapool 'AZ' Sequence 'AZ_ZOOM_"+fixture.fid + "' /o /nc");
    } else {
        CmdIndirectWait("Store Sequence 'AZ_ZOOM_"+fixture.fid + "' /o /nc");
    }

    ClearAll();
    if (fixture.fixtureType.opticalParameters.iris.max != fixture.fixtureType.opticalParameters.iris.min){
        Cmd("Fixture " + fixture.fid)
        Cmd("Attribute Iris At " + fixture.fixtureType.opticalParameters.iris.max);
        if (useAZDatapool){
            CmdIndirectWait("Store Datapool 'AZ' Sequence 'AZ_IRIS_"+fixture.fid + "' /o /nc");
        } else {
            CmdIndirectWait("Store Sequence 'AZ_IRIS_"+fixture.fid + "' /o /nc");
        }
    }
}

function createSizeSequence(fixture : AZ_Fixture, useAZDatapool:boolean) : void {
    if (useAZDatapool){
        createAZDatapool();
    }
    ClearAll();
    if(useAZDatapool){
        CmdIndirectWait("Store Datapool 'AZ' Sequence 'AZ_SIZE_"+ fixture.fid + "' /o /nc");
        CmdIndirectWait("Store Datapool 'AZ' Sequence 'AZ_SIZE' /o /nc");
    } else {
        CmdIndirectWait("Store Sequence 'AZ_SIZE_"+ fixture.fid + "' /o /nc");
        CmdIndirectWait("Store Sequence 'AZ_SIZE' /o /nc");
    }
}

export function createSequencesForFixture(enabledFixture : AZ_EnabledFixture, useAZDatapool: boolean) : void {
    ClearAll();
    // if (getSeqHandleFromName("AZ_TRACK_"+enabledFixture.fixture.fid) == null){
    //     createTrackingSequence(enabledFixture.fixture.fid);
    // }
    // storeTrackingCue(enabledFixture);
    createZoomIrisSequence(enabledFixture.fixture, useAZDatapool);
    createSizeSequence(enabledFixture.fixture, useAZDatapool);
    if (useAZDatapool){
        PrintEcho("Sequences created for fixture " + enabledFixture.fixture.fid + " in AZ Datapool", 0);
    } else {
        PrintEcho("Sequences created for fixture " + enabledFixture.fixture.fid, 0);
    }
}