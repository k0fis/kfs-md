import SwiftUI

// MARK: - Focused value keys for menu commands

private struct FocusedSearchKey: FocusedValueKey {
    typealias Value = Binding<Bool>
}

private struct FocusedGoToLineKey: FocusedValueKey {
    typealias Value = Binding<Bool>
}

extension FocusedValues {
    var isSearchActive: Binding<Bool>? {
        get { self[FocusedSearchKey.self] }
        set { self[FocusedSearchKey.self] = newValue }
    }
    var isGoToLineActive: Binding<Bool>? {
        get { self[FocusedGoToLineKey.self] }
        set { self[FocusedGoToLineKey.self] = newValue }
    }
}

// MARK: - ContentView

struct ContentView: View {
    @Binding var document: MarkdownDocument
    @State private var isEditing = false
    @State private var isSearching = false
    @State private var searchText = ""
    @State private var showGoToLine = false
    @State private var goToLineText = ""
    @State private var showLineNumbers = true
    @State private var scrollToLine: Int? = nil

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
                    EditorView(text: $document.text)
                } else if document.isMarkdown {
                    MarkdownViewerView(text: document.text)
                } else {
                    PlainTextViewerView(
                        text: document.text,
                        searchText: searchText,
                        showLineNumbers: showLineNumbers,
                        scrollToLine: $scrollToLine
                    )
                }
            }
        }
        .frame(minWidth: 500, minHeight: 400)
        .background(AppColors.background)
        .focusedValue(\.isSearchActive, $isSearching)
        .focusedValue(\.isGoToLineActive, $showGoToLine)
        // Mutual exclusivity: only one bar at a time
        .onChange(of: isSearching) { newValue in
            if newValue { showGoToLine = false; goToLineText = "" }
        }
        .onChange(of: showGoToLine) { newValue in
            if newValue { isSearching = false; searchText = "" }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isEditing.toggle()
                } label: {
                    Image(systemName: isEditing ? "eye" : "pencil")
                    Text(isEditing ? "View" : "Edit")
                }
                .keyboardShortcut("e", modifiers: .command)
            }

            ToolbarItem(placement: .automatic) {
                Button {
                    showLineNumbers.toggle()
                } label: {
                    Image(systemName: showLineNumbers ? "list.number" : "list.bullet")
                }
                .help(showLineNumbers ? "Hide line numbers" : "Show line numbers")
            }
        }
    }
}
