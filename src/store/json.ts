/** @noSelfInFile */
// Minimal JSON for the config stored in GlobalVars.
// Lua cannot tell an empty array from an empty object: both encode as [] and decode to an empty table.

export function encode(value: unknown): string {
    if (value === undefined || value === null) return "null";
    if (typeof value === "boolean") return value ? "true" : "false";
    if (typeof value === "number") {
        if (value !== value || value === Infinity || value === -Infinity) return "null";
        return Math.floor(value) === value && Math.abs(value) < 1e15 ? string.format("%d", value) : string.format("%.10g", value);
    }
    if (typeof value === "string") return encodeString(value);
    if (Array.isArray(value)) {
        const parts: string[] = [];
        for (const item of value) parts.push(encode(item));
        return "[" + parts.join(",") + "]";
    }
    const obj = value as { [key: string]: unknown };
    const keys: string[] = [];
    for (const key in obj) keys.push(key);
    keys.sort();
    const parts: string[] = [];
    for (const key of keys) parts.push(encodeString(key) + ":" + encode(obj[key]));
    return "{" + parts.join(",") + "}";
}

function encodeString(s: string): string {
    let out = "\"";
    for (let i = 0; i < s.length; i++) {
        const c = s.charAt(i);
        if (c === "\"") out += "\\\"";
        else if (c === "\\") out += "\\\\";
        else if (c === "\n") out += "\\n";
        else if (c === "\r") out += "\\r";
        else if (c === "\t") out += "\\t";
        else out += c;
    }
    return out + "\"";
}

interface Cursor { s: string; i: number }

export function decode(text: string): unknown {
    const c: Cursor = { s: text, i: 0 };
    const value = parseValue(c);
    skipSpace(c);
    if (c.i < c.s.length) throw new Error("unexpected text at " + c.i);
    return value;
}

function skipSpace(c: Cursor): void {
    while (c.i < c.s.length) {
        const ch = c.s.charAt(c.i);
        if (ch !== " " && ch !== "\n" && ch !== "\r" && ch !== "\t") return;
        c.i++;
    }
}

function expectWord(c: Cursor, word: string): void {
    if (c.s.substring(c.i, c.i + word.length) !== word) throw new Error("expected " + word + " at " + c.i);
    c.i += word.length;
}

function parseValue(c: Cursor): unknown {
    skipSpace(c);
    const ch = c.s.charAt(c.i);
    if (ch === "{") return parseObject(c);
    if (ch === "[") return parseArray(c);
    if (ch === "\"") return parseString(c);
    if (ch === "t") { expectWord(c, "true"); return true; }
    if (ch === "f") { expectWord(c, "false"); return false; }
    if (ch === "n") { expectWord(c, "null"); return undefined; }
    return parseNumber(c);
}

function parseNumber(c: Cursor): number {
    const start = c.i;
    while (c.i < c.s.length && "+-0123456789.eE".indexOf(c.s.charAt(c.i)) >= 0) c.i++;
    if (c.i === start) throw new Error("unexpected character at " + start);
    const n = Number(c.s.substring(start, c.i));
    if (n !== n) throw new Error("bad number at " + start);
    return n;
}

function parseString(c: Cursor): string {
    c.i++;
    let out = "";
    while (c.i < c.s.length) {
        const ch = c.s.charAt(c.i);
        c.i++;
        if (ch === "\"") return out;
        if (ch === "\\") {
            const e = c.s.charAt(c.i);
            c.i++;
            if (e === "n") out += "\n";
            else if (e === "r") out += "\r";
            else if (e === "t") out += "\t";
            else out += e;
        } else {
            out += ch;
        }
    }
    throw new Error("unterminated string");
}

function parseArray(c: Cursor): unknown[] {
    c.i++;
    const out: unknown[] = [];
    skipSpace(c);
    if (c.s.charAt(c.i) === "]") { c.i++; return out; }
    while (true) {
        out.push(parseValue(c));
        skipSpace(c);
        const ch = c.s.charAt(c.i);
        c.i++;
        if (ch === "]") return out;
        if (ch !== ",") throw new Error("expected , or ] at " + (c.i - 1));
    }
}

function parseObject(c: Cursor): { [key: string]: unknown } {
    c.i++;
    const out: { [key: string]: unknown } = {};
    skipSpace(c);
    if (c.s.charAt(c.i) === "}") { c.i++; return out; }
    while (true) {
        skipSpace(c);
        if (c.s.charAt(c.i) !== "\"") throw new Error("expected key at " + c.i);
        const key = parseString(c);
        skipSpace(c);
        if (c.s.charAt(c.i) !== ":") throw new Error("expected : at " + c.i);
        c.i++;
        const value = parseValue(c);
        if (value !== undefined) out[key] = value;
        skipSpace(c);
        const ch = c.s.charAt(c.i);
        c.i++;
        if (ch === "}") return out;
        if (ch !== ",") throw new Error("expected , or } at " + (c.i - 1));
    }
}
