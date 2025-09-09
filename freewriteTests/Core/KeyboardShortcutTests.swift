import Testing
import AppKit
@testable import freewrite

/// Tests for keyboard shortcut system with freewriting constraint respect
@MainActor
struct KeyboardShortcutTests {
    
    // MARK: - Test Setup
    
    private func createShortcutManager() -> KeyboardShortcutManager {
        let manager = KeyboardShortcutManager()
        return manager
    }
    
    private func createKeyEvent(key: String, modifiers: NSEvent.ModifierFlags = []) -> NSEvent {
        // Helper to create test key events
        return NSEvent.keyEvent(
            with: .keyDown,
            location: NSPoint.zero,
            modifierFlags: modifiers,
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            characters: key,
            charactersIgnoringModifiers: key,
            isARepeat: false,
            keyCode: 0
        )!
    }
    
    // MARK: - Essential Flow Shortcuts Tests
    
    @Test("⌘N creates new session without breaking flow")
    func testNewSessionShortcut() async {
        let manager = createShortcutManager()
        let event = createKeyEvent(key: "n", modifiers: [.command])
        
        var newSessionCalled = false
        manager.onNewSession = { newSessionCalled = true }
        
        let handled = manager.handleKeyEvent(event)
        
        #expect(handled == true)
        #expect(newSessionCalled == true)
    }
    
    @Test("⌘T toggles timer without UI interruption")
    func testTimerToggleShortcut() async {
        let manager = createShortcutManager()
        let event = createKeyEvent(key: "t", modifiers: [.command])
        
        var timerToggleCalled = false
        manager.onTimerToggle = { timerToggleCalled = true }
        
        let handled = manager.handleKeyEvent(event)
        
        #expect(handled == true)
        #expect(timerToggleCalled == true)
    }
    
    @Test("⌘D toggles distraction-free mode")
    func testDistactionFreeShortcut() async {
        let manager = createShortcutManager()
        let event = createKeyEvent(key: "d", modifiers: [.command])
        
        var distractionFreeCalled = false
        manager.onToggleDistractionFree = { distractionFreeCalled = true }
        
        let handled = manager.handleKeyEvent(event)
        
        #expect(handled == true)
        #expect(distractionFreeCalled == true)
    }
    
    // MARK: - Constraint Enforcement Tests
    
    @Test("⌘Z undo is properly blocked to maintain freewriting constraints")
    func testUndoBlocked() async {
        let manager = createShortcutManager()
        let event = createKeyEvent(key: "z", modifiers: [.command])
        
        var undoAttempted = false
        manager.onConstraintViolation = { _ in undoAttempted = true }
        
        let handled = manager.handleKeyEvent(event)
        
        #expect(handled == true) // Handled by blocking
        #expect(undoAttempted == true) // Violation detected
    }
    
    @Test("⌘X cut is blocked to prevent text removal")
    func testCutBlocked() async {
        let manager = createShortcutManager()
        let event = createKeyEvent(key: "x", modifiers: [.command])
        
        var constraintViolated = false
        manager.onConstraintViolation = { _ in constraintViolated = true }
        
        let handled = manager.handleKeyEvent(event)
        
        #expect(handled == true)
        #expect(constraintViolated == true)
    }
    
    @Test("⌘V paste is allowed but constrained to end of text")
    func testPasteConstrained() async {
        let manager = createShortcutManager()
        let event = createKeyEvent(key: "v", modifiers: [.command])
        
        var pasteHandled = false
        manager.onConstrainedPaste = { pasteHandled = true }
        
        let handled = manager.handleKeyEvent(event)
        
        #expect(handled == true)
        #expect(pasteHandled == true)
    }
    
    // MARK: - Timer Preset Tests
    
    @Test("⌘1-9 sets timer presets correctly")
    func testTimerPresets() async {
        let manager = createShortcutManager()
        
        // Test ⌘5 for 25 minute preset (5 * 5 = 25)
        let event = createKeyEvent(key: "5", modifiers: [.command])
        
        var presetMinutes: Int?
        manager.onTimerPreset = { minutes in presetMinutes = minutes }
        
        let handled = manager.handleKeyEvent(event)
        
        #expect(handled == true)
        #expect(presetMinutes == 25) // 5 * 5 minutes
    }
    
    // MARK: - Flow State Protection Tests
    
    @Test("Shortcuts don't interrupt active typing flow")
    func testFlowProtection() async {
        let manager = createShortcutManager()
        
        // Simulate active typing state
        manager.setTypingState(.activeFlow)
        
        // Non-essential shortcut should be deferred
        let event = createKeyEvent(key: "o", modifiers: [.command])
        let handled = manager.handleKeyEvent(event)
        
        #expect(handled == false) // Deferred during flow
    }
    
    @Test("Emergency shortcuts work even during flow state")
    func testEmergencyShortcuts() async {
        let manager = createShortcutManager()
        manager.setTypingState(.activeFlow)
        
        // ⌘D should always work (escape hatch)
        let event = createKeyEvent(key: "d", modifiers: [.command])
        let handled = manager.handleKeyEvent(event)
        
        #expect(handled == true) // Emergency shortcuts always work
    }
}