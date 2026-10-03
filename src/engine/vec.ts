/** @noSelfInFile */

export interface Vec3 { x: number; y: number; z: number }

export function vec(x: number, y: number, z: number): Vec3 {
    return { x, y, z };
}

export function add(a: Vec3, b: Vec3): Vec3 {
    return { x: a.x + b.x, y: a.y + b.y, z: a.z + b.z };
}

export function distance(a: Vec3, b: Vec3): number {
    const dx = a.x - b.x, dy = a.y - b.y, dz = a.z - b.z;
    return Math.sqrt(dx * dx + dy * dy + dz * dz);
}

// Euler rotation in degrees, applied about the fixed X, then Y, then Z axes.
export function rotate(v: Vec3, deg: Vec3): Vec3 {
    const rx = deg.x * Math.PI / 180, ry = deg.y * Math.PI / 180, rz = deg.z * Math.PI / 180;
    let x = v.x, y = v.y, z = v.z;
    let t = y * Math.cos(rx) - z * Math.sin(rx); z = y * Math.sin(rx) + z * Math.cos(rx); y = t;
    t = x * Math.cos(ry) + z * Math.sin(ry); z = -x * Math.sin(ry) + z * Math.cos(ry); x = t;
    t = x * Math.cos(rz) - y * Math.sin(rz); y = x * Math.sin(rz) + y * Math.cos(rz); x = t;
    return { x, y, z };
}
