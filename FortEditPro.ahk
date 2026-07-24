#Requires AutoHotkey v2.0
#SingleInstance Force
#Warn All, Off
Persistent
SetTitleMatchMode 2
SetKeyDelay -1, -1
SetMouseDelay -1
SendMode "Input"

; ================================================================
;  FortEditPro  —  v1.2  (premium UI)
; ================================================================

APP_NAME    := "FortEditPro"
APP_VERSION := "1.2.0"
CONFIG_FILE := A_ScriptDir "\config.ini"

; ---- palette ----
COL_BG        := "0x0F0F14"
COL_SIDEBAR   := "0x16161D"
COL_CARD      := "0x1C1C26"
COL_CARD_HI   := "0x24243040"
COL_BORDER    := "0x2A2A38"
COL_TEXT      := "0xE6E6EE"
COL_TEXT_DIM  := "0x8A8A99"
COL_ACCENT    := "0x7C3AED"
COL_ACCENT_HI := "0x9061FF"
COL_OK        := "0x22C55E"
COL_BAD       := "0xEF4444"
COL_INPUT     := "0x22222E"

cfg := Map(
    "editKey","G", "confirmKey","LButton", "resetKey","RButton",
    "pickupKey","E", "crouchKey","LCtrl",
    "wallKey","Q", "floorKey","3", "stairKey","2", "roofKey","4",
    "holdDoubleTrigger","XButton1", "dragEditTrigger","XButton2",
    "pickupSpamTrigger","F", "instaBuildTrigger","MButton",
    "crouchJitterTrigger","C",
    "baseDelay",14, "jitterAmount",3,
    "pickupInterval",25, "crouchInterval",55,
    "requireFortnite",true, "enabled",true
)

LoadConfig()

JDelay(base := 0) {
    global cfg
    if base = 0
        base := cfg["baseDelay"]
    jit := cfg["jitterAmount"]
    ms  := base + Random(-jit, jit)
    if ms < 1
        ms := 1
    DllCall("Sleep", "UInt", ms)
}

InFortnite() {
    global cfg
    if !cfg["requireFortnite"]
        return true
    return WinActive("ahk_exe FortniteClient-Win64-Shipping.exe")
        || WinActive("ahk_exe FortniteClient-Win64-Shipping_EAC.exe")
        || WinActive("ahk_exe FortniteClient-Win64-Shipping_EAC_EOS.exe")
        || WinActive("Fortnite")
}

TapKey(k) {
    Send "{" k " down}"
    JDelay()
    Send "{" k " up}"
}
HoldKey(k) {
    if (k = "LButton" || k = "RButton" || k = "MButton")
        Click "Down " SubStr(k, 1, StrLen(k) - 6)
    else
        Send "{" k " down}"
}
ReleaseKey(k) {
    if (k = "LButton" || k = "RButton" || k = "MButton")
        Click "Up " SubStr(k, 1, StrLen(k) - 6)
    else
        Send "{" k " up}"
}
ClickBtn(k) {
    if (k = "LButton")
        Click "Left"
    else if (k = "RButton")
        Click "Right"
    else if (k = "MButton")
        Click "Middle"
    else
        TapKey(k)
}
CleanKey(hk) {
    while StrLen(hk) && InStr("$*~+^!#", SubStr(hk, 1, 1))
        hk := SubStr(hk, 2)
    return hk
}

DoHoldDoubleEdit(hkName, *) {
    global cfg
    if !cfg["enabled"] || !InFortnite()
        return
    key := CleanKey(hkName)
    Loop {
        if !GetKeyState(key, "P")
            break
        TapKey(cfg["editKey"]), JDelay()
        ClickBtn(cfg["confirmKey"]), JDelay()
        if !GetKeyState(key, "P")
            break
        TapKey(cfg["editKey"]), JDelay()
        ClickBtn(cfg["confirmKey"]), JDelay()
    }
}

DoDragEdit(hkName, *) {
    global cfg
    if !cfg["enabled"] || !InFortnite()
        return
    key := CleanKey(hkName)
    TapKey(cfg["editKey"]), JDelay()
    HoldKey(cfg["confirmKey"])
    while GetKeyState(key, "P")
        Sleep 5
    ReleaseKey(cfg["confirmKey"]), JDelay()
    ClickBtn(cfg["confirmKey"])
}

