import SwiftUI

@main
struct KfsMdApp: App {
    @FocusedBinding(\.isSearchActive) var isSearchActive
    @FocusedBinding(\.isGoToLineActive) var isGoToLineActive

    init() {
        registerBundledFonts()
    }

    var body: some Scene {
        DocumentGroup(newDocument: MarkdownDocument()) { file in
            ContentView(document: file.$document)
                .preferredColorScheme(.dark)
        }
        .defaultSize(width: 820, height: 900)
        .commands {
            CommandGroup(after: .textEditing) {
                Divider()
                Button("Find…") {
                    isSearchActive = true
                }
                .keyboardShortcut("f", modifiers: .command)

                Button("Go to Line…") {
                    isGoToLineActive = true
                }
                .keyboardShortcut("g", modifiers: .command)
            }
        }
    }

    private func registerBundledFonts() {
        let fontNames = ["JetBrainsMono-Regular", "JetBrainsMono-Bold"]
        for name in fontNames {
            // .app bundle: fonts in Contents/Resources/Fonts/
            // swift run: fonts in SPM resource bundle
            let url = Bundle.main.url(forResource: name, withExtension: "ttf", subdirectory: "Fonts")
                ?? (try? findModuleBundle())?.url(forResource: name, withExtension: "ttf", subdirectory: "Fonts")
            guard let url else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }

    private func findModuleBundle() throws -> Bundle? {
        let bundleName = "kfs-md_KfsMd"
        let candidates = [
            Bundle.main.resourceURL,
            Bundle.main.bundleURL,
            Bundle.main.bundleURL.deletingLastPathComponent(),
        ]
        for candidate in candidates {
            guard let dir = candidate else { continue }
            let bundlePath = dir.appendingPathComponent(bundleName + ".bundle")
            if let bundle = Bundle(url: bundlePath) {
                return bundle
            }
        }
        return nil
    }
}
