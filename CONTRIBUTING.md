# Contributing

Thanks for helping. Bug reports, label translations and fixes for new Claude app layouts are
the most useful contributions.

1. Read [AGENTS.md](AGENTS.md): the layout, the commands and the safety rules every change
   keeps. The app presses **Allow once** and nothing else.
2. Put logic in `macos/sources/core/` with a test, and keep `macos/sources/app/` to reading
   the screen and the disk.
3. Run `cd macos && swift test` and `scripts/build-app.sh` before opening a pull request.
4. Translate new menu text into all seven languages.
5. Write commit messages as [Conventional Commits](https://www.conventionalcommits.org/),
   for example `fix(core): stop the window walk from running twice`. The types and scopes
   are listed in [AGENTS.md](AGENTS.md#commits).

A change to how the Claude window or its notifications are read needs a log excerpt or an
Accessibility dump showing the layout it relies on.
