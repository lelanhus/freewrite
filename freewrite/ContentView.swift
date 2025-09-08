import SwiftUI
import Combine

struct ContentView: View {
    // Services (initialized safely)
    private let timerService: FreewriteTimer
    private let fileService: FileManagementServiceProtocol
    private let aiService: AIIntegrationServiceProtocol
    
    // Entry Management State
    @State private var entries: [WritingEntryDTO] = []
    @State private var selectedEntryId: UUID? = nil
    @State private var text: String = FreewriteConstants.headerString
    
    // State Managers
    @State private var uiState = UIStateManager()
    @State private var hoverState = HoverStateManager()
    @State private var typographyState = TypographyStateManager()
    @State private var timerCancellable: AnyCancellable?
    @State private var fullscreenCancellables = Set<AnyCancellable>()
    
    @AppStorage("colorScheme") private var colorSchemeString: String = "light"
    
    // MARK: - Initialization
    
    init() {
        // Safe service resolution with proper error handling
        do {
            self.timerService = try DIContainer.shared.resolveSafe(TimerServiceProtocol.self) as! FreewriteTimer
            self.fileService = try DIContainer.shared.resolveSafe(FileManagementServiceProtocol.self)
            self.aiService = try DIContainer.shared.resolveSafe(AIIntegrationServiceProtocol.self)
        } catch {
            fatalError("Failed to resolve services: \(error). Ensure DIContainer.configure() is called before creating ContentView.")
        }
    }
    
    // Computed properties
    private var colorScheme: ColorScheme {
        return colorSchemeString == "dark" ? .dark : .light
    }
    
    
    var body: some View {
        let navHeight: CGFloat = 68
        
        HStack(spacing: 0) {
            // Main content - matching original structure exactly
            ZStack {
                FreewriteColors.contentBackground
                    .ignoresSafeArea()
                
                TextEditor(text: Binding(
                    get: { text },
                    set: { newValue in
                        processTextChange(newValue)
                    }
                ))
                .background(FreewriteColors.contentBackground)
                .font(.custom(typographyState.selectedFont, size: typographyState.fontSize))
                .foregroundColor(FreewriteColors.writingText)
                .scrollContentBackground(.hidden)
                .scrollIndicators(.never)
                .lineSpacing(typographyState.lineHeight)
                .frame(maxWidth: 650)
                .id("\(typographyState.selectedFont)-\(typographyState.fontSize)-\(colorScheme)")
                .padding(.bottom, uiState.bottomNavOpacity > 0 ? navHeight : 0)
                .ignoresSafeArea()
                .onAppear {
                    uiState.placeholderText = PlaceholderConstants.random()
                }
                .overlay(
                    ZStack(alignment: .topLeading) {
                        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text(uiState.placeholderText)
                                .font(.custom(typographyState.selectedFont, size: typographyState.fontSize))
                                .foregroundColor(FreewriteColors.placeholderText)
                                .allowsHitTesting(false)
                                .offset(x: 5, y: typographyState.placeholderOffset)
                        }
                    }, alignment: .topLeading
                )
                .background(GeometryReader { geometry in
                    Color.clear.onAppear {
                        uiState.viewHeight = geometry.size.height
                    }
                })
                .padding(.bottom, uiState.viewHeight > 0 ? uiState.viewHeight / 4 : 0)
                
                VStack {
                    Spacer()
                    NavigationBar(
                        typographyState: typographyState,
                        hoverState: hoverState,
                        uiState: uiState,
                        colorSchemeString: $colorSchemeString,
                        text: $text,
                        timerService: timerService,
                        colorScheme: colorScheme,
                        canUseChat: canUseChat,
                        onNewEntry: {
                            Task {
                                await createNewEntry()
                            }
                        },
                        onOpenChatGPT: { openChatGPT() },
                        onOpenClaude: { openClaude() },
                        onCopyPrompt: { copyPromptToClipboard() }
                    )
                    .opacity(uiState.bottomNavOpacity)
                    .onHover { hovering in
                        hoverState.isHoveringBottomNav = hovering
                        if hovering {
                            withAnimation(.easeOut(duration: 0.2)) {
                                uiState.bottomNavOpacity = 1.0
                            }
                        } else if timerService.isRunning {
                            withAnimation(.easeIn(duration: 1.0)) {
                                uiState.bottomNavOpacity = 0.0
                            }
                        }
                    }
                }
            }
            
            // Right sidebar (hidden by default)
            if uiState.showingSidebar {
                Divider()
                
                Sidebar(
                    entries: $entries,
                    selectedEntryId: $selectedEntryId,
                    hoveredEntryId: $hoverState.hoveredEntryId,
                    fileService: fileService,
                    onLoadEntry: { entry in
                        await loadEntry(entry)
                    },
                    onDeleteEntry: { entry in
                        await deleteEntry(entry)
                    },
                    onSaveCurrentText: {
                        await saveCurrentText()
                    }
                )
            }
        }
        .frame(minWidth: 1100, minHeight: 600)
        .animation(.easeInOut(duration: 0.2), value: uiState.showingSidebar)
        .preferredColorScheme(colorScheme)
        .background(FreewriteColors.contentBackground) // Ensure entire window uses system background
        .onAppear {
            Task {
                await setupInitialState()
            }
            uiState.placeholderText = PlaceholderConstants.random()
            setupTimerSubscription()
            setupFullscreenSubscriptions()
        }
        .onDisappear {
            cleanupTimerSubscription()
            cleanupFullscreenSubscriptions()
        }
    }
    
    // MARK: - Computed Properties
    
    var canUseChat: Bool {
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleanText.count >= FreewriteConstants.minimumTextLength
    }
    
    // MARK: - Text Management
    
    private func processTextChange(_ newValue: String) {
        let validationResult = TextConstraintValidator.validateSimpleTextChange(
            newText: newValue,
            currentText: text
        )
        
        if validationResult.shouldProvideFeedback {
            TextConstraintValidator.provideFeedback()
            return
        }
        
        text = validationResult.correctedText ?? newValue
        
        // Auto-save with file service
        Task {
            await saveCurrentText()
        }
    }
    
    // MARK: - Entry Management
    
    private func setupInitialState() async {
        await loadInitialEntry()
    }
    
    private func saveCurrentText() async {
        do {
            if let currentEntry = await getCurrentEntry() {
                try await fileService.saveEntry(currentEntry.id, content: text)
            }
        } catch {
            print("Auto-save failed: \(error)")
        }
    }
    
    private func createNewEntry() async {
        do {
            let newEntry = try await fileService.createNewEntry()
            entries.insert(newEntry, at: 0) // Add to beginning of list
            selectedEntryId = newEntry.id
            text = FreewriteConstants.headerString
            
            // Save the initial empty entry
            try await fileService.saveEntry(newEntry.id, content: text)
        } catch {
            print("Failed to create new entry: \(error)")
        }
    }
    
    private func loadInitialEntry() async {
        do {
            entries = try await fileService.loadAllEntries()
            
            if let mostRecent = entries.first {
                selectedEntryId = mostRecent.id
                let content = try await fileService.loadEntry(mostRecent.id)
                text = content
            } else {
                // No entries exist, create first entry
                await createNewEntry()
            }
        } catch {
            print("Failed to load initial entry: \(error)")
            await createNewEntry()
        }
    }
    
    private func loadEntry(_ entry: WritingEntryDTO) async {
        do {
            selectedEntryId = entry.id
            let content = try await fileService.loadEntry(entry.id)
            text = content
        } catch {
            print("Failed to load entry: \(error)")
        }
    }
    
    private func deleteEntry(_ entry: WritingEntryDTO) async {
        do {
            try await fileService.deleteEntry(entry.id)
            entries.removeAll { $0.id == entry.id }
            
            // If the deleted entry was selected, select the first entry or create a new one
            if selectedEntryId == entry.id {
                if let firstEntry = entries.first {
                    await loadEntry(firstEntry)
                } else {
                    await createNewEntry()
                }
            }
        } catch {
            print("Failed to delete entry: \(error)")
        }
    }
    
    private func getCurrentEntry() async -> WritingEntryDTO? {
        do {
            let entries = try await fileService.loadAllEntries()
            return entries.first // Most recent entry
        } catch {
            return nil
        }
    }
    
    // MARK: - AI Integration
    
    private func openChatGPT() {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        Task {
            do {
                try await aiService.openChatGPT(with: trimmedText)
            } catch {
                print("Failed to open ChatGPT: \(error)")
            }
        }
    }
    
    private func openClaude() {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        Task {
            do {
                try await aiService.openClaude(with: trimmedText)
            } catch {
                print("Failed to open Claude: \(error)")
            }
        }
    }
    
    private func copyPromptToClipboard() {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        aiService.copyPromptToClipboard(with: trimmedText)
    }
    
    // MARK: - Timer Subscription Management
    
    private func setupTimerSubscription() {
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                // Handle timer updates - make bottom nav disappear when timer is running
                if timerService.isRunning && !hoverState.isHoveringBottomNav {
                    withAnimation(.easeIn(duration: 1.0)) {
                        uiState.bottomNavOpacity = 0.0
                    }
                } else if !timerService.isRunning {
                    withAnimation(.easeOut(duration: 0.2)) {
                        uiState.bottomNavOpacity = 1.0
                    }
                }
            }
    }
    
    private func cleanupTimerSubscription() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }
    
    // MARK: - Fullscreen Subscription Management
    
    private func setupFullscreenSubscriptions() {
        // Setup fullscreen enter notification
        NotificationCenter.default
            .publisher(for: NSWindow.willEnterFullScreenNotification)
            .sink { _ in
                uiState.isFullscreen = true
            }
            .store(in: &fullscreenCancellables)
        
        // Setup fullscreen exit notification  
        NotificationCenter.default
            .publisher(for: NSWindow.willExitFullScreenNotification)
            .sink { _ in
                uiState.isFullscreen = false
            }
            .store(in: &fullscreenCancellables)
    }
    
    private func cleanupFullscreenSubscriptions() {
        fullscreenCancellables.removeAll()
    }
}


#Preview {
    ContentView()
}