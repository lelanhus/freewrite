import Foundation

/// Service responsible for managing writing entry files and data persistence
@MainActor
protocol FileManagementServiceProtocol: Sendable {
    /// Creates a new writing entry
    /// - Returns: The newly created entry DTO
    func createNewEntry() async throws -> WritingEntryDTO
    
    /// Loads the content of a specific entry
    /// - Parameter entryId: The unique identifier of the entry
    /// - Returns: The text content of the entry
    func loadEntry(_ entryId: UUID) async throws -> String
    
    /// Saves content to a specific entry
    /// - Parameters:
    ///   - entryId: The unique identifier of the entry
    ///   - content: The text content to save
    func saveEntry(_ entryId: UUID, content: String) async throws
    
    /// Deletes an entry from the file system
    /// - Parameter entryId: The unique identifier of the entry to delete
    func deleteEntry(_ entryId: UUID) async throws
    
    /// Loads all available entries
    /// - Returns: Array of entry DTOs sorted by creation date (newest first)
    func loadAllEntries() async throws -> [WritingEntryDTO]
    
    /// Updates the preview text for an entry based on its content
    /// - Parameter entryId: The unique identifier of the entry
    func updatePreviewText(_ entryId: UUID) async throws
    
    /// Gets the documents directory URL
    /// - Returns: URL of the Freewrite documents directory
    func getDocumentsDirectory() -> URL
    
    /// Checks if an entry exists
    /// - Parameter entryId: The unique identifier of the entry
    /// - Returns: Boolean indicating if the entry exists
    func entryExists(_ entryId: UUID) async -> Bool
}