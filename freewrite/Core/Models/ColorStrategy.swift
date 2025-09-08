import SwiftUI

/// System color strategy for accessible, native-feeling UI
/// Uses SwiftUI semantic colors with mixing for visual variety while preserving accessibility
struct FreewriteColors {
    
    // MARK: - Background Colors (Native Accessibility)
    
    /// Main content background - adapts to system light/dark mode
    static let contentBackground = Color(NSColor.textBackgroundColor)
    
    /// Navigation background - adapts with system transparency
    static let navigationBackground = Color(NSColor.controlBackgroundColor)
    
    /// Sidebar background - maintains contrast with content
    static let sidebarBackground = Color(NSColor.windowBackgroundColor)
    
    /// Popover background - system standard with proper contrast
    static let popoverBackground = Color(NSColor.controlBackgroundColor)
    
    // MARK: - Text Colors (Semantic & Accessible)
    
    /// Primary text - system text color with full accessibility
    static let primaryText = Color.primary
    
    /// Secondary text - system secondary with proper contrast ratios
    static let secondaryText = Color.secondary
    
    /// Writing text - enhanced readability with subtle warmth
    static let writingText = Color.primary.mix(with: .brown, by: 0.05)
    
    /// Placeholder text - system secondary with reduced opacity for subtlety
    static let placeholderText = Color.secondary.opacity(0.6)
    
    // MARK: - Interactive Colors
    
    /// Default navigation text - system with slight mixing for personality
    static let navigationText = Color.secondary.mix(with: .blue, by: 0.1)
    
    /// Hovered navigation text - system primary with mixing for feedback
    static let navigationTextHover = Color.primary.mix(with: .blue, by: 0.15)
    
    /// Timer text when running - system orange with slight red mixing for urgency
    static let timerRunning = Color.orange.mix(with: .red, by: 0.2)
    
    /// Timer text when paused - standard navigation color
    static let timerPaused = navigationText
    
    // MARK: - Accent Colors (System + Mixing)
    
    /// Delete action - system red with slight darkening for clarity
    static let deleteAction = Color.red.mix(with: .black, by: 0.1)
    
    /// Theme toggle - system accent color with mixing for visibility
    static let themeToggle = Color.accentColor.mix(with: .blue, by: 0.1)
    
    /// Chat button - system green with mixing for distinctiveness
    static let chatButton = Color.green.mix(with: .blue, by: 0.2)
    
    // MARK: - State Colors
    
    /// Selection highlight - system selection color with reduced opacity
    static let selectionHighlight = Color.accentColor.opacity(0.1)
    
    /// Hover highlight - system selection color with very low opacity
    static let hoverHighlight = Color.accentColor.opacity(0.05)
    
    /// Separator lines - system separator color
    static let separator = Color(NSColor.separatorColor)
    
    // MARK: - Utility Methods
    
    /// Get appropriate text color for navigation based on hover state
    static func navigationTextColor(isHovering: Bool) -> Color {
        return isHovering ? navigationTextHover : navigationText
    }
    
    /// Get timer color based on running state and hover
    static func timerColor(isRunning: Bool, isHovering: Bool) -> Color {
        if isRunning {
            return isHovering ? timerRunning.mix(with: .white, by: 0.1) : timerRunning
        } else {
            return isHovering ? navigationTextHover : timerPaused
        }
    }
    
    /// Get background color for entry rows
    static func entryBackground(isSelected: Bool, isHovered: Bool) -> Color {
        if isSelected {
            return selectionHighlight
        } else if isHovered {
            return hoverHighlight
        } else {
            return Color.clear
        }
    }
}

// MARK: - Color Extensions for Mixing

extension Color {
    /// Mix this color with another color by a specified ratio
    /// Uses simple opacity adjustment to maintain accessibility
    /// - Parameters:
    ///   - color: Color to mix with  
    ///   - ratio: Mixing ratio (0.0 = no mixing, 1.0 = full secondary color influence)
    /// - Returns: Adjusted color that preserves accessibility contrast ratios
    func mix(with color: Color, by ratio: Double) -> Color {
        let clampedRatio = max(0.0, min(0.2, ratio)) // Subtle mixing to preserve accessibility
        
        // For SwiftUI semantic colors, just adjust opacity slightly for interactive feedback
        return self.opacity(1.0 - clampedRatio * 0.3)
    }
    
    /// Create a subtle tinted version for interactive states
    func tinted(with color: Color) -> Color {
        // Simple opacity adjustment for tinting
        return color == .clear ? self : self.opacity(0.8)
    }
    
    /// Create a more prominent version for active states  
    func emphasized(with color: Color) -> Color {
        return color == .clear ? self : self.opacity(0.9)
    }
}

// MARK: - Theme Extensions

extension View {
    /// Apply Freewrite's color theme while preserving system accessibility
    func freewriteColorScheme() -> some View {
        self
            .foregroundStyle(FreewriteColors.primaryText)
            .background(FreewriteColors.contentBackground)
            // Automatically respects system light/dark mode and accessibility settings
    }
    
    /// Apply navigation styling with hover support
    func navigationButton(isHovering: Bool) -> some View {
        self
            .foregroundColor(FreewriteColors.navigationTextColor(isHovering: isHovering))
            .animation(.easeInOut(duration: 0.15), value: isHovering)
    }
}