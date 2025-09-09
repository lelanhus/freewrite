import Foundation
import SwiftUI

/// User preferences system with minimal philosophy and progressive disclosure
@MainActor
@Observable
final class UserPreferences {
    
    // MARK: - Timer Preferences
    
    var defaultTimerDuration: Int = FreewriteConstants.defaultTimerDuration {
        didSet {
            // Validate timer bounds for methodology effectiveness
            // Note: Removed validation to prevent infinite loop - validation happens at usage points
        }
    }
    
    var autoStartTimer: Bool = false
    var timerSound: TimerSound = .subtleChime
    var sessionAutoAdvance: Bool = false // Create new entry when timer ends
    
    // MARK: - Constraint Preferences (Therapeutic Efficacy)
    
    var constraintLevel: ConstraintLevel = .standard
    var backspaceGracePeriod: Double = ProgressiveDisclosureConstants.minBackspaceGracePeriod { // Seconds of backspace tolerance
        didSet {
            // Maintain freewriting methodology integrity
            // Note: Removed validation to prevent infinite loop - validation happens at usage points
        }
    }
    var minimumSessionLength: Int = ProgressiveDisclosureConstants.defaultMinimumSessionLength // 5 minutes minimum for effectiveness
    
    // MARK: - AI Analysis Preferences
    
    var analysisStyle: AIAnalysisStyle = .friend
    var autoOpenAnalysis: Bool = false
    var analysisThreshold: Int = FreewriteConstants.minimumTextLength
    var privacyMode: Bool = false // Disable auto-opening URLs
    
    // MARK: - Experience Preferences
    
    var defaultToDistractionFree: Bool = false
    var showWordCountDuringSession: Bool = false
    var typingMomentumFeedback: Bool = false
    var sessionCount: Int = PerformanceConstants.initialErrorCount // Track user experience level
    
    // MARK: - Preference Categories
    
    enum TimerSound: String, CaseIterable {
        case none = "None"
        case subtleChime = "Subtle Chime"
        case gentleBell = "Gentle Bell"
        case completionTone = "Completion Tone"
    }
    
    enum ConstraintLevel: String, CaseIterable {
        case gentle = "Gentle" // For trauma recovery, emotional writing
        case standard = "Standard" // Classic freewriting methodology  
        case strict = "Strict" // Maximum constraint enforcement
        
        var backspaceAllowed: Bool {
            switch self {
            case .gentle: return true // 3 second grace period
            case .standard: return false // No backspace (classic)
            case .strict: return false // No backspace + stricter paste rules
            }
        }
    }
    
    enum AIAnalysisStyle: String, CaseIterable {
        case friend = "Friend" // Casual, supportive tone
        case therapist = "Therapist" // Professional, therapeutic approach
        case coach = "Coach" // Motivational, action-oriented
        case analyst = "Analyst" // Objective, pattern-focused
    }
    
    // MARK: - Progressive Disclosure
    
    struct SettingItem {
        let key: String
        let title: String
        let description: String
        let category: SettingCategory
        let minimumSessionsToShow: Int
    }
    
    enum SettingCategory {
        case essential // Timer, theme, basic constraints
        case methodology // Advanced constraints, session settings
        case ai // Analysis preferences, privacy
        case advanced // Power user features
    }
    
