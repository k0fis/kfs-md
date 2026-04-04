import SwiftUI

struct EditorView: View {
    @Binding var text: String

    var body: some View {
        TextEditor(text: $text)
            .font(.custom("JetBrains Mono", size: 13))
            .foregroundStyle(AppColors.textPrimary)
            .scrollContentBackground(.hidden)
            .background(AppColors.background)
            .padding(16)
    }
}
