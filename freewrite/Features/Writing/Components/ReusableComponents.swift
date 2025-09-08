import SwiftUI

// MARK: - Reusable Navigation Button Component

/// Eliminates the massive duplication in font selection buttons
/// Reduces ~200 lines of repetitive hover logic to reusable components
struct NavigationButton: View {
    let title: String
    let isHovered: Bool
    let action: () -> Void
    let onHoverChange: (Bool) -> Void
    
    var body: some View {
        Button(title, action: action)
            .buttonStyle(.plain)
            .navigationButton(isHovering: isHovered)
            .onHover { hovering in
                onHoverChange(hovering)
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
    }
}

// MARK: - Font Selection Component (Eliminates 150+ lines)

struct FontSelector: View {
    @Binding var selectedFont: String
    @Binding var hoveredFont: String?
    @Binding var isHoveringBottomNav: Bool
    
    private let fonts: [(name: String, value: String)] = [
        ("Lato", "Lato-Regular"),
        ("Arial", "Arial"),
        ("System", ".AppleSystemUIFont"),
        ("Serif", "Times New Roman")
    ]
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(fonts, id: \.name) { font in
                NavigationButton(
                    title: font.name,
                    isHovered: hoveredFont == font.name,
                    action: { 
                        selectedFont = font.value
                        hoveredFont = nil
                    },
                    onHoverChange: { hovering in
                        hoveredFont = hovering ? font.name : nil
                        isHoveringBottomNav = hovering
                    }
                )
                
                if font.name != fonts.last?.name {
                    Text("•").foregroundColor(FreewriteColors.separator)
                }
            }
            
            Text("•").foregroundColor(FreewriteColors.separator)
            
            NavigationButton(
                title: "Random",
                isHovered: hoveredFont == "Random",
                action: {
                    if let randomFont = NSFontManager.shared.availableFontFamilies.randomElement() {
                        selectedFont = randomFont
                        hoveredFont = nil
                    }
                },
                onHoverChange: { hovering in
                    hoveredFont = hovering ? "Random" : nil
                    isHoveringBottomNav = hovering
                }
            )
        }
    }
}

// MARK: - Font Size Control Component

struct FontSizeControl: View {
    @Binding var fontSize: CGFloat
    @Binding var isHoveringSize: Bool
    @Binding var isHoveringBottomNav: Bool
    
    private let fontSizes: [CGFloat] = [16, 18, 20, 22, 24, 26]
    
    private var fontSizeButtonTitle: String {
        "\(Int(fontSize))px"
    }
    
    var body: some View {
        NavigationButton(
            title: fontSizeButtonTitle,
            isHovered: isHoveringSize,
            action: cycleFontSize,
            onHoverChange: { hovering in
                isHoveringSize = hovering
                isHoveringBottomNav = hovering
            }
        )
        .onAppear(perform: setupScrolling)
    }
    
    private func cycleFontSize() {
        if let currentIndex = fontSizes.firstIndex(of: fontSize) {
            let nextIndex = (currentIndex + 1) % fontSizes.count
            fontSize = fontSizes[nextIndex]
        }
    }
    
    private func setupScrolling() {
        NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { event in
            if isHoveringSize {
                let direction = event.deltaY > 0 ? -1 : 1
                if let currentIndex = fontSizes.firstIndex(of: fontSize) {
                    let newIndex = max(0, min(fontSizes.count - 1, currentIndex + direction))
                    fontSize = fontSizes[newIndex]
                    NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
                }
            }
            return event
        }
    }
}

// MARK: - Timer Control Component

struct TimerControl: View {
    let timerService: any TimerServiceProtocol
    @Binding var isHoveringTimer: Bool
    @Binding var isHoveringBottomNav: Bool
    
    private var timerButtonTitle: String {
        let minutes = timerService.timeRemaining / 60
        let seconds = timerService.timeRemaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var body: some View {
        NavigationButton(
            title: timerButtonTitle,
            isHovered: isHoveringTimer,
            action: {
                if timerService.isRunning {
                    timerService.pause()
                } else {
                    timerService.start()
                }
            },
            onHoverChange: { hovering in
                isHoveringTimer = hovering
                isHoveringBottomNav = hovering
            }
        )
        .foregroundColor(FreewriteColors.timerColor(isRunning: timerService.isRunning, isHovering: isHoveringTimer))
        .onAppear(perform: setupTimerScrolling)
    }
    
    private func setupTimerScrolling() {
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
                    timerService.setTime(min(max(newTime, 0), 2700))
                }
            }
            return event
        }
    }
}

