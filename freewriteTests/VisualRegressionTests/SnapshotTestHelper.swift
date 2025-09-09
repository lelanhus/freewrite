import SwiftUI
import AppKit
import Foundation
@testable import Freewrite

/// Simple snapshot testing helper for visual regression testing
@MainActor
struct SnapshotTestHelper {
    
    // MARK: - Configuration
    
    private static let snapshotsDirectory = "freewriteTests/VisualRegressionTests/Snapshots/"
    private static let referenceDirectory = "Reference/"
    private static let diffDirectory = "Diff/"
    
    // MARK: - Snapshot Testing
    
    /// Captures a snapshot of a SwiftUI view and compares it to reference
    static func verifySnapshot<Content: View>(
        of view: Content,
        named name: String,
        size: CGSize = CGSize(width: 400, height: 300)
    ) throws -> Bool {
        let renderer = ImageRenderer(content: view.frame(width: size.width, height: size.height))
        renderer.scale = 2.0 // Retina scale for crisp images
        
        guard let currentImage = renderer.nsImage else {
            throw SnapshotError.renderingFailed("Failed to render view to NSImage")
        }
        
        let referenceImagePath = getSnapshotPath(name: name, directory: referenceDirectory)
        let currentImagePath = getSnapshotPath(name: name, directory: "Current/")
        
        // Save current image
        try saveImage(currentImage, to: currentImagePath)
        
        // Check if reference exists
        if FileManager.default.fileExists(atPath: referenceImagePath) {
            guard let referenceImage = NSImage(contentsOfFile: referenceImagePath) else {
                throw SnapshotError.referenceMissing("Could not load reference image at \(referenceImagePath)")
            }
            
            // Compare images
            let imagesMatch = compareImages(referenceImage, currentImage)
            
            if !imagesMatch {
                // Generate diff image for debugging
                let diffImagePath = getSnapshotPath(name: name, directory: diffDirectory)
                try generateDiffImage(reference: referenceImage, current: currentImage, diffPath: diffImagePath)
                throw SnapshotError.mismatch("Images don't match. Diff saved to: \(diffImagePath)")
            }
            
            return true
        } else {
            // No reference exists - save current as reference for future runs
            try saveImage(currentImage, to: referenceImagePath)
            print("📸 Reference snapshot saved for '\(name)' at \(referenceImagePath)")
            return true
        }
    }
    
    /// Simple snapshot verification for layout testing (no pixel-perfect comparison)
    static func verifyLayout<Content: View>(
        of view: Content,
        named name: String,
        size: CGSize = CGSize(width: 400, height: 300)
    ) throws -> Bool {
        // For now, just verify the view can be rendered without crashing
        let renderer = ImageRenderer(content: view.frame(width: size.width, height: size.height))
        renderer.scale = 1.0
        
        guard let image = renderer.nsImage else {
            throw SnapshotError.renderingFailed("Failed to render view for layout test")
        }
        
        // Basic sanity checks
        guard image.size.width > 0 && image.size.height > 0 else {
            throw SnapshotError.renderingFailed("Rendered image has zero dimensions")
        }
        
        return true
    }
    
    // MARK: - Helper Methods
    
    private static func getSnapshotPath(name: String, directory: String) -> String {
        let testBundle = Bundle(for: NSClassFromString("FreewriteTests.SnapshotTests") ?? NSObject.self)
        let bundlePath = testBundle.bundlePath
        let projectPath = URL(fileURLWithPath: bundlePath).deletingLastPathComponent().deletingLastPathComponent().path
        
        let fullDirectory = "\(projectPath)/\(snapshotsDirectory)\(directory)"
        
        // Ensure directory exists
        try? FileManager.default.createDirectory(atPath: fullDirectory, withIntermediateDirectories: true)
        
        return "\(fullDirectory)\(name).png"
    }
    
    private static func saveImage(_ image: NSImage, to path: String) throws {
        guard let tiffData = image.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            throw SnapshotError.savingFailed("Failed to convert image to PNG data")
        }
        
