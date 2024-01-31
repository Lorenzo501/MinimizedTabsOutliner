;@Ahk2Exe-UpdateManifest 0,,, 1
#Requires AutoHotkey 2.0
#SingleInstance Off

; Early attempt to start chrome normally (otherwise trying again later in case Tabs Outliner does exist then)
if (A_Args.length > 0 && A_Args[1] = "--duo" && WinExist("Tabs Outliner ahk_exe chrome.exe"))
{
    Run("chrome.exe --start-maximized")
    ExitApp()
}

; To make certain things work even when an admin window becomes active
if (!A_IsCompiled && !InStr(A_AhkPath, "_UIA.exe"))
{
    A_DetectHiddenWindows := true

    ; Gets skipped when the user executes the script manually from the taskbar before or while the startup instance executes
    if (WinGetList(A_ScriptFullPath " ahk_class AutoHotkey").Length = 1)
        Run("*UIAccess " A_ScriptFullPath (A_Args.length > 0 ? " " A_Args[1] : ""))
    
    ExitApp()
}
else if (A_IsCompiled)
{
    A_DetectHiddenWindows := true

    if (WinGetList(A_ScriptFullPath " ahk_class AutoHotkey").Length > 1)
        ExitApp()
}

#NoTrayIcon
Persistent()
interfaceImprovementsJS := "
(
    arrayHtml = document.getElementsByClassName(`"mainViewMessage`"); arrayHtml[0].parentNode.removeChild(arrayHtml[0]);
    arrayHtml = document.getElementsByClassName(`"winNTASC`"); arrayHtml[arrayHtml.length - 1].replaceChildren();
    window.scrollTo(0, document.body.scrollHeight - window.innerHeight - 1200)
)"
A_KeyDelay := -1 ; For pasting with ControlSend
A_WinDelay := -1
EVENT_OBJECT_SHOW := 0x8002
EVENT_OBJECT_NAMECHANGE := 0x800C

; The first scope executes at startup (using no flag will trigger this expanded single mode)
if (A_Args.length = 0)
{
    A_CoordModeMouse := "Screen"
    EVENT_OBJECT_LOCATIONCHANGE := 0x800B

    WinWait("ahk_class Progman") ; Gotta wait until it exists before activating it to deactivate the taskbar
    TaskbarUtilities.ToggleDeactivateTimer()

    ; This might be too early to do it, possibly causing software that runs minimized at startup to become unminimized due to WinSize2 affecting it. But then again, it might also be
    ; necessary for software that runs unminimized at startup to be fixed by WinSize2. I have chosen to run WinSize2 as late as possible for my own situation. Feel free to install AHKv2,
    ; uncomment these 3 lines and comment-out the identical Run line, and its if-else statement except the ToggleWinSize2() which it contains, then recompile this script or use the old
    ; "Minimized Tabs Outliner.xml" file of its initial commit in the repo. That one can be used to start the .ahk file instead of the .exe file (the release runs .exe w/ Task Scheduler)
    ;Run(RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run", "WinSize2"))
    ;Sleep(200)
    ;ToggleWinSize2()

    TaskbarUtilities.WaitDeactivate()

    if (!TaskbarUtilities.HasDeactivateTimedOut)
        TaskbarUtilities.MakeInvisible()

    windowToActivate := WinExist("A") ; The currently active window gets reactivated in the end
    BufferInputs(true) ; Start buffering keys
    HookEvent(EVENT_OBJECT_NAMECHANGE, HandleTabsOutlinerEvent)
}
else if (A_Args[1] = "--single")
{
    ToggleWinSize2()
    BufferInputs(true) ; Start buffering keys
    HookEvent(EVENT_OBJECT_NAMECHANGE, HandleTabsOutlinerEvent)
}
else if (A_Args[1] = "--duo")
{
    if (WinExist("Tabs Outliner ahk_exe chrome.exe"))
    {
        Run("chrome.exe --start-maximized")
        ExitApp()
    }
    else
    {
        ToggleWinSize2()
        BufferInputs(true) ; Start buffering keys
        HookEvent(EVENT_OBJECT_NAMECHANGE, HandleTabsOutlinerEvent)
        Run("chrome.exe --start-maximized")
    }
}
else
    throw ValueError("Parameter invalid, use either --single or --duo (unset parameter is expanded single`nmode to be executed at startup)", -1, A_Args[1])

if (A_Args.length = 0 || A_Args[1] = "--single")
{
    if (ProcessExist("chrome.exe"))
    {
        HookEvent(EVENT_OBJECT_NAMECHANGE, HandleDisposableNewTabEvent)
        Run("chrome.exe --new-window")

        HandleDisposableNewTabEvent(hWinEventHook, event, hWnd, *)
        {
            static isBeingUsed := false

            try
                if (InStr(WinGetTitle(hWnd), "Google Chrome",, -1) && !isBeingUsed)
                {
                    isBeingUsed := true
                    WinSetTransparent(0, hWnd)
                    DllCall("UnhookWinEvent", "Ptr", hWinEventHook)
                    DisposableNewTabChrome.Id := hWnd
                    Sleep(10)
                    WinHide(hWnd)

                    while (!WinExist("Tabs Outliner ahk_exe chrome.exe"))
                        ControlSend("!x", hWnd)
                }
        }
    }
    else
        Run("chrome.exe --silent-launch --start-maximized")
}

;********** LIBRARY **********

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
            WinWait("Tabs Outliner ahk_exe chrome.exe")
            ProcessWaitClose("LogonUI.exe")
            WinActivate()
            Send("{End 2}{Esc}")
            HookEvent(EVENT_OBJECT_NAMECHANGE, HandleDevToolsEvent, WinGetPID())
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
        static isBeingMadeTransparent := false

        try
            if (WinGetTitle(hWnd) = "DevToolsApp" && !isBeingMadeTransparent)
            {
                isBeingMadeTransparent := true
                WinSetTransparent(0, hWnd)
                DllCall("UnhookWinEvent", "Ptr", hWinEventHook)
                WinExist(hWnd)
                Sleep(500)
                WinHide()
                Send("^``")
                Sleep(500)
                shouldDetectHiddenWindowsPrevious := DetectHiddenWindows(true)
                ClipSend(interfaceImprovementsJS)
                Sleep(500)
                WinClose()

                if (DisposableNewTabChrome.Id)
                    WinClose(DisposableNewTabChrome.Id)

                A_DetectHiddenWindows := shouldDetectHiddenWindowsPrevious
                tabsOutlinerId := WinExist("Tabs Outliner ahk_exe chrome.exe")
                MoveAndResize()
                WinMinimize()
                WinSetTransparent("Off")
                IID_ITaskbarList := "{56FDF342-FD6D-11d0-958A-006097C9A090}"
                CLSID_TaskbarList := "{56FDF344-FD6D-11d0-958A-006097C9A090}"
                tbl := ComObject(CLSID_TaskbarList, IID_ITaskbarList) ; Creates the TaskbarList object
                ComCall(3, tbl) ; This is tbl.HrInit(), which initializes the taskbar list object
                ComCall(5, tbl, "Ptr", tabsOutlinerId) ; This is tbl.DeleteTab(tabsOutlinerId), which deletes a tab from the TaskbarList
                ComCall(4, tbl, "Ptr", tabsOutlinerId) ; This is tbl.AddTab(tabsOutlinerId), which adds a tab to the TaskbarList
                TaskbarUtilities.Show()
                ProcessWaitClose("userinit.exe") ; At this point all startup software is running
                Sleep(100)

                if (IsSet(windowToActivate))
                    try WinActivate(windowToActivate)

                Sleep(200)
                BufferInputs(, true) ; Stop buffering keys and sending them out

                if (A_Args.length = 0)
                    Run(RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run", "WinSize2"))
                else
                    ToggleWinSize2() ; Unpausing WinSize2 now that it can no longer misbehave

                ExitApp()
            }
    }
}

class DisposableNewTabChrome
{
    static __New() => this.Id := 0
}

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

; Uses the INI file of WinSize2 to fix Tabs Outliner (should be used while it's still invisible and looks better than WinSize2 doing it)
MoveAndResize()
{
    section := IniRead(A_AppData "\MagraSoft\WinSize2.INI", "WinSize"), linesSplit := StrSplit(section, "`n")

    for (iteratedLine in linesSplit)
        if (InStr(iteratedLine, "Tabs Outliner"))
            lineSplit := StrSplit(iteratedLine, ""), tabsOutlinerInfo := [lineSplit[2], lineSplit[3], lineSplit[4], lineSplit[5]]

    WinRestore(), WinMove(tabsOutlinerInfo[1], tabsOutlinerInfo[2], tabsOutlinerInfo[3], tabsOutlinerInfo[4])
}

; This is necessary to stop interference from WinSize2 AHK scripts (e.g. Tabs Outliner not always being minimized could otherwise happen)
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