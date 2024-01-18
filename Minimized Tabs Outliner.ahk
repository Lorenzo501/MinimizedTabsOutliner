;for the one at startup of the PC it's a bit more risky to send input while a bunch of processess are being started, it waits for the user to log on at the very least to make it work
;but I could send input twice, that will probably work (probably not necessary though and to do it reliably it might need a delay before sending each duplicate)


;if mouse-click interference isn't as rare as I thought, then create a LButton hotkey that saves the cursor position when executed and have this hotkey disabled by default, and enabled on
;demand when temporarily necessary to buffer mouse clicks. so then when it's enabled, it'll save cursor positions of times when the user clicked while in the buffer state, then when the
;buffer state ends, you can iterate over the cursor positions and sending clicks with them (without moving the cursor), removing the ones from the collection that are used. the LButton
;hotkey should ofcourse not send clicks itself when used. and maybe the LButton Up hotkey needs to simply temporarily return. if this for some reason doesn't work then simply use BlockInput
;temporarily. And do ALWAYS/IN ANY CASE keep the WinActivate before each input being send (it keeps it more reliable in case windows appear out of nowhere)

;I only need BlockInput or w/e for the one that executes at startup of the PC there the user can actually interfere, b/c the others execute as soon as I click one of the icons in the
;taskbar so it's likely that I won't click something other than inside the chrome window that opens, and the ones that are invisible can't be clicked by the user.
;and the ones where keys are being send w/ SendInput, will cause user input to be postponed so I highly doubt that the user can interfere! even when it's not just one SendInput action


;the fast mode might improve things, but I don't fully understand it: CallbackCreate(Function, "Fast")


;I can make a new instance send a msg to the first instance to trigger something extra (if absolutely necessary, but I can likely always let the new instance do the extra thing itself)


;if (WinActive("ahk_exe explorer.exe") && !WinActive("ahk_class CabinetWClass")) ; is probably better than combining WinActive("ahk_class Progman") || WinActive("ahk_class Shell_TrayWnd")
;because there might be other classes that need to be detected as well, except the file explorer


;this is not great and doesn't always work (try no keydelay and sending lots of keys first, then consider a delay if sending lots of keys isn't making it reliable)
;temporary "BlockInput and AlwaysOnTop" not included
;A_KeyDelay := 500
;ControlSend("{End 2}{Esc}") ; works even when the window has been made hidden (w/ WinHide)


