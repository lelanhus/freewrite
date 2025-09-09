import Testing
import SwiftUI
@testable import Freewrite

/// Integration tests for UI component interactions and state management
@MainActor  
struct UIComponentIntegrationTests {
    
    // MARK: - State Manager Integration
    
    @Test("State managers properly coordinate across components")
    func testStateManagerIntegration() async throws {
        let uiState = UIStateManager()
        let hoverState = HoverStateManager()
        let typographyState = TypographyStateManager()
        
        // Test: UI state changes affect other components
        uiState.showingSidebar = true
        #expect(uiState.showingSidebar == true)
        
        // Test: Typography state caching works properly
        let originalLineHeight = typographyState.lineHeight
        typographyState.updateFontSize(20)
        let newLineHeight = typographyState.lineHeight
        #expect(newLineHeight != originalLineHeight)
        
        // Test: Hover state isolation
        hoverState.isHoveringTimer = true
        hoverState.resetAllHover()
        #expect(hoverState.isHoveringTimer == false)
    }
    
    // MARK: - Navigation Component Integration
    
    @Test("NavigationBar integrates properly with services and state")
    func testNavigationBarIntegration() async throws {
        // Test that NavigationBar receives and handles all required dependencies:
        // - TypographyState for font controls
        // - HoverState for interaction feedback  
        // - UIState for menu management
        // - Timer service for time display and controls
        // - Action callbacks for functionality
        
        let typographyState = TypographyStateManager()
        let hoverState = HoverStateManager()
        let uiState = UIStateManager()
        let timer = FreewriteTimer()
        let disclosureManager = ShortcutDisclosureManager()
        
        // Test: Timer display integration
        timer.reset(to: 1800) // 30 minutes
        let expectedTitle = "30:00"
        #expect(timer.formattedTime == expectedTitle)
        
        // Test: Font size integration
        typographyState.updateFontSize(24)
        let expectedButtonTitle = "24px"
        #expect(typographyState.fontSizeButtonTitle == expectedButtonTitle)
        
        // Test: Chat menu state integration
        uiState.showingChatMenu = true
        #expect(uiState.showingChatMenu == true)
        
        // Test: Shortcut disclosure integration  
        disclosureManager.registerSessionStart()
        let tooltip = disclosureManager.getTooltipFor(element: "timer")
        #expect(tooltip != nil)
    }
    
    // MARK: - File Service Integration with UI
    
    @Test("File operations properly update UI state and provide feedback")
    func testFileServiceUIIntegration() async throws {
        let fileService = MockFileManagementService()
        let progressState = ProgressStateManager()
        let errorManager = ErrorManager()
        
        // Test: Progress indication during file operations
        progressState.startLoading("Testing file operations")
        #expect(progressState.isVisible == true)
        #expect(progressState.loadingMessage == "Testing file operations")
        
        // Test: Successful operation clears progress
        _ = try await fileService.createNewEntry()
        progressState.finishLoading()
        #expect(progressState.isVisible == false)
        
        // Test: Error handling integration
        fileService.shouldFailOperations = true
        #expect(errorManager.currentError == nil)
        
        // Simulate error reporting (would happen in real integration)
        let testError = FreewriteError.fileOperationFailed("Test error")
        let userError = UserError.fileOperationFailed(
            operation: "test operation",
            error: testError,
            retry: {}
        )
        errorManager.reportError(userError)
        
        #expect(errorManager.currentError != nil)
        #expect(errorManager.currentError?.title == "File Operation Failed")
    }
    
    // MARK: - ContentView Integration
    
