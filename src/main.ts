/** @noSelfInFile */
/// <reference types="@typescript-to-lua/language-extensions" />
import { MaDesk } from "./console/ma-desk";
import { AutoZoom } from "./runtime/autozoom";
import { setPlugin } from "./console/window";

declare let AZ: AutoZoom | undefined;

// The chunk is called with (pluginName, componentName, signalTable, handle); window buttons need the last two.
const [, , signals, handle] = [...$vararg];
setPlugin(signals, handle);

function main(_display: unknown, _args: unknown): void {
    if (AZ !== undefined) {
        try {
            AZ.Stop();
        } catch (e) {
            Printf("[AZ] The previous AutoZoom instance did not stop cleanly: " + tostring(e));
        }
    }
    const id = string.format("%d-%d", os.time(), math.random(1, 1000000));
    AZ = new AutoZoom(new MaDesk(), id);
    Printf("[AZ] AutoZoom 2.1.0.0 by Naostage");
    AZ.Install();
    AZ.Start();
}

// @ts-ignore: grandMA3 runs the chunk's returned function
return main;
