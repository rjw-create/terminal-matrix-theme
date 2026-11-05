# terminal-matrix-theme

A green-on-black "movie hacker" look for Windows Terminal and Claude Code on Windows.

Inspired by MylesA1234/HackerScreen (https://github.com/MylesA1234/HackerScreen). No code, colors or word lists were copied from it.

- Windows Terminal: pure black background, electric green text (#00FF41, with neon #39FF14 accents), a full green 16-color set (only red stays red, for errors), green block cursor, Cascadia Mono, falling binary rain and a faint layer of drifting programming terms.
- A dedicated "Claude // Hacker" Windows Terminal profile and a "Claude Hacker" desktop shortcut: a short boot sequence, ACCESS GRANTED, then Claude Code.
- PowerShell: an ACCESS GRANTED prompt (ACCESS DENIED in red after a failed command), a green banner and green typed text.
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
| `windows-terminal/matrix-rain.hlsl` | A pixel shader that draws falling 0 and 1 digits behind the text, and scrolls the word layer. Optional, see "Raining binary" and "Word layer". |
| `windows-terminal/assets/hacker-words.png` | The word layer: 16 programming and hacker terms in dim green on black, 1920x1080, made by `tools/build-word-layer.ps1`. |
| `windows-terminal/hacker-profile.json` | The fixed parts of the "Claude // Hacker" profile (guid, name, padding, tab color). install.ps1 adds the command, scheme, font, cursor, shader and word layer. |
| `tools/build-word-layer.ps1` | Regenerates the word layer PNG with System.Drawing (built into Windows). Edit the term list or sizes at the top. |
| `powershell/start-hacker.ps1` | What the Claude // Hacker profile runs: boot sequence, ACCESS GRANTED, then `claude`. |
| `powershell/profile-block.ps1` | A marked block that install.ps1 appends to your PowerShell profile: a green binary-crab startup banner, green PSReadLine colors for the text you type and the ACCESS GRANTED prompt. |
| `claude-code/matrix-session-banner.ps1` | A SessionStart hook script that prints a small binary crab banner when Claude Code starts. |
| `install.ps1` | Backs up settings, edits Windows Terminal's `settings.json`, adds the Claude // Hacker profile and desktop shortcut, installs the theme, and merges `theme`, `spinnerVerbs`, `companyAnnouncements`, `spinnerTipsOverride` and a SessionStart hook into `~/.claude/settings.json`. Options: see "Switches". |
| `uninstall.ps1` | Removes exactly what install added. |

## Install

Run in Windows PowerShell (5.1 or 7), from the repo folder:

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

What it changes, and prints as it goes:

1. Copies `~/.claude/settings.json`, Windows Terminal's `settings.json` and each PowerShell profile to `.bak-<timestamp>` files next to the originals.
2. Edits Windows Terminal's `settings.json` (JSON-aware, other keys kept): adds the "Matrix Green" scheme to `schemes`, and sets `colorScheme`, `font`, `cursorShape`, the rain shader and the word layer (see "Word layer") on the default profile and on the Windows PowerShell and PowerShell 7 profiles, matched by guid. It also adds the "Claude // Hacker" profile (replacing an older copy with the same guid, so running install again never duplicates it). The file is rewritten by PowerShell, so its indentation may change. If it contains `//` comments the script skips it and tells you.
3. Copies the theme to `~/.claude/themes/matrix.json`.
4. Unless you pass `-NoRain`, copies `matrix-rain.hlsl` to `%LOCALAPPDATA%\terminal-matrix-theme\` and points the profiles at it.
5. Writes a block between `# >>> terminal-matrix-theme >>>` and `# <<< terminal-matrix-theme <<<` into your PowerShell profile (the running shell's profile, plus the PowerShell 7 profile if `pwsh` is installed). If the block is already there it is refreshed in place. The banner is skipped when `MATRIX_THEME_NO_BANNER=1` is set or the shell was started with `-Command`, `-File` or `-EncodedCommand`. The color part does nothing if PSReadLine is not loaded. Set `MATRIX_THEME_PROFILE_PATHS` (semicolon separated) to target other files, for example copies when testing.
6. Sets `theme`, `spinnerVerbs`, `companyAnnouncements` and `spinnerTipsOverride` in `~/.claude/settings.json` and, unless `-NoClaudeBanner`, appends a `SessionStart` hook (existing hooks are kept). See "Claude Code theme: ansi or custom" for the `theme` value.

7. Creates a "Claude Hacker" shortcut on your desktop (see "Desktop shortcut").

Set `MATRIX_THEME_WT_SETTINGS` to a settings.json path to run the Windows Terminal edit on a copy, and `MATRIX_THEME_DESKTOP` to a folder to put the shortcut somewhere other than your desktop. Together with `CLAUDE_CONFIG_DIR`, `LOCALAPPDATA` and `MATRIX_THEME_PROFILE_PATHS` this lets you test the whole install on copies.

### Switches

All are for `install.ps1`, for example `powershell -ExecutionPolicy Bypass -File .\install.ps1 -NoWords -NoPrompt`.

| Switch | Effect |
| --- | --- |
| `-NoRain` | No rain shader. The word layer, if on, becomes a still background image. |
| `-NoWords` | No word layer. |
| `-NoPrompt` | Keep your normal PowerShell prompt instead of ACCESS GRANTED. |
| `-NoClaudeBanner` | No Claude Code SessionStart banner hook. |
| `-ClaudeTheme ansi` or `custom` | Which Claude Code theme to select, see "Claude Code theme: ansi or custom". Default `ansi`. |
| `-RainStrength 0.12` | Rain brightness, 0 to 1. Default 0.12. See "Tuning rain and words". |
| `-WordStrength 0.35` | Word layer brightness inside the shader, 0 to 1. Default 0.35. |

To change switches after installing, run `uninstall.ps1` and then `install.ps1` with the new switches. Running install again over an existing install keeps keys set by the earlier run.

It also saves your previous values of those four keys to `~/.claude/terminal-matrix-theme-state.json` so uninstall can put them back.

It also saves the previous values of exactly the keys it changes (in Claude Code's settings and in Windows Terminal's profiles) to `~/.claude/terminal-matrix-theme-state.json` so uninstall can put them back.

## Why Windows Terminal's settings.json is edited, not a fragment

The first version used a Windows Terminal JSON fragment. On at least one machine (Windows Terminal 1.24, default profile Windows PowerShell) it had no visible effect. The fragment docs say a fragment can update only the default Command Prompt and PowerShell profiles and dynamic profiles, by `updates` guid, which should include this profile, so I could not find the reason from the docs. Editing `settings.json` is the documented path for color schemes and profile settings (color schemes page below), so install.ps1 does that. An old fragment folder from earlier versions is deleted by uninstall.

## Uninstall

Run in Windows PowerShell, from the repo folder:

```powershell
powershell -ExecutionPolicy Bypass -File .\uninstall.ps1
```

This restores the Windows Terminal keys it changed and removes the "Matrix Green" scheme and the "Claude // Hacker" profile, deletes the desktop shortcut (only if it still opens that profile), deletes the shader, word image, start script, banner script, theme file and any old fragment folder, removes the marked block from your PowerShell profile(s), restores your previous values of the four Claude Code keys and removes only the banner hook it added. A value you changed after install is left alone. The `.bak-*` backups stay in place.

## Claude // Hacker profile

A new entry in Windows Terminal's tab dropdown. It uses the Matrix Green scheme, the rain and word layer, a block cursor, 12 px padding and a dark green tab. Its command is `powershell.exe -NoLogo -NoExit -ExecutionPolicy Bypass -File <start-hacker.ps1>`, which:

1. Shows a boot sequence of eight made-up status lines, about 1.5 seconds in total. They are decoration, not real checks. Press any key to skip it.
2. Prints ACCESS GRANTED.
3. Starts `claude` from your PATH. If it is not found, it says so and leaves you at a normal PowerShell prompt. When Claude Code exits, the tab stays open at a PowerShell prompt.

Your other profiles are not replaced; they get the same reskin as before.

## Desktop shortcut

`install.ps1` creates `Claude Hacker.lnk` on your desktop. It runs `wt.exe -p "Claude // Hacker"`, which opens Windows Terminal with that profile. The desktop folder comes from Windows (`[Environment]::GetFolderPath('Desktop')`), so a desktop moved to OneDrive is found. If a different shortcut with that name already exists, install leaves it alone and tells you.

## ACCESS GRANTED prompt

The PowerShell profile block sets the prompt to:

```text
ACCESS GRANTED :: C:\current\folder
>
```

After a command fails it shows ACCESS DENIED in red instead. The exit code of the last command (`$LASTEXITCODE`) is kept. It sits inside the marked block, between its own `prompt` markers, so `-NoPrompt` leaves it out and uninstall removes it with the block.

## Word layer

A faint layer of 16 programming and hacker terms (NULL POINTER, KERNEL PANIC, RACE CONDITION and so on) behind the text.

How it is shown, and why: the Windows Terminal docs say a background image "can be a .jpg, .png, or .gif file" but do not say a GIF animates, and do not describe how a background image combines with a pixel shader. They do document `experimental.pixelShaderImagePath`, an image that is "made available in texture register `t1`" of the shader (profile appearance page, linked below). So:

- With the rain on (the default), `hacker-words.png` is given to the shader through `experimental.pixelShaderImagePath`, and the shader scrolls it slowly upward, so the words drift. The shader decides where the terminal has text before it adds the words and rain, and only draws them on dark pixels, so they never cover or blur text.
- With `-NoRain`, there is no shader, so the PNG is set as a still `backgroundImage` with `backgroundImageOpacity` 0.5.
- With `-NoWords`, neither is set.

If your Windows Terminal version does not support `experimental.pixelShaderImagePath`, the shader sees an empty texture and draws no words; the rain still works.

### Tuning rain and words

The easy way is the install switches, which write the values into the installed copy of the shader (the repo file is not changed). Run in Windows PowerShell from the repo folder, for example:

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -RainStrength 0.08 -WordStrength 0.25
```

- `-RainStrength`: rain brightness, 0 (off) to 1. Default 0.12.
- `-WordStrength`: word brightness, 0 (off) to 1. Default 0.35.
- Values outside 0 to 1 are refused. If you run `install.ps1` again without a switch, the value already in the installed shader is kept, so a re-install does not undo your tuning. After `uninstall.ps1` the defaults apply again.

You can also edit the defaults at the top of `windows-terminal/matrix-rain.hlsl`:

- Rain brightness: `RAIN_STRENGTH` (default 0.12).
- Rain trail length: `TRAIL_ROWS`, in character rows (default 10).
- Word brightness: `WORD_STRENGTH` (default 0.35).
- Word drift speed: `WORD_DRIFT_PX` (pixels per second, default 6; 0 stops it).
- Word brightness with `-NoRain`: `backgroundImageOpacity` in Windows Terminal (Settings > profile > Appearance > Background image opacity), or the 0.5 in `install.ps1`.
- Different words: edit `$Terms` in `tools/build-word-layer.ps1`, then run it in Windows PowerShell from the repo folder:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\build-word-layer.ps1
```

After editing the shader or image, run `install.ps1` again to copy them into place, then open a new tab (I have not checked whether an open tab picks up a changed shader file).

The image is 1920x1080 and tiles, so it covers larger windows too.

## Raining binary

The background rain is a custom pixel shader, set through Windows Terminal's `experimental.pixelShaderPath` profile setting. I chose it over an animated GIF because the Microsoft docs describe a `time` value the shader can use to animate, while the `backgroundImage` page only says a `.gif` is accepted and does not say it animates. A shader is also plain text, adds no binary file, and keeps the text crisp because the rain is drawn only where the terminal pixel is dark.

- The shader draws 0 and 1 shapes in columns that fall at different speeds, at 12 percent strength with 10-row trails. Change it with `install.ps1 -RainStrength` (see "Tuning rain and words").
- It is experimental. Microsoft says the feature's continued existence is not guaranteed, that it overrides `experimental.retroTerminalEffect`, and that if a shader fails to compile the terminal shows a warning and ignores it. It also redraws every frame, so it uses some GPU.
- To skip it: `powershell -ExecutionPolicy Bypass -File .\install.ps1 -NoRain` (Windows PowerShell). To remove it later, run `uninstall.ps1`, then `install.ps1 -NoRain`.
- I compiled the shader, including the word layer, with the Windows `d3dcompiler_47` library (targets `ps_5_0` and `ps_4_0`) and it compiled without errors, but I could not look at the result on screen.

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

In `ansi` mode Claude's accent colors are whatever the scheme's ANSI colors are. The docs do not say which ANSI slots `dark-ansi` uses for the orange brand accent or for other roles, so I cannot tell you that. Every slot except `red` and `brightRed` is now a green or green-tinted color, including the yellow slots (lime, #c6ff3d and #e0ff80), so Claude's accents stay green. The cost is that warnings drawn in yellow look closer to the greens; errors stay salmon-red (#ff5f57, #ff8f85). If you want gold warnings back, set `yellow` and `brightYellow` in `windows-terminal/matrix-scheme.json` (they were #ffd400 and #fff04d) and run `install.ps1` again.

### Contrast

WCAG contrast ratios against the black background (AA asks for at least 4.5:1 for normal text): foreground 15.38:1, white 18.74:1, brightWhite 19.99:1, red 7.03:1, brightRed 9.52:1, and brightBlack, the dimmest text color, 6.10:1. Foreground text on the selection color is 6.01:1.

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
