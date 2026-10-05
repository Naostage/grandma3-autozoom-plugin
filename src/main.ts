/** @noSelfInFile */
import { MaDesk } from "./console/ma-desk";
import { AutoZoom } from "./runtime/autozoom";

declare let AZ: AutoZoom | undefined;

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
    Printf("[AZ] AutoZoom 2.0.0 by Naostage");
    AZ.Install();
    AZ.Start();
}

// @ts-ignore: grandMA3 runs the chunk's returned function
return main;
