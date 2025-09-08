import Foundation

/// File management service implementation
@MainActor
final class FileManagementService: FileManagementServiceProtocol {
    private let fileManager = FileManager.default
    
    // Cached documents directory for performance
    private lazy var documentsDirectory: URL = {
        let directory = fileManager
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(FileSystemConstants.documentsDirectoryName)
        
        // Create directory if it doesn't exist
        if !fileManager.fileExists(atPath: directory.path) {
            do {
                try fileManager.createDirectory(
                    at: directory,
                    withIntermediateDirectories: true
                )
                print("Created Freewrite directory at: \(directory.path)")
            } catch {
                print("Error creating directory: \(error)")
            }
        }
        
        return directory
    }()
    
    func createNewEntry() async throws -> WritingEntryDTO {
        let id = UUID()
        let now = Date()
        
        // Create filename with UUID and timestamp
        let dateString = DateFormatter.filenameFormatter.string(from: now)
        let filename = "[\(id.uuidString)]-[\(dateString)].\(FileSystemConstants.fileExtension)"
        
        // Format display date
        let displayDate = DateFormatter.entryFormatter.string(from: now)
        
        let entry = WritingEntryDTO(
            id: id,
            filename: filename,
            displayDate: displayDate,
            previewText: "",
            wordCount: 0,
            isWelcomeEntry: false,
            createdAt: now,
            modifiedAt: now
        )
        
        // Create empty file
        let fileURL = documentsDirectory.appendingPathComponent(filename)
        let initialContent = FreewriteConstants.headerString
        
        do {
            try initialContent.write(to: fileURL, atomically: true, encoding: .utf8)
            print("Created new entry: \(filename)")
        } catch {
            throw FreewriteError.fileOperationFailed("Failed to create entry: \(error)")
        }
        
        return entry
    }
    
    func loadEntry(_ entryId: UUID) async throws -> String {
        guard let entry = try await findEntry(entryId) else {
            throw FreewriteError.entryNotFound
        }
        
        let fileURL = documentsDirectory.appendingPathComponent(entry.filename)
        
        do {
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            print("Loaded entry: \(entry.filename)")
            return content
        } catch {
            throw FreewriteError.fileOperationFailed("Failed to load entry: \(error)")
        }
    }
    
    func saveEntry(_ entryId: UUID, content: String) async throws {
        guard let entry = try await findEntry(entryId) else {
            throw FreewriteError.entryNotFound
        }
        
        let fileURL = documentsDirectory.appendingPathComponent(entry.filename)
        
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            print("Saved entry: \(entry.filename)")
        } catch {
            throw FreewriteError.fileOperationFailed("Failed to save entry: \(error)")
        }
    }
    
    func deleteEntry(_ entryId: UUID) async throws {
        guard let entry = try await findEntry(entryId) else {
            throw FreewriteError.entryNotFound
        }
        
        let fileURL = documentsDirectory.appendingPathComponent(entry.filename)
        
        do {
            try fileManager.removeItem(at: fileURL)
            print("Deleted entry: \(entry.filename)")
        } catch {
            throw FreewriteError.fileOperationFailed("Failed to delete entry: \(error)")
        }
    }
    
    func loadAllEntries() async throws -> [WritingEntryDTO] {
        do {
            let fileURLs = try fileManager.contentsOfDirectory(
                at: documentsDirectory,
                includingPropertiesForKeys: nil
            )
            
            let mdFiles = fileURLs.filter { $0.pathExtension == FileSystemConstants.fileExtension }
            print("Found \(mdFiles.count) entries")
            
            let entries = try await processEntryFiles(mdFiles)
            return entries.sorted { $0.createdAt > $1.createdAt }
            
        } catch {
            throw FreewriteError.fileOperationFailed("Failed to load entries: \(error)")
        }
    }
    
    func updatePreviewText(_ entryId: UUID) async throws {
        guard let entry = try await findEntry(entryId) else {
            throw FreewriteError.entryNotFound
        }
        
        let content = try await loadEntry(entryId)
        let _ = extractPreviewText(from: content)
        
        print("Updated preview for entry: \(entry.filename)")
    }
    
    func getDocumentsDirectory() -> URL {
        return documentsDirectory
    }
    
    func entryExists(_ entryId: UUID) async -> Bool {
        do {
            return try await findEntry(entryId) != nil
        } catch {
            return false
        }
    }
    
    // MARK: - Private Methods
    
    private func findEntry(_ entryId: UUID) async throws -> WritingEntryDTO? {
        let entries = try await loadAllEntries()
        return entries.first { $0.id == entryId }
    }
    
    private func processEntryFiles(_ fileURLs: [URL]) async throws -> [WritingEntryDTO] {
        var entries: [WritingEntryDTO] = []
        
        for fileURL in fileURLs {
            do {
                let entry = try await processEntryFile(fileURL)
                entries.append(entry)
            } catch {
                print("Error processing entry \(fileURL.lastPathComponent): \(error)")
                // Continue processing other entries
            }
        }
        
        return entries
    }
    
    private func processEntryFile(_ fileURL: URL) async throws -> WritingEntryDTO {
        let filename = fileURL.lastPathComponent
        
        // Extract UUID and date from filename pattern: [uuid]-[yyyy-MM-dd-HH-mm-ss].md
        guard let uuidMatch = filename.range(of: "\\[(.*?)\\]", options: .regularExpression),
              let dateMatch = filename.range(of: "\\[(\\d{4}-\\d{2}-\\d{2}-\\d{2}-\\d{2}-\\d{2})\\]", options: .regularExpression),
              let uuid = UUID(uuidString: String(filename[uuidMatch].dropFirst().dropLast())) else {
            throw FreewriteError.invalidEntryFormat
        }
        
        // Parse date
        let dateString = String(filename[dateMatch].dropFirst().dropLast())
        guard let fileDate = DateFormatter.filenameFormatter.date(from: dateString) else {
            throw FreewriteError.invalidEntryFormat
        }
        
        // Read content for preview
        let content = try String(contentsOf: fileURL, encoding: .utf8)
        let previewText = extractPreviewText(from: content)
        let wordCount = calculateWordCount(content)
        let isWelcomeEntry = content.contains("Welcome to Freewrite")
        
        // Format display date
        let displayDate = DateFormatter.entryFormatter.string(from: fileDate)
        
        return WritingEntryDTO(
            id: uuid,
            filename: filename,
            displayDate: displayDate,
            previewText: previewText,
            wordCount: wordCount,
            isWelcomeEntry: isWelcomeEntry,
            createdAt: fileDate,
            modifiedAt: fileDate // TODO: Get actual modification date
        )
    }
    
    private func extractPreviewText(from content: String) -> String {
        let trimmed = content
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        return trimmed.isEmpty ? "" : 
            (trimmed.count > 30 ? String(trimmed.prefix(30)) + "..." : trimmed)
    }
    
    private func calculateWordCount(_ content: String) -> Int {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? 0 : 
            trimmed.components(separatedBy: .whitespacesAndNewlines)
                   .filter { !$0.isEmpty }.count
    }
}