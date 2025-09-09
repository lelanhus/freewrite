import SwiftUI
@testable import Freewrite

// MARK: - Test Overlay Components for Visual Regression Testing

/// Simple progress overlay for snapshot testing
struct ProgressOverlay: View {
    let message: String
    let progress: Double
    
    var body: some View {
        VStack(spacing: 12) {
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .frame(width: 200)
            
            Text("\(Int(progress * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 8)
    }
}

/// Simple error overlay for snapshot testing
struct ErrorOverlay: View {
    let title: String
    let message: String
    let onRetry: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("×") {
                    onDismiss()
                }
                .font(.title2)
                .foregroundColor(.secondary)
                .buttonStyle(.plain)
            }
            
            HStack {
                Spacer()
                
                Button("Retry") {
                    onRetry()
                }
                .buttonStyle(.borderedProminent)
                
                Button("Dismiss") {
                    onDismiss()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 12)
        .frame(maxWidth: 350)
    }
}

// MARK: - Preview Support

#Preview("Progress Overlay") {
    ProgressOverlay(message: "Saving your thoughts...", progress: 0.75)
        .padding()
        .background(Color.gray.opacity(0.1))
}

#Preview("Error Overlay") {
    ErrorOverlay(
        title: "Save Failed",
        message: "Could not save your writing session. Please try again.",
        onRetry: {},
        onDismiss: {}
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}