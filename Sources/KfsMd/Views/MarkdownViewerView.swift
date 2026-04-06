import SwiftUI
import MarkdownUI

struct MarkdownViewerView: View {
    let text: String
    let fontSize: CGFloat
    let searchText: String
    let currentMatchIndex: Int
    let highlightedLine: Int?

    private var blocks: [String] {
        splitMarkdownBlocks(text)
    }

    private func countMatches(in str: String) -> Int {
        guard !searchText.isEmpty else { return 0 }
        var count = 0
        var start = str.startIndex
        while start < str.endIndex,
              let range = str.range(of: searchText, options: .caseInsensitive, range: start..<str.endIndex) {
            count += 1
            start = range.upperBound
        }
        return count
    }

    private func currentMatchBlockIndex() -> Int? {
        guard !searchText.isEmpty, currentMatchIndex >= 0 else { return nil }
        var total = 0
        for (i, block) in blocks.enumerated() {
            let count = countMatches(in: block)
            if currentMatchIndex < total + count {
                return i
            }
            total += count
        }
        return nil
    }

    /// Find which block contains a given line number (1-based).
    private func blockIndexForLine(_ targetLine: Int) -> Int? {
        guard targetLine >= 1 else { return nil }
        let allLines = text.components(separatedBy: "\n")
        guard targetLine <= allLines.count else { return nil }

        var blockIndex = 0
        var currentBlockHasContent = false
        var inCodeFence = false

        for (i, line) in allLines.enumerated() {
            if line.trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                inCodeFence = !inCodeFence
            }

            let isSep = !inCodeFence
                && line.trimmingCharacters(in: .whitespaces).isEmpty
                && currentBlockHasContent

            if isSep {
                blockIndex += 1
                currentBlockHasContent = false
            } else {
                currentBlockHasContent = true
            }

            if i + 1 == targetLine {
                return blockIndex
            }
        }
        return nil
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(blocks.enumerated()), id: \.offset) { index, block in
                        let isCurrentBlock = !searchText.isEmpty && currentMatchBlockIndex() == index
                        let hasMatch = !searchText.isEmpty && countMatches(in: block) > 0
                        let isGoToTarget = highlightedLine != nil && blockIndexForLine(highlightedLine!) == index

                        Markdown(block)
                            .markdownTheme(.darkTerminal(fontSize: fontSize))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 2)
                            .padding(.horizontal, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(isGoToTarget
                                          ? AppColors.goToLineHighlight
                                          : isCurrentBlock
                                            ? AppColors.currentMatchHighlight.opacity(0.2)
                                            : hasMatch
                                              ? AppColors.searchHighlight
                                              : Color.clear)
                            )
                            .id(index)
                    }
                }
                .padding(32)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(AppColors.background)
            .onAppear {
                scrollToMatch(proxy: proxy)
            }
            .onChange(of: currentMatchIndex) { _ in
                scrollToMatch(proxy: proxy)
            }
            .onChange(of: searchText) { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    scrollToMatch(proxy: proxy)
                }
            }
            .onChange(of: highlightedLine) { newValue in
                guard let line = newValue, let blockIdx = blockIndexForLine(line) else { return }
                withAnimation(.easeInOut(duration: 0.3)) {
                    proxy.scrollTo(blockIdx, anchor: .center)
                }
            }
        }
    }

    private func scrollToMatch(proxy: ScrollViewProxy) {
        if let blockIdx = currentMatchBlockIndex() {
            withAnimation(.easeInOut(duration: 0.3)) {
                proxy.scrollTo(blockIdx, anchor: .center)
            }
        }
    }

    /// Split markdown into blocks at blank lines, keeping code fences intact.
    private func splitMarkdownBlocks(_ text: String) -> [String] {
        var blocks: [String] = []
        var current = ""
        var inCodeFence = false

        for line in text.components(separatedBy: "\n") {
            if line.trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                inCodeFence = !inCodeFence
            }

            if !inCodeFence && line.trimmingCharacters(in: .whitespaces).isEmpty && !current.isEmpty {
                blocks.append(current)
                current = ""
            } else {
                if !current.isEmpty { current += "\n" }
                current += line
            }
        }

        if !current.isEmpty {
            blocks.append(current)
        }

        return blocks.isEmpty ? [""] : blocks
    }
}
