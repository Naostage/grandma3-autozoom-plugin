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


// Iterate on Children() rather than indexing 0..Count() : on 2.5, DataPools[i] can be nil for some i < Count().
// Children() also returns a plain Lua array, which avoids TSTL's index translation on typed MA3 objects.
function getDataPools(): any[] {
    let datapools: any[] = [];
    for (let datapool of ShowData().DataPools.Children()){
        if (datapool != null){
            datapools.push(datapool);
        }
    }
    return datapools;
}

export function getSeqHandleFromName(seqName: string): any{
    // Access sequences by the named "Sequences" child : its index in the datapool changed in 2.5 (6 -> 7).
    for (let datapool of getDataPools()){
        let sequences = datapool.Sequences;
        if (sequences == null){
            continue;
        }
        for (let seq of sequences.Children()){
            if (seq != null && seq.Name == seqName){
                return seq;
            }
        }
    }
    return null;
}


let missingSizeFaderWarned : { [seqName: string]: boolean } = {};

function getSizeFaderValue(seqName : string) : number | null {
    let seq = getSeqHandleFromName(seqName);
    if (seq == null){
        // Called every frame : only warn once per missing fader
        if (!missingSizeFaderWarned[seqName]){
            PrintEcho("Size fader " + seqName + " not found, using the fixed beam size", 3);
            missingSizeFaderWarned[seqName] = true;
        }
        return null;
    }
    missingSizeFaderWarned[seqName] = false;
    return seq.GetFader({"token":"FaderMaster"});
}

export function getFixtureSizeFaderValue(fid : number) : number | null {
    return getSizeFaderValue("AZ_SIZE_"+fid);
}


export function getGlobalSizeFaderValue() : number | null {
    return getSizeFaderValue("AZ_SIZE");
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
    for (let datapool of getDataPools()){
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
    // Zoom must be quoted ("Z" alone parses as Zero), and the value is given in physical units
    // so it does not depend on the user's readout setting.
    Cmd("Fixture " + fixture.fid)
    Cmd("Attribute \"Zoom\" At Absolute Physical " + fixture.fixtureType.opticalParameters.zoom.max);
    if (useAZDatapool){
        CmdIndirectWait("Store Datapool 'AZ' Sequence 'AZ_ZOOM_"+fixture.fid + "' /o /nc");
    } else {
        CmdIndirectWait("Store Sequence 'AZ_ZOOM_"+fixture.fid + "' /o /nc");
    }

    ClearAll();
    if (fixture.fixtureType.opticalParameters.iris.max != fixture.fixtureType.opticalParameters.iris.min){
        Cmd("Fixture " + fixture.fid)
        Cmd("Attribute \"Iris\" At Absolute Physical " + fixture.fixtureType.opticalParameters.iris.max);
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