// MARK: - Theme Toggle Component

struct ThemeToggle: View {
    @Binding var colorSchemeString: String
    @Binding var isHoveringThemeToggle: Bool
    @Binding var isHoveringBottomNav: Bool
    
    private var colorScheme: ColorScheme {
        return colorSchemeString == "dark" ? .dark : .light
    }
    
    var body: some View {
        Button(action: {
            colorSchemeString = colorScheme == .light ? "dark" : "light"
        }) {
            Image(systemName: colorScheme == .light ? "moon.fill" : "sun.max.fill")
                .foregroundColor(FreewriteColors.themeToggle.tinted(with: isHoveringThemeToggle ? .white : .clear))
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
    }
}

// MARK: - Utility Button Component (Eliminates repetition)

struct UtilityButton: View {
    let title: String
    let isHovered: Bool
    let action: () -> Void
    let onHoverChange: (Bool) -> Void
    
    var body: some View {
        NavigationButton(
            title: title,
            isHovered: isHovered,
            action: action,
            onHoverChange: onHoverChange
        )
    }
}

// MARK: - Icon Button Component

struct IconButton: View {
    let systemName: String
    let isHovered: Bool
    let action: () -> Void
    let onHoverChange: (Bool) -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .foregroundColor(FreewriteColors.navigationTextColor(isHovering: isHovered))
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            onHoverChange(hovering)
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

// MARK: - Separator Component

struct NavigationSeparator: View {
    var body: some View {
        Text("•").foregroundColor(FreewriteColors.separator)
    }
}

// MARK: - Bottom Navigation Composition (Reduces ContentView by ~300 lines)

struct BottomNavigationBar: View {
    // Font state
    @Binding var selectedFont: String
    @Binding var fontSize: CGFloat
    @Binding var hoveredFont: String?
    @Binding var isHoveringSize: Bool
    
    // Navigation hover states
    @Binding var bottomNavOpacity: Double
    @Binding var isHoveringBottomNav: Bool
    @Binding var isHoveringTimer: Bool
    @Binding var isHoveringThemeToggle: Bool
    @Binding var isHoveringClock: Bool
    @Binding var isHoveringNewEntry: Bool
    @Binding var isHoveringChat: Bool
    @Binding var isHoveringFullscreen: Bool
    
    // UI mode state
    @Binding var colorSchemeString: String
    @Binding var showingSidebar: Bool
    @Binding var isFullscreen: Bool
    @Binding var showingChatMenu: Bool
    @Binding var didCopyPrompt: Bool
    
    // Services and data
    let timerService: any TimerServiceProtocol
    let text: String
    let canUseChat: Bool
    
    // Actions
    let onNewEntry: () -> Void
    let onOpenChatGPT: () -> Void
    let onOpenClaude: () -> Void
    let onCopyPrompt: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                // Left side - font controls (massively simplified)
                HStack(spacing: 8) {
                    FontSizeControl(
                        fontSize: $fontSize,
                        isHoveringSize: $isHoveringSize,
                        isHoveringBottomNav: $isHoveringBottomNav
                    )
                    
                    NavigationSeparator()
                    
                    FontSelector(
                        selectedFont: $selectedFont,
                        hoveredFont: $hoveredFont,
                        isHoveringBottomNav: $isHoveringBottomNav
                    )
                }
                .padding(8)
                .cornerRadius(6)
                .onHover { hovering in
                    isHoveringBottomNav = hovering
                }
                
                Spacer()
                
