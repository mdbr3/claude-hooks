# Claude Code: show a Windows toast only when you are NOT actively looking at
# VS Code. Suppress while VS Code is the foreground app; notify otherwise.
# (On Windows, minimizing VS Code changes the foreground window, so minimize is
# handled automatically.)
# Called from a hook as:  & notify-when-away.ps1 "<message>" "<sound>"
# Receives the hook JSON on stdin (provides session_id).
param(
  [string]$Message,
  [string]$Sound = "Default"
)

# Read the hook JSON from stdin.
$raw = [Console]::In.ReadToEnd()
try { $hook = $raw | ConvertFrom-Json } catch { $hook = $null }
$sid = if ($hook -and $hook.session_id) { $hook.session_id } else { "" }

# Win32 helper to read the foreground window's owning process.
Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class Fg {
  [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
}
"@ -ErrorAction SilentlyContinue

$h = [Fg]::GetForegroundWindow()
$wpid = 0
[Fg]::GetWindowThreadProcessId($h, [ref]$wpid) | Out-Null
$proc = (Get-Process -Id $wpid -ErrorAction SilentlyContinue).ProcessName

# VS Code in front -> you're looking at it -> stay quiet. Otherwise notify.
if ($proc -ne "Code") {
  $uri = "vscode://anthropic.claude-code/open?session=$sid"
  Import-Module BurntToast -ErrorAction SilentlyContinue
  if (Get-Module BurntToast) {
    # Clicking the button opens the deep link -> focuses the exact chat.
    $btn = New-BTButton -Content "Open chat" -Arguments $uri -ActivationType Protocol
    New-BurntToastNotification -Text "Claude Code", $Message -Button $btn -Sound $Sound
  } else {
    # Fallback if BurntToast is not installed: audible beep only.
    [console]::beep(880, 200)
  }
}
