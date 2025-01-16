import { calculateZoomIrisFaderValues, TargetZoomIris } from "./calculate-zoom-iris";
import { getFixtureSizeFaderValue, getGlobalSizeFaderValue, moveFaderGMA3 } from "./handle-execs";
import { getFixturePosition } from "./load-patch";
import { PrintEcho, remap } from "./utils";

export class Vector3 {
    x: number;
    y: number;
    z: number;

    constructor(x: number, y: number, z: number) {
        this.x = x;
        this.y = y;
        this.z = z;
    }

    static getDistance(a: Vector3, b: Vector3): number {
        return Math.sqrt(Math.pow(a.x - b.x, 2) + Math.pow(a.y - b.y, 2) + Math.pow(a.z - b.z, 2));
    }

    distance(a: Vector3): number {
        return Vector3.getDistance(this, a);
    }


}

export type AZ_FTZoom = { min: number; max: number };
export type AZ_FTIris = { min: number; max: number };

export type AZ_FTOpticalParameters = {
    zoom: AZ_FTZoom;
    iris: AZ_FTIris;
}

export class AZ_FixtureType {
    id: number;
    name: string;
    opticalParameters: AZ_FTOpticalParameters;
    mode: string;
    constructor(id: number, name: string, opticalParameters: AZ_FTOpticalParameters, mode: string) {
        this.id = id;
        this.name = name;
        this.opticalParameters = opticalParameters;
        this.mode = mode;
    }

    print(level : number) : void{
        PrintEcho("Fixture Type: " + this.name + " is in " + this.mode + " mode", level);
        PrintEcho("Optical Parameters: Zoom min: " + this.opticalParameters.zoom.min + " max: " + this.opticalParameters.zoom.max, level);
        PrintEcho("Optical Parameters: Iris min: " + this.opticalParameters.iris.min + " max: " + this.opticalParameters.iris.max, level);
    }
}

export class AZ_Fixture {
    fid: number;
    name: string;
    fixtureType: AZ_FixtureType;
    position: Vector3;
    handle: Fixture;
    lastZoom : number;
    lastIris : number;
    constructor(fid: number, name: string, fixtureType: AZ_FixtureType, position: Vector3, handle: Fixture) {
        this.fid = fid;
        this.name = name;
        this.fixtureType = fixtureType;
        this.position = position;
        this.handle = handle;
        this.lastZoom = 0
        this.lastIris = 0;
    }

    print(level: number) : void {
        PrintEcho("Fixture: "+ this.fid + "  -  " + this.name + " at position (" + this.position.x + ", " + this.position.y + ", " + this.position.z + ")", level);
        this.fixtureType.print(level);
    }

    updateTo(targetZI : TargetZoomIris) : void {
        if (Math.round(targetZI.zoom) != this.lastZoom) {
            moveFaderGMA3(this.getZoomFader(), Math.round(targetZI.zoom));
            this.lastZoom = Math.round(targetZI.zoom);
        }
        if (Math.round(targetZI.iris) != this.lastIris && targetZI.iris != -1) {
            moveFaderGMA3(this.getIrisFader(), Math.round(targetZI.iris));
            this.lastIris = Math.round(targetZI.iris);
        }
    }

    getZoomFader():string{
        return "AZ_ZOOM_"+this.fid
    }
    getIrisFader():string{
        return "AZ_IRIS_"+this.fid
    }
}

export class AZ_Marker {
    fid: number;
    cid: number;
    name: string;
    handle: Fixture;
    position : Vector3;

    constructor(fid: number, cid: number, name: string, handle: Fixture) {
        this.fid = fid;
        this.cid = cid;
        this.name = name;
        this.handle = handle;
        this.position = new Vector3(0,0,0);
    }

    print(level : number) {
        PrintEcho("Marker: " + this.fid + " - " + this.name, level)
    }

    update() : void {
        // Printf("AZ->Marker->Update")
        // ShowData().PSNProtocol[1][3]:
        let PSNProtocol = ShowData().PSNProtocol;
        for (let i = 1; i <= PSNProtocol.count; i++){
            let trackingSystem = PSNProtocol[i];
            // Printf(i)
            for(let j = 1; j <= trackingSystem.count; j++){
                // Printf(j)
                let tracker = trackingSystem[j];
                if (tracker.MARKERID == this.cid) {
                    this.position.x = tracker.POSITIONX;
                    this.position.y = tracker.POSITIONY;
                    this.position.z = tracker.POSITIONZ;
                    // PrintEcho("Marker " + this.fid + " | Position (" + this.position.x + ", " + this.position.y + ", " + this.position.z + ")", 0)
                    return;
                }
            }
        }
    }
}

export type AZ_PatchInfo = {
    fixtures: AZ_Fixture[],
    markers: AZ_Marker[]
}

export class AZ_EnabledFixture {
    fixture: AZ_Fixture;
    marker : AZ_Marker;
    beamSize : number;

    constructor(fixture:  AZ_Fixture, marker: AZ_Marker, beamSize:number) {
        this.fixture = fixture;
        this.marker = marker;
        this.beamSize = beamSize
    }

    Update(sizeFaderConfig : AZ_SizeFaderConfig) : void {
        let targettedBeamSize = this.beamSize;
        if (sizeFaderConfig.globalEnabled == true){
            targettedBeamSize = remap(getGlobalSizeFaderValue(), 0, 100, sizeFaderConfig.rangeMin, sizeFaderConfig.rangeMax);
            // PrintEcho("Using global size fader value for fixture " + this.fixture.fid + " : " + targettedBeamSize, 0)
        }
        else if (sizeFaderConfig.fixturesEnabled[this.fixture.fid] == true){
            targettedBeamSize = remap(getFixtureSizeFaderValue(this.fixture.fid), 0, 100, sizeFaderConfig.rangeMin, sizeFaderConfig.rangeMax);
            // PrintEcho("Using fixture size fader value for fixture " + this.fixture.fid + " : " + targettedBeamSize, 0)
        }
        let targetZoomIris = calculateZoomIrisFaderValues(this.fixture.position, this.marker.position, this.fixture.fixtureType.opticalParameters, targettedBeamSize);
        // PrintEcho("Fixture " + this.fixture.fid + " should now be at (zoom :" + targetZoomIris.zoom + " | iris : " + targetZoomIris.iris + ")", 0)
        this.fixture.updateTo(targetZoomIris)
    }
}
export type AZ_SizeFaderConfig = {
    globalEnabled: boolean,
    fixturesEnabled: { [key: number]: boolean },
    rangeMin: number,
    rangeMax: number
}