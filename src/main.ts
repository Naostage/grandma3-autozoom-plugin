import { AZ_Global_Type } from "./autozoom_object";
import { PrintEcho } from "./utils";

declare var AZ: AZ_Global_Type | undefined;

const GLOBAL_NAME = "AZ";

// grandMA3 v2.5.1 resolves the global name "AZ" to a value that is not a plugin
// instance (no Cleanup/CreateMacros methods). Only treat a value as a previous
// AutoZoom instance when it really is one.
function isAutoZoomInstance(value: unknown): value is AZ_Global_Type {
    if (type(value) !== "table") return false;
    const [ok, isInstance] = pcall(() => type((value as any).Cleanup) === "function" && type((value as any).Init) === "function");
    return ok && isInstance === true;
}

function cleanupPrevious(value: unknown): void {
    if (!isAutoZoomInstance(value)) return;
    const [ok, err] = pcall(() => value.Cleanup());
    if (!ok) PrintEcho("Failed to clean up previous instance : " + tostring(err), 2);
}

function main(display: any, args: any) {
    const globals = _G as any;
    const rawPrevious = rawget(globals, GLOBAL_NAME);
    cleanupPrevious(rawPrevious);
    if (AZ !== rawPrevious) cleanupPrevious(AZ);

    const instance = new AZ_Global_Type();
    // rawset bypasses any metamethod on the global table so that Lua "AZ:..." commands
    // (macros, command line) reach this instance; the plain assignment covers a plugin
    // environment that is not _G.
    rawset(globals, GLOBAL_NAME, instance);
    AZ = instance;
    instance.Init();
}

// ignore error for this :
// @ts-ignore
return main;
