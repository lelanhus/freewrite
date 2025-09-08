import Foundation
import AppKit

/// AI integration service implementation
@MainActor
final class AIIntegrationService: AIIntegrationServiceProtocol {
    
    func canShareViaURL(_ content: String) -> Bool {
        let gptFullText = AIConstants.defaultPrompt + "\n\n" + content
        let claudeFullText = AIConstants.claudePrompt + "\n\n" + content
        
        let gptURL = AIConstants.chatGPTBaseURL + (gptFullText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")
        let claudeURL = AIConstants.claudeBaseURL + (claudeFullText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")
        
        return gptURL.count <= FreewriteConstants.maxURLLength && 
               claudeURL.count <= FreewriteConstants.maxURLLength
    }
    
    func generateChatGPTURL(content: String, prompt: String? = nil) throws -> URL {
        let fullPrompt = prompt ?? AIConstants.defaultPrompt
        let fullText = fullPrompt + "\n\n" + content
        
        guard let encodedText = fullText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw FreewriteError.invalidConfiguration
        }
        
        let urlString = AIConstants.chatGPTBaseURL + encodedText
        
        guard urlString.count <= FreewriteConstants.maxURLLength else {
            throw FreewriteError.urlTooLong
        }
        
        guard let url = URL(string: urlString) else {
            throw FreewriteError.invalidConfiguration
        }
        
        return url
    }
    
    func generateClaudeURL(content: String, prompt: String? = nil) throws -> URL {
        let fullPrompt = prompt ?? AIConstants.claudePrompt
        let fullText = fullPrompt + "\n\n" + content
        
        guard let encodedText = fullText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw FreewriteError.invalidConfiguration
        }
        
        let urlString = AIConstants.claudeBaseURL + encodedText
        
        guard urlString.count <= FreewriteConstants.maxURLLength else {
            throw FreewriteError.urlTooLong
        }
        
        guard let url = URL(string: urlString) else {
            throw FreewriteError.invalidConfiguration
        }
        
        return url
    }
    
    func createPromptForClipboard(content: String, prompt: String? = nil) -> String {
        let fullPrompt = prompt ?? AIConstants.defaultPrompt
        return fullPrompt + "\n\n" + content
    }
    
    func copyPromptToClipboard(content: String, prompt: String? = nil) {
        let fullText = createPromptForClipboard(content: content, prompt: prompt)
        
        // Safe clipboard operations with error handling
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        let success = pasteboard.setString(fullText, forType: .string)
        if success {
            print("Successfully copied prompt to clipboard (\(fullText.count) characters)")
        } else {
            print("ERROR: Failed to copy prompt to clipboard")
        }
    }
    
    func openURL(_ url: URL) {
        // Validate URL before attempting to open to prevent crashes
        guard url.absoluteString.hasPrefix("http://") || url.absoluteString.hasPrefix("https://") else {
            print("ERROR: Invalid URL scheme for: \(url.absoluteString)")
            return
        }
        
        // Safe URL opening with error handling
        let success = NSWorkspace.shared.open(url)
        if success {
            print("Successfully opened URL: \(url.absoluteString)")
        } else {
            print("ERROR: Failed to open URL: \(url.absoluteString)")
        }
    }
    
    func openChatGPT(with content: String) async throws {
        let url = try generateChatGPTURL(content: content)
        openURL(url)
    }
    
    func openClaude(with content: String) async throws {
        let url = try generateClaudeURL(content: content)
        openURL(url)
    }
    
    func copyPromptToClipboard(with content: String) {
        copyPromptToClipboard(content: content)
    }
}