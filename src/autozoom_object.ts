import { PrintEcho, PrintLogLevel, SetLogLevel } from "./utils";
import { fetchFixtures, loadFixtureTypes } from "./load-patch";
import { AZ_EnabledFixture, AZ_PatchInfo, AZ_SizeFaderConfig } from "./types";
import { createSequencesForFixture, moveFaderGMA3 } from "./handle-execs";
import { createMacro } from "./create-macros";
import { IMPORTED_MACROS } from "./macros";


export class AZ_Global_Type {
    patch_info: AZ_PatchInfo;
    enabledFixtures: AZ_EnabledFixture[];
    enabled: boolean;

    sizeFaderConfig : AZ_SizeFaderConfig = {globalEnabled:false, fixturesEnabled:[], rangeMin:0.5, rangeMax:3};
    createSequences = false;

    refreshRate = 30;
    initialized = false;

    useAZDatapool = false;


    constructor() {
        this.patch_info = { fixtures: [], markers: [] };
        this.enabledFixtures = [];
        this.enabled = false;

        PrintEcho("AZ created, patch_info", 10);
    }


    ShowEnabled(): void {
        if (this.enabled) {
            PrintEcho("AutoZoom is enabled", 10);
        } else {
            PrintEcho("AutoZoom is disabled", 10);
        }
    }
    Enable(): void {
        if(!this.initialized){
            this.Start();
        }
        if (!this.enabled) {
            PrintEcho("Enabling Plugin AutoZoom", 10);
            this.enabled = true;
        }
        this.ShowEnabled();

        this.RegisterUpdateLoop();
    }
    Disable(): void {
        if (this.enabled) {
            PrintEcho("Disabling Plugin AutoZoom", 10);

            this.enabled = false;
        }
        this.ShowEnabled();
    }
    Toggle(): void {
        if (this.enabled) {
            this.Disable();
        } else {
            this.Enable();
        }
    }
    ScanPatch(): void {
        this.patch_info = { fixtures: [], markers: [] };
        let fixtureTypes_in_XYZ = loadFixtureTypes();
        let fixture_and_markers = fetchFixtures(fixtureTypes_in_XYZ);
        PrintEcho("--- Scanned all fixtures that have XYZ", 1)
        this.patch_info = { fixtures: fixture_and_markers.fixtures, markers: fixture_and_markers.markers};
        PrintEcho("--- Patch fetched - found " + this.patch_info.fixtures.length + " fixtures and " + this.patch_info.markers.length + " markers.", 10);
    }

    PrintCurrentPatch(): void {
        if (!this){
            PrintEcho("AZ is not defined", 3);
            return;
        }

        if (!(this.patch_info)) {
            PrintEcho("Patch is not defined", 3);
            return;
        }
        if (this.patch_info === undefined) {
            PrintEcho("Nothing is defined, problem...", 3);
            return;
        }
        if (this.patch_info.fixtures === undefined) {
            PrintEcho("Fixtures aren't defined, problem...", 3);
            return;
        }
        if (this.patch_info.markers === undefined) {
            PrintEcho("Markers aren't defined, problem...", 3);
            return;
        }
        if (this.patch_info.fixtures.length == 0) {
            PrintEcho("No fixtures in patch", 3);
            return;
        }
        if (this.patch_info.markers.length == 0) {
            PrintEcho("No markers in patch", 3);
            return;
        }
        PrintEcho("Current Patch", 10);
        PrintEcho("Fixtures", 10);
        for (let fixture of this.patch_info.fixtures) {
            fixture.print(10);
        }
        PrintEcho("Markers", 10);
        for (let marker of this.patch_info.markers) {
            marker.print(10);
        }
    }
    GetFixturesStatus(): void {
        if (this.enabledFixtures.length == 0) {
            PrintEcho("No fixtures enabled", 10);
            return;
        }
        for(let enabledFixture of this.enabledFixtures){
            PrintEcho("Fixture " + enabledFixture.fixture.fid + " -> " + enabledFixture.marker.fid + " | beamsize : " + enabledFixture.beamSize, 10)
        }


    }
    EnableFixture(fixtureid: number, markerid: number, beamSize: number): void {
        // Check if the fixtureid is in the patch_info.fixtures
        // Check if the markerid is in the patch_info.markers
        // Store in enabledFixtures a new AZ_EnabledFixture at index [fixtureid]
        if (!this.patch_info.fixtures) {
            PrintEcho("Patch is not defined", 10);
        }
        if (this.patch_info.fixtures.length === 0) {
            PrintEcho("No fixtures in patch", 10);
            return;
        }
        if (this.patch_info.markers.length === 0) {
            PrintEcho("No markers in patch", 10);
            return;
        }
        for (let fixture of this.patch_info.fixtures) {
            if (fixture.fid === fixtureid) {
                for (let marker of this.patch_info.markers) {
                    if (marker.fid === markerid) {
                        let enabledFixture = new AZ_EnabledFixture(
                            fixture, marker, beamSize)
                        for (let i = 0; i < this.enabledFixtures.length; i++) {
                            if (this.enabledFixtures[i].fixture.fid == fixtureid){
                                this.enabledFixtures[i].marker = marker;
                                this.enabledFixtures[i].beamSize = beamSize;
                                PrintEcho("Updated fixture " + fixtureid + " - Marker : " + marker.fid + " - " + marker.cid + + " |  Beam size : " + beamSize, 10)
                                this.enabledFixtures[i].fixture.forceUpdate();
                                return;
                            }
                        }
                        this.enabledFixtures.push(enabledFixture);
                        PrintEcho("Enabled fixture " + fixtureid + " - Marker : " + marker.fid + " |  Beam size : " + beamSize, 10)
                        return;
                    }
                }
                PrintEcho("No marker with id " + markerid + " found", 10);
                return;
            }
        }
        PrintEcho("No fixture with id " + fixtureid + " found", 10);
    }

