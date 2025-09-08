import SwiftUI

struct NavigationBar: View {
    @Binding var fontSize: CGFloat
    @Binding var selectedFont: String
    @Binding var hoveredFont: String?
    @Binding var isHoveringSize: Bool
    @Binding var isHoveringTimer: Bool
    @Binding var isHoveringChat: Bool
    @Binding var isHoveringThemeToggle: Bool
    @Binding var isHoveringFullscreen: Bool
    @Binding var isHoveringNewEntry: Bool
    @Binding var isHoveringClock: Bool
    @Binding var isHoveringBottomNav: Bool
    @Binding var showingChatMenu: Bool
    @Binding var didCopyPrompt: Bool
    @Binding var showingSidebar: Bool
    @Binding var colorSchemeString: String
    @Binding var isFullscreen: Bool
    @Binding var text: String
    
    let timerService: FreewriteTimer
    let colorScheme: ColorScheme
    let canUseChat: Bool
    
    let onNewEntry: () -> Void
    let onOpenChatGPT: () -> Void
    let onOpenClaude: () -> Void
    let onCopyPrompt: () -> Void
    
    var fontSizeButtonTitle: String {
        return "\(Int(fontSize))px"
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
                fontSize: $fontSize,
                selectedFont: $selectedFont,
                hoveredFont: $hoveredFont,
                isHoveringSize: $isHoveringSize,
                isHoveringBottomNav: $isHoveringBottomNav
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
                .foregroundColor(FreewriteColors.timerColor(isRunning: timerService.isRunning, isHovering: isHoveringTimer))
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
                
                Text("•").foregroundColor(FreewriteColors.separator)
                
                if canUseChat {
                    Button("Chat") {
                        showingChatMenu = true
                        didCopyPrompt = false
                    }
                    .buttonStyle(.plain)
                    .navigationButton(isHovering: isHoveringChat)
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
                        ChatMenu(
                            text: text,
                            didCopyPrompt: $didCopyPrompt,
                            showingChatMenu: $showingChatMenu,
                            onOpenChatGPT: onOpenChatGPT,
                            onOpenClaude: onOpenClaude,
                            onCopyPrompt: onCopyPrompt
                        )
                    }
                    
                    Text("•").foregroundColor(FreewriteColors.separator)
                }
                
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

                Text("•").foregroundColor(FreewriteColors.separator)
                
                Button(isFullscreen ? "Minimize" : "Fullscreen") {
                    if let window = NSApplication.shared.windows.first {
                        window.toggleFullScreen(nil)
                    }
                }
                .buttonStyle(.plain)
                .navigationButton(isHovering: isHoveringFullscreen)
                .onHover { hovering in
                    isHoveringFullscreen = hovering
                    isHoveringBottomNav = hovering
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
                .navigationButton(isHovering: isHoveringNewEntry)
                .onHover { hovering in
                    isHoveringNewEntry = hovering
                    isHoveringBottomNav = hovering
                    if hovering {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }
                
                Text("•").foregroundColor(FreewriteColors.separator)
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showingSidebar.toggle()
                    }
                }) {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(FreewriteColors.navigationTextColor(isHovering: isHoveringClock))
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
        .background(FreewriteColors.navigationBackground)
        .onHover { hovering in
            isHoveringBottomNav = hovering
        }
    }
}