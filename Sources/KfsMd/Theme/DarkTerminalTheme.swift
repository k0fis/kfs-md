import SwiftUI
import MarkdownUI

extension MarkdownUI.Theme {
    static let darkTerminal = Theme()
        .text {
            ForegroundColor(AppColors.textPrimary)
            FontFamily(.custom("JetBrains Mono"))
            FontSize(14)
        }
        .heading1 { configuration in
            configuration.label
                .markdownTextStyle {
                    FontSize(28)
                    FontWeight(.bold)
                    ForegroundColor(AppColors.heading1)
                }
                .padding(.bottom, 8)
                .padding(.top, 16)
        }
        .heading2 { configuration in
            configuration.label
                .markdownTextStyle {
                    FontSize(22)
                    FontWeight(.semibold)
                    ForegroundColor(AppColors.heading2)
                }
                .padding(.bottom, 6)
                .padding(.top, 12)
        }
        .heading3 { configuration in
            configuration.label
                .markdownTextStyle {
                    FontSize(18)
                    FontWeight(.semibold)
                    ForegroundColor(AppColors.heading3)
                }
                .padding(.bottom, 4)
                .padding(.top, 10)
        }
        .codeBlock { configuration in
            configuration.label
                .markdownTextStyle {
                    FontFamily(.custom("JetBrains Mono"))
                    FontSize(13)
                    ForegroundColor(AppColors.codeText)
                }
                .padding(12)
                .background(AppColors.codeBackground)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .padding(.vertical, 4)
        }
        .blockquote { configuration in
            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(AppColors.blockquoteBorder)
                    .frame(width: 3)
                configuration.label
                    .markdownTextStyle {
                        ForegroundColor(AppColors.textSecondary)
                    }
                    .padding(.leading, 12)
            }
            .padding(.vertical, 4)
        }
        .link {
            ForegroundColor(AppColors.link)
        }
        .code {
            FontFamily(.custom("JetBrains Mono"))
            FontSize(13)
            ForegroundColor(AppColors.inlineCode)
            BackgroundColor(AppColors.inlineCodeBackground)
        }
        .strong {
            FontWeight(.bold)
        }
        .emphasis {
            FontStyle(.italic)
        }
        .listItem { configuration in
            configuration.label
                .markdownTextStyle {
                    ForegroundColor(AppColors.textPrimary)
                }
        }
}
