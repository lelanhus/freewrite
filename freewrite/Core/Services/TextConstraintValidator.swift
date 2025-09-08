import Foundation
import AppKit

/// Validation results for text editing operations
struct TextConstraintValidationResult {
    let isValid: Bool
    let correctedText: String?
    let shouldProvideFeedback: Bool
    let cursorPosition: Int?
    
    static let valid = TextConstraintValidationResult(
        isValid: true,
        correctedText: nil,
        shouldProvideFeedback: false,
        cursorPosition: nil
    )
    
    static func invalid(
        correctedText: String,
        cursorPosition: Int? = nil,
        shouldProvideFeedback: Bool = true
    ) -> TextConstraintValidationResult {
        return TextConstraintValidationResult(
            isValid: false,
            correctedText: correctedText,
            shouldProvideFeedback: shouldProvideFeedback,
            cursorPosition: cursorPosition
        )
    }
}

/// Core text constraint validation logic for freewriting
struct TextConstraintValidator {
    
    /// Validates if a text change is allowed according to freewriting rules
    /// - Parameters:
    ///   - currentText: The new text state
    ///   - previousText: The previous valid text state
    ///   - cursorPosition: Current cursor position
    /// - Returns: Validation result with correction instructions
    static func validateTextChange(
        currentText: String,
        previousText: String,
        cursorPosition: Int
    ) -> TextConstraintValidationResult {
        
        // Check if user is trying to edit previous content
        if isEditingPreviousContent(
            current: currentText,
            previous: previousText,
            cursorPosition: cursorPosition
        ) {
            return .invalid(
                correctedText: previousText,
                cursorPosition: previousText.count,
                shouldProvideFeedback: true
            )
        }
        
        // Check if the text still has required prefix
        if !currentText.hasPrefix(FreewriteConstants.headerString) {
            let correctedText = FreewriteConstants.headerString + currentText
            let newCursorPosition = cursorPosition + FreewriteConstants.headerString.count
            
            return .invalid(
                correctedText: correctedText,
                cursorPosition: newCursorPosition,
                shouldProvideFeedback: false
            )
        }
        
        return .valid
    }
    
    /// Validates a simple text change for basic constraint enforcement
    /// - Parameters:
    ///   - newText: The proposed new text
    ///   - currentText: The current text state
    /// - Returns: Validation result with processed text
    static func validateSimpleTextChange(
        newText: String,
        currentText: String
    ) -> TextConstraintValidationResult {
        
        // Only apply constraints for actual deletions/edits, allow forward typing
        let currentTextContent = currentText.dropFirst(2) // Content after "\n\n"
        let newTextContent = newText.dropFirst(2) // Content after "\n\n"
        
        // Check if user is trying to delete/edit existing content
        if newText.count >= 2 && newTextContent.count < currentTextContent.count {
            return .invalid(
                correctedText: currentText,
                shouldProvideFeedback: true
            )
        }
        
        // Validate text length constraints to prevent performance issues
        if let lengthValidation = validateTextLength(newText) {
            return lengthValidation
        }
        
        // Ensure the text always starts with two newlines
        let processedText: String
        if !newText.hasPrefix("\n\n") {
            processedText = "\n\n" + newText.trimmingCharacters(in: .newlines)
        } else {
            processedText = newText
        }
        
        return .invalid(
            correctedText: processedText,
            shouldProvideFeedback: false
        )
    }
    
    /// Validates text length to prevent performance issues
    /// - Parameter text: The text to validate
    /// - Returns: ValidationResult if length constraints violated, nil if valid
    static func validateTextLength(_ text: String) -> TextConstraintValidationResult? {
        let textLength = text.count
        
        // Hard limit - prevent extremely long texts that could cause performance issues
        if textLength > FreewriteConstants.maximumTextLength {
            print("WARNING: Text length (\(textLength)) exceeds maximum (\(FreewriteConstants.maximumTextLength))")
            return .invalid(
                correctedText: String(text.prefix(FreewriteConstants.maximumTextLength)),
                shouldProvideFeedback: true
            )
        }
        
        // Soft warning - log performance warning but allow
        if textLength > FreewriteConstants.warningTextLength {
            print("INFO: Large text detected (\(textLength) characters) - may impact performance")
        }
        
        return nil // Length is acceptable
    }
    
    /// Provides user feedback for constraint violations
    static func provideFeedback() {
        NSSound.beep()
    }
    
    /// Configures a text view for freewriting constraints
    /// - Parameter textView: The NSTextView to configure
    @MainActor
    static func configureTextViewForFreewriting(_ textView: NSTextView) {
        // Disable spell checking and grammar checking
        textView.isContinuousSpellCheckingEnabled = false
        textView.isGrammarCheckingEnabled = false
        
        // Disable smart quotes and other automatic text replacement
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        
        // Disable undo to prevent constraint bypassing
        textView.allowsUndo = false
    }
    
    // MARK: - Private Helpers
    
    private static func isEditingPreviousContent(
        current: String,
        previous: String,
        cursorPosition: Int
    ) -> Bool {
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
}