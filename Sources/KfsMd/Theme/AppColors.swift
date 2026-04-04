import SwiftUI

enum AppColors {
    static let background = Color(red: 0.10, green: 0.10, blue: 0.18)   // #1a1a2e
    static let textPrimary = Color.white.opacity(0.87)
    static let textSecondary = Color.white.opacity(0.60)

    // Headings
    static let heading1 = Color(red: 0.40, green: 0.90, blue: 0.40)     // green
    static let heading2 = Color(red: 0.40, green: 0.85, blue: 0.95)     // cyan
    static let heading3 = Color(red: 0.70, green: 0.70, blue: 0.95)     // lavender

    // Code
    static let codeText = Color(red: 0.40, green: 0.90, blue: 0.40)     // green
    static let codeBackground = Color.black.opacity(0.4)
    static let inlineCode = Color(red: 0.95, green: 0.65, blue: 0.30)   // orange
    static let inlineCodeBackground = Color.white.opacity(0.08)

    // Links & accents
    static let link = Color(red: 0.40, green: 0.85, blue: 0.95)         // cyan
    static let blockquoteBorder = Color.yellow.opacity(0.5)
}