        try pngData.write(to: URL(fileURLWithPath: path))
    }
    
    private static func compareImages(_ reference: NSImage, _ current: NSImage) -> Bool {
        // Simple size comparison first
        guard reference.size == current.size else { return false }
        
        // Get image data for pixel comparison
        guard let refTiff = reference.tiffRepresentation,
              let refBitmap = NSBitmapImageRep(data: refTiff),
              let currentTiff = current.tiffRepresentation,
              let currentBitmap = NSBitmapImageRep(data: currentTiff) else {
            return false
        }
        
        // Compare pixel data
        let refData = refBitmap.bitmapData
        let currentData = currentBitmap.bitmapData
        let bytesPerPixel = refBitmap.bitsPerPixel / 8
        let totalBytes = Int(refBitmap.pixelsWide * refBitmap.pixelsHigh) * bytesPerPixel
        
        // Allow for minor pixel differences (anti-aliasing, rendering variations)
        let tolerance = 5 // Allow up to 5/255 difference per channel
        var differences = 0
        
        for i in 0..<totalBytes {
            let refValue = Int(refData?[i] ?? 0)
            let currentValue = Int(currentData?[i] ?? 0)
            
            if abs(refValue - currentValue) > tolerance {
                differences += 1
            }
        }
        
        // Allow up to 1% pixel differences
        let maxAllowedDifferences = totalBytes / 100
        return differences <= maxAllowedDifferences
    }
    
    private static func generateDiffImage(reference: NSImage, current: NSImage, diffPath: String) throws {
        // For now, just save both images side by side as a simple diff
        let combinedWidth = reference.size.width + current.size.width
        let maxHeight = max(reference.size.height, current.size.height)
        
        let combinedImage = NSImage(size: CGSize(width: combinedWidth, height: maxHeight))
        combinedImage.lockFocus()
        
        // Draw reference on left
        reference.draw(in: CGRect(origin: .zero, size: reference.size))
        
        // Draw current on right
        current.draw(in: CGRect(origin: CGPoint(x: reference.size.width, y: 0), size: current.size))
        
        combinedImage.unlockFocus()
        
        try saveImage(combinedImage, to: diffPath)
    }
}

// MARK: - Error Types

enum SnapshotError: LocalizedError {
    case renderingFailed(String)
    case referenceMissing(String)
    case mismatch(String)
    case savingFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .renderingFailed(let message):
            return "Rendering failed: \(message)"
        case .referenceMissing(let message):
            return "Reference missing: \(message)"
        case .mismatch(let message):
            return "Snapshot mismatch: \(message)"
        case .savingFailed(let message):
            return "Saving failed: \(message)"
        }
    }
}

// MARK: - Test View Helpers

extension SnapshotTestHelper {
    
    /// Creates a test ContentView with controlled state for consistent snapshots
    static func createTestContentView() -> some View {
        ContentView()
            .frame(width: 800, height: 600)
            .environment(\.colorScheme, .light) // Force light mode for consistency
    }
    
    /// Creates a test NavigationBar with specific state
    static func createTestNavigationBar(timerRunning: Bool = false, fontSize: Int = 18) -> some View {
        let typographyState = TypographyStateManager()
        let hoverState = HoverStateManager()
        let uiState = UIStateManager()
        let timer = FreewriteTimer()
        let disclosureManager = ShortcutDisclosureManager()
        
        typographyState.updateFontSize(CGFloat(fontSize))
        if timerRunning {
            timer.start()
        }
        
        return NavigationBar(
            typographyState: typographyState,
            hoverState: hoverState,
            uiState: uiState,
            disclosureManager: disclosureManager,
            text: .constant("Test content"),
            timerService: timer,
            colorScheme: .light,
            canUseChat: true,
            onNewEntry: {},
            onOpenChatGPT: {},
            onOpenClaude: {},
            onCopyPrompt: {},
            onColorSchemeToggle: {}
        )
        .frame(width: 600, height: 44)
        .environment(\.colorScheme, .light)
    }
}