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
    /// Resets the container for testing
    func reset() {
        services.clear()
        isConfigured = false
    }
}