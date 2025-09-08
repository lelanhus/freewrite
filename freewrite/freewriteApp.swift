import SwiftUI

@main
struct FreewriteApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("colorScheme") private var colorSchemeString: String = "light"
    @State private var isConfigured = false
    
    init() {
        // Simple synchronous setup for fastest startup
        registerFonts()
        DIContainer.shared.configure()
        _isConfigured = State(initialValue: true) // Start ready immediately
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(
                colorScheme: colorSchemeString == "dark" ? .dark : .light,
                onColorSchemeToggle: {
                    colorSchemeString = colorSchemeString == "light" ? "dark" : "light"
                }
            )
            .toolbar(.hidden, for: .windowToolbar)
            .preferredColorScheme(colorSchemeString == "dark" ? .dark : .light)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1100, height: 600)
        .windowToolbarStyle(.unifiedCompact)
        .windowResizability(.contentSize)
    }
    
    private func registerFonts() {
        // Simple synchronous font registration
        guard let fontURL = Bundle.main.url(forResource: "Lato-Regular", withExtension: "ttf") else {
            print("Warning: Lato-Regular.ttf not found")
            return
        }
        
        CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)
    }
    
}

// MARK: - App Delegate
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        Task { @MainActor in
            configureMainWindow()
        }
    }
    
    @MainActor
    private func configureMainWindow() {
        guard let window = NSApplication.shared.windows.first else { return }
        
        // Ensure window starts in windowed mode
        if window.styleMask.contains(.fullScreen) {
            window.toggleFullScreen(nil)
        }
        
        // Center the window on the screen
        window.center()
    }
}