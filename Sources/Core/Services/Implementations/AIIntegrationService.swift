import Foundation
import AppKit

/// AI integration service implementation
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
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(fullText, forType: .string)
        
        print("Prompt copied to clipboard (\(fullText.count) characters)")
    }
    
    func openURL(_ url: URL) {
        NSWorkspace.shared.open(url)
        print("Opened URL: \(url.absoluteString)")
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