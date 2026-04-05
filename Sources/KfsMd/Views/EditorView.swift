import SwiftUI
import AppKit

struct EditorView: NSViewRepresentable {
    @Binding var text: String
    let fontSize: CGFloat
    let showLineNumbers: Bool
    let searchText: String

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

        // Line number ruler
        let ruler = LineNumberRulerView(textView: textView, scrollView: scrollView, fontSize: fontSize)
        scrollView.verticalRulerView = ruler
        scrollView.hasVerticalRuler = true
        scrollView.rulersVisible = showLineNumbers
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

        // Ruler
        scrollView.rulersVisible = showLineNumbers
        if let ruler = scrollView.verticalRulerView as? LineNumberRulerView {
            ruler.fontSize = fontSize
            ruler.updateThickness(for: textView.string)
            ruler.needsDisplay = true
        }

        // Search highlighting
        highlightSearch(in: textView)
    }

    private func highlightSearch(in textView: NSTextView) {
        guard let layoutManager = textView.layoutManager else { return }
        let nsString = textView.string as NSString
        let fullRange = NSRange(location: 0, length: nsString.length)
        layoutManager.removeTemporaryAttribute(.backgroundColor, forCharacterRange: fullRange)
        layoutManager.removeTemporaryAttribute(.foregroundColor, forCharacterRange: fullRange)

        guard !searchText.isEmpty else { return }

        let highlightColor = NSColor(AppColors.searchHighlight)
        var searchRange = NSRange(location: 0, length: nsString.length)

        while searchRange.location < nsString.length {
            let found = nsString.range(of: searchText, options: .caseInsensitive, range: searchRange)
            guard found.location != NSNotFound else { break }

            layoutManager.addTemporaryAttribute(.backgroundColor, value: highlightColor, forCharacterRange: found)
            layoutManager.addTemporaryAttribute(.foregroundColor, value: NSColor.black, forCharacterRange: found)

            searchRange.location = found.location + found.length
            searchRange.length = nsString.length - searchRange.location
        }
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: EditorView
        weak var textView: NSTextView?
        var updatedByUser = false

        init(_ parent: EditorView) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            updatedByUser = true
            parent.text = textView.string

            if let scrollView = textView.enclosingScrollView,
               let ruler = scrollView.verticalRulerView as? LineNumberRulerView {
                ruler.updateThickness(for: textView.string)
                ruler.needsDisplay = true
            }
        }
    }
}

// MARK: - Line Number Ruler

class LineNumberRulerView: NSRulerView {
    var fontSize: CGFloat
    private weak var textView: NSTextView?

    init(textView: NSTextView, scrollView: NSScrollView, fontSize: CGFloat) {
        self.textView = textView
        self.fontSize = fontSize
        super.init(scrollView: scrollView, orientation: .verticalRuler)
        self.clientView = textView
        updateThickness(for: textView.string)

        NotificationCenter.default.addObserver(
            self, selector: #selector(needsRedisplay),
            name: NSText.didChangeNotification, object: textView
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(needsRedisplay),
            name: NSView.boundsDidChangeNotification,
            object: scrollView.contentView
        )
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    func updateThickness(for text: String) {
        let lineCount = text.components(separatedBy: "\n").count
        let digits = max(String(lineCount).count, 2)
        ruleThickness = CGFloat(digits) * 8 + 20
    }

    @objc private func needsRedisplay() {
        needsDisplay = true
    }

    override func drawHashMarksAndLabels(in rect: NSRect) {
        guard let textView = textView,
              let layoutManager = textView.layoutManager,
              let textContainer = textView.textContainer else { return }

        // Background
        NSColor(AppColors.background).set()
        rect.fill()

        // Separator
        NSColor.white.withAlphaComponent(0.15).set()
        let sepRect = NSRect(x: ruleThickness - 1, y: rect.origin.y, width: 1, height: rect.height)
        sepRect.fill()

        let font = NSFont(name: "JetBrains Mono", size: fontSize - 1)
            ?? .monospacedSystemFont(ofSize: fontSize - 1, weight: .regular)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.white.withAlphaComponent(0.40)
        ]

        let visibleRect = textView.visibleRect
        let glyphRange = layoutManager.glyphRange(forBoundingRect: visibleRect, in: textContainer)
        let charRange = layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
        let nsString = textView.string as NSString

        // Count lines before visible range
        var lineNumber = 1
        if charRange.location > 0 {
            let pre = nsString.substring(to: charRange.location)
            lineNumber = pre.components(separatedBy: "\n").count
        }

        // Draw visible lines
        var index = charRange.location
        while index <= NSMaxRange(charRange) && index < nsString.length {
            let lineRange = nsString.lineRange(for: NSRange(location: index, length: 0))
            let lineGlyphRange = layoutManager.glyphRange(forCharacterRange: lineRange, actualCharacterRange: nil)
            var lineRect = layoutManager.boundingRect(forGlyphRange: lineGlyphRange, in: textContainer)

            lineRect.origin.y += textView.textContainerInset.height - visibleRect.origin.y

            let lineStr = "\(lineNumber)" as NSString
            let size = lineStr.size(withAttributes: attrs)
            let x = ruleThickness - size.width - 8
            let y = lineRect.origin.y + (lineRect.height - size.height) / 2

            lineStr.draw(at: NSPoint(x: x, y: y), withAttributes: attrs)

            lineNumber += 1
            index = NSMaxRange(lineRange)
        }
    }
}
