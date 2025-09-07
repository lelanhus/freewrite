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
    @State private var isHoveringNewEntry = false
    @State private var isHoveringChat = false
    @State private var viewHeight: CGFloat = 0
    
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
                                    // TODO: Implement chat integration
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
                // TODO: Implement sidebar for history
                VStack {
                    Text("History")
                    Spacer()
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
        // TODO: Implement with file service - save current text to active entry
    }
    
    private func createNewEntry() async {
        // TODO: Implement with file service - create new entry
        placeholderText = placeholderOptions.randomElement() ?? "\n\nBegin writing"
        text = FreewriteConstants.headerString
    }
    
    private func loadInitialEntry() async {
        // TODO: Implement with file service - load most recent or create first entry
    }
}

// Helper function to calculate line height - from original
func getLineHeight(font: NSFont) -> CGFloat {
    return font.ascender - font.descender + font.leading
}

#Preview {
    ContentView()
}