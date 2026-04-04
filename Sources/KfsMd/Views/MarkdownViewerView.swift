import SwiftUI
import MarkdownUI

struct MarkdownViewerView: View {
    let text: String

    var body: some View {
        ScrollView {
            Markdown(text)
                .markdownTheme(.darkTerminal)
                .textSelection(.enabled)
                .padding(32)
                .frame(maxWidth: 720, alignment: .leading)
                .frame(maxWidth: .infinity)
        }
        .background(AppColors.background)
    }
}
