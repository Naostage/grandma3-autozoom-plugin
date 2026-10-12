import { PrintEcho, PrintLogLevel, Popup, SetLogLevel } from "./utils";
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

        PrintEcho("AZ created, patch_info", 0);
    }


    statusMessage(): string {
        return this.enabled ? "AutoZoom is enabled" : "AutoZoom is disabled";
    }

    ShowEnabled(): void {
        Popup(this.statusMessage());
    }
    Enable(): void {
        if(!this.initialized){
            this.Start();
        }
        this.enabled = true;
        this.enabledFixtures.forEach(enabledFixture => enabledFixture.fixture.invalidate());
        this.RegisterUpdateLoop();
        this.ShowEnabled();
    }
    Disable(): void {
        this.enabled = false;
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
        let enabledCount = this.enabledFixtures.length;
        let message = this.loadPatch();
        Popup(message, this.enabledFixtures.length < enabledCount ? 2 : 10);
    }

    loadPatch(): string[] {
        this.patch_info = { fixtures: [], markers: [] };
        let fixtureTypes_in_XYZ = loadFixtureTypes();
        let fixture_and_markers = fetchFixtures(fixtureTypes_in_XYZ);
        PrintEcho("--- Scanned all fixtures that have XYZ", 1)
        this.patch_info = { fixtures: fixture_and_markers.fixtures, markers: fixture_and_markers.markers};
        let removedFixtures: number[] = [];
        this.enabledFixtures = this.enabledFixtures.filter(enabledFixture => {
            let fixture = this.patch_info.fixtures.find(fixture => fixture.fid === enabledFixture.fixture.fid);
            let marker = this.patch_info.markers.find(marker => marker.fid === enabledFixture.marker.fid);
            if (!fixture || !marker) {
                removedFixtures.push(enabledFixture.fixture.fid);
                return false;
            }
            enabledFixture.fixture = fixture;
            enabledFixture.marker = marker;
            return true;
        });

        let message = [
            "Patch scanned",
            "  - XYZ fixtures : " + this.patch_info.fixtures.length,
            "  - Markers : " + this.patch_info.markers.length,
        ];
        if (removedFixtures.length == 0) return message;
        return [...message, "  - Disabled fixtures no longer in the patch : " + removedFixtures.join(", ")];
    }

    PrintCurrentPatch(): void {
        if (this.patch_info.fixtures.length == 0) return Popup("No fixtures in patch", 3);
        if (this.patch_info.markers.length == 0) return Popup("No markers in patch", 3);

        Popup([
            "Current Patch",
            "",
            "XYZ fixtures (" + this.patch_info.fixtures.length + ")",
            ...this.patch_info.fixtures.flatMap(fixture => fixture.describe()),
            "",
            "Markers (" + this.patch_info.markers.length + ")",
            ...this.patch_info.markers.map(marker => marker.describe()),
        ]);
    }
    GetFixturesStatus(): void {
        if (this.enabledFixtures.length == 0) return Popup("No fixtures enabled");

        Popup(this.enabledFixtures.map(enabledFixture =>
            "Fixture " + enabledFixture.fixture.fid + " -> " + enabledFixture.marker.fid + " | beamsize : " + enabledFixture.beamSize));
    }
    EnableFixture(fixtureid: number, markerid: number, beamSize: number): void {
        if (this.patch_info.fixtures.length === 0) return Popup("No fixtures with XYZ mode active in patch", 3);

        if (this.patch_info.markers.length === 0) return Popup("No markers in patch", 3);

        let fixture = this.patch_info.fixtures.find(fixture => fixture.fid === fixtureid);
        if (!fixture) return Popup("No fixture with id " + fixtureid + " found", 3);

        let marker = this.patch_info.markers.find(marker => marker.fid === markerid);
        if (!marker) return Popup("No marker with id " + markerid + " found", 3);

        let enabledFixture = this.enabledFixtures.find(enabledFixture => enabledFixture.fixture.fid === fixtureid);
        let messages: string[] = [];

        if (enabledFixture) {
            enabledFixture.marker = marker;
            enabledFixture.beamSize = beamSize;
            messages.push("Updated fixture " + fixtureid + " - Marker : " + marker.fid + " | Beam size : " + beamSize);
        } else {
            enabledFixture = new AZ_EnabledFixture(fixture, marker, beamSize);
            this.enabledFixtures.push(enabledFixture);
            messages.push("Enabled fixture " + fixtureid + " - Marker : " + marker.fid + " | Beam size : " + beamSize);
        }

        enabledFixture.fixture.invalidate();
        if (!marker.update()) {
            messages.push("", "Marker ID : " + marker.fid + " with Channel ID : " + marker.cid + " is not assigned to any PSN tracker, the zoom will not follow it. Set the Channel ID of the Marker in the PSN configuration.");
            return Popup(messages, 2);
        }
        if (this.enabled) {
            enabledFixture.forceUpdate(this.sizeFaderConfig);
        }
        Popup(messages);
    }

    DisableFixture(fixtureid: number): void {
        let index = this.enabledFixtures.findIndex(enabledFixture => enabledFixture.fixture.fid == fixtureid);
        if (index === -1) return Popup("Fixture " + fixtureid + " was not enabled", 3);

        this.enabledFixtures.splice(index, 1);
        Popup("Disabled fixture " + fixtureid);
    }
    LogLevel(levelString: string): void {
        SetLogLevel(levelString);
    }
    GetLogLevel(): void {
        PrintLogLevel();
    }

    DisableAllFixtures() : void {
        this.enabledFixtures = []
        Popup("Disabled all fixtures");
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

    loopId = 0;

    UpdateLoop(loopId: number):void {
        if (loopId != this.loopId) {
            return;
        }
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
        Popup("Set refresh rate to " + rate + " updates/second");
    }

    RegisterUpdateLoop(): void {
        if (!this.enabled) {
            PrintEcho("Autozoom is disabled, failed to start loop", 3)
            return;
        }
        let updatePeriod = 1/this.refreshRate;

        this.global_call_repeat = this.refreshRate*10;
        this.expected_remaining_update = this.global_call_repeat;
        this.loopId++;
        let loopId = this.loopId;
        Timer(()=>{this.UpdateLoop(loopId)}, updatePeriod, this.expected_remaining_update);
    }

    Init() : void {
        if(!this.initialized){
            this.Start();
        }
    }

    Start() : void {
        let patchMessage = this.loadPatch();
        this.initialized = true;
        Popup([
            "Plugin GRANDMA3 AUTOZOOM launched",
            "Plugin version : 1.1.2",
            "Plugin author : Naostage 2025",
            "",
            ...patchMessage,
            "",
            this.statusMessage(),
        ]);
    }

    Cleanup() : void {
        this.expected_remaining_update = 0;
        this.global_call_repeat = 0;
        this.enabled = false;
        PrintEcho("Plugin GRANDMA3 AUTOZOOM stopped", 1);
    }

    EnableSizeFader(fid: number) : void {
        for (let fixture of this.patch_info.fixtures){
            if (fixture.fid == fid){
                this.sizeFaderConfig.fixturesEnabled[fid] = true;
                Popup("Enabled size fader for fixture " + fid);
                return;
            }
        }
        Popup("Fixture " + fid + " not found in the patch", 3);
    }

    DisableSizeFader(fid: number) : void {
        for (let fixture of this.patch_info.fixtures){
            if (fixture.fid == fid){
                this.sizeFaderConfig.fixturesEnabled[fid] = false;
                Popup("Disabled size fader for fixture " + fid);
                return;
            }
        }
        Popup("Fixture " + fid + " not found in the patch", 3);
    }

    EnableGlobalSizeFader() : void {
        // Try to create the global size fader (if needed)
        
        this.sizeFaderConfig.globalEnabled = true;
        Popup("Enabled global size fader");
    }

    DisableGlobalSizeFader() : void {
        this.sizeFaderConfig.globalEnabled = false;
        Popup("Disabled global size fader");
    }

    SetSizeFaderRange(min: number, max: number) : void {
        this.sizeFaderConfig.rangeMin = min;
        this.sizeFaderConfig.rangeMax = max;
        Popup("Set size fader range to [" + min + ", " + max + "]");
    }

    EnableDatapool() : void {
        this.useAZDatapool = true;
        Popup("Enabled AZ Datapool");
    }

    DisableDatapool() : void {
        this.useAZDatapool = false;
        Popup("Disabled AZ Datapool");
    }

    CreateMacros(startingIndex : number) : void {
        if (!startingIndex){
            Popup("No starting index provided, macros creation cancelled, Usage : AZ:CreateMacros(<Starting Index>)", 3);
            return;
        }

        for(let i = 0; i < IMPORTED_MACROS.length; i++){
            createMacro(IMPORTED_MACROS[i].name, startingIndex+i, IMPORTED_MACROS[i].commands);
        }
    }

    CreateAZSequences(fid: number) {
        let enabledFixture = this.enabledFixtures.find(enabledFixture => enabledFixture.fixture.fid === fid);
        if (!enabledFixture) return Popup("Fixture " + fid + " is not enabled", 3);

        createSequencesForFixture(enabledFixture, this.useAZDatapool);
        enabledFixture.fixture.invalidate();
    }

}
