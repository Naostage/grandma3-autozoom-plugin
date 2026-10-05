/** @noSelfInFile */
import { Desk } from "../desk";
import { fidKey } from "../format";
import { Vec3 } from "../engine/vec";
import { CellSpec, MarkerReadings, PatchFixture, PatchScan, Views } from "../model";
import { Config, SetupAnswers } from "../store/config";
import { ensureAppearances } from "./appearances";
import * as layout from "./layout";
import * as live from "./live";
import { info, warnOnce } from "./log";
import { scanPatch } from "./patch";
import * as pool from "./pool";
import * as ui from "./ui";
import * as undo from "./undo";
import * as vars from "./vars";

export class MaDesk implements Desk {
    private lastScan: PatchScan = { fixtures: [], markers: [], problems: [] };
    private engaged: { [fid: string]: boolean } = {};    // AZ_BASE turned On; empty after a plugin restart (On again is harmless)

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
        try {
            ensureAppearances();       // cosmetic: must never keep the fader sequences from being created
        } catch (e) {
            warnOnce("appearances", "Could not create the AutoZoom appearances: " + tostring(e));
        }
        pool.ensureSizeSequence();
        pool.ensureRawMacro(pool.START_MACRO, `Call Plugin "${pool.PLUGIN_NAME}"`);
        try {
            pool.removeCellMacros();
        } catch (e) {
            warnOnce("cell-macros", "Could not remove the old layout macros: " + tostring(e));
        }
        for (const f of scan.fixtures) {
            const hasIris = f.optics.irisMax > f.optics.irisMin;
            const base: [string, number][] = [["Zoom", f.optics.zoomMin]];
            if (hasIris) base.push(["Iris", f.optics.irisMin]);
            pool.ensureCueSequence(pool.baseSeqName(f.fid), f.fid, base);
            pool.setPriority(pool.baseSeqName(f.fid), "High");
            pool.setNoOffWhenOverridden(pool.baseSeqName(f.fid));
            pool.ensureFaderSequence(pool.zoomSeqName(f.fid), f.fid, "Zoom", f.optics.zoomMax);
            pool.setPriority(pool.zoomSeqName(f.fid), "Super");
            if (hasIris) {
                pool.ensureFaderSequence(pool.irisSeqName(f.fid), f.fid, "Iris", f.optics.irisMax);
                pool.setPriority(pool.irisSeqName(f.fid), "Super");
            }
        }
    }
    readMarkerCid(f: PatchFixture): number { return live.readMarkerCid(f); }
    readOffset(f: PatchFixture): Vec3 { return live.readOffset(f, this.lastScan.markers); }
    readProgrammerCid(f: PatchFixture): number { return live.readProgrammerCid(f); }
    readMarkers(): MarkerReadings { return live.readMarkers(); }
    readSizeFader(): number | undefined { return pool.readMaster(pool.SIZE_SEQ); }
    // AZ_BASE (High) holds zoom/iris at minimum while driven; it goes On once per engagement, before the Temp faders.
    setFaders(f: PatchFixture, zoom: number, iris: number | undefined): void {
        const key = fidKey(f.fid);
        if (!this.engaged[key] && pool.sequenceOn(pool.baseSeqName(f.fid))) this.engaged[key] = true;
        pool.setTemp(pool.zoomSeqName(f.fid), zoom);
        if (iris !== undefined && f.optics.irisMax > f.optics.irisMin) pool.setTemp(pool.irisSeqName(f.fid), iris);
    }
    // Each step is guarded: a failing Temp write must never keep the base On.
    releaseFaders(f: PatchFixture): void {
        releaseTemp(pool.zoomSeqName(f.fid));
        if (f.optics.irisMax > f.optics.irisMin) releaseTemp(pool.irisSeqName(f.fid));
        this.engaged[fidKey(f.fid)] = false;
        pool.sequenceOff(pool.baseSeqName(f.fid));
    }
    buildLayout(cells: CellSpec[]): void { layout.buildLayout(cells); }
    refreshLayout(views: Views): void { layout.refreshLayout(views); }
    startLoop(rate: number, tick: () => void, cleanup: () => void): void { ui.startLoop(rate, tick, cleanup); }
    stopLoop(): void { ui.stopLoop(); }
    later(fn: () => void): void { ui.later(fn); }
    prompt(title: string, value: string): string | undefined { return ui.prompt(title, value); }
    setupDialog(current: Config): SetupAnswers | undefined { return ui.setupDialog(current); }
    runCommands(commands: string[]): void { ui.runCommands(commands); }
    lastCommand(): string | undefined { return undo.lastCommand(); }
    topUndoName(): string | undefined { return undo.topUndoName(); }
    undoMark(): string { return undo.undoMark(); }
    undoProgrammer(): void { undo.undoProgrammer(); }
}

function releaseTemp(name: string): void {
    try {
        pool.setTemp(name, 0);
    } catch (e) {
        warnOnce("release:" + name + ":" + tostring(e), `Could not release ${name}: ${tostring(e)}`);
    }
}

export function createMaDesk(): MaDesk {
    return new MaDesk();
}
