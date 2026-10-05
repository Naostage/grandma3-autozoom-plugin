/** @noSelfInFile */
const warned: { [key: string]: boolean } = {};

export function info(message: string): void {
    Printf("[AZ] " + message);
}

export function warnOnce(key: string, message: string): void {
    if (warned[key]) return;
    warned[key] = true;
    Printf("[AZ warning] " + message);
}
