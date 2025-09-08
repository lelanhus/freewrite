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
        // Register critical services (File Management and Timer)
        // These are essential and cannot degrade gracefully
        services.register(
            FileManagementServiceProtocol.self,
            factory: { FileManagementService() },
            singleton: true
        )
        
        services.register(
            TimerServiceProtocol.self,
            factory: { FreewriteTimer() }
        )
        
        // Register non-critical services with graceful degradation
        registerExportServiceWithFallback()
        registerAIServiceWithFallback()
    }
    
    private func registerExportServiceWithFallback() {
        // Break potential dependency cycle by using lazy resolution
        services.register(
            ExportServiceProtocol.self,
            factory: {
                // Create export service with lazy file service injection to prevent cycles
                return LazyPDFExportService()
            }
        )
    }
    
    private func registerAIServiceWithFallback() {
        services.register(
            AIIntegrationServiceProtocol.self,
            factory: { 
                // For now, services don't throw, but this provides framework for future graceful degradation
                return AIIntegrationService()
            },
            singleton: true
        )
    }
}

// MARK: - Graceful Degradation Services

/// No-op export service for graceful degradation when PDF export fails
final class NoOpExportService: ExportServiceProtocol {
    func exportToPDF(entryId: UUID, settings: PDFExportSettings) async throws -> Data {
        print("Export service unavailable - PDF export disabled")
        throw FreewriteError.pdfGenerationFailed
    }
    
    func exportToText(entryId: UUID) async throws -> String {
        print("Export service unavailable - text export disabled") 
        throw FreewriteError.fileOperationFailed("Export service unavailable")
    }
    
    func exportToMarkdown(entryId: UUID) async throws -> String {
        print("Export service unavailable - markdown export disabled")
        throw FreewriteError.fileOperationFailed("Export service unavailable")
    }
    
    func suggestedFilename(for entryId: UUID, format: ExportFormat) async throws -> String {
        return "export-unavailable"
    }
}

/// Lazy PDF export service to break dependency cycles
final class LazyPDFExportService: ExportServiceProtocol {
    private lazy var underlyingService: ExportServiceProtocol = {
        // Lazy resolution prevents dependency cycles during initialization
        do {
            let fileService = try DIContainer.shared.resolveSafe(FileManagementServiceProtocol.self)
            return PDFExportService(fileService: fileService)
        } catch {
            print("WARNING: Failed to resolve FileManagementService for export, using no-op service")
            return NoOpExportService()
        }
    }()
    
    func exportToPDF(entryId: UUID, settings: PDFExportSettings) async throws -> Data {
        return try await underlyingService.exportToPDF(entryId: entryId, settings: settings)
    }
    
    func exportToText(entryId: UUID) async throws -> String {
        return try await underlyingService.exportToText(entryId: entryId)
    }
    
    func exportToMarkdown(entryId: UUID) async throws -> String {
        return try await underlyingService.exportToMarkdown(entryId: entryId)
    }
    
    func suggestedFilename(for entryId: UUID, format: ExportFormat) async throws -> String {
        return try await underlyingService.suggestedFilename(for: entryId, format: format)
    }
}

/// No-op AI service for graceful degradation when AI integration fails  
@MainActor
final class NoOpAIIntegrationService: AIIntegrationServiceProtocol {
    func canShareViaURL(_ content: String) -> Bool { false }
    
    func generateChatGPTURL(content: String, prompt: String?) throws -> URL {
        throw FreewriteError.urlTooLong
    }
    
    func generateClaudeURL(content: String, prompt: String?) throws -> URL {
        throw FreewriteError.urlTooLong  
    }
    
    func createPromptForClipboard(content: String, prompt: String?) -> String {
        return "AI Integration unavailable"
    }
    
    func copyPromptToClipboard(content: String, prompt: String?) {
        print("AI Integration unavailable - clipboard copy disabled")
    }
    
    func openURL(_ url: URL) {
        print("AI Integration unavailable - URL opening disabled")
    }
    
    func openChatGPT(with content: String) async throws {
        print("AI Integration unavailable - ChatGPT opening disabled")
        throw FreewriteError.invalidConfiguration
    }
    
    func openClaude(with content: String) async throws {
        print("AI Integration unavailable - Claude opening disabled")
        throw FreewriteError.invalidConfiguration
    }
    
    func copyPromptToClipboard(with content: String) {
        print("AI Integration unavailable - clipboard copy disabled")
    }
}

// MARK: - Testing Support
extension DIContainer {
    /// Resets the container for testing
    func reset() {
        services.clear()
        isConfigured = false
    }
}