DoPickupSpam(hkName, *) {
    global cfg
    if !cfg["enabled"] || !InFortnite()
        return
    key := CleanKey(hkName)
    while GetKeyState(key, "P") {
        Send "{" cfg["pickupKey"] " down}"
        Sleep 10
        Send "{" cfg["pickupKey"] " up}"
        JDelay(cfg["pickupInterval"])
    }
}

DoInstaBuild(*) {
    global cfg
    if !cfg["enabled"] || !InFortnite()
        return
    TapKey(cfg["wallKey"]),  JDelay()
    TapKey(cfg["stairKey"]), JDelay()
    TapKey(cfg["floorKey"]), JDelay()
    TapKey(cfg["roofKey"])
}

DoCrouchJitter(hkName, *) {
    global cfg
    if !cfg["enabled"] || !InFortnite()
        return
    key := CleanKey(hkName)
    while GetKeyState(key, "P") {
        Send "{" cfg["crouchKey"] " down}"
        JDelay(cfg["crouchInterval"])
        Send "{" cfg["crouchKey"] " up}"
        JDelay(cfg["crouchInterval"])
    }
}

LoadConfig() {
    global cfg, CONFIG_FILE
    if !FileExist(CONFIG_FILE)
        return
    for k in cfg {
        val := IniRead(CONFIG_FILE, "Settings", k, "")
        if val = ""
            continue
        if (k = "baseDelay" || k = "jitterAmount"
            || k = "pickupInterval" || k = "crouchInterval")
            cfg[k] := Integer(val)
        else if (k = "requireFortnite" || k = "enabled")
            cfg[k] := (val = "1" || val = "true")
        else
            cfg[k] := val
    }
}

SaveConfig() {
    global cfg, CONFIG_FILE
    for k, v in cfg {
        out := (v = true) ? "1" : (v = false) ? "0" : v
        IniWrite(out, CONFIG_FILE, "Settings", k)
    }
}

BoundHotkeys := []

BindHotkeys() {
    global cfg, BoundHotkeys
    for hk in BoundHotkeys {
        try Hotkey hk, "Off"
    }
    BoundHotkeys := []

    BindHold(cfgKey, fn) {
        global cfg, BoundHotkeys
        hk := "*" cfg[cfgKey]
        try {
            Hotkey hk, ((n) => (*) => fn(n))(hk), "On"
            BoundHotkeys.Push(hk)
        }
    }

    BindHold("holdDoubleTrigger",   DoHoldDoubleEdit)
    BindHold("dragEditTrigger",     DoDragEdit)
    BindHold("pickupSpamTrigger",   DoPickupSpam)
    BindHold("crouchJitterTrigger", DoCrouchJitter)

    hk := "*" cfg["instaBuildTrigger"]
    try {
        Hotkey hk, DoInstaBuild, "On"
        BoundHotkeys.Push(hk)
    }

    try Hotkey "F8", ToggleEnabled, "On"
    try Hotkey "F9", (*) => ExitApp(), "On"
}

ToggleEnabled(*) {
    global cfg
    cfg["enabled"] := !cfg["enabled"]
    UpdateStatusPill()
}

; ================================================================
;  GUI
; ================================================================

WIN_W := 860
WIN_H := 600
SB_W  := 220
HD_H  := 54

myGui := Gui("-Caption +Border +LastFound", APP_NAME)
myGui.BackColor := COL_BG
myGui.MarginX := 0
myGui.MarginY := 0

sidebarBg := myGui.Add("Progress"
    , "x0 y0 w" SB_W " h" WIN_H " Background" COL_SIDEBAR " Range0-1", 0)

headerBg := myGui.Add("Progress"
    , "x" SB_W " y0 w" (WIN_W - SB_W) " h" HD_H
      " Background" COL_CARD " Range0-1", 0)

myGui.SetFont("s16 bold cWhite", "Segoe UI")
brand := myGui.Add("Text"
    , "x20 y18 w" (SB_W - 40) " h26 BackgroundTrans", APP_NAME)

