import SwiftUI
import AppKit

/// A text editor that enforces freewriting constraints
struct ConstrainedTextEditor: View {
    @Binding var text: String
    let onTextChange: (String) -> Void
    
    @State private var lastValidText: String = ""
    @State private var textEditor: NSTextView?
    
    var body: some View {
        FreewriteTextEditor(
            text: $text,
            onTextChange: onTextChange,
            onEditorReady: { editor in
                textEditor = editor
                setupConstraints(for: editor)
            }
        )
        .onReceive(NotificationCenter.default.publisher(for: NSText.didChangeNotification)) { notification in
            guard let textView = notification.object as? NSTextView,
                  textView == textEditor else { return }
            
            enforceConstraints(in: textView)
        }
    }
    
    // MARK: - Constraint Enforcement
    
    private func setupConstraints(for textView: NSTextView) {
        // Disable spell checking and grammar checking
        textView.isContinuousSpellCheckingEnabled = false
        textView.isGrammarCheckingEnabled = false
        
        // Disable smart quotes and other automatic text replacement
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        
        // Store initial valid text
        lastValidText = text
    }
    
    private func enforceConstraints(in textView: NSTextView) {
        guard let textStorage = textView.textStorage else { return }
        
        let currentText = textStorage.string
        let currentRange = textView.selectedRange()
        
        // Check if user is trying to edit previous text
        if isEditingPreviousContent(current: currentText, previous: lastValidText, cursorPosition: currentRange.location) {
            // Revert to last valid state
            textStorage.replaceCharacters(in: NSRange(location: 0, length: textStorage.length), with: lastValidText)
            
            // Move cursor to end
            let endPosition = lastValidText.count
            textView.setSelectedRange(NSRange(location: endPosition, length: 0))
            
            // Provide feedback (subtle shake or beep)
            provideFeedback()
            
            return
        }
        
        // Check if the text still has required prefix
        if !currentText.hasPrefix(FreewriteConstants.headerString) {
            let correctedText = FreewriteConstants.headerString + currentText
            textStorage.replaceCharacters(in: NSRange(location: 0, length: textStorage.length), with: correctedText)
            
            // Adjust cursor position
            let newPosition = currentRange.location + FreewriteConstants.headerString.count
            textView.setSelectedRange(NSRange(location: newPosition, length: 0))
        }
        
        // Update last valid text if this is a valid forward addition
        if currentText.count >= lastValidText.count {
            lastValidText = currentText
            onTextChange(currentText)
        }
    }
    
    private func isEditingPreviousContent(current: String, previous: String, cursorPosition: Int) -> Bool {
        // If text is shorter, user deleted something
        if current.count < previous.count {
            return true
        }
        
        // If cursor is not at the end and text changed, user is editing middle
        if cursorPosition < previous.count && current != previous {
            return true
        }
        
        // Check if the existing text was modified (not just appended to)
        if current.count > previous.count {
            let commonLength = min(current.count, previous.count)
            let currentPrefix = String(current.prefix(commonLength))
            let previousPrefix = String(previous.prefix(commonLength))
            
            if currentPrefix != previousPrefix {
                return true
            }
        }
        
        return false
    }
    
    private func provideFeedback() {
        // Subtle system beep
        NSSound.beep()
        
        // Optional: Add a subtle visual indicator
        // Could flash the border or show a brief message
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
            let currentSelection = textView.selectedRange()
            textView.string = text
            
            // Restore selection if valid
            let newLength = text.count
            if currentSelection.location <= newLength {
                textView.setSelectedRange(NSRange(
                    location: min(currentSelection.location, newLength),
                    length: 0
                ))
            }
        }
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
        
        // Block arrow keys when they would move cursor backwards for editing
        if event.keyCode == 123 || event.keyCode == 124 { // Left or Right arrows
            let currentSelection = selectedRange()
            if event.keyCode == 123 && currentSelection.location > 0 { // Left arrow
                // Only allow if at the very end of text
                if currentSelection.location < string.count {
                    NSSound.beep()
                    return
                }
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
        // Allow paste only at the end of text
        let currentSelection = selectedRange()
        if currentSelection.location == string.count {
            super.keyDown(with: event)
        } else {
            NSSound.beep()
        }
    }
}