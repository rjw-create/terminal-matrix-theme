# terminal-matrix-theme

A green-on-black "movie hacker" look for Windows Terminal and Claude Code on Windows.

- Windows Terminal: pure black background, electric green text (#00FF41, with neon #39FF14 and pure #00FF00 accents), green block cursor, Cascadia Mono.
- Claude Code: green through the built-in `dark-ansi` theme by default (or a custom `matrix` theme with `-ClaudeTheme custom`; greens for text, spinner and borders; red and yellow kept for errors and warnings) plus about 40 extra spinner words such as "Decrypting 0110" and "Bypassing the firewall".

I could not take screenshots when building this, so there is no image yet. Add one to the repo if you like.

## What each file does

| File | What it does |
| --- | --- |
| `windows-terminal/matrix-scheme.json` | The "Matrix Green" color scheme and the profile settings (Cascadia Mono 12 pt, filled-box cursor) that install.ps1 writes into Windows Terminal's `settings.json`. |
| `claude-code/themes/matrix.json` | Claude Code custom theme (base `dark`, color tokens overridden to greens). |
| `claude-code/spinner-verbs.json` | The `spinnerVerbs` setting: mode `append`, so your words are added to Claude Code's built-in ones. |
| `claude-code/company-announcements.json` | The `companyAnnouncements` setting: 12 startup lines such as "> wake up, neo". Claude Code shows one at random per session. |
| `claude-code/spinner-tips.json` | The `spinnerTipsOverride` setting: 15 short real Claude Code tips under the label "intel", with `excludeDefault` true so only these show. |
| `windows-terminal/matrix-rain.hlsl` | A pixel shader that draws falling 0 and 1 digits behind the text. Optional, see "Raining binary". |
| `powershell/profile-block.ps1` | A marked block that install.ps1 appends to your PowerShell profile: a green binary-crab startup banner and green PSReadLine colors for the text you type. |
| `claude-code/matrix-session-banner.ps1` | A SessionStart hook script that prints a small binary crab banner when Claude Code starts. |
| `install.ps1` | Backs up settings, edits Windows Terminal's `settings.json`, installs the theme, and merges `theme`, `spinnerVerbs`, `companyAnnouncements`, `spinnerTipsOverride` and a SessionStart hook into `~/.claude/settings.json`. Options: `-NoRain`, `-NoClaudeBanner`, `-ClaudeTheme ansi` or `custom`. |
| `uninstall.ps1` | Removes exactly what install added. |

## Install

Run in Windows PowerShell (5.1 or 7), from the repo folder:

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

What it changes, and prints as it goes:

1. Copies `~/.claude/settings.json`, Windows Terminal's `settings.json` and each PowerShell profile to `.bak-<timestamp>` files next to the originals.
2. Edits Windows Terminal's `settings.json` (JSON-aware, other keys kept): adds the "Matrix Green" scheme to `schemes`, and sets `colorScheme`, `font`, `cursorShape` and (unless `-NoRain`) `experimental.pixelShaderPath` on the default profile and on the Windows PowerShell and PowerShell 7 profiles, matched by guid. The file is rewritten by PowerShell, so its indentation may change. If it contains `//` comments the script skips it and tells you.
3. Copies the theme to `~/.claude/themes/matrix.json`.
4. Unless you pass `-NoRain`, copies `matrix-rain.hlsl` to `%LOCALAPPDATA%\terminal-matrix-theme\` and points the profiles at it.
5. Writes a block between `# >>> terminal-matrix-theme >>>` and `# <<< terminal-matrix-theme <<<` into your PowerShell profile (the running shell's profile, plus the PowerShell 7 profile if `pwsh` is installed). If the block is already there it is refreshed in place. The banner is skipped when `MATRIX_THEME_NO_BANNER=1` is set or the shell was started with `-Command`, `-File` or `-EncodedCommand`. The color part does nothing if PSReadLine is not loaded. Set `MATRIX_THEME_PROFILE_PATHS` (semicolon separated) to target other files, for example copies when testing.
6. Sets `theme`, `spinnerVerbs`, `companyAnnouncements` and `spinnerTipsOverride` in `~/.claude/settings.json` and, unless `-NoClaudeBanner`, appends a `SessionStart` hook (existing hooks are kept). See "Claude Code theme: ansi or custom" for the `theme` value.

Set `MATRIX_THEME_WT_SETTINGS` to a settings.json path to run the Windows Terminal edit on a copy.

It also saves your previous values of those four keys to `~/.claude/terminal-matrix-theme-state.json` so uninstall can put them back.

It also saves the previous values of exactly the keys it changes (in Claude Code's settings and in Windows Terminal's profiles) to `~/.claude/terminal-matrix-theme-state.json` so uninstall can put them back.

## Why Windows Terminal's settings.json is edited, not a fragment

The first version used a Windows Terminal JSON fragment. On at least one machine (Windows Terminal 1.24, default profile Windows PowerShell) it had no visible effect. The fragment docs say a fragment can update only the default Command Prompt and PowerShell profiles and dynamic profiles, by `updates` guid, which should include this profile, so I could not find the reason from the docs. Editing `settings.json` is the documented path for color schemes and profile settings (color schemes page below), so install.ps1 does that. An old fragment folder from earlier versions is deleted by uninstall.

## Uninstall

Run in Windows PowerShell, from the repo folder:

```powershell
powershell -ExecutionPolicy Bypass -File .\uninstall.ps1
```

This restores the Windows Terminal keys it changed and removes the "Matrix Green" scheme, deletes the shader, banner script, theme file and any old fragment folder, removes the marked block from your PowerShell profile(s), restores your previous values of the four Claude Code keys and removes only the banner hook it added. A value you changed after install is left alone. The `.bak-*` backups stay in place.

## Raining binary

The background rain is a custom pixel shader, set through Windows Terminal's `experimental.pixelShaderPath` profile setting. I chose it over an animated GIF because the Microsoft docs describe a `time` value the shader can use to animate, while the `backgroundImage` page only says a `.gif` is accepted and does not say it animates. A shader is also plain text, adds no binary file, and keeps the text crisp because the rain is drawn only where the terminal pixel is dark.

- The shader draws 0 and 1 shapes in columns that fall at different speeds, at 30 percent strength. Change `RAIN_STRENGTH` at the top of `windows-terminal/matrix-rain.hlsl` (0 to 1) and run `install.ps1` again.
- It is experimental. Microsoft says the feature's continued existence is not guaranteed, that it overrides `experimental.retroTerminalEffect`, and that if a shader fails to compile the terminal shows a warning and ignores it. It also redraws every frame, so it uses some GPU.
- To skip it: `powershell -ExecutionPolicy Bypass -File .\install.ps1 -NoRain` (Windows PowerShell). To remove it later, run `uninstall.ps1`, then `install.ps1 -NoRain`.
- I compiled the shader with the Windows `d3dcompiler_47` library (target `ps_5_0`) and it compiled without errors, but I could not look at the result on screen.

## Change the words

Edit `claude-code/spinner-verbs.json` and run `install.ps1` again. Use `"mode": "replace"` to show only your words instead of adding to the built-in ones (an empty list falls back to the built-ins). You can also edit `spinnerVerbs` directly in `~/.claude/settings.json`.

## Change the colors

- Terminal: edit the scheme in `windows-terminal/matrix-scheme.json`, then run `install.ps1` again.
- Claude Code: edit `~/.claude/themes/matrix.json`.
- Typed text in Claude Code: the docs list no color token for the prompt input, so typed text follows `text`, the closest documented match ("Default foreground text"). It is set to #00FF41, and `promptBorder` is #39FF14.
- Typed text in PowerShell: edit the colors in `powershell/profile-block.ps1` and run `uninstall.ps1` then `install.ps1`.

## Claude Code theme: ansi or custom

`install.ps1` sets Claude Code's `theme` according to `-ClaudeTheme`:

- `ansi` (the default) sets `"theme": "dark-ansi"`, a built-in value the settings reference lists as "the dark theme using only your terminal's ANSI color palette". Claude Code then uses the 16 colors of the Windows Terminal scheme, which is green, so Claude Code looks green without custom theme loading.
- `custom` sets `"theme": "custom:matrix"`, which uses `~/.claude/themes/matrix.json`.

Why the fallback exists: on one install (Claude Code 2.1.318) `/theme` did not list the custom theme at all, even though the file was valid and in `~/.claude/themes/`. I could not confirm why, so I make no claim about the cause. The theme file is installed either way. Switch with `/theme` inside Claude Code, or rerun this in Windows PowerShell from the repo folder:

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -ClaudeTheme custom
```

In `ansi` mode Claude's accent colors are whatever the scheme's ANSI colors are. The docs do not say which ANSI slots `dark-ansi` uses for the orange brand accent or for other roles, so I cannot tell you that. I left the scheme's yellow slots golden (`yellow`, `brightYellow`) so warnings stay distinct from the greens, and errors use red. If you see an orange or yellow accent you dislike, edit those slots in `windows-terminal/matrix-scheme.json` (for example to a lime such as #ccff00) and run `install.ps1` again; the cost is that warnings then look closer to the greens.

## Banners

- PowerShell: the profile block prints a green binary crab (plain ASCII, 17 lines, under 80 columns) and "ACCESS GRANTED // TERMINAL ONLINE" when a terminal opens. Set `MATRIX_THEME_NO_BANNER=1` to skip it.
- Claude Code: the hooks reference says "To surface a message to the user on any platform, return `systemMessage` in JSON output", and its field table describes `systemMessage` as a warning message shown to the user. `claude-code/matrix-session-banner.ps1` prints a small crab as that `systemMessage` from a `SessionStart` hook (matcher `startup`). The docs do not say how a multi-line `systemMessage` is rendered at session start, and the SessionStart section I read does not mention `systemMessage`, so whether it displays correctly is unverified. Plain stdout from a SessionStart hook goes to Claude as context, not to you, which is why JSON is used. Skip the hook with `-NoClaudeBanner`.
- `companyAnnouncements`: the docs describe an array of strings and do not say whether a string may contain newlines, so the lines here are single-line.

## Theme tokens

`claude-code/themes/matrix.json` overrides every token the Claude Code docs name in the custom theme reference: text and accents, status colors, input-box and mode colors, diff colors (including the dimmed ones), the fullscreen backgrounds, the usage meter and speaker labels, the paired shimmer colors, the eight `<color>_FOR_SUBAGENTS_ONLY` colors (eight different greens so helper agents stay distinguishable) and the `rainbow_<color>` and `rainbow_<color>_shimmer` tokens (a green gradient). Red and yellow remain only on `error`, `warning` and the removed-diff backgrounds, so errors stay visible.

The docs also say the `/theme` editor shows the same tokens plus "a few single-purpose accents such as onboarding screen colors" that are left out of the reference. They are not named, so this theme does not set them and they keep the `dark` base colors. Unknown token names are ignored by Claude Code, so I did not guess any.

## Limits

- Claude Code cannot set the window background. It only controls its own text colors. The black background comes from Windows Terminal's color scheme.
- Windows Terminal also has an optional `"experimental.retroTerminalEffect": true` profile setting (scan lines and blurry edges). It is documented as experimental, blurs text, and is not enabled here. Add it to a profile yourself if you want it.

## Docs used

- Claude Code settings reference: https://code.claude.com/docs/en/settings-reference.md (`spinnerVerbs`, `theme`, `companyAnnouncements`, `spinnerTipsOverride`)
- Claude Code custom themes: https://code.claude.com/docs/en/terminal-config.md#create-a-custom-theme
- Claude Code status line: https://code.claude.com/docs/en/statusline.md (not changed by this repo)
- Windows Terminal color schemes: https://learn.microsoft.com/en-us/windows/terminal/customize-settings/color-schemes
- Claude Code hooks reference: https://code.claude.com/docs/en/hooks.md (`SessionStart`, `systemMessage`)
- Windows Terminal JSON fragment extensions (no longer used by install.ps1): https://learn.microsoft.com/en-us/windows/terminal/json-fragment-extensions
- Windows Terminal profile appearance (`backgroundImage`, `experimental.pixelShaderPath`): https://learn.microsoft.com/en-us/windows/terminal/customize-settings/profile-appearance
- Windows Terminal pixel shader authoring: https://github.com/microsoft/terminal/blob/main/samples/PixelShaders/README.md

## License

MIT, see `LICENSE`.
