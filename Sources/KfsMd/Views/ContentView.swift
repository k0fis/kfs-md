import SwiftUI
import AppKit

struct ContentView: View {
    @Binding var document: MarkdownDocument
    @State private var isEditing = false
    @State private var isSearching = false
    @State private var searchText = ""
    @State private var currentMatchIndex = 0
    @State private var showGoToLine = false
    @State private var goToLineText = ""
    @State private var highlightedLine: Int? = nil
    @State private var highlightGeneration = 0
    @State private var fontSize: CGFloat = 13
    @State private var renderMarkdown: Bool? = nil  // nil = auto (based on file type)
    @State private var showCopiedFeedback = false
    @State private var showJiraCopiedFeedback = false

    private var isRenderedMarkdown: Bool {
        renderMarkdown ?? document.isMarkdown
    }

    private var totalLines: Int {
        document.text.components(separatedBy: "\n").count
    }

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

    private func goToLine(_ line: Int) {
        let gen = highlightGeneration + 1
        highlightGeneration = gen
        highlightedLine = line
        showGoToLine = false
        goToLineText = ""
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if highlightGeneration == gen {
                highlightedLine = nil
            }
        }
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

            if showGoToLine {
                GoToLineBarView(
                    lineText: $goToLineText,
                    totalLines: totalLines,
                    onGo: goToLine,
                    onClose: {
                        showGoToLine = false
                        goToLineText = ""
                    }
                )
            }

            Group {
                if isEditing {
                    EditorView(
                        text: $document.text,
                        fontSize: fontSize,
                        searchText: searchText,
                        currentMatchIndex: currentMatchIndex,
                        highlightedLine: highlightedLine
                    )
                } else if isRenderedMarkdown {
                    MarkdownViewerView(
                        text: document.text,
                        fontSize: fontSize,
                        searchText: searchText,
                        currentMatchIndex: currentMatchIndex,
                        highlightedLine: highlightedLine
                    )
                } else {
                    PlainTextViewerView(
                        text: document.text,
                        searchText: searchText,
                        fontSize: fontSize,
                        currentMatchIndex: currentMatchIndex,
                        highlightedLine: highlightedLine
                    )
                }
            }
        }
        .frame(minWidth: 500, minHeight: 400)
        .background(AppColors.background)
        .background(
            ViewModeKeyHandler(
                onSlash: { isSearching = true }
            )
            .frame(width: 0, height: 0)
        )
        .onChange(of: searchText) { _ in
            currentMatchIndex = 0
        }
        .onChange(of: isSearching) { newValue in
            if newValue { showGoToLine = false; goToLineText = "" }
        }
        .onChange(of: showGoToLine) { newValue in
            if newValue { isSearching = false; searchText = "" }
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
                    ClipboardHelper.copyFormatted(markdown: document.text)
                    showCopiedFeedback = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        showCopiedFeedback = false
                    }
                } label: {
                    Image(systemName: showCopiedFeedback ? "checkmark" : "doc.on.clipboard")
                }
                .keyboardShortcut("c", modifiers: [.command, .shift])
                .help("Copy Formatted (⌘⇧C)")
            }

            ToolbarItem(placement: .automatic) {
                Button {
                    ClipboardHelper.copyAsJira(markdown: document.text)
                    showJiraCopiedFeedback = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        showJiraCopiedFeedback = false
                    }
                } label: {
                    Image(systemName: showJiraCopiedFeedback ? "checkmark" : "ticket")
                }
                .keyboardShortcut("j", modifiers: [.command, .shift])
                .help("Copy as Jira (⌘⇧J)")
            }

            ToolbarItem(placement: .automatic) {
                Button {
                    showGoToLine = true
                } label: {
                    Image(systemName: "arrow.right.to.line")
                }
                .keyboardShortcut("l", modifiers: .command)
                .help("Go to Line (⌘L)")
            }

            ToolbarItem(placement: .automatic) {
                Button {
                    renderMarkdown = !isRenderedMarkdown
                } label: {
                    Image(systemName: isRenderedMarkdown ? "doc.plaintext" : "doc.richtext")
                }
                .help(isRenderedMarkdown ? "Plain text" : "Rendered markdown")
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
                .help(isEditing ? "View Mode (⌘E)" : "Edit Mode (⌘E)")
            }
        }
    }
}

// MARK: - View Mode Key Handler

struct ViewModeKeyHandler: NSViewRepresentable {
    let onSlash: () -> Void

    func makeNSView(context: Context) -> NSView {
        let view = KeyHandlerView()
        view.onSlash = onSlash
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        guard let view = nsView as? KeyHandlerView else { return }
        view.onSlash = onSlash
    }

    class KeyHandlerView: NSView {
        var onSlash: (() -> Void)?
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

                    if event.charactersIgnoringModifiers == "/" {
                        self.onSlash?()
                        return nil
                    }
                    return event
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
