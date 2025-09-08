import Foundation

/// Service responsible for AI integration (ChatGPT, Claude)
protocol AIIntegrationServiceProtocol: Sendable {
    /// Validates if text content can be shared via URL
    /// - Parameter content: The text content to validate
    /// - Returns: Boolean indicating if content can be shared via URL
    func canShareViaURL(_ content: String) -> Bool
    
    /// Generates a ChatGPT URL with the provided content
    /// - Parameters:
    ///   - content: The text content to share
    ///   - prompt: Optional custom prompt (uses default if nil)
    /// - Returns: URL for ChatGPT with the content
    /// - Throws: FreewriteError.urlTooLong if content is too long for URL
    func generateChatGPTURL(content: String, prompt: String?) throws -> URL
    
    /// Generates a Claude URL with the provided content
    /// - Parameters:
    ///   - content: The text content to share
    ///   - prompt: Optional custom prompt (uses default if nil)
    /// - Returns: URL for Claude with the content
    /// - Throws: FreewriteError.urlTooLong if content is too long for URL
    func generateClaudeURL(content: String, prompt: String?) throws -> URL
    
    /// Creates a formatted prompt with content for copying to clipboard
    /// - Parameters:
    ///   - content: The text content
    ///   - prompt: Optional custom prompt (uses default if nil)
    /// - Returns: Formatted prompt with content
    func createPromptForClipboard(content: String, prompt: String?) -> String
    
    /// Copies prompt with content to system clipboard
    /// - Parameters:
    ///   - content: The text content
    ///   - prompt: Optional custom prompt (uses default if nil)
    func copyPromptToClipboard(content: String, prompt: String?)
    
    /// Opens a URL in the default browser
    /// - Parameter url: The URL to open
    func openURL(_ url: URL)
    
    /// Convenience method to open ChatGPT with content
    /// - Parameter content: The text content to share
    func openChatGPT(with content: String) async throws
    
    /// Convenience method to open Claude with content
    /// - Parameter content: The text content to share
    func openClaude(with content: String) async throws
    
    /// Convenience method to copy prompt to clipboard
    /// - Parameter content: The text content to include
    func copyPromptToClipboard(with content: String)
}

// MARK: - AI Provider
enum AIProvider: String, CaseIterable, Sendable {
    case chatGPT = "chatgpt"
    case claude = "claude"
    
    var displayName: String {
        switch self {
        case .chatGPT: return "ChatGPT"
        case .claude: return "Claude"
        }
    }
    
    var baseURL: String {
        switch self {
        case .chatGPT: return AIConstants.chatGPTBaseURL
        case .claude: return AIConstants.claudeBaseURL
        }
    }
}