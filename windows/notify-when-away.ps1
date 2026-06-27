# Claude Code: show a Windows toast only when you are NOT actively looking at
# this session's VS Code window.
# Called from a hook as:  & notify-when-away.ps1 "<message>" "<sound>"
# Receives the hook JSON on stdin (provides session_id and cwd).
param(
  [string]$Message,
  [string]$Sound = "Default"
)

# Read the hook JSON from stdin.
$raw = [Console]::In.ReadToEnd()
try { $hook = $raw | ConvertFrom-Json } catch { $hook = $null }
$sid = if ($hook -and $hook.session_id) { $hook.session_id } else { "" }
$cwd = if ($hook -and $hook.cwd) { $hook.cwd } else { "" }
$ws  = if ($cwd) { Split-Path $cwd -Leaf } else { "" }

# Win32 helpers to read the foreground window (process + title).
Add-Type @"
using System;
using System.Text;
using System.Runtime.InteropServices;
public static class Fg {
  [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
  [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
}
"@ -ErrorAction SilentlyContinue

$h = [Fg]::GetForegroundWindow()
$wpid = 0
[Fg]::GetWindowThreadProcessId($h, [ref]$wpid) | Out-Null
$sb = New-Object System.Text.StringBuilder 1024
[Fg]::GetWindowText($h, $sb, $sb.Capacity) | Out-Null
$title = $sb.ToString()
$proc  = (Get-Process -Id $wpid -ErrorAction SilentlyContinue).ProcessName

# On Windows, minimizing VS Code changes the foreground window, so "Code" being
# foreground already means a visible window. Match the workspace to keep other
# VS Code windows notifying.
$looking = $false
if ($proc -eq "Code") {
  if ([string]::IsNullOrEmpty($ws) -or $title -like "*$ws*") {
    $looking = $true
  }
}

if (-not $looking) {
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
