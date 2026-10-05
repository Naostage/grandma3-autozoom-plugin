/** @noSelfInFile */
import { Optics } from "./engine/beam";
import { Vec3 } from "./engine/vec";

export interface PatchFixture {
    fid: number;
    name: string;
    position: Vec3;                                            // stage position, parents included
    optics: Optics;
    uich: { marker: number; x: number; y: number; z: number }; // UI channel indexes of XYZ_MArker, XYZ_X/Y/Z
}
export interface Space { min: Vec3; max: Vec3 }
export interface PatchMarker { cid: number; name: string; targetSpace: Space }
export interface PatchScan { fixtures: PatchFixture[]; markers: PatchMarker[]; problems: string[] }
export interface MarkerReading { pos: Vec3; rot?: Vec3 }
export type MarkerReadings = { [cid: string]: MarkerReading };
export interface CellSpec { key: string; x: number; y: number; w: number; h: number; command: string }
export interface CellView { text: string; border: string; textColor: string }
export type Views = { [key: string]: CellView };
export interface SeqRef { id: string; no: number; name: string }
