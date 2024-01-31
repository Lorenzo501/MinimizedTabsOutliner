#Requires AutoHotkey 2.0
#SingleInstance Force ; For UI Access
#NoTrayIcon

; To make certain things work even when an admin window becomes active
if (!InStr(A_AhkPath, "_UIA.exe"))
{
    Run("*UIAccess " A_ScriptFullPath)
    ExitApp()
}

Persistent()
interfaceImprovementsJS := "
(
    arrayHtml = document.getElementsByClassName(`"mainViewMessage`"); arrayHtml[0].parentNode.removeChild(arrayHtml[0]);
    arrayHtml = document.getElementsByClassName(`"winNTASC`"); arrayHtml[arrayHtml.length - 1].replaceChildren();
    window.scrollTo(0, document.body.scrollHeight - window.innerHeight - 1200)
)"
A_KeyDelay := -1 ; For pasting with ControlSend
A_WinDelay := -1
A_CoordModeMouse := "Screen"
EVENT_OBJECT_SHOW := 0x8002
EVENT_OBJECT_LOCATIONCHANGE := 0x800B
EVENT_OBJECT_NAMECHANGE := 0x800C

WinWait("ahk_class Progman") ; Gotta wait until it exists before activating it to deactivate the taskbar
TaskbarUtilities.ToggleDeactivateTimer()

Run(RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run", "WinSize2"),,, &pid)
HookEvent(EVENT_OBJECT_SHOW, HandleWinSize2Event, pid)
HookEvent(EVENT_OBJECT_LOCATIONCHANGE, HandleWinSize2Event, pid)
Sleep(200)
ToggleWinSize2()

HandleWinSize2Event(hWinEventHook, event, hWnd, *)
{
    try WinClose("ahk_class tooltips_class32 ahk_id " hWnd)
}

TaskbarUtilities.WaitDeactivate()

if (!TaskbarUtilities.HasDeactivateTimedOut)
    TaskbarUtilities.MakeInvisible()

if (WinActive("ahk_exe explorer.exe") && !WinActive("ahk_class CabinetWClass"))
    windowToActivate := "ahk_class Progman" ; Activating desktop in the end to prevent WinSize2 from trying to fix the position/size of a minimized window (keeps it minimized)
else
    windowToActivate := WinExist("A") ; The currently active window gets reactivated in the end

BufferInputs(true) ; Start buffering keys
HookEvent(EVENT_OBJECT_NAMECHANGE, HandleTabsOutlinerEvent)
Run("chrome.exe --silent-launch --start-maximized")

HandleTabsOutlinerEvent(hWinEventHook, event, hWnd, *)
{
    static isBeingMinimized := false

    try
        if (WinGetTitle(hWnd) = "_crx_eggkanocgddhmamlbiijnphhppkpkmkl" && !isBeingMinimized)
        {
            isBeingMinimized := true
            WinSetTransparent(0, hWnd)
            DllCall("UnhookWinEvent", "Ptr", hWinEventHook)
            HookEvent(EVENT_OBJECT_SHOW, HandleStatusBarEvent)
;Thread("NoTimers")
;Thread("Priority", 1)
            WinWait("Tabs Outliner ahk_exe chrome.exe")
            ProcessWaitClose("LogonUI.exe")
            WinActivate()
            Send("{End 2}{Esc}")
            HookEvent(EVENT_OBJECT_NAMECHANGE, HandleDevToolsEvent, WinGetPID())
;Sleep(500)
            WinActivate()
            Send("{Esc}{F12}")
        }

    HandleStatusBarEvent(hWinEventHook, event, hWnd, *)
    {
        static isBeingHidden := false
        titleMatchModePrevious := SetTitleMatchMode("RegEx")

        try
            if (WinExist("^$ ahk_class Chrome_WidgetWin_1") && !isBeingHidden) ; Titleless chrome status bar (^ = begin of line, $ = end of line)
            {
                isBeingHidden := true
                WinHide()
                DllCall("UnhookWinEvent", "Ptr", hWinEventHook)
            }

        A_TitleMatchMode := titleMatchModePrevious
    }

    HandleDevToolsEvent(hWinEventHook, event, hWnd, *)
    {
        static isBeingMadeTransparent := false, errors := "Errors:"

        try
            if (WinGetTitle(hWnd) = "DevToolsApp" && !isBeingMadeTransparent)
            {
                isBeingMadeTransparent := true
                WinSetTransparent(0, hWnd)
                DllCall("UnhookWinEvent", "Ptr", hWinEventHook)
                WinExist(hWnd)
                Sleep(300)
                WinHide()
                Send("^``")
                Sleep(500)
                shouldDetectHiddenWindowsPrevious := DetectHiddenWindows(true)
                ClipSend(interfaceImprovementsJS)
                Sleep(500)
                WinClose()
                A_DetectHiddenWindows := shouldDetectHiddenWindowsPrevious

                WinExist("Tabs Outliner ahk_exe chrome.exe")
                MoveAndResize()
;Sleep(200)
                WinMinimize()
;WinWaitNotActive(,, 2) ; Use this if the window becomes opaque before the minimize animation finishes
                WinSetTransparent("Off")
/*
instead of the two lines above, only for the multi-purpose / launch parameter / merged version of this script (the next 'Create' commit)
if (A_Args.length = 0)
    WinMinimize(), WinSetTransparent("Off")
*/
                Sleep(200)
                WinHide()
                Sleep(100)
                WinShow()
                TaskbarUtilities.Show()
                ProcessWaitClose("userinit.exe") ; At this point all startup software is running
                Sleep(100)
                WinActivate(WinExist(windowToActivate) ? windowToActivate : "ahk_class Progman")
                Sleep(200)
                BufferInputs(, true) ; Stop buffering keys and sending them out
                ToggleWinSize2() ; Unpausing WinSize2 now that it can no longer misbehave at startup
/*
only for the multi-purpose / launch parameter / merged version of this script (the next 'Create' commit)
; These scopes are executed late b/c there is no other workaround to prevent WinSize2 from affecting Tabs Outliner in these modes
if (A_Args.length > 0)
{
    if (A_Args[1] = "--duo")
    {
        Sleep(1000)
        WinMinimize()
        WinSetTransparent("Off")
    }
    else if (A_Args[1] = "--single")
        WinSetTransparent("Off")
}
*/
                Sleep(8000) ; To get rid of the WinSize2 ToolTip
                ExitApp()
            }
        catch as e  ; Handles the first error thrown by the block above
            Tooltip(errors .= "`n" e.Message "`t" e.What "`t" e.Line "`t" e.Stack)
    }
}

;********** LIBRARY **********

class TaskbarUtilities
{
    static HasDeactivateTimedOut => A_TickCount - this.StartTime > 900

    static __New() => (this.IsInvisible := false, this.DeactivatedTaskbarY := A_ScreenHeight - 2)

    ; To make it less bothersome by deactivating the taskbar
    static ToggleDeactivateTimer()
    {
        static isEnabled := false
        SetTimer(Deactivate, (isEnabled := !isEnabled) ? 30 : 0)

        Deactivate() => WinActivate("ahk_class Progman")
    }

    static WaitDeactivate()
    {
        this.StartTime := A_TickCount, WinGetPos(, &currentTaskbarY,,, "ahk_class Shell_TrayWnd")

        while (currentTaskbarY != this.DeactivatedTaskbarY)
        {
            Sleep(10)
            WinGetPos(, &currentTaskbarY,,, "ahk_class Shell_TrayWnd")

            if (this.HasDeactivateTimedOut)
                break
        }

        this.ToggleDeactivateTimer()
    }

    ; To prevent anything except the user from reactivating the taskbar
    static MakeInvisible()
    {
        WinSetTransparent(0, "ahk_class Shell_TrayWnd")
        this.IsInvisible := true
        SetTimer(this._ShowOnHover := ObjBindMethod(this, "ShowOnHover"), 20)
        Hotkey("~LWin", (*) => this.Show())
    }

    static ShowOnHover()
    {
        MouseGetPos(, &currentCursorY)

        if (currentCursorY >= this.DeactivatedTaskbarY)
            this.Show()
    }

    static Show()
    {
        if (this.IsInvisible)
        {
            this.ToggleDeactivateTimer(), this.WaitDeactivate()
            WinSetTransparent("Off", "ahk_class Shell_TrayWnd"), SetTimer(this._ShowOnHover, 0), Hotkey("~LWin", (*) => this.Show(), "Off"), this.IsInvisible := false
        }
    }
}

/*
 * Buffering keyboard inputs to send later. if `shouldSendBufferedkeys` is false, it returns all the inputs that were being buffered.
 * [Unused feature] stop buffering keys but not sending them out. It returns all the buffered inputs as a string: bufferedkeys := BufferInputs()
 * @param {number} mode Toggle on/off
 * @param {number} shouldSendBufferedkeys Release buffered keys when it stops buffering keys
 * @returns {string} All the inputs that were being buffered
 */
BufferInputs(mode := false, shouldSendBufferedkeys := false)
{
    static ih := "", inputs := ""

    if (!mode && ih is InputHook)
    {
        ih.Stop()
        
        if (shouldSendBufferedkeys)
            Send(inputs)
        
        return inputs 
    }
    else
        inputs := ""

    ih                := InputHook("I1 L0 *")
    ih.NotifyNonText  := true
    ih.VisibleNonText := false
    ih.OnKeyDown      := OnKey.Bind(,,, "Down")
    ih.OnKeyUp        := OnKey.Bind(,,, "Up")
    ih.KeyOpt("{All}", "N S")
    ih.Start()

    OnKey(ih, VK, SC, UD) => (Critical(), inputs .= Format("{{1} {2}}", GetKeyName(Format("vk{1:x}sc{2:x}", VK, SC)), UD))
}

ClipSend(textToSend)
{
  clipPrevious := ClipboardAll()
  A_Clipboard := textToSend
  Send("{Ctrl down}")
  Sleep(100)
  WinActivate()
  ControlSend("v{Enter}")
  Send("{Ctrl up}")
  Sleep(250)
  A_Clipboard := clipPrevious
}

; Uses the INI file of WinSize2 to fix tabs outliner (should be used while it's still invisible and looks better than WinSize2 doing it)
MoveAndResize()
{
    section := IniRead(A_AppData "\MagraSoft\WinSize2.INI", "WinSize"), linesSplit := StrSplit(section, "`n")

    for (iteratedLine in linesSplit)
        if (InStr(iteratedLine, "Tabs Outliner"))
            lineSplit := StrSplit(iteratedLine, ""), tabsOutlinerInfo := [lineSplit[2], lineSplit[3], lineSplit[4], lineSplit[5]]

    WinRestore(), WinMove(tabsOutlinerInfo[1], tabsOutlinerInfo[2], tabsOutlinerInfo[3], tabsOutlinerInfo[4])
}

; This is necessary to stop interference from WinSize2 AHK scripts (e.g. tabs outliner not always being minimized could otherwise happen)
ToggleWinSize2()
{
    A_DetectHiddenWindows := true

    ; Pause/unpause when the main WinSize2 AHK script is running
    loop
    {
        ids := WinGetList("ahk_class AutoHotkey")

        for (iteratedId in ids)
            if (InStr(WinGetTitle(iteratedId), "WinSize2.EXE",, -1))
            {
                loop
                    try
                    {
                        ; The following is the same as the user having selected "Pause Script" from the tray menu (65306 = PAUSE, 65305 = SUSPEND)
                        SendMessage(0x0111, 65306,,, iteratedId,,,, 300)

                        return
                    }
                    catch (TimeoutError)
                        continue
            }

        Sleep(30)
    }
}

HookEvent(event, fnObj, pid := 0) => DllCall("SetWinEventHook", "UInt", event, "UInt", event, "Ptr", 0, "Ptr", CallbackCreate(fnObj), "UInt", pid, "UInt", 0, "UInt", 0)