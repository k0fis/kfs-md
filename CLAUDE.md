# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**kfs-md** — nativní macOS viewer pro Markdown a plain text soubory. Tmavé terminálové téma, JetBrains Mono font. Jako `glow` v CLI, ale GUI.

Stack: **Swift 5.9+ / SwiftUI / MarkdownUI** (SPM package). Document-based app (`DocumentGroup`).

## Commands

```bash
swift build                      # Build (debug)
swift build -c release           # Build (release)
swift run                        # Run app (dev mode, no Dock icon)
open build/kfs-md.app            # Run as .app bundle (Dock icon works)
swift package resolve            # Resolve SPM dependencies
```

## Architecture

- **Document-based app**: `DocumentGroup` + `FileDocument` → automatický Open/Save, Recent Documents, tabs
- **Dva režimy zobrazení**: `.md` → MarkdownUI rendered, `.txt/.log/.nfo` → monospace plain text
- **View/Edit toggle**: Cmd+E přepíná mezi prohlížením a editací
- **Dark mode**: `.preferredColorScheme(.dark)` na root view
- **Search (Cmd+F)**: Search bar s počtem výskytů, case-insensitive. Žluté zvýraznění v plain text vieweru i editoru
- **Go to Line (Cmd+G)**: Skok na řádek s animací (plain text viewer)
- **Line numbers**: Toggleable čísla řádků v plain text vieweru (LazyVStack + gutter) i editoru (NSRulerView)
- **Zoom (Cmd+=/Cmd-)**: Změna velikosti fontu 9–36pt, proporcionální škálování headings v markdown

### Source Modules

| Soubor | Obsah |
|--------|-------|
| `Sources/KfsMd/KfsMdApp.swift` | @main, DocumentGroup, font registrace (Bundle.main → fallback SPM bundle) |
| `Sources/KfsMd/MarkdownDocument.swift` | FileDocument protocol, UTType routing |
| `Sources/KfsMd/Views/ContentView.swift` | Router: viewer vs editor, search/goToLine/zoom state, toolbar shortcuts |
| `Sources/KfsMd/Views/MarkdownViewerView.swift` | MarkdownUI rendered view s dynamickým fontSize |
| `Sources/KfsMd/Views/PlainTextViewerView.swift` | Monospace plain text view, line numbers, search highlighting, scroll-to-line |
| `Sources/KfsMd/Views/EditorView.swift` | NSViewRepresentable (NSTextView) s line number ruler a search highlighting |
| `Sources/KfsMd/Views/SearchBarView.swift` | SearchBarView (Cmd+F) a GoToLineBarView (Cmd+G) |
| `Sources/KfsMd/Theme/DarkTerminalTheme.swift` | Custom MarkdownUI theme, dynamický fontSize se škálováním |
| `Sources/KfsMd/Theme/AppColors.swift` | Barevná paleta |

### Gotchas

- **Font loading**: NEPOUŽÍVAT `Bundle.module` přímo — crashuje v .app bundlu. Kód v `KfsMdApp.swift` hledá fonty nejdřív v `Bundle.main` (pro .app), pak fallback na SPM resource bundle (pro `swift run`).
- **`swift run` vs `.app`**: `swift run` spouští bez Dock ikony a bez Info.plist file associations. Pro plný test vytvořit lokální .app bundle (viz `build/` adresář nebo CI workflow).
- **Gatekeeper**: Ad-hoc signed → po instalaci nutný `xattr -cr /Applications/kfs-md.app` nebo "Open Anyway" v System Settings → Privacy & Security.
- **EditorView je NSViewRepresentable**: Používá `NSTextView` (ne SwiftUI TextEditor) kvůli line number ruler a search highlighting přes `layoutManager.addTemporaryAttribute`. Koordinátor sleduje `textDidChange` a synchronizuje `@Binding var text`.
- **Keyboard shortcuts**: Řešené přes toolbar buttons s `.keyboardShortcut()`. FocusedBinding/FocusedValue nefungoval spolehlivě s DocumentGroup.

### Podporované formáty

| Přípona | Zobrazení |
|---------|-----------|
| `.md`, `.markdown` | MarkdownUI rendered |
| `.txt`, `.log`, `.nfo`, `.cfg`, `.ini`, `.conf` | Monospace plain text |

## CI/CD

| Workflow | Trigger | Výstup |
|----------|---------|--------|
| `release.yml` | tag `v*` | 1) Build → DMG → GitHub Release  2) Auto-update SHA256 v `k0fis/homebrew-tap` |

Release vyžaduje secret `DEPLOY_TOKEN` (GitHub PAT s repo scope pro push do homebrew-tap).

## Distribuce

```bash
# Release nové verze:
git tag v0.x.y && git push origin v0.x.y
# → CI automaticky: build → DMG → Release → aktualizace Homebrew cask

# Instalace:
brew tap k0fis/tap
brew install --cask kfs-md
```

## Dependency

Jediná: `gonzalezreal/swift-markdown-ui` 2.4+ (MarkdownUI).

## Plánované (v2+)

- Konverze kódování (CP850, CP852, CP1250) pro staré texty
- Syntax highlighting v code blocích
- Outline sidebar (obsah z headings)
