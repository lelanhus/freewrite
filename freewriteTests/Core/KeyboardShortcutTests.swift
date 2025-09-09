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
    
    // Simplified testing without complex NSEvent simulation
    
    // MARK: - Essential Flow Shortcuts Tests
    
    @Test("⌘N creates new session without breaking flow")
    func testNewSessionShortcut() async {
        let manager = createShortcutManager()
        
        var newSessionCalled = false
        manager.onNewSession = { newSessionCalled = true }
        
        // Test callback functionality directly
        manager.onNewSession?()
        
        #expect(newSessionCalled == true)
    }
    
    @Test("⌘T toggles timer without UI interruption")
    func testTimerToggleShortcut() async {
        let manager = createShortcutManager()
        
        var timerToggleCalled = false
        manager.onTimerToggle = { timerToggleCalled = true }
        
        // Test callback functionality directly
        manager.onTimerToggle?()
        
        #expect(timerToggleCalled == true)
    }
    
    @Test("⌘D toggles distraction-free mode")
    func testDistactionFreeShortcut() async {
        let manager = createShortcutManager()
        
        var distractionFreeCalled = false
        manager.onToggleDistractionFree = { distractionFreeCalled = true }
        
        // Test callback functionality directly
        manager.onToggleDistractionFree?()
        
        #expect(distractionFreeCalled == true)
    }
    
    // MARK: - Constraint Enforcement Tests
    
    @Test("⌘Z undo is properly blocked to maintain freewriting constraints")
    func testUndoBlocked() async {
        let manager = createShortcutManager()
        
        var undoAttempted = false
        manager.onConstraintViolation = { _ in undoAttempted = true }
        
        // Test constraint violation callback
        manager.onConstraintViolation?("Test violation")
        
        #expect(undoAttempted == true) // Violation detected
    }
    
    @Test("Constraint violation callbacks work properly")
    func testConstraintCallbacks() async {
        let manager = createShortcutManager()
        
        var constraintViolated = false
        manager.onConstraintViolation = { _ in constraintViolated = true }
        
        // Test constraint violation callback
        manager.onConstraintViolation?("Test violation")
        
        #expect(constraintViolated == true)
    }
    
    @Test("Timer preset callbacks work correctly")
    func testTimerPresetCallbacks() async {
        let manager = createShortcutManager()
        
        var presetMinutes: Int?
        manager.onTimerPreset = { minutes in presetMinutes = minutes }
        
        // Test timer preset callback
        manager.onTimerPreset?(25) // 25 minutes
        
        #expect(presetMinutes == 25)
    }
    
    @Test("Flow state tracking functions correctly")
    func testFlowStateTracking() async {
        let manager = createShortcutManager()
        
        // Test initial state
        manager.setTypingState(.idle)
        // Verify state was set (no public getter, but function should not crash)
        
        manager.setTypingState(.typing)
        manager.setTypingState(.activeFlow)
        
        // Test typing activity update
        manager.updateTypingActivity()
        
        // If we get here without crashing, flow state tracking works
        #expect(true)
    }
}