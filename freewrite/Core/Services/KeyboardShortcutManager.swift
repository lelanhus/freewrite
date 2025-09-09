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
    private let flowStateThreshold: TimeInterval = KeyboardShortcutConstants.flowStateThreshold
    
    // MARK: - Performance Monitoring
    
    private var keyEventProcessingTimes: [TimeInterval] = []
    private let maxPerformanceSamples = KeyboardShortcutConstants.maxPerformanceSamples
    private var performanceWarningThreshold: TimeInterval = KeyboardShortcutConstants.performanceWarningThreshold
    
    // MARK: - Error Handling
    
    private var consecutiveErrors = PerformanceConstants.initialErrorCount
    private let maxConsecutiveErrors = KeyboardShortcutConstants.maxConsecutiveErrors
    private var lastErrorTime: Date = Date.distantPast
    private let errorCooldownPeriod: TimeInterval = KeyboardShortcutConstants.errorCooldownPeriod
    
    var onErrorReported: ((KeyboardEventError) -> Void)?
    
    // MARK: - Shortcut Action Handlers
    
    var onNewSession: (() -> Void)?
    var onTimerToggle: (() -> Void)?
    var onToggleDistractionFree: (() -> Void)?
    var onTimerPreset: ((Int) -> Void)?
    var onConstraintViolation: ((String) -> Void)?
    var onConstrainedPaste: (() -> Void)?
    var onExportForAI: (() -> Void)?
    var onToggleSidebar: (() -> Void)?
    var onOpenSettings: (() -> Void)?
    
    // MARK: - Public Interface
    
    func setTypingState(_ state: TypingState) {
        currentTypingState = state
    }
    
    func updateTypingActivity() {
        lastKeystrokeTime = Date()
        
        // Auto-detect flow state based on continuous typing
        let timeSinceLastKeystroke = Date().timeIntervalSince(lastKeystrokeTime)
        if timeSinceLastKeystroke < KeyboardShortcutConstants.typingContinuityThreshold && currentTypingState != .activeFlow {
            // Continuous typing detected - likely entering flow
            currentTypingState = .typing
        }
    }
    
    func handleKeyEvent(_ event: NSEvent) -> Bool {
        let startTime = CFAbsoluteTimeGetCurrent()
        defer {
            let processingTime = CFAbsoluteTimeGetCurrent() - startTime
            recordPerformanceMetric(processingTime)
        }
        
        do {
            return try handleKeyEventSafely(event)
        } catch {
            handleKeyboardError(error, event: event)
            return false // Fail safely - don't break typing flow
        }
    }
    
    private func handleKeyEventSafely(_ event: NSEvent) throws -> Bool {
        guard event.type == .keyDown else { return false }
        
        // Validate event data before processing
        guard let characters = event.charactersIgnoringModifiers, !characters.isEmpty else {
            throw KeyboardEventError.invalidEventData("Missing or empty characters")
        }
        
        // Update typing state with error boundary
        do {
            updateTypingActivity()
        } catch {
            throw KeyboardEventError.stateUpdateFailed("Failed to update typing activity: \(error)")
        }
        
        // Handle command shortcuts with error boundary
        if event.modifierFlags.contains(.command) {
            return try handleCommandShortcutSafely(characters, event: event)
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
        case "w", "q", "m":
            // System shortcuts - let system handle
            return false
            
        case ",":
            // Preferences - handle with our settings
            onOpenSettings?()
            return true
            
        default:
            return false
        }
    }
    
    private func isEmergencyShortcut(_ key: String) -> Bool {
        // Emergency shortcuts that work even during flow state
        return KeyboardShortcutConstants.emergencyShortcuts.contains(key.lowercased())
    }
    
    // MARK: - Performance Monitoring
    
    private func recordPerformanceMetric(_ processingTime: TimeInterval) {
        keyEventProcessingTimes.append(processingTime)
        
        // Maintain sample size limit
        if keyEventProcessingTimes.count > maxPerformanceSamples {
            keyEventProcessingTimes.removeFirst()
        }
        
        // Log warning if processing is slow (could interrupt typing flow)
        if processingTime > performanceWarningThreshold {
            let formattedTime = String(format: KeyboardShortcutConstants.timingFormatPrecision, processingTime * KeyboardShortcutConstants.millisecondsMultiplier)
            print("⚠️ Keyboard event processing slow: \(formattedTime)ms")
        }
    }
    
    func getPerformanceStats() -> (average: TimeInterval, max: TimeInterval, sampleCount: Int) {
        guard !keyEventProcessingTimes.isEmpty else {
            return (average: TimeInterval(PerformanceConstants.zeroValue), max: TimeInterval(PerformanceConstants.zeroValue), sampleCount: PerformanceConstants.emptyCount)
        }
        
        let sum = keyEventProcessingTimes.reduce(TimeInterval(PerformanceConstants.zeroValue), +)
        let average = sum / Double(keyEventProcessingTimes.count)
        let max = keyEventProcessingTimes.max() ?? TimeInterval(PerformanceConstants.zeroValue)
        
        return (average: average, max: max, sampleCount: keyEventProcessingTimes.count)
    }
    
    // MARK: - Error Handling Methods
    
    private func handleCommandShortcutSafely(_ key: String, event: NSEvent) throws -> Bool {
        // Check for flow state protection
        if currentTypingState == .activeFlow && !isEmergencyShortcut(key) {
            return false
        }
        
        guard !key.isEmpty else {
            throw KeyboardEventError.invalidEventData("Empty key string")
        }
        
        let lowerKey = key.lowercased()
        
        switch lowerKey {
        case "n":
            try executeCallbackSafely(onNewSession, shortcut: "⌘N")
            return true
        case "t":
            try executeCallbackSafely(onTimerToggle, shortcut: "⌘T")
            return true
        case "d":
            try executeCallbackSafely(onToggleDistractionFree, shortcut: "⌘D")
            return true
        case "z":
            try executeCallbackSafely({ self.onConstraintViolation?("Undo blocked - freewriting constraints active") }, shortcut: "⌘Z")
            return true
        case "x":
            try executeCallbackSafely({ self.onConstraintViolation?("Cut blocked - freewriting constraints active") }, shortcut: "⌘X")
            return true
        case "v":
            try executeCallbackSafely(onConstrainedPaste, shortcut: "⌘V")
            return true
        case "c":
            return false // Let system handle
        case "e":
            if !event.modifierFlags.contains(.shift) {
                try executeCallbackSafely(onExportForAI, shortcut: "⌘E")
                return true
            }
            return false
        case "o":
            try executeCallbackSafely(onToggleSidebar, shortcut: "⌘O")
            return true
        case "1", "2", "3", "4", "5", "6", "7", "8", "9":
            guard KeyboardShortcutConstants.validTimerPresetDigits.contains(lowerKey),
                  let digit = Int(lowerKey) else {
                throw KeyboardEventError.callbackExecutionFailed("Failed to parse timer preset digit: \(lowerKey)")
            }
            let minutes = digit * KeyboardShortcutConstants.timerPresetMultiplier
            try executeCallbackSafely({ self.onTimerPreset?(minutes) }, shortcut: "⌘\(digit)")
            return true
        case "w", "q", "m":
            return false // Let system handle
        case ",":
            try executeCallbackSafely(onOpenSettings, shortcut: "⌘,")
            return true
        default:
            return false
        }
    }
    
    private func executeCallbackSafely(_ callback: (() -> Void)?, shortcut: String) throws {
        guard let callback = callback else {
            throw KeyboardEventError.callbackNotSet("No callback set for shortcut: \(shortcut)")
        }
        
        do {
            callback()
        } catch {
            throw KeyboardEventError.callbackExecutionFailed("Callback execution failed for \(shortcut): \(error)")
        }
    }
    
    private func handleKeyboardError(_ error: Error, event: NSEvent) {
        consecutiveErrors += 1
        lastErrorTime = Date()
        
        let keyboardError: KeyboardEventError
        if let existingError = error as? KeyboardEventError {
            keyboardError = existingError
        } else {
            keyboardError = KeyboardEventError.unexpectedError("Unexpected error: \(error)")
        }
        
        var errorContext = "Event: type=\(event.type.rawValue), modifiers=\(event.modifierFlags.rawValue)"
        if let chars = event.charactersIgnoringModifiers {
            errorContext += ", chars='\(chars)'"
        }
        errorContext += ", state=\(currentTypingState), errors=\(consecutiveErrors)"
        
        print("⚠️ Keyboard event error (\(consecutiveErrors)/\(maxConsecutiveErrors)): \(keyboardError.localizedDescription)")
        print("📋 Context: \(errorContext)")
        
        if consecutiveErrors >= maxConsecutiveErrors {
            print("🚫 Too many keyboard errors. Temporarily limiting shortcuts.")
        }
        
        onErrorReported?(keyboardError)
        
        if Date().timeIntervalSince(lastErrorTime) > errorCooldownPeriod {
            consecutiveErrors = PerformanceConstants.initialErrorCount
        }
    }
    
    func getErrorStats() -> (consecutiveErrors: Int, lastErrorTime: Date, isInCooldown: Bool) {
        let isInCooldown = Date().timeIntervalSince(lastErrorTime) < errorCooldownPeriod
        return (consecutiveErrors: consecutiveErrors, lastErrorTime: lastErrorTime, isInCooldown: isInCooldown)
    }
    
    func resetErrorState() {
        consecutiveErrors = PerformanceConstants.initialErrorCount
        lastErrorTime = Date.distantPast
    }
}