;perhaps this is even more thread-safe (although I doubt it's necessary)
;static isBeingMinimized
;if (!IsSet(isBeingMinimized) && (isBeingMinimized := true))


;a higher A_KeyDuration could be useful to make pasting with ControlSend more reliable? and if I were to use SendEvent (A_KeyDelayPlay & A_KeyDurationPlay contain the settings for SendPlay)


;MsgBox(FormatTime(A_Now, "HH : mm : ss")) ; RUNS BEFORE I'M EVEN LOGGED ON!^^
;startTime := A_TickCount
;Run("chrome.exe --start-maximized",,, &pid) ; doing this before the hooking results in some events being missed
;WinWait("ahk_pid " pid)
;MsgBox(A_TickCount - startTime " milliseconds have elapsed")
;DllCall("SetWinEventHook", "UInt", 32780, "UInt", 32780, "Ptr", 0, "Ptr", CallbackCreate(cb), "UInt", pid, "UInt", 0, "UInt", 0)
cb(hWinEventHook, Event, hWnd, *)
{
    Critical()
    static isNewTabChromeActive := true, isTabsOutlinerActive := true
    
    try
    {
        if (InStr(WinGetTitle(hWnd), "Google Chrome",, -1) && isNewTabChromeActive)
        {
            isNewTabChromeActive := false
            oldWinDelay := SetWinDelay(-1)
            WinSetTransparent(0, hWnd)
            A_WinDelay := oldWinDelay
            WinHide(hWnd)

            return
        }

        if (WinGetTitle(hWnd) != "_crx_eggkanocgddhmamlbiijnphhppkpkmkl")
            return
    }
    catch
    {
        return
    }

    if (isTabsOutlinerActive)
    {
        isTabsOutlinerActive := false
        oldWinDelay := SetWinDelay(-1)
        WinSetTransparent(0, hWnd)
        A_WinDelay := oldWinDelay

        WinHide(hWnd)
        DllCall("UnhookWinEvent", "Ptr", hWinEventHook)

        ;Thread("NoTimers")
        ;Thread("Priority", 1)

        ; To make ControlClick work (put it on the line above ControlClick?)
        ;ProcessWaitClose("LogonUI.exe")

        DetectHiddenWindows(true)
        A_WinDelay := -1
        WinWait("Tabs Outliner ahk_exe chrome.exe")
        A_WinDelay := oldWinDelay

        ; TRY AGAIN, WITH SILENT-LAUNCH (now includes controldelay -1) AND TRY SCROLLWHEEL
        ; this can be used to click on the bottom of the tabs outliner scrollbar
        ;WinGetClientPos(,, &tabsOutlinerWidth, &tabsOutlinerHeight)
        ;Send("{Shift down}")
        ;A_ControlDelay := -1
        ;ControlClick("x" tabsOutlinerWidth-1 " y" tabsOutlinerHeight-1,,,,, "NA")
        ;Send("{Shift up}")

        ;https://www.autohotkey.com/board/topic/24029-controlsend-controlclick-workaround-send-a-ctrldownleftmouse/page-2#entry156078
        ;https://www.autohotkey.com/boards/viewtopic.php?style=7&t=97971
        ;so these can't be used instead
        ;ControlSend("{Shift down}")
        ;ControlSend("{Shift up}")

        ;ControlClick(, hWnd,, "WD", 273, "NA")

        WinMinimize()
        WinClose("Google Chrome ahk_exe chrome.exe")
        DetectHiddenWindows(false)
        WinSetTransparent("Off")

        ; This needs to be delayed until all startup items are running, b/c too early caused it to try to fix the size/position of uTorrent for example, causing it to get shown at startup
        ; and that was bad b/c I had uTorrent set up to start as minimized. So apparently it didn't even get the chance to do that.. Similar to the issue it may cause w/ tabs outliner
        Run(RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run", "WinSize2"))
        
        ExitApp()
    }
}


;A_ControlDelay := -1 ; default is 20, could try 0 instead, or maybe above 20 is best b/c the CPU could be under load (this only affects ControlClick)

;WinSetTransparent(1)
;ControlClick(,,, "WheelUp", 12, "NA")
;WinSetTransparent(0)


;Not all applications obey a ClickCount higher than 1 for turning the mouse wheel. For those applications, use a loop to turn the wheel more than one notch as in this example, which turns
;it 5 notches:
/*Loop 5
    ControlClick Control, WinTitle, WinText, "WheelUp"*/


;maybe the lowest possible value to allow ControlClick to work? idk but this normally allows the window to be clickable by the user (can do 0 first and then 1 right before ControlClick)
;WinSetTransparent(1)


;REQUIRES UI ACCESS WHEN START MENU IS OPEN
;temporarily hiding the taskbar to get rid of all orange icons or if that doesn't happen, then hide until the Tabs Outliner hide-show code removes the individual orange icon
;WinHide("ahk_class Shell_TrayWnd")
;WinShow("ahk_class Shell_TrayWnd")


;#WinActivateForce might fix the orange icon but not always, so try the solution below with ̶S̶l̶e̶e̶p̶(̶1̶0̶0̶) Sleep(500) right above it if another window function was executed right before
;if this doesn't fix the orange icon, then try doing it after the user has logged on at the end of the cb function (or mix it together with the solution above this)
;SetWinDelay(-1)
;WinHide("Tabs Outliner ahk_exe chrome.exe")
;WinShow("Tabs Outliner ahk_exe chrome.exe")
;SetWinDelay(100)


; CONFIRMED WORKAROUND TO SETUP WINDOW THAT'S MOVED OUT OF VIEW (DON'T FORGET "DetectHiddenWindows"): HIDE > INVISIBLE > MAXIMIZE > HIDE > MINIMIZE > VISIBLE


; [gotta make sure that WinSize2 doesn't interfere with ControlClick nor minimization:]
; UNSAFE/INITIAL VERSION (this one doesn't make sure that it has been paused/unpaused)
; This is necessary to stop interference from WinSize2 AHK scripts (e.g. use this if tabs outliner isn't always being minimized, then I suspect it's b/c of WinSize2 interfering)
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
                ; The following is the same as the user having selected "Pause Script" from the tray menu (65306 = PAUSE, 65305 = SUSPEND)
                PostMessage(0x0111, 65306,,, iteratedId)

                break 2
            }

        Sleep(30)
    }
}

