# Windows API (Accessibility)
* [Event Constants](https://learn.microsoft.com/en-us/windows/win32/winauto/event-constants)  
* [SetWinEventHook function](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-setwineventhook)  
* [WinEventProc callback function](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nc-winuser-wineventproc)  
* [UnhookWinEvent function](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-unhookwinevent)

# Chrome Watcher (automatic).ahk
IMPORTANT: this AHK script expects Tabs Outliner to appear and uses this as the cue to stop the script. If you just want to see chrome event data without logging that of Tabs Outliner, then make sure to exit the script when you're done by using the tray icon (to stop the logger). Otherwise make sure that Tabs Outliner gets started automatically at chrome startup before using this script.

And if you don't want chrome event data of chrome windows that were already open, then ofcourse you should close all chrome windows (including Tabs Outliner) before using this script. When you start this script, chrome will start automatically and you'll get a logger.txt on your desktop with all the chrome/Tabs Outliner event data.

# Chrome Watcher (with hotkeys).ahk
When you start this AHK script, you can press `F1` to start chrome and you'll get a logger.txt on your desktop with all the chrome event data. But you will have to press it again to stop the data logging yourself. You can also press `F2` to close all the chrome windows by force. And you can press `F3` to stop the script.
