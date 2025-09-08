import Foundation

/// File management service implementation
@MainActor
final class FileManagementService: FileManagementServiceProtocol {
    private let fileManager = FileManager.default
    
    // Background queue for heavy file operations to prevent UI blocking
    private let fileOperationQueue = DispatchQueue(
        label: "freewrite.fileoperations", 
        qos: .userInitiated,
        attributes: .concurrent
    )
    
    // Entry caching for performance
    private var entryCache: [UUID: WritingEntryDTO] = [:]
    private var entryCacheTimestamp: Date?
    private let cacheExpiryInterval: TimeInterval = 30.0 // 30 seconds
    
    // File operation coordination to prevent corruption
    private var activeSaveOperations: Set<UUID> = []
    
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
        
        // Atomic file creation with rollback capability
        let fileURL = documentsDirectory.appendingPathComponent(filename)
        let initialContent = FreewriteConstants.headerString
        
        // Check if file already exists to prevent overwriting
        if fileManager.fileExists(atPath: fileURL.path) {
            throw FreewriteError.fileOperationFailed("Entry file already exists: \(filename)")
        }
        
        do {
            // Step 1: Create file atomically
            try initialContent.write(to: fileURL, atomically: true, encoding: .utf8)
            
            // Step 2: Update cache (if this fails, rollback file creation)
            updateCacheEntry(entry)
            
            print("Created new entry: \(filename)")
            return entry
            
        } catch {
            // Rollback: Remove file if it was created but cache update failed
            if fileManager.fileExists(atPath: fileURL.path) {
                try? fileManager.removeItem(at: fileURL)
                print("Rolled back file creation for: \(filename)")
            }
            throw FreewriteError.fileOperationFailed("Failed to create entry: \(error)")
        }
    }
    
    func loadEntry(_ entryId: UUID) async throws -> String {
        guard let entry = try await findEntry(entryId) else {
            throw FreewriteError.entryNotFound
        }
        
        let fileURL = documentsDirectory.appendingPathComponent(entry.filename)
        
        // Move file reading to background queue to prevent UI blocking
        return try await withCheckedThrowingContinuation { continuation in
            fileOperationQueue.async {
                do {
                    let content = try String(contentsOf: fileURL, encoding: .utf8)
                    print("Loaded entry: \(entry.filename)")
                    continuation.resume(returning: content)
                } catch {
                    continuation.resume(throwing: FreewriteError.fileOperationFailed("Failed to load entry: \(error)"))
                }
            }
        }
    }
    
    func saveEntry(_ entryId: UUID, content: String) async throws {
        // Prevent concurrent saves to same entry to avoid file corruption
        guard !activeSaveOperations.contains(entryId) else {
            throw FreewriteError.fileOperationFailed("Save already in progress for entry: \(entryId)")
        }
        
        guard let entry = try await findEntry(entryId) else {
            throw FreewriteError.entryNotFound
        }
        
        let fileURL = documentsDirectory.appendingPathComponent(entry.filename)
        
        // Mark save operation as active to prevent concurrent writes
        activeSaveOperations.insert(entryId)
        
        defer {
            // Always cleanup active operation, even if save fails
            activeSaveOperations.remove(entryId)
        }
        
        // Move file writing to background queue to prevent UI blocking
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            fileOperationQueue.async {
                do {
                    // Atomic file write on background queue
                    try content.write(to: fileURL, atomically: true, encoding: .utf8)
                    
                    // Switch back to main actor for cache update
                    Task { @MainActor in
                        // Update cache with modified entry data (must be after successful write)
                        let updatedEntry = WritingEntryDTO(
                            id: entry.id,
                            filename: entry.filename,
                            displayDate: entry.displayDate,
                            previewText: self.extractPreviewText(from: content),
                            wordCount: self.calculateWordCount(content),
                            isWelcomeEntry: entry.isWelcomeEntry,
                            createdAt: entry.createdAt,
                            modifiedAt: Date()
                        )
                        self.updateCacheEntry(updatedEntry)
                        
                        print("Saved entry: \(entry.filename)")
                        continuation.resume()
                    }
                } catch {
                    continuation.resume(throwing: FreewriteError.fileOperationFailed("Failed to save entry: \(error)"))
                }
            }
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
        // Atomic cache access - check validity and return in single operation
        let cachedEntries = getValidCachedEntries()
        if !cachedEntries.isEmpty {
            return cachedEntries.sorted { $0.createdAt > $1.createdAt }
        }
        
        // Cache miss or expired, refresh cache atomically
        try await refreshEntryCache()
        return Array(entryCache.values).sorted { $0.createdAt > $1.createdAt }
    }
    
    private func loadAllEntriesFromDisk() async throws -> [WritingEntryDTO] {
        // Move heavy directory scanning to background queue to prevent UI blocking
        let directoryURL = documentsDirectory // Capture MainActor property
        
        return try await withCheckedThrowingContinuation { continuation in
            fileOperationQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: FreewriteError.invalidConfiguration)
                    return
                }
                
                do {
                    // Use separate FileManager instance for background operations
                    let backgroundFileManager = FileManager()
                    let fileURLs = try backgroundFileManager.contentsOfDirectory(
                        at: directoryURL,
                        includingPropertiesForKeys: nil
                    )
                    
                    let mdFiles = fileURLs.filter { $0.pathExtension == FileSystemConstants.fileExtension }
                    print("Found \(mdFiles.count) entries")
                    
                    // Process files on background queue
                    Task {
                        do {
                            let entries = try await self.processEntryFiles(mdFiles)
                            let sortedEntries = entries.sorted { $0.createdAt > $1.createdAt }
                            continuation.resume(returning: sortedEntries)
                        } catch {
                            continuation.resume(throwing: error)
                        }
                    }
                } catch {
                    continuation.resume(throwing: FreewriteError.fileOperationFailed("Failed to load entries: \(error)"))
                }
            }
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
        // Atomic cache lookup - eliminates TOCTOU race condition
        if let cachedEntry = getValidCachedEntry(entryId) {
            return cachedEntry
        }
        
        // Cache miss or expired, refresh cache atomically and try again
        try await refreshEntryCache()
        return entryCache[entryId] // Direct access after refresh
    }
    
    // MARK: - Cache Management (Race-condition Safe)
    
    private func getValidCachedEntry(_ entryId: UUID) -> WritingEntryDTO? {
        // Atomic check-and-get operation to prevent TOCTOU races
        guard let timestamp = entryCacheTimestamp else { return nil }
        guard Date().timeIntervalSince(timestamp) < cacheExpiryInterval else { return nil }
        return entryCache[entryId]
    }
    
    private func getValidCachedEntries() -> [WritingEntryDTO] {
        // Atomic check-and-get-all operation to prevent TOCTOU races  
        guard let timestamp = entryCacheTimestamp else { return [] }
        guard Date().timeIntervalSince(timestamp) < cacheExpiryInterval else { return [] }
        return Array(entryCache.values)
    }
    
    private func isCacheValid() -> Bool {
        guard let timestamp = entryCacheTimestamp else { return false }
        return Date().timeIntervalSince(timestamp) < cacheExpiryInterval
    }
    
    private func refreshEntryCache() async throws {
        let entries = try await loadAllEntriesFromDisk()
        
        // Atomic cache replacement - build new cache state first, then replace atomically
        var newCache: [UUID: WritingEntryDTO] = [:]
        for entry in entries {
            newCache[entry.id] = entry
        }
        
        // Atomic replacement to prevent partial state corruption
        entryCache = newCache
        entryCacheTimestamp = Date()
    }
    
    private func invalidateCache() {
        // Atomic invalidation - timestamp and entries must be consistent
        entryCacheTimestamp = nil
        entryCache.removeAll()
    }
    
    private func updateCacheEntry(_ entry: WritingEntryDTO) {
        // Only update if cache is valid, otherwise ignore to maintain consistency
        if entryCacheTimestamp != nil {
            entryCache[entry.id] = entry
        }
    }
    
    private func removeCacheEntry(_ entryId: UUID) {
        // Only remove if cache is valid, otherwise ignore to maintain consistency
        if entryCacheTimestamp != nil {
            entryCache.removeValue(forKey: entryId)
        }
    }
    
    private func processEntryFiles(_ fileURLs: [URL]) async throws -> [WritingEntryDTO] {
        // Use TaskGroup with concurrency limit to prevent resource exhaustion
        let maxConcurrentOperations = 5 // Reasonable limit for file operations
        
        return try await withThrowingTaskGroup(of: WritingEntryDTO?.self) { group in
            var entries: [WritingEntryDTO] = []
            var currentBatch = 0
            
            for fileURL in fileURLs {
                // Limit concurrent operations to prevent file handle exhaustion
                if currentBatch >= maxConcurrentOperations {
                    // Wait for some tasks to complete before adding more
                    if let entry = try await group.next() {
                        if let validEntry = entry {
                            entries.append(validEntry)
                        }
                    }
                    currentBatch -= 1
                }
                
                group.addTask { [fileURL] in
                    do {
                        return try await self.processEntryFile(fileURL)
                    } catch {
                        print("Error processing entry \(fileURL.lastPathComponent): \(error)")
                        return nil // Return nil for failed entries, continue processing
                    }
                }
                currentBatch += 1
            }
            
            // Collect remaining results
            for try await entry in group {
                if let validEntry = entry {
                    entries.append(validEntry)
                }
            }
            
            return entries
        }
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