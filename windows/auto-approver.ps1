<#
  Claude Code - Auto Approver for Windows

  Accepts every Claude Code permission prompt in the Claude desktop app by invoking its
  "Allow once" button through UI Automation, in the app's window or on its toast.

  Labels to press: %APPDATA%\ClaudeCodeAutoApprover\labels.txt (one per line), else "Allow once".
  Log:             %LOCALAPPDATA%\ClaudeCodeAutoApprover\ClaudeCodeAutoApprover.log
#>
Add-Type -AssemblyName UIAutomationClient, UIAutomationTypes, System.Windows.Forms, System.Drawing

$dataDir    = Join-Path $env:APPDATA 'ClaudeCodeAutoApprover'
$logDir     = Join-Path $env:LOCALAPPDATA 'ClaudeCodeAutoApprover'
$labelsPath = Join-Path $dataDir 'labels.txt'
$logPath    = Join-Path $logDir 'ClaudeCodeAutoApprover.log'
New-Item -ItemType Directory -Force -Path $dataDir, $logDir | Out-Null

# One instance only: a second launch exits.
$created = $false
$mutex = New-Object System.Threading.Mutex($true, 'Local\ClaudeCodeAutoApprover', [ref]$created)
if (-not $created) { exit }

# The log restarts past 1 MB.
if ((Test-Path $logPath) -and (Get-Item $logPath).Length -gt 1MB) { Remove-Item $logPath }
function Log([string]$s) {
    Add-Content -Path $logPath -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $s" -Encoding UTF8
}

# Labels are compared as their words, so shortcut glyphs and digits beside them do not matter.
function Words([string]$s) {
    (($s.ToLowerInvariant() -split '[^\p{L}]+') | Where-Object { $_ }) -join ' '
}

# One-time approvals only: "Always allow" writes a permanent rule, and a bare "Allow" also
# labels the Allow/Deny choice of a rule in the app's settings.
function Get-Wanted {
    $listed = @()
    if (Test-Path $labelsPath) {
        $listed = @(Get-Content $labelsPath -Encoding UTF8 |
            ForEach-Object { $_.Trim() } | Where-Object { $_ -and -not $_.StartsWith('#') })
    }
    if ($listed.Count -eq 0) { $listed = @('Allow once') }
    $set = New-Object 'System.Collections.Generic.HashSet[string]'
    foreach ($l in $listed) { [void]$set.Add((Words $l)) }
    return ,$set
}

$AE          = [System.Windows.Automation.AutomationElement]
$ButtonType  = [System.Windows.Automation.ControlType]::Button
$isButton    = New-Object System.Windows.Automation.PropertyCondition($AE::ControlTypeProperty, $ButtonType)
$anything    = [System.Windows.Automation.Condition]::TrueCondition
$Children    = [System.Windows.Automation.TreeScope]::Children
$Descendants = [System.Windows.Automation.TreeScope]::Descendants

function Invoke-Element($el) {
    $p = $null
    if ($el.TryGetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern, [ref]$p)) {
        $p.Invoke()
        return $true
    }
    return $false
}

# Top-level windows owned by the named processes.
function Get-Windows([string[]]$names) {
    $ids = @(Get-Process -Name $names -ErrorAction SilentlyContinue | ForEach-Object { $_.Id })
    if ($ids.Count -eq 0) { return @() }
    @($AE::RootElement.FindAll($Children, $anything) | Where-Object { $ids -contains $_.Current.ProcessId })
}

$known = New-Object 'System.Collections.Generic.HashSet[string]'

