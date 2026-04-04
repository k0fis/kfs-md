import SwiftUI

struct ContentView: View {
    @Binding var document: MarkdownDocument
    @State private var isEditing = false

    var body: some View {
        Group {
            if isEditing {
                EditorView(text: $document.text)
            } else if document.isMarkdown {
                MarkdownViewerView(text: document.text)
            } else {
                PlainTextViewerView(text: document.text)
            }
        }
        .frame(minWidth: 500, minHeight: 400)
        .background(AppColors.background)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isEditing.toggle()
                } label: {
                    Image(systemName: isEditing ? "eye" : "pencil")
                    Text(isEditing ? "View" : "Edit")
                }
                .keyboardShortcut("e", modifiers: .command)
            }
        }
    }
}
