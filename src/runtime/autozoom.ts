/** @noSelfInFile */
import { armCommand, normalizeFids, parseArmList, rewriteCueCommand } from "../engine/arm-command";
import { parsePresetCommand, undoMatches } from "../engine/preset-ref";
import { programCommands, releaseCommands } from "../engine/program";
import { evaluate, FaderOutput, FixtureResult, MarkerSample } from "../engine/fixture-state";
import { vec, Vec3 } from "../engine/vec";
import { Desk } from "../desk";
import { fidKey, fmtInt, fmtNum } from "../format";
import { MarkerReadings, PatchFixture, PatchScan, SeqRef } from "../model";
import { applySetup, Config, CONFIG_KEY, defaultConfig, INSTANCE_KEY, offsetLabel, parseConfig, pruneConfig, serializeConfig } from "../store/config";
import { buildViews, layoutCells, RowState, stateLabel } from "../ui/view-model";

export const CAPTURE_SECONDS = 15;
export const PICK_SECONDS = 10;

interface Live { cid: number; programmerCid: number; offset: Vec3 }

export class AutoZoom {
    protected config: Config = defaultConfig();
    protected scanned: PatchScan = { fixtures: [], markers: [], problems: [] };
    protected running = false;
    protected message = "";
    protected captureUntil: number | undefined;
    protected captureStartId: string | undefined;
    protected pickUntil: number | undefined;
    protected pickBaseline: string | undefined;
    protected pickUndoMark: string | undefined;
    private results: { [fid: string]: FixtureResult } = {};
    private live: { [fid: string]: Live } = {};
    private sent: { [fid: string]: string } = {};
    private warned: { [key: string]: boolean } = {};
    private dirtyAt: number | undefined;
    private lastSize: number | undefined;
    private loopGen = 0;

    constructor(protected readonly desk: Desk, private readonly id: string) {}

    // ---------- lifecycle ----------
    private isCurrent(): boolean {
        return this.desk.loadText(INSTANCE_KEY) === this.id;
    }

    private ensureCurrent(): boolean {
        if (this.isCurrent()) return true;
        this.desk.log("Run the AutoZoom plugin for this show");
        return false;
    }

    Install(): void {
        const loaded = parseConfig(this.desk.loadText(CONFIG_KEY));
        if (loaded.warning !== undefined) this.desk.log(loaded.warning);
        this.config = loaded.config;
        this.desk.saveText(INSTANCE_KEY, this.id);
        this.Rescan();
    }

    Rescan(): void {
        if (!this.ensureCurrent()) return;
        this.scanned = this.desk.scan();
        for (const p of this.scanned.problems) this.desk.log(p);
        this.config = pruneConfig(this.config, this.scanned.fixtures.map(f => f.fid));
        this.desk.install(this.scanned);
        this.desk.buildLayout(layoutCells(this.scanned.fixtures, this.scanned.markers));
        this.sent = {};
        this.results = {};
        this.desk.log(`Found ${fmtInt(this.scanned.fixtures.length)} fixtures and ${fmtInt(this.scanned.markers.length)} markers`);
        this.update();
    }

    Start(): void {
        if (!this.ensureCurrent()) return;
        if (this.running) return;
        this.running = true;
        const gen = ++this.loopGen;
        this.desk.startLoop(
            this.config.rate,
            () => { if (gen === this.loopGen) this.tick(); },
            () => { if (gen === this.loopGen) this.onLoopStopped(); },
        );
        this.say("AutoZoom started");
    }

    Stop(): void {
        if (!this.isCurrent()) {
            // Another instance owns this show: stop our own loop, touch nothing else.
            if (!this.running) return;
            this.running = false;
            this.loopGen++;
            this.desk.stopLoop();
            return;
        }
        this.saveConfig();
        if (!this.running) return;
        this.running = false;
        this.loopGen++;
        this.desk.stopLoop();
        if (this.captureUntil !== undefined) this.endCapture("Capture cancelled");
        if (this.pickUntil !== undefined) this.endPick("Preset pick cancelled");
        // Release first: a failing refresh below must never leave a fader driven.
        for (const f of this.scanned.fixtures) {
            const key = fidKey(f.fid);
            if (this.sent[key] === "release") continue;
            try {
                this.desk.releaseFaders(f);
            } catch (e) {
                this.warnOnce(`release:${key}:${tostring(e)}`, `Fixture ${fmtInt(f.fid)}: release failed: ${tostring(e)}`);
            }
            this.sent[key] = "release";
        }
        try {
            this.update();
        } catch (e) {
            this.warnOnce(`stop:${tostring(e)}`, `Refresh after stop failed: ${tostring(e)}`);
        }
        this.say("AutoZoom stopped");
    }

