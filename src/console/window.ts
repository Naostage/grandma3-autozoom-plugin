/** @noSelfInFile */
// Screen-overlay windows (title bar, rows, buttons, scroll grids), ported from Bake Offset.
// Buttons call back through the plugin's signal table: PluginComponent = our handle, Clicked = signal name.

const SCROLLBAR_WIDTH = 30;

let signalTable: any = {};
let pluginHandle: any;

export function setPlugin(signals: any, handle: any): void {
    signalTable = signals ?? {};
    pluginHandle = handle;
}

export function color(group: string, name: string): any {
    const [ok, c] = pcall(() => (Root() as any).ColorTheme.ColorGroups[group][name]);
    return ok ? c : undefined;
}

function screenOverlay(): any {
    let idx = (Obj as any).Index(GetFocusDisplay());
    if (idx > 5) idx = 1;
    return (GetDisplayByIndex(idx) as any).ScreenOverlay;
}

// Writes a property that some console versions may not have.
function set(obj: any, key: string, value: any): void {
    pcall(() => { obj[key] = value; });
}

export function buildBase(title: string, width: number): any {
    const overlay = screenOverlay();
    overlay.ClearUIChildren();

    const base = overlay.Append("BaseInput");
    base.Name = title;
    base.W = width;
    base.Rows = 2;
    base[1][1].SizePolicy = "Fixed";
    base[1][1].Size = "60";
    base[1][2].SizePolicy = "Content";

    const titleBar = base.Append("TitleBar");
    titleBar.Columns = 2;
    titleBar.Anchors = "0,0";
    titleBar[2][2].SizePolicy = "Fixed";
    titleBar[2][2].Size = "50";
    set(titleBar, "Texture", "corner2");

    const titleBtn = titleBar.Append("TitleButton");
    titleBtn.Text = title;
    set(titleBtn, "Texture", "corner1");
    titleBtn.Anchors = "0,0";
    set(titleBtn, "Icon", "wizard");

    const closeBtn = titleBar.Append("CloseButton");
    closeBtn.Anchors = "1,0";
    set(closeBtn, "Texture", "corner2");

    const body = base.Append("DialogFrame");
    body.H = "100%";
    body.W = "100%";
    body.Anchors = "0,1";
    set(body, "Margin", "2,5");
    return body;
}

export function fixedRows(body: any, sizes: number[]): void {
    body.Columns = 1;
    body.Rows = sizes.length;
    sizes.forEach((s, i) => {
        body[1][i + 1].SizePolicy = "Fixed";
        body[1][i + 1].Size = tostring(s);
    });
}

export function row(parent: any, anchorRow: number): any {
    const r = parent.Append("AutoLayout");
    r.Anchors = "0," + anchorRow;
    r.W = "100%";
    r.H = "100%";
    r.Direction = "Horizontal";
    r.Content = "Yes";
    set(r, "Margin", "5,5,5,5");
    return r;
}

export function label(parent: any, text: string, w: number, h: number): any {
    const b = parent.Append("Button");
    b.W = w;
    b.H = h;
    b.Text = text;
    set(b, "Texture", "corner5");
    set(b, "TextAlignmentH", "Left");
    set(b, "TextAlignmentV", "Centre");
    set(b, "Padding", "15,5,15,5");
    set(b, "Font", "Medium20");
    set(b, "Focus", "Never");
    set(b, "HasHover", "No");
    return b;
}

export function button(parent: any, text: string, w: number, h: number, signal: string, fn: (caller: any) => void): any {
    const b = parent.Append("Button");
    b.W = w;
    b.H = h;
    b.Text = text;
    set(b, "Texture", "corner15");
    set(b, "TextAlignmentH", "Centre");
    set(b, "TextAlignmentV", "Centre");
    set(b, "Focus", "Never");
    set(b, "HasHover", "Yes");
    set(b, "Margin", "0,0,5,0");
    b.PluginComponent = pluginHandle;
    b.Clicked = signal;
    signalTable[signal] = fn;
    return b;
}

export function scrollGrid(parent: any, anchorRow: number, width: number, contentHeight: number, columns: number, rows: number): any {
    const frame = parent.Append("AutoLayout");
    frame.Anchors = "0," + anchorRow;
    frame.W = "100%";
    frame.H = "100%";
    frame.Direction = "Horizontal";
    frame.Content = "Yes";
    const box = frame.Append("ScrollBox");
    box.W = width - SCROLLBAR_WIDTH - 20;
    box.H = "100%";
    const bar = frame.Append("ScrollBarV");
    bar.W = SCROLLBAR_WIDTH;
    bar.H = "100%";
    bar.ScrollTarget = box;
    const grid = box.Append("UILayoutGrid");
    grid.Anchors = "0,0";
    grid.W = "100%";
    grid.H = contentHeight;
    grid.Columns = columns;
    grid.Rows = rows;
    return grid;
}

export function paint(obj: any, c: any): void {
    if (c !== undefined) set(obj, "BackColor", c);
}

// Tick colours of the add picker: green = in the list by itself, yellow = only through a group.
// Theme colour names to be confirmed by the group probe (C1).
export function tickColor(kind: "self" | "group"): any {
    return kind === "self" ? color("Global", "Selected") : color("Global", "WarningText");
}

export function textColor(obj: any, c: any): void {
    if (c !== undefined) set(obj, "TextColor", c);
}

export function closeWindow(): void {
    screenOverlay().ClearUIChildren();
}

export function ask(title: string, message: string): boolean {
    const r: any = MessageBox({ title, message, commands: [{ value: 1, name: "Yes" }, { value: 0, name: "No" }] } as any);
    return r !== undefined && r.result === 1;
}
