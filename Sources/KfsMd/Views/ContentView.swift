import SwiftUI

struct ContentView: View {
    @Binding var document: MarkdownDocument
    @State private var isEditing = false
    @State private var isSearching = false
    @State private var searchText = ""
    @State private var showGoToLine = false
    @State private var goToLineText = ""
    @State private var showLineNumbers = true
    @State private var scrollToLine: Int? = nil
    @State private var fontSize: CGFloat = 13

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

    var body: some View {
        VStack(spacing: 0) {
            if isSearching {
                SearchBarView(
                    searchText: $searchText,
                    matchCount: matchCount,
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
                    onGo: { line in
                        scrollToLine = line
                        showGoToLine = false
                        goToLineText = ""
                    },
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
                        showLineNumbers: showLineNumbers,
                        searchText: searchText
                    )
                } else if document.isMarkdown && !showLineNumbers {
                    MarkdownViewerView(text: document.text, fontSize: fontSize)
                } else {
                    PlainTextViewerView(
                        text: document.text,
                        searchText: searchText,
                        showLineNumbers: showLineNumbers,
                        fontSize: fontSize,
                        scrollToLine: $scrollToLine
                    )
                }
            }
        }
        .frame(minWidth: 500, minHeight: 400)
        .background(AppColors.background)
        // Mutual exclusivity: only one bar at a time
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
                    showGoToLine = true
                } label: {
                    Image(systemName: "arrow.right.to.line")
                }
                .keyboardShortcut("g", modifiers: .command)
                .help("Go to Line (⌘G)")
            }

            ToolbarItem(placement: .automatic) {
                Button {
                    showLineNumbers.toggle()
                } label: {
                    Image(systemName: showLineNumbers ? "list.number" : "list.bullet")
                }
                .help(showLineNumbers ? "Hide line numbers" : "Show line numbers")
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
