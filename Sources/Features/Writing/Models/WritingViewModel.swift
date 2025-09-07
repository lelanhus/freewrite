import SwiftUI

/// View model for the writing feature
@MainActor
@Observable
final class WritingViewModel {
    // MARK: - Published State
    private(set) var currentText: String = FreewriteConstants.headerString
    private(set) var selectedEntry: WritingEntryDTO?
    private(set) var placeholderText: String = PlaceholderConstants.random()
    private(set) var isLoading: Bool = false
    private(set) var error: FreewriteError?
    
    // MARK: - Services
    private let fileService: FileManagementServiceProtocol
    let timerService: TimerServiceProtocol
    
    // MARK: - Initialization
    init(
        fileService: FileManagementServiceProtocol,
        timerService: TimerServiceProtocol
    ) {
        self.fileService = fileService
        self.timerService = timerService
        
        Task {
            await loadInitialEntry()
        }
    }
    
    // MARK: - Convenience initializer using DI
    convenience init() {
        self.init(
            fileService: DIContainer.shared.resolve(FileManagementServiceProtocol.self),
            timerService: DIContainer.shared.resolve(TimerServiceProtocol.self)
        )
    }
    
    // MARK: - Public Methods
    
    /// Updates the current text content
    func updateText(_ newText: String) {
        let processedText = ensureNewlinePrefix(newText)
        currentText = processedText
        
        // Auto-save after a short delay
        Task {
            await autoSave()
        }
    }
    
    /// Creates a new writing entry
    func createNewEntry() async {
        isLoading = true
        error = nil
        
        do {
            let entry = try await fileService.createNewEntry()
            selectedEntry = entry
            currentText = FreewriteConstants.headerString
            placeholderText = PlaceholderConstants.random()
            
            print("Created new entry: \(entry.filename)")
        } catch {
            self.error = error as? FreewriteError ?? .fileOperationFailed(error.localizedDescription)
            print("Failed to create new entry: \(error)")
        }
        
        isLoading = false
    }
    
    /// Loads a specific entry
    func loadEntry(_ entry: WritingEntryDTO) async {
        guard selectedEntry?.id != entry.id else { return }
        
        isLoading = true
        error = nil
        
        do {
            // Save current entry before switching
            await saveCurrentEntry()
            
            let content = try await fileService.loadEntry(entry.id)
            selectedEntry = entry
            currentText = content
            
            print("Loaded entry: \(entry.filename)")
        } catch {
            self.error = error as? FreewriteError ?? .fileOperationFailed(error.localizedDescription)
            print("Failed to load entry: \(error)")
        }
        
        isLoading = false
    }
    
    /// Deletes the current entry
    func deleteCurrentEntry() async {
        guard let entry = selectedEntry else { return }
        
        isLoading = true
        error = nil
        
        do {
            try await fileService.deleteEntry(entry.id)
            
            // Create a new entry after deletion
            await createNewEntry()
            
            print("Deleted entry: \(entry.filename)")
        } catch {
            self.error = error as? FreewriteError ?? .fileOperationFailed(error.localizedDescription)
            print("Failed to delete entry: \(error)")
        }
        
        isLoading = false
    }
    
    /// Clears any error state
    func clearError() {
        error = nil
    }
    
    // MARK: - Timer Integration
    var timeRemaining: Int { timerService.timeRemaining }
    var isTimerRunning: Bool { timerService.isRunning }
    var isTimerFinished: Bool { timerService.isFinished }
    var formattedTime: String { timerService.formattedTime }
    
    func startTimer() {
        timerService.start()
    }
    
    func pauseTimer() {
        timerService.pause()
    }
    
    func resetTimer() {
        timerService.reset()
    }
    
    func adjustTimer(by seconds: Int) {
        timerService.adjustTime(by: seconds)
    }
    
    // MARK: - Computed Properties
    
    /// Whether the current text has enough content for AI chat
    var canUseChat: Bool {
        let cleanText = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleanText.count >= FreewriteConstants.minimumTextLength
    }
    
    /// Word count of current text
    var wordCount: Int {
        let cleanText = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleanText.isEmpty ? 0 :
            cleanText.components(separatedBy: .whitespacesAndNewlines)
                     .filter { !$0.isEmpty }.count
    }
    
    /// Character count of current text
    var characterCount: Int {
        currentText.trimmingCharacters(in: .whitespacesAndNewlines).count
    }
    
    // MARK: - Private Methods
    
    private func loadInitialEntry() async {
        do {
            let entries = try await fileService.loadAllEntries()
            
            if let mostRecent = entries.first {
                await loadEntry(mostRecent)
            } else {
                // No entries exist, create first entry with welcome content
                await createWelcomeEntry()
            }
        } catch {
            print("Failed to load initial entry: \(error)")
            await createNewEntry()
        }
    }
    
    private func createWelcomeEntry() async {
        do {
            let entry = try await fileService.createNewEntry()
            let welcomeContent = await loadWelcomeContent()
            
            selectedEntry = entry
            currentText = welcomeContent
            
            try await fileService.saveEntry(entry.id, content: welcomeContent)
            
            print("Created welcome entry")
        } catch {
            print("Failed to create welcome entry: \(error)")
            await createNewEntry()
        }
    }
    
    private func loadWelcomeContent() async -> String {
        do {
            let documentsDir = fileService.getDocumentsDirectory()
            let welcomeURL = documentsDir.appendingPathComponent("../../../Resources/default.md")
            let content = try String(contentsOf: welcomeURL, encoding: .utf8)
            return content
        } catch {
            print("Could not load welcome content: \(error)")
            return FreewriteConstants.headerString + "Welcome to Freewrite! Start typing to begin your writing session."
        }
    }
    
    private func ensureNewlinePrefix(_ text: String) -> String {
        return text.hasPrefix(FreewriteConstants.headerString) ? text : FreewriteConstants.headerString + text
    }
    
    private func saveCurrentEntry() async {
        guard let entry = selectedEntry else { return }
        
        do {
            try await fileService.saveEntry(entry.id, content: currentText)
        } catch {
            print("Auto-save failed: \(error)")
        }
    }
    
    private func autoSave() async {
        // Debounce auto-save to avoid excessive file operations
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
        await saveCurrentEntry()
    }
}