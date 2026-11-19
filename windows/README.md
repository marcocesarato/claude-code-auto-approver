# Claude Code - Auto Approver for Windows

Accepts every Claude Code permission prompt in the Claude desktop app by invoking its
**Allow once** button through UI Automation: in the app's window for the session on
screen, and on its toast notification for a session in the background. It never presses
**Always allow**, so it writes no permanent rule.

## Install

```powershell
powershell -ExecutionPolicy Bypass -File install.ps1
```

The script is copied to `%LOCALAPPDATA%\ClaudeCodeAutoApprover`, started, and started again at every
sign-in. A green dot in the tray means it is active; its menu pauses it, opens the log or
quits. No permission needs granting.

## When a prompt is not accepted

Open the log from the tray menu (`%LOCALAPPDATA%\ClaudeCodeAutoApprover\ClaudeCodeAutoApprover.log`):

- `🆕 New buttons:` lists the buttons it saw; a dialog's appear when it opens.
- `🔔 No "Allow once" on the toast` lists the toast's buttons.

Put the right label in `%APPDATA%\ClaudeCodeAutoApprover\labels.txt`, one per line. It is read on
every check, so nothing needs restarting.

## Uninstall

```powershell
powershell -ExecutionPolicy Bypass -File uninstall.ps1
```