    Toggle(): void {
        if (!this.ensureCurrent()) return;
        if (this.running) this.Stop(); else this.Start();
    }

    // ---------- arms ----------
    Arm(list: string): void {
        if (!this.ensureCurrent()) return;
        this.setArmed(parseArmList(list));
    }

    ArmToggle(fid: number): void {
        if (!this.ensureCurrent()) return;
        const armed = this.config.armed.filter(f => f !== fid);
        if (armed.length === this.config.armed.length) armed.push(fid);
        this.setArmed(armed);
    }

    ArmAll(): void {
        if (!this.ensureCurrent()) return;
        this.setArmed(this.scanned.fixtures.map(f => f.fid));
    }

    DisarmAll(): void {
        if (!this.ensureCurrent()) return;
        this.setArmed([]);
    }

    Status(): void {
        if (!this.ensureCurrent()) return;
        this.desk.log(`AutoZoom ${this.running ? "running" : "stopped"}, ${fmtInt(this.config.armed.length)} armed`);
        for (const f of this.scanned.fixtures) {
            const r = this.results[fidKey(f.fid)];
            this.desk.log(`  ${fmtInt(f.fid)} ${f.name}: ${r === undefined ? "-" : stateLabel(r.state)}`);
        }
    }

    // ---------- tap-to-program, setup, size ----------
    Program(fid: number, cid: number): void {
        if (!this.ensureCurrent()) return;
        const f = this.fixture(fid);
        if (f === undefined) {
            this.desk.log(`Fixture ${fmtInt(fid)} is not an AutoZoom fixture`);
            return;
        }
        if (this.desk.readProgrammerCid(f) === cid) {
            this.desk.runCommands(releaseCommands(fid));
        } else {
            this.desk.runCommands(programCommands(fid, cid, f.optics, this.config.offset));
        }
        this.update();
    }

    Setup(): void {
        if (!this.ensureCurrent()) return;
        this.desk.later(() => {
            const answers = this.desk.setupDialog(this.config);
            if (answers === undefined) return;
            const rate = this.config.rate;
            const result = applySetup(this.config, answers);
            for (const e of result.errors) this.desk.log(e);
            this.config = result.config;
            this.markDirty();
            if (this.config.rate !== rate && this.running) this.desk.log("The new refresh rate applies after Stop and Start");
            this.say("Setup saved");
            this.update();
        });
    }

    Size(fid: number): void {
        if (!this.ensureCurrent()) return;
        const f = this.fixture(fid);
        if (f === undefined) {
            this.desk.log(`Fixture ${fmtInt(fid)} is not an AutoZoom fixture`);
            return;
        }
        this.desk.later(() => {
            const key = fidKey(fid);
            const current = this.config.size[key];
            const answer = this.desk.prompt(`Beam size of ${fmtInt(fid)} in metres (empty = global fader)`, current === undefined ? "" : fmtNum(current));
            if (answer === undefined) return;
            const text = answer.trim().replace(",", ".");
            if (text === "") {
                delete this.config.size[key];
            } else {
                const n = Number(text);
                if (n !== n || n <= 0) {
                    this.desk.log("Size must be a number of metres above 0");
                    return;
                }
                this.config.size[key] = n;
            }
            this.markDirty();
            this.update();
        });
    }

    // ---------- loop ----------
    protected tick(): void {
        if (!this.isCurrent()) {
            this.desk.log("Another AutoZoom instance took over; this one stops");
            this.running = false;
            this.loopGen++;
            this.desk.stopLoop();
            return;
        }
        this.update();
        if (this.dirtyAt !== undefined && this.desk.now() - this.dirtyAt >= 1) this.saveConfig();
    }

    protected onLoopStopped(): void {
        // Called when the loop ends; Stop() already released everything when it was a normal stop.
        this.running = false;
    }

    protected update(): void {
        this.beforeUpdate();
        const markers = this.desk.readMarkers();
        const globalSize = this.globalSize();
        for (const f of this.scanned.fixtures) {
            try {
                this.updateFixture(f, markers, globalSize);
            } catch (e) {
                this.warnOnce(`${fmtInt(f.fid)}:${tostring(e)}`, `Fixture ${fmtInt(f.fid)}: ${tostring(e)}`);
            }
        }
        this.render(markers, globalSize);
    }

