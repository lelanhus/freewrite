import SwiftUI

struct ContentView: View {
    // Services
    private let timerService = DIContainer.shared.resolve(TimerServiceProtocol.self) as! FreewriteTimer
    
    // ViewModel
    @State private var viewModel = ContentViewModel()
    
    // UI State
    @State private var selectedFont: String = "Lato-Regular" 
    @State private var fontSize: CGFloat = 18
    @State private var isHoveringTimer = false
    @State private var bottomNavOpacity: Double = 1.0
    @State private var isHoveringBottomNav = false
    @State private var placeholderText: String = ""
    @AppStorage("colorScheme") private var colorSchemeString: String = "light"
    
    private var colorScheme: ColorScheme {
        return colorSchemeString == "dark" ? .dark : .light
    }
    @State private var showingSidebar = false
    @State private var isHoveringThemeToggle = false
    @State private var isHoveringClock = false
    @State private var hoveredFont: String? = nil
    @State private var isHoveringSize = false
    @State private var isHoveringNewEntry = false
    @State private var isHoveringChat = false
    @State private var viewHeight: CGFloat = 0
    @State private var showingChatMenu = false
    @State private var didCopyPrompt: Bool = false
    @State private var hoveredEntryId: UUID? = nil
    @State private var isFullscreen = false
    @State private var isHoveringFullscreen = false
    
    // Computed properties
    var lineHeight: CGFloat {
        let font = NSFont(name: selectedFont, size: fontSize) ?? .systemFont(ofSize: fontSize)
        let defaultLineHeight = getLineHeight(font: font)
        return (fontSize * 1.5) - defaultLineHeight
    }
    
    var placeholderOffset: CGFloat {
        return fontSize / 2
    }
    
    
    var body: some View {
        let navHeight: CGFloat = 68
        let _ = FreewriteColors.navigationText // TODO: Remove after migration to components
        let _ = FreewriteColors.navigationTextHover // TODO: Remove after migration to components
        
        HStack(spacing: 0) {
            // Main content - matching original structure exactly
            ZStack {
                FreewriteColors.contentBackground
                    .ignoresSafeArea()
                
                TextEditor(text: Binding(
                    get: { viewModel.text },
                    set: { newValue in
                        viewModel.processTextChange(newValue)
                    }
                ))
                .background(FreewriteColors.contentBackground)
                .font(.custom(selectedFont, size: fontSize))
                .foregroundColor(FreewriteColors.writingText)
                .scrollContentBackground(.hidden)
                .scrollIndicators(.never)
                .lineSpacing(lineHeight)
                .frame(maxWidth: 650)
                .id("\(selectedFont)-\(fontSize)-\(colorScheme)")
                .padding(.bottom, bottomNavOpacity > 0 ? navHeight : 0)
                .ignoresSafeArea()
                .onAppear {
                    placeholderText = viewModel.placeholderOptions.randomElement() ?? "\n\nBegin writing"
                }
                .overlay(
                    ZStack(alignment: .topLeading) {
                        if viewModel.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text(placeholderText)
                                .font(.custom(selectedFont, size: fontSize))
                                .foregroundColor(FreewriteColors.placeholderText)
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
                    NavigationBar(
                        fontSize: $fontSize,
                        selectedFont: $selectedFont,
                        hoveredFont: $hoveredFont,
                        isHoveringSize: $isHoveringSize,
                        isHoveringTimer: $isHoveringTimer,
                        isHoveringChat: $isHoveringChat,
                        isHoveringThemeToggle: $isHoveringThemeToggle,
                        isHoveringFullscreen: $isHoveringFullscreen,
                        isHoveringNewEntry: $isHoveringNewEntry,
                        isHoveringClock: $isHoveringClock,
                        isHoveringBottomNav: $isHoveringBottomNav,
                        showingChatMenu: $showingChatMenu,
                        didCopyPrompt: $didCopyPrompt,
                        showingSidebar: $showingSidebar,
                        colorSchemeString: $colorSchemeString,
                        isFullscreen: $isFullscreen,
                        text: $viewModel.text,
                        timerService: timerService,
                        colorScheme: colorScheme,
                        canUseChat: viewModel.canUseChat,
                        onNewEntry: {
                            Task {
                                await viewModel.createNewEntry()
                            }
                        },
                        onOpenChatGPT: { viewModel.openChatGPT() },
                        onOpenClaude: { viewModel.openClaude() },
                        onCopyPrompt: { viewModel.copyPromptToClipboard() }
                    )
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
                
                Sidebar(
                    entries: $viewModel.entries,
                    selectedEntryId: $viewModel.selectedEntryId,
                    hoveredEntryId: $hoveredEntryId,
                    fileService: DIContainer.shared.resolve(FileManagementServiceProtocol.self),
                    onLoadEntry: { entry in
                        await viewModel.loadEntry(entry)
                    },
                    onDeleteEntry: { entry in
                        await viewModel.deleteEntry(entry)
                    },
                    onSaveCurrentText: {
                        await viewModel.saveCurrentText()
                    }
                )
            }
        }
        .frame(minWidth: 1100, minHeight: 600)
        .animation(.easeInOut(duration: 0.2), value: showingSidebar)
        .preferredColorScheme(colorScheme)
        .background(FreewriteColors.contentBackground) // Ensure entire window uses system background
        .onAppear {
            Task {
                await viewModel.setupInitialState()
            }
            placeholderText = viewModel.placeholderOptions.randomElement() ?? "\n\nBegin writing"
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
    
}


#Preview {
    ContentView()
}