myGui.SetFont("s8 c" TrimC(COL_TEXT_DIM), "Segoe UI")
myGui.Add("Text", "x20 y42 w" (SB_W - 40) " h14 BackgroundTrans"
    , "v" APP_VERSION "  •  premium")

myGui.SetFont("s13 bold cWhite", "Segoe UI")
sectionTitle := myGui.Add("Text"
    , "x" (SB_W + 24) " y18 w400 h22 BackgroundTrans", "Macros")

myGui.SetFont("s14 bold cWhite", "Segoe UI")
minBtn := myGui.Add("Text"
    , "x" (WIN_W - 76) " y14 w28 h28 Center BackgroundTrans", Chr(0x2013))
closeBtn := myGui.Add("Text"
    , "x" (WIN_W - 42) " y14 w28 h28 Center BackgroundTrans", "X")

closeBtn.OnEvent("Click", (*) => ExitApp())
minBtn.OnEvent("Click",   (*) => myGui.Minimize())

NAV := [
    ["macros",  "Macros"],
    ["binds",   "In-game binds"],
    ["timing",  "Timing"],
    ["about",   "About"]
]

navHwnds := Map()
navAccents := Map()

myGui.SetFont("s10 c" TrimC(COL_TEXT), "Segoe UI")
navY := 90
for idx, item in NAV {
    key   := item[1]
    label := item[2]

    accent := myGui.Add("Progress"
        , "x0 y" navY " w4 h36 Background" COL_ACCENT " Range0-1", 0)
    accent.Visible := false

    t := myGui.Add("Text"
        , "x20 y" (navY + 8) " w" (SB_W - 30) " h22 BackgroundTrans", label)
    t.OnEvent("Click", ((k) => (*) => ShowSection(k))(key))

    navHwnds[key]   := t
    navAccents[key] := accent
    navY += 44
}

statusPillBg := myGui.Add("Progress"
    , "x20 y" (WIN_H - 90) " w" (SB_W - 40) " h34"
      " Background" COL_CARD " Range0-1", 0)

myGui.SetFont("s10 bold cWhite", "Segoe UI")
statusDot := myGui.Add("Progress"
    , "x32 y" (WIN_H - 78) " w10 h10 Background" COL_OK " Range0-1", 0)
statusText := myGui.Add("Text"
    , "x48 y" (WIN_H - 80) " w120 h22 BackgroundTrans", "Active")

myGui.SetFont("s8 c" TrimC(COL_TEXT_DIM), "Segoe UI")
myGui.Add("Text", "x20 y" (WIN_H - 44) " w" (SB_W - 40)
    " h30 BackgroundTrans"
    , "F8  toggle all macros`nF9  kill script")

contentX := SB_W + 24
contentY := HD_H + 24

sections := Map()

MakeSection(key) {
    global sections
    sections[key] := []
}
AddToSection(key, ctrl) {
    global sections
    sections[key].Push(ctrl)
}

MakeCard(x, y, w, h, title) {
    global myGui
    ctrls := []
    bg := myGui.Add("Progress"
        , "x" x " y" y " w" w " h" h
          " Background" COL_CARD " Range0-1", 0)
    ctrls.Push(bg)
    myGui.SetFont("s9 bold c" TrimC(COL_TEXT_DIM), "Segoe UI")
    ttl := myGui.Add("Text", "x" (x + 16) " y" (y + 12) " w"
        (w - 32) " h16 BackgroundTrans", StrUpper(title))
    ctrls.Push(ttl)
    return ctrls
}

