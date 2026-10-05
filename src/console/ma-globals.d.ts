/** @noSelfInFile */
// grandMA3 globals used by AutoZoom that grandma3-ts-types does not declare (or declares too narrowly).
declare function GetRTChannel(uiChannel: number): any;
declare function Time(): number;
declare function Timer(callback: () => void, delaySec: number, repeatTimes: number, cleanup?: () => void): void;
