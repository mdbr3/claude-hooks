#!/bin/bash
# Claude Code: show a macOS desktop notification only when you are NOT actively
# looking at this session's VS Code window.
# Called from a hook as:  notify-when-away.sh "<message>" "<sound>"
# Receives the hook JSON on stdin (provides .session_id and .cwd).

msg="$1"
sound="$2"

input="$(cat)"
sid="$(printf '%s' "$input" | /usr/bin/jq -r '.session_id // empty' 2>/dev/null)"
cwd="$(printf '%s' "$input" | /usr/bin/jq -r '.cwd // empty' 2>/dev/null)"
ws="$(basename "$cwd" 2>/dev/null)"

# Are you currently looking at this session's VS Code window?
looking=0
front_bundle="$(lsappinfo info -only bundleid "$(lsappinfo front)" 2>/dev/null)"
if printf '%s' "$front_bundle" | grep -qF com.microsoft.VSCode; then
  # VS Code is frontmost. Require a non-minimized window whose title matches this
  # session's workspace, so other VS Code windows / minimized state still notify.
  minimized="$(/usr/bin/osascript -e 'tell application "System Events" to tell (first process whose frontmost is true) to get value of attribute "AXMinimized" of front window' 2>/dev/null)"
  title="$(/usr/bin/osascript -e 'tell application "System Events" to tell (first process whose frontmost is true) to get title of front window' 2>/dev/null)"
  if [ "$minimized" = "false" ]; then
    if [ -z "$ws" ] || printf '%s' "$title" | grep -qF "$ws"; then
      looking=1
    fi
  fi
fi

# Looking at this session -> stay quiet. Otherwise notify; clicking jumps to the chat.
if [ "$looking" -eq 0 ]; then
  /usr/local/bin/terminal-notifier \
    -title "Claude Code" \
    -message "$msg" \
    -sound "$sound" \
    -execute "open 'vscode://anthropic.claude-code/open?session=$sid'"
fi
