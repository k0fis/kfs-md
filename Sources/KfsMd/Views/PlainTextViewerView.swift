import SwiftUI

struct PlainTextViewerView: View {
    let text: String

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            Text(text)
                .font(.custom("JetBrains Mono", size: 13))
                .foregroundStyle(AppColors.textPrimary)
                .textSelection(.enabled)
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(AppColors.background)
    }
}