    DisableFixture(fixtureid: number): void {
        for (let i = 0; i < this.enabledFixtures.length; i++) {
            if (this.enabledFixtures[i].fixture.fid == fixtureid) {
                delete this.enabledFixtures[i];
                PrintEcho("Disabled fixture " + fixtureid, 10);
                return;
            }
        }
        PrintEcho("Fixture " + fixtureid + " was not enabled", 10);
    }
    LogLevel(levelString: string): void {
        SetLogLevel(levelString);
    }
    GetLogLevel(): void {
        PrintLogLevel();
    }

    DisableAllFixtures() : void {
        this.enabledFixtures = []
        PrintEcho("Disabled all fixtures", 10)
    }

    UpdateMarkers() : void{
        for (let marker of this.patch_info.markers){
            marker.update();
        }
    }

    UpdateFixtures() : void {
        for(let enabledFixture of this.enabledFixtures) {
            enabledFixture.Update(this.sizeFaderConfig);
        }
    }

    expected_remaining_update = 0;
    global_call_repeat = 10;

    UpdateLoop():void {
        this.expected_remaining_update--;
        if(!this.enabled){
            this.expected_remaining_update = 0;
            this.global_call_repeat = 0;
            return;

        }

        this.UpdateMarkers();
        this.UpdateFixtures();

        if (this.expected_remaining_update == 0) {
            this.RegisterUpdateLoop();
        }
    }

    SetRefreshRate(rate: number): void {
        this.refreshRate = rate;
        PrintEcho("Set refresh rate to " + rate + " updates/second", 10);
    }

    RegisterUpdateLoop(): void {
        if (!this.enabled) {
            PrintEcho("Autozoom is disabled, failed to start loop", 10)
            return;
        }
        let updatePeriod = 1/this.refreshRate;
        if (this.expected_remaining_update > 0) {
            PrintEcho("Update loop is already registered, expected remaining update " + this.expected_remaining_update, 1);
            return;
        }

        this.global_call_repeat = this.refreshRate*10;
        this.expected_remaining_update = this.global_call_repeat;
        Timer(()=>{this.UpdateLoop()}, updatePeriod, this.expected_remaining_update);
    }

    Init() : void {
        if(!this.initialized){
            this.Start();
        }
    }

    Start() : void {
        PrintEcho("Plugin GRANDMA3 AUTOZOOM launched ", 10);
        PrintEcho("Plugin version : 1.1.2", 10);
        PrintEcho("Plugin author : Naostage 2025", 10);
        PrintEcho("", 10)
        this.ScanPatch();
        this.ShowEnabled();
    }

    Cleanup() : void {
        this.expected_remaining_update = 0;
        this.global_call_repeat = 0;
        this.enabled = false;
        PrintEcho("Plugin GRANDMA3 AUTOZOOM stopped", 10);
    }

    EnableSizeFader(fid: number) : void {
        for (let fixture of this.patch_info.fixtures){
            if (fixture.fid == fid){
                this.sizeFaderConfig.fixturesEnabled[fid] = true;
                PrintEcho("Enabled size fader for fixture " + fid, 10);
                return;
            }
        }
        PrintEcho("Fixture " + fid + " not found in the patch", 10);
    }

    DisableSizeFader(fid: number) : void {
        for (let fixture of this.patch_info.fixtures){
            if (fixture.fid == fid){
                this.sizeFaderConfig.fixturesEnabled[fid] = false;
                PrintEcho("Disabled size fader for fixture " + fid, 10);
                return;
            }
        }
        PrintEcho("Fixture " + fid + " not found in the patch", 10);
    }

    EnableGlobalSizeFader() : void {
        // Try to create the global size fader (if needed)
        
        this.sizeFaderConfig.globalEnabled = true;
        PrintEcho("Enabled global size fader", 10);
    }

    DisableGlobalSizeFader() : void {
        this.sizeFaderConfig.globalEnabled = false;
        PrintEcho("Disabled global size fader", 10);
    }

    SetSizeFaderRange(min: number, max: number) : void {
        this.sizeFaderConfig.rangeMin = min;
        this.sizeFaderConfig.rangeMax = max;
        PrintEcho("Set size fader range to [" + min + ", " + max + "]", 10);
    }

    EnableDatapool() : void {
        this.useAZDatapool = true;
        PrintEcho("Enabled AZ Datapool", 10);
    }

    DisableDatapool() : void {
        this.useAZDatapool = false;
        PrintEcho("Disabled AZ Datapool", 10);
    }

    CreateMacros(startingIndex : number) : void {
        if (!startingIndex){
            PrintEcho("No starting index provided, macros creation cancelled, Usage : AZ:CreateMacros(<Starting Index>)", 10);
            return;
        }

        for(let i = 0; i < IMPORTED_MACROS.length; i++){
            createMacro(IMPORTED_MACROS[i].name, startingIndex+i, IMPORTED_MACROS[i].commands);
        }
    }

    CreateAZSequences(fid: number) {
        // Checks if fid in enabledFixtures
        // if yes -> Create a sequences => X, Y, Z at 0, Marker set, and Zoom, Iris at min
        // Also create 3 sequences : AZ_ZOOM_fid, AZ_IRIS_fid, AZ_SIZE_fid
        for (let i = 0; i < this.enabledFixtures.length; i++){
            let enabledFixture = this.enabledFixtures[i];
            if (enabledFixture.fixture.fid == fid){
                createSequencesForFixture(enabledFixture, this.useAZDatapool);
                return;
            }
        }
        // if no -> Print error message
        PrintEcho("Fixture " + fid + " is not enabled", 10);
    }

}
