import Foundation
@testable import freewrite

@MainActor
final class MockFileManagementService: @unchecked Sendable, FileManagementServiceProtocol {
    private var mockEntries: [UUID: WritingEntryDTO] = [:]
    private var mockContents: [UUID: String] = [:]
    var shouldFailOperations = false
    var operationDelay: TimeInterval = 0
    
    func createNewEntry() async throws -> WritingEntryDTO {
        if shouldFailOperations { throw FreewriteError.fileOperationFailed("Mock failure") }
        if operationDelay > 0 { try await Task.sleep(nanoseconds: UInt64(operationDelay * 1_000_000_000)) }
        
        let entry = WritingEntryDTO(
            id: UUID(),
            filename: "mock-entry-\(Date().timeIntervalSince1970).md",
            displayDate: "Mock Date",
            previewText: "",
            wordCount: 0,
            isWelcomeEntry: false,
            createdAt: Date(),
            modifiedAt: Date()
        )
        mockEntries[entry.id] = entry
        mockContents[entry.id] = FreewriteConstants.headerString
        return entry
    }
    
    func loadEntry(_ entryId: UUID) async throws -> String {
        if shouldFailOperations { throw FreewriteError.fileOperationFailed("Mock load failure") }
        if operationDelay > 0 { try await Task.sleep(nanoseconds: UInt64(operationDelay * 1_000_000_000)) }
        
        guard let content = mockContents[entryId] else { throw FreewriteError.entryNotFound }
        return content
    }
    
    func saveEntry(_ entryId: UUID, content: String) async throws {
        if shouldFailOperations { throw FreewriteError.fileOperationFailed("Mock save failure") }
        if operationDelay > 0 { try await Task.sleep(nanoseconds: UInt64(operationDelay * 1_000_000_000)) }
        
        guard let existingEntry = mockEntries[entryId] else { throw FreewriteError.entryNotFound }
        mockContents[entryId] = content
        
        // Create updated entry with new modification date (immutable struct)
        let updatedEntry = WritingEntryDTO(
            id: existingEntry.id,
            filename: existingEntry.filename,
            displayDate: existingEntry.displayDate,
            previewText: String(content.prefix(30)),
            wordCount: content.split(separator: " ").count,
            isWelcomeEntry: existingEntry.isWelcomeEntry,
            createdAt: existingEntry.createdAt,
            modifiedAt: Date()
        )
        mockEntries[entryId] = updatedEntry
    }
    
    func deleteEntry(_ entryId: UUID) async throws {
        if shouldFailOperations { throw FreewriteError.fileOperationFailed("Mock delete failure") }
        if operationDelay > 0 { try await Task.sleep(nanoseconds: UInt64(operationDelay * 1_000_000_000)) }
        
        guard mockEntries[entryId] != nil else { throw FreewriteError.entryNotFound }
        mockEntries.removeValue(forKey: entryId)
        mockContents.removeValue(forKey: entryId)
    }
    
    func loadAllEntries() async throws -> [WritingEntryDTO] {
        if shouldFailOperations { throw FreewriteError.fileOperationFailed("Mock load all failure") }
        if operationDelay > 0 { try await Task.sleep(nanoseconds: UInt64(operationDelay * 1_000_000_000)) }
        
        return Array(mockEntries.values).sorted { $0.createdAt > $1.createdAt }
    }
    
    func updatePreviewText(_ entryId: UUID) async throws {
        if shouldFailOperations { throw FreewriteError.fileOperationFailed("Mock update failure") }
        // Mock implementation - no actual preview update needed
    }
    
    func getDocumentsDirectory() -> URL {
        return URL(fileURLWithPath: "/tmp/freewrite-mock")
    }
    
    func entryExists(_ entryId: UUID) async -> Bool {
        return mockEntries[entryId] != nil
    }
}