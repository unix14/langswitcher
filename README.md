# LangSwitcher v1.4

> A lightweight, blazing-fast macOS menu bar utility that instantly converts text typed in the wrong keyboard layout between **English** and **Hebrew** (Israeli SI-1452 layout). Developed by Eyal Yaakobi.

<p align="center">
  <img src="LangSwitcher/Assets.xcassets/AppIcon.appiconset/icon_128x128.png" width="128" alt="LangSwitcher Icon" />
</p>

---

## Features

- **Global Activation**: Simply highlight your text and press `⌘⇧L` (Cmd+Shift+L).
- **Intelligent Heuristics**: Automatically detects language majority and translates in the correct direction (Hebrew ⇄ English).
- **Grammatically Correct Hebrew**: Seamlessly applies Hebrew final-form letters (`מ↔ם`, `נ↔ן`, `כ↔ך`, `פ↔ף`, `צ↔ץ`) depending on word boundaries.
- **Smart Formatting Injection**: Uses native macOS CoreGraphics events (`CGEvent`) to type translated text directly, avoiding the newline-doubling issues caused by standard clipboard pasting in apps like Slack, Discord, and WhatsApp.
- **Rich Dark Aesthetics**: Features a polished dark-themed interface with diagonal gradients and a clean status bar indicator (`A⇄א`).
- **Fully Native & Lightweight**: Zero external dependencies, zero SPM/CocoaPods, built purely with Swift, AppKit, and Carbon.

---

## Installation

### 1. Via Homebrew (Recommended)

You can tap the repository and install the application directly via Homebrew Cask:

```bash
# Tap the repository
brew tap unix14/tap

# Install LangSwitcher Cask
brew install --cask langswitcher
```

> [!NOTE]
> **Tap Trust & Overwrite Conflicts:**
> - **Untrusted Tap**: Since this is a personal third-party tap, Homebrew may require you to trust it first. If prompted, run `brew trust unix14/tap` and rerun the install command.
> - **Existing App Conflict**: If you already have a manual or compiled installation at `/Applications/LangSwitcher.app`, Homebrew will refuse to overwrite it by default. You can force Homebrew to overwrite it by adding the `--force` flag:
>   ```bash
>   brew install --cask --force langswitcher
>   ```

### 2. Manual Installation

1. Navigate to the [Releases](https://github.com/unix14/langswitcher/releases) section.
2. Download `LangSwitcher-1.4.dmg`.
3. Open the DMG and drag **LangSwitcher.app** into your `/Applications` directory.

---

## How It Works

1. **Selection Conversion**:
   - Select any text typed in the wrong layout (e.g., `jnho` instead of `חמים`).
   - Press the global hotkey `⌘⇧L`.
   - The app copies the text, translates the layout, and types it back in place.
2. **Layout Translation Rules**:
   - If no selection is active, it falls back to a select-all (`⌘A` + `⌘C`) of the current text box.
   - Text inputs are lowercased when mapping Latin input to Hebrew.

### Mapping Examples

| Input (Wrong Layout) | Output (Corrected Layout) |
| -------------------- | ------------------------- |
| `jnho`               | `חמים`                    |
| `HAHA`               | `ישיש`                    |
| `Hello`              | `יקככם`                   |
| `haha`               | `ישיש`                    |
| `ישיש`               | `haha`                    |
| `חמים`               | `john`                    |

---

## Setup & Accessibility

To allow **LangSwitcher** to automatically capture and correct text inside other apps, it requires Accessibility permissions. 

1. On the first launch, macOS will prompt you to authorize the app.
2. Go to **System Settings ➔ Privacy & Security ➔ Accessibility**.
3. Toggle the switch next to **LangSwitcher** to enable access.
4. If you ever need to configure it, click the status bar icon (`A⇄א`) and select **Settings…** or use the shortcut `⌘,`.

### macOS Gatekeeper Security Notice

Because LangSwitcher is compiled and signed locally (ad-hoc) without an active Apple Developer ID, macOS Gatekeeper may show a warning on first launch:
> *"Apple could not verify LangSwitcher is free of malware..."*

To open it safely:
1. **Right-click** (or Control-click) `LangSwitcher.app` in your `/Applications` directory.
2. Select **Open** from the context menu.
3. Click **Open** in the confirmation dialog. (You will only need to do this once).

---

## Development & Compilation

To compile or customize the application locally:

- **Generate Icons**:
  ```bash
  swift scripts/make_icon.swift
  ```
- **Install & Relaunch**:
  ```bash
  bash scripts/install.sh
  ```
- **Package Release DMG**:
  ```bash
  bash scripts/build_dmg.sh
  ```

---

## License & Attribution

Created by **Eyal Yaakobi** (© 2026). All rights reserved. 
