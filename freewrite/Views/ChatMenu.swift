import SwiftUI

struct ChatMenu: View {
    let text: String
    @Binding var didCopyPrompt: Bool
    @Binding var showingChatMenu: Bool
    
    let onOpenChatGPT: () -> Void
    let onOpenClaude: () -> Void
    let onCopyPrompt: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            let _ = text.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if text.count < 350 {
                Text("Please free write for at minimum 5 minutes first. Then click this. Trust.")
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                    .frame(width: 250)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            } else {
                Button(action: {
                    showingChatMenu = false
                    onOpenChatGPT()
                }) {
                    Text("ChatGPT")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                .foregroundColor(.primary)
                
                Divider()
                
                Button(action: {
                    showingChatMenu = false
                    onOpenClaude()
                }) {
                    Text("Claude")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                .foregroundColor(.primary)
                
                Divider()
                
                Button(action: {
                    onCopyPrompt()
                    didCopyPrompt = true
                }) {
                    Text(didCopyPrompt ? "Copied!" : "Copy Prompt")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                .foregroundColor(.primary)
            }
        }
        .frame(minWidth: 120, maxWidth: 250)
        .background(FreewriteColors.popoverBackground)
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.1), radius: 4, y: 2)
        .onChange(of: showingChatMenu) { _, newValue in
            if !newValue {
                didCopyPrompt = false
            }
        }
    }
}