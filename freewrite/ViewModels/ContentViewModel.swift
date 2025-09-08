import SwiftUI
import Foundation

@MainActor
@Observable
final class ContentViewModel {
    private let fileService: FileManagementServiceProtocol
    private let aiService: AIIntegrationServiceProtocol
    
    var entries: [WritingEntryDTO] = []
    var selectedEntryId: UUID? = nil
    var text: String = FreewriteConstants.headerString
    
    let placeholderOptions = [
        "\n\nBegin writing",
        "\n\nPick a thought and go", 
        "\n\nStart typing",
        "\n\nWhat's on your mind",
        "\n\nJust start",
        "\n\nType your first thought",
        "\n\nStart with one sentence",
        "\n\nJust say it"
    ]
    
    init() {
        self.fileService = DIContainer.shared.resolve(FileManagementServiceProtocol.self)
        self.aiService = DIContainer.shared.resolve(AIIntegrationServiceProtocol.self)
    }
    
    // MARK: - Text Management
    
    func processTextChange(_ newValue: String) {
        // Only apply constraints for actual deletions/edits, allow forward typing
        let currentTextContent = text.dropFirst(2) // Content after "\n\n"
        let newTextContent = newValue.dropFirst(2) // Content after "\n\n" 
        
        // Check if user is trying to delete/edit existing content
        if newValue.count >= 2 && newTextContent.count < currentTextContent.count {
            NSSound.beep()
            return
        }
        
        // Ensure the text always starts with two newlines
        let processedValue: String
        if !newValue.hasPrefix("\n\n") {
            processedValue = "\n\n" + newValue.trimmingCharacters(in: .newlines)
        } else {
            processedValue = newValue
        }
        
        text = processedValue
        
        // Auto-save with file service
        Task {
            await saveCurrentText()
        }
    }
    
    // MARK: - Entry Management
    
    func setupInitialState() async {
        await loadInitialEntry()
    }
    
    func saveCurrentText() async {
        do {
            if let currentEntry = await getCurrentEntry() {
                try await fileService.saveEntry(currentEntry.id, content: text)
            }
        } catch {
            print("Auto-save failed: \(error)")
        }
    }
    
    func createNewEntry() async {
        do {
            let newEntry = try await fileService.createNewEntry()
            entries.insert(newEntry, at: 0) // Add to beginning of list
            selectedEntryId = newEntry.id
            text = FreewriteConstants.headerString
            
            // Save the initial empty entry
            try await fileService.saveEntry(newEntry.id, content: text)
        } catch {
            print("Failed to create new entry: \(error)")
        }
    }
    
    func loadInitialEntry() async {
        do {
            entries = try await fileService.loadAllEntries()
            
            if let mostRecent = entries.first {
                selectedEntryId = mostRecent.id
                let content = try await fileService.loadEntry(mostRecent.id)
                text = content
            } else {
                // No entries exist, create first entry
                await createNewEntry()
            }
        } catch {
            print("Failed to load initial entry: \(error)")
            await createNewEntry()
        }
    }
    
    func loadEntry(_ entry: WritingEntryDTO) async {
        do {
            selectedEntryId = entry.id
            let content = try await fileService.loadEntry(entry.id)
            text = content
        } catch {
            print("Failed to load entry: \(error)")
        }
    }
    
    func deleteEntry(_ entry: WritingEntryDTO) async {
        do {
            try await fileService.deleteEntry(entry.id)
            entries.removeAll { $0.id == entry.id }
            
            // If the deleted entry was selected, select the first entry or create a new one
            if selectedEntryId == entry.id {
                if let firstEntry = entries.first {
                    await loadEntry(firstEntry)
                } else {
                    await createNewEntry()
                }
            }
        } catch {
            print("Failed to delete entry: \(error)")
        }
    }
    
    private func getCurrentEntry() async -> WritingEntryDTO? {
        do {
            let entries = try await fileService.loadAllEntries()
            return entries.first // Most recent entry
        } catch {
            return nil
        }
    }
    
    // MARK: - AI Integration
    
    func openChatGPT() {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        Task {
            do {
                try await aiService.openChatGPT(with: trimmedText)
            } catch {
                print("Failed to open ChatGPT: \(error)")
            }
        }
    }
    
    func openClaude() {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        Task {
            do {
                try await aiService.openClaude(with: trimmedText)
            } catch {
                print("Failed to open Claude: \(error)")
            }
        }
    }
    
    func copyPromptToClipboard() {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        aiService.copyPromptToClipboard(with: trimmedText)
    }
    
    // MARK: - Computed Properties
    
    var canUseChat: Bool {
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleanText.count >= FreewriteConstants.minimumTextLength
    }
}