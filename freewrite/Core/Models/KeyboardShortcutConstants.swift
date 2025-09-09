import Foundation

/// Constants for keyboard shortcut system configuration and performance monitoring
struct KeyboardShortcutConstants {
    
    // MARK: - Flow State Detection
    
    /// Time threshold for continuous typing to detect flow state (seconds)
    static let flowStateThreshold: TimeInterval = 10.0
    
    /// Maximum time between keystrokes to maintain typing state (seconds)
    static let typingContinuityThreshold: TimeInterval = 2.0
    
    // MARK: - Performance Monitoring
    
    /// Maximum number of performance samples to keep in memory
    static let maxPerformanceSamples = 100
    
    /// Processing time threshold that triggers performance warnings (seconds)
    /// Events taking longer than this may interrupt typing flow
    static let performanceWarningThreshold: TimeInterval = 0.002 // 2ms
    
    /// Multiplier to convert seconds to milliseconds for logging
    static let millisecondsMultiplier: Double = 1000.0
    
    /// Format precision for performance timing display
    static let timingFormatPrecision = "%.3f"
    
    // MARK: - Error Handling
    
    /// Maximum consecutive errors before temporarily limiting shortcuts
    static let maxConsecutiveErrors = 5
    
    /// Cooldown period between error bursts (seconds)
    static let errorCooldownPeriod: TimeInterval = 30.0
    
    // MARK: - Timer Presets
    
    /// Minutes per timer preset digit (1=5min, 2=10min, etc.)
    static let timerPresetMultiplier = 5
    
    /// Valid timer preset digits
    static let validTimerPresetDigits: Set<String> = ["1", "2", "3", "4", "5", "6", "7", "8", "9"]
    
    // MARK: - Emergency Shortcuts
    
    /// Shortcuts that work even during deep flow state
    static let emergencyShortcuts: Set<String> = ["d", "w", "q"]
    
    // MARK: - System Integration
    
    /// Shortcuts that should be handled by the system, not blocked
    static let systemShortcuts: Set<String> = ["w", "q", "m", "c"]
    
    /// Shortcuts that violate freewriting constraints and should be blocked
    static let constraintViolatingShortcuts: Set<String> = ["z", "x"]
}

/// Constants for progressive disclosure in user preferences
struct ProgressiveDisclosureConstants {
    
    // MARK: - Session Thresholds for Feature Revelation
    
    /// Sessions required to show essential settings (timer, sound, basic constraints)
    static let essentialSettingsThreshold = 1
    
    /// Sessions required to show basic constraint settings
    static let basicConstraintsThreshold = 3
    
    /// Sessions required to show methodology settings (grace period, auto-start)
    static let methodologySettingsThreshold = 5
    
    /// Sessions required to show advanced methodology settings (minimum session)
    static let advancedMethodologyThreshold = 10
    
    /// Sessions required to show AI analysis settings
    static let aiSettingsThreshold = 10
    
    /// Sessions required to show privacy settings
    static let privacySettingsThreshold = 15
    
    // MARK: - Constraint Configuration
    
    /// Minimum backspace grace period (seconds)
    static let minBackspaceGracePeriod: Double = 0.0
    
    /// Maximum backspace grace period (seconds) 
    static let maxBackspaceGracePeriod: Double = 3.0
    
    /// Default minimum session length for effectiveness (seconds)
    static let defaultMinimumSessionLength = 300 // 5 minutes
    
    /// Grace period for gentle constraint mode (seconds)
    static let gentleModeGracePeriod: Double = 3.0
}

/// Constants for performance and optimization settings
struct PerformanceConstants {
    
    // MARK: - Memory Management
    
    /// Default value for zero state checks
    static let zeroValue = 0
    
    /// Default empty count for collections
    static let emptyCount = 0
    
    /// Initial value for error counters
    static let initialErrorCount = 0
    
    // MARK: - Timing Precision
    
    /// Number of decimal places for performance metrics
    static let performanceDecimalPlaces = 3
    
    /// Minimum meaningful time interval (microseconds)
    static let minimumTimeInterval: TimeInterval = 0.000001
}