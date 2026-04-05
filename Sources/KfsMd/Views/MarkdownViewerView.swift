import SwiftUI
import MarkdownUI

struct MarkdownViewerView: View {
    let text: String
    let fontSize: CGFloat

    var body: some View {
        ScrollView {
            Markdown(text)
                .markdownTheme(.darkTerminal(fontSize: fontSize))
                .textSelection(.enabled)
                .padding(32)
                .frame(maxWidth: 720, alignment: .leading)
                .frame(maxWidth: .infinity)
        }
        .background(AppColors.background)
    }
}
