# claude-hooks

Desktop notifications for [Claude Code](https://claude.com/claude-code) running in the **VS Code extension**. You get a native notification when Claude:

- 🔐 **needs permission** (to edit a file / run a command),
- ⏳ **is waiting** for your input,
- ✅ **finished** working,

…but **only when you are not already looking at that chat**. Clicking a notification **jumps you straight to the exact chat** that fired it.

## Why this exists

The Claude Code VS Code extension has no native OS notifications — when the panel is hidden you only get a small dot on the icon. These hooks add real, clickable desktop notifications.

## How it works

Claude Code fires lifecycle **hooks** (`PermissionRequest`, `Notification`, `Stop`). Each hook runs a small script that:

1. Reads the hook's `session_id` and `cwd` from stdin.
2. Looks at the **foreground window** — if it's this session's VS Code window (not minimized, title matches the workspace), it stays quiet.
3. Otherwise it shows a desktop notification whose click opens
   `vscode://anthropic.claude-code/open?session=<id>` — focusing the exact chat.

Distinct sounds per event make the three cases easy to tell apart.

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

4. **Grant permissions** (System Settings → Privacy & Security):
   - **Notifications** → enable **terminal-notifier** (Allow Notifications, Banners or Alerts).
   - **Accessibility** → enable **Visual Studio Code**. This is required to read window state (minimized / which window). **Restart VS Code** after enabling.

5. **Reload** — open the `/hooks` menu in Claude Code once, or restart it, so settings reload.

6. **Customize** (optional) — edit the message text and sounds in `settings.hooks.json`.
   Available macOS sounds: `Basso`, `Blow`, `Bottle`, `Frog`, `Funk`, `Glass`, `Hero`, `Morse`, `Ping`, `Pop`, `Purr`, `Sosumi`, `Submarine`, `Tink`.

**Notes / limitations**
- "Looking at this session" is matched by the **workspace folder name** in the window title. Two windows with the same folder name can't be told apart.
- Without Accessibility, the script can't detect minimize — it would mute while minimized. Granting Accessibility fixes this.

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

**Notes / limitations**
- On Windows, minimizing VS Code already changes the foreground window, so the minimize case is handled automatically (no extra permission needed).
- Windows toast sounds are a fixed set (e.g. `Default`, `IM`, `Mail`, `Reminder`, `SMS`, `Alarm`, `Call`). See the [BurntToast docs](https://github.com/Windos/BurntToast) for the full list.

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
