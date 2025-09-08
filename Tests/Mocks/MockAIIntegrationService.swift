import Foundation
@testable import freewrite

@MainActor
final class MockAIIntegrationService: @unchecked Sendable, AIIntegrationServiceProtocol {
    var shouldFailOperations = false
    private(set) var lastOpenedURL: URL?
    private(set) var lastCopiedContent: String?
    
    func canShareViaURL(_ content: String) -> Bool {
        return content.count < 2000 // Mock URL length limit
    }
    
    func generateChatGPTURL(content: String, prompt: String?) throws -> URL {
        if shouldFailOperations { throw FreewriteError.urlTooLong }
        return URL(string: "https://chat.openai.com/?m=mock-content")!
    }
    
    func generateClaudeURL(content: String, prompt: String?) throws -> URL {
        if shouldFailOperations { throw FreewriteError.urlTooLong }
        return URL(string: "https://claude.ai/new?q=mock-content")!
    }
    
    func createPromptForClipboard(content: String, prompt: String?) -> String {
        let fullPrompt = prompt ?? "Mock prompt"
        return "\(fullPrompt)\n\n\(content)"
    }
    
    func copyPromptToClipboard(content: String, prompt: String?) {
        lastCopiedContent = createPromptForClipboard(content: content, prompt: prompt)
        // Mock clipboard operation - don't actually modify system clipboard
    }
    
    func openURL(_ url: URL) {
        lastOpenedURL = url
        // Mock URL opening - don't actually open URLs in tests
    }
    
    func openChatGPT(with content: String) async throws {
        if shouldFailOperations { throw FreewriteError.urlTooLong }
        let url = try generateChatGPTURL(content: content, prompt: nil)
        openURL(url)
    }
    
    func openClaude(with content: String) async throws {
        if shouldFailOperations { throw FreewriteError.urlTooLong }
        let url = try generateClaudeURL(content: content, prompt: nil)
        openURL(url)
    }
    
    func copyPromptToClipboard(with content: String) {
        copyPromptToClipboard(content: content, prompt: nil)
    }
}