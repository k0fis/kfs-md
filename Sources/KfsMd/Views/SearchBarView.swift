import SwiftUI

struct SearchBarView: View {
    @Binding var searchText: String
    let matchCount: Int
    let onClose: () -> Void
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppColors.textSecondary)

            TextField("Search…", text: $searchText)
                .textFieldStyle(.plain)
                .font(.custom("JetBrains Mono", size: 13))
                .foregroundStyle(AppColors.textPrimary)
                .focused($isFocused)

            if !searchText.isEmpty {
                Text(matchCount > 0 ? "\(matchCount) matches" : "No matches")
                    .font(.custom("JetBrains Mono", size: 11))
                    .foregroundStyle(matchCount > 0 ? AppColors.textSecondary : AppColors.inlineCode)

                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(AppColors.textSecondary)
                }
                .buttonStyle(.plain)
            }

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .foregroundStyle(AppColors.textSecondary)
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.escape, modifiers: [])
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.5))
        .onAppear { isFocused = true }
    }
}

struct GoToLineBarView: View {
    @Binding var lineText: String
    let totalLines: Int
    let onGo: (Int) -> Void
    let onClose: () -> Void
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.right.to.line")
                .foregroundStyle(AppColors.textSecondary)

            Text("Go to Line:")
                .font(.custom("JetBrains Mono", size: 13))
                .foregroundStyle(AppColors.textSecondary)

            TextField("1–\(totalLines)", text: $lineText)
                .textFieldStyle(.plain)
                .font(.custom("JetBrains Mono", size: 13))
                .foregroundStyle(AppColors.textPrimary)
                .focused($isFocused)
                .frame(width: 80)
                .onSubmit {
                    if let line = Int(lineText), line >= 1, line <= totalLines {
                        onGo(line)
                    }
                }

            Text("of \(totalLines)")
                .font(.custom("JetBrains Mono", size: 11))
                .foregroundStyle(AppColors.textSecondary)

            Spacer()

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .foregroundStyle(AppColors.textSecondary)
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.escape, modifiers: [])
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.5))
        .onAppear { isFocused = true }
    }
}
