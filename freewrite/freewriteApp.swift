import SwiftUI

@main
struct FreewriteApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("colorScheme") private var colorSchemeString: String = "light"
    @State private var isConfigured = false
    
    init() {
        configureDependencies()
        // Font registration moved to async to prevent startup blocking
    }
    
    var body: some Scene {
        WindowGroup {
            if isConfigured {
                ContentView(
                    colorScheme: colorSchemeString == "dark" ? .dark : .light,
                    onColorSchemeToggle: {
                        colorSchemeString = colorSchemeString == "light" ? "dark" : "light"
                    }
                )
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
    
    private func registerFontsAsync() async {
        await withCheckedContinuation { continuation in
            // Move font registration to background queue to prevent startup blocking
            DispatchQueue.global(qos: .userInitiated).async {
                guard let fontURL = Bundle.main.url(forResource: "Lato-Regular", withExtension: "ttf") else {
                    print("Warning: Lato-Regular.ttf not found")
                    continuation.resume()
                    return
                }
                
                let success = CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)
                if success {
                    print("Successfully registered Lato-Regular font")
                } else {
                    print("Warning: Failed to register Lato-Regular font")
                }
                
                continuation.resume()
            }
        }
    }
    
    private func registerFonts() {
        // Legacy synchronous method - kept for compatibility but not used
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
        // Configure services and fonts asynchronously to prevent startup blocking
        async let fontRegistration: Void = registerFontsAsync()
        async let containerConfiguration: Void = configureDIContainer()
        
        // Wait for both to complete
        let _ = await fontRegistration
        let _ = await containerConfiguration
        
        isConfigured = true
    }
    
    @MainActor
    private func configureDIContainer() async {
        DIContainer.shared.configure()
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