import Foundation
import AppKit

/// Manages keyboard shortcuts with freewriting constraint awareness and flow state protection
@MainActor
final class KeyboardShortcutManager: @unchecked Sendable {
    
    // MARK: - Typing State Tracking
    
    enum TypingState {
        case idle           // Not actively typing
        case typing         // Regular typing
        case activeFlow     // Deep flow state - minimal interruptions
    }
    
    private var currentTypingState: TypingState = .idle
    private var lastKeystrokeTime: Date = Date.distantPast
    private let flowStateThreshold: TimeInterval = 10.0 // 10 seconds of continuous typing = flow
    
    // MARK: - Shortcut Action Handlers
    
    var onNewSession: (() -> Void)?
    var onTimerToggle: (() -> Void)?
    var onToggleDistractionFree: (() -> Void)?
    var onTimerPreset: ((Int) -> Void)?
    var onConstraintViolation: ((String) -> Void)?
    var onConstrainedPaste: (() -> Void)?
    var onExportForAI: (() -> Void)?
    var onToggleSidebar: (() -> Void)?
    
    // MARK: - Public Interface
    
    func setTypingState(_ state: TypingState) {
        currentTypingState = state
    }
    
    func updateTypingActivity() {
        lastKeystrokeTime = Date()
        
        // Auto-detect flow state based on continuous typing
        let timeSinceLastKeystroke = Date().timeIntervalSince(lastKeystrokeTime)
        if timeSinceLastKeystroke < 2.0 && currentTypingState != .activeFlow {
            // Continuous typing detected - likely entering flow
            currentTypingState = .typing
        }
    }
    
    func handleKeyEvent(_ event: NSEvent) -> Bool {
        guard event.type == .keyDown else { return false }
        guard let characters = event.charactersIgnoringModifiers else { return false }
        
        // Update typing state
        updateTypingActivity()
        
        // Handle command shortcuts
        if event.modifierFlags.contains(.command) {
            return handleCommandShortcut(characters, event: event)
        }
        
        return false // Not handled
    }
    
    // MARK: - Private Implementation
    
    private func handleCommandShortcut(_ key: String, event: NSEvent) -> Bool {
        // Check for flow state protection
        if currentTypingState == .activeFlow && !isEmergencyShortcut(key) {
            // Defer non-emergency shortcuts during flow state
            return false
        }
        
        switch key.lowercased() {
        // MARK: Essential Flow Shortcuts
        case "n":
            onNewSession?()
            return true
            
        case "t":
            onTimerToggle?()
            return true
            
        case "d":
            onToggleDistractionFree?()
            return true
            
        // MARK: Constraint Violations (Blocked)
        case "z":
            onConstraintViolation?("Undo blocked - freewriting constraints active")
            return true // Handled by blocking
            
        case "x":
            onConstraintViolation?("Cut blocked - freewriting constraints active")
            return true // Handled by blocking
            
        // MARK: Allowed with Constraints
        case "v":
            onConstrainedPaste?()
            return true
            
        case "c":
            // Copy allowed - doesn't modify text
            return false // Let system handle
            
        // MARK: Session Management
        case "e":
            if !event.modifierFlags.contains(.shift) {
                onExportForAI?()
                return true
            }
            return false
            
        case "o":
            onToggleSidebar?()
            return true
            
        // MARK: Timer Presets (⌘1-9)
        case "1", "2", "3", "4", "5", "6", "7", "8", "9":
            if let digit = Int(key) {
                let minutes = digit * 5 // 1=5min, 2=10min, etc.
                onTimerPreset?(minutes)
                return true
            }
            return false
            
        // MARK: System Shortcuts (Allow)
        case "w", "q", "m", ",":
            // Window, Quit, Minimize, Preferences - let system handle
            return false
            
        default:
            return false
        }
    }
    
    private func isEmergencyShortcut(_ key: String) -> Bool {
        // Emergency shortcuts that work even during flow state
        return ["d", "w", "q"].contains(key.lowercased())
    }
}

// MARK: - Shortcut Delegate Protocol

protocol KeyboardShortcutDelegate: AnyObject {
    func shortcutTriggered(_ shortcut: String, context: String)
    func constraintViolationOccurred(_ message: String)
}