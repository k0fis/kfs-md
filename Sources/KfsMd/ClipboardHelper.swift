import AppKit
import cmark_gfm
import cmark_gfm_extensions

enum ClipboardHelper {

    /// Copy markdown text as formatted rich text (RTF) to the clipboard.
    /// Falls back to plain text if conversion fails.
    static func copyFormatted(markdown: String) {
        let html = markdownToHTML(markdown)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        if let htmlData = html.data(using: .utf8),
           let attributed = NSAttributedString(
               html: htmlData,
               options: [.documentType: NSAttributedString.DocumentType.html,
                         .characterEncoding: String.Encoding.utf8.rawValue],
               documentAttributes: nil
           ),
           let rtfData = attributed.rtf(from: NSRange(location: 0, length: attributed.length)) {
            pasteboard.setData(rtfData, forType: .rtf)
            pasteboard.setString(markdown, forType: .string)
        } else {
            pasteboard.setString(markdown, forType: .string)
        }
    }

    private static func markdownToHTML(_ markdown: String) -> String {
        cmark_gfm_core_extensions_ensure_registered()

        guard let parser = cmark_parser_new(CMARK_OPT_DEFAULT) else {
            return wrapPlainHTML(markdown)
        }
        defer { cmark_parser_free(parser) }

        let extensions = ["table", "strikethrough", "autolink", "tasklist"]
        for name in extensions {
            if let ext = cmark_find_syntax_extension(name) {
                cmark_parser_attach_syntax_extension(parser, ext)
            }
        }

        cmark_parser_feed(parser, markdown, markdown.utf8.count)
        guard let doc = cmark_parser_finish(parser) else {
            return wrapPlainHTML(markdown)
        }
        defer { cmark_node_free(doc) }

        guard let rawHTML = cmark_render_html(doc, CMARK_OPT_DEFAULT, cmark_parser_get_syntax_extensions(parser)) else {
            return wrapPlainHTML(markdown)
        }

        let body = String(cString: rawHTML)
        free(rawHTML)

        return """
        <html><head><meta charset="utf-8"><style>
        body { font-family: -apple-system, Helvetica, Arial, sans-serif; font-size: 13px; }
        code { font-family: 'JetBrains Mono', Menlo, monospace; background: #f0f0f0; padding: 1px 4px; border-radius: 3px; }
        pre { background: #f5f5f5; padding: 10px; border-radius: 5px; overflow-x: auto; }
        pre code { background: none; padding: 0; }
        blockquote { border-left: 3px solid #ccc; margin-left: 0; padding-left: 12px; color: #555; }
        table { border-collapse: collapse; }
        th, td { border: 1px solid #ddd; padding: 6px 10px; }
        th { background: #f5f5f5; }
        </style></head><body>\(body)</body></html>
        """
    }

    private static func wrapPlainHTML(_ text: String) -> String {
        let escaped = text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
        return "<html><body><pre>\(escaped)</pre></body></html>"
    }
}
