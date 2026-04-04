import SwiftUI
import UniformTypeIdentifiers

struct MarkdownDocument: FileDocument {
    var text: String
    var rawData: Data
    var fileType: UTType

    static var readableContentTypes: [UTType] {
        [.markdown, .plainText, .log, .xml, .json]
    }

    static var writableContentTypes: [UTType] {
        [.markdown, .plainText]
    }

    init(text: String = "", fileType: UTType = .markdown) {
        self.text = text
        self.rawData = text.data(using: .utf8) ?? Data()
        self.fileType = fileType
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.rawData = data
        self.text = String(data: data, encoding: .utf8)
            ?? String(data: data, encoding: .isoLatin1)
            ?? ""
        self.fileType = configuration.contentType
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = text.data(using: .utf8)!
        return FileWrapper(regularFileWithContents: data)
    }

    var isMarkdown: Bool {
        fileType.conforms(to: .markdown)
    }
}

extension UTType {
    static let markdown = UTType("net.daringfireball.markdown") ?? .plainText
    static let log = UTType("public.log") ?? .plainText
}
