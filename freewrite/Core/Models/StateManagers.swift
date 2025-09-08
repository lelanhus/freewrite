import SwiftUI
import Foundation

// MARK: - UI State Manager

@Observable
@MainActor
final class UIStateManager {
    var selectedFont: String = "Lato-Regular"
    var fontSize: CGFloat = 18
    var bottomNavOpacity: Double = 1.0
    var placeholderText: String = ""
    var showingSidebar = false
    var viewHeight: CGFloat = 0
    var showingChatMenu = false
    var didCopyPrompt: Bool = false
    var isFullscreen = false
    
    private var colorSchemeString: String = "light"
    
    var colorScheme: ColorScheme {
        return colorSchemeString == "dark" ? .dark : .light
    }
    
    func setColorScheme(_ scheme: String) {
        colorSchemeString = scheme
    }
    
    func getColorSchemeString() -> String {
        return colorSchemeString
    }
}

// MARK: - Hover State Manager

@Observable
@MainActor
final class HoverStateManager {
    var isHoveringTimer = false
    var isHoveringBottomNav = false
    var isHoveringThemeToggle = false
    var isHoveringClock = false
    var isHoveringSize = false
    var isHoveringNewEntry = false
    var isHoveringChat = false
    var isHoveringFullscreen = false
    var hoveredFont: String? = nil
    var hoveredEntryId: UUID? = nil
    
    func resetAllHover() {
        isHoveringTimer = false
        isHoveringBottomNav = false
        isHoveringThemeToggle = false
        isHoveringClock = false
        isHoveringSize = false
        isHoveringNewEntry = false
        isHoveringChat = false
        isHoveringFullscreen = false
        hoveredFont = nil
        hoveredEntryId = nil
    }
}

// MARK: - Typography State Manager

@Observable
@MainActor
final class TypographyStateManager {
    var selectedFont: String = FontConstants.defaultFont
    var fontSize: CGFloat = FontConstants.defaultSize
    
    var lineHeight: CGFloat {
        let font = NSFont(name: selectedFont, size: fontSize) ?? .systemFont(ofSize: fontSize)
        let defaultLineHeight = getLineHeight(font: font)
        return (fontSize * 1.5) - defaultLineHeight
    }
    
    var placeholderOffset: CGFloat {
        return fontSize / 2
    }
    
    func updateFont(_ font: String) {
        selectedFont = font
    }
    
    func updateFontSize(_ size: CGFloat) {
        fontSize = size
    }
}

// MARK: - Progress State Manager

@Observable
@MainActor
final class ProgressStateManager {
    private(set) var isLoading = false
    private(set) var loadingMessage = ""
    private(set) var progress: Double = 0.0
    
    func startLoading(_ message: String) {
        loadingMessage = message
        progress = 0.0
        isLoading = true
    }
    
    func updateProgress(_ value: Double, message: String? = nil) {
        progress = min(max(value, 0.0), 1.0) // Clamp between 0 and 1
        if let message = message {
            loadingMessage = message
        }
    }
    
    func finishLoading() {
        isLoading = false
        loadingMessage = ""
        progress = 0.0
    }
    
    var isVisible: Bool {
        return isLoading
    }
}

// Note: getLineHeight function is defined in Extensions/ContentView+Extensions.swift