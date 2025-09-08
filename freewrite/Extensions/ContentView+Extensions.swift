import SwiftUI
import AppKit

// MARK: - Helper Functions

func getLineHeight(font: NSFont) -> CGFloat {
    return font.ascender - font.descender + font.leading
}