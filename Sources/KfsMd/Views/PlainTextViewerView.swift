import SwiftUI

struct PlainTextViewerView: View {
    let text: String
    let searchText: String
    let fontSize: CGFloat
    let currentMatchIndex: Int

    private var lines: [String] {
        text.components(separatedBy: "\n")
    }

    private func countMatches(in line: String) -> Int {
        guard !searchText.isEmpty else { return 0 }
        var count = 0
        var start = line.startIndex
        while start < line.endIndex,
              let range = line.range(of: searchText, options: .caseInsensitive, range: start..<line.endIndex) {
            count += 1
            start = range.upperBound
        }
        return count
    }

    private func currentMatchLineIndex() -> Int? {
        guard !searchText.isEmpty, currentMatchIndex >= 0 else { return nil }
        var total = 0
        for (i, line) in lines.enumerated() {
            let count = countMatches(in: line)
            if currentMatchIndex < total + count {
                return i
            }
            total += count
        }
        return nil
    }

    var body: some View {
        let allLines = lines
        let offsets: [Int] = {
            guard !searchText.isEmpty else { return Array(repeating: 0, count: allLines.count) }
            var result: [Int] = []
            var total = 0
            for line in allLines {
                result.append(total)
                total += countMatches(in: line)
            }
            return result
        }()

        ScrollViewReader { proxy in
            ScrollView([.horizontal, .vertical]) {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(allLines.enumerated()), id: \.offset) { index, line in
                        if searchText.isEmpty {
                            Text(line.isEmpty ? " " : line)
                                .font(.custom("JetBrains Mono", size: fontSize))
                                .foregroundStyle(AppColors.textPrimary)
                                .textSelection(.enabled)
                                .id(index)
                        } else {
                            Text(highlightLine(line, globalOffset: offsets[index]))
                                .textSelection(.enabled)
                                .id(index)
                        }
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(AppColors.background)
            .onAppear {
                if !searchText.isEmpty {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        if let lineIdx = currentMatchLineIndex() {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                proxy.scrollTo(lineIdx, anchor: .center)
                            }
                        }
                    }
                }
            }
            .onChange(of: searchText) { _ in
                if let lineIdx = currentMatchLineIndex() {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo(lineIdx, anchor: .center)
                    }
                }
            }
            .onChange(of: currentMatchIndex) { _ in
                if let lineIdx = currentMatchLineIndex() {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo(lineIdx, anchor: .center)
                    }
                }
            }
        }
    }

    private func highlightLine(_ line: String, globalOffset: Int) -> AttributedString {
        let displayLine = line.isEmpty ? " " : line
        guard !searchText.isEmpty else {
            var result = AttributedString(displayLine)
            result.font = .custom("JetBrains Mono", size: fontSize)
            result.foregroundColor = AppColors.textPrimary
            return result
        }

        var result = AttributedString()
        var lastEnd = displayLine.startIndex
        var localIndex = 0

        var searchStart = displayLine.startIndex
        while searchStart < displayLine.endIndex,
              let range = displayLine.range(of: searchText, options: .caseInsensitive, range: searchStart..<displayLine.endIndex) {
            if lastEnd < range.lowerBound {
                var before = AttributedString(displayLine[lastEnd..<range.lowerBound])
                before.font = .custom("JetBrains Mono", size: fontSize)
                before.foregroundColor = AppColors.textPrimary
                result += before
            }

            let isCurrent = (globalOffset + localIndex) == currentMatchIndex
            var match = AttributedString(displayLine[range])
            match.font = .custom("JetBrains Mono", size: fontSize)
            match.foregroundColor = .black
            match.backgroundColor = isCurrent ? AppColors.currentMatchHighlight : AppColors.searchHighlight
            result += match

            lastEnd = range.upperBound
            searchStart = range.upperBound
            localIndex += 1
        }

        if lastEnd < displayLine.endIndex {
            var remaining = AttributedString(displayLine[lastEnd...])
            remaining.font = .custom("JetBrains Mono", size: fontSize)
            remaining.foregroundColor = AppColors.textPrimary
            result += remaining
        }

        return result
    }
}