MakeField(x, y, w, cfgKey, label, isSlider := false
        , minV := 0, maxV := 100, tick := 10) {
    global myGui, cfg
    ctrls := []
    myGui.SetFont("s9 c" TrimC(COL_TEXT), "Segoe UI")
    lbl := myGui.Add("Text", "x" x " y" y " w" (w - 160)
        " h22 BackgroundTrans", label)
    ctrls.Push(lbl)

    if isSlider {
        s := myGui.Add("Slider", "x" (x + w - 150) " y" (y - 2)
            " w110 Range" minV "-" maxV " TickInterval" tick, cfg[cfgKey])
        myGui.SetFont("s10 bold cWhite", "Segoe UI")
        v := myGui.Add("Text", "x" (x + w - 32) " y" y
            " w32 h22 Right BackgroundTrans", cfg[cfgKey])
        s.OnEvent("Change", ((c, disp) => (ctrl, *) => (
            cfg[c] := ctrl.Value, disp.Value := ctrl.Value, SaveConfig()
        ))(cfgKey, v))
        ctrls.Push(s), ctrls.Push(v)
    } else {
        f := myGui.Add("Edit", "x" (x + w - 150) " y" (y - 2)
            " w140 h24 Background" COL_INPUT " cWhite -E0x200 Center"
            , cfg[cfgKey])
        f.OnEvent("LoseFocus", ((c) => (ctrl, *) => (
            cfg[c] := ctrl.Value, SaveConfig()
        ))(cfgKey))
        ctrls.Push(f)
    }
    return ctrls
}

MakeSection("macros")

cardW := WIN_W - SB_W - 48
card := MakeCard(contentX, contentY, cardW, 260, "Macro triggers")
for c in card
    AddToSection("macros", c)

macFields := [
    ["holdDoubleTrigger",   "Hold-double-edit"],
    ["dragEditTrigger",     "Drag-edit"],
    ["pickupSpamTrigger",   "Pickup spam"],
    ["instaBuildTrigger",   "Insta-build (turtle)"],
    ["crouchJitterTrigger", "Crouch jitter"]
]

fy := contentY + 44
for pair in macFields {
    ctrls := MakeField(contentX + 20, fy, cardW - 40, pair[1], pair[2])
    for c in ctrls
        AddToSection("macros", c)
    fy += 40
}

card2Y := contentY + 280
card := MakeCard(contentX, card2Y, cardW, 100, "Safety")
for c in card
    AddToSection("macros", c)

myGui.SetFont("s10 c" TrimC(COL_TEXT), "Segoe UI")
fnOnly := myGui.Add("CheckBox", "x" (contentX + 20) " y" (card2Y + 46)
    " w400 cWhite Background" COL_CARD " Checked"
    (cfg["requireFortnite"] ? 1 : 0)
    , "Only fire macros when Fortnite is focused")
fnOnly.OnEvent("Click", (ctrl, *) => (
    cfg["requireFortnite"] := ctrl.Value, SaveConfig()
))
AddToSection("macros", fnOnly)

MakeSection("binds")

card := MakeCard(contentX, contentY, cardW, 400, "Your in-game binds")
for c in card
    AddToSection("binds", c)

bindFields := [
    ["editKey",    "Edit key"],
    ["confirmKey", "Edit confirm (LButton)"],
    ["resetKey",   "Edit reset (RButton)"],
    ["pickupKey",  "Pickup / interact"],
    ["crouchKey",  "Crouch"],
    ["wallKey",    "Wall"],
    ["stairKey",   "Stair / ramp"],
    ["floorKey",   "Floor"],
    ["roofKey",    "Roof / cone"]
]
fy := contentY + 44
for pair in bindFields {
    ctrls := MakeField(contentX + 20, fy, cardW - 40, pair[1], pair[2])
    for c in ctrls
        AddToSection("binds", c)
    fy += 38
}

MakeSection("timing")

card := MakeCard(contentX, contentY, cardW, 240, "Timing (milliseconds)")
for c in card
    AddToSection("timing", c)

tFields := [
    ["baseDelay",      "Base delay",       4,  40, 5],
    ["jitterAmount",   "Jitter (+/-)",     0,  10, 1],
    ["pickupInterval", "Pickup interval", 10,  80, 10],
    ["crouchInterval", "Crouch interval", 20, 120, 10]
]
fy := contentY + 50
for row in tFields {
    ctrls := MakeField(contentX + 20, fy, cardW - 40
        , row[1], row[2], true, row[3], row[4], row[5])
    for c in ctrls
        AddToSection("timing", c)
    fy += 42
}

rebindY := contentY + 260
myGui.SetFont("s10 bold cWhite", "Segoe UI")
rebindBg := myGui.Add("Progress"
    , "x" contentX " y" rebindY " w180 h40 Background" COL_ACCENT
      " Range0-1", 0)
