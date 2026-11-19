# Agent guide

Notes for coding agents and contributors working on Claude Code - Auto Approver. The README
is for users; this file is for whoever changes the code.

## What the product is

A menu bar app that presses **Allow once** on Claude Code permission prompts in the Claude
desktop app (bundle `com.anthropic.claudefordesktop`), through the macOS Accessibility API.
It handles prompts in two places: the dialog in the Claude window, and the notification
banner in Notification Center (`com.apple.notificationcenterui`). A PowerShell port in
`windows/` does the same with UI Automation.

## Layout

| Path | What it holds | Rule |
|---|---|---|
| `macos/sources/core/` | `Labels`, `Chats`, `L10n`, `Pause`: pure logic | No AppKit, no Accessibility, no file access. Everything here has a test. |
| `macos/sources/app/` | Menu, monitor, Accessibility walkers, notifier, settings | Reads the screen and the disk. Keep the logic in `core/`. |
| `macos/tests/` | Swift Testing suites for `core/` | XCTest is not used: it does not run with the Command Line Tools. |
| `macos/resources/Info.plist` | Bundle metadata and the version | The release workflow overrides the version from the tag. |
| `macos/scripts/` | `build-app.sh`, `install.sh`, `uninstall.sh`, `make-icon.swift` | Each script `cd`s to `macos/` itself. |
| `windows/` | `auto-approver.ps1` and its installers | Keep its behaviour and log lines in step with the macOS app. |
| `docs/` | README art, light and dark; `make-art.py` writes each picture as SVG and as the 2x PNG the README shows | Edit the generator, never the pictures. Rendering the PNGs needs Google Chrome. |

Folder names are lowercase. Swift files are named after the type they hold.

## Commands

```bash
cd macos
swift test                 # the core's tests
scripts/build-app.sh       # build/Claude Code - Auto Approver.app, universal when Xcode is installed
scripts/install.sh         # build, install in /Applications or ~/Applications, start
```

If `swift test` reports `no such module 'Testing'` or a missing `TestingMacros` plugin, the
active developer directory lacks Swift Testing. Run it with Xcode's toolchain:
`DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test`.

`build-app.sh` builds in `.build-app/`, apart from `.build/`. Xcode's build system, which the
universal build uses, leaves `.build/` in a state `swift test` cannot use.

## Rules that keep the app safe

- **Press Allow once and nothing else.** Never add a label that grants a lasting permission,
  such as "Always allow", or one that answers a question or approves a plan.
  `LabelsTests.neverPressesAnythingElse` guards this; extend it when you add labels.
- **When in doubt, do not press.** A doubtful chat match skips the prompt. A failed read
  presses nothing. An error is logged, never turned into an approval.
- **No network access and no telemetry.** The app reads the screen and writes a local log.
- **No forced unwraps or `try!` in `sources/app/`.** A crash stops all approvals until
  someone notices. Accessibility reads can return nothing at any moment.
- **Walk the tree once per check.** Never use `lazy.compactMap { … }.first` over a walk:
  it runs the walk twice, and that crashed the app once.

## Making a change

- **New user-visible text:** add an `L10n.Key` and its string in all seven languages (en, it,
  de, es, fr, pt, ja). `LocalizationTests.everyLanguageHasEveryString` fails otherwise.
- **New Claude label:** read it from the Claude app's own translations in
  `/Applications/Claude.app/Contents/Resources/*.json` rather than guessing it.
- **Accessibility layout:** Claude's window changes between releases. Before relying on a
  role, title or nesting, inspect the live tree with a small AX probe, and log what the app
  sees (`🆕 New buttons:`, `🔔 Permission notification:`) so a user's log can diagnose it.
- **Log lines** start with an emoji that names the event, and they are the user's main
  diagnostic tool. Keep them in English and in step with the Windows port.
- **Tests:** logic goes in `core/` with a test. A bug fix starts with a failing test when
  the logic can be tested there.

## After rebuilding

Each build is signed ad hoc, so macOS stops honouring the Accessibility grant of the
previous build. The person running the app must reset it and turn it on again; agents do
not change privacy settings for them:

```bash
tccutil reset Accessibility com.marcocesarato.ClaudeCodeAutoApprover
```

So an agent does not install a build over the user's running app unless asked: verify a
change with `swift test` and `scripts/build-app.sh`, which leave the installed app alone.

## Commits

Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/):
`<type>(<optional scope>): <summary>`, with the summary in the imperative and under 72
characters. Types: `feat`, `fix`, `docs`, `refactor`, `test`, `build`, `ci`, `chore`.
Scopes, when they help: `macos`, `windows`, `core`, `docs`, `ci`. A breaking change adds
`!` after the type and a `BREAKING CHANGE:` footer. The body says why, in full sentences.

```text
feat(macos): pause auto-approve for a chosen length of time
fix(core): stop the window walk from running twice
```

## Releasing

Update `CHANGELOG.md` and `macos/resources/Info.plist`, then push a tag `vX.Y.Z`. `.github/workflows/release.yml` runs the
tests, builds the app with that version, zips it with `ditto`, zips `windows/`, writes
`SHA256SUMS.txt` and publishes a GitHub release.

## Naming

The product is **Claude Code - Auto Approver**, by Marco Cesarato. Its bundle identifier is
`com.marcocesarato.ClaudeCodeAutoApprover`, and its support folder and log are named
`ClaudeCodeAutoApprover`. The project is unofficial: never present it as an Anthropic product.