                // Right side - utility controls (massively simplified)
                HStack(spacing: 8) {
                    TimerControl(
                        timerService: timerService,
                        isHoveringTimer: $isHoveringTimer,
                        isHoveringBottomNav: $isHoveringBottomNav
                    )
                    
                    NavigationSeparator()
                    
                    if canUseChat {
                        ChatButton(
                            showingChatMenu: $showingChatMenu,
                            didCopyPrompt: $didCopyPrompt,
                            isHoveringChat: $isHoveringChat,
                            isHoveringBottomNav: $isHoveringBottomNav,
                            text: text,
                            onOpenChatGPT: onOpenChatGPT,
                            onOpenClaude: onOpenClaude,
                            onCopyPrompt: onCopyPrompt
                        )
                        
                        NavigationSeparator()
                    }
                    
                    ThemeToggle(
                        colorSchemeString: $colorSchemeString,
                        isHoveringThemeToggle: $isHoveringThemeToggle,
                        isHoveringBottomNav: $isHoveringBottomNav
                    )
                    
                    NavigationSeparator()
                    
                    UtilityButton(
                        title: isFullscreen ? "Minimize" : "Fullscreen",
                        isHovered: isHoveringFullscreen,
                        action: {
                            if let window = NSApplication.shared.windows.first {
                                window.toggleFullScreen(nil)
                            }
                        },
                        onHoverChange: { hovering in
                            isHoveringFullscreen = hovering
                            isHoveringBottomNav = hovering
                        }
                    )
                    
                    NavigationSeparator()
                    
                    UtilityButton(
                        title: "New Entry",
                        isHovered: isHoveringNewEntry,
                        action: onNewEntry,
                        onHoverChange: { hovering in
                            isHoveringNewEntry = hovering
                            isHoveringBottomNav = hovering
                        }
                    )
                    
                    NavigationSeparator()
                    
                    IconButton(
                        systemName: "clock.arrow.circlepath",
                        isHovered: isHoveringClock,
                        action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showingSidebar.toggle()
                            }
                        },
                        onHoverChange: { hovering in
                            isHoveringClock = hovering
                            isHoveringBottomNav = hovering
                        }
                    )
                }
                .padding(8)
                .cornerRadius(6)
                .onHover { hovering in
                    isHoveringBottomNav = hovering
                }
            }
            .padding()
            .background(FreewriteColors.navigationBackground)
            .opacity(bottomNavOpacity)
            .onHover { hovering in
                isHoveringBottomNav = hovering
                if hovering {
                    withAnimation(.easeOut(duration: 0.2)) {
                        bottomNavOpacity = 1.0
                    }
                }
                // Timer-based fade handled by parent
            }
        }
    }
}

// MARK: - Chat Button Component (Simplifies chat logic)

struct ChatButton: View {
    @Binding var showingChatMenu: Bool
    @Binding var didCopyPrompt: Bool
    @Binding var isHoveringChat: Bool
    @Binding var isHoveringBottomNav: Bool
    
    let text: String
    let onOpenChatGPT: () -> Void
    let onOpenClaude: () -> Void
    let onCopyPrompt: () -> Void
    
    var body: some View {
        NavigationButton(
            title: "Chat",
            isHovered: isHoveringChat,
            action: {
                showingChatMenu = true
                didCopyPrompt = false
            },
            onHoverChange: { hovering in
                isHoveringChat = hovering
                isHoveringBottomNav = hovering
            }
        )
        .popover(isPresented: $showingChatMenu, attachmentAnchor: .point(UnitPoint(x: 0.5, y: 0)), arrowEdge: .top) {
            ChatMenuPopover(
                text: text,
                didCopyPrompt: $didCopyPrompt,
                showingChatMenu: $showingChatMenu,
                onOpenChatGPT: onOpenChatGPT,
                onOpenClaude: onOpenClaude,
                onCopyPrompt: onCopyPrompt
            )
        }
    }
}

// MARK: - Chat Menu Popover (Extracts complex popup logic)

private struct ChatMenuPopover: View {
    let text: String
    @Binding var didCopyPrompt: Bool
    @Binding var showingChatMenu: Bool
    let onOpenChatGPT: () -> Void
    let onOpenClaude: () -> Void
    let onCopyPrompt: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            if text.count < 350 {
                Text("Please free write for at minimum 5 minutes first. Then click this. Trust.")
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                    .frame(width: 250)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            } else {
                ChatOptionButton(title: "ChatGPT") {
                    showingChatMenu = false
                    onOpenChatGPT()
                }
                
                Divider()
                
                ChatOptionButton(title: "Claude") {
                    showingChatMenu = false
                    onOpenClaude()
                }
                
                Divider()
                
                ChatOptionButton(title: didCopyPrompt ? "Copied!" : "Copy Prompt") {
                    onCopyPrompt()
                    didCopyPrompt = true
                }
            }
        }
        .frame(minWidth: 120, maxWidth: 250)
        .background(FreewriteColors.popoverBackground)
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.1), radius: 4, y: 2)
        .onChange(of: showingChatMenu) { _, newValue in
            if !newValue {
                didCopyPrompt = false
            }
        }
    }
}

// MARK: - Chat Option Button

private struct ChatOptionButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .foregroundColor(.primary)
        .onHover { hovering in
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}