;the next thing is probably not necessary, b/c I can just use SendMessage with TimeoutError to bruteforce the toggle (very reliable) and then there's no need to edit WinSize2 source,
;and providing the change in the EXE but yeah I'm already gonna provide the EXE but it's better to keep most stuff in my own script. if u use PostMessage instead of SendMessage to pause
;script, then u need to add Sleep(10) before SendMsg(0x5555, 69)

;convert to AHKv1 and then put this in the target script:
;OnMessage(0x5555, (wParam, *) => (wParam = 69 ? A_IsPaused : ""))

;send pause message with this function:
PauseScript(targetScriptTitle)
{
    DetectHiddenWindows(true)

    if (!WinExist(targetScriptTitle))
        return TrayTip("Target Script Not Found")

    SendMessage(0x0111, 65306)

    return "Target Script " (SendMessage(0x5555, 69) ? "Is Paused" : "Is Not Paused")
}

;version 2
PauseScript(targetScriptTitle)
{
    DetectHiddenWindows(true)
    
    if (!WinExist(targetScriptTitle))
        return TrayTip("Target Script Not Found")

    try SendMsg(0x0111, 65306)

    try return SendMsg(0x5555, 69) ? "Is Paused" : "Is Not Paused"
    return "SendMessage Failed"

    SendMsg(msg, wParam := 0, lParam := 0, timeout := 500) => SendMessage(msg, wParam, lParam,,,,,, timeout)
}


;SetKeyDelay():
;Every newly launched thread (such as a hotkey, custom menu item, or timed subroutine) starts off fresh with the default setting for this function. That default may be changed by using this
;function during script startup
;For Send/SendEvent mode, a delay of 0 internally executes a Sleep(0), which yields the remainder of the script's timeslice to any other process that may need it. If there is none, Sleep(0)
;will not sleep at all. By contrast, a delay of -1 will never sleep. For better reliability, 0 is recommended as an alternative to -1.
;When the delay is set to -1, a script's process-priority becomes an important factor in how fast it can send keystrokes when using the traditional SendEvent mode. To raise a script's
;priority, use ProcessSetPriority "High". Although this typically causes keystrokes to be sent faster than the active window can process them, the system automatically buffers them.
;Buffered keystrokes continue to arrive in the target window after the Send function completes (even if the window is no longer active). This is usually harmless because any subsequent
;keystrokes sent to the same window get queued up behind the ones already in the buffer

;AutoHotkey's update interval is 16ms, so using 10ms in code will make it happen at each update, making it 20ms would probably become 2x16=32ms, so each second update then
;Specify -1 for no delay at all or 0 for the smallest possible delay?

;in AHK scripts you can use this if it needs priority above basically everything else (overkill for most situations):
;ProcessSetPriority("High")
;if you add an AHK script as a task to task scheduler, you might want to export the task & then change the XML default priority from value: 7 (below normal) to: 5 (normal), then import it.
;no need to set it to normal in the AHK script itself, because it's normal by default (programs ran by task scheduler sometimes need different priorities but usually below normal is fine).
;don't set any other priority in task scheduler for AHK scripts, b/c those you should set in the AHK scripts directly (for when you open the file directly plus any other situation)
;for non-AHK tasks in task scheduler it could make a lot more sense, so you might want this:
;Task Priority	Priority Category
;0		Real-time
;1		High
;2-3		Above normal
;4-6		Normal
;7-8		Below normal
;9-10		Idle


AHK is not case-sensitive, so:
class EXAMPLE {
}
instance := example()
MsgBox(Type(instance))

Will show:
EXAMPLE

But this won't work, b/c the variable name is already used by the class name:
class EXAMPLE {
}
example := EXAMPLE()
MsgBox(Type(example))

Therefore you'd have to use hungarian notation, like an underscore to do it right:
class Example {
}
_example := Example()
MsgBox(Type(_example))


