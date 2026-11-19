# Installs Claude Code - Auto Approver for the current user: copies the script, starts it at sign-in,
# and starts it now. Run: powershell -ExecutionPolicy Bypass -File install.ps1
$ErrorActionPreference = 'Stop'
$dest = Join-Path $env:LOCALAPPDATA 'ClaudeCodeAutoApprover'
New-Item -ItemType Directory -Force -Path $dest | Out-Null
Copy-Item (Join-Path $PSScriptRoot 'auto-approver.ps1') $dest -Force
$script = Join-Path $dest 'auto-approver.ps1'
$psArgs = "-NoProfile -STA -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$script`""

$lnk = Join-Path ([Environment]::GetFolderPath('Startup')) 'Claude Code - Auto Approver.lnk'
$shortcut = (New-Object -ComObject WScript.Shell).CreateShortcut($lnk)
$shortcut.TargetPath  = (Get-Command powershell.exe).Source
$shortcut.Arguments   = $psArgs
$shortcut.WindowStyle = 7   # minimized: no console flashes at sign-in
$shortcut.Description = 'Claude Code - Auto Approver'
$shortcut.Save()

# Replace a running copy with the new one.
Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" |
    Where-Object { $_.CommandLine -like '*auto-approver.ps1*' } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force }
Start-Process powershell.exe -ArgumentList $psArgs -WindowStyle Hidden

Write-Host "Claude Code - Auto Approver installed in $dest and started; it starts at every sign-in."
Write-Host "Log: $dest\ClaudeCodeAutoApprover.log"
