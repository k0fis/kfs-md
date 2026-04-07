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

    /// Copy markdown text as Jira wiki markup (plain text) to the clipboard.
    static func copyAsJira(markdown: String) {
        let jira = markdownToJira(markdown)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(jira, forType: .string)
    }

    // MARK: - Markdown → Jira Wiki Markup

    private static func markdownToJira(_ markdown: String) -> String {
        let lines = markdown.components(separatedBy: "\n")
        var result: [String] = []
        var i = 0
        var inCodeBlock = false

        while i < lines.count {
            let line = lines[i]
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)

            // Fenced code blocks
            if trimmedLine.hasPrefix("```") {
                if inCodeBlock {
                    result.append("{code}")
                    inCodeBlock = false
                } else {
                    let lang = String(trimmedLine.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                    result.append(lang.isEmpty ? "{code}" : "{code:\(lang)}")
                    inCodeBlock = true
                }
                i += 1
                continue
            }

            if inCodeBlock {
                result.append(line)
                i += 1
                continue
            }

            // Horizontal rule (before list check — `* * *` looks like a list item)
            if line.range(of: #"^\s*(-\s*){3,}$|^\s*(\*\s*){3,}$|^\s*(_\s*){3,}$"#, options: .regularExpression) != nil {
                result.append("----")
                i += 1
                continue
            }

            // Table separator → skip
            if line.range(of: #"^\|[\s:|-]+\|$"#, options: .regularExpression) != nil {
                i += 1
                continue
            }

            // Table rows
            if trimmedLine.hasPrefix("|") && trimmedLine.hasSuffix("|") && trimmedLine.count > 1 {
                let isHeader = (i + 1 < lines.count) &&
                    lines[i + 1].range(of: #"^\|[\s:|-]+\|$"#, options: .regularExpression) != nil
                let cells = trimmedLine
                    .dropFirst().dropLast()
                    .components(separatedBy: "|")
                    .map { convertJiraInline($0.trimmingCharacters(in: .whitespaces)) }
                if isHeader {
                    result.append("||" + cells.joined(separator: "||") + "||")
                } else {
                    result.append("|" + cells.joined(separator: "|") + "|")
                }
                i += 1
                continue
            }

            // Headings
            if line.range(of: #"^#{1,6}\s+"#, options: .regularExpression) != nil {
                let hashes = line.prefix(while: { $0 == "#" })
                let text = String(line[hashes.endIndex...])
                    .trimmingCharacters(in: .whitespaces)
                    .replacingOccurrences(of: #"\s*#+\s*$"#, with: "", options: .regularExpression)
                result.append("h\(hashes.count). \(convertJiraInline(text))")
                i += 1
                continue
            }

            // Blockquote
            if trimmedLine.hasPrefix(">") {
                result.append("{quote}")
                while i < lines.count && lines[i].trimmingCharacters(in: .whitespaces).hasPrefix(">") {
                    var l = lines[i].trimmingCharacters(in: .whitespaces)
                    if l.hasPrefix("> ") { l = String(l.dropFirst(2)) }
                    else if l == ">" { l = "" }
                    else { l = String(l.dropFirst(1)) }
                    result.append(convertJiraInline(l))
                    i += 1
                }
                result.append("{quote}")
                continue
            }

            // Unordered list
            let stripped = String(line.drop(while: { $0 == " " || $0 == "\t" }))
            if stripped.hasPrefix("- ") || stripped.hasPrefix("* ") || stripped.hasPrefix("+ ") {
                let indent = line.count - stripped.count
                let depth = max(1, indent / 2 + 1)
                var content = String(stripped.dropFirst(2))
                if content.hasPrefix("[ ] ") {
                    content = String(content.dropFirst(4))
                } else if content.hasPrefix("[x] ") || content.hasPrefix("[X] ") {
                    content = "(/) " + String(content.dropFirst(4))
                }
                result.append(String(repeating: "*", count: depth) + " " + convertJiraInline(content))
                i += 1
                continue
            }

            // Ordered list
            if stripped.range(of: #"^\d+\.\s+"#, options: .regularExpression) != nil {
                let indent = line.count - stripped.count
                let depth = max(1, indent / 3 + 1)
                let content = stripped.replacingOccurrences(of: #"^\d+\.\s+"#, with: "", options: .regularExpression)
                result.append(String(repeating: "#", count: depth) + " " + convertJiraInline(content))
                i += 1
                continue
            }

            // Regular text
            result.append(convertJiraInline(line))
            i += 1
        }

        return result.joined(separator: "\n")
    }

    private static func convertJiraInline(_ text: String) -> String {
        var s = text

        // Inline code: `code` → {{code}}
        s = s.replacingOccurrences(of: #"`([^`]+)`"#, with: "{{$1}}", options: .regularExpression)

        // Images: ![alt](url) → !url|alt!
        s = s.replacingOccurrences(of: #"!\[([^\]]*)\]\(([^)]+)\)"#, with: "!$2|$1!", options: .regularExpression)

        // Links: [text](url) → [text|url]
        s = s.replacingOccurrences(of: #"\[([^\]]+)\]\(([^)]+)\)"#, with: "[$1|$2]", options: .regularExpression)

        // Bold → placeholder (to avoid conflict with italic conversion)
        s = s.replacingOccurrences(of: #"\*\*(.+?)\*\*"#, with: "\u{0001}$1\u{0001}", options: .regularExpression)
        s = s.replacingOccurrences(of: #"__(.+?)__"#, with: "\u{0001}$1\u{0001}", options: .regularExpression)

        // Italic *text* → _text_
        s = s.replacingOccurrences(of: #"(?<![*\\])\*([^*]+)\*(?!\*)"#, with: "_$1_", options: .regularExpression)

        // Restore bold placeholders → *text*
        s = s.replacingOccurrences(of: "\u{0001}", with: "*")

        // Strikethrough: ~~text~~ → -text-
        s = s.replacingOccurrences(of: #"~~(.+?)~~"#, with: "-$1-", options: .regularExpression)

        return s
    }

    // MARK: - Markdown → HTML (for Copy Formatted)

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