// MARK: - Shortcut Delegate Protocol

protocol KeyboardShortcutDelegate: AnyObject {
    func shortcutTriggered(_ shortcut: String, context: String)
    func constraintViolationOccurred(_ message: String)
    func keyboardErrorOccurred(_ error: KeyboardEventError)
}

// MARK: - Error Types

enum KeyboardEventError: LocalizedError {
    case invalidEventData(String)
    case stateUpdateFailed(String)
    case callbackNotSet(String)
    case callbackExecutionFailed(String)
    case unexpectedError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidEventData(let message):
            return "Invalid keyboard event data: \(message)"
        case .stateUpdateFailed(let message):
            return "State update failed: \(message)"
        case .callbackNotSet(let message):
            return "Callback not set: \(message)"
        case .callbackExecutionFailed(let message):
            return "Callback execution failed: \(message)"
        case .unexpectedError(let message):
            return "Unexpected keyboard error: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidEventData:
            return "This usually indicates a system-level keyboard event issue. Try restarting the application."
        case .stateUpdateFailed:
            return "The keyboard state manager encountered an error. Typing should continue to work normally."
        case .callbackNotSet:
            return "A keyboard shortcut was triggered but no handler was configured. This is a development issue."
        case .callbackExecutionFailed:
            return "A keyboard shortcut handler failed to execute. The shortcut will be temporarily disabled."
        case .unexpectedError:
            return "An unexpected error occurred. Keyboard shortcuts will be temporarily disabled for safety."
        }
    }
}