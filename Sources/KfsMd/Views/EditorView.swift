import SwiftUI
import AppKit

struct EditorView: NSViewRepresentable {
    @Binding var text: String
    let fontSize: CGFloat
    let searchText: String
    let currentMatchIndex: Int
    let highlightedLine: Int?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        guard let textView = scrollView.documentView as? NSTextView else {
            return scrollView
        }

        // Force TextKit 1 — accessing layoutManager triggers compatibility switch from TextKit 2
        _ = textView.layoutManager

        let font = NSFont(name: "JetBrains Mono", size: fontSize)
            ?? .monospacedSystemFont(ofSize: fontSize, weight: .regular)
        textView.font = font
        textView.textColor = NSColor(AppColors.textPrimary)
        textView.backgroundColor = NSColor(AppColors.background)
        textView.insertionPointColor = .white
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.isRichText = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.textContainerInset = NSSize(width: 16, height: 16)
        textView.usesFindBar = false
        textView.string = text
        textView.delegate = context.coordinator
        context.coordinator.textView = textView

        scrollView.drawsBackground = false

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }

        // Update text only if changed externally (not by user typing)
        if context.coordinator.updatedByUser {
            context.coordinator.updatedByUser = false
        } else if textView.string != text {
            textView.string = text
        }

        // Font
        let font = NSFont(name: "JetBrains Mono", size: fontSize)
            ?? .monospacedSystemFont(ofSize: fontSize, weight: .regular)
        if textView.font != font {
            textView.font = font
        }

        // Search highlighting (clears all temp attributes first)
        let shouldScrollSearch = context.coordinator.lastMatchIndex != currentMatchIndex
            || context.coordinator.lastSearchText != searchText
        highlightSearch(in: textView, scrollToMatch: shouldScrollSearch)
        context.coordinator.lastMatchIndex = currentMatchIndex
        context.coordinator.lastSearchText = searchText

        // Go-to-line highlighting (applied after search, so it's on top)
        let goToChanged = highlightedLine != context.coordinator.lastHighlightedLine
        if let line = highlightedLine {
            highlightGoToLine(line, in: textView, scroll: goToChanged)
        }
        context.coordinator.lastHighlightedLine = highlightedLine
    }

    private func highlightSearch(in textView: NSTextView, scrollToMatch: Bool) {
        guard let layoutManager = textView.layoutManager else { return }
        let nsString = textView.string as NSString
        let fullRange = NSRange(location: 0, length: nsString.length)
        layoutManager.removeTemporaryAttribute(.backgroundColor, forCharacterRange: fullRange)
        layoutManager.removeTemporaryAttribute(.foregroundColor, forCharacterRange: fullRange)

        guard !searchText.isEmpty else { return }

        let highlightColor = NSColor(AppColors.searchHighlight)
        let currentColor = NSColor(AppColors.currentMatchHighlight)
        var searchRange = NSRange(location: 0, length: nsString.length)
        var matchIndex = 0

        while searchRange.location < nsString.length {
            let found = nsString.range(of: searchText, options: .caseInsensitive, range: searchRange)
            guard found.location != NSNotFound else { break }

            let isCurrent = matchIndex == currentMatchIndex
            let bgColor = isCurrent ? currentColor : highlightColor
            layoutManager.addTemporaryAttribute(.backgroundColor, value: bgColor, forCharacterRange: found)
            layoutManager.addTemporaryAttribute(.foregroundColor, value: NSColor.black, forCharacterRange: found)

            if isCurrent && scrollToMatch {
                textView.scrollRangeToVisible(found)
            }

            searchRange.location = found.location + found.length
            searchRange.length = nsString.length - searchRange.location
            matchIndex += 1
        }
    }

    private func highlightGoToLine(_ lineNumber: Int, in textView: NSTextView, scroll: Bool) {
        guard let layoutManager = textView.layoutManager else { return }
        let nsString = textView.string as NSString
        guard nsString.length > 0 else { return }

        // Find the NSRange for the target line
        var currentLine = 1
        var index = 0

        while index < nsString.length && currentLine < lineNumber {
            let lineRange = nsString.lineRange(for: NSRange(location: index, length: 0))
            index = NSMaxRange(lineRange)
            currentLine += 1
        }

        guard currentLine == lineNumber else { return }
        let lineRange = nsString.lineRange(for: NSRange(location: min(index, nsString.length - 1), length: 0))

        let highlightColor = NSColor(AppColors.goToLineHighlight)
        layoutManager.addTemporaryAttribute(.backgroundColor, value: highlightColor, forCharacterRange: lineRange)

        if scroll {
            textView.scrollRangeToVisible(lineRange)
        }
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: EditorView
        weak var textView: NSTextView?
        var updatedByUser = false
        var lastMatchIndex = -1
        var lastSearchText = ""
        var lastHighlightedLine: Int? = nil

        init(_ parent: EditorView) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            updatedByUser = true
            parent.text = textView.string
        }
    }
}
