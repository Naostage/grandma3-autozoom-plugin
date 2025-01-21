

export function createMacro(name:string, number:number, lines:string[]) {
    CmdIndirect("Store Macro " + number + " '" + name + "' /o /nc");
    for (let i = 0; i < lines.length; i++) {
        CmdIndirect("Store Macro " + number +"."+(i+1)+" /o /nc");
        CmdIndirect("Set Macro " + number +"."+(i+1) + " Property 'Command' '" + lines[i] + "'");
    }
}