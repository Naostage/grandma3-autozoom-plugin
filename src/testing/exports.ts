/** @noSelfInFile */
// Entry of the test bundle (build/azlib.lua). Each module under test is re-exported here.
import * as format from "../format";
import * as json from "../store/json";
import * as config from "../store/config";
import * as vec from "../engine/vec";
import * as beam from "../engine/beam";
import * as state from "../engine/fixture-state";
import * as arm from "../engine/arm-command";
import * as program from "../engine/program";
import * as preset from "../engine/preset-ref";
import * as view from "../ui/view-model";
import * as runtime from "../runtime/autozoom";
import * as patch from "../console/patch";
import * as live from "../console/live";
import * as vars from "../console/vars";
import * as madesk from "../console/ma-desk";

export const ready = true;
export { format, json, config, vec, beam, state, arm, program, preset, view, runtime, patch, live, vars, madesk };
