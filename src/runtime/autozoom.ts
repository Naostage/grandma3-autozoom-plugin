/** @noSelfInFile */
import { armCommand, normalizeFids, parseArmList, rewriteCueCommand } from "../engine/arm-command";
import { evaluate, FaderOutput, FixtureResult, MarkerSample } from "../engine/fixture-state";
import { vec, Vec3 } from "../engine/vec";
import { Desk } from "../desk";
import { fidKey, fmtInt, fmtNum } from "../format";
import { MarkerReadings, PatchFixture, PatchScan, SeqRef } from "../model";
import { Config, CONFIG_KEY, defaultConfig, INSTANCE_KEY, offsetLabel, parseConfig, pruneConfig, serializeConfig } from "../store/config";
import { buildViews, layoutCells, RowState, stateLabel } from "../ui/view-model";

export const CAPTURE_SECONDS = 15;

interface Live { cid: number; programmerCid: number; offset: Vec3 }

export class AutoZoom {
    protected config: Config = defaultConfig();
    protected scanned: PatchScan = { fixtures: [], markers: [], problems: [] };
    protected running = false;
    protected message = "";
    protected captureUntil: number | undefined;
    protected captureStartId: string | undefined;
    private results: { [fid: string]: FixtureResult } = {};
    private live: { [fid: string]: Live } = {};
    private sent: { [fid: string]: string } = {};
    private warned: { [key: string]: boolean } = {};
    private dirtyAt: number | undefined;
    private lastSize: number | undefined;
    private loopGen = 0;

    constructor(protected readonly desk: Desk, private readonly id: string) {}

    // ---------- lifecycle ----------
    Install(): void {
        const loaded = parseConfig(this.desk.loadText(CONFIG_KEY));
        if (loaded.warning !== undefined) this.desk.log(loaded.warning);
        this.config = loaded.config;
        this.desk.saveText(INSTANCE_KEY, this.id);
        this.Rescan();
    }

    Rescan(): void {
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
        this.saveConfig();
        if (!this.running) return;
        this.running = false;
        this.loopGen++;
        this.desk.stopLoop();
        if (this.captureUntil !== undefined) this.endCapture("Capture cancelled");
        this.update();
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
        this.say("AutoZoom stopped");
    }

    Toggle(): void {
        if (this.running) this.Stop(); else this.Start();
    }

    // ---------- arms ----------
    Arm(list: string): void {
        this.setArmed(parseArmList(list));
    }

    ArmToggle(fid: number): void {
        const armed = this.config.armed.filter(f => f !== fid);
        if (armed.length === this.config.armed.length) armed.push(fid);
        this.setArmed(armed);
    }

    ArmAll(): void {
        this.setArmed(this.scanned.fixtures.map(f => f.fid));
    }

    DisarmAll(): void {
        this.setArmed([]);
    }

    Status(): void {
        this.desk.log(`AutoZoom ${this.running ? "running" : "stopped"}, ${fmtInt(this.config.armed.length)} armed`);
        for (const f of this.scanned.fixtures) {
            const r = this.results[fidKey(f.fid)];
            this.desk.log(`  ${fmtInt(f.fid)} ${f.name}: ${r === undefined ? "-" : stateLabel(r.state)}`);
        }
    }

    // ---------- loop ----------
    protected tick(): void {
        if (this.desk.loadText(INSTANCE_KEY) !== this.id) {
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

    protected beforeUpdate(): void {
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
        this.desk.refreshLayout(buildViews(
            { running: this.running, captureSecondsLeft: left, liveMarkers, globalSize, offsetLabel: offsetLabel(this.config), message: this.message },
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
