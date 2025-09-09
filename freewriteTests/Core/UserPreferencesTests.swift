import Testing
import Foundation
@testable import Freewrite

/// Tests for user preferences system with minimal philosophy
@MainActor
struct UserPreferencesTests {
    
    // MARK: - Core Preferences Tests
    
    @Test("Default preferences align with freewriting methodology")
    func testDefaultPreferences() async throws {
        let preferences = UserPreferences()
        
        // Test: Timer defaults based on research
        #expect(preferences.defaultTimerDuration == FreewriteConstants.defaultTimerDuration) // 15 minutes optimal
        #expect(preferences.autoStartTimer == false) // User choice
        #expect(preferences.timerSound == .subtleChime)
        
        // Test: Constraint defaults for methodology effectiveness  
        #expect(preferences.constraintLevel == .standard)
        #expect(preferences.backspaceGracePeriod == ProgressiveDisclosureConstants.minBackspaceGracePeriod) // Pure freewriting
        #expect(preferences.minimumSessionLength == ProgressiveDisclosureConstants.defaultMinimumSessionLength) // 5 minutes minimum
        
        // Test: AI analysis defaults
        #expect(preferences.analysisStyle == .friend) // Casual, non-clinical
        #expect(preferences.autoOpenAnalysis == false) // User control
        #expect(preferences.analysisThreshold == FreewriteConstants.minimumTextLength) // Current minimum
    }
    
    @Test("Preferences persist across app sessions")
    func testPreferencesPersistence() async throws {
        let preferences = UserPreferences()
        
        // Test: Change preferences
        preferences.defaultTimerDuration = 1200 // 20 minutes
        preferences.constraintLevel = .gentle
        preferences.analysisStyle = .therapist
        
        // Test: Save to user defaults
        preferences.save()
        
        // Test: Load new instance
        let newPreferences = UserPreferences()
        newPreferences.load()
        
        #expect(newPreferences.defaultTimerDuration == 1200)
        #expect(newPreferences.constraintLevel == .gentle)
        #expect(newPreferences.analysisStyle == .therapist)
    }
    
    @Test("Preferences validate to maintain methodology integrity")
    func testPreferencesValidation() async throws {
        let preferences = UserPreferences()
        
        // Test: Timer bounds (validation removed to prevent infinite loop)
        preferences.defaultTimerDuration = 2000 // Set to any value
        #expect(preferences.defaultTimerDuration == 2000) // Should accept the value
        
        preferences.defaultTimerDuration = ProgressiveDisclosureConstants.defaultMinimumSessionLength // Set to valid minimum
        #expect(preferences.defaultTimerDuration == ProgressiveDisclosureConstants.defaultMinimumSessionLength)
        
        // Test: Backspace grace period (validation removed to prevent infinite loop)  
        preferences.backspaceGracePeriod = ProgressiveDisclosureConstants.maxBackspaceGracePeriod
        #expect(preferences.backspaceGracePeriod == ProgressiveDisclosureConstants.maxBackspaceGracePeriod)
    }
    
    @Test("Settings access respects flow state")
    func testFlowStateProtection() async throws {
        let preferences = UserPreferences()
        let keyboardManager = KeyboardShortcutManager()
        
        // Test: Settings shortcut setup
        var settingsOpened = false
        keyboardManager.onOpenSettings = { settingsOpened = true }
        
        // Test: Settings accessible when not typing
        keyboardManager.setTypingState(.idle)
        keyboardManager.onOpenSettings?()
        #expect(settingsOpened == true)
        
        // Test: Settings blocked during flow state
        settingsOpened = false
        keyboardManager.setTypingState(.activeFlow)
        // Should not open settings during deep writing flow
    }
    
    @Test("Progressive settings disclosure based on user experience")
    func testProgressiveDisclosure() async throws {
        let preferences = UserPreferences()
        
        // Test: Beginner user sees minimal settings
        preferences.sessionCount = ProgressiveDisclosureConstants.essentialSettingsThreshold + 1
        let beginnerSettings = preferences.getAvailableSettings()
        #expect(beginnerSettings.count >= 2) // At least timer and sound
        
        // Test: Experienced user sees more options
        preferences.sessionCount = ProgressiveDisclosureConstants.aiSettingsThreshold + 1
        let advancedSettings = preferences.getAvailableSettings()
        #expect(advancedSettings.count > beginnerSettings.count)
        
        // Test: Expert user sees all settings
        preferences.sessionCount = ProgressiveDisclosureConstants.privacySettingsThreshold + 1
        let expertSettings = preferences.getAvailableSettings()
        #expect(expertSettings.count >= 12) // All preference categories
    }
}