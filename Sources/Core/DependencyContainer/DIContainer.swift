import Foundation

/// Main dependency injection container for the application
@MainActor
final class DIContainer: Sendable {
    static let shared = DIContainer()
    
    private let services: ServiceRegistry
    private var isConfigured = false
    
    private init() {
        self.services = ServiceRegistry()
    }
    
    /// Configures the container with production services
    func configure() {
        guard !isConfigured else { return }
        
        registerProductionServices()
        isConfigured = true
    }
    
    /// Resolves a service instance
    /// - Parameter type: The service type to resolve
    /// - Returns: Service instance
    /// - Throws: Fatal error if service is not registered (legacy - being phased out)
    func resolve<T>(_ type: T.Type) -> T {
        guard let service = services.resolve(type) else {
            // TODO: Replace all call sites with resolveSafe and remove this method
            fatalError("Service \(type) not registered. Make sure DIContainer.configure() is called.")
        }
        return service
    }
    
    /// Safe resolve method that throws instead of crashing
    /// - Parameter type: The service type to resolve
    /// - Returns: Service instance
    /// - Throws: FreewriteError.invalidConfiguration if service not registered
    func resolveSafe<T>(_ type: T.Type) throws -> T {
        guard let service = services.resolve(type) else {
            throw FreewriteError.invalidConfiguration
        }
        return service
    }
    
    /// Registers a service (used for testing)
    /// - Parameters:
    ///   - type: Service type
    ///   - factory: Factory closure
    ///   - singleton: Whether to cache as singleton
    func register<T>(
        _ type: T.Type,
        factory: @escaping () -> T,
        singleton: Bool = false
    ) {
        services.register(type, factory: factory, singleton: singleton)
    }
    
    // MARK: - Private Methods
    
    private func registerProductionServices() {
        // File Management Service
        services.register(
            FileManagementServiceProtocol.self,
            factory: { FileManagementService() },
            singleton: true
        )
        
        // Timer Service
        services.register(
            TimerServiceProtocol.self,
            factory: { FreewriteTimer() }
        )
        
        // Export Service
        services.register(
            ExportServiceProtocol.self,
            factory: { [weak self] in
                let fileService = self?.services.resolve(FileManagementServiceProtocol.self) ?? FileManagementService()
                return PDFExportService(fileService: fileService)
            }
        )
        
        // AI Integration Service
        services.register(
            AIIntegrationServiceProtocol.self,
            factory: { AIIntegrationService() },
            singleton: true
        )
    }
}

// MARK: - Testing Support
extension DIContainer {
    /// Creates a test container with mock services
    /// - Returns: Configured test container
    @MainActor
    static func createTestContainer() -> DIContainer {
        let container = DIContainer()
        container.registerTestServices()
        container.isConfigured = true
        return container
    }
    
    private func registerTestServices() {
        // Register mock implementations for testing
        services.register(
            FileManagementServiceProtocol.self,
            factory: { MockFileManagementService() }
        )
        
        services.register(
            TimerServiceProtocol.self,
            factory: { MockTimerService() }
        )
        
        services.register(
            ExportServiceProtocol.self,
            factory: { MockExportService() }
        )
        
        services.register(
            AIIntegrationServiceProtocol.self,
            factory: { MockAIIntegrationService() }
        )
    }
    
    /// Resets the container for testing
    func reset() {
        services.clear()
        isConfigured = false
    }
}

// MARK: - Mock Service Placeholders (to be implemented in Tests/Mocks)

@MainActor
final class MockFileManagementService: @unchecked Sendable, FileManagementServiceProtocol {
    private var mockEntries: [UUID: WritingEntryDTO] = [:]
    private var mockContents: [UUID: String] = [:]
    var shouldFailOperations = false
    var operationDelay: TimeInterval = 0
    
    func createNewEntry() async throws -> WritingEntryDTO {
        if shouldFailOperations { throw FreewriteError.fileOperationFailed("Mock failure") }
        if operationDelay > 0 { try await Task.sleep(nanoseconds: UInt64(operationDelay * 1_000_000_000)) }
        
        let entry = WritingEntryDTO(
            id: UUID(),
            filename: "mock-entry-\(Date().timeIntervalSince1970).md",
            displayDate: "Mock Date",
            previewText: "",
            wordCount: 0,
            isWelcomeEntry: false,
            createdAt: Date(),
            modifiedAt: Date()
        )
        mockEntries[entry.id] = entry
        mockContents[entry.id] = FreewriteConstants.headerString
        return entry
    }
    
