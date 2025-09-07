import Foundation
import SwiftUI

// MARK: - Writing Entry DTO
struct WritingEntryDTO: Identifiable, Sendable, Hashable {
    let id: UUID
    let filename: String
    let displayDate: String
    let previewText: String
    let wordCount: Int
    let isWelcomeEntry: Bool
    let createdAt: Date
    let modifiedAt: Date
    
    // Computed properties
    var displayTitle: String {
        previewText.isEmpty ? "New Entry" : previewText
    }
    
    var formattedDate: String {
        DateFormatter.entryFormatter.string(from: createdAt)
    }
    
    var isEmpty: Bool {
        previewText.isEmpty
    }
}

// MARK: - User Preferences DTO
struct UserPreferencesDTO: Sendable, Hashable {
    let selectedFont: String
    let fontSize: CGFloat
    let colorScheme: ColorScheme
    let timerDuration: Int
    
    enum ColorScheme: String, CaseIterable, Sendable {
        case light = "light"
        case dark = "dark"
        
        var swiftUIColorScheme: SwiftUI.ColorScheme {
            switch self {
            case .light: return .light
            case .dark: return .dark
            }
        }
    }
    
    static let `default` = UserPreferencesDTO(
        selectedFont: FontConstants.defaultFont,
        fontSize: FontConstants.defaultSize,
        colorScheme: .light,
        timerDuration: FreewriteConstants.defaultTimerDuration
    )
}

// MARK: - PDF Export Settings
struct PDFExportSettings: Sendable {
    let fontSize: CGFloat
    let fontName: String
    let lineSpacing: CGFloat
    let margins: PDFMargins
    
    static let `default` = PDFExportSettings(
        fontSize: 12,
        fontName: "Helvetica",
        lineSpacing: 4,
        margins: PDFMargins.standard
    )
}

struct PDFMargins: Sendable {
    let top: CGFloat
    let bottom: CGFloat
    let left: CGFloat
    let right: CGFloat
    
    static let standard = PDFMargins(
        top: 72,
        bottom: 72,
        left: 72,
        right: 72
    )
}

// MARK: - App State DTOs
struct AppStateDTO: Sendable {
    let isFullscreen: Bool
    let showingSidebar: Bool
    let selectedEntryId: UUID?
    let bottomNavOpacity: Double
    
    static let initial = AppStateDTO(
        isFullscreen: false,
        showingSidebar: false,
        selectedEntryId: nil,
        bottomNavOpacity: 1.0
    )
}

struct TimerStateDTO: Sendable {
    let timeRemaining: Int
    let isRunning: Bool
    let isFinished: Bool
    
    static let initial = TimerStateDTO(
        timeRemaining: FreewriteConstants.defaultTimerDuration,
        isRunning: false,
        isFinished: false
    )
}

// MARK: - Error Types
enum FreewriteError: Error, Sendable {
    case fileOperationFailed(String)
    case invalidEntryFormat
    case entryNotFound
    case pdfGenerationFailed
    case urlTooLong
    case invalidConfiguration
    
    var localizedDescription: String {
        switch self {
        case .fileOperationFailed(let message):
            return "File operation failed: \(message)"
        case .invalidEntryFormat:
            return "Invalid entry format"
        case .entryNotFound:
            return "Entry not found"
        case .pdfGenerationFailed:
            return "Failed to generate PDF"
        case .urlTooLong:
            return "URL too long for sharing"
        case .invalidConfiguration:
            return "Invalid configuration"
        }
    }
}

// MARK: - Date Formatter Extensions
extension DateFormatter {
    static let entryFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()
    
    static let shortFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()
    
    static let filenameFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        return formatter
    }()
}