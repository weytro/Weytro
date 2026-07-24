#Requires AutoHotkey v2.0
#SingleInstance Force
#Warn All, Off

; NOTE: auto-elevation removed. Some laptop trackpad drivers synthesize
; clicks as user-mode input, which Windows won't deliver to an admin
; window (UIPI). Keeping the exe non-admin so setup clicks work. If you
; find hotkeys don't hook Fortnite when playing, right-click the exe
; and "Run as administrator" for that session.

Persistent
SetTitleMatchMode 2
SetKeyDelay -1, -1
SetMouseDelay -1
SendMode "Input"

; ================================================================
;  FortEditPro  —  v1.3
; ================================================================

APP_NAME    := "FortEditPro"
APP_VERSION := "1.3.0"
CONFIG_FILE := A_ScriptDir "\config.ini"

COL_BG        := "0x0F0F14"
COL_SIDEBAR   := "0x16161D"
COL_CARD      := "0x1C1C26"
COL_TEXT      := "0xE6E6EE"
COL_TEXT_DIM  := "0x8A8A99"
COL_ACCENT    := "0x7C3AED"
COL_ACCENT_HI := "0x9061FF"
COL_DANGER    := "0xEF4444"
COL_OK        := "0x22C55E"
COL_INPUT     := "0x22222E"
COL_NAV_SEL   := "0x2A2140"

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

; ================================================================
;  macro helpers
; ================================================================

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

    ; Turn OFF any existing bindings from previous calls
    for hk in BoundHotkeys {
        try Hotkey hk, "Off"
    }
    BoundHotkeys := []

    ; Context: hotkeys only exist when the guard passes.
    ; When the guard is on, that means "only when Fortnite is focused."
    ; When the guard is off, InFortnite() returns true unconditionally
    ; so hotkeys are active everywhere.
    if cfg["requireFortnite"]
        HotIf (*) => InFortnite()
    else
        HotIf  ; clear - active in every window

    BindHold(cfgKey, fn) {
        global cfg, BoundHotkeys
        ; ~ passes the native key through, * fires regardless of modifiers
        hk := "~*" cfg[cfgKey]
        try {
            Hotkey hk, ((n) => (*) => fn(n))(hk), "On"
            BoundHotkeys.Push(hk)
        }
    }

    BindHold("holdDoubleTrigger",   DoHoldDoubleEdit)
    BindHold("dragEditTrigger",     DoDragEdit)
    BindHold("pickupSpamTrigger",   DoPickupSpam)
    BindHold("crouchJitterTrigger", DoCrouchJitter)

    hk := "~*" cfg["instaBuildTrigger"]
    try {
        Hotkey hk, DoInstaBuild, "On"
        BoundHotkeys.Push(hk)
    }

    ; Clear the context for anything defined after this call
    HotIf
}

; Register global control hotkeys ONCE at startup, outside BindHotkeys()
; so a bad trigger config can never wipe them.
try Hotkey "*F8", ToggleEnabled, "On"
try Hotkey "*F9", (*) => ExitApp(), "On"

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

myGui := Gui("-Caption +Border", APP_NAME)
myGui.BackColor := COL_BG
myGui.MarginX := 0
myGui.MarginY := 0

; ---------- backgrounds (added FIRST so they sit under everything) ----------
sidebarBg := myGui.Add("Progress"
    , "x0 y0 w" SB_W " h" WIN_H " Background" COL_SIDEBAR " Range0-1", 0)
headerBg  := myGui.Add("Progress"
    , "x" SB_W " y0 w" (WIN_W - SB_W) " h" HD_H
      " Background" COL_CARD " Range0-1", 0)

; ---------- brand (in sidebar) ----------
myGui.SetFont("s16 bold cWhite", "Segoe UI")
brand := myGui.Add("Text"
    , "x0 y18 w" SB_W " h26 Center Background" COL_SIDEBAR, APP_NAME)

myGui.SetFont("s8 c" TrimC(COL_TEXT_DIM), "Segoe UI")
myGui.Add("Text", "x0 y42 w" SB_W " h14 Center Background" COL_SIDEBAR
    , "v" APP_VERSION "  •  premium")

; ---------- section title (in header) ----------
myGui.SetFont("s13 bold cWhite", "Segoe UI")
sectionTitle := myGui.Add("Text"
    , "x" (SB_W + 24) " y18 w400 h22 Background" COL_CARD, "Macros")

; ---------- close / minimize (clickable text with explicit bg) ----------
myGui.SetFont("s14 bold cWhite", "Segoe UI")
minBtn := myGui.Add("Text"
    , "x" (WIN_W - 76) " y14 w28 h28 Center Background" COL_CARD, Chr(0x2013))
closeBtn := myGui.Add("Text"
    , "x" (WIN_W - 42) " y14 w28 h28 Center Background" COL_CARD, "X")

