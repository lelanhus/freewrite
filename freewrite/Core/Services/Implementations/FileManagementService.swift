import Foundation

/// File management service implementation
@MainActor
final class FileManagementService: FileManagementServiceProtocol {
    private let fileManager = FileManager.default
    
    // Entry caching for performance
    private var entryCache: [UUID: WritingEntryDTO] = [:]
    private var entryCacheTimestamp: Date?
    private let cacheExpiryInterval: TimeInterval = 30.0 // 30 seconds
    
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
            
            // Update cache with new entry
            updateCacheEntry(entry)
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
            
            // Update cache with modified entry data
            let updatedEntry = WritingEntryDTO(
                id: entry.id,
                filename: entry.filename,
                displayDate: entry.displayDate,
                previewText: extractPreviewText(from: content),
                wordCount: calculateWordCount(content),
                isWelcomeEntry: entry.isWelcomeEntry,
                createdAt: entry.createdAt,
                modifiedAt: Date()
            )
            updateCacheEntry(updatedEntry)
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
            
            // Remove from cache
            removeCacheEntry(entryId)
        } catch {
            throw FreewriteError.fileOperationFailed("Failed to delete entry: \(error)")
        }
    }
    
    func loadAllEntries() async throws -> [WritingEntryDTO] {
        // Return cached entries if available and valid
        if isCacheValid(), !entryCache.isEmpty {
            return Array(entryCache.values).sorted { $0.createdAt > $1.createdAt }
        }
        
        // Cache miss or expired, refresh cache
        try await refreshEntryCache()
        return Array(entryCache.values).sorted { $0.createdAt > $1.createdAt }
    }
    
    private func loadAllEntriesFromDisk() async throws -> [WritingEntryDTO] {
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
        // Try to get from cache first
        if let cachedEntry = getCachedEntry(entryId) {
            return cachedEntry
        }
        
        // Cache miss, refresh cache and try again
        try await refreshEntryCache()
        return getCachedEntry(entryId)
    }
    
    // MARK: - Cache Management
    
    private func getCachedEntry(_ entryId: UUID) -> WritingEntryDTO? {
        guard isCacheValid() else { return nil }
        return entryCache[entryId]
    }
    
    private func isCacheValid() -> Bool {
        guard let timestamp = entryCacheTimestamp else { return false }
        return Date().timeIntervalSince(timestamp) < cacheExpiryInterval
    }
    
    private func refreshEntryCache() async throws {
        let entries = try await loadAllEntriesFromDisk()
        entryCache.removeAll()
        
        for entry in entries {
            entryCache[entry.id] = entry
        }
        
        entryCacheTimestamp = Date()
    }
    
    private func invalidateCache() {
        entryCache.removeAll()
        entryCacheTimestamp = nil
    }
    
    private func updateCacheEntry(_ entry: WritingEntryDTO) {
        entryCache[entry.id] = entry
    }
    
    private func removeCacheEntry(_ entryId: UUID) {
        entryCache.removeValue(forKey: entryId)
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
            modifiedAt: getFileModificationDate(for: fileURL) ?? fileDate
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
    
    private func getFileModificationDate(for fileURL: URL) -> Date? {
        do {
            let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
            return attributes[.modificationDate] as? Date
        } catch {
            print("Warning: Could not get modification date for \(fileURL.lastPathComponent): \(error)")
            return nil
        }
    }
}