UI Access allows accessible-level interaction from applications running different integrity levels while administrative application have access to system-level resources.
UI Access is as insecure as an elevated process with the huge caveat that doesn't have access to system-level assets making harder to vertical level attacks to affect
Is harder to an escalation of privileges
https://learn.microsoft.com/en-us/windows/security/threat-protection/security-policy-settings/user-account-control-allow-uiaccess-applications-to-prompt-for-elevation-without-using-the-secure-desktop
And the why is harder:
https://learn.microsoft.com/en-us/windows/security/threat-protection/security-policy-settings/user-account-control-only-elevate-uiaccess-applications-that-are-installed-in-secure-locations
The requirements are tailored to make it so, only applications installed AND with the proper configuration in the manifest (plus a verified signature) are able to bypass the UIPI


; if (GetUrl(hWnd) = "chrome://newtab")
; if (GetUrl(hWnd) = "chrome://newtab/")
; if (GetUrl(hWnd) = "chrome://new-tab-page")
; if (GetUrl(hWnd) = "chrome://new-tab-page/")

; Version: 2023.05.11.1
; https://gist.github.com/7cce378c9dfdaf733cb3ca6df345b140

GetUrl(WinTitle*) {
    active := WinExist("A")
    if !(hWnd := WinExist(WinTitle*))
        return
    objId := -4
    wClass := WinGetClass()
    if (wClass ~= "Chrome") {
        appPid := WinGetPID()
        hWnd := WinExist("ahk_pid" appPid)
        if (active != hWnd)
            objId := 0
    }
    oAcc := Acc_ObjectFromWindow(hWnd, objId)
    if (wClass ~= "Chrome") {
        try {
            SendMessage 0x003D, 0, 1, "Chrome_RenderWidgetHostHWND1"
            oAcc.accName(0)
        }
    }
    if (oAcc := GetUrl_Recurse(oAcc))
        return oAcc.accValue(0)
}

GetUrl_Recurse(oAcc) {
    if (ComObjType(oAcc, "Name") != "IAccessible")
        return
    if (oAcc.accValue(0) ~= "^[\w-]+:")
        return oAcc
    for _, accChild in Acc_Children(oAcc) {
        oAcc := GetUrl_Recurse(accChild)
        if (IsObject(oAcc))
            return oAcc
    }
}

/********** proper input tooltip **********/

;Persistent()
;HookAllKeys()

HookAllKeys()
{
    static inputs     := ""
    ih                := InputHook("I1 L0 *")
    ih.NotifyNonText  := true
    ih.VisibleNonText := false
    ih.OnKeyDown      := OnKey.Bind(,,, "Down")
    ih.OnKeyUp        := OnKey.Bind(,,, "Up")
    ih.KeyOpt("{All}", "N S")
    ih.Start()
    
    OnKey(ih, VK, SC, UD) => (
        Critical(),
        ToolTip(inputs .= Format("{{1} {2}}", GetKeyName(Format("vk{:x}sc{:x}", VK, SC)), UD))
    )

;Change the callback function OnKey to this, then it will just send the key u pressed itself
;OnKey(ih, VK, SC, UD) => Send(Format("{Blind}{{1} {2}}", GetKeyName(Format("vk{:x}sc{:x}", VK, SC)), UD))
}

/********** TRASH: input tooltip 2, release & repress **********/

;Func1()
Func1()
{
loop
{
    loop (0xFF) 
    {
        static input := ""
        key := Format("VK{:02X}", A_Index)

        if (GetKeyState(key))
            Tooltip(input .= key)
    }
}
}



; Use it to release all currently pressed keys, do a hotkey action, and then repress the keys:
ReleaseKeys()
{
    releasedKeys := [], str := ""

    loop (0xFF)
    {
        key := Format("VK{:02X}", A_Index)

        if (GetKeyState(key))
        {
            str .= "{" key " Up}"
            releasedKeys.Push(key)
        }
    }

    Send(str)
    return releasedKeys
}

RepressKeys(keys)
{
    str := ""

    for (key in keys)
    {
        if (GetKeyState(key, "P"))
            str .= "{" key " Down}"
    }

    Send(str)
}

/********** TRASH: compact buffer input **********/

