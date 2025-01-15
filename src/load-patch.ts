// The goal of this file is to return all fixture types that are in XYZ mode enabled
import { AZ_Fixture, AZ_FixtureType, AZ_Marker, Vector3 } from "./types";
import { PrintEcho } from "./utils";

export interface AZ_FTZoom {
    min: number;
    max: number;
}

export interface AZ_FTIris {
    min: number;
    max: number;
}

export interface AZ_FTOpticalParameters {
    zoom: AZ_FTZoom;
    iris: AZ_FTIris;
}


export function getFTZoom(fixtureType: DMXMode): AZ_FTZoom {
    let min : number | undefined = 0;
    let max : number | undefined = 0;
    fixtureType.DMXChannels.forEach((channel) => {
        // Check if there are children
        if (channel.Children().length == 0) {
            return;
        }

        // Check if the channel is a zoom channel
        if (channel.Children()[0].attribute == "Zoom") {
            min = channel.Children()[0].Children()[0].physicalFrom;
            max = channel.Children()[0].Children()[0].physicalTo;
        }
        
    });
    return { min: Math.min(min,max), max: Math.max(min,max) };
}

export function getFTIris(fixtureType: DMXMode): AZ_FTIris {
    let min : number | undefined = 0;
    let max : number | undefined = 0;
    fixtureType.DMXChannels.forEach((channel) => {
        // Check if there are children
        if (channel.Children().length == 0) {
            return;
        }

        // Check if the channel is an iris channel
        if (channel.Children()[0].attribute == "Iris") {
            min = channel.Children()[0].Children()[0].physicalFrom;
            max = channel.Children()[0].Children()[0].physicalTo;
        }
    });
    if (min === undefined) {
        min = 0;
    }
    if (max === undefined) {
        max = 0;
    }
    return { min: Math.min(min,max), max: Math.max(min, max) };
}

export function getOpticalParameters(fixtureType: DMXMode): AZ_FTOpticalParameters {
    let zoom : AZ_FTZoom = getFTZoom(fixtureType);
    let iris : AZ_FTIris = getFTIris(fixtureType);
    if (zoom.min === undefined || zoom.max === undefined || iris.min === undefined || iris.max === undefined) {
        return { zoom: { min: 0, max: 0 }, iris: { min: 0, max: 0 } };
    }
    return {
        zoom: getFTZoom(fixtureType),
        iris: getFTIris(fixtureType)
    };
}

export function loadFixtureTypes(): AZ_FixtureType[] {
    let returnFTs: AZ_FixtureType[] = [];
    let fixtureTypes: FixtureTypeObj[] = Patch().FixtureTypes.Children();
    // PrintEcho("Number of fixture types : " + fixtureTypes.length);
    // Add the rest of the implementation here
    fixtureTypes.forEach((fixtureType) => {
        let modes : DMXModes = fixtureType.DMXModes;
        if (modes === undefined) {
            return null;
        }
        modes.forEach((mode) => {
            // PrintEcho("Examining mode : " + mode.Name + " for fixture type : " + fixtureType.Name + " ... XYZ : " + mode.XYZ);
            if (mode.XYZ === true) {
                let opticalParameters = getOpticalParameters(mode);
                let id = fixtureType.id;
                let name = fixtureType.Name;
                let ft = new AZ_FixtureType(id, name, opticalParameters, mode.Name);
                returnFTs.push(ft);
            }
        });
    });
    return returnFTs;
}

export function getFixturePosition(fixture: FixtureTypeObj ): Vector3 {
    return new Vector3(fixture.POSX, fixture.POSY, fixture.POSZ);
}

function searchXYZFixtures(fixtureOrGroup: any, return_fixtures: AZ_Fixture[], return_markers: AZ_Marker[], XYZFixtureTypes: AZ_FixtureType[]) {
    // PrintEcho("Fixture Name : " + fixtureOrGroup.Name + " - Fixture IDType : " + fixtureOrGroup.IDType);
    if (fixtureOrGroup.IDType == "MArker") {
        let marker = new AZ_Marker (
            fixtureOrGroup.fid, fixtureOrGroup.cid, fixtureOrGroup.name, fixtureOrGroup
        )
        return_markers.push(marker);
        // PrintEcho("Found marker : " + marker.name);
        return;
    }
    // search if fixtureOrGroup.FixtureType has "Grouping" in it
    if (fixtureOrGroup.FixtureType === undefined) {
        return;
    }
    let fixtureType : FixtureTypeObj= fixtureOrGroup.FixtureType;
    let fixtureTypeName = fixtureType.Name;
    // PrintEcho("Analyzing new fixture : " + fixtureTypeName)
    if (fixtureTypeName == "Grouping") {
        // PrintEcho("Fixture is a group")
        // PrintEcho("Group : " + fixtureOrGroup.name)
        let fixtures = fixtureOrGroup.Children();
        
        for (let i = 0; i < fixtureOrGroup.count; i++) {
            searchXYZFixtures(fixtures[i+1], return_fixtures, return_markers, XYZFixtureTypes);
        }
    }
    else {
        // PrintEcho("Searching in group " + fixtureOrGroup.name)
        // Search if the fixture type is in XYZFixtureTypes
        let az_ft : AZ_FixtureType | null = null;
        XYZFixtureTypes.forEach((fixtureTypeXYZ) => {
            if (!(fixtureTypeXYZ.name === fixtureTypeName)) {
                return;
            }
            else{
                az_ft = fixtureTypeXYZ;
            }});
        if (az_ft === null) {
            return;
        }
        if (fixtureOrGroup.fid == "None") {
            return;
        }
        let fixture: AZ_Fixture = new AZ_Fixture(fixtureOrGroup.fid, fixtureOrGroup.Name, az_ft, getFixturePosition(fixtureOrGroup), fixtureOrGroup);

        if (az_ft !== undefined && fixture !== undefined) {
            return_fixtures.push(fixture);
            // @ts-ignore
            // PrintEcho("Found fixture : " + fixture.name + " with fixture type : " + az_ft.name + " at position : " + fixture.position.x + ", " + fixture.position.y + ", " + fixture.position.z);
        }
    }
    
}


// Create a combination type of AZ_Fixture[] and AZ_Marker[]
export type AZ_FixtureMarker = {
    fixtures: AZ_Fixture[];
    markers: AZ_Marker[];
}

export function fetchFixtures(XYZFixtureTypes : AZ_FixtureType[]): AZ_FixtureMarker {
    let return_fixtures: AZ_Fixture[] = [];
    let return_markers: AZ_Marker[] = [];
    let stages = Patch().Stages;
    if (stages.count === 0) {
        PrintEcho("No stages found", 3);
        return { fixtures: [], markers: [] };
    }   
    PrintEcho("Number of stages : " + stages.count, 0);
    for(let i = 0; i < stages.count; i++) {
        PrintEcho("Stage number : " + (i+1),0);
        let stage = stages.Children()[i+1];
        //stage.Dump();
        let fixtures = stage.Fixtures.Children();
        for (let j = 1; j <= stage.Fixtures.count; j++) {
            let fixture = fixtures[j];
            // PrintEcho("Fixture number : " + (j+1));
            // PrintEcho("Fixture name : " + fixture.Name);
            searchXYZFixtures(fixture, return_fixtures, return_markers, XYZFixtureTypes);
        }
    }
    return { fixtures: return_fixtures, markers: return_markers };
}
