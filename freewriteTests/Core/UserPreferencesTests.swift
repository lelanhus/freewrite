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
        #expect(preferences.defaultTimerDuration == 900) // 15 minutes optimal
        #expect(preferences.autoStartTimer == false) // User choice
        #expect(preferences.timerSound == .subtleChime)
        
        // Test: Constraint defaults for methodology effectiveness  
        #expect(preferences.constraintLevel == .standard)
        #expect(preferences.backspaceGracePeriod == 0) // Pure freewriting
        #expect(preferences.minimumSessionLength == 300) // 5 minutes minimum
        
        // Test: AI analysis defaults
        #expect(preferences.analysisStyle == .friend) // Casual, non-clinical
        #expect(preferences.autoOpenAnalysis == false) // User control
        #expect(preferences.analysisThreshold == 350) // Current minimum
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
        
        // Test: Timer bounds validation
        preferences.defaultTimerDuration = 2000 // Invalid (too long)
        #expect(preferences.defaultTimerDuration == FreewriteConstants.maxTimerDuration)
        
        preferences.defaultTimerDuration = 60 // Invalid (too short)
        #expect(preferences.defaultTimerDuration >= 300) // 5 minute minimum
        
        // Test: Constraint validation
        preferences.backspaceGracePeriod = 10 // Too long for freewriting
        #expect(preferences.backspaceGracePeriod <= 3) // Maximum 3 seconds
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
        preferences.sessionCount = 2
        let beginnerSettings = preferences.getAvailableSettings()
        #expect(beginnerSettings.count <= 4) // Timer, theme, sound, constraints
        
        // Test: Experienced user sees more options
        preferences.sessionCount = 20
        let advancedSettings = preferences.getAvailableSettings()
        #expect(advancedSettings.count > beginnerSettings.count)
        
        // Test: Expert user sees all settings
        preferences.sessionCount = 50
        let expertSettings = preferences.getAvailableSettings()
        #expect(expertSettings.count >= 12) // All preference categories
    }
}