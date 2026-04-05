import SwiftUI
import AppKit

struct ContentView: View {
    @Binding var document: MarkdownDocument
    @State private var isEditing = false
    @State private var isSearching = false
    @State private var searchText = ""
    @State private var currentMatchIndex = 0
    @State private var fontSize: CGFloat = 13

    private var matchCount: Int {
        guard !searchText.isEmpty else { return 0 }
        var count = 0
        var start = document.text.startIndex
        while start < document.text.endIndex,
              let range = document.text.range(of: searchText, options: .caseInsensitive, range: start..<document.text.endIndex) {
            count += 1
            start = range.upperBound
        }
        return count
    }

    private func nextMatch() {
        guard matchCount > 0 else { return }
        currentMatchIndex = (currentMatchIndex + 1) % matchCount
    }

    private func prevMatch() {
        guard matchCount > 0 else { return }
        currentMatchIndex = (currentMatchIndex - 1 + matchCount) % matchCount
    }

    var body: some View {
        VStack(spacing: 0) {
            if isSearching {
                SearchBarView(
                    searchText: $searchText,
                    matchCount: matchCount,
                    currentMatch: currentMatchIndex,
                    onNext: nextMatch,
                    onPrev: prevMatch,
                    onClose: {
                        isSearching = false
                        searchText = ""
                    }
                )
            }

            Group {
                if isEditing {
                    EditorView(
                        text: $document.text,
                        fontSize: fontSize,
                        searchText: searchText,
                        currentMatchIndex: currentMatchIndex
                    )
                } else if document.isMarkdown {
                    MarkdownViewerView(text: document.text, fontSize: fontSize)
                } else {
                    PlainTextViewerView(
                        text: document.text,
                        searchText: searchText,
                        fontSize: fontSize,
                        currentMatchIndex: currentMatchIndex
                    )
                }
            }
        }
        .frame(minWidth: 500, minHeight: 400)
        .background(AppColors.background)
        .background(
            ViewModeKeyHandler(
                onSlash: { isSearching = true },
                onN: nextMatch,
                onP: prevMatch
            )
            .frame(width: 0, height: 0)
        )
        .onChange(of: searchText) { _ in
            currentMatchIndex = 0
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    isSearching = true
                } label: {
                    Image(systemName: "magnifyingglass")
                }
                .keyboardShortcut("f", modifiers: .command)
                .help("Find (⌘F)")
            }

            ToolbarItem(placement: .automatic) {
                Button {
                    fontSize = max(fontSize - 1, 9)
                } label: {
                    Image(systemName: "minus.magnifyingglass")
                }
                .keyboardShortcut("-", modifiers: .command)
                .help("Zoom Out (⌘-)")
            }

            ToolbarItem(placement: .automatic) {
                Button {
                    fontSize = min(fontSize + 1, 36)
                } label: {
                    Image(systemName: "plus.magnifyingglass")
                }
                .keyboardShortcut("=", modifiers: .command)
                .help("Zoom In (⌘+)")
            }

            ToolbarItem(placement: .primaryAction) {
                Button {
                    isEditing.toggle()
                } label: {
                    Image(systemName: isEditing ? "eye" : "pencil")
                    Text(isEditing ? "View" : "Edit")
                }
                .keyboardShortcut("e", modifiers: .command)
            }
        }
    }
}

// MARK: - View Mode Key Handler

struct ViewModeKeyHandler: NSViewRepresentable {
    let onSlash: () -> Void
    let onN: () -> Void
    let onP: () -> Void

    func makeNSView(context: Context) -> NSView {
        let view = KeyHandlerView()
        view.onSlash = onSlash
        view.onN = onN
        view.onP = onP
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        guard let view = nsView as? KeyHandlerView else { return }
        view.onSlash = onSlash
        view.onN = onN
        view.onP = onP
    }

    class KeyHandlerView: NSView {
        var onSlash: (() -> Void)?
        var onN: (() -> Void)?
        var onP: (() -> Void)?
        private var monitor: Any?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            if window != nil && monitor == nil {
                monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                    guard let self = self,
                          event.window == self.window else { return event }

                    // Don't intercept when typing in an editable text field/editor
                    if let responder = event.window?.firstResponder as? NSText,
                       responder.isEditable {
                        return event
                    }

                    let significantFlags: NSEvent.ModifierFlags = [.command, .shift, .control, .option]
                    guard event.modifierFlags.intersection(significantFlags).isEmpty else {
                        return event
                    }

                    switch event.charactersIgnoringModifiers {
                    case "/":
                        self.onSlash?()
                        return nil
                    case "n":
                        self.onN?()
                        return nil
                    case "p":
                        self.onP?()
                        return nil
                    default:
                        return event
                    }
                }
            } else if window == nil, let monitor = monitor {
                NSEvent.removeMonitor(monitor)
                self.monitor = nil
            }
        }

        deinit {
            if let monitor = monitor {
                NSEvent.removeMonitor(monitor)
            }
        }
    }
}
