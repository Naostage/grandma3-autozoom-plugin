/** @noSelfInFile */
import { Desk } from "../desk";
import { Vec3 } from "../engine/vec";
import { CellSpec, MarkerReadings, PatchFixture, PatchScan, SeqRef, Views } from "../model";
import { Config, SetupAnswers } from "../store/config";
import { ensureAppearances } from "./appearances";
import * as cues from "./cues";
import * as layout from "./layout";
import * as live from "./live";
import { info } from "./log";
import { scanPatch } from "./patch";
import * as pool from "./pool";
import * as ui from "./ui";
import * as vars from "./vars";

export class MaDesk implements Desk {
    private lastScan: PatchScan = { fixtures: [], markers: [], problems: [] };

    now(): number { return Time(); }
    log(message: string): void { info(message); }
    loadText(key: string): string | undefined { return vars.loadText(key); }
    saveText(key: string, value: string): void { vars.saveText(key, value); }
    scan(): PatchScan {
        this.lastScan = scanPatch();
        return this.lastScan;
    }
    install(scan: PatchScan): void {
        pool.ensurePool();
        ensureAppearances();
        pool.ensureSizeSequence();
        pool.ensureRawMacro(pool.START_MACRO, `Call Plugin "${pool.PLUGIN_NAME}"`);
        for (const f of scan.fixtures) {
            pool.ensureFaderSequence(pool.zoomSeqName(f.fid), f.fid, "Zoom", f.optics.zoomMax);
            if (f.optics.irisMax > f.optics.irisMin) pool.ensureFaderSequence(pool.irisSeqName(f.fid), f.fid, "Iris", f.optics.irisMax);
        }
    }
    readMarkerCid(f: PatchFixture): number { return live.readMarkerCid(f); }
    readOffset(f: PatchFixture): Vec3 { return live.readOffset(f, this.lastScan.markers); }
    readProgrammerCid(f: PatchFixture): number { return live.readProgrammerCid(f); }
    readMarkers(): MarkerReadings { return live.readMarkers(); }
    readSizeFader(): number | undefined { return pool.readMaster(pool.SIZE_SEQ); }
    setFaders(f: PatchFixture, zoom: number, iris: number | undefined): void {
        pool.setTemp(pool.zoomSeqName(f.fid), zoom);
        if (iris !== undefined && f.optics.irisMax > f.optics.irisMin) pool.setTemp(pool.irisSeqName(f.fid), iris);
    }
    releaseFaders(f: PatchFixture): void {
        pool.setTemp(pool.zoomSeqName(f.fid), 0);
        if (f.optics.irisMax > f.optics.irisMin) pool.setTemp(pool.irisSeqName(f.fid), 0);
    }
    buildLayout(cells: CellSpec[]): void { layout.buildLayout(cells); }
    refreshLayout(views: Views): void { layout.refreshLayout(views); }
    startLoop(rate: number, tick: () => void, cleanup: () => void): void { ui.startLoop(rate, tick, cleanup); }
    stopLoop(): void { ui.stopLoop(); }
    later(fn: () => void): void { ui.later(fn); }
    selectedSequence(): SeqRef | undefined { return cues.selectedSequence(); }
    runningCue(seq: SeqRef): number | undefined { return cues.runningCue(seq); }
    selectedCue(seq: SeqRef): number | undefined { return cues.selectedCue(seq); }
    readCueCommand(seq: SeqRef, cue: number): string | undefined { return cues.readCueCommand(seq, cue); }
    writeCueCommand(seq: SeqRef, cue: number, text: string): boolean { return cues.writeCueCommand(seq, cue, text); }
    prompt(title: string, value: string): string | undefined { return ui.prompt(title, value); }
    setupDialog(current: Config): SetupAnswers | undefined { return ui.setupDialog(current); }
    runCommands(commands: string[]): void { ui.runCommands(commands); }
}

export function createMaDesk(): MaDesk {
    return new MaDesk();
}