/*text := ""

loop (226)
{
    iteratedKey := GetKeyName(Format("VK{1:02X}", A_Index))

    if (iteratedKey)
        text .= iteratedKey " "
}

MsgBox text

; BUFFERING INPUT WORKS (you do lose key modifiers and key down/up status, which is what makes selecting text w/ cursor works)
loop (226)
    Hotkey("$" Format("VK{1:02X}", A_Index), (*) => Send("{" SubStr(A_ThisHotkey, 2) "}"))*/

    ; BUT NOT LIKE THIS (idk how this makes sense but whatever, I got a more reliable way that allows you to keep all key functionality)
    /*if (key := Format("VK{1:02X}", A_Index) != "LButton")
        Hotkey("$" key, (*) => Send("{" SubStr(A_ThisHotkey, 2) "}"))*/

/*F1::
{
Critical
Tooltip("buffering input")
startTime := A_TickCount

while (A_TickCount - startTime < 5000)
    continue

Tooltip()
}

; This also doesn't allow text to be selected properly while mouse input is buffered..
$LButton::Send("{LButton Down}")
$LButton Up::Send("{LButton Up}")*/

/********** TRASH: I've patched WinSize2.ahk in a more simple way (keeping this in case if I ever wanna implement the patch in my own script or need to do something differently) **********/

/* BRAINSTORM SESSION *
** * * * * * * * * * *
** ISSUE: This will cause the WinSize2 unpause at the end to affect (in my case) uTorrent, making it become activated/unminimized and its pos/size being fixed unintentionally
** HACKY SOLUTION: First doing WinActive("A") to see if there's anything active, in which case the issue mentioned above will happen, so then do the following:
** Find all minimized apps of WinSize2 INI that exist after userinit.exe closes, right before unpausing WinSize2, and then make those transparent,
** unpause WinSize2, set timer of 5sec and then minimize them again in case WinSize2 has unminimized them and whatnot, and then just make them visible
** NICE SOLUTION: use code from WinSize2Turbo, e.g. the callback to see if WinSize2 has finished doing something, might work like a charm, using a timeout of 500ms b/c it should be done
** by then: 10ms custom interval in WinSize2 settings + max approx 150ms for each of these two actions: resize and move, WinSize2 checks all windows at once, so I bet it's fine this way.
** I could leave a note in the initial commit to multiply the 2-action timeout by the amount of minimized windows that WinSize2 can affect at that moment, add the base timeout 200ms on top.
** The 500ms timeout is made up of the 2-action timeout: 150ms+150ms=300ms and the base timeout: 10ms custom interval (200ms interval for those who kept the default) in WinSize2 settings.
** If the timeout is reached then WinSize2 didn't affect it ̶a̶n̶d̶ ̶t̶h̶e̶ ̶u̶s̶e̶r̶ ̶m̶i̶g̶h̶t̶'̶v̶e̶ ̶u̶n̶m̶i̶n̶i̶m̶i̶z̶e̶d̶ ̶i̶t (np, then it'd get fixed), so after the timeout the windows have to become visible again
**
** Can also save the minimized windows, then when the event watcher notices a window has become (unminimized?) resized/repositioned then start a timeout for that specific window and
** in that time it can do the other resize/reposition action, and if it doesn't, then the user has unminimized the window itself....... NOPE?: even if the user unminimizes it, then WinSize2
** would DEFINITELY fix it... ̶s̶o̶ ̶i̶t̶ ̶d̶o̶e̶s̶n̶'̶t̶ ̶m̶a̶t̶t̶e̶r̶/̶d̶o̶e̶s̶n̶'̶t̶ ̶h̶a̶v̶e̶ ̶t̶o̶  which will be seen by the event watcher as the 2nd event (resize/reposition), or 150ms extra as a timeout..hmmmm, it
** DOESN'T HAVE TO USE A TIMEOUT AFTERWARDS IF THE WINDOW GETS UNMINIMIZED BY THE USER (or after the first resize/reposition action happened), B/C THE WINDOW WILL DEFINITELY GET FIXED THEN.
** should have a timeout beforehand in case it doesn't get affected by WinSize2 unintentionally or unminimized by the user (the script HAS to ExitApp), or maybe start a timer at the end of
** the DevTools cb, which first makes all invisible windows that remain, visible again and then uses ExitApp(). I can probably incorporate this fix in the patched WinSize2 to make that work
** properly (there is a Patched WinSize2 folder in the AutoHotkey folder), or if it can't be done then just use it in this script (Minimized Tabs Outliner.ahk) and use the patched WinSize2
** alongside it, because that one should then work fine as long as I have fixed the issue somewhere
*/
; Early attempt to start chrome normally (otherwise trying again later in case Tabs Outliner does exist then)
;CODE OMITTED