# The dialog in the Claude window: present for the session on screen.
function Press-InWindow($wanted) {
    $fresh = @()
    try {
        foreach ($w in Get-Windows 'claude') {
            foreach ($b in $w.FindAll($Descendants, $isButton)) {
                $name = $b.Current.Name
                if ($wanted.Contains((Words $name))) {
                    if (Invoke-Element $b) { return $name }
                    Log "❌ Could not press `"$name`""
                } elseif ($name -and $name.Length -le 30 -and $known.Add($name)) {
                    $fresh += $name
                }
            }
        }
    } finally {
        # Short labels new to this run are logged: a dialog's buttons show up here.
        if ($fresh.Count -gt 0) { Log "🆕 New buttons: $($fresh -join ' · ')" }
        if ($known.Count -gt 3000) { $known.Clear() }
    }
    return $null
}

$steps = @{}   # toast text -> fallback already tried

# A toast from the Claude app ("Allow Claude to run …?"): a session not on screen asks here.
function Press-OnToast($wanted) {
    foreach ($w in Get-Windows 'ShellExperienceHost') {
        $all  = @($w.FindAll($Descendants, $anything))
        $text = ($all | ForEach-Object { $_.Current.Name }) -join ' '
        if ($text -notmatch 'Allow Claude to') { continue }
        $key = $text.Substring(0, [Math]::Min(200, $text.Length))
        if (-not $steps.ContainsKey($key)) {
            Log "🔔 Permission notification: $($text.Substring(0, [Math]::Min(160, $text.Length)))"
            $steps[$key] = 0
        }
        foreach ($b in $all) {
            if ($b.Current.ControlType -eq $ButtonType -and $wanted.Contains((Words $b.Current.Name))) {
                if (Invoke-Element $b) { return "$($b.Current.Name) (notifica)" }
            }
        }
        # No action offered: open the session from the toast, where the dialog in the
        # window is answered on the next tick.
        if ($steps[$key] -eq 0) {
            $steps[$key] = 1
            $buttons = ($all | Where-Object { $_.Current.ControlType -eq $ButtonType } |
                ForEach-Object { $_.Current.Name }) -join ' · '
            $opened = $false
            foreach ($el in $all) {
                if ($el.Current.Name -match 'Allow Claude to' -and (Invoke-Element $el)) { $opened = $true; break }
            }
            Log "🔔 No `"Allow once`" on the toast (buttons: $buttons); session opened: $opened"
        }
        if ($steps.Count -gt 200) { $steps.Clear() }
    }
    return $null
}

# Tray icon: the state, pause, the log, exit.
function New-Icon([System.Drawing.Color]$color) {
    $bmp = New-Object System.Drawing.Bitmap 16, 16
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = 'AntiAlias'
    $g.FillEllipse((New-Object System.Drawing.SolidBrush $color), 1, 1, 14, 14)
    $g.Dispose()
    [System.Drawing.Icon]::FromHandle($bmp.GetHicon())
}
$iconOn  = New-Icon ([System.Drawing.Color]::FromArgb(89, 209, 166))
$iconOff = New-Icon ([System.Drawing.Color]::Gray)

$state = @{ Active = $true; Cooldown = 0; Accepted = 0 }

$menu     = New-Object System.Windows.Forms.ContextMenuStrip
$status   = $menu.Items.Add('Auto-approve on')
$status.Enabled = $false
[void]$menu.Items.Add('-')
$pause    = $menu.Items.Add('Pause')
$openLog  = $menu.Items.Add('Open log')
[void]$menu.Items.Add('-')
$quit     = $menu.Items.Add('Quit')

$tray = New-Object System.Windows.Forms.NotifyIcon
$tray.Icon = $iconOn
$tray.Text = 'Claude Code - Auto Approver'
$tray.ContextMenuStrip = $menu
$tray.Visible = $true

$pause.Add_Click({
    $state.Active = -not $state.Active
    $status.Text = if ($state.Active) { 'Auto-approve on' } else { 'Paused' }
    $pause.Text  = if ($state.Active) { 'Pause' } else { 'Resume' }
    $tray.Icon   = if ($state.Active) { $iconOn } else { $iconOff }
    Log $(if ($state.Active) { '▶️ Monitor ripreso' } else { '⏹ Monitor in pausa' })
})
$openLog.Add_Click({ Start-Process notepad.exe $logPath })
$quit.Add_Click({
    $tray.Visible = $false
    [System.Windows.Forms.Application]::Exit()
})

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 1500
$timer.Add_Tick({
    if (-not $state.Active) { return }
    # A pressed dialog needs a moment to close: never press the same one twice.
    if ($state.Cooldown -gt 0) { $state.Cooldown--; return }
    try {
        $wanted = Get-Wanted
        $label = Press-InWindow $wanted
        if (-not $label) { $label = Press-OnToast $wanted }
        if ($label) {
            $state.Accepted++
            $state.Cooldown = 1
            Log "🤖 Auto-approve #$($state.Accepted): pressed `"$label`""
        }
    } catch {
        Log "❌ $($_.Exception.Message)"
    }
})

Log "🚀 Claude Code - Auto Approver for Windows started — pressing: $((Get-Wanted) -join ', ')"
$timer.Start()
[System.Windows.Forms.Application]::Run()
$timer.Stop()
$tray.Dispose()
$mutex.ReleaseMutex()
