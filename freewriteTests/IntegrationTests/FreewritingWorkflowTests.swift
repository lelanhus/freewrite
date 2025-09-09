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
        // Setup services - using real services for integration testing
        let fileService = FileManagementService()
        let aiService = AIIntegrationService()
        let timer = FreewriteTimer()
        
        // Test: Create new entry
        let entry = try await fileService.createNewEntry()
        #expect(entry.id != UUID(uuidString: "00000000-0000-0000-0000-000000000000"))
        #expect(entry.filename.contains(entry.id.uuidString))
        
        // Test: Write content
        let testContent = "\n\nThis is a test freewriting session about breakthrough thinking"
        try await fileService.saveEntry(entry.id, content: testContent)
        
        // Test: Timer integration
        timer.start()
        #expect(timer.isRunning == true)
        #expect(timer.timeRemaining == FreewriteConstants.defaultTimerDuration)
        
        // Test: Load saved content
        let savedContent = try await fileService.loadEntry(entry.id)
        #expect(savedContent == testContent)
        
        // Test: AI analysis preparation
        let canShare = aiService.canShareViaURL(testContent)
        #expect(canShare == true) // Short content should be shareable
        
        // Test: Complete workflow success
        #expect(entry.wordCount >= 0)
        #expect(!entry.previewText.isEmpty)
    }
    
    // MARK: - Keyboard Shortcut Integration
    
    @Test("Keyboard shortcuts properly integrate with services and state")
    func testKeyboardShortcutIntegration() async throws {
        let keyboardManager = KeyboardShortcutManager()
        let timer = FreewriteTimer()
        let fileService = FileManagementService()
        
        // Test: ⌘T timer toggle integration
        var timerToggled = false
        keyboardManager.onTimerToggle = {
            if timer.isRunning {
                timer.pause()
            } else {
                timer.start()
            }
            timerToggled = true
        }
        
        let timerEvent = NSEvent.keyEvent(
            with: .keyDown,
            location: NSPoint.zero,
            modifierFlags: [.command],
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            characters: "t",
            charactersIgnoringModifiers: "t",
            isARepeat: false,
            keyCode: 0
        )!
        
        let handled = keyboardManager.handleKeyEvent(timerEvent)
        
        #expect(handled == true)
        #expect(timerToggled == true)
        #expect(timer.isRunning == true)
        
        // Test: ⌘N new session integration
        var newSessionCreated = false
        keyboardManager.onNewSession = {
            newSessionCreated = true
            timer.reset()
            timer.start()
        }
        
        let newSessionEvent = NSEvent.keyEvent(
            with: .keyDown,
            location: NSPoint.zero,
            modifierFlags: [.command],
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            characters: "n",
            charactersIgnoringModifiers: "n",
            isARepeat: false,
            keyCode: 0
        )!
        
        let newSessionHandled = keyboardManager.handleKeyEvent(newSessionEvent)
        
        #expect(newSessionHandled == true)
        #expect(newSessionCreated == true)
        #expect(timer.isRunning == true)
        #expect(timer.timeRemaining == FreewriteConstants.defaultTimerDuration)
    }
    
    // MARK: - File Operations Integration
    
    @Test("File operations integrate properly with UI state and error handling")
    func testFileOperationIntegration() async throws {
        let fileService = FileManagementService()
        let errorManager = ErrorManager()
        
        // Test: Successful file operation
        let entry = try await fileService.createNewEntry()
        #expect(errorManager.currentError == nil)
        
        // Test: File operation error handling  
        fileService.shouldFailOperations = true
        
        do {
            _ = try await fileService.createNewEntry()
            #expect(Bool(false), "Should have thrown error")
        } catch {
            #expect(error is FreewriteError)
        }
    }
    
    // MARK: - Constraint Integration
    
    @Test("Text constraints integrate with keyboard shortcuts and UI")
    func testConstraintIntegration() async throws {
        let validator = TextConstraintValidator.self
        let keyboardManager = KeyboardShortcutManager()
        
        // Test: Constraint violation detection
        var violationDetected = false
        var violationMessage = ""
        
        keyboardManager.onConstraintViolation = { message in
            violationDetected = true
            violationMessage = message
        }
        
        // Test blocked shortcuts
        let undoEvent = NSEvent.keyEvent(
            with: .keyDown,
            location: NSPoint.zero,
            modifierFlags: [.command],
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            characters: "z",
            charactersIgnoringModifiers: "z",
            isARepeat: false,
            keyCode: 0
        )!
        
        let handled = keyboardManager.handleKeyEvent(undoEvent)
        
        #expect(handled == true)
        #expect(violationDetected == true)
        #expect(violationMessage.contains("Undo blocked"))
        
        // Test text constraint validation
        let currentText = "\n\nHello world"
        let invalidText = "\n\nHello"  // Shortened text
        
        let result = validator.validateSimpleTextChange(
            newText: invalidText,
            currentText: currentText
        )
        
        #expect(result.shouldProvideFeedback == true)
        #expect(result.correctedText == currentText)
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