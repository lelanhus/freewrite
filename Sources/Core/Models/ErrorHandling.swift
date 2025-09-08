import SwiftUI
import Foundation

// MARK: - Enhanced Error Handling

/// User-facing error information with recovery options
struct UserError: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let recoverySuggestion: String?
    let recoveryAction: (() -> Void)?
    
    static func fileOperationFailed(operation: String, error: Error, retry: (() -> Void)? = nil) -> UserError {
        UserError(
            title: "File Operation Failed",
            message: "Failed to \(operation). \(error.localizedDescription)",
            recoverySuggestion: retry != nil ? "Tap Retry to try again." : nil,
            recoveryAction: retry
        )
    }
    
    static func timerError(_ error: Error) -> UserError {
        UserError(
            title: "Timer Error",
            message: "Timer operation failed: \(error.localizedDescription)",
            recoverySuggestion: "The timer may not work correctly until you restart the app.",
            recoveryAction: nil
        )
    }
    
    static func aiIntegrationError(_ error: Error) -> UserError {
        UserError(
            title: "AI Integration Error", 
            message: "Failed to open AI chat: \(error.localizedDescription)",
            recoverySuggestion: "Try copying the prompt manually or check your internet connection.",
            recoveryAction: nil
        )
    }
    
    static func entryLoadingFailed(_ error: Error, createNew: @escaping () -> Void) -> UserError {
        UserError(
            title: "Entry Loading Failed",
            message: "Could not load your writing entries: \(error.localizedDescription)",
            recoverySuggestion: "Tap 'Create New' to start fresh or check file permissions.",
            recoveryAction: createNew
        )
    }
}

/// Error management observable for ContentView
@Observable
final class ErrorManager {
    private(set) var currentError: UserError? = nil
    private var errorLog: [ErrorLogEntry] = []
    
    func reportError(_ error: UserError) {
        currentError = error
        logError(error)
        print("ERROR: \(error.title) - \(error.message)")
    }
    
    func clearError() {
        currentError = nil
    }
    
    func retryCurrentOperation() {
        currentError?.recoveryAction?()
        clearError()
    }
    
    private func logError(_ error: UserError) {
        let logEntry = ErrorLogEntry(
            timestamp: Date(),
            title: error.title,
            message: error.message
        )
        errorLog.append(logEntry)
        
        // Keep only last 50 errors to prevent memory bloat
        if errorLog.count > 50 {
            errorLog.removeFirst()
        }
    }
    
    /// Get recent errors for debugging
    var recentErrors: [ErrorLogEntry] {
        Array(errorLog.suffix(10))
    }
}

/// Internal error logging
struct ErrorLogEntry {
    let timestamp: Date
    let title: String  
    let message: String
}

// MARK: - Retry Mechanism

/// Utility for retrying async operations with exponential backoff
struct RetryHandler {
    static func withRetry<T>(
        maxAttempts: Int = 3,
        initialDelay: TimeInterval = 0.5,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        
        for attempt in 1...maxAttempts {
            do {
                return try await operation()
            } catch {
                lastError = error
                
                if attempt < maxAttempts {
                    let delay = initialDelay * Double(attempt) // Exponential backoff
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? FreewriteError.retryFailed
    }
}

// MARK: - Enhanced FreewriteError

extension FreewriteError {
    static let retryFailed = FreewriteError.fileOperationFailed("Maximum retry attempts exceeded")
    
    var userFriendlyDescription: String {
        switch self {
        case .fileOperationFailed(let message):
            return "File operation failed: \(message)"
        case .invalidConfiguration:
            return "App configuration is invalid. Please restart the application."
        case .urlTooLong:
            return "Your entry is too long to share via URL. Try copying the prompt instead."
        case .invalidEntryFormat:
            return "Entry file format is invalid and cannot be loaded."
        case .entryNotFound:
            return "The requested entry could not be found."
        case .pdfGenerationFailed:
            return "PDF generation failed. Please try again."
        }
    }
}