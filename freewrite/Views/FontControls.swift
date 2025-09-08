import SwiftUI

struct FontControls: View {
    @Bindable var typographyState: TypographyStateManager
    @Bindable var hoverState: HoverStateManager
    
    // Cached font sizes array for performance
    private let fontSizes: [CGFloat] = FontConstants.availableSizes
    
    var body: some View {
        HStack(spacing: 8) {
            Button(typographyState.fontSizeButtonTitle) {
                if let currentIndex = fontSizes.firstIndex(of: typographyState.fontSize) {
                    let nextIndex = (currentIndex + 1) % fontSizes.count
                    typographyState.updateFontSize(fontSizes[nextIndex])
                }
            }
            .buttonStyle(.plain)
            .navigationButton(isHovering: hoverState.isHoveringSize)
            .onHover { hovering in
                hoverState.isHoveringSize = hovering
                hoverState.isHoveringBottomNav = hovering
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
            .onAppear {
                // Add scroll wheel event monitoring for font size adjustment
                NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { event in
                    if hoverState.isHoveringSize {
                        let direction = event.deltaY > 0 ? -1 : 1 // Scroll up decreases, scroll down increases
                        
                        if let currentIndex = fontSizes.firstIndex(of: typographyState.fontSize) {
                            let newIndex = max(0, min(fontSizes.count - 1, currentIndex + direction))
                            typographyState.updateFontSize(fontSizes[newIndex])
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
                typographyState: typographyState,
                hoverState: hoverState
            )
            
            Text("•").foregroundColor(FreewriteColors.separator)
            
            FontButton(
                title: "Arial",
                fontName: "Arial",
                typographyState: typographyState,
                hoverState: hoverState
            )
            
            Text("•").foregroundColor(FreewriteColors.separator)
            
            FontButton(
                title: "System",
                fontName: ".AppleSystemUIFont",
                typographyState: typographyState,
                hoverState: hoverState
            )
            
            Text("•").foregroundColor(FreewriteColors.separator)
            
            FontButton(
                title: "Serif",
                fontName: "Times New Roman",
                typographyState: typographyState,
                hoverState: hoverState
            )
            
            Text("•").foregroundColor(FreewriteColors.separator)
            
            Button("Random") {
                if let randomFont = NSFontManager.shared.availableFontFamilies.randomElement() {
                    typographyState.updateFont(randomFont)
                }
            }
            .buttonStyle(.plain)
            .navigationButton(isHovering: hoverState.hoveredFont == "Random")
            .onHover { hovering in
                hoverState.hoveredFont = hovering ? "Random" : nil
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
}

struct FontButton: View {
    let title: String
    let fontName: String
    @Bindable var typographyState: TypographyStateManager
    @Bindable var hoverState: HoverStateManager
    
    var body: some View {
        Button(title) {
            typographyState.updateFont(fontName)
        }
        .buttonStyle(.plain)
        .navigationButton(isHovering: hoverState.hoveredFont == title)
        .onHover { hovering in
            hoverState.hoveredFont = hovering ? title : nil
            hoverState.isHoveringBottomNav = hovering
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}