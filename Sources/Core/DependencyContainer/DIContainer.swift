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

final class MockFileManagementService: @unchecked Sendable, FileManagementServiceProtocol {
    func createNewEntry() async throws -> WritingEntryDTO { fatalError("Mock not implemented") }
    func loadEntry(_ entryId: UUID) async throws -> String { fatalError("Mock not implemented") }
    func saveEntry(_ entryId: UUID, content: String) async throws { fatalError("Mock not implemented") }
    func deleteEntry(_ entryId: UUID) async throws { fatalError("Mock not implemented") }
    func loadAllEntries() async throws -> [WritingEntryDTO] { fatalError("Mock not implemented") }
    func updatePreviewText(_ entryId: UUID) async throws { fatalError("Mock not implemented") }
    func getDocumentsDirectory() -> URL { fatalError("Mock not implemented") }
    func entryExists(_ entryId: UUID) async -> Bool { fatalError("Mock not implemented") }
}

final class MockTimerService: @unchecked Sendable, TimerServiceProtocol {
    var timeRemaining: Int = 0
    var isRunning: Bool = false
    var isFinished: Bool = false
    var formattedTime: String = "0:00"
    
    func start() {}
    func pause() {}
    func reset() {}
    func reset(to duration: Int) {}
    func adjustTime(by seconds: Int) {}
    func setTime(_ seconds: Int) {}
}

final class MockExportService: @unchecked Sendable, ExportServiceProtocol {
    func exportToPDF(entryId: UUID, settings: PDFExportSettings) async throws -> Data { fatalError("Mock not implemented") }
    func exportToText(entryId: UUID) async throws -> String { fatalError("Mock not implemented") }
    func exportToMarkdown(entryId: UUID) async throws -> String { fatalError("Mock not implemented") }
    func suggestedFilename(for entryId: UUID, format: ExportFormat) async throws -> String { fatalError("Mock not implemented") }
}

@MainActor
final class MockAIIntegrationService: @unchecked Sendable, AIIntegrationServiceProtocol {
    func canShareViaURL(_ content: String) -> Bool { fatalError("Mock not implemented") }
    func generateChatGPTURL(content: String, prompt: String?) throws -> URL { fatalError("Mock not implemented") }
    func generateClaudeURL(content: String, prompt: String?) throws -> URL { fatalError("Mock not implemented") }
    func createPromptForClipboard(content: String, prompt: String?) -> String { fatalError("Mock not implemented") }
    func copyPromptToClipboard(content: String, prompt: String?) { fatalError("Mock not implemented") }
    func openURL(_ url: URL) { fatalError("Mock not implemented") }
    func openChatGPT(with content: String) async throws { fatalError("Mock not implemented") }
    func openClaude(with content: String) async throws { fatalError("Mock not implemented") }
    func copyPromptToClipboard(with content: String) { fatalError("Mock not implemented") }
}