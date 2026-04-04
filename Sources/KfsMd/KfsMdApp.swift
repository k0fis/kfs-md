import SwiftUI

@main
struct KfsMdApp: App {
    init() {
        registerBundledFonts()
    }

    var body: some Scene {
        DocumentGroup(newDocument: MarkdownDocument()) { file in
            ContentView(document: file.$document)
                .preferredColorScheme(.dark)
        }
        .defaultSize(width: 820, height: 900)
    }

    private func registerBundledFonts() {
        let fontNames = ["JetBrainsMono-Regular", "JetBrainsMono-Bold"]
        for name in fontNames {
            guard let url = Bundle.module.url(forResource: name, withExtension: "ttf", subdirectory: "Fonts") else {
                continue
            }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}
