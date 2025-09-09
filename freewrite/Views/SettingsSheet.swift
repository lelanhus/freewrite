import SwiftUI

/// Minimal, beautiful settings sheet that respects the app's philosophy
struct SettingsSheet: View {
    @Bindable var preferences: UserPreferences
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Preferences")
                    .font(.title2)
                    .fontWeight(.light)
                
                Spacer()
                
                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.title2)
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 10)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Progressive disclosure based on user experience
                    let availableSettings = preferences.getAvailableSettings()
                    
                    if availableSettings.contains(where: { $0.category == .essential }) {
                        essentialSettings
                    }
                    
                    if availableSettings.contains(where: { $0.category == .methodology }) {
                        methodologySettings
                    }
                    
                    if availableSettings.contains(where: { $0.category == .ai }) {
                        aiSettings
                    }
                    
                    // Reset option (always available)
                    resetSection
                }
            }
        }
        .padding(24)
        .frame(width: 400, height: 500)
        .background(.regularMaterial)
        .cornerRadius(16)
        .shadow(radius: 20)
    }
    
    // MARK: - Settings Sections
    
    @ViewBuilder
    private var essentialSettings: some View {
        SettingsSection("Session") {
            VStack(spacing: 12) {
                // Timer duration
                HStack {
                    Text("Default Timer")
                    Spacer()
                    Picker("", selection: $preferences.defaultTimerDuration) {
                        ForEach([300, 600, 900, 1200, 1500, 1800, 2700], id: \.self) { seconds in
                            Text("\(seconds/60) min").tag(seconds)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 100)
                }
                
                // Timer sound
                HStack {
                    Text("Completion Sound")
                    Spacer()
                    Picker("", selection: $preferences.timerSound) {
                        ForEach(UserPreferences.TimerSound.allCases, id: \.self) { sound in
                            Text(sound.rawValue).tag(sound)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 120)
                }
                
                // Auto-start timer
                if preferences.sessionCount >= 3 {
                    Toggle("Auto-start timer", isOn: $preferences.autoStartTimer)
                }
            }
        }
    }
    
    @ViewBuilder  
    private var methodologySettings: some View {
        SettingsSection("Writing Constraints") {
            VStack(spacing: 12) {
                // Constraint level
                VStack(alignment: .leading, spacing: 8) {
                    Text("Constraint Level")
                        .font(.subheadline)
                    
                    Picker("", selection: $preferences.constraintLevel) {
                        ForEach(UserPreferences.ConstraintLevel.allCases, id: \.self) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    Text(constraintLevelDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Backspace grace period (only for gentle mode)
                if preferences.constraintLevel == .gentle {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Typo Grace Period")
                            Spacer()
                            Text("\(String(format: "%.1f", preferences.backspaceGracePeriod))s")
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(
                            value: $preferences.backspaceGracePeriod,
                            in: 0...3,
                            step: 0.5
                        )
                    }
                }
                
                // Minimum session length
                if preferences.sessionCount >= 10 {
                    HStack {
                        Text("Minimum Session")
                        Spacer()
                        Picker("", selection: $preferences.minimumSessionLength) {
                            Text("None").tag(0)
                            Text("5 min").tag(300)
                            Text("10 min").tag(600)
                            Text("15 min").tag(900)
                        }
                        .pickerStyle(.menu)
                        .frame(width: 80)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var aiSettings: some View {
        SettingsSection("AI Analysis") {
            VStack(spacing: 12) {
                // Analysis style
                HStack {
                    Text("Analysis Style")
                    Spacer()
                    Picker("", selection: $preferences.analysisStyle) {
                        ForEach(UserPreferences.AIAnalysisStyle.allCases, id: \.self) { style in
                            Text(style.rawValue).tag(style)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 100)
                }
                
                // Auto-open analysis
                Toggle("Auto-open analysis", isOn: $preferences.autoOpenAnalysis)
                
                // Privacy mode
                if preferences.sessionCount >= 15 {
                    Toggle("Privacy mode", isOn: $preferences.privacyMode)
                        .help("Never automatically open external URLs")
                }
            }
        }
    }
    
    @ViewBuilder
    private var resetSection: some View {
        VStack(spacing: 8) {
            Button {
                preferences.resetToDefaults()
            } label: {
                Text("Reset to Methodology Defaults")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            
            Text("Based on Peter Elbow's 1973 freewriting research")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.top, 8)
    }
    
    // MARK: - Helper Properties
    
    private var constraintLevelDescription: String {
        switch preferences.constraintLevel {
        case .gentle:
            return "Softer constraints for emotional writing and recovery"
        case .standard:
            return "Classic freewriting methodology (recommended)"
        case .strict:
            return "Maximum constraints for advanced practitioners"
        }
    }
}

// MARK: - Settings Section Component

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontWeight(.medium)
            
            content
                .padding(.leading, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    SettingsSheet(
        preferences: UserPreferences(),
        isPresented: .constant(true)
    )
}