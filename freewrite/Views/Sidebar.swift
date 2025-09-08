import SwiftUI

struct Sidebar: View {
    @Binding var entries: [WritingEntryDTO]
    @Binding var selectedEntryId: UUID?
    @Binding var hoveredEntryId: UUID?
    
    let fileService: FileManagementServiceProtocol
    let onLoadEntry: (WritingEntryDTO) async -> Void
    let onDeleteEntry: (WritingEntryDTO) async -> Void
    let onSaveCurrentText: () async -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button(action: {
                NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: fileService.getDocumentsDirectory().path)
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Text("History")
                                .font(.system(size: 13))
                                .foregroundColor(.primary)
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 10))
                                .foregroundColor(.primary)
                        }
                        Text(fileService.getDocumentsDirectory().path)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider()
            
            // Entries List
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(entries) { entry in
                        EntryRow(
                            entry: entry,
                            selectedEntryId: selectedEntryId,
                            hoveredEntryId: $hoveredEntryId,
                            onSelectEntry: { selectedEntry in
                                if selectedEntryId != selectedEntry.id {
                                    Task {
                                        await onSaveCurrentText() // Save current before switching
                                        await onLoadEntry(selectedEntry)
                                    }
                                }
                            },
                            onDeleteEntry: { entryToDelete in
                                Task {
                                    await onDeleteEntry(entryToDelete)
                                }
                            }
                        )
                        
                        if entry.id != entries.last?.id {
                            Divider()
                        }
                    }
                }
            }
            .scrollIndicators(.never)
        }
        .frame(width: 200)
        .background(FreewriteColors.sidebarBackground)
    }
}

struct EntryRow: View {
    let entry: WritingEntryDTO
    let selectedEntryId: UUID?
    @Binding var hoveredEntryId: UUID?
    let onSelectEntry: (WritingEntryDTO) -> Void
    let onDeleteEntry: (WritingEntryDTO) -> Void
    
    var body: some View {
        Button(action: {
            onSelectEntry(entry)
        }) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(entry.filename) // Using filename as preview for now
                            .font(.system(size: 13))
                            .lineLimit(1)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        // Export/Trash icons that appear on hover
                        if hoveredEntryId == entry.id {
                            HStack(spacing: 8) {
                                Button(action: {
                                    onDeleteEntry(entry)
                                }) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 11))
                                        .foregroundColor(FreewriteColors.deleteAction)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    Text(entry.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(FreewriteColors.entryBackground(
                        isSelected: entry.id == selectedEntryId, 
                        isHovered: entry.id == hoveredEntryId
                    ))
            )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                hoveredEntryId = hovering ? entry.id : nil
            }
        }
    }
}