import { AZ_FTOpticalParameters, Vector3 } from "./types";


export type TargetZoomIris = {
    zoom: number,
    iris: number
}


function getFaderValue(min: number, max: number, value: number) : number {
    if (max == min) {
        return 100;
    }
    let level = Math.round((value - min) / (max - min)*100);
    return Math.min(100, Math.max(0, level));
}


function getBeamSizeAtTarget(zoom: number, distance: number) : number {
    // zoom in degrees, distance in meters
    // Calculate the beam size at the target
    let angle = zoom * Math.PI / 180;
    return 2 * distance * Math.tan(angle/2);
}

// Based on the distance between the two points, calculate the zoom level and the iris
export function calculateZoomIrisFaderValues(fixturePosition : Vector3, targetPosition : Vector3, opticalParameters: AZ_FTOpticalParameters, targetBeamDiameter:number) : TargetZoomIris {
    // This function calculates the zoom and iris values to point a beam of a specific size to a target
    // The beam is a cone, and the size is the diameter of the cone at the target position
    // The fixturePosition is the position of the fixture
    // The targetPosition is the position of the target
    // The opticalParameters are the zoom and iris ranges of the fixture : zoom : min, max in degrees, iris : min, max in percentage
    // The beamSize is the diameter of the beam at the target position

    // Calculate the distance between the fixture and the target
    let distance = fixturePosition.distance(targetPosition);

    // Calculate the necessary angle to have the cone in so that the diameter at the target is the beamSize (so radius is beamSize/2)
    let angle = Math.atan((targetBeamDiameter/2) / distance)*2*180/Math.PI; // angle of the cone in degrees

    // If the zoom is enough to have the beamSize at the target, return the zoom and iris values
    // The zoom is enough if the angle is between the min and max zoom values
    if (angle >= opticalParameters.zoom.min && angle <= opticalParameters.zoom.max) {
        // Calculate the zoom value
        return {zoom: getFaderValue(opticalParameters.zoom.min, opticalParameters.zoom.max, angle), iris: 100};
    }
    // If the zoom isn't enough (beam needed is too small), return the zoom value at min and the iris value to have the beamSize at the target
    else if (angle < opticalParameters.zoom.min) {
        let zoomBeamSize = getBeamSizeAtTarget(opticalParameters.zoom.min, distance);
        if (opticalParameters.iris.min === opticalParameters.iris.max) {
            return {zoom: 0, iris: -1};
        }
        let irisLevel = getFaderValue(opticalParameters.iris.min, opticalParameters.iris.max, targetBeamDiameter/zoomBeamSize);
        return {zoom: 0, iris: irisLevel};
    }
    else {
        // if the zoom is not wide enough, return the max zoom and iris.
        return {zoom: 100, iris: 100};
    }
}
