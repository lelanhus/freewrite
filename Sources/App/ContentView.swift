import SwiftUI

struct ContentView: View {
    @State private var viewModel = WritingViewModel()
    @State private var selectedFont: String = "Lato-Regular"
    @State private var fontSize: CGFloat = 18
    @State private var isHoveringTimer = false
    @State private var bottomNavOpacity: Double = 1.0
    @State private var isHoveringBottomNav = false
    
    var body: some View {
        ZStack {
            // Full-screen text editor matching original
            TextEditor(text: Binding(
                get: { viewModel.currentText },
                set: { newValue in
                    // Ensure the text always starts with two newlines like original
                    if !newValue.hasPrefix("\n\n") {
                        viewModel.updateText("\n\n" + newValue.trimmingCharacters(in: .newlines))
                    } else {
                        viewModel.updateText(newValue)
                    }
                }
            ))
            .font(.custom(selectedFont, size: fontSize))
            .scrollContentBackground(.hidden)
            .scrollIndicators(.never)
            .frame(maxWidth: 650) // Original constraint width
            .onScrollWheel { event in
                // Timer scroll adjustment when hovering timer
                if isHoveringTimer, let timer = viewModel.timerService as? FreewriteTimer {
                    timer.handleScrollAdjustment(deltaY: event.scrollingDeltaY)
                }
            }
            
            // Placeholder overlay - matching original positioning
            if viewModel.currentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(viewModel.placeholderText)
                    .font(.custom(selectedFont, size: fontSize))
                    .foregroundColor(.secondary.opacity(0.5))
                    .allowsHitTesting(false)
                    .offset(x: 5, y: fontSize / 2)
            }
            
            // Bottom navigation bar - matching original
            VStack {
                Spacer()
                HStack {
                    // Left side - font controls
                    HStack(spacing: 8) {
                        Button("\(Int(fontSize))px") {
                            let fontSizes: [CGFloat] = [16, 18, 20, 22, 24, 26]
                            if let currentIndex = fontSizes.firstIndex(of: fontSize) {
                                let nextIndex = (currentIndex + 1) % fontSizes.count
                                fontSize = fontSizes[nextIndex]
                            }
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.secondary)
                        
                        Text("•").foregroundColor(.secondary)
                        
                        Button("Lato") {
                            selectedFont = "Lato-Regular"
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.secondary)
                        
                        Text("•").foregroundColor(.secondary)
                        
                        Button("Arial") {
                            selectedFont = "Arial"
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.secondary)
                        
                        Text("•").foregroundColor(.secondary)
                        
                        Button("System") {
                            selectedFont = ".AppleSystemUIFont"
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.secondary)
                        
                        Text("•").foregroundColor(.secondary)
                        
                        Button("Serif") {
                            selectedFont = "Times New Roman"
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.secondary)
                        
                        Text("•").foregroundColor(.secondary)
                        
                        Button("Random") {
                            if let randomFont = NSFontManager.shared.availableFontFamilies.randomElement() {
                                selectedFont = randomFont
                            }
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.secondary)
                    }
                    .padding(8)
                    
                    Spacer()
                    
                    // Right side - utility controls
                    HStack(spacing: 8) {
                        Button(viewModel.formattedTime) {
                            if viewModel.isTimerRunning {
                                viewModel.pauseTimer()
                            } else {
                                viewModel.startTimer()
                            }
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(viewModel.isTimerRunning ? .secondary.opacity(0.8) : .secondary)
                        .onHover { hovering in
                            isHoveringTimer = hovering
                        }
                        
                        Text("•").foregroundColor(.secondary)
                        
                        if viewModel.canUseChat {
                            Button("Chat") {
                                // TODO: Implement chat integration
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(.secondary)
                            
                            Text("•").foregroundColor(.secondary)
                        }
                        
                        Button("Minimize") {
                            if let window = NSApplication.shared.windows.first {
                                window.toggleFullScreen(nil)
                            }
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.secondary)
                        
                        Text("•").foregroundColor(.secondary)
                        
                        Button("New Entry") {
                            Task {
                                await viewModel.createNewEntry()
                            }
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.secondary)
                        
                        Text("•").foregroundColor(.secondary)
                        
                        Text("⌘").foregroundColor(.secondary)
                        
                        Text("•").foregroundColor(.secondary)
                        
                        Button(action: {}) {
                            Image(systemName: "questionmark.circle")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(8)
                }
                .padding()
                .opacity(bottomNavOpacity)
                .onHover { hovering in
                    isHoveringBottomNav = hovering
                    if hovering {
                        withAnimation(.easeOut(duration: 0.2)) {
                            bottomNavOpacity = 1.0
                        }
                    } else if viewModel.isTimerRunning {
                        withAnimation(.easeIn(duration: 1.0)) {
                            bottomNavOpacity = 0.0
                        }
                    }
                }
            }
        }
        .frame(minWidth: 1100, minHeight: 600)
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            if let error = viewModel.error {
                Text(error.localizedDescription)
            }
        }
    }
}

#Preview {
    ContentView()
}