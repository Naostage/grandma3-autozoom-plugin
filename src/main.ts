
import { AZ_Global_Type } from "./autozoom_object";
import { PrintEcho, SetLogLevel } from "./utils";



declare var AZ : AZ_Global_Type; 

function main(display: any, args: any) {
    // if AZ exists, we clean it up
    if (AZ !== undefined) {
        AZ.DisableAllFixtures();
        AZ.Cleanup();
        AZ.Disable();
    }   
    AZ = new AZ_Global_Type();
    AZ.Init();
}

// ignore error for this : 
// @ts-ignore
return main;

