# Stops Claude Code - Auto Approver and removes it and its sign-in shortcut.
Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" |
    Where-Object { $_.CommandLine -like '*auto-approver.ps1*' } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force }
Remove-Item (Join-Path ([Environment]::GetFolderPath('Startup')) 'Claude Code - Auto Approver.lnk') -ErrorAction SilentlyContinue
Remove-Item (Join-Path $env:LOCALAPPDATA 'ClaudeCodeAutoApprover') -Recurse -Force -ErrorAction SilentlyContinue
Write-Host 'Claude Code - Auto Approver removed.'