    Capture(): void {
        if (!this.ensureCurrent()) return;
        if (this.captureUntil !== undefined) {
            this.endCapture("Capture cancelled");
            return;
        }
        if (!this.running) {
            this.say("Start AutoZoom to use Capture");
            return;
        }
        const current = this.desk.selectedSequence();
        this.captureStartId = current?.id;
        this.captureUntil = this.desk.now() + CAPTURE_SECONDS;
        this.message = current === undefined
            ? "Select the sequence to store the arms in"
            : `Select the sequence to store the arms in (to use Seq ${fmtInt(current.no)}, select another sequence first, then it)`;
        this.update();
    }

    PickOffset(): void {
        if (!this.ensureCurrent()) return;
        if (this.pickUntil !== undefined) { this.endPick("Preset pick cancelled"); return; }
        if (!this.running) { this.say("Start AutoZoom to pick a preset"); return; }
        this.pickBaseline = this.desk.lastCommand();
        this.pickUndoMark = this.desk.undoMark();
        this.pickUntil = this.desk.now() + PICK_SECONDS;
        this.message = "Tap the preset that holds the XYZ offset";
        this.update();
    }

    private updatePick(): void {
        if (this.pickUntil === undefined) return;
        if (this.desk.now() > this.pickUntil) { this.endPick("Preset pick timed out"); return; }
        const cmd = this.desk.lastCommand();
        if (cmd === undefined || cmd === this.pickBaseline) return;
        const preset = parsePresetCommand(cmd);
        if (preset === undefined) return;                      // unrelated command: keep waiting
        const undoName = this.desk.topUndoName();
        this.desk.log(`Preset pick saw "${cmd}", undo entry "${undoName ?? ""}"`);
        // Oops only a new undo entry that is the tap itself: an older entry (e.g. "Store Preset 2.30") is never touched.
        if (this.desk.undoMark() !== this.pickUndoMark && undoMatches(undoName, cmd)) this.desk.undoProgrammer();
        this.config.offset = { ...this.config.offset, source: "preset", preset };
        this.markDirty();
        this.endPick(`Offset preset ${preset}`);
    }

    private endPick(message: string): void {
        this.pickUntil = undefined;
        this.pickBaseline = undefined;
        this.pickUndoMark = undefined;
        this.say(message);
    }

    protected beforeUpdate(): void {
        try {
            this.updatePick();
        } catch (e) {
            this.endPick("Preset pick failed: " + tostring(e));
        }
        if (this.captureUntil === undefined) return;
        if (this.desk.now() > this.captureUntil) {
            this.endCapture("Capture timed out");
            return;
        }
        const seq = this.desk.selectedSequence();
        if (seq === undefined || seq.id === this.captureStartId) return;
        this.captureUntil = undefined;
        this.desk.later(() => this.storeArms(seq));
    }

    private storeArms(seq: SeqRef): void {
        const suggested = this.desk.selectedCue(seq) ?? this.desk.runningCue(seq);
        const answer = this.desk.prompt(`Store AutoZoom arms in Seq ${fmtInt(seq.no)} '${seq.name}': cue number`, suggested === undefined ? "" : fmtNum(suggested));
        if (answer === undefined) {
            this.endCapture("Capture cancelled");
            return;
        }
        const cue = Number(answer.trim());
        const existing = answer.trim() !== "" && cue === cue ? this.desk.readCueCommand(seq, cue) : undefined;
        if (existing === undefined) {
            this.endCapture(`Seq ${fmtInt(seq.no)} has no cue ${answer.trim()}; nothing stored`);
            return;
        }
        const ok = this.desk.writeCueCommand(seq, cue, rewriteCueCommand(existing, armCommand(this.config.armed)));
        this.endCapture(ok ? `Stored in Seq ${fmtInt(seq.no)} '${seq.name}' cue ${fmtNum(cue)}` : `Could not write the command of Seq ${fmtInt(seq.no)} cue ${fmtNum(cue)}`);
    }

    private endCapture(message: string): void {
        this.captureUntil = undefined;
        this.captureStartId = undefined;
        this.say(message);
    }

