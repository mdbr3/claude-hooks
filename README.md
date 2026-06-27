# claude-hooks

Desktop notifications for [Claude Code](https://claude.com/claude-code) running in the **VS Code extension**. You get a native notification when Claude:

- 🔐 **needs permission** (to edit a file / run a command),
- ⏳ **is waiting** for your input,
- ✅ **finished** working,

…but **only when you are not looking at VS Code**. Clicking a notification **jumps you straight to the exact chat** that fired it.

## Why this exists

The Claude Code VS Code extension has no native OS notifications — when the panel is hidden you only get a small dot on the icon. These hooks add real, clickable desktop notifications.

## How it works

Claude Code fires lifecycle **hooks** (`PermissionRequest`, `Notification`, `Stop`). Each hook runs a small script that:

1. Reads the hook's `session_id` from stdin.
2. Checks the **foreground app** — if VS Code is in front (and, on macOS, not minimized), it stays quiet.
3. Otherwise it shows a desktop notification whose click opens
   `vscode://anthropic.claude-code/open?session=<id>` — focusing the exact chat that fired it.

Distinct sounds per event make the three cases easy to tell apart.

### Behavior

| Where you are | Notification? |
|---|---|
| Looking at any VS Code window | ❌ no |
| VS Code minimized | ✅ yes |
| Another app (browser, Slack…) | ✅ yes |
| Click a notification | → jumps to the chat that fired it |

> **Note on multiple chat windows:** notifications are suppressed whenever a VS Code window is focused — the script can't tell *which* chat window you're looking at (Claude Code exposes no per-chat window signal; see [issue #10366](https://github.com/anthropics/claude-code/issues/10366)). So while you work in one VS Code window you won't get a banner about *another* chat — you'll still see that chat's icon dot when you switch to it. The click-to-jump always targets the correct chat.

---

## macOS setup

**Prerequisites:** [Homebrew](https://brew.sh).

1. **Install dependencies**
   ```bash
   brew install terminal-notifier
   # jq is usually preinstalled; if not: brew install jq
   ```

2. **Install the script**
   ```bash
   cp macos/notify-when-away.sh ~/.claude/notify-when-away.sh
   chmod +x ~/.claude/notify-when-away.sh
   ```

3. **Add the hooks** — merge the contents of [`macos/settings.hooks.json`](macos/settings.hooks.json) into `~/.claude/settings.json` under a top-level `"hooks"` key. If you don't have a `settings.json` yet, create one with just that block.

4. **Allow notifications** — System Settings → Notifications → enable **terminal-notifier** (Allow Notifications, Banners or Alerts). The first notification registers it in this list.

5. **(Optional) Detect minimize** — to also get notified while VS Code is *minimized*, grant Accessibility: System Settings → Privacy & Security → Accessibility → enable **Visual Studio Code**, then **restart VS Code**. Without this, minimize is treated the same as "looking at VS Code" (no notification).

6. **Reload** — open the `/hooks` menu in Claude Code once, or restart it, so settings reload.

7. **Customize** (optional) — edit the message text and sounds in `settings.hooks.json`.
   Available macOS sounds: `Basso`, `Blow`, `Bottle`, `Frog`, `Funk`, `Glass`, `Hero`, `Morse`, `Ping`, `Pop`, `Purr`, `Sosumi`, `Submarine`, `Tink`.

---

## Windows setup

**Prerequisites:** PowerShell 5+, VS Code (its `vscode://` protocol handler is registered on install).

1. **Install BurntToast** (toast notifications)
   ```powershell
   Install-Module BurntToast -Scope CurrentUser
   ```
   If module install is blocked: `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`.

2. **Install the script** — copy `windows/notify-when-away.ps1` to
   `%USERPROFILE%\.claude\notify-when-away.ps1`.

3. **Add the hooks** — merge [`windows/settings.hooks.json`](windows/settings.hooks.json) into
   `%USERPROFILE%\.claude\settings.json` under a top-level `"hooks"` key.

4. **Allow notifications** — Windows Settings → System → Notifications → make sure notifications are on (BurntToast posts under PowerShell).

5. **Reload** — restart Claude Code.

> On Windows the minimize case is handled automatically (minimizing VS Code changes the foreground window), so no extra permission is needed. Windows toast sounds are a fixed set (e.g. `Default`, `IM`, `Mail`, `Reminder`, `SMS`, `Alarm`, `Call`) — see the [BurntToast docs](https://github.com/Windos/BurntToast).

---

## Files

| Path | Purpose |
|------|---------|
| `macos/notify-when-away.sh` | macOS notifier script (run by the hooks) |
| `macos/settings.hooks.json` | Hooks block to merge into `~/.claude/settings.json` |
| `windows/notify-when-away.ps1` | Windows notifier script |
| `windows/settings.hooks.json` | Hooks block to merge into `%USERPROFILE%\.claude\settings.json` |

## Customize the messages / sounds

Each event maps to one line in `settings.hooks.json`: `script "<message>" "<sound>"`.
Change the text to your language and pick whichever sounds you like per event.
