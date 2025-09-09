import Testing
import Foundation
import AppKit
@testable import Freewrite

/// Comprehensive tests for AIIntegrationService
@MainActor
struct AIIntegrationServiceTests {
    
    // MARK: - Setup
    
    private func createService() -> AIIntegrationService {
        return AIIntegrationService()
    }
    
    private let shortContent = "Short test content for AI integration"
    private let longContent = String(repeating: "Very long content that will exceed URL limits. ", count: 200)
    
    // MARK: - URL Generation Tests
    
    @Test("ChatGPT URL generation with default prompt")
    func testChatGPTURLGeneration() async throws {
        let service = createService()
        
        let url = try await service.generateChatGPTURL(content: shortContent, prompt: nil)
        
        #expect(url.scheme == "https")
        #expect(url.host == "chat.openai.com")
        #expect(url.absoluteString.contains("m="))
    }
    
    @Test("Claude URL generation with default prompt")
    @MainActor  
    func testClaudeURLGeneration() async throws {
        let service = createService()
        
        let url = try await service.generateClaudeURL(content: shortContent, prompt: nil)
        
        #expect(url.scheme == "https")
        #expect(url.host == "claude.ai")
        #expect(url.absoluteString.contains("q="))
    }
    
    @Test("ChatGPT URL generation with custom prompt")
    func testChatGPTURLWithCustomPrompt() async throws {
        let service = createService()
        let customPrompt = "Custom test prompt"
        
        let url = try await service.generateChatGPTURL(content: shortContent, prompt: customPrompt)
        
        #expect(url.absoluteString.contains("Custom%20test%20prompt"))
    }
    
    @Test("Claude URL generation with custom prompt") 
    func testClaudeURLWithCustomPrompt() async throws {
        let service = createService()
        let customPrompt = "Custom Claude prompt"
        
        let url = try await service.generateClaudeURL(content: shortContent, prompt: customPrompt)
        
        #expect(url.absoluteString.contains("Custom%20Claude%20prompt"))
    }
    
    // MARK: - URL Length Validation Tests
    
    @Test("Can share via URL returns true for short content")
    func testCanShareShortContent() async throws {
        let service = createService()
        
        let canShare = service.canShareViaURL(shortContent)
        
        #expect(canShare == true)
    }
    
    @Test("Can share via URL returns false for long content")
    func testCanShareLongContent() async throws {
        let service = createService()
        
        let canShare = service.canShareViaURL(longContent)
        
        #expect(canShare == false)
    }
    
    @Test("Long content throws URL too long error")
    func testLongContentThrowsError() async throws {
        let service = createService()
        
        await #expect(throws: FreewriteError.self) {
            _ = try await service.generateChatGPTURL(content: longContent, prompt: nil)
        }
        
        await #expect(throws: FreewriteError.self) {
            _ = try await service.generateClaudeURL(content: longContent, prompt: nil)
        }
    }
    
    // MARK: - Prompt Creation Tests
    
    @Test("Create prompt for clipboard includes content")
    func testCreatePromptForClipboard() async throws {
        let service = createService()
        
        let prompt = service.createPromptForClipboard(content: shortContent, prompt: nil)
        
        #expect(prompt.contains(shortContent))
        #expect(prompt.contains(AIConstants.defaultPrompt))
    }
    
    @Test("Create prompt with custom prompt")
    func testCreatePromptWithCustomPrompt() async throws {
        let service = createService()
        let customPrompt = "Custom prompt for testing"
        
        let prompt = service.createPromptForClipboard(content: shortContent, prompt: customPrompt)
        
        #expect(prompt.contains(shortContent))
        #expect(prompt.contains(customPrompt))
        #expect(!prompt.contains(AIConstants.defaultPrompt))
    }
    
    // MARK: - Clipboard Tests
    
    @Test("Copy prompt to clipboard updates pasteboard")
    func testCopyPromptToClipboard() async throws {
        let service = createService()
        
        // Clear clipboard first
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        // Copy prompt
        service.copyPromptToClipboard(content: shortContent, prompt: nil)
        
        // Verify clipboard content
        let clipboardContent = pasteboard.string(forType: .string)
        #expect(clipboardContent != nil)
        #expect(clipboardContent?.contains(shortContent) == true)
    }
    
    // MARK: - Convenience Method Tests
    
    @Test("Open ChatGPT convenience method works")
    func testOpenChatGPTConvenience() async throws {
        let service = createService()
        
        // Should not throw for valid content
        try await service.openChatGPT(with: shortContent)
        
        // Should throw for content that's too long
        await #expect(throws: FreewriteError.self) {
            try await service.openChatGPT(with: longContent)
        }
    }
    
    @Test("Open Claude convenience method works")
    func testOpenClaudeConvenience() async throws {
        let service = createService()
        
        // Should not throw for valid content
        try await service.openClaude(with: shortContent)
        
        // Should throw for content that's too long
        await #expect(throws: FreewriteError.self) {
            try await service.openClaude(with: longContent)
        }
    }
    
    @Test("Copy prompt convenience method works")
    func testCopyPromptConvenience() async throws {
        let service = createService()
        
        // Clear clipboard
        NSPasteboard.general.clearContents()
        
        // Copy using convenience method
        service.copyPromptToClipboard(with: shortContent)
        
        // Verify
        let clipboardContent = NSPasteboard.general.string(forType: .string)
        #expect(clipboardContent?.contains(shortContent) == true)
    }
    
    // MARK: - Error Handling Tests
    
    @Test("Invalid content encoding throws appropriate error")
    func testInvalidContentEncoding() async throws {
        let service = createService()
        // Create content with characters that might cause encoding issues
        let problematicContent = String(repeating: "\u{0000}", count: 10)
        
        // Should handle gracefully or throw specific error
        await #expect(throws: FreewriteError.self) {
            _ = try await service.generateChatGPTURL(content: problematicContent, prompt: nil)
        }
    }
    
    // MARK: - Integration Tests
    
    @Test("Full workflow: generate URL, copy prompt, open service")
    func testFullWorkflow() async throws {
        let service = createService()
        
        // 1. Check if can share
        let canShare = service.canShareViaURL(shortContent)
        #expect(canShare == true)
        
        // 2. Generate URLs
        let chatGPTURL = try await service.generateChatGPTURL(content: shortContent, prompt: nil)
        let claudeURL = try await service.generateClaudeURL(content: shortContent, prompt: nil)
        
        #expect(chatGPTURL.absoluteString.count > 0)
        #expect(claudeURL.absoluteString.count > 0)
        
        // 3. Create clipboard prompt
        let clipboardPrompt = service.createPromptForClipboard(content: shortContent, prompt: nil)
        #expect(clipboardPrompt.contains(shortContent))
        
        // 4. Use convenience methods
        try await service.openChatGPT(with: shortContent)
        try await service.openClaude(with: shortContent)
        service.copyPromptToClipboard(with: shortContent)
    }
    
    // MARK: - Performance Tests
    
    @Test("URL generation is fast for typical content")
    func testURLGenerationPerformance() async throws {
        let service = createService()
        let typicalContent = String(repeating: "Typical writing content. ", count: 50)
        
        let startTime = Date()
        
        for _ in 0..<100 {
            _ = try await service.generateChatGPTURL(content: typicalContent, prompt: nil)
            _ = try await service.generateClaudeURL(content: typicalContent, prompt: nil)
        }
        
        let elapsed = Date().timeIntervalSince(startTime)
        #expect(elapsed < 1.0) // Should complete in under 1 second
    }
}