;Attempt #2 like described earlier
;in WinSize2.ahk somewhere before it tries to fix stuff
;maybe a delay is necessary first to hold off until the ToggleWinSize2 unpause (idk if it will otherwise execute too early, at the start of my script when running WinSize2, which is bad)
;find the minimized windows, make em invisible
;setup an event watcher
;then let it fix what it want,
;and make unminimized windows minimized and visible again

;the WinSize2 workarounds in my own script are gonna be kept in the next commit but then taken out in the one after that, just in case (so I can see where everything belonged in the code)

/********** TRASH: old target+start_dir **********/

;DEFAULT TARGET+START_DIR OF CHROME
;"C:\Program Files\Google\Chrome\Application\chrome.exe"
;"C:\Program Files\Google\Chrome\Application"

;DEFAULT TARGET OF TABS OUTLINER:
;"C:\Program Files\Google\Chrome\Application\chrome.exe" --profile-directory=Default --app-id=eggkanocgddhmamlbiijnphhppkpkmkl

;PREVIOUS TARGET+START_DIR OF TABS OUTLINER
;"C:\Program Files\Google\Chrome\Application\chrome.exe" --silent-launch
;"C:\Program Files\Google\Chrome\Application"

/********** TRASH: problematic INI stuff **********/

/*; This will prevent WinSize2 from affecting other windows
FileCopy(A_AppData "\MagraSoft\WinSize2.INI", A_Temp, 1)
section := IniRead(A_AppData "\MagraSoft\WinSize2.INI", "WinSize")
linesSplit := StrSplit(section, "`n")
for (iteratedLine in linesSplit)
    if (InStr(iteratedLine, "Tabs Outliner"))
        IniWrite("AWNr_1=" StrSplit(iteratedLine, "=")[2], A_AppData "\MagraSoft\WinSize2.INI", "WinSize")*/


/*"HandleDevToolsEvent" CODE OMITTED
            HookEvent(EVENT_OBJECT_LOCATIONCHANGE, HandleFinalPhaseTabsOutlinerEvent, WinGetPID("Tabs Outliner ahk_exe chrome.exe"))

            ; Letting WinSize2 temporarily run to fix the size and position of Tabs Outliner while it's invisible
            ToggleWinSize2()
        }
    }

    HandleFinalPhaseTabsOutlinerEvent(hWinEventHook, event, hWnd, *)
    {
        ; The first one is WinSize2 resizing Tabs Outliner and second one is WinSize2 repositioning Tabs Outliner
        static matchCounter := 0

        try if (WinGetTitle(hWnd) = "Tabs Outliner" && ++matchCounter = 2)
        {
            ToggleWinSize2() ; Temporarily pausing WinSize2 to prevent interference with the code below
            FileCopy(A_Temp "\WinSize2.INI", A_AppData "\MagraSoft", 1)
            DllCall("UnhookWinEvent", "Ptr", hWinEventHook)
CODE OMITTED*/

/********** TRASH: visibility check that's likely not gonna be used **********/

;if I want to check if a window is visible or invisible,
;then use WinGetTransparent or maybe this (usage example: WinVisible("ahk_class Shell_TrayWnd")):

WinVisible(winTitle)
{
    style := WinGetStyle(winTitle)
    result := style & 0x10000000 ; 0x10000000 is WS_VISIBLE

    return result != 0 ? true : false
}

/********** TRASH: Embedded INI.ahk that's likely not gonna be used **********/

#Requires AutoHotkey 2.0
;so you don't need to read/write to the registry

F1::GetFeatureStatus("Feature1")
F2::GetFeatureStatus("Feature2")
F3::IniWrite("Feature1=test123", A_ScriptFullPath, "SavedVariables2")

GetFeatureStatus(featureName)
{
    section := IniRead(A_ScriptFullPath, "SavedVariables")
    linesSplit := StrSplit(section, "`n")

    for (line in linesSplit)
        if (InStr(line, featureName))
            if (StrSplit(line, "=")[2])
                MsgBox(featureName " is enabled")
            else
                MsgBox(featureName " is disabled")
}

/*
[SavedVariables]
Feature1=1
Feature2=0
[SavedVariables2]
Feature1=test123
*/