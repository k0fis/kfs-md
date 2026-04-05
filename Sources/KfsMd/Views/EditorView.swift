import SwiftUI
import AppKit

struct EditorView: NSViewRepresentable {
    @Binding var text: String
    let fontSize: CGFloat
    let searchText: String
    let currentMatchIndex: Int

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

        // Search highlighting
        let shouldScroll = context.coordinator.lastMatchIndex != currentMatchIndex
            || context.coordinator.lastSearchText != searchText
        highlightSearch(in: textView, scrollToMatch: shouldScroll)
        context.coordinator.lastMatchIndex = currentMatchIndex
        context.coordinator.lastSearchText = searchText
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

    // MARK: - Coordinator

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: EditorView
        weak var textView: NSTextView?
        var updatedByUser = false
        var lastMatchIndex = -1
        var lastSearchText = ""

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