rebindLbl := myGui.Add("Text"
    , "x" contentX " y" (rebindY + 10) " w180 h20 Center BackgroundTrans"
    , "Apply changes")
rebindLbl.OnEvent("Click", (*) => (BindHotkeys(), FlashToast("Hotkeys rebound")))
rebindBg.OnEvent("Click",  (*) => (BindHotkeys(), FlashToast("Hotkeys rebound")))
AddToSection("timing", rebindBg)
AddToSection("timing", rebindLbl)

MakeSection("about")

card := MakeCard(contentX, contentY, cardW, 220, "About")
for c in card
    AddToSection("about", c)

myGui.SetFont("s10 c" TrimC(COL_TEXT), "Segoe UI")
a1 := myGui.Add("Text"
    , "x" (contentX + 20) " y" (contentY + 44) " w" (cardW - 40)
      " h22 BackgroundTrans", APP_NAME " - high-performance macro suite")
AddToSection("about", a1)

myGui.SetFont("s9 c" TrimC(COL_TEXT_DIM), "Segoe UI")
a2 := myGui.Add("Text"
    , "x" (contentX + 20) " y" (contentY + 72) " w" (cardW - 40)
      " h60 BackgroundTrans"
    , "Version " APP_VERSION "`nBuilt for Fortnite. Optimized delays,"
    . " humanized jitter, per-key remapping, session-persistent config.")
AddToSection("about", a2)

myGui.SetFont("s9 c" TrimC(COL_TEXT_DIM), "Segoe UI")
a3 := myGui.Add("Text"
    , "x" (contentX + 20) " y" (contentY + 150) " w" (cardW - 40)
      " h50 BackgroundTrans"
    , "License:  active`nSupport:  discord.gg/yourserver")
AddToSection("about", a3)

currentSection := ""

ShowSection(key) {
    global sections, currentSection, sectionTitle, navHwnds, navAccents, NAV
    if currentSection = key
        return
    for s, ctrls in sections {
        for c in ctrls
            c.Visible := (s = key)
    }
    for _, item in NAV {
        k := item[1]
        navAccents[k].Visible := (k = key)
        try navHwnds[k].Opt(
            (k = key) ? "c" TrimC("0xFFFFFF") : "c" TrimC(COL_TEXT_DIM)
        )
    }
    for _, item in NAV {
        if item[1] = key {
            sectionTitle.Value := item[2]
            break
        }
    }
    currentSection := key
}

UpdateStatusPill() {
    global cfg, statusText, statusDot, COL_OK, COL_BAD
    if cfg["enabled"] {
        statusText.Value := "Active"
        statusDot.Opt("Background" COL_OK)
    } else {
        statusText.Value := "Paused"
        statusDot.Opt("Background" COL_BAD)
    }
    statusDot.Value := 0
}

FlashToast(text) {
    ToolTip(text, , , 1)
    SetTimer(() => ToolTip(,,,1), -1200)
}

TrimC(hex) {
    if SubStr(hex, 1, 2) = "0x"
        return SubStr(hex, 3)
    return hex
}

StrUpper(s) {
    return Format("{:U}", s)
}

OnMessage(0x201, WM_LBUTTONDOWN_Handler)

WM_LBUTTONDOWN_Handler(wParam, lParam, msg, hwnd) {
    global myGui, headerBg, brand, sectionTitle, sidebarBg
    if (hwnd = headerBg.Hwnd || hwnd = brand.Hwnd
        || hwnd = sectionTitle.Hwnd || hwnd = sidebarBg.Hwnd) {
        PostMessage(0xA1, 2, 0, , "ahk_id " myGui.Hwnd)
    }
}

myGui.Show("w" WIN_W " h" WIN_H)
ShowSection("macros")
UpdateStatusPill()

A_TrayMenu.Delete()
A_TrayMenu.Add("Show " APP_NAME, (*) => myGui.Show())
A_TrayMenu.Add("Toggle on/off", ToggleEnabled)
A_TrayMenu.Add()
A_TrayMenu.Add("Exit", (*) => ExitApp())
A_TrayMenu.Default := "Show " APP_NAME
A_IconTip := APP_NAME " v" APP_VERSION

BindHotkeys()
