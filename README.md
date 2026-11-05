# terminal-matrix-theme

A green-on-black "movie hacker" look for Windows Terminal and Claude Code on Windows.

- Windows Terminal: pure black background, phosphor green text (#00ff41), green block cursor, Cascadia Mono.
- Claude Code: a custom `matrix` theme (greens for text, spinner and borders; red and yellow kept for errors and warnings) plus about 40 extra spinner words such as "Decrypting 0110" and "Bypassing the firewall".

I could not take screenshots when building this, so there is no image yet. Add one to the repo if you like.

## What each file does

| File | What it does |
| --- | --- |
| `windows-terminal/matrix-fragment.json` | A Windows Terminal JSON fragment. It adds the color scheme "Matrix Green" and applies it, with Cascadia Mono 12 pt and a filled-box cursor, to the Windows PowerShell and PowerShell 7 profiles. |
| `claude-code/themes/matrix.json` | Claude Code custom theme (base `dark`, color tokens overridden to greens). |
| `claude-code/spinner-verbs.json` | The `spinnerVerbs` setting: mode `append`, so your words are added to Claude Code's built-in ones. |
| `install.ps1` | Backs up settings, installs the fragment and theme, and merges `theme` and `spinnerVerbs` into `~/.claude/settings.json`. |
| `uninstall.ps1` | Removes exactly what install added. |

## Install

Run in Windows PowerShell (5.1 or 7), from the repo folder:

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

What it changes, and prints as it goes:

1. Copies `~/.claude/settings.json` and Windows Terminal's `settings.json` to `settings.json.bak-<timestamp>` next to the originals.
2. Copies the fragment to `%LOCALAPPDATA%\Microsoft\Windows Terminal\Fragments\terminal-matrix-theme\`. Windows Terminal's own `settings.json` is not edited.
3. Copies the theme to `~/.claude/themes/matrix.json`.
4. Sets `"theme": "custom:matrix"` and `spinnerVerbs` in `~/.claude/settings.json`. Other keys are kept. The file is rewritten by PowerShell, so its indentation may change, and comments are not allowed in that file anyway.

It also saves your previous `theme` and `spinnerVerbs` values to `~/.claude/terminal-matrix-theme-state.json` so uninstall can put them back.

Windows Terminal applies fragment profile changes to the Windows PowerShell and PowerShell 7 profiles only; a profile with an explicit `colorScheme` in your own `settings.json` wins over the fragment. To use the scheme in another profile, set `"colorScheme": "Matrix Green"` on it in Settings.

## Uninstall

Run in Windows PowerShell, from the repo folder:

```powershell
powershell -ExecutionPolicy Bypass -File .\uninstall.ps1
```

This deletes the fragment folder and theme file, restores your previous `theme`, and removes `spinnerVerbs` (or restores your previous one). The `.bak-*` backups stay in place.

## Change the words

Edit `claude-code/spinner-verbs.json` and run `install.ps1` again. Use `"mode": "replace"` to show only your words instead of adding to the built-in ones (an empty list falls back to the built-ins). You can also edit `spinnerVerbs` directly in `~/.claude/settings.json`.

## Change the colors

- Terminal: edit the `Matrix Green` scheme in the fragment, then run `install.ps1` again.
- Claude Code: edit `~/.claude/themes/matrix.json`. Claude Code reloads theme files while running.

## Limits

- Claude Code cannot set the window background. It only controls its own text colors. The black background comes from Windows Terminal's color scheme.
- Windows Terminal also has an optional `"experimental.retroTerminalEffect": true` profile setting (scan lines and blurry edges). It is documented as experimental, blurs text, and is not enabled here. Add it to a profile yourself if you want it.

## Docs used

- Claude Code settings reference: https://code.claude.com/docs/en/settings-reference.md (`spinnerVerbs`, `theme`)
- Claude Code custom themes: https://code.claude.com/docs/en/terminal-config.md#create-a-custom-theme
- Claude Code status line: https://code.claude.com/docs/en/statusline.md (not changed by this repo)
- Windows Terminal color schemes: https://learn.microsoft.com/en-us/windows/terminal/customize-settings/color-schemes
- Windows Terminal JSON fragment extensions: https://learn.microsoft.com/en-us/windows/terminal/json-fragment-extensions
- Windows Terminal profile appearance: https://learn.microsoft.com/en-us/windows/terminal/customize-settings/profile-appearance

## License

MIT, see `LICENSE`.
