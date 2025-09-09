import Foundation
@testable import Freewrite

final class MockExportService: @unchecked Sendable, ExportServiceProtocol {
    func exportToPDF(entryId: UUID, settings: PDFExportSettings) async throws -> Data { 
        fatalError("Mock not implemented") 
    }
    
    func exportToText(entryId: UUID) async throws -> String { 
        fatalError("Mock not implemented") 
    }
    
    func exportToMarkdown(entryId: UUID) async throws -> String { 
        fatalError("Mock not implemented") 
    }
    
    func suggestedFilename(for entryId: UUID, format: ExportFormat) async throws -> String { 
        fatalError("Mock not implemented") 
    }
}