# Minimized Tabs Outliner (wrapped .ps1).bat
IMPORTANT: the following title in the script must be made identical to the one that you see in the tiny preview window, when your cursor is on the chrome icon in the taskbar with the 'new tab' chrome window in view: `Nieuw tabblad - Google Chrome` (Dutch language).

The powershell wrapper/batch-powershell hybrid makes using the powershell script as easy as with any other executable file. Easily run the embedded powershell script by double-clicking the .bat file. It also makes it super easy when you create a shortcut of it, which I recommended you do to make it run minimized as well. Simply right-click the .bat file and then click on "Create shortcut". These actions won't work with non-wrapped .ps1 files and would've required a more difficult workflow, which isn't particularly straightforward for end users. After you have made the shortcut, you have to make it run at startup by pressing the `WinKey + R`, then copy and paste the following text into the **Run** dialog box: `shell:startup`. Then the startup folder will open in which the shortcut has to be placed. After this you're done.

You can also run the .bat file completely hidden at startup by using the following AutoHotKey script instead of a shortcut, and ofcourse placed in the startup folder (get the latest AutoHotKey version):
```
#Requires AutoHotkey 2.0.5
#NoTrayIcon
Run "C:\Users\XXX\Documents\Minimized Tabs Outliner (wrapped .ps1).bat",,"Hide"
```

When you double-click a non-wrapped .ps1 file, it will open in notepad, the same thing happens when you create a shortcut of it like described before. To create a proper shortcut of a non-wrapped .ps1 file, you would have to open the shortcut wizard and include some text in front of the .ps1 file location to run it with powershell when the shortcut gets double-clicked, and even more text to bypass the execution policy, so that it works on all devices.
