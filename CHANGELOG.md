# Changelog

## Unreleased

- The menu has a **GitHub** item that opens the project's page.
- A window, opened at launch, from the Dock and from **Open window…** in the menu:
  **Status** (state, pause, today's count), **Activity** (each approval with its chat and
  request), **Chats** (skip a chat with a switch) and **Settings** (open at login, the
  buttons to press, the log). Closing it keeps the app in the menu bar.
- The log records the chat and the request of each approval.
- The menu bar icon starts next to the clock, so a notch no longer hides it.

## 1.0.1

- New app icon: a woodpecker, made in Icon Composer, so macOS 26 shows it in Liquid Glass.
  The README banner shows it too.

## 1.0.0

First release as **Claude Code - Auto Approver**.

- Presses **Allow once** in the Claude desktop app, in its window and on its notification
  banners, through Accessibility. Never **Always allow**.
- Recognises the button in every language the Claude app speaks; the app's own interface
  is in English, Italian, German, Spanish, French, Portuguese and Japanese.
- Labels to press can be replaced in `labels.txt` without a restart.
- Pauses for 5 min to 6 h, or until resumed, from the menu bar.
- Leaves the prompts of chosen chats to you, picked from the menu bar.
- Keeps the Mac from idle sleep while on; logs screen lock and unlock.
- Template menu bar icon; app icon in the macOS glass style.
- Swift package with a tested core, build and install scripts, CI and tagged releases.
