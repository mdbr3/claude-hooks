#!/bin/bash
# Claude Code: show a macOS desktop notification only when you are NOT actively
# looking at VS Code. Suppress while a VS Code window is in front and not
# minimized; notify when you're in another app OR VS Code is minimized.
# Called from a hook as:  notify-when-away.sh "<message>" "<sound>"
# Receives the hook JSON on stdin (provides .session_id).

msg="$1"
sound="$2"

sid="$(/usr/bin/jq -r '.session_id // empty' 2>/dev/null)"

looking=0
front_bundle="$(lsappinfo info -only bundleid "$(lsappinfo front)" 2>/dev/null)"
if printf '%s' "$front_bundle" | grep -qF com.microsoft.VSCode; then
  # VS Code is the frontmost app. Stay quiet unless its window is minimized
  # (that means you've stepped away). If the window state can't be read, default
  # to quiet so you're never spammed while actually looking at VS Code.
  minimized="$(/usr/bin/osascript -e 'tell application "System Events" to tell (first process whose frontmost is true) to get value of attribute "AXMinimized" of front window' 2>/dev/null)"
  if [ "$minimized" != "true" ]; then
    looking=1
  fi
fi

# Looking at VS Code -> stay quiet. Otherwise notify; clicking jumps to the chat.
if [ "$looking" -eq 0 ]; then
  /usr/local/bin/terminal-notifier \
    -title "Claude Code" \
    -message "$msg" \
    -sound "$sound" \
    -execute "open 'vscode://anthropic.claude-code/open?session=$sid'"
fi
