import SwiftUI

/// Timer display that responds to scroll gestures for time adjustment
struct ScrollableTimerView: View {
    @Bindable var timer: FreewriteTimer
    
    var body: some View {
        Text(timer.formattedTime)
            .font(.monospaced(.title2)())
            .foregroundColor(timer.isRunning ? .red : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(timer.isRunning ? .red.opacity(0.3) : .clear, lineWidth: 1)
                    )
            )
            .onScrollWheel { event in
                timer.handleScrollAdjustment(deltaY: event.scrollingDeltaY)
            }
            .help("Scroll to adjust timer in 5-minute increments")
    }
}

// MARK: - Scroll Wheel Modifier
struct ScrollWheelModifier: ViewModifier {
    let action: (NSEvent) -> Void
    
    func body(content: Content) -> some View {
        content
            .background(ScrollWheelView(action: action))
    }
}

extension View {
    func onScrollWheel(perform action: @escaping (NSEvent) -> Void) -> some View {
        self.modifier(ScrollWheelModifier(action: action))
    }
}

// MARK: - NSView for Scroll Events
struct ScrollWheelView: NSViewRepresentable {
    let action: (NSEvent) -> Void
    
    func makeNSView(context: Context) -> ScrollWheelNSView {
        let view = ScrollWheelNSView()
        view.scrollAction = action
        return view
    }
    
    func updateNSView(_ nsView: ScrollWheelNSView, context: Context) {
        nsView.scrollAction = action
    }
}

class ScrollWheelNSView: NSView {
    var scrollAction: ((NSEvent) -> Void)?
    
    override func scrollWheel(with event: NSEvent) {
        scrollAction?(event)
    }
    
    override var acceptsFirstResponder: Bool { true }
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        
        // Remove existing tracking areas
        trackingAreas.forEach { removeTrackingArea($0) }
        
        // Add new tracking area
        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.activeInActiveApp, .mouseEnteredAndExited, .mouseMoved],
            owner: self
        )
        addTrackingArea(trackingArea)
    }
}