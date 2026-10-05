/** @noSelfInFile */
import { Vec3 } from "./engine/vec";
import { CellSpec, MarkerReadings, PatchFixture, PatchScan, Views } from "./model";
import { Config, SetupAnswers } from "./store/config";

// Everything AutoZoom needs from the console. MaDesk (src/console) implements it on grandMA3;
// tests use tests/lib/fakedesk.lua.
export interface Desk {
    now(): number;                                         // seconds
    log(message: string): void;                            // System Monitor
    loadText(key: string): string | undefined;             // GlobalVars
    saveText(key: string, value: string): void;
    scan(): PatchScan;
    install(scan: PatchScan): void;                        // DataPool, AZ_BASE/AZ_ZOOM/AZ_IRIS/AZ_SIZE sequences
    readMarkerCid(f: PatchFixture): number;                // live XYZ_MArker output, 0 = none
    readOffset(f: PatchFixture): Vec3;                     // live XYZ_X/Y/Z output in metres
    readProgrammerCid(f: PatchFixture): number;            // XYZ_MArker when it comes from the programmer, else 0
    readMarkers(): MarkerReadings;                         // PSN positions by CID
    readSizeFader(): number | undefined;                   // AZ_SIZE master 0..100, undefined if missing
    setFaders(f: PatchFixture, zoom: number, iris: number | undefined): void;
    releaseFaders(f: PatchFixture): void;
    buildLayout(cells: CellSpec[]): void;
    refreshLayout(views: Views): void;
    startLoop(rate: number, tick: () => void, cleanup: () => void): void;
    stopLoop(): void;
    later(fn: () => void): void;                           // run in its own coroutine (prompts must not block the loop)
    prompt(title: string, value: string): string | undefined;      // undefined = cancelled
    setupDialog(current: Config): SetupAnswers | undefined;
    runCommands(commands: string[]): void;
    lastCommand(): string | undefined;                     // CmdObj().LastCommand
    topUndoName(): string | undefined;                     // name of the most recent undo entry
    undoMark(): string;                                    // changes whenever an undo entry is added or undone
    undoProgrammer(): void;                                // Oops with CurrentProfile().OopsProgrammer temporarily on
}