    private updateFixture(f: PatchFixture, markers: MarkerReadings, globalSize: number): void {
        const key = fidKey(f.fid);
        const cid = this.desk.readMarkerCid(f);
        const live: Live = { cid, programmerCid: this.desk.readProgrammerCid(f), offset: this.desk.readOffset(f) };
        this.live[key] = live;
        let marker: MarkerSample | undefined;
        if (cid !== 0 && this.scanned.markers.some(m => m.cid === cid)) {
            const reading = markers[fidKey(cid)];
            marker = reading !== undefined ? { pos: reading.pos, rot: reading.rot, live: true } : { pos: vec(0, 0, 0), live: false };
        }
        const result = evaluate({
            running: this.running, armed: this.isArmed(f.fid), markerCid: cid, offset: live.offset,
            fixturePos: f.position, optics: f.optics, size: this.sizeFor(f.fid, globalSize), marker,
        });
        this.results[key] = result;
        this.apply(f, result.output);
    }

    private apply(f: PatchFixture, out: FaderOutput): void {
        if (out.kind === "hold") return;
        const key = fidKey(f.fid);
        const signature = out.kind === "release" ? "release" : `${out.zoom}|${out.iris}`;
        if (this.sent[key] === signature) return;
        this.sent[key] = signature;
        if (out.kind === "release") this.desk.releaseFaders(f);
        else this.desk.setFaders(f, out.zoom, out.iris);
    }

    private render(markers: MarkerReadings, globalSize: number): void {
        const rows: RowState[] = [];
        for (const f of this.scanned.fixtures) {
            const key = fidKey(f.fid);
            const live = this.live[key] ?? { cid: 0, programmerCid: 0, offset: vec(0, 0, 0) };
            rows.push({
                fixture: f, armed: this.isArmed(f.fid), markerCid: live.cid, programmerCid: live.programmerCid, offset: live.offset,
                result: this.results[key] ?? { state: "offline", output: { kind: "release" } },
                size: this.sizeFor(f.fid, globalSize), sizeFixed: this.config.size[key] !== undefined,
            });
        }
        let liveMarkers = 0;
        for (const m of this.scanned.markers) if (markers[fidKey(m.cid)] !== undefined) liveMarkers++;
        const left = this.captureUntil === undefined ? undefined : Math.max(0, Math.ceil(this.captureUntil - this.desk.now()));
        const pickLeft = this.pickUntil === undefined ? undefined : Math.max(0, Math.ceil(this.pickUntil - this.desk.now()));
        this.desk.refreshLayout(buildViews(
            { running: this.running, captureSecondsLeft: left, pickSecondsLeft: pickLeft, liveMarkers, globalSize, offsetLabel: offsetLabel(this.config), message: this.message },
            rows, this.scanned.markers, markers,
        ));
    }

    // ---------- helpers ----------
    protected isArmed(fid: number): boolean {
        return this.config.armed.indexOf(fid) >= 0;
    }

    protected fixture(fid: number): PatchFixture | undefined {
        return this.scanned.fixtures.find(f => f.fid === fid);
    }

    private setArmed(fids: number[]): void {
        const known = normalizeFids(fids).filter(fid => this.fixture(fid) !== undefined);
        const unknown = normalizeFids(fids).filter(fid => this.fixture(fid) === undefined);
        if (unknown.length > 0) this.desk.log(`Not AutoZoom fixtures, ignored: ${unknown.map(f => fmtInt(f)).join(", ")}`);
        this.config.armed = known;
        this.markDirty();
        this.update();
    }

    private globalSize(): number {
        const [min, max] = [this.config.range[0], this.config.range[1]];
        const fader = this.desk.readSizeFader();
        if (fader !== undefined) this.lastSize = min + (max - min) * Math.min(100, Math.max(0, fader)) / 100;
        return this.lastSize ?? min;
    }

    protected sizeFor(fid: number, globalSize: number): number {
        return this.config.size[fidKey(fid)] ?? globalSize;
    }

    protected markDirty(): void {
        if (this.running) this.dirtyAt = this.desk.now(); else this.saveConfig();
    }

    protected saveConfig(): void {
        this.desk.saveText(CONFIG_KEY, serializeConfig(this.config));
        this.dirtyAt = undefined;
    }

    protected say(message: string): void {
        this.message = message;
        this.desk.log(message);
    }

    private warnOnce(key: string, message: string): void {
        if (this.warned[key]) return;
        this.warned[key] = true;
        this.desk.log(message);
    }
}

export function createAutoZoom(desk: Desk, id: string): AutoZoom {
    return new AutoZoom(desk, id);
}
