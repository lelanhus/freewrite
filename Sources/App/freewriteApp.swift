import SwiftUI

@main
struct FreewriteApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("colorScheme") private var colorSchemeString: String = "light"
    @State private var isConfigured = false
    
    init() {
        registerFonts()
        configureDependencies()
    }
    
    var body: some Scene {
        WindowGroup {
            if isConfigured {
                ContentView()
                    .toolbar(.hidden, for: .windowToolbar)
                    .preferredColorScheme(colorSchemeString == "dark" ? .dark : .light)
            } else {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .task {
                        await configureServices()
                    }
            }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1100, height: 600)
        .windowToolbarStyle(.unifiedCompact)
        .windowResizability(.contentSize)
    }
    
    private func registerFonts() {
        guard let fontURL = Bundle.main.url(forResource: "Lato-Regular", withExtension: "ttf") else {
            print("Warning: Lato-Regular.ttf not found")
            return
        }
        
        CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)
    }
    
    private func configureDependencies() {
        // Initial setup - the actual configuration happens in configureServices()
    }
    
    @MainActor
    private func configureServices() async {
        DIContainer.shared.configure()
        isConfigured = true
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