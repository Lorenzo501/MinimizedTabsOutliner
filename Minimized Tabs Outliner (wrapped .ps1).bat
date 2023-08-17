<# :: Batch Script Section

@powershell Invoke-Expression $([System.IO.File]::ReadAllText('%~f0'))
@exit /b

#>
# PowerShell Script Section

# waiting on the user to log on so that WinSize2 becomes operational
while ($true)
{
    $LogonUI = Get-Process | where { $_.name -eq "LogonUI" }
    if (!$LogonUI) { break }
    Start-Sleep -Milliseconds 50
}

# starting chrome maximized and don't forget to make the chrome shortcut do the same, otherwise it won't always be maximized and WinSize2 fixes position and size of tabs outliner
start chrome --start-maximized

while ($true)
{
    $TabsOutliner = Get-Process | where { $_.name -eq "chrome" -and $_.mainwindowtitle -eq "Tabs Outliner" }
    if ($TabsOutliner) { break }
    Start-Sleep -Milliseconds 50
}

# giving the main chrome window focus by doing ALT+TAB to switch back to the previous window
$wsh = New-Object -ComObject Wscript.Shell
$wsh.Sendkeys("%{TAB}")

while ($true)
{
    $NewTabChrome = Get-Process | where { $_.name -eq "chrome" -and $_.mainwindowtitle -eq "Nieuw tabblad - Google Chrome" }
    if ($NewTabChrome) { break }
    Start-Sleep -Milliseconds 50
}

# this only works when this chrome window has focus (which it now should have)
$NewTabChrome.CloseMainWindow() > $null

$x = New-Object -ComObject Shell.Application
$x.minimizeall()
