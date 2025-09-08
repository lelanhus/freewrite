import SwiftUI

// MARK: - Content & Writing State
@Observable
final class WritingState {
    var text: String = FreewriteConstants.headerString
    var placeholderText: String = ""
    
    func updateText(_ newText: String) {
        text = newText
    }
    
    func setPlaceholder(_ placeholder: String) {
        placeholderText = placeholder
    }
}

// MARK: - Font & Typography State
@Observable
final class FontState {
    var selectedFont: String = "Lato-Regular"
    var fontSize: CGFloat = 18
    var hoveredFont: String? = nil
    var isHoveringSize = false
    
    func selectFont(_ font: String) {
        selectedFont = font
        hoveredFont = nil
    }
    
    func cycleFontSize() {
        let fontSizes: [CGFloat] = [16, 18, 20, 22, 24, 26]
        if let currentIndex = fontSizes.firstIndex(of: fontSize) {
            let nextIndex = (currentIndex + 1) % fontSizes.count
            fontSize = fontSizes[nextIndex]
        }
    }
    
    func setFontSize(_ size: CGFloat) {
        fontSize = size
    }
    
    var fontSizeButtonTitle: String {
        return "\(Int(fontSize))px"
    }
}

// MARK: - Navigation & Hover State
@Observable
final class NavigationState {
    var bottomNavOpacity: Double = 1.0
    var isHoveringBottomNav = false
    var isHoveringTimer = false
    var isHoveringThemeToggle = false
    var isHoveringClock = false
    var isHoveringNewEntry = false
    var isHoveringChat = false
    var isHoveringFullscreen = false
    
    func setHovering(_ element: NavigationElement, _ isHovering: Bool) {
        switch element {
        case .bottomNav: isHoveringBottomNav = isHovering
        case .timer: isHoveringTimer = isHovering
        case .themeToggle: isHoveringThemeToggle = isHovering
        case .clock: isHoveringClock = isHovering
        case .newEntry: isHoveringNewEntry = isHovering
        case .chat: isHoveringChat = isHovering
        case .fullscreen: isHoveringFullscreen = isHovering
        }
    }
    
    func setBottomNavOpacity(_ opacity: Double) {
        bottomNavOpacity = opacity
    }
}

enum NavigationElement {
    case bottomNav, timer, themeToggle, clock, newEntry, chat, fullscreen
}

// MARK: - UI Mode State
@Observable
final class UIMode {
    var colorScheme: ColorScheme = .light
    var showingSidebar = false
    var isFullscreen = false
    var viewHeight: CGFloat = 0
    
    func toggleColorScheme() {
        colorScheme = colorScheme == .light ? .dark : .light
    }
    
    func toggleSidebar() {
        showingSidebar.toggle()
    }
    
    func setFullscreen(_ fullscreen: Bool) {
        isFullscreen = fullscreen
    }
    
    func setViewHeight(_ height: CGFloat) {
        viewHeight = height
    }
}

// MARK: - Chat State
@Observable
final class ChatState {
    var showingChatMenu = false
    var didCopyPrompt: Bool = false
    
    func showMenu() {
        showingChatMenu = true
        didCopyPrompt = false
    }
    
    func hideMenu() {
        showingChatMenu = false
        didCopyPrompt = false
    }
    
    func markPromptCopied() {
        didCopyPrompt = true
    }
}

// MARK: - Entry Management State
@Observable
final class EntryState {
    var entries: [WritingEntryDTO] = []
    var selectedEntryId: UUID? = nil
    var hoveredEntryId: UUID? = nil
    
    func setEntries(_ newEntries: [WritingEntryDTO]) {
        entries = newEntries
    }
    
    func addEntry(_ entry: WritingEntryDTO) {
        entries.insert(entry, at: 0)
    }
    
    func removeEntry(withId id: UUID) {
        entries.removeAll { $0.id == id }
    }
    
    func selectEntry(_ id: UUID?) {
        selectedEntryId = id
    }
    
    func setHoveredEntry(_ id: UUID?) {
        hoveredEntryId = id
    }
    
    var currentEntry: WritingEntryDTO? {
        return entries.first { $0.id == selectedEntryId }
    }
}