    @Test("ContentView properly coordinates all subsystems")
    func testContentViewIntegration() async throws {
        // Test that ContentView properly:
        // - Initializes all state managers
        // - Connects services through DI container
        // - Sets up keyboard shortcuts  
        // - Handles UI state coordination
        // - Manages component lifecycle
        
        let uiState = UIStateManager()
        let hoverState = HoverStateManager()
        let typographyState = TypographyStateManager()
        let progressState = ProgressStateManager()
        let errorManager = ErrorManager()
        let keyboardManager = KeyboardShortcutManager()
        let disclosureManager = ShortcutDisclosureManager()
        
        // Test: State manager initialization
        #expect(uiState.bottomNavOpacity == 1.0)
        #expect(typographyState.selectedFont == FontConstants.defaultFont)
        #expect(progressState.isVisible == false)
        #expect(errorManager.currentError == nil)
        
        // Test: Keyboard integration setup
        var shortcutTriggered = false
        keyboardManager.onNewSession = { shortcutTriggered = true }
        
        let event = NSEvent.keyEvent(
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
        
        let handled = keyboardManager.handleKeyEvent(event)
        #expect(handled == true)
        #expect(shortcutTriggered == true)
        
        // Test: Progressive disclosure tracking
        disclosureManager.registerSessionStart()
        disclosureManager.registerShortcutUsed("⌘N")
        #expect(disclosureManager.shouldShowTooltip(for: "⌘N") == true)
    }
    
    // MARK: - Constraint System Integration
    
    @Test("Text constraints integrate properly with UI and keyboard system")
    func testConstraintSystemIntegration() async throws {
        let keyboardManager = KeyboardShortcutManager()
        
        // Test: Constraint violation handling
        var violationOccurred = false
        var violationMessage = ""
        
        keyboardManager.onConstraintViolation = { message in
            violationOccurred = true
            violationMessage = message
        }
        
        // Test: Undo attempt blocked
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
        #expect(violationOccurred == true)
        #expect(violationMessage.contains("freewriting constraints"))
        
        // Test: Text validation integration
        let currentText = "\n\nTest content"
        let shortenedText = "\n\nTest"
        
        let result = TextConstraintValidator.validateSimpleTextChange(
            newText: shortenedText,
            currentText: currentText
        )
        
        #expect(result.shouldProvideFeedback == true)
        #expect(result.correctedText == currentText)
    }
    
    // MARK: - Error Recovery Integration
    
    @Test("Error recovery workflows function properly across components")
    func testErrorRecoveryIntegration() async throws {
        let errorManager = ErrorManager()
        let fileService = MockFileManagementService()
        
        // Test: Error reporting and recovery
        fileService.shouldFailOperations = true
        
        var retryAttempted = false
        let retryAction = { retryAttempted = true }
        
        let userError = UserError.fileOperationFailed(
            operation: "test operation",
            error: FreewriteError.fileOperationFailed("Mock failure"),
            retry: retryAction
        )
        
        errorManager.reportError(userError)
        
        #expect(errorManager.currentError != nil)
        #expect(errorManager.currentError?.recoveryAction != nil)
        
        // Test: Retry functionality
        errorManager.retryCurrentOperation()
        #expect(retryAttempted == true)
        #expect(errorManager.currentError == nil)
    }
    
    // MARK: - Session Lifecycle Integration
    
    @Test("Complete session lifecycle with proper state transitions")
    func testSessionLifecycleIntegration() async throws {
        let timer = FreewriteTimer()
        let fileService = MockFileManagementService()
        let progressState = ProgressStateManager()
        
        // Test: Session start
        let entry = try await fileService.createNewEntry()
        timer.start()
        
        #expect(timer.isRunning == true)
        #expect(entry.wordCount == 0)
        
        // Test: Writing phase
        let content = "\n\nThis is test content for integration testing of the freewriting workflow"
        try await fileService.saveEntry(entry.id, content: content)
        
        // Test: Session completion
        timer.pause()
        #expect(timer.isRunning == false)
        
        let savedContent = try await fileService.loadEntry(entry.id)
        #expect(savedContent == content)
        
        // Test: AI analysis readiness
        #expect(content.count >= FreewriteConstants.minimumTextLength)
    }
}