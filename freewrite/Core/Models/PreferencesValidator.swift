import Foundation

/// Validation utilities for user preferences that prevent infinite loops
@MainActor
struct PreferencesValidator {
    
    // MARK: - Timer Duration Validation
    
    /// Validates and clamps timer duration to methodology-effective bounds
    static func validateTimerDuration(_ duration: Int) -> Int {
        let minDuration = ProgressiveDisclosureConstants.defaultMinimumSessionLength
        let maxDuration = FreewriteConstants.maxTimerDuration
        
        return max(minDuration, min(duration, maxDuration))
    }
    
    /// Checks if timer duration is within valid bounds
    static func isValidTimerDuration(_ duration: Int) -> Bool {
        let minDuration = ProgressiveDisclosureConstants.defaultMinimumSessionLength
        let maxDuration = FreewriteConstants.maxTimerDuration
        
        return duration >= minDuration && duration <= maxDuration
    }
    
    // MARK: - Backspace Grace Period Validation
    
    /// Validates and clamps backspace grace period to freewriting methodology bounds
    static func validateBackspaceGracePeriod(_ period: Double) -> Double {
        let minPeriod = ProgressiveDisclosureConstants.minBackspaceGracePeriod
        let maxPeriod = ProgressiveDisclosureConstants.maxBackspaceGracePeriod
        
        return max(minPeriod, min(period, maxPeriod))
    }
    
    /// Checks if backspace grace period is within methodology bounds
    static func isValidBackspaceGracePeriod(_ period: Double) -> Bool {
        let minPeriod = ProgressiveDisclosureConstants.minBackspaceGracePeriod
        let maxPeriod = ProgressiveDisclosureConstants.maxBackspaceGracePeriod
        
        return period >= minPeriod && period <= maxPeriod
    }
    
    // MARK: - Session Count Validation
    
    /// Validates session count for progressive disclosure
    static func validateSessionCount(_ count: Int) -> Int {
        return max(PerformanceConstants.zeroValue, count)
    }
    
    /// Checks if session count is valid
    static func isValidSessionCount(_ count: Int) -> Bool {
        return count >= PerformanceConstants.zeroValue
    }
    
    // MARK: - Minimum Session Length Validation
    
    /// Validates minimum session length for methodology effectiveness
    static func validateMinimumSessionLength(_ length: Int) -> Int {
        let minLength = ProgressiveDisclosureConstants.defaultMinimumSessionLength
        let maxLength = FreewriteConstants.maxTimerDuration
        
        return max(minLength, min(length, maxLength))
    }
    
    /// Checks if minimum session length is valid
    static func isValidMinimumSessionLength(_ length: Int) -> Bool {
        let minLength = ProgressiveDisclosureConstants.defaultMinimumSessionLength
        let maxLength = FreewriteConstants.maxTimerDuration
        
        return length >= minLength && length <= maxLength
    }
    
    // MARK: - Settings UI Validation
    
    /// Validates that all preferences are within acceptable bounds for UI display
    static func validateAllPreferences(_ preferences: UserPreferences) -> [String] {
        var validationErrors: [String] = []
        
        if !isValidTimerDuration(preferences.defaultTimerDuration) {
            validationErrors.append("Timer duration must be between \(ProgressiveDisclosureConstants.defaultMinimumSessionLength/60) and \(FreewriteConstants.maxTimerDuration/60) minutes")
        }
        
        if !isValidBackspaceGracePeriod(preferences.backspaceGracePeriod) {
            validationErrors.append("Backspace grace period must be between \(ProgressiveDisclosureConstants.minBackspaceGracePeriod) and \(ProgressiveDisclosureConstants.maxBackspaceGracePeriod) seconds")
        }
        
        if !isValidMinimumSessionLength(preferences.minimumSessionLength) {
            validationErrors.append("Minimum session length must be between \(ProgressiveDisclosureConstants.defaultMinimumSessionLength/60) and \(FreewriteConstants.maxTimerDuration/60) minutes")
        }
        
        return validationErrors
    }
    
    /// Returns validated preference values without modifying the original
    static func getValidatedPreferences(_ preferences: UserPreferences) -> (
        timerDuration: Int,
        gracePeriod: Double, 
        minimumLength: Int,
        sessionCount: Int
    ) {
        return (
            timerDuration: validateTimerDuration(preferences.defaultTimerDuration),
            gracePeriod: validateBackspaceGracePeriod(preferences.backspaceGracePeriod),
            minimumLength: validateMinimumSessionLength(preferences.minimumSessionLength),
            sessionCount: validateSessionCount(preferences.sessionCount)
        )
    }
}