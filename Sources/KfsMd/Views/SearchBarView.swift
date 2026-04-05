import SwiftUI

struct SearchBarView: View {
    @Binding var searchText: String
    let matchCount: Int
    let currentMatch: Int
    let onNext: () -> Void
    let onPrev: () -> Void
    let onClose: () -> Void
    @FocusState private var isFocused: Bool

    private var matchDisplay: String {
        guard !searchText.isEmpty else { return "" }
        guard matchCount > 0 else { return "No matches" }
        return "\(currentMatch + 1)/\(matchCount)"
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppColors.textSecondary)

            TextField("Search…", text: $searchText)
                .textFieldStyle(.plain)
                .font(.custom("JetBrains Mono", size: 13))
                .foregroundStyle(AppColors.textPrimary)
                .focused($isFocused)
                .onSubmit { onNext() }

            if !searchText.isEmpty {
                Text(matchDisplay)
                    .font(.custom("JetBrains Mono", size: 11))
                    .foregroundStyle(matchCount > 0 ? AppColors.textSecondary : AppColors.inlineCode)
                    .frame(minWidth: 50)

                Button(action: onPrev) {
                    Image(systemName: "chevron.up")
                        .foregroundStyle(AppColors.textSecondary)
                }
                .buttonStyle(.plain)
                .disabled(matchCount == 0)
                .keyboardShortcut("g", modifiers: [.command, .shift])

                Button(action: onNext) {
                    Image(systemName: "chevron.down")
                        .foregroundStyle(AppColors.textSecondary)
                }
                .buttonStyle(.plain)
                .disabled(matchCount == 0)
                .keyboardShortcut("g", modifiers: .command)
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

// MARK: - Go To Line Bar

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

            TextField("Line (1–\(totalLines))…", text: $lineText)
                .textFieldStyle(.plain)
                .font(.custom("JetBrains Mono", size: 13))
                .foregroundStyle(AppColors.textPrimary)
                .focused($isFocused)
                .onSubmit {
                    if let num = Int(lineText), num >= 1, num <= totalLines {
                        onGo(num)
                    }
                }

            Text("/ \(totalLines)")
                .font(.custom("JetBrains Mono", size: 11))
                .foregroundStyle(AppColors.textSecondary)

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
