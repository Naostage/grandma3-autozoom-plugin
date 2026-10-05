/** @noSelfInFile */
import { fidKey, fmtNum } from "../format";
import { decode, encode } from "./json";

export type OffsetSource = "preset" | "values";

export interface Config {
    armed: number[];
    size: { [fid: string]: number };   // fixed beam size (m) per fixture; absent = global fader
    range: number[];                    // [min, max] metres of the AZ_SIZE fader
    rate: number;                       // updates per second
    offset: { source: OffsetSource; preset: string; values: number[] };
}

export const CONFIG_KEY = "AutoZoom.config";
export const INSTANCE_KEY = "AutoZoom.instance";
const UNREADABLE = "Saved AutoZoom settings were unreadable; defaults restored";

export function defaultConfig(): Config {
    return { armed: [], size: {}, range: [0.5, 5], rate: 30, offset: { source: "values", preset: "", values: [0, 0, 0] } };
}

function num(v: unknown): number | undefined {
    return typeof v === "number" && v === v ? v : undefined;
}

export function parseConfig(text: string | undefined): { config: Config; warning?: string } {
    const config = defaultConfig();
    if (text === undefined || text === "") return { config };
    let raw: any;
    try {
        raw = decode(text);
    } catch (e) {
        return { config, warning: UNREADABLE };
    }
    if (typeof raw !== "object") return { config, warning: UNREADABLE };
    if (Array.isArray(raw.armed)) {
        for (const fid of raw.armed) if (num(fid) !== undefined) config.armed.push(Math.floor(fid));
    }
    if (typeof raw.size === "object") {
        for (const key in raw.size) {
            const v = num(raw.size[key]);
            if (v !== undefined && v > 0) config.size[key] = v;
        }
    }
    if (Array.isArray(raw.range) && raw.range.length === 2) {
        const lo = num(raw.range[0]), hi = num(raw.range[1]);
        if (lo !== undefined && hi !== undefined && lo > 0 && hi > lo) config.range = [lo, hi];
    }
    const rate = num(raw.rate);
    if (rate !== undefined && rate >= 1 && rate <= 60) config.rate = rate;
    if (typeof raw.offset === "object") {
        const o = raw.offset;
        if (o.source === "preset" || o.source === "values") config.offset.source = o.source;
        if (typeof o.preset === "string") config.offset.preset = o.preset;
        if (Array.isArray(o.values) && o.values.length === 3) {
            config.offset.values = [num(o.values[0]) ?? 0, num(o.values[1]) ?? 0, num(o.values[2]) ?? 0];
        }
    }
    return { config };
}

export function serializeConfig(c: Config): string {
    return encode({ v: 1, armed: c.armed, size: c.size, range: c.range, rate: c.rate, offset: c.offset });
}

export function pruneConfig(config: Config, fids: number[]): Config {
    const keep: { [fid: string]: boolean } = {};
    for (const fid of fids) keep[fidKey(fid)] = true;
    const armed: number[] = [];
    for (const fid of config.armed) if (keep[fidKey(fid)]) armed.push(fid);
    const size: { [fid: string]: number } = {};
    for (const key in config.size) if (keep[key]) size[key] = config.size[key];
    return { ...config, armed, size };
}

export interface SetupAnswers { source: OffsetSource; preset: string; x: string; y: string; z: string; min: string; max: string; rate: string }

export function applySetup(current: Config, a: SetupAnswers): { config: Config; errors: string[] } {
    const errors: string[] = [];
    const config: Config = { ...current, range: [...current.range], offset: { ...current.offset, values: [...current.offset.values] } };
    const read = (label: string, text: string): number | undefined => {
        const n = Number(text.trim());
        if (text.trim() === "" || n !== n) { errors.push(`${label}: "${text}" is not a number`); return undefined; }
        return n;
    };
    const x = read("Offset X", a.x), y = read("Offset Y", a.y), z = read("Offset Z", a.z);
    if (x !== undefined && y !== undefined && z !== undefined) config.offset.values = [x, y, z];
    if (a.source === "preset" && a.preset.trim() === "") errors.push("Offset source is Preset but no preset number was given");
    else config.offset.source = a.source;
    config.offset.preset = a.preset.trim();
    const lo = read("Size min", a.min), hi = read("Size max", a.max);
    if (lo !== undefined && hi !== undefined) {
        if (lo > 0 && hi > lo) config.range = [lo, hi];
        else errors.push("Size range must be min > 0 and max > min");
    }
    const rate = read("Refresh rate", a.rate);
    if (rate !== undefined) {
        if (rate >= 1 && rate <= 60) config.rate = rate;
        else errors.push("Refresh rate must be between 1 and 60");
    }
    return { config, errors };
}

export function offsetLabel(c: Config): string {
    if (c.offset.source === "preset") return "Preset " + c.offset.preset;
    return c.offset.values.map(v => fmtNum(v)).join("/") + " m";
}
