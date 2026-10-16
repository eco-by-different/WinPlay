![Repo size](https://img.shields.io/github/repo-size/eco-by-different/winplay)
![Last commit](https://img.shields.io/github/last-commit/eco-by-different/winplay)

# WinPlay

WinPlay is a tiny and minimalist media player built exclusively for Windows.

It uses the native Windows multimedia components, so no FFmpeg, external codecs, libraries, or installation are required.

## Screenshot

![WinPlay 1.0](WinPlay.png)

## Features

- Video and audio playback
- Drag and drop
- Play, pause, and stop
- Seek bar with playback time
- Volume control and mute
- Fullscreen mode
- Keyboard shortcuts
- Hardware-accelerated playback when supported by Windows
- Automatic sleep prevention during playback
- Compact dark interface
- Single portable executable

## Keyboard shortcuts

- `Space` – Play / Pause
- `Left` / `Right` – Seek 5 seconds
- `Up` / `Down` – Adjust volume
- `M` – Mute
- `F11` – Fullscreen
- `Esc` – Exit fullscreen
- `Ctrl+O` – Open media

## Requirements

- Windows 10 or Windows 11
- Windows PowerShell 5.1 for the script version
- Playback support depends on the codecs and multimedia components available in Windows

## Usage

Open a media file using the **OPEN** button or simply drag and drop it into the WinPlay window.

## Philosophy

WinPlay does not bundle its own playback engine. It provides a minimal interface for the multimedia capabilities already available in Windows.

Small application. Native Windows playback.
