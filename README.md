# terminal-matrix-theme

A green-on-black "movie hacker" look for Windows Terminal and Claude Code on Windows.

- Windows Terminal: pure black background, electric green text (#00FF41, with neon #39FF14 and pure #00FF00 accents), green block cursor, Cascadia Mono.
- Claude Code: a custom `matrix` theme (greens for text, spinner and borders; red and yellow kept for errors and warnings) plus about 40 extra spinner words such as "Decrypting 0110" and "Bypassing the firewall".

I could not take screenshots when building this, so there is no image yet. Add one to the repo if you like.

## What each file does

| File | What it does |
| --- | --- |
| `windows-terminal/matrix-fragment.json` | A Windows Terminal JSON fragment. It adds the color scheme "Matrix Green" and applies it, with Cascadia Mono 12 pt and a filled-box cursor, to the Windows PowerShell and PowerShell 7 profiles. |
| `claude-code/themes/matrix.json` | Claude Code custom theme (base `dark`, color tokens overridden to greens). |
| `claude-code/spinner-verbs.json` | The `spinnerVerbs` setting: mode `append`, so your words are added to Claude Code's built-in ones. |
| `claude-code/company-announcements.json` | The `companyAnnouncements` setting: 12 startup lines such as "> wake up, neo". Claude Code shows one at random per session. |
| `claude-code/spinner-tips.json` | The `spinnerTipsOverride` setting: 15 short real Claude Code tips under the label "intel", with `excludeDefault` true so only these show. |
| `windows-terminal/matrix-rain.hlsl` | A pixel shader that draws falling 0 and 1 digits behind the text. Optional, see "Raining binary". |
| `powershell/profile-block.ps1` | A marked block that install.ps1 appends to your PowerShell profile. It sets PSReadLine colors so the text you type is green. |
| `install.ps1` | Backs up settings, installs the fragment and theme, and merges `theme`, `spinnerVerbs`, `companyAnnouncements` and `spinnerTipsOverride` into `~/.claude/settings.json`. |
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
4. Unless you pass `-NoRain`, copies `matrix-rain.hlsl` to `%LOCALAPPDATA%\terminal-matrix-theme\` and writes its absolute path into the installed fragment as `experimental.pixelShaderPath` (the repo copy of the fragment stays machine-independent).
5. Appends a block between `# >>> terminal-matrix-theme >>>` and `# <<< terminal-matrix-theme <<<` to your PowerShell profile (the running shell's profile, plus the PowerShell 7 profile if `pwsh` is installed). The profile is backed up first, the block is not added twice, and it does nothing if PSReadLine is not loaded. Set `MATRIX_THEME_PROFILE_PATHS` (semicolon separated) to target other files, for example copies when testing.
6. Sets `"theme": "custom:matrix"`, `spinnerVerbs`, `companyAnnouncements` and `spinnerTipsOverride` in `~/.claude/settings.json`. Other keys are kept. The file is rewritten by PowerShell, so its indentation may change, and comments are not allowed in that file anyway.

It also saves your previous values of those four keys to `~/.claude/terminal-matrix-theme-state.json` so uninstall can put them back.

Windows Terminal applies fragment profile changes to the Windows PowerShell and PowerShell 7 profiles only; a profile with an explicit `colorScheme` in your own `settings.json` wins over the fragment. To use the scheme in another profile, set `"colorScheme": "Matrix Green"` on it in Settings.

## Uninstall

Run in Windows PowerShell, from the repo folder:

```powershell
powershell -ExecutionPolicy Bypass -File .\uninstall.ps1
```

This deletes the fragment folder and theme file, removes the marked block from your PowerShell profile(s), restores your previous `theme`, and removes `spinnerVerbs` (or restores your previous one). The `.bak-*` backups stay in place.

## Raining binary

The background rain is a custom pixel shader, set through Windows Terminal's `experimental.pixelShaderPath` profile setting. I chose it over an animated GIF because the Microsoft docs describe a `time` value the shader can use to animate, while the `backgroundImage` page only says a `.gif` is accepted and does not say it animates. A shader is also plain text, adds no binary file, and keeps the text crisp because the rain is drawn only where the terminal pixel is dark.

- The shader draws 0 and 1 shapes in columns that fall at different speeds, at 30 percent strength. Change `RAIN_STRENGTH` at the top of `windows-terminal/matrix-rain.hlsl` (0 to 1) and run `install.ps1` again.
- It is experimental. Microsoft says the feature's continued existence is not guaranteed, that it overrides `experimental.retroTerminalEffect`, and that if a shader fails to compile the terminal shows a warning and ignores it. It also redraws every frame, so it uses some GPU.
- To skip it: `powershell -ExecutionPolicy Bypass -File .\install.ps1 -NoRain` (Windows PowerShell). To remove it later, run `uninstall.ps1`, then `install.ps1 -NoRain`.
- I compiled the shader with the Windows `d3dcompiler_47` library (target `ps_5_0`) and it compiled without errors, but I could not look at the result on screen.

## Change the words

Edit `claude-code/spinner-verbs.json` and run `install.ps1` again. Use `"mode": "replace"` to show only your words instead of adding to the built-in ones (an empty list falls back to the built-ins). You can also edit `spinnerVerbs` directly in `~/.claude/settings.json`.

## Change the colors

- Terminal: edit the `Matrix Green` scheme in the fragment, then run `install.ps1` again.
- Claude Code: edit `~/.claude/themes/matrix.json`.
- Typed text in Claude Code: the docs list no color token for the prompt input, so typed text follows `text`, the closest documented match ("Default foreground text"). It is set to #00FF41, and `promptBorder` is #39FF14.
- Typed text in PowerShell: edit the colors in `powershell/profile-block.ps1` and run `uninstall.ps1` then `install.ps1`.

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
- Windows Terminal JSON fragment extensions: https://learn.microsoft.com/en-us/windows/terminal/json-fragment-extensions
- Windows Terminal profile appearance (`backgroundImage`, `experimental.pixelShaderPath`): https://learn.microsoft.com/en-us/windows/terminal/customize-settings/profile-appearance
- Windows Terminal pixel shader authoring: https://github.com/microsoft/terminal/blob/main/samples/PixelShaders/README.md

## License

MIT, see `LICENSE`.