    func getAvailableSettings() -> [SettingItem] {
        let allSettings: [SettingItem] = [
            // Essential (show after 1 session)
            SettingItem(
                key: "timer", 
                title: "Default Timer",
                description: "How long should sessions last?",
                category: .essential,
                minimumSessionsToShow: ProgressiveDisclosureConstants.essentialSettingsThreshold
            ),
            SettingItem(
                key: "sound",
                title: "Timer Sound", 
                description: "Sound when session completes",
                category: .essential,
                minimumSessionsToShow: ProgressiveDisclosureConstants.essentialSettingsThreshold
            ),
            SettingItem(
                key: "constraints",
                title: "Writing Constraints",
                description: "How strict should the no-editing rules be?", 
                category: .essential,
                minimumSessionsToShow: ProgressiveDisclosureConstants.basicConstraintsThreshold
            ),
            
            // Methodology (show after 5 sessions)
            SettingItem(
                key: "gracePeriod",
                title: "Typo Grace Period",
                description: "Allow backspace for immediate typos (0-\(Int(ProgressiveDisclosureConstants.maxBackspaceGracePeriod)) seconds)",
                category: .methodology,
                minimumSessionsToShow: ProgressiveDisclosureConstants.methodologySettingsThreshold
            ),
            SettingItem(
                key: "autoStart",
                title: "Auto-Start Timer",
                description: "Start timer automatically with new sessions",
                category: .methodology, 
                minimumSessionsToShow: ProgressiveDisclosureConstants.methodologySettingsThreshold
            ),
            SettingItem(
                key: "minimumLength",
                title: "Minimum Session",
                description: "Enforce minimum writing time",
                category: .methodology,
                minimumSessionsToShow: ProgressiveDisclosureConstants.advancedMethodologyThreshold
            ),
            
            // AI (show after 10 sessions)
            SettingItem(
                key: "analysisStyle",
                title: "AI Analysis Style",
                description: "How should AI respond to your writing?",
                category: .ai,
                minimumSessionsToShow: ProgressiveDisclosureConstants.aiSettingsThreshold
            ),
            SettingItem(
                key: "autoAnalysis", 
                title: "Auto-Open Analysis",
                description: "Automatically open AI analysis after sessions",
                category: .ai,
                minimumSessionsToShow: ProgressiveDisclosureConstants.aiSettingsThreshold
            ),
            SettingItem(
                key: "privacyMode",
                title: "Privacy Mode",
                description: "Never auto-open external URLs",
                category: .ai,
                minimumSessionsToShow: ProgressiveDisclosureConstants.privacySettingsThreshold
            )
        ]
        
        return allSettings.filter { $0.minimumSessionsToShow <= sessionCount }
    }
    
    // MARK: - Persistence
    
    func save() {
        let defaults = UserDefaults.standard
        defaults.set(defaultTimerDuration, forKey: "defaultTimerDuration")
        defaults.set(autoStartTimer, forKey: "autoStartTimer")
        defaults.set(timerSound.rawValue, forKey: "timerSound")
        defaults.set(constraintLevel.rawValue, forKey: "constraintLevel")
        defaults.set(backspaceGracePeriod, forKey: "backspaceGracePeriod")
        defaults.set(analysisStyle.rawValue, forKey: "analysisStyle")
        defaults.set(autoOpenAnalysis, forKey: "autoOpenAnalysis")
        defaults.set(privacyMode, forKey: "privacyMode")
        defaults.set(sessionCount, forKey: "sessionCount")
    }
    
    func load() {
        let defaults = UserDefaults.standard
        defaultTimerDuration = defaults.integer(forKey: "defaultTimerDuration") == 0 ? 
            FreewriteConstants.defaultTimerDuration : defaults.integer(forKey: "defaultTimerDuration")
        autoStartTimer = defaults.bool(forKey: "autoStartTimer")
        backspaceGracePeriod = defaults.double(forKey: "backspaceGracePeriod")
        autoOpenAnalysis = defaults.bool(forKey: "autoOpenAnalysis")  
        privacyMode = defaults.bool(forKey: "privacyMode")
        sessionCount = defaults.integer(forKey: "sessionCount")
        
        // String enums with fallbacks
        if let soundValue = TimerSound(rawValue: defaults.string(forKey: "timerSound") ?? "") {
            timerSound = soundValue
        }
        if let constraintValue = ConstraintLevel(rawValue: defaults.string(forKey: "constraintLevel") ?? "") {
            constraintLevel = constraintValue  
        }
        if let styleValue = AIAnalysisStyle(rawValue: defaults.string(forKey: "analysisStyle") ?? "") {
            analysisStyle = styleValue
        }
    }
    
    func resetToDefaults() {
        defaultTimerDuration = FreewriteConstants.defaultTimerDuration
        autoStartTimer = false
        timerSound = .subtleChime
        constraintLevel = .standard
        backspaceGracePeriod = 0.0
        analysisStyle = .friend
        autoOpenAnalysis = false
        privacyMode = false
        // Note: Don't reset sessionCount - preserve user experience level
    }
    
    // MARK: - Initialization
    
    init() {
        load() // Load saved preferences on startup
    }
}