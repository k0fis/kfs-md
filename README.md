# kfs-md

A native macOS Markdown and plain text viewer with a dark terminal aesthetic.

![macOS](https://img.shields.io/badge/macOS-13%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## Features

- **Markdown rendering** — headings, code blocks, tables, lists, blockquotes (GFM)
- **Plain text viewer** — monospace display for `.txt`, `.log`, `.nfo` files
- **Dark terminal theme** — dark navy background, green/cyan headings, JetBrains Mono font
- **View / Edit toggle** — switch with `Cmd+E`
- **Document-based** — native Open/Save, Recent Documents, tabs, drag & drop

## Install

### Homebrew

```bash
brew tap k0fis/tap
brew install --cask kfs-md
```

### Download

Grab the DMG from [Releases](https://github.com/k0fis/kfs-md/releases).

## Build from source

```bash
swift build
swift run
```

To create a proper `.app` bundle with Dock icon:

```bash
swift build -c release
# see .github/workflows/release.yml for bundle packaging steps
```

## Supported file types

| Extension | Display |
|-----------|---------|
| `.md`, `.markdown` | Rendered Markdown |
| `.txt`, `.log`, `.nfo`, `.cfg`, `.ini`, `.conf` | Monospace plain text |

## Keyboard shortcuts

| Shortcut | Action |
|----------|--------|
| `Cmd+E` | Toggle View / Edit mode |
| `Cmd+O` | Open file |
| `Cmd+S` | Save (in edit mode) |

## Screenshot

*Coming soon*

## License

MIT
