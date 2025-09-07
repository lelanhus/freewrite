import Foundation

/// Thread-safe service registry for dependency injection
final class ServiceRegistry: @unchecked Sendable {
    private let lock = NSLock()
    private var factories: [ObjectIdentifier: () -> Any] = [:]
    private var singletons: [ObjectIdentifier: Any] = [:]
    
    /// Registers a service factory
    /// - Parameters:
    ///   - type: The service type to register
    ///   - factory: Factory closure that creates instances
    ///   - singleton: Whether to cache the instance as a singleton
    func register<T>(
        _ type: T.Type,
        factory: @escaping () -> T,
        singleton: Bool = false
    ) {
        lock.withLock {
            let key = ObjectIdentifier(type)
            factories[key] = factory
            
            if singleton {
                singletons[key] = factory()
            }
        }
    }
    
    /// Resolves a service instance
    /// - Parameter type: The service type to resolve
    /// - Returns: Service instance or nil if not registered
    func resolve<T>(_ type: T.Type) -> T? {
        lock.withLock {
            let key = ObjectIdentifier(type)
            
            // Return singleton if exists
            if let singleton = singletons[key] as? T {
                return singleton
            }
            
            // Create new instance
            guard let factory = factories[key] else { return nil }
            return factory() as? T
        }
    }
    
    /// Unregisters a service
    /// - Parameter type: The service type to unregister
    func unregister<T>(_ type: T.Type) {
        lock.withLock {
            let key = ObjectIdentifier(type)
            factories.removeValue(forKey: key)
            singletons.removeValue(forKey: key)
        }
    }
    
    /// Clears all registered services
    func clear() {
        lock.withLock {
            factories.removeAll()
            singletons.removeAll()
        }
    }
    
    /// Checks if a service is registered
    /// - Parameter type: The service type to check
    /// - Returns: Boolean indicating if service is registered
    func isRegistered<T>(_ type: T.Type) -> Bool {
        lock.withLock {
            let key = ObjectIdentifier(type)
            return factories[key] != nil
        }
    }
}