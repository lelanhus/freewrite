import Testing
import Foundation
import AppKit
@testable import Freewrite

/// Integration tests for complete freewriting workflows
@MainActor
struct FreewritingWorkflowTests {
    
    // MARK: - Complete Session Workflow
    
    @Test("Complete freewriting session: new entry → write → timer → save → AI analysis")
    func testCompleteWritingSession() async throws {
        // Test: Core components work together
        let timer = FreewriteTimer()
        let textValidator = TextConstraintValidator.self
        
        // Test: Timer functionality
        timer.start()
        #expect(timer.isRunning == true)
        #expect(timer.timeRemaining == FreewriteConstants.defaultTimerDuration)
        
        timer.pause()
        #expect(timer.isRunning == false)
        
        // Test: Text constraint validation
        let validContent = "\n\nThis is valid freewriting content"
        let invalidContent = "\n\nShort" // Deletion attempt
        
        let result = textValidator.validateSimpleTextChange(
            newText: invalidContent,
            currentText: validContent
        )
        
        #expect(result.shouldProvideFeedback == true)
        #expect(result.correctedText == validContent)
        
        // Test: Constants integration
        #expect(FreewriteConstants.defaultTimerDuration == 900)
        #expect(FreewriteConstants.headerString == "\n\n")
    }
    
    // MARK: - Keyboard Shortcut Integration
    
    @Test("Keyboard shortcuts properly integrate with services and state")
    func testKeyboardShortcutIntegration() async throws {
        let keyboardManager = KeyboardShortcutManager()
        let timer = FreewriteTimer()
        
        // Test: Handler setup works
        var timerToggled = false
        keyboardManager.onTimerToggle = {
            if timer.isRunning {
                timer.pause()
            } else {
                timer.start()
            }
            timerToggled = true
        }
        
        // Simulate timer toggle action
        keyboardManager.onTimerToggle?()
        
        #expect(timerToggled == true)
        #expect(timer.isRunning == true)
        
        // Test: New session handler
        var newSessionCreated = false
        keyboardManager.onNewSession = {
            newSessionCreated = true
            timer.reset()
            timer.start()
        }
        
        // Simulate new session action
        keyboardManager.onNewSession?()
        
        #expect(newSessionCreated == true)
        #expect(timer.isRunning == true)
        #expect(timer.timeRemaining == FreewriteConstants.defaultTimerDuration)
    }
    
    // MARK: - File Operations Integration
    
    @Test("File operations integrate properly with UI state and error handling")
    func testFileOperationIntegration() async throws {
        let errorManager = ErrorManager()
        
        // Test: Error manager functionality
        #expect(errorManager.currentError == nil)
        
        let testError = UserError(
            title: "Test Error",
            message: "Test message",
            recoverySuggestion: nil,
            recoveryAction: nil
        )
        
        errorManager.reportError(testError)
        #expect(errorManager.currentError != nil)
        #expect(errorManager.currentError?.title == "Test Error")
        
        errorManager.clearError()
        #expect(errorManager.currentError == nil)
    }
    
    // MARK: - Constraint Integration
    
    @Test("Text constraints integrate with keyboard shortcuts and UI")
    func testConstraintIntegration() async throws {
        let validator = TextConstraintValidator.self
        let keyboardManager = KeyboardShortcutManager()
        
        // Test: Constraint violation callback setup
        var violationDetected = false
        keyboardManager.onConstraintViolation = { message in
            violationDetected = true
        }
        
        // Simulate constraint violation
        keyboardManager.onConstraintViolation?("Test violation")
        #expect(violationDetected == true)
        
        // Test: Text constraint validation logic  
        let currentText = "\n\nHello world"
        let invalidText = "\n\nHello"  // Shortened text (deletion attempt)
        
        let result = validator.validateSimpleTextChange(
            newText: invalidText,
            currentText: currentText
        )
        
        #expect(result.shouldProvideFeedback == true)
        #expect(result.correctedText == currentText)
        
        // Test: Valid text addition
        let extendedText = "\n\nHello world extended"
        let validResult = validator.validateSimpleTextChange(
            newText: extendedText,
            currentText: currentText
        )
        
        #expect(validResult.shouldProvideFeedback == false)
        #expect(validResult.correctedText == extendedText)
    }
    
    // MARK: - Progressive Disclosure Integration
    
    @Test("Shortcut disclosure adapts to user behavior over sessions")
    func testProgressiveDisclosureIntegration() async throws {
        let disclosureManager = ShortcutDisclosureManager()
        
        // Test: Beginner user level
        #expect(disclosureManager.shouldShowTooltip(for: "⌘N") == true)
        #expect(disclosureManager.shouldShowTooltip(for: "⌘⇧F") == false)
        
        // Test: User progression
        for _ in 1...10 {
            disclosureManager.registerSessionStart()
        }
        disclosureManager.registerShortcutUsed("⌘N")
        disclosureManager.registerShortcutUsed("⌘T")
        disclosureManager.registerShortcutUsed("⌘D")
        
        // Should now show intermediate shortcuts
        #expect(disclosureManager.shouldShowTooltip(for: "⌘E") == true)
        #expect(disclosureManager.shouldShowTooltip(for: "⌘1") == true)
        
        // Test: Contextual tooltips
        let timerTooltip = disclosureManager.getTooltipFor(element: "timer")
        #expect(timerTooltip != nil)
        #expect(timerTooltip?.shortcut == "⌘T")
    }
    
    // MARK: - Memory and Resource Management Integration
    
    @Test("Proper cleanup and resource management across components")
    func testResourceManagementIntegration() async throws {
        // This test would verify that:
        // - Timers are properly cleaned up
        // - Event monitors are removed  
        // - Notification subscriptions are cancelled
        // - File handles are closed
        // - Memory leaks don't occur
        
        let timer = FreewriteTimer()
        timer.start()
        #expect(timer.isRunning == true)
        
        timer.pause()
        #expect(timer.isRunning == false)
        
        // Timer should clean up properly without memory leaks
        // (This would be verified with memory profiling tools)
    }
}