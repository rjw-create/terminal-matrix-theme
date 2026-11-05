# Hacker revamp plan (2026-11-05)

Branch `feature/hacker-revamp`. Goal: keep the current reskin of existing Windows Terminal profiles, and add a
dedicated "Claude // Hacker" profile with a boot sequence, an ACCESS GRANTED prompt, a faint drifting word layer,
a full green 16-colour scheme and a desktop shortcut. Inspired by MylesA1234/HackerScreen (no code copied; that
repo has no license).

## Key finding: how the word layer is shown

The Windows Terminal profile appearance page
(https://learn.microsoft.com/en-us/windows/terminal/customize-settings/profile-appearance) says the background
image "can be a .jpg, .png, or .gif file" but does not say a GIF animates, and says nothing about how
`backgroundImage` combines with `experimental.pixelShaderPath`. It does document
`experimental.pixelShaderImagePath`: "an image file to be loaded alongsize [sic] the shader. It will be made available
in texture register `t1`."

So, instead of an animated GIF:

- The generator writes a static PNG of faint terms (1920x1080, tiles vertically without a seam).
- With the rain on (default), the PNG is passed to the shader through `experimental.pixelShaderImagePath`. The
  shader scrolls it slowly upward using its documented `time` value, so the words drift. The shader adds the
  words itself, after it measures the terminal pixel, so its text mask cannot mistake words for text: words and
  rain are only drawn where the terminal pixel is dark.
- With `-NoRain`, there is no shader, so the PNG is set as a static `backgroundImage` at low
  `backgroundImageOpacity`.
- `-NoWords` skips the word layer either way.
- If a Windows Terminal version ignores `pixelShaderImagePath`, texture `t1` is unbound; the shader checks its
  size and draws no words.

## Pieces, files and tests

| Piece | Files | How it is tested (copies only) |
| --- | --- | --- |
| Full green 16-colour scheme | `windows-terminal/matrix-scheme.json` | Script computes WCAG contrast of foreground, white, brightWhite (and the rest) against the background. |
| Word layer generator + image | `tools/build-word-layer.ps1`, `windows-terminal/assets/hacker-words.png` | Run generator, check size (< 1 MB) and dimensions; view the PNG. |
| Shader word drift | `windows-terminal/matrix-rain.hlsl` | Compile with `d3dcompiler_47` (`ps_5_0`) via a scratch script. |
| Claude // Hacker profile | `windows-terminal/hacker-profile.json`, `install.ps1` | Install on a copy of settings.json; check the profile exists once, with the expected keys. |
| Boot sequence + launcher | `powershell/start-hacker.ps1` | Run it with a fake `claude` on PATH, and with none, and with `-SkipIntro`; time the intro. |
| ACCESS GRANTED prompt | `powershell/profile-block.ps1` (inside the existing markers, in its own sub-markers) | Dot-source the block in a fresh `powershell -NoProfile`, call `prompt`, check output and that `$LASTEXITCODE` is kept. Install with `-NoPrompt` and check the section is gone. |
| Desktop shortcut | `install.ps1`, `uninstall.ps1` | `MATRIX_THEME_DESKTOP` points at a scratch folder; read the .lnk back with `WScript.Shell`. |
| README | `README.md` | Read through; no control characters. |

New switches: `-NoWords`, `-NoPrompt`. Existing `-NoRain`, `-NoClaudeBanner`, `-ClaudeTheme` keep working.
New test override: `MATRIX_THEME_DESKTOP` (desktop folder for the shortcut).

## State and re-install

The state file (`terminal-matrix-theme-state.json`) is written on the first install only, so "previous" values
are never our own. Today a re-install only adds missing top-level keys. That would miss new per-profile keys
(for example `experimental.pixelShaderImagePath` for someone who installed the older version), so re-install now
also merges missing Windows Terminal records, profiles and keys into the saved state. New state entries:
`hackerProfile` (per settings.json path: whether a profile with our GUID existed) and `shortcut` (the .lnk path).

The Claude // Hacker profile has a fixed GUID (`{7dee5498-89ee-42d5-a3e3-be4fd0239c50}`); install removes any
profile with that GUID before adding it, so re-install never duplicates it. The reskin loop skips that GUID.

## Uninstall

- Profile: removes the profile with our GUID from each recorded settings.json.
- Scheme, reskinned keys: as today (restored only if still the installed value).
- Shortcut: deleted only if it still points at `wt.exe` with our profile argument.
- Word image, start script, shader: inside `%LOCALAPPDATA%\terminal-matrix-theme\`, which uninstall already
  deletes.
- Prompt: part of the marked profile block, which uninstall already removes.

## End-to-end test

On copies (scratch `CLAUDE_CONFIG_DIR`, `LOCALAPPDATA`, `MATRIX_THEME_PROFILE_PATHS`, `MATRIX_THEME_WT_SETTINGS`,
`MATRIX_THEME_DESKTOP`): install, install again (no duplicates), uninstall, then compare the JSON structurally
(parsed and re-serialised, sorted keys) with the originals. Hash the real files before and after to show they
did not change. Parse every script with the Windows PowerShell 5.1 parser. Scan changed files for control
characters and mojibake.
