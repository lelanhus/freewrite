import SwiftUI

struct FontControls: View {
    @Binding var fontSize: CGFloat
    @Binding var selectedFont: String
    @Binding var hoveredFont: String?
    @Binding var isHoveringSize: Bool
    @Binding var isHoveringBottomNav: Bool
    
    var fontSizeButtonTitle: String {
        return "\(Int(fontSize))px"
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Button(fontSizeButtonTitle) {
                let fontSizes: [CGFloat] = [16, 18, 20, 22, 24, 26]
                if let currentIndex = fontSizes.firstIndex(of: fontSize) {
                    let nextIndex = (currentIndex + 1) % fontSizes.count
                    fontSize = fontSizes[nextIndex]
                }
            }
            .buttonStyle(.plain)
            .navigationButton(isHovering: isHoveringSize)
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
            
            Text("•").foregroundColor(FreewriteColors.separator)
            
            FontButton(
                title: "Lato",
                fontName: "Lato-Regular",
                selectedFont: $selectedFont,
                hoveredFont: $hoveredFont,
                isHoveringBottomNav: $isHoveringBottomNav
            )
            
            Text("•").foregroundColor(FreewriteColors.separator)
            
            FontButton(
                title: "Arial",
                fontName: "Arial",
                selectedFont: $selectedFont,
                hoveredFont: $hoveredFont,
                isHoveringBottomNav: $isHoveringBottomNav
            )
            
            Text("•").foregroundColor(FreewriteColors.separator)
            
            FontButton(
                title: "System",
                fontName: ".AppleSystemUIFont",
                selectedFont: $selectedFont,
                hoveredFont: $hoveredFont,
                isHoveringBottomNav: $isHoveringBottomNav
            )
            
            Text("•").foregroundColor(FreewriteColors.separator)
            
            FontButton(
                title: "Serif",
                fontName: "Times New Roman",
                selectedFont: $selectedFont,
                hoveredFont: $hoveredFont,
                isHoveringBottomNav: $isHoveringBottomNav
            )
            
            Text("•").foregroundColor(FreewriteColors.separator)
            
            Button("Random") {
                if let randomFont = NSFontManager.shared.availableFontFamilies.randomElement() {
                    selectedFont = randomFont
                }
            }
            .buttonStyle(.plain)
            .navigationButton(isHovering: hoveredFont == "Random")
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
    }
}

struct FontButton: View {
    let title: String
    let fontName: String
    @Binding var selectedFont: String
    @Binding var hoveredFont: String?
    @Binding var isHoveringBottomNav: Bool
    
    var body: some View {
        Button(title) {
            selectedFont = fontName
        }
        .buttonStyle(.plain)
        .navigationButton(isHovering: hoveredFont == title)
        .onHover { hovering in
            hoveredFont = hovering ? title : nil
            isHoveringBottomNav = hovering
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}