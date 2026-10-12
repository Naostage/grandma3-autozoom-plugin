
let logLevel = 1;

export function SetLogLevel(levelString: string) {
    switch (levelString) {
        case "DEBUG":
            logLevel = 0;
            break;
        case "INFO":
            logLevel = 1;
            break;
        case "WARN":
            logLevel = 2;
            break;
        case "ERROR":
            logLevel = 3;
            break;
        default:
            logLevel = 1;
            break;
    }
    Popup("Log level set to " + getLogLevelString(logLevel));
}

function getLogLevelString(level : number) {
    switch(level) {
        case 0:
            return " - DEBUG"
        case 1:
            return " - INFO"
        case 2:
            return " - WARN"
        case 3:
            return " - ERROR"
        default:
            return ""
    }
}

export function PrintLogLevel() {
    Popup("Log level is " + getLogLevelString(logLevel));
}
export function PrintEcho(message : string, level : number) {
    if (level >= logLevel) {
        Printf("[AZ" + getLogLevelString(level) + "] " + message);
    }
}


export function remap(value: number, low1: number, high1: number, low2: number, high2: number): number {
    return low2 + (high2 - low2) * (value - low1) / (high1 - low1);
}


export function ClearAll() : void {
    Cmd("ClearAll");
}

export function Popup(message : string | string[], level : number = 10) {
    MessageBox({
        title: "AutoZoom" + getLogLevelString(level),
        message: typeof message === "string" ? message : message.join("\n"),
        commands: [{ value: 1, name: "OK" }],
    });
}