    func loadEntry(_ entryId: UUID) async throws -> String {
        if shouldFailOperations { throw FreewriteError.fileOperationFailed("Mock load failure") }
        if operationDelay > 0 { try await Task.sleep(nanoseconds: UInt64(operationDelay * 1_000_000_000)) }
        
        guard let content = mockContents[entryId] else { throw FreewriteError.entryNotFound }
        return content
    }
    
    func saveEntry(_ entryId: UUID, content: String) async throws {
        if shouldFailOperations { throw FreewriteError.fileOperationFailed("Mock save failure") }
        if operationDelay > 0 { try await Task.sleep(nanoseconds: UInt64(operationDelay * 1_000_000_000)) }
        
        guard let existingEntry = mockEntries[entryId] else { throw FreewriteError.entryNotFound }
        mockContents[entryId] = content
        
        // Create updated entry with new modification date (immutable struct)
        let updatedEntry = WritingEntryDTO(
            id: existingEntry.id,
            filename: existingEntry.filename,
            displayDate: existingEntry.displayDate,
            previewText: String(content.prefix(30)),
            wordCount: content.split(separator: " ").count,
            isWelcomeEntry: existingEntry.isWelcomeEntry,
            createdAt: existingEntry.createdAt,
            modifiedAt: Date()
        )
        mockEntries[entryId] = updatedEntry
    }
    
    func deleteEntry(_ entryId: UUID) async throws {
        if shouldFailOperations { throw FreewriteError.fileOperationFailed("Mock delete failure") }
        if operationDelay > 0 { try await Task.sleep(nanoseconds: UInt64(operationDelay * 1_000_000_000)) }
        
        guard mockEntries[entryId] != nil else { throw FreewriteError.entryNotFound }
        mockEntries.removeValue(forKey: entryId)
        mockContents.removeValue(forKey: entryId)
    }
    
    func loadAllEntries() async throws -> [WritingEntryDTO] {
        if shouldFailOperations { throw FreewriteError.fileOperationFailed("Mock load all failure") }
        if operationDelay > 0 { try await Task.sleep(nanoseconds: UInt64(operationDelay * 1_000_000_000)) }
        
        return Array(mockEntries.values).sorted { $0.createdAt > $1.createdAt }
    }
    
    func updatePreviewText(_ entryId: UUID) async throws {
        if shouldFailOperations { throw FreewriteError.fileOperationFailed("Mock update failure") }
        // Mock implementation - no actual preview update needed
    }
    
    func getDocumentsDirectory() -> URL {
        return URL(fileURLWithPath: "/tmp/freewrite-mock")
    }
    
    func entryExists(_ entryId: UUID) async -> Bool {
        return mockEntries[entryId] != nil
    }
}

@MainActor
final class MockTimerService: @unchecked Sendable, TimerServiceProtocol {
    private(set) var timeRemaining: Int = 900
    private(set) var isRunning: Bool = false
    private(set) var isFinished: Bool = false
    var shouldFailOperations = false
    
    var formattedTime: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    func start() {
        guard !isRunning && timeRemaining > 0 else { return }
        isRunning = true
        isFinished = false
    }
    
    func pause() {
        guard isRunning else { return }
        isRunning = false
    }
    
    func reset() {
        reset(to: 900)
    }
    
    func reset(to duration: Int) {
        timeRemaining = max(0, min(duration, 2700))
        isRunning = false
        isFinished = false
    }
    
    func adjustTime(by seconds: Int) {
        let newTime = timeRemaining + seconds
        timeRemaining = max(0, min(newTime, 2700))
        
        if timeRemaining == 0 && isRunning {
            isRunning = false
            isFinished = true
        }
    }
    
    func setTime(_ seconds: Int) {
        timeRemaining = max(0, min(seconds, 2700))
        
        if timeRemaining == 0 && isRunning {
            isRunning = false
            isFinished = true
        }
    }
    
    func handleScrollAdjustment(deltaY: CGFloat) {
        let direction = deltaY > 0 ? 1 : -1
        let adjustment = direction * 5 * 60 // 5 minutes
        adjustTime(by: adjustment)
    }
}

final class MockExportService: @unchecked Sendable, ExportServiceProtocol {
    func exportToPDF(entryId: UUID, settings: PDFExportSettings) async throws -> Data { fatalError("Mock not implemented") }
    func exportToText(entryId: UUID) async throws -> String { fatalError("Mock not implemented") }
    func exportToMarkdown(entryId: UUID) async throws -> String { fatalError("Mock not implemented") }
    func suggestedFilename(for entryId: UUID, format: ExportFormat) async throws -> String { fatalError("Mock not implemented") }
}

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