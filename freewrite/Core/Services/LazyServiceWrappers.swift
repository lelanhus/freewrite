import Foundation
import SwiftUI

/// Lazy service wrapper that defers expensive service initialization until first use
@MainActor
final class LazyServiceWrapper<Service>: @unchecked Sendable {
    private var _service: Service?
    private let factory: () -> Service
    private let serviceName: String
    
    init(serviceName: String, factory: @escaping () -> Service) {
        self.serviceName = serviceName
        self.factory = factory
    }
    
    var service: Service {
        if let service = _service {
            return service
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        let newService = factory()
        let initTime = CFAbsoluteTimeGetCurrent() - startTime
        
        if initTime > PerformanceConstants.minimumTimeInterval {
            let formattedTime = String(format: KeyboardShortcutConstants.timingFormatPrecision, initTime * KeyboardShortcutConstants.millisecondsMultiplier)
            print("🚀 Lazy initialized \(serviceName) in \(formattedTime)ms")
        }
        
        _service = newService
        return newService
    }
    
    /// Check if service has been initialized without triggering initialization
    var isInitialized: Bool {
        return _service != nil
    }
    
    /// Reset the service (primarily for testing)
    func reset() {
        _service = nil
    }
}

/// Lazy AI integration service for performance optimization
@MainActor
final class LazyAIIntegrationService: AIIntegrationServiceProtocol {
    private let lazyService: LazyServiceWrapper<AIIntegrationServiceProtocol>
    
    init() {
        self.lazyService = LazyServiceWrapper(serviceName: "AIIntegrationService") {
            // Only initialize when first needed
            return AIIntegrationService()
        }
    }
    
    var isInitialized: Bool { lazyService.isInitialized }
    
    func canShareViaURL(_ content: String) -> Bool {
        return lazyService.service.canShareViaURL(content)
    }
    
    func generateChatGPTURL(content: String, prompt: String?) throws -> URL {
        return try lazyService.service.generateChatGPTURL(content: content, prompt: prompt)
    }
    
    func generateClaudeURL(content: String, prompt: String?) throws -> URL {
        return try lazyService.service.generateClaudeURL(content: content, prompt: prompt)
    }
    
    func createPromptForClipboard(content: String, prompt: String?) -> String {
        return lazyService.service.createPromptForClipboard(content: content, prompt: prompt)
    }
    
    func copyPromptToClipboard(content: String, prompt: String?) {
        lazyService.service.copyPromptToClipboard(content: content, prompt: prompt)
    }
    
    func openURL(_ url: URL) {
        lazyService.service.openURL(url)
    }
    
    func openChatGPT(with content: String) async throws {
        try await lazyService.service.openChatGPT(with: content)
    }
    
    func openClaude(with content: String) async throws {
        try await lazyService.service.openClaude(with: content)
    }
    
    func copyPromptToClipboard(with content: String) {
        lazyService.service.copyPromptToClipboard(with: content)
    }
}

/// Lazy state manager for less-critical UI features
@MainActor
@Observable
final class LazyShortcutDisclosureManager: ShortcutDisclosureManaging {
    private let lazyManager: LazyServiceWrapper<ShortcutDisclosureManager>
    
    init() {
        self.lazyManager = LazyServiceWrapper(serviceName: "ShortcutDisclosureManager") {
            return ShortcutDisclosureManager()
        }
    }
    
    var isInitialized: Bool { lazyManager.isInitialized }
    
    func registerSessionStart() {
        lazyManager.service.registerSessionStart()
    }
    
    func registerShortcutUsed(_ shortcut: String) {
        lazyManager.service.registerShortcutUsed(shortcut)
    }
    
    func shouldShowTooltip(for shortcut: String) -> Bool {
        return lazyManager.service.shouldShowTooltip(for: shortcut)
    }
    
    func getTooltipFor(element: String) -> String? {
        return lazyManager.service.getTooltipFor(element: element)
    }
}

/// Performance monitoring for lazy initialization
struct LazyInitializationStats {
    let totalServicesRegistered: Int
    let servicesInitialized: Int
    let averageInitTime: TimeInterval
    let longestInitService: String?
    let longestInitTime: TimeInterval
    
    var initializationRatio: Double {
        guard totalServicesRegistered > PerformanceConstants.zeroValue else { return Double(PerformanceConstants.zeroValue) }
        return Double(servicesInitialized) / Double(totalServicesRegistered)
    }
    
    var isPerformanceOptimal: Bool {
        // Good performance if we've initialized less than 70% of services and init times are reasonable
        return initializationRatio < 0.7 && averageInitTime < 0.01 // 10ms average
    }
}

/// Manager for tracking lazy initialization performance
@MainActor
final class LazyInitializationTracker: @unchecked Sendable {
    static let shared = LazyInitializationTracker()
    
    private var serviceStats: [String: (initTime: TimeInterval, isInitialized: Bool)] = [:]
    
    private init() {}
    
    func recordInitialization(serviceName: String, initTime: TimeInterval) {
        serviceStats[serviceName] = (initTime: initTime, isInitialized: true)
    }
    
    func recordServiceRegistration(serviceName: String) {
        if serviceStats[serviceName] == nil {
            serviceStats[serviceName] = (initTime: TimeInterval(PerformanceConstants.zeroValue), isInitialized: false)
        }
    }
    
    func getStats() -> LazyInitializationStats {
        let totalServices = serviceStats.count
        let initializedServices = serviceStats.values.filter { $0.isInitialized }.count
        let initTimes = serviceStats.values.compactMap { $0.isInitialized ? $0.initTime : nil }
        let averageTime = initTimes.isEmpty ? TimeInterval(PerformanceConstants.zeroValue) : initTimes.reduce(TimeInterval(PerformanceConstants.zeroValue), +) / Double(initTimes.count)
        
        let longestInit = serviceStats.max { $0.value.initTime < $1.value.initTime }
        
        return LazyInitializationStats(
            totalServicesRegistered: totalServices,
            servicesInitialized: initializedServices,
            averageInitTime: averageTime,
            longestInitService: longestInit?.key,
            longestInitTime: longestInit?.value.initTime ?? TimeInterval(PerformanceConstants.zeroValue)
        )
    }
    
    func reset() {
        serviceStats.removeAll()
    }
}