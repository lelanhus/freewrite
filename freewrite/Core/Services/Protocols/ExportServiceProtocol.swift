import Foundation

/// Service responsible for exporting entries to various formats
@MainActor
protocol ExportServiceProtocol: Sendable {
    /// Exports an entry as PDF
    /// - Parameters:
    ///   - entryId: The unique identifier of the entry
    ///   - settings: PDF export settings
    /// - Returns: PDF data
    func exportToPDF(entryId: UUID, settings: PDFExportSettings) async throws -> Data
    
    /// Exports an entry as plain text
    /// - Parameter entryId: The unique identifier of the entry
    /// - Returns: Plain text content
    func exportToText(entryId: UUID) async throws -> String
    
    /// Exports an entry as Markdown
    /// - Parameter entryId: The unique identifier of the entry
    /// - Returns: Markdown formatted content
    func exportToMarkdown(entryId: UUID) async throws -> String
    
    /// Generates a suggested filename for export
    /// - Parameters:
    ///   - entryId: The unique identifier of the entry
    ///   - format: The export format (pdf, txt, md)
    /// - Returns: Suggested filename with extension
    func suggestedFilename(for entryId: UUID, format: ExportFormat) async throws -> String
}

// MARK: - Export Format
enum ExportFormat: String, CaseIterable, Sendable {
    case pdf = "pdf"
    case text = "txt"
    case markdown = "md"
    
    var fileExtension: String {
        rawValue
    }
    
    var displayName: String {
        switch self {
        case .pdf: return "PDF"
        case .text: return "Plain Text"
        case .markdown: return "Markdown"
        }
    }
}