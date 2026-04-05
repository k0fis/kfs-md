import SwiftUI
import MarkdownUI

struct MarkdownViewerView: View {
    let text: String
    let fontSize: CGFloat
    let searchText: String
    let currentMatchIndex: Int

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

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(blocks.enumerated()), id: \.offset) { index, block in
                        let isCurrentBlock = !searchText.isEmpty && currentMatchBlockIndex() == index
                        let hasMatch = !searchText.isEmpty && countMatches(in: block) > 0

                        Markdown(block)
                            .markdownTheme(.darkTerminal(fontSize: fontSize))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 2)
                            .padding(.horizontal, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(isCurrentBlock
                                          ? AppColors.currentMatchHighlight.opacity(0.2)
                                          : hasMatch
                                            ? AppColors.searchHighlight
                                            : Color.clear)
                            )
                            .id(index)
                    }
                }
                .padding(32)
                .frame(maxWidth: 720, alignment: .leading)
                .frame(maxWidth: .infinity)
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
