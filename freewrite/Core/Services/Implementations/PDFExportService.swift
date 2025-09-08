import Foundation
import CoreText
import AppKit

/// PDF export service implementation
@MainActor
final class PDFExportService: ExportServiceProtocol {
    private let fileService: FileManagementServiceProtocol
    
    init(fileService: FileManagementServiceProtocol) {
        self.fileService = fileService
    }
    
    func exportToPDF(entryId: UUID, settings: PDFExportSettings) async throws -> Data {
        let content = try await fileService.loadEntry(entryId)
        return try createPDFFromText(content, settings: settings)
    }
    
    func exportToText(entryId: UUID) async throws -> String {
        let content = try await fileService.loadEntry(entryId)
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func exportToMarkdown(entryId: UUID) async throws -> String {
        // For now, entries are already in markdown format
        return try await exportToText(entryId: entryId)
    }
    
    func suggestedFilename(for entryId: UUID, format: ExportFormat) async throws -> String {
        let entries = try await fileService.loadAllEntries()
        guard let entry = entries.first(where: { $0.id == entryId }) else {
            throw FreewriteError.entryNotFound
        }
        
        let content = try await fileService.loadEntry(entryId)
        let title = extractTitleFromContent(content, date: entry.displayDate)
        
        return "\(title).\(format.fileExtension)"
    }
    
    // MARK: - Private Methods
    
    private func createPDFFromText(_ text: String, settings: PDFExportSettings) throws -> Data {
        // Letter size page dimensions
        let pageWidth: CGFloat = 612.0  // 8.5 x 72
        let pageHeight: CGFloat = 792.0 // 11 x 72
        
        // Calculate content area
        let contentRect = CGRect(
            x: settings.margins.left,
            y: settings.margins.bottom,
            width: pageWidth - (settings.margins.left + settings.margins.right),
            height: pageHeight - (settings.margins.top + settings.margins.bottom)
        )
        
        // Create PDF data container
        let pdfData = NSMutableData()
        
        // Configure text formatting
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = settings.lineSpacing
        
        guard let font = NSFont(name: settings.fontName, size: settings.fontSize) else {
            throw FreewriteError.pdfGenerationFailed
        }
        
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.black,
            .paragraphStyle: paragraphStyle
        ]
        
        // Clean text content
        let cleanedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let attributedString = NSAttributedString(string: cleanedText, attributes: textAttributes)
        
        // Create PDF context
        guard let dataConsumer = CGDataConsumer(data: pdfData),
              let pdfContext = CGContext(consumer: dataConsumer, mediaBox: nil, nil) else {
            throw FreewriteError.pdfGenerationFailed
        }
        
        // Create text layout
        let framesetter = CTFramesetterCreateWithAttributedString(attributedString)
        var currentRange = CFRange(location: 0, length: 0)
        var pageIndex = 0
        
        // Generate pages
        while currentRange.location < attributedString.length {
            // Begin new page
            pdfContext.beginPage(mediaBox: nil)
            
            // Fill background
            pdfContext.setFillColor(NSColor.white.cgColor)
            pdfContext.fill(CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))
            
            // Create text frame
            let framePath = CGMutablePath()
            framePath.addRect(contentRect)
            
            let frame = CTFramesetterCreateFrame(
                framesetter,
                currentRange,
                framePath,
                nil
            )
            
            // Draw text
            CTFrameDraw(frame, pdfContext)
            
            // Update range for next page
            let visibleRange = CTFrameGetVisibleStringRange(frame)
            currentRange.location += visibleRange.length
            
            pdfContext.endPage()
            pageIndex += 1
            
            // Safety limit
            if pageIndex > 100 {
                print("PDF generation safety limit reached")
                break
            }
        }
        
        pdfContext.closePDF()
        return pdfData as Data
    }
    
    private func extractTitleFromContent(_ content: String, date: String) -> String {
        // Clean content
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            return "Entry-\(date)"
        }
        
        // Extract first few words
        let words = trimmed
            .replacingOccurrences(of: "\n", with: " ")
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .map { word in
                word.trimmingCharacters(in: CharacterSet(charactersIn: ".,!?;:\"'()[]{}<>"))
                    .lowercased()
            }
            .filter { !$0.isEmpty }
        
        // Use first 4 words or less
        let titleWords = Array(words.prefix(4))
        
        return titleWords.isEmpty ? 
            "Entry-\(date)" : 
            titleWords.joined(separator: "-")
    }
}