import SwiftUI

struct NavigationBar: View {
    // State Managers (clean parameter passing)
    @Bindable var typographyState: TypographyStateManager
    @Bindable var hoverState: HoverStateManager
    @Bindable var uiState: UIStateManager
    
    // Shortcut disclosure system
    let disclosureManager: ShortcutDisclosureManager
    
    // Essential bindings that can't be in managers
    @Binding var text: String
    
    // Services and computed values
    let timerService: FreewriteTimer
    let colorScheme: ColorScheme
    let canUseChat: Bool
    
    // Actions
    let onNewEntry: () -> Void
    let onOpenChatGPT: () -> Void
    let onOpenClaude: () -> Void
    let onCopyPrompt: () -> Void
    let onColorSchemeToggle: () -> Void
    
    // Event Monitor Management
    @State private var scrollEventMonitor: Any?
    
    var fontSizeButtonTitle: String {
        return "\(Int(typographyState.fontSize))px"
    }
    
    var timerButtonTitle: String {
        let minutes = timerService.timeRemaining / 60
        let seconds = timerService.timeRemaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var body: some View {
        HStack {
            // Font buttons (left side)
            FontControls(
                typographyState: typographyState,
                hoverState: hoverState
            )
            
            Spacer()
            
            // Utility buttons (right side)
            HStack(spacing: 8) {
                // Timer button
                Button(timerButtonTitle) {
                    if timerService.isRunning {
                        timerService.pause()
                    } else {
                        timerService.start()
                    }
                }
                .buttonStyle(.plain)
                .foregroundColor(FreewriteColors.timerColor(isRunning: timerService.isRunning, isHovering: hoverState.isHoveringTimer))
                .onHover { hovering in
                    hoverState.isHoveringTimer = hovering
                    hoverState.isHoveringBottomNav = hovering
                    if hovering {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }
                .shortcutTooltip(
                    element: "timer", 
                    disclosureManager: disclosureManager
                )
                .onAppear {
                    setupScrollEventMonitor()
                }
                .onDisappear {
                    cleanupScrollEventMonitor()
                }
                
                Text("•").foregroundColor(FreewriteColors.separator)
                
                if canUseChat {
                    Button("Chat") {
                        if uiState.canToggleMenu {
                            uiState.openChatMenu()
                        }
                    }
                    .buttonStyle(.plain)
                    .navigationButton(isHovering: hoverState.isHoveringChat)
                    .onHover { hovering in
                        hoverState.isHoveringChat = hovering
                        hoverState.isHoveringBottomNav = hovering
                        if hovering {
                            NSCursor.pointingHand.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                    .popover(isPresented: $uiState.showingChatMenu, attachmentAnchor: .point(UnitPoint(x: 0.5, y: 0)), arrowEdge: .top) {
                        ChatMenu(
                            text: text,
                            uiState: uiState,
                            onOpenChatGPT: onOpenChatGPT,
                            onOpenClaude: onOpenClaude,
                            onCopyPrompt: onCopyPrompt
                        )
                    }
                    
                    Text("•").foregroundColor(FreewriteColors.separator)
                }
                
                Button(action: {
                    onColorSchemeToggle()
                }) {
                    Image(systemName: colorScheme == .light ? "moon.fill" : "sun.max.fill")
                        .foregroundColor(FreewriteColors.themeToggle.tinted(with: hoverState.isHoveringThemeToggle ? .white : .clear))
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    hoverState.isHoveringThemeToggle = hovering
                    hoverState.isHoveringBottomNav = hovering
                    if hovering {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }

                Text("•").foregroundColor(FreewriteColors.separator)
                
                Button(uiState.isFullscreen ? "Minimize" : "Fullscreen") {
                    if let window = NSApplication.shared.windows.first {
                        window.toggleFullScreen(nil)
                    }
                }
                .buttonStyle(.plain)
                .navigationButton(isHovering: hoverState.isHoveringFullscreen)
                .onHover { hovering in
                    hoverState.isHoveringFullscreen = hovering
                    hoverState.isHoveringBottomNav = hovering
                    if hovering {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }

                Text("•").foregroundColor(FreewriteColors.separator)
                
                Button("New Entry") {
                    onNewEntry()
                }
                .buttonStyle(.plain)
                .navigationButton(isHovering: hoverState.isHoveringNewEntry)
                .onHover { hovering in
                    hoverState.isHoveringNewEntry = hovering
                    hoverState.isHoveringBottomNav = hovering
                    if hovering {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }
                .shortcutTooltip(
                    element: "newEntry",
                    disclosureManager: disclosureManager
                )
                
                Text("•").foregroundColor(FreewriteColors.separator)
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        uiState.showingSidebar.toggle()
                    }
                }) {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(FreewriteColors.navigationTextColor(isHovering: hoverState.isHoveringClock))
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    hoverState.isHoveringClock = hovering
                    hoverState.isHoveringBottomNav = hovering
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
                hoverState.isHoveringBottomNav = hovering
            }
        }
        .padding()
        .background(FreewriteColors.navigationBackground)
        .onHover { hovering in
            hoverState.isHoveringBottomNav = hovering
        }
    }
    
    // MARK: - Event Monitor Management
    
    private func setupScrollEventMonitor() {
        // Store the monitor reference for proper cleanup
        scrollEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { event in
            if hoverState.isHoveringTimer {
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
    
    private func cleanupScrollEventMonitor() {
        if let monitor = scrollEventMonitor {
            NSEvent.removeMonitor(monitor)
            scrollEventMonitor = nil
        }
    }
}