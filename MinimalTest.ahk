#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

myGui := Gui("", "Click Test")
myGui.BackColor := "0x222222"

myGui.SetFont("s12 bold cWhite", "Segoe UI")
myGui.Add("Text", "x20 y10 w280 h30 Background0x222222"
    , "Bare-bones button test")

myGui.SetFont("s11 Norm cBlack", "Segoe UI")
btn := myGui.Add("Button", "x20 y50 w280 h60", "CLICK ME")
btn.OnEvent("Click", (*) => MsgBox(
    "SUCCESS: native Button.OnEvent(Click) fires on this machine.",
    "Click test", "T4"))

myGui.SetFont("s9 cWhite", "Segoe UI")
myGui.Add("Text", "x20 y120 w280 h40 Background0x222222"
    , "If clicking the button above shows a message box,"
    . " clicks work on this machine and the bug is somewhere in"
    . " FortEditPro. Press F9 to close.")

myGui.Show("w320 h180")

*F9::ExitApp()
