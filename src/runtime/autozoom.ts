/** @noSelfInFile */
import { normalizeFids, parseArmList } from "../engine/arm-command";
import { programCommands, releaseCommands } from "../engine/program";
import { evaluate, FaderOutput, FixtureResult, MarkerSample } from "../engine/fixture-state";
import { vec, Vec3 } from "../engine/vec";
import { Desk } from "../desk";
import { fidKey, fmtInt, fmtNum } from "../format";
import { LayoutRow, MarkerReadings, PatchFixture, PatchScan } from "../model";
import { applySetup, Config, CONFIG_KEY, defaultConfig, INSTANCE_KEY, offsetLabel, parseConfig, pruneConfig, serializeConfig } from "../store/config";
import { buildViews, GroupRowState, layoutCells, RowState, stateLabel, summarize } from "../ui/view-model";

interface Live { cid: number; programmerCid: number; offset: Vec3 }

export class AutoZoom {
    protected config: Config = defaultConfig();
    protected patch: PatchScan = { fixtures: [], markers: [], problems: [] };      // full scan
    protected scanned: PatchScan = { fixtures: [], markers: [], problems: [] };    // fixtures = the managed ones
    private layoutRows: LayoutRow[] = [];
    protected running = false;
    protected message = "";
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
        const old = this.scanned.fixtures;
        this.patch = this.desk.scan();
        for (const p of this.patch.problems) this.desk.log(p);
        this.layoutRows = this.resolveRows();
        const managed = this.managedFixtures();
        const kept: { [fid: string]: boolean } = {};
        for (const f of managed) kept[fidKey(f.fid)] = true;
        // A fixture dropped from the patch or from the layout rows is never updated again: release it (and its AZ_BASE) now.
        this.releaseAll(old.filter(f => !kept[fidKey(f.fid)]));
        this.scanned = { ...this.patch, fixtures: managed };
        this.config = pruneConfig(this.config, this.patch.fixtures.map(f => f.fid));
        this.desk.install(this.scanned);
        this.desk.buildLayout(layoutCells(this.layoutRows, this.scanned.markers));
        this.sent = {};
        this.results = {};
        this.desk.log(`Found ${fmtInt(this.scanned.fixtures.length)} fixtures and ${fmtInt(this.scanned.markers.length)} markers`);
        this.update();
    }

    // Layout rows from config.rows (empty: one row per patch fixture). Group contents are read now, not on every tick.
    private resolveRows(): LayoutRow[] {
        const byFid: { [fid: string]: PatchFixture } = {};
        for (const f of this.patch.fixtures) byFid[fidKey(f.fid)] = f;
        if (this.config.rows.length === 0) return this.patch.fixtures.map(f => ({ kind: "fixture", fixture: f }));
        const groups = this.config.rows.some(e => e.kind === "group") ? this.desk.listGroups() : [];
        const rows: LayoutRow[] = [];
        for (const e of this.config.rows) {
            if (e.kind === "fixture") {
                const f = byFid[fidKey(e.fid)];
                if (f === undefined) this.desk.log(`Fixture ${fmtInt(e.fid)} in the layout rows is not an XYZ fixture`);
                else rows.push({ kind: "fixture", fixture: f });
                continue;
            }
            const g = groups.find(x => x.no === e.no);
            const members: { [fid: string]: boolean } = {};
            for (const fid of g?.fids ?? []) members[fidKey(fid)] = true;
            rows.push({
                kind: "group", no: e.no, name: g?.name ?? e.name, missing: g === undefined,
                fixtures: this.patch.fixtures.filter(f => members[fidKey(f.fid)]),
            });
        }
        return rows;
    }

    // Union of the fixtures the rows reach, in patch order.
    private managedFixtures(): PatchFixture[] {
        const reached: { [fid: string]: boolean } = {};
        for (const r of this.layoutRows) {
            if (r.kind === "fixture") reached[fidKey(r.fixture.fid)] = true;
            else for (const f of r.fixtures) reached[fidKey(f.fid)] = true;
        }
        return this.patch.fixtures.filter(f => reached[fidKey(f.fid)]);
    }

    private groupRow(no: number): (LayoutRow & { kind: "group" }) | undefined {
        for (const r of this.layoutRows) if (r.kind === "group" && r.no === no) return r;
        return undefined;
    }

    // The Rescan layout cell uses this: rebuilding the layout inside the tap of one of its own elements is unsafe.
    RescanLater(): void {
        if (!this.ensureCurrent()) return;
        this.desk.later(() => this.Rescan());
    }

    // Removed in 2.0.0.2; kept so old cues and macros that call it get a message instead of an error.
    Capture(): void {
        this.desk.log("Capture was removed in 2.0.0.2");
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
        // Release first: a failing refresh below must never leave a fader driven.
        this.releaseAll(this.scanned.fixtures);
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
        if (this.fixture(fid) === undefined) {
            this.desk.log(`Not AutoZoom fixtures, ignored: ${fmtInt(fid)}`);
            return;
        }
        const disarmed = this.config.disarmed.filter(f => f !== fid);
        if (disarmed.length === this.config.disarmed.length) disarmed.push(fid);
        this.config.disarmed = disarmed;
        this.markDirty();
        this.update();
    }

    // Any member disarmed: arm the whole group; all armed: disarm the whole group.
    ArmGroup(no: number): void {
        if (!this.ensureCurrent()) return;
        const fids = this.groupFids(no);
        if (fids === undefined) return;
        const anyDisarmed = fids.some(fid => !this.isArmed(fid));
        const rest = this.config.disarmed.filter(fid => fids.indexOf(fid) < 0);
        this.config.disarmed = anyDisarmed ? rest : [...rest, ...fids];
        this.markDirty();
        this.update();
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
        this.desk.log(`AutoZoom ${this.running ? "running" : "stopped"}, ${fmtInt(this.scanned.fixtures.filter(f => this.isArmed(f.fid)).length)} armed`);
        for (const row of this.rowStates(this.globalSize())) {
            if ("members" in row) {
                const sum = summarize(row.members);
                this.desk.log(`  G${fmtInt(row.no)} ${row.name}: ${fmtInt(sum.tracking)}/${fmtInt(sum.total)} tracking`);
            } else {
                const r = this.results[fidKey(row.fixture.fid)];
                this.desk.log(`  ${fmtInt(row.fixture.fid)} ${row.fixture.name}: ${r === undefined ? "-" : stateLabel(r.state)}`);
            }
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
            this.desk.runCommands(releaseCommands([fid]));
        } else {
            this.desk.runCommands(programCommands([fid], cid, this.config.offset));
        }
        this.update();
    }

    // All members already on that marker in the programmer: release them; else program them all with one selection.
    ProgramGroup(no: number, cid: number): void {
        if (!this.ensureCurrent()) return;
        const fids = this.groupFids(no);
        if (fids === undefined) return;
        const all = this.scanned.fixtures.filter(f => fids.indexOf(f.fid) >= 0).every(f => this.desk.readProgrammerCid(f) === cid);
        this.desk.runCommands(all ? releaseCommands(fids) : programCommands(fids, cid, this.config.offset));
        this.update();
    }

    // The XYZ fixtures of a group row, or undefined (logged) when it has none.
    private groupFids(no: number): number[] | undefined {
        const fids = (this.groupRow(no)?.fixtures ?? []).map(f => f.fid);
        if (fids.length > 0) return fids;
        this.desk.log(`Group ${fmtInt(no)} has no XYZ fixtures`);
        return undefined;
    }

    Setup(): void {
        if (!this.ensureCurrent()) return;
        this.desk.later(() => {
            const answers = this.desk.setupDialog(this.config);
            if (answers === undefined) return;
            if (answers.action === "pick") {                  // the other answers are not applied
                this.openPicker();
                return;
            }
            if (answers.action === "rows") {
                this.openRows();
                return;
            }
            if (answers.action !== "save") return;
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
        // Only reached when the loop ends without Stop() (Stop bumps loopGen first): release what is still driven.
        this.running = false;
        this.releaseAll(this.scanned.fixtures);
    }

    // Releases every listed fixture not already released; one failure never stops the others.
    private releaseAll(fixtures: PatchFixture[]): void {
        for (const f of fixtures) {
            const key = fidKey(f.fid);
            if (this.sent[key] === "release") continue;
            try {
                this.desk.releaseFaders(f);
            } catch (e) {
                this.warnOnce(`release:${key}:${tostring(e)}`, `Fixture ${fmtInt(f.fid)}: release failed: ${tostring(e)}`);
            }
            this.sent[key] = "release";
        }
    }

    protected update(): void {
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

    Rows(): void {
        if (!this.ensureCurrent()) return;
        this.openRows();
    }

    // Edits are stored as they are made; closing with changes rebuilds the layout and the managed set.
    private openRows(): void {
        const catalog = { groups: this.desk.listGroups(), fixtures: this.patch.fixtures.map(f => ({ fid: f.fid, name: f.name })) };
        this.desk.openRowsEditor(this.config.rows, catalog, rows => {
            if (!this.ensureCurrent()) return;
            this.config.rows = rows;
            this.markDirty();
        }, changed => {
            if (changed) this.RescanLater();
        });
    }

    PickOffset(): void {
        if (!this.ensureCurrent()) return;
        this.openPicker();
    }

    private openPicker(): void {
        this.desk.openPresetPicker(this.config.offset.preset, preset => {
            if (!this.ensureCurrent()) return;
            this.config.offset = { ...this.config.offset, source: "preset", preset };
            this.markDirty();
            this.say(`Offset preset ${preset}`);
            this.update();
        });
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

    private rowState(f: PatchFixture, globalSize: number): RowState {
        const key = fidKey(f.fid);
        const live = this.live[key] ?? { cid: 0, programmerCid: 0, offset: vec(0, 0, 0) };
        return {
            fixture: f, armed: this.isArmed(f.fid), markerCid: live.cid, programmerCid: live.programmerCid, offset: live.offset,
            result: this.results[key] ?? { state: "offline", output: { kind: "release" } },
            size: this.sizeFor(f.fid, globalSize), sizeFixed: this.config.size[key] !== undefined,
        };
    }

    private rowStates(globalSize: number): (RowState | GroupRowState)[] {
        return this.layoutRows.map(r => r.kind === "fixture"
            ? this.rowState(r.fixture, globalSize)
            : { no: r.no, name: r.name, missing: r.missing, members: r.fixtures.map(f => this.rowState(f, globalSize)) });
    }

    private render(markers: MarkerReadings, globalSize: number): void {
        const rows = this.rowStates(globalSize);
        let liveMarkers = 0;
        for (const m of this.scanned.markers) if (markers[fidKey(m.cid)] !== undefined) liveMarkers++;
        this.desk.refreshLayout(buildViews(
            { running: this.running, liveMarkers, globalSize, offsetLabel: offsetLabel(this.config), message: this.message },
            rows, this.scanned.markers, markers,
        ));
    }

    // ---------- helpers ----------
    protected isArmed(fid: number): boolean {
        return this.config.disarmed.indexOf(fid) < 0;
    }

    protected fixture(fid: number): PatchFixture | undefined {
        return this.scanned.fixtures.find(f => f.fid === fid);
    }

    private setArmed(fids: number[]): void {
        const known = normalizeFids(fids).filter(fid => this.fixture(fid) !== undefined);
        const unknown = normalizeFids(fids).filter(fid => this.fixture(fid) === undefined);
        if (unknown.length > 0) this.desk.log(`Not AutoZoom fixtures, ignored: ${unknown.map(f => fmtInt(f)).join(", ")}`);
        // Fixtures outside the layout rows keep their arm state.
        const outside = this.config.disarmed.filter(fid => this.fixture(fid) === undefined);
        this.config.disarmed = [...outside, ...this.scanned.fixtures.map(f => f.fid).filter(fid => known.indexOf(fid) < 0)];
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
