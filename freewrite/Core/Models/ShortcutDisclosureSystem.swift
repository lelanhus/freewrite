import SwiftUI
import Foundation

/// Progressive disclosure system for keyboard shortcuts - beautiful and minimal
@MainActor
@Observable
final class ShortcutDisclosureManager {
    
    // MARK: - User Proficiency Tracking
    
    enum UserLevel {
        case beginner      // First few sessions
        case intermediate  // Discovered basic shortcuts  
        case expert        // Using advanced shortcuts regularly
    }
    
    private(set) var userLevel: UserLevel = .beginner
    private var sessionCount: Int = 0
    private var shortcutsUsed: Set<String> = []
    
    // MARK: - Tooltip State
    
    struct TooltipState {
        let shortcut: String
        let description: String
        let priority: Int // Higher = more important to show
        var isVisible: Bool = false
        var shouldShow: Bool = true
    }
    
    private var activeTooltips: [String: TooltipState] = [:]
    
    // MARK: - Progressive Disclosure Logic
    
    func registerSessionStart() {
        sessionCount += 1
        updateUserLevel()
    }
    
    func registerShortcutUsed(_ shortcut: String) {
        shortcutsUsed.insert(shortcut)
        updateUserLevel()
    }
    
    func getTooltipFor(element: String, context: String = "") -> TooltipState? {
        let relevantShortcuts = getRelevantShortcuts(for: element, context: context)
        
        // Return highest priority tooltip that should be shown
        return relevantShortcuts
            .filter { $0.shouldShow }
            .max { $0.priority < $1.priority }
    }
    
    func shouldShowTooltip(for shortcut: String) -> Bool {
        // Don't show tooltips for shortcuts user already knows
        if shortcutsUsed.contains(shortcut) && userLevel == .expert {
            return false
        }
        
        // Progressive disclosure based on user level
        switch userLevel {
        case .beginner:
            return beginnerShortcuts.contains(shortcut)
        case .intermediate:
            return beginnerShortcuts.contains(shortcut) || intermediateShortcuts.contains(shortcut)
        case .expert:
            return true // Show all shortcuts for expert users
        }
    }
    
    // MARK: - Shortcut Categories
    
    private let beginnerShortcuts = ["⌘N", "⌘T", "⌘D"]
    
    private let intermediateShortcuts = [
        "⌘E", "⌘O", "⌘+", "⌘-", "⌘1", "⌘2", "⌘3"
    ]
    
    private let expertShortcuts = [
        "⌘⇧N", "⌘⇧F", "⌘⇧E", "⌘⇧A", "⌘4", "⌘5", "⌘6", "⌘7", "⌘8", "⌘9"
    ]
    
    // MARK: - Private Helpers
    
    private func updateUserLevel() {
        let shortcutsKnown = shortcutsUsed.count
        
        switch (sessionCount, shortcutsKnown) {
        case (0...5, _):
            userLevel = .beginner
        case (6...20, 0...3):
            userLevel = .intermediate
        case (6...20, 4...):
            userLevel = .expert
        case (21..., _):
            userLevel = .expert
        default:
            userLevel = .intermediate
        }
    }
    
    private func getRelevantShortcuts(for element: String, context: String) -> [TooltipState] {
        var tooltips: [TooltipState] = []
        
        switch element {
        case "timer":
            if shouldShowTooltip(for: "⌘T") {
                tooltips.append(TooltipState(
                    shortcut: "⌘T",
                    description: "Toggle timer",
                    priority: 10
                ))
            }
            if shouldShowTooltip(for: "⌘+") {
                tooltips.append(TooltipState(
                    shortcut: "⌘+ / ⌘-",
                    description: "Adjust time",
                    priority: 8
                ))
            }
            
        case "newEntry":
            if shouldShowTooltip(for: "⌘N") {
                tooltips.append(TooltipState(
                    shortcut: "⌘N",
                    description: "New session",
                    priority: 9
                ))
            }
            
        case "chat":
            if shouldShowTooltip(for: "⌘E") {
                tooltips.append(TooltipState(
                    shortcut: "⌘E",
                    description: "Export for AI",
                    priority: 7
                ))
            }
            
        case "sidebar":
            if shouldShowTooltip(for: "⌘O") {
                tooltips.append(TooltipState(
                    shortcut: "⌘O",
                    description: "Browse history",
                    priority: 6
                ))
            }
            
        default:
            break
        }
        
        return tooltips
    }
}

// MARK: - Tooltip UI Component

struct ShortcutTooltip: View {
    let tooltip: ShortcutDisclosureManager.TooltipState
    @Binding var isVisible: Bool
    
    var body: some View {
        if isVisible && tooltip.shouldShow {
            HStack(spacing: 6) {
                // Keyboard shortcut styling
                Text(tooltip.shortcut)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.primary.opacity(0.1))
                    .cornerRadius(4)
                
                // Description
                Text(tooltip.description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6))
            .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
            .transition(.opacity.combined(with: .scale(scale: 0.95)).animation(.easeInOut(duration: 0.2)))
        }
    }
}

// MARK: - View Extension for Easy Integration

extension View {
    func shortcutTooltip(
        element: String,
        context: String = "",
        disclosureManager: ShortcutDisclosureManager
    ) -> some View {
        self.overlay(alignment: .topTrailing) {
            if let tooltip = disclosureManager.getTooltipFor(element: element, context: context) {
                ShortcutTooltip(
                    tooltip: tooltip,
                    isVisible: .constant(tooltip.isVisible)
                )
                .offset(x: 10, y: -5)
            }
        }
    }
}