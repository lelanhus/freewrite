import SwiftUI
import AppKit
import Combine

/// A text editor that enforces freewriting constraints
struct ConstrainedTextEditor: View {
    @Binding var text: String
    let onTextChange: (String) -> Void
    
    @State private var lastValidText: String = ""
    @State private var textEditor: NSTextView?
    @State private var notificationCancellable: AnyCancellable?
    
    var body: some View {
        FreewriteTextEditor(
            text: $text,
            onTextChange: onTextChange,
            onEditorReady: { editor in
                textEditor = editor
                setupConstraints(for: editor)
            }
        )
        .onAppear {
            setupNotificationObserver()
        }
        .onDisappear {
            cleanupNotificationObserver()
        }
    }
    
    // MARK: - Constraint Enforcement
    
    private func setupConstraints(for textView: NSTextView) {
        TextConstraintValidator.configureTextViewForFreewriting(textView)
        lastValidText = text
    }
    
    // MARK: - Notification Management
    
    private func setupNotificationObserver() {
        notificationCancellable = NotificationCenter.default
            .publisher(for: NSText.didChangeNotification)
            .sink { notification in
                guard let textView = notification.object as? NSTextView,
                      textView == textEditor else { return }
                
                enforceConstraints(in: textView)
            }
    }
    
    private func cleanupNotificationObserver() {
        notificationCancellable?.cancel()
        notificationCancellable = nil
    }
    
    private func enforceConstraints(in textView: NSTextView) {
        guard let textStorage = textView.textStorage else { return }
        
        let currentText = textStorage.string
        let currentRange = textView.selectedRange()
        
        let validationResult = TextConstraintValidator.validateTextChange(
            currentText: currentText,
            previousText: lastValidText,
            cursorPosition: currentRange.location
        )
        
        if !validationResult.isValid {
            guard let correctedText = validationResult.correctedText else { return }
            
            // Apply correction
            textStorage.replaceCharacters(
                in: NSRange(location: 0, length: textStorage.length),
                with: correctedText
            )
            
            // Update cursor position
            let cursorPosition = validationResult.cursorPosition ?? correctedText.count
            textView.setSelectedRange(NSRange(location: cursorPosition, length: 0))
            
            // Provide feedback if needed
            if validationResult.shouldProvideFeedback {
                TextConstraintValidator.provideFeedback()
            }
            
            return
        }
        
        // Update last valid text if this is a valid forward addition
        if currentText.count >= lastValidText.count {
            lastValidText = currentText
            onTextChange(currentText)
        }
    }
    
}

// MARK: - NSTextView Wrapper

struct FreewriteTextEditor: NSViewRepresentable {
    @Binding var text: String
    let onTextChange: (String) -> Void
    let onEditorReady: (NSTextView) -> Void
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        let textView = NSTextView()
        
        // Configure scroll view
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.documentView = textView
        
        // Configure text view
        textView.isRichText = false
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = false // Disable undo to prevent constraint bypassing
        textView.font = NSFont.systemFont(ofSize: 18)
        textView.textColor = NSColor.textColor
        textView.backgroundColor = NSColor.clear
        textView.textContainerInset = NSSize(width: 8, height: 8)
        
        // Set up text container
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainer?.maximumNumberOfLines = 0
        
        // Set initial text
        textView.string = text
        
        // Notify that editor is ready
        DispatchQueue.main.async {
            onEditorReady(textView)
        }
        
        return scrollView
    }
    
    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        
        // Only update if text is different to avoid cursor jumping
        if textView.string != text {
            textView.string = text
            
            // Consistent selection restoration - always place cursor at end for freewriting
            let targetLocation = text.count // Always place cursor at end for forward-only writing
            
            textView.setSelectedRange(NSRange(location: targetLocation, length: 0))
            
            // Ensure cursor is visible after text update
            textView.scrollRangeToVisible(NSRange(location: targetLocation, length: 0))
        }
    }
    
    func dismantleNSView(_ scrollView: NSScrollView, context: Context) {
        // Proper cleanup of AppKit resources to prevent memory leaks
        guard let textView = scrollView.documentView as? NSTextView else { return }
        
        // Clear delegates and references that could cause retention cycles
        textView.delegate = nil
        
        // Clear text storage and layout manager references
        if let layoutManager = textView.textContainer?.layoutManager,
           let _ = textView.textContainer {
            layoutManager.removeTextContainer(at: 0) // Remove by index
        }
        
        // Clear the text content to release any retained strings
        textView.string = ""
        
        // Remove from scroll view
        scrollView.documentView = nil
        
        print("Cleaned up NSTextView resources")
    }
}

// MARK: - Key Event Handling Extension

extension NSTextView {
    open override func keyDown(with event: NSEvent) {
        // Block backspace and delete keys
        if event.keyCode == 51 || event.keyCode == 117 { // Backspace or Delete
            NSSound.beep()
            return
        }
        
        // Consistent selection handling - maintain cursor at end for freewriting
        if event.keyCode == 123 || event.keyCode == 124 { // Left or Right arrows
            let currentSelection = selectedRange()
            
            // Always enforce cursor at end for consistent freewriting behavior
            if currentSelection.location < string.count {
                NSSound.beep()
                // Force cursor back to end
                setSelectedRange(NSRange(location: string.count, length: 0))
                scrollRangeToVisible(NSRange(location: string.count, length: 0))
                return
            }
        }
        
        // Block keyboard shortcuts that could bypass constraints
        if event.modifierFlags.contains(.command) {
            switch event.charactersIgnoringModifiers {
            case "z", "Z": // Undo/Redo
                NSSound.beep()
                return
            case "v": // Paste - could allow, but with constraints
                handlePaste(event)
                return
            case "x": // Cut
                NSSound.beep()
                return
            default:
                break
            }
        }
        
        super.keyDown(with: event)
    }
    
    private func handlePaste(_ event: NSEvent) {
        // Consistent paste behavior - always paste at end of text
        let currentSelection = selectedRange()
        if currentSelection.location == string.count {
            super.keyDown(with: event)
            // Ensure cursor stays at end after paste
            DispatchQueue.main.async {
                self.setSelectedRange(NSRange(location: self.string.count, length: 0))
                self.scrollRangeToVisible(NSRange(location: self.string.count, length: 0))
            }
        } else {
            NSSound.beep()
            // Force cursor to end for consistent state
            setSelectedRange(NSRange(location: string.count, length: 0))
            scrollRangeToVisible(NSRange(location: string.count, length: 0))
        }
    }
}