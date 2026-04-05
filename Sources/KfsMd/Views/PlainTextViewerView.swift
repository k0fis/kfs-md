import SwiftUI

struct PlainTextViewerView: View {
    let text: String
    let searchText: String
    let showLineNumbers: Bool
    @Binding var scrollToLine: Int?

    private var lines: [String] {
        text.components(separatedBy: "\n")
    }

    private var gutterWidth: CGFloat {
        let digits = max(String(lines.count).count, 2)
        return CGFloat(digits) * 8 + 12
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView([.horizontal, .vertical]) {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                        HStack(alignment: .top, spacing: 0) {
                            if showLineNumbers {
                                Text("\(index + 1)")
                                    .font(.custom("JetBrains Mono", size: 13))
                                    .foregroundStyle(AppColors.lineNumber)
                                    .frame(minWidth: gutterWidth, alignment: .trailing)
                                    .padding(.trailing, 12)
                            }

                            if searchText.isEmpty {
                                Text(line.isEmpty ? " " : line)
                                    .font(.custom("JetBrains Mono", size: 13))
                                    .foregroundStyle(AppColors.textPrimary)
                                    .textSelection(.enabled)
                            } else {
                                Text(highlightLine(line))
                                    .textSelection(.enabled)
                            }
                        }
                        .id(index + 1)
                    }
                }
                .padding(EdgeInsets(top: 24, leading: showLineNumbers ? 8 : 24, bottom: 24, trailing: 24))
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(AppColors.background)
            .onChange(of: scrollToLine) { target in
                guard let target else { return }
                withAnimation(.easeInOut(duration: 0.3)) {
                    proxy.scrollTo(target, anchor: .center)
                }
                DispatchQueue.main.async { scrollToLine = nil }
            }
        }
    }

    private func highlightLine(_ line: String) -> AttributedString {
        let displayLine = line.isEmpty ? " " : line
        guard !searchText.isEmpty else {
            var result = AttributedString(displayLine)
            result.font = .custom("JetBrains Mono", size: 13)
            result.foregroundColor = AppColors.textPrimary
            return result
        }

        var result = AttributedString()
        var lastEnd = displayLine.startIndex

        var searchStart = displayLine.startIndex
        while searchStart < displayLine.endIndex,
              let range = displayLine.range(of: searchText, options: .caseInsensitive, range: searchStart..<displayLine.endIndex) {
            // Text before match
            if lastEnd < range.lowerBound {
                var before = AttributedString(displayLine[lastEnd..<range.lowerBound])
                before.font = .custom("JetBrains Mono", size: 13)
                before.foregroundColor = AppColors.textPrimary
                result += before
            }

            // Matched text
            var match = AttributedString(displayLine[range])
            match.font = .custom("JetBrains Mono", size: 13)
            match.foregroundColor = .black
            match.backgroundColor = AppColors.searchHighlight
            result += match

            lastEnd = range.upperBound
            searchStart = range.upperBound
        }

        // Remaining text after last match
        if lastEnd < displayLine.endIndex {
            var remaining = AttributedString(displayLine[lastEnd...])
            remaining.font = .custom("JetBrains Mono", size: 13)
            remaining.foregroundColor = AppColors.textPrimary
            result += remaining
        }

        return result
    }
}
