# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**kfs-md** — nativní macOS viewer pro Markdown a plain text soubory. Tmavé terminálové téma, JetBrains Mono font. Jako `glow` v CLI, ale GUI.

Stack: **Swift 5.9+ / SwiftUI / MarkdownUI** (SPM package). Document-based app (`DocumentGroup`).

## Commands

```bash
swift build                      # Build (debug)
swift build -c release           # Build (release)
swift run                        # Run app
swift package resolve            # Resolve SPM dependencies
```

## Architecture

- **Document-based app**: `DocumentGroup` + `FileDocument` → automatický Open/Save, Recent Documents, tabs
- **Dva režimy zobrazení**: `.md` → MarkdownUI rendered, `.txt/.log/.nfo` → monospace plain text
- **View/Edit toggle**: Cmd+E přepíná mezi prohlížením a editací
- **Dark mode enforced**: `NSApp.appearance = .darkAqua`

### Source Modules

| Soubor | Obsah |
|--------|-------|
| `Sources/KfsMd/KfsMdApp.swift` | @main, DocumentGroup, font registrace |
| `Sources/KfsMd/MarkdownDocument.swift` | FileDocument protocol, UTType routing |
| `Sources/KfsMd/Views/ContentView.swift` | Router: viewer vs editor, mode toggle |
| `Sources/KfsMd/Views/MarkdownViewerView.swift` | MarkdownUI rendered view |
| `Sources/KfsMd/Views/PlainTextViewerView.swift` | Monospace plain text view |
| `Sources/KfsMd/Views/EditorView.swift` | TextEditor pro raw editaci |
| `Sources/KfsMd/Theme/DarkTerminalTheme.swift` | Custom MarkdownUI theme |
| `Sources/KfsMd/Theme/AppColors.swift` | Barevná paleta |

### Podporované formáty

| Přípona | Zobrazení |
|---------|-----------|
| `.md`, `.markdown` | MarkdownUI rendered |
| `.txt`, `.log`, `.nfo`, `.cfg`, `.ini`, `.conf` | Monospace plain text |

## CI/CD

| Workflow | Trigger | Výstup |
|----------|---------|--------|
| `release.yml` | tag `v*` | macOS DMG → GitHub Release |

## Dependency

Jediná: `gonzalezreal/swift-markdown-ui` 2.4+ (MarkdownUI).

## Plánované (v2+)

- Konverze kódování (CP850, CP852, CP1250) pro staré texty
- Syntax highlighting v code blocích
