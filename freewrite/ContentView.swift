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
    @State private var progressState = ProgressStateManager()
    @State private var errorManager = ErrorManager()
    @State private var timerCancellable: AnyCancellable?
    @State private var fullscreenCancellables = Set<AnyCancellable>()
    
    // Color scheme passed from parent to avoid @AppStorage threading issues
    let colorScheme: ColorScheme
    let onColorSchemeToggle: () -> Void
    
    // MARK: - Initialization
    
    init(colorScheme: ColorScheme = .light, onColorSchemeToggle: @escaping () -> Void = {}) {
        self.colorScheme = colorScheme
        self.onColorSchemeToggle = onColorSchemeToggle
        
        // Safe service resolution with proper error handling
        do {
            let resolvedTimerService = try DIContainer.shared.resolveSafe(TimerServiceProtocol.self)
            guard let freewriteTimer = resolvedTimerService as? FreewriteTimer else {
                fatalError("TimerService is not FreewriteTimer implementation. Got: \(type(of: resolvedTimerService))")
            }
            self.timerService = freewriteTimer
            self.fileService = try DIContainer.shared.resolveSafe(FileManagementServiceProtocol.self)
            self.aiService = try DIContainer.shared.resolveSafe(AIIntegrationServiceProtocol.self)
        } catch {
            fatalError("Failed to resolve services: \(error). Ensure DIContainer.configure() is called before creating ContentView.")
        }
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
                
                // Progress indicator overlay
                if progressState.isVisible {
                    VStack(spacing: 12) {
                        ProgressView(value: progressState.progress)
                            .frame(width: 200)
                        Text(progressState.loadingMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                    .shadow(radius: 4)
                }
                
                // Error presentation overlay
                if let error = errorManager.currentError {
                    VStack(spacing: 12) {
                        Text(error.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(error.message)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        HStack(spacing: 12) {
                            Button("Dismiss") {
                                errorManager.clearError()
                            }
                            .buttonStyle(.bordered)
                            
                            if error.recoveryAction != nil {
                                Button("Retry") {
                                    errorManager.retryCurrentOperation()
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                    .shadow(radius: 8)
                    .frame(maxWidth: 300)
                }
                
                VStack {
                    Spacer()
                    NavigationBar(
                        typographyState: typographyState,
                        hoverState: hoverState,
                        uiState: uiState,
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
                        onCopyPrompt: { copyPromptToClipboard() },
                        onColorSchemeToggle: onColorSchemeToggle
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
                .onAppear {
                    // Load entries when sidebar first appears
                    Task {
                        await loadAllEntries()
                    }
                }
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
            
            // Setup hover state coordination to prevent pollution
            uiState.notifyHoverStateReset = { [weak hoverState] in
                hoverState?.resetAllHover()
            }
        }
        .onDisappear {
            cleanupTimerSubscription()
            cleanupFullscreenSubscriptions()
            // Reset hover states on view disappear to prevent pollution
            hoverState.resetAllHover()
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
        
        // Store previous state for potential rollback
        let previousText = text
        let processedText = validationResult.correctedText ?? newValue
        
        // Optimistically update UI state
        text = processedText
        
        // Atomic save with rollback capability
        Task {
            do {
                try await saveTextAtomically(processedText, previousState: previousText)
            } catch {
                // Critical: Rollback UI state if save failed to prevent data loss illusion
                await MainActor.run {
                    text = previousText
                    print("CRITICAL: Text save failed, rolled back UI state: \(error)")
                }
            }
        }
    }
    
    private func saveTextAtomically(_ textContent: String, previousState: String) async throws {
        guard let currentEntry = await getCurrentEntry() else {
            throw FreewriteError.entryNotFound
        }
        
        // Attempt atomic save - if this fails, caller will rollback UI state
        try await fileService.saveEntry(currentEntry.id, content: textContent)
    }
    
    // MARK: - Entry Management
    
    private func setupInitialState() async {
        // Start fresh - no need to load previous session for freewriting
        await createNewEntry()
    }
    
    private func saveCurrentText() async {
        do {
            if let currentEntry = await getCurrentEntry() {
                try await fileService.saveEntry(currentEntry.id, content: text)
            }
        } catch {
            // Report auto-save failures to user - critical for data safety awareness
            errorManager.reportError(UserError.fileOperationFailed(
                operation: "auto-save text",
                error: error,
                retry: { Task { await self.saveCurrentText() } }
            ))
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
            // Report entry creation failures - important for user awareness
            errorManager.reportError(UserError.fileOperationFailed(
                operation: "create new entry",
                error: error,
                retry: { Task { await self.createNewEntry() } }
            ))
        }
    }
    
    
    private func loadEntry(_ entry: WritingEntryDTO) async {
        // Reset hover states when switching entries to prevent pollution
        hoverState.resetAllHover()
        
        do {
            selectedEntryId = entry.id
            let content = try await fileService.loadEntry(entry.id)
            text = content
        } catch {
            // Report entry loading errors with retry option
            errorManager.reportError(UserError.fileOperationFailed(
                operation: "load entry",
                error: error,
                retry: { Task { await self.loadEntry(entry) } }
            ))
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
            // Report entry deletion errors - important for user awareness
            errorManager.reportError(UserError.fileOperationFailed(
                operation: "delete entry",
                error: error,
                retry: { Task { await self.deleteEntry(entry) } }
            ))
        }
    }
    
    private func loadAllEntries() async {
        do {
            entries = try await fileService.loadAllEntries()
        } catch {
            print("Failed to load entries: \(error)")
            entries = []
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
                // Report AI integration errors to user
                errorManager.reportError(UserError.aiIntegrationError(error))
            }
        }
    }
    
    private func openClaude() {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        Task {
            do {
                try await aiService.openClaude(with: trimmedText)
            } catch {
                // Report AI integration errors to user
                errorManager.reportError(UserError.aiIntegrationError(error))
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
    // Safe preview configuration with proper lifecycle management
    ContentView(
        colorScheme: .light,
        onColorSchemeToggle: {
            print("Preview: Color scheme toggle - no-op in preview environment")
        }
    )
    .onAppear {
        // Ensure DI container is configured for previews
        DIContainer.shared.configure()
    }
}