closeBtn.OnEvent("Click", (*) => ExitApp())
minBtn.OnEvent("Click",   (*) => myGui.Minimize())

; ---------- nav ----------
NAV := [
    ["macros",   "Macros"],
    ["binds",    "In-game binds"],
    ["settings", "Settings"]
]

navHwnds   := Map()
navRowBgs  := Map()

; Real Button controls for the nav - guaranteed clickable. We swap the
; button LABEL to include a leading marker for the selected item since
; native Buttons don't accept Background color.
myGui.SetFont("s10 Norm", "Segoe UI")
navY := 90
for idx, item in NAV {
    key   := item[1]
    label := item[2]

    btn := myGui.Add("Button"
        , "x10 y" navY " w" (SB_W - 20) " h36", label)

    handler := ((k) => (*) => ShowSection(k))(key)
    btn.OnEvent("Click", handler)

    navRowBgs[key] := btn   ; reused for selected-state label swap
    navHwnds[key]  := btn
    navY += 44
}

; ---------- status pill (bottom of sidebar) ----------
myGui.Add("Progress"
    , "x20 y" (WIN_H - 90) " w" (SB_W - 40) " h34"
      " Background" COL_CARD " Range0-1", 0)

myGui.SetFont("s10 bold cWhite", "Segoe UI")
statusDot := myGui.Add("Progress"
    , "x32 y" (WIN_H - 78) " w10 h10 Background" COL_OK " Range0-1", 0)
statusText := myGui.Add("Text"
    , "x48 y" (WIN_H - 80) " w120 h22 Background" COL_CARD, "Active")

myGui.SetFont("s8 c" TrimC(COL_TEXT_DIM), "Segoe UI")
myGui.Add("Text", "x20 y" (WIN_H - 44) " w" (SB_W - 40) " h30 Background" COL_SIDEBAR
    , "F8  toggle all macros`nF9  kill script")

; ================================================================
;  content sections
; ================================================================

contentX := SB_W + 24
contentY := HD_H + 24
cardW    := WIN_W - SB_W - 48

sections := Map()

MakeSection(key) {
    global sections
    sections[key] := []
}
AddToSection(key, ctrl) {
    global sections
    sections[key].Push(ctrl)
}

MakeCard(key, x, y, w, h, title) {
    global myGui, COL_CARD, COL_TEXT_DIM
    bg := myGui.Add("Progress"
        , "x" x " y" y " w" w " h" h " Background" COL_CARD " Range0-1", 0)
    AddToSection(key, bg)
    myGui.SetFont("s9 bold c" TrimC(COL_TEXT_DIM), "Segoe UI")
    ttl := myGui.Add("Text", "x" (x + 16) " y" (y + 12) " w" (w - 32)
        " h16 Background" COL_CARD, StrUpper(title))
    AddToSection(key, ttl)
}

MakeKeyField(key, x, y, w, cfgKey, label) {
    global myGui, cfg, COL_TEXT, COL_CARD, COL_INPUT
    myGui.SetFont("s9 c" TrimC(COL_TEXT), "Segoe UI")
    lbl := myGui.Add("Text", "x" x " y" y " w" (w - 160) " h22 Background" COL_CARD, label)
    AddToSection(key, lbl)

    f := myGui.Add("Edit", "x" (x + w - 150) " y" (y - 2)
        " w140 h24 Background" COL_INPUT " cWhite -E0x200 Center", cfg[cfgKey])
    f.OnEvent("LoseFocus", ((c) => (ctrl, *) => (
        cfg[c] := ctrl.Value, SaveConfig()
    ))(cfgKey))
    AddToSection(key, f)
}

MakeSlider(key, x, y, w, cfgKey, label, minV, maxV, tick) {
    global myGui, cfg, COL_TEXT, COL_CARD
    myGui.SetFont("s9 c" TrimC(COL_TEXT), "Segoe UI")
    lbl := myGui.Add("Text", "x" x " y" y " w" (w - 160) " h22 Background" COL_CARD, label)
    AddToSection(key, lbl)

    s := myGui.Add("Slider", "x" (x + w - 150) " y" (y - 2) " w110 Range" minV "-" maxV
        " TickInterval" tick, cfg[cfgKey])
    myGui.SetFont("s10 bold cWhite", "Segoe UI")
    v := myGui.Add("Text", "x" (x + w - 32) " y" y " w32 h22 Right Background" COL_CARD, cfg[cfgKey])
    s.OnEvent("Change", ((c, disp) => (ctrl, *) => (
        cfg[c] := ctrl.Value, disp.Value := ctrl.Value, SaveConfig()
    ))(cfgKey, v))
    AddToSection(key, s)
    AddToSection(key, v)
}

; ================================================================
;  section: MACROS
; ================================================================
MakeSection("macros")
MakeCard("macros", contentX, contentY, cardW, 260, "Macro triggers")

macFields := [
    ["holdDoubleTrigger",   "Hold-double-edit"],
    ["dragEditTrigger",     "Drag-edit"],
    ["pickupSpamTrigger",   "Pickup spam"],
    ["instaBuildTrigger",   "Insta-build (turtle)"],
    ["crouchJitterTrigger", "Crouch jitter"]
]
fy := contentY + 44
for pair in macFields {
    MakeKeyField("macros", contentX + 20, fy, cardW - 40, pair[1], pair[2])
    fy += 40
}

; safety card
card2Y := contentY + 280
MakeCard("macros", contentX, card2Y, cardW, 100, "Safety")

myGui.SetFont("s10 c" TrimC(COL_TEXT), "Segoe UI")
fnOnly := myGui.Add("CheckBox", "x" (contentX + 20) " y" (card2Y + 46)
    " w400 cWhite Background" COL_CARD " Checked" (cfg["requireFortnite"] ? 1 : 0)
    , "Only fire macros when Fortnite is focused")
fnOnly.OnEvent("Click", (ctrl, *) => (
    cfg["requireFortnite"] := ctrl.Value, SaveConfig()
))
AddToSection("macros", fnOnly)

; ================================================================
;  section: BINDS
; ================================================================
MakeSection("binds")
MakeCard("binds", contentX, contentY, cardW, 400, "Your in-game binds")

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
    MakeKeyField("binds", contentX + 20, fy, cardW - 40, pair[1], pair[2])
    fy += 38
}

; ================================================================
;  section: SETTINGS
; ================================================================
MakeSection("settings")
MakeCard("settings", contentX, contentY, cardW, 240, "Timing (milliseconds)")

tFields := [
    ["baseDelay",      "Base delay",       4,  40, 5],
    ["jitterAmount",   "Jitter (+/-)",     0,  10, 1],
    ["pickupInterval", "Pickup interval", 10,  80, 10],
    ["crouchInterval", "Crouch interval", 20, 120, 10]
]
fy := contentY + 50
for row in tFields {
    MakeSlider("settings", contentX + 20, fy, cardW - 40
        , row[1], row[2], row[3], row[4], row[5])
    fy += 42
}

; --- action buttons row (real Button controls) ---
btnY := contentY + 260
myGui.SetFont("s10 Norm", "Segoe UI")

applyBtn := myGui.Add("Button"
    , "x" contentX " y" btnY " w180 h40 Default", "Apply changes")
applyBtn.OnEvent("Click", (*) => (BindHotkeys(), FlashToast("Hotkeys rebound")))
AddToSection("settings", applyBtn)

exitX := contentX + 200
exitBtn := myGui.Add("Button"
    , "x" exitX " y" btnY " w180 h40", "Exit app")
exitBtn.OnEvent("Click", (*) => ExitApp())
AddToSection("settings", exitBtn)

; --- info card ---
infoY := btnY + 60
MakeCard("settings", contentX, infoY, cardW, 90, "About")

myGui.SetFont("s9 c" TrimC(COL_TEXT_DIM), "Segoe UI")
infoLbl := myGui.Add("Text"
    , "x" (contentX + 16) " y" (infoY + 40) " w" (cardW - 32) " h40 Background" COL_CARD
    , APP_NAME " v" APP_VERSION "`nSupport: discord.gg/yourserver")
AddToSection("settings", infoLbl)

; ================================================================
;  section switching
; ================================================================

currentSection := ""

ShowSection(key) {
    global sections, currentSection, sectionTitle, navHwnds, navRowBgs, NAV
    global COL_SIDEBAR, COL_NAV_SEL, COL_TEXT, COL_TEXT_DIM

    ; DEBUG: prove the click reached the handler
    ToolTip("click -> " key, , , 1)
    SetTimer(() => ToolTip(,,,1), -1200)

    if currentSection = key
        return
    for s, ctrls in sections {
        for c in ctrls
            c.Visible := (s = key)
    }
    for _, item in NAV {
        k         := item[1]
        origLabel := item[2]
        selected  := (k = key)
        ; Native Button controls can't be recolored - mark the active
        ; tab with a leading arrow instead.
        prefix := selected ? Chr(0x25B6) " " : "   "
        try navHwnds[k].Text := prefix origLabel
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
    global cfg, statusText, statusDot, COL_OK, COL_DANGER
    if cfg["enabled"] {
        statusText.Value := "Active"
        statusDot.Opt("Background" COL_OK)
    } else {
        statusText.Value := "Paused"
        statusDot.Opt("Background" COL_DANGER)
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

; Drag-by-header removed for this build. We have zero custom message
; handlers now - if a click still fails to register, the culprit is
; something other than message hooks.

; ================================================================
;  show + init
; ================================================================

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
