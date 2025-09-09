import Testing
import Foundation
@testable import Freewrite

/// Comprehensive tests for FileManagementService
@MainActor
struct FileManagementServiceTests {
    
    // MARK: - Setup & Teardown
    
    private func createService() -> FileManagementService {
        return FileManagementService()
    }
    
    private func createTestDirectory() throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("FreewriteTests")
            .appendingPathComponent(UUID().uuidString)
        
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        return tempDir
    }
    
    private func cleanupTestDirectory(_ directory: URL) {
        try? FileManager.default.removeItem(at: directory)
    }
    
    // MARK: - Directory Tests
    
    @Test("Documents directory is created and accessible")
    func testDocumentsDirectory() async throws {
        let service = createService()
        
        let documentsDir = service.getDocumentsDirectory()
        
        #expect(FileManager.default.fileExists(atPath: documentsDir.path))
        #expect(documentsDir.pathComponents.contains("Freewrite"))
    }
    
    // MARK: - Entry Creation Tests
    
    @Test("Create new entry generates valid DTO")
    func testCreateNewEntry() async throws {
        let service = createService()
        
        let entry = try await service.createNewEntry()
        
        #expect(entry.id != UUID.zero) // Valid UUID
        #expect(!entry.filename.isEmpty)
        #expect(entry.filename.hasSuffix(".md"))
        #expect(entry.createdAt <= Date()) // Created in the past or now
    }
    
    @Test("Multiple entries have unique IDs and filenames")
    func testMultipleEntryCreation() async throws {
        let service = createService()
        
        let entry1 = try await service.createNewEntry()
        let entry2 = try await service.createNewEntry()
        
        #expect(entry1.id != entry2.id)
        #expect(entry1.filename != entry2.filename)
    }
    
    // MARK: - Save & Load Tests
    
    @Test("Save and load entry content")
    func testSaveLoadEntry() async throws {
        let service = createService()
        let testContent = "Test content for entry\nWith multiple lines"
        
        let entry = try await service.createNewEntry()
        
        // Save content
        try await service.saveEntry(entry.id, content: testContent)
        
        // Load and verify
        let loadedContent = try await service.loadEntry(entry.id)
        #expect(loadedContent == testContent)
    }
    
    @Test("Save entry overwrites existing content")
    func testSaveEntryOverwrite() async throws {
        let service = createService()
        let entry = try await service.createNewEntry()
        
        // Save initial content
        try await service.saveEntry(entry.id, content: "Initial content")
        
        // Overwrite with new content
        let newContent = "Updated content"
        try await service.saveEntry(entry.id, content: newContent)
        
        // Verify overwrite
        let loadedContent = try await service.loadEntry(entry.id)
        #expect(loadedContent == newContent)
    }
    
    // MARK: - Delete Tests
    
    @Test("Delete entry removes file")
    func testDeleteEntry() async throws {
        let service = createService()
        let entry = try await service.createNewEntry()
        
        // Save some content first
        try await service.saveEntry(entry.id, content: "Content to be deleted")
        
        // Verify it exists
        #expect(try await service.entryExists(entry.id) == true)
        
        // Delete entry
        try await service.deleteEntry(entry.id)
        
        // Verify deletion
        #expect(try await service.entryExists(entry.id) == false)
    }
    
    @Test("Delete non-existent entry throws error")
    func testDeleteNonExistentEntry() async throws {
        let service = createService()
        let fakeId = UUID()
        
        await #expect(throws: FreewriteError.self) {
            try await service.deleteEntry(fakeId)
        }
    }
    
    // MARK: - Load All Entries Tests
    
    @Test("Load all entries returns empty array initially")
    func testLoadAllEntriesEmpty() async throws {
        let service = createService()
        
        let entries = try await service.loadAllEntries()
        
        #expect(entries.isEmpty)
    }
    
    @Test("Load all entries returns created entries")
    func testLoadAllEntriesWithContent() async throws {
        let service = createService()
        
        // Create multiple entries
        let entry1 = try await service.createNewEntry()
        let entry2 = try await service.createNewEntry()
        
        // Save content
        try await service.saveEntry(entry1.id, content: "Entry 1 content")
        try await service.saveEntry(entry2.id, content: "Entry 2 content")
        
        // Load all
        let entries = try await service.loadAllEntries()
        
        #expect(entries.count == 2)
        #expect(entries.contains { $0.id == entry1.id })
        #expect(entries.contains { $0.id == entry2.id })
    }
    
    @Test("Entries are sorted by creation date (newest first)")
    func testEntriesSortedByDate() async throws {
        let service = createService()
        
        let entry1 = try await service.createNewEntry()
        // Small delay to ensure different timestamps
        try await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds
        let entry2 = try await service.createNewEntry()
        
        let entries = try await service.loadAllEntries()
        
        #expect(entries.count == 2)
        #expect(entries[0].id == entry2.id) // Newest first
        #expect(entries[1].id == entry1.id) // Older second
    }
    
    // MARK: - Entry Existence Tests
    
    @Test("Entry exists returns true for valid entry")
    func testEntryExists() async throws {
        let service = createService()
        let entry = try await service.createNewEntry()
        
        try await service.saveEntry(entry.id, content: "Test content")
        
        #expect(try await service.entryExists(entry.id) == true)
    }
    
    @Test("Entry exists returns false for non-existent entry")
    func testEntryNotExists() async throws {
        let service = createService()
        let fakeId = UUID()
        
        #expect(try await service.entryExists(fakeId) == false)
    }
    
    // MARK: - Error Handling Tests
    
    @Test("Load non-existent entry throws appropriate error")
    func testLoadNonExistentEntry() async throws {
        let service = createService()
        let fakeId = UUID()
        
        await #expect(throws: FreewriteError.self) {
            _ = try await service.loadEntry(fakeId)
        }
    }
    
    @Test("Update preview text handles missing files gracefully")
    func testUpdatePreviewTextMissingFile() async throws {
        let service = createService()
        let fakeId = UUID()
        
        // Should not throw, but handle gracefully
        await #expect(throws: FreewriteError.self) {
            try await service.updatePreviewText(fakeId)
        }
    }
    
    // MARK: - Content Validation Tests
    
    @Test("Save entry handles empty content")
    func testSaveEmptyContent() async throws {
        let service = createService()
        let entry = try await service.createNewEntry()
        
        try await service.saveEntry(entry.id, content: "")
        
        let loadedContent = try await service.loadEntry(entry.id)
        #expect(loadedContent == "")
    }
    
    @Test("Save entry handles large content")
    func testSaveLargeContent() async throws {
        let service = createService()
        let entry = try await service.createNewEntry()
        let largeContent = String(repeating: "Large content test. ", count: 1000)
        
        try await service.saveEntry(entry.id, content: largeContent)
        
        let loadedContent = try await service.loadEntry(entry.id)
        #expect(loadedContent == largeContent)
    }
    
    @Test("Save entry handles special characters")
    func testSaveSpecialCharacters() async throws {
        let service = createService()
        let entry = try await service.createNewEntry()
        let specialContent = "Content with émojis 🚀, newlines\n\nand special chars: åß∂ƒ©"
        
        try await service.saveEntry(entry.id, content: specialContent)
        
        let loadedContent = try await service.loadEntry(entry.id)
        #expect(loadedContent == specialContent)
    }
    
    // MARK: - Concurrent Access Tests
    
    @Test("Concurrent entry creation produces unique entries")
    func testConcurrentEntryCreation() async throws {
        let service = createService()
        
        // Create entries concurrently
        async let entry1 = service.createNewEntry()
        async let entry2 = service.createNewEntry()
        async let entry3 = service.createNewEntry()
        
        let entries = try await [entry1, entry2, entry3]
        
        #expect(entries.count == 3)
        #expect(Set(entries.map(\.id)).count == 3) // All unique IDs
        #expect(Set(entries.map(\.filename)).count == 3) // All unique filenames
    }
}