import SwiftUI

struct ContentView: View {
    // Direct service dependencies - Model-View architecture
    private let fileService = DIContainer.shared.resolve(FileManagementServiceProtocol.self)
    private let timerService = DIContainer.shared.resolve(TimerServiceProtocol.self) as! FreewriteTimer
    
    // UI State matching original
    @State private var text: String = FreewriteConstants.headerString
    @State private var selectedFont: String = "Lato-Regular" 
    @State private var fontSize: CGFloat = 18
    @State private var isHoveringTimer = false
    @State private var bottomNavOpacity: Double = 1.0
    @State private var isHoveringBottomNav = false
    @State private var placeholderText: String = ""
    @State private var colorScheme: ColorScheme = .light
    @State private var showingSidebar = false
    @State private var isHoveringThemeToggle = false
    @State private var isHoveringClock = false
    @State private var hoveredFont: String? = nil
    @State private var isHoveringSize = false
    @State private var isHoveringFonts = false
    @State private var isHoveringNewEntry = false
    @State private var isHoveringChat = false
    @State private var viewHeight: CGFloat = 0
    @State private var showingChatMenu = false
    @State private var didCopyPrompt: Bool = false
    @State private var entries: [WritingEntryDTO] = []
    @State private var selectedEntryId: UUID? = nil
    @State private var hoveredEntryId: UUID? = nil
    @State private var isFullscreen = false
    @State private var isHoveringFullscreen = false
    
    let placeholderOptions = [
        "\n\nBegin writing",
        "\n\nPick a thought and go", 
        "\n\nStart typing",
        "\n\nWhat's on your mind",
        "\n\nJust start",
        "\n\nType your first thought",
        "\n\nStart with one sentence",
        "\n\nJust say it"
    ]
    
    // Computed properties matching original
    var lineHeight: CGFloat {
        let font = NSFont(name: selectedFont, size: fontSize) ?? .systemFont(ofSize: fontSize)
        let defaultLineHeight = getLineHeight(font: font)
        return (fontSize * 1.5) - defaultLineHeight
    }
    
    var placeholderOffset: CGFloat {
        return fontSize / 2
    }
    
    var fontSizeButtonTitle: String {
        return "\(Int(fontSize))px"
    }
    
    var timerButtonTitle: String {
        let minutes = timerService.timeRemaining / 60
        let seconds = timerService.timeRemaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var body: some View {
        let buttonBackground = colorScheme == .light ? Color.white : Color.black
        let navHeight: CGFloat = 68
        let textColor = colorScheme == .light ? Color.gray : Color.gray.opacity(0.8)
        let textHoverColor = colorScheme == .light ? Color.black : Color.white
        
        HStack(spacing: 0) {
            // Main content - matching original structure exactly
            ZStack {
                Color(colorScheme == .light ? .white : .black)
                    .ignoresSafeArea()
                
                TextEditor(text: Binding(
                    get: { text },
                    set: { newValue in
                        // Apply constraints inline - prevent backspacing, deletions
                        if newValue.count < text.count {
                            NSSound.beep()
                            return
                        }
                        
                        // Ensure the text always starts with two newlines
                        if !newValue.hasPrefix("\n\n") {
                            text = "\n\n" + newValue.trimmingCharacters(in: .newlines)
                        } else {
                            text = newValue
                        }
                        
                        // Auto-save with file service
                        Task {
                            await saveCurrentText()
                        }
                    }
                ))
                .background(Color(colorScheme == .light ? .white : .black))
                .font(.custom(selectedFont, size: fontSize))
                .foregroundColor(colorScheme == .light ? Color(red: 0.20, green: 0.20, blue: 0.20) : Color(red: 0.9, green: 0.9, blue: 0.9))
                .scrollContentBackground(.hidden)
                .scrollIndicators(.never)
                .lineSpacing(lineHeight)
                .frame(maxWidth: 650)
                .id("\(selectedFont)-\(fontSize)-\(colorScheme)")
                .padding(.bottom, bottomNavOpacity > 0 ? navHeight : 0)
                .ignoresSafeArea()
                .colorScheme(colorScheme)
                .onAppear {
                    placeholderText = placeholderOptions.randomElement() ?? "\n\nBegin writing"
                }
                .overlay(
                    ZStack(alignment: .topLeading) {
                        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text(placeholderText)
                                .font(.custom(selectedFont, size: fontSize))
                                .foregroundColor(colorScheme == .light ? .gray.opacity(0.5) : .gray.opacity(0.6))
                                .allowsHitTesting(false)
                                .offset(x: 5, y: placeholderOffset)
                        }
                    }, alignment: .topLeading
                )
                .background(GeometryReader { geometry in
                    Color.clear.onAppear {
                        viewHeight = geometry.size.height
                    }
                })
                .padding(.bottom, viewHeight > 0 ? viewHeight / 4 : 0)
                
                VStack {
                    Spacer()
                    HStack {
                        // Font buttons (left side) - matching original exactly
                        HStack(spacing: 8) {
                            Button(fontSizeButtonTitle) {
                                let fontSizes: [CGFloat] = [16, 18, 20, 22, 24, 26]
                                if let currentIndex = fontSizes.firstIndex(of: fontSize) {
                                    let nextIndex = (currentIndex + 1) % fontSizes.count
                                    fontSize = fontSizes[nextIndex]
                                }
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(isHoveringSize ? textHoverColor : textColor)
                            .onHover { hovering in
                                isHoveringSize = hovering
                                isHoveringBottomNav = hovering
                                if hovering {
                                    NSCursor.pointingHand.push()
                                } else {
                                    NSCursor.pop()
                                }
                            }
                            .onAppear {
                                // Add scroll wheel event monitoring for font size adjustment
                                NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { event in
                                    if isHoveringSize {
                                        let fontSizes: [CGFloat] = [16, 18, 20, 22, 24, 26]
                                        let direction = event.deltaY > 0 ? -1 : 1 // Scroll up decreases, scroll down increases
                                        
                                        if let currentIndex = fontSizes.firstIndex(of: fontSize) {
                                            let newIndex = max(0, min(fontSizes.count - 1, currentIndex + direction))
                                            fontSize = fontSizes[newIndex]
                                            NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
                                        }
                                    }
                                    return event
                                }
                            }
                            
                            Text("•").foregroundColor(.gray)
                            
                            Button("Lato") {
                                selectedFont = "Lato-Regular"
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(hoveredFont == "Lato" ? textHoverColor : textColor)
                            .onHover { hovering in
                                hoveredFont = hovering ? "Lato" : nil
                                isHoveringBottomNav = hovering
                                if hovering {
                                    NSCursor.pointingHand.push()
                                } else {
                                    NSCursor.pop()
                                }
                            }
                            
                            Text("•").foregroundColor(.gray)
                            
                            Button("Arial") {
                                selectedFont = "Arial"
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(hoveredFont == "Arial" ? textHoverColor : textColor)
                            .onHover { hovering in
                                hoveredFont = hovering ? "Arial" : nil
                                isHoveringBottomNav = hovering
                                if hovering {
                                    NSCursor.pointingHand.push()
                                } else {
                                    NSCursor.pop()
                                }
                            }
                            
                            Text("•").foregroundColor(.gray)
                            
                            Button("System") {
                                selectedFont = ".AppleSystemUIFont"
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(hoveredFont == "System" ? textHoverColor : textColor)
                            .onHover { hovering in
                                hoveredFont = hovering ? "System" : nil
                                isHoveringBottomNav = hovering
                                if hovering {
                                    NSCursor.pointingHand.push()
                                } else {
                                    NSCursor.pop()
                                }
                            }
                            
                            Text("•").foregroundColor(.gray)
                            
                            Button("Serif") {
                                selectedFont = "Times New Roman"
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(hoveredFont == "Serif" ? textHoverColor : textColor)
                            .onHover { hovering in
                                hoveredFont = hovering ? "Serif" : nil
                                isHoveringBottomNav = hovering
                                if hovering {
                                    NSCursor.pointingHand.push()
                                } else {
                                    NSCursor.pop()
                                }
                            }
                            
                            Text("•").foregroundColor(.gray)
                            
                            Button("Random") {
                                if let randomFont = NSFontManager.shared.availableFontFamilies.randomElement() {
                                    selectedFont = randomFont
                                }
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(hoveredFont == "Random" ? textHoverColor : textColor)
                            .onHover { hovering in
                                hoveredFont = hovering ? "Random" : nil
                                isHoveringBottomNav = hovering
                                if hovering {
                                    NSCursor.pointingHand.push()
                                } else {
                                    NSCursor.pop()
                                }
                            }
                        }
                        .padding(8)
                        .cornerRadius(6)
                        .onHover { hovering in
                            isHoveringBottomNav = hovering
                        }
                        
                        Spacer()
                        
                        // Utility buttons (right side) - matching original exactly
                        HStack(spacing: 8) {
                            Button(timerButtonTitle) {
                                // Implement double-click to reset like original
                                if timerService.isRunning {
                                    timerService.pause()
                                } else {
                                    timerService.start()
                                }
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(isHoveringTimer ? textHoverColor : textColor)
                            .onHover { hovering in
                                isHoveringTimer = hovering
                                isHoveringBottomNav = hovering
                                if hovering {
                                    NSCursor.pointingHand.push()
                                } else {
                                    NSCursor.pop()
                                }
                            }
                            .onAppear {
                                // Add scroll wheel event monitoring for timer adjustment
                                NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { event in
                                    if isHoveringTimer {
                                        let scrollBuffer = event.deltaY * 0.25
                                        
                                        if abs(scrollBuffer) >= 0.1 {
                                            let currentMinutes = timerService.timeRemaining / 60
                                            NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
                                            let direction = -scrollBuffer > 0 ? 5 : -5
                                            let newMinutes = currentMinutes + direction
                                            let roundedMinutes = (newMinutes / 5) * 5
                                            let newTime = roundedMinutes * 60
                                            timerService.setTime(min(max(newTime, 0), 2700)) // 0 to 45 minutes
                                        }
                                    }
                                    return event
                                }
                            }
                            
                            Text("•").foregroundColor(.gray)
                            
                            if canUseChat {
                                Button("Chat") {
                                    showingChatMenu = true
                                    didCopyPrompt = false
                                }
                                .buttonStyle(.plain)
                                .foregroundColor(isHoveringChat ? textHoverColor : textColor)
                                .onHover { hovering in
                                    isHoveringChat = hovering
                                    isHoveringBottomNav = hovering
                                    if hovering {
                                        NSCursor.pointingHand.push()
                                    } else {
                                        NSCursor.pop()
                                    }
                                }
                                .popover(isPresented: $showingChatMenu, attachmentAnchor: .point(UnitPoint(x: 0.5, y: 0)), arrowEdge: .top) {
                                    VStack(spacing: 0) {
                                        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
                                        
                                        if text.count < 350 {
                                            Text("Please free write for at minimum 5 minutes first. Then click this. Trust.")
                                                .font(.system(size: 14))
                                                .foregroundColor(.primary)
                                                .frame(width: 250)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 8)
                                        } else {
                                            Button(action: {
                                                showingChatMenu = false
                                                openChatGPT()
                                            }) {
                                                Text("ChatGPT")
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 8)
                                            }
                                            .buttonStyle(.plain)
                                            .foregroundColor(.primary)
                                            
                                            Divider()
                                            
                                            Button(action: {
                                                showingChatMenu = false
                                                openClaude()
                                            }) {
                                                Text("Claude")
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 8)
                                            }
                                            .buttonStyle(.plain)
                                            .foregroundColor(.primary)
                                            
                                            Divider()
                                            
                                            Button(action: {
                                                copyPromptToClipboard()
                                                didCopyPrompt = true
                                            }) {
                                                Text(didCopyPrompt ? "Copied!" : "Copy Prompt")
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 8)
                                            }
                                            .buttonStyle(.plain)
                                            .foregroundColor(.primary)
                                        }
                                    }
                                    .frame(minWidth: 120, maxWidth: 250)
                                    .background(Color(NSColor.controlBackgroundColor))
                                    .cornerRadius(8)
                                    .shadow(color: Color.black.opacity(0.1), radius: 4, y: 2)
                                    .onChange(of: showingChatMenu) { newValue in
                                        if !newValue {
                                            didCopyPrompt = false
                                        }
                                    }
                                }
                                
                                Text("•").foregroundColor(.gray)
                            }
                            
                            Button(action: {
                                colorScheme = colorScheme == .light ? .dark : .light
                            }) {
                                Image(systemName: colorScheme == .light ? "moon.fill" : "sun.max.fill")
                                    .foregroundColor(isHoveringThemeToggle ? textHoverColor : textColor)
                            }
                            .buttonStyle(.plain)
                            .onHover { hovering in
                                isHoveringThemeToggle = hovering
                                isHoveringBottomNav = hovering
                                if hovering {
                                    NSCursor.pointingHand.push()
                                } else {
                                    NSCursor.pop()
                                }
                            }

                            Text("•").foregroundColor(.gray)
                            
                            Button(isFullscreen ? "Minimize" : "Fullscreen") {
                                if let window = NSApplication.shared.windows.first {
                                    window.toggleFullScreen(nil)
                                }
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(isHoveringFullscreen ? textHoverColor : textColor)
                            .onHover { hovering in
                                isHoveringFullscreen = hovering
                                isHoveringBottomNav = hovering
                                if hovering {
                                    NSCursor.pointingHand.push()
                                } else {
                                    NSCursor.pop()
                                }
                            }

                            Text("•").foregroundColor(.gray)
                            
                            Button("New Entry") {
                                Task {
                                    await createNewEntry()
                                }
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(isHoveringNewEntry ? textHoverColor : textColor)
                            .onHover { hovering in
                                isHoveringNewEntry = hovering
                                isHoveringBottomNav = hovering
                                if hovering {
                                    NSCursor.pointingHand.push()
                                } else {
                                    NSCursor.pop()
                                }
                            }
                            
                            Text("•").foregroundColor(.gray)
                            
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showingSidebar.toggle()
                                }
                            }) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .foregroundColor(isHoveringClock ? textHoverColor : textColor)
                            }
                            .buttonStyle(.plain)
                            .onHover { hovering in
                                isHoveringClock = hovering
                                isHoveringBottomNav = hovering
                                if hovering {
                                    NSCursor.pointingHand.push()
                                } else {
                                    NSCursor.pop()
                                }
                            }
                        }
                        .padding(8)
                        .cornerRadius(6)
                        .onHover { hovering in
                            isHoveringBottomNav = hovering
                        }
                    }
                    .padding()
                    .background(Color(colorScheme == .light ? .white : .black))
                    .opacity(bottomNavOpacity)
                    .onHover { hovering in
                        isHoveringBottomNav = hovering
                        if hovering {
                            withAnimation(.easeOut(duration: 0.2)) {
                                bottomNavOpacity = 1.0
                            }
                        } else if timerService.isRunning {
                            withAnimation(.easeIn(duration: 1.0)) {
                                bottomNavOpacity = 0.0
                            }
                        }
                    }
                }
            }
            
            // Right sidebar (hidden by default)
            if showingSidebar {
                Divider()
                
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
                                Button(action: {
                                    if selectedEntryId != entry.id {
                                        Task {
                                            await saveCurrentText() // Save current before switching
                                            await loadEntry(entry: entry)
                                        }
                                    }
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
                                                            Task {
                                                                await deleteEntry(entry: entry)
                                                            }
                                                        }) {
                                                            Image(systemName: "trash")
                                                                .font(.system(size: 11))
                                                                .foregroundColor(.red)
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
                                            .fill(entry.id == selectedEntryId ? Color.gray.opacity(0.1) : 
                                                  entry.id == hoveredEntryId ? Color.gray.opacity(0.05) : Color.clear)
                                    )
                                }
                                .buttonStyle(.plain)
                                .contentShape(Rectangle())
                                .onHover { hovering in
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        hoveredEntryId = hovering ? entry.id : nil
                                    }
                                }
                                
                                if entry.id != entries.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                    .scrollIndicators(.never)
                }
                .frame(width: 200)
                .background(Color(colorScheme == .light ? .white : .black))
            }
        }
        .frame(minWidth: 1100, minHeight: 600)
        .animation(.easeInOut(duration: 0.2), value: showingSidebar)
        .preferredColorScheme(colorScheme)
        .onAppear {
            setupInitialState()
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            // Handle timer updates - make bottom nav disappear when timer is running
            if timerService.isRunning && !isHoveringBottomNav {
                withAnimation(.easeIn(duration: 1.0)) {
                    bottomNavOpacity = 0.0
                }
            } else if !timerService.isRunning {
                withAnimation(.easeOut(duration: 0.2)) {
                    bottomNavOpacity = 1.0
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.willEnterFullScreenNotification)) { _ in
            isFullscreen = true
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.willExitFullScreenNotification)) { _ in
            isFullscreen = false
        }
    }
    
    // MARK: - Computed Properties
    
    var canUseChat: Bool {
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleanText.count >= FreewriteConstants.minimumTextLength
    }
    
    // MARK: - Methods
    
    private func setupInitialState() {
        placeholderText = placeholderOptions.randomElement() ?? "\n\nBegin writing"
        Task {
            await loadInitialEntry()
        }
    }
    
    private func saveCurrentText() async {
        // Auto-save current text using file service
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
            placeholderText = placeholderOptions.randomElement() ?? "\n\nBegin writing"
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
    
    private func loadEntry(entry: WritingEntryDTO) async {
        do {
            selectedEntryId = entry.id
            let content = try await fileService.loadEntry(entry.id)
            text = content
        } catch {
            print("Failed to load entry: \(error)")
        }
    }
    
    private func deleteEntry(entry: WritingEntryDTO) async {
        do {
            try await fileService.deleteEntry(entry.id)
            entries.removeAll { $0.id == entry.id }
            
            // If the deleted entry was selected, select the first entry or create a new one
            if selectedEntryId == entry.id {
                if let firstEntry = entries.first {
                    await loadEntry(entry: firstEntry)
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
    
    private func openChatGPT() {
        let aiService = DIContainer.shared.resolve(AIIntegrationServiceProtocol.self)
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
        let aiService = DIContainer.shared.resolve(AIIntegrationServiceProtocol.self)
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
        let aiService = DIContainer.shared.resolve(AIIntegrationServiceProtocol.self)
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        aiService.copyPromptToClipboard(with: trimmedText)
    }
}

// Helper function to calculate line height - from original
func getLineHeight(font: NSFont) -> CGFloat {
    return font.ascender - font.descender + font.leading
}

#Preview {
    ContentView()
}