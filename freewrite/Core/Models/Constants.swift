import Foundation
import SwiftUI

// MARK: - Application Constants
enum FreewriteConstants {
    // Timer
    static let defaultTimerDuration: Int = 900 // 15 minutes in seconds
    static let maxTimerDuration: Int = 2700 // 45 minutes in seconds
    static let timerStepSize: Int = 5 // 5 minute increments
    
    // Text Editor
    static let maxTextWidth: CGFloat = 650
    static let minimumTextLength: Int = 350
    static let headerString: String = "\n\n"
    
    // UI Layout
    static let sidebarWidth: CGFloat = 200
    static let entryHeight: CGFloat = 40
    static let navHeight: CGFloat = 68
    
    // Window
    static let defaultWindowWidth: CGFloat = 1100
    static let defaultWindowHeight: CGFloat = 600
    
    // URLs
    static let maxURLLength: Int = 6000
}

// MARK: - Font Constants
enum FontConstants {
    static let defaultFont: String = "Lato-Regular"
    static let defaultSize: CGFloat = 18
    
    static let availableFonts: [String] = [
        "Lato-Regular",
        "Arial", 
        ".AppleSystemUIFont",
        "Times New Roman"
    ]
    
    static let availableSizes: [CGFloat] = [16, 18, 20, 22, 24, 26]
}

// MARK: - Placeholder Constants
enum PlaceholderConstants {
    static let options: [String] = [
        "\n\nBegin writing",
        "\n\nPick a thought and go",
        "\n\nStart typing",
        "\n\nWhat's on your mind",
        "\n\nJust start",
        "\n\nType your first thought",
        "\n\nStart with one sentence",
        "\n\nJust say it"
    ]
    
    static func random() -> String {
        options.randomElement() ?? options[0]
    }
}

// MARK: - File System Constants
enum FileSystemConstants {
    static let documentsDirectoryName: String = "Freewrite"
    static let fileExtension: String = "md"
    static let welcomeFileName: String = "default.md"
}

// MARK: - AI Integration Constants  
enum AIConstants {
    static let chatGPTBaseURL: String = "https://chat.openai.com/?m="
    static let claudeBaseURL: String = "https://claude.ai/new?q="
    
    static let defaultPrompt: String = """
    below is my journal entry. wyt? talk through it with me like a friend. don't therpaize me and give me a whole breakdown, don't repeat my thoughts with headings. really take all of this, and tell me back stuff truly as if you're an old homie.
    
    Keep it casual, dont say yo, help me make new connections i don't see, comfort, validate, challenge, all of it. dont be afraid to say a lot. format with markdown headings if needed.

    do not just go through every single thing i say, and say it back to me. you need to proccess everythikng is say, make connections i don't see it, and deliver it all back to me as a story that makes me feel what you think i wanna feel. thats what the best therapists do.

    ideally, you're style/tone should sound like the user themselves. it's as if the user is hearing their own tone but it should still feel different, because you have different things to say and don't just repeat back they say.

    else, start by saying, "hey, thanks for showing me this. my thoughts:"
        
    my entry:
    """
    
    static let claudePrompt: String = """
    Take a look at my journal entry below. I'd like you to analyze it and respond with deep insight that feels personal, not clinical.
    Imagine you're not just a friend, but a mentor who truly gets both my tech background and my psychological patterns. I want you to uncover the deeper meaning and emotional undercurrents behind my scattered thoughts.
    Keep it casual, dont say yo, help me make new connections i don't see, comfort, validate, challenge, all of it. dont be afraid to say a lot. format with markdown headings if needed.
    Use vivid metaphors and powerful imagery to help me see what I'm really building. Organize your thoughts with meaningful headings that create a narrative journey through my ideas.
    Don't just validate my thoughts - reframe them in a way that shows me what I'm really seeking beneath the surface. Go beyond the product concepts to the emotional core of what I'm trying to solve.
    Be willing to be profound and philosophical without sounding like you're giving therapy. I want someone who can see the patterns I can't see myself and articulate them in a way that feels like an epiphany.
    Start with 'hey, thanks for showing me this. my thoughts:' and then use markdown headings to structure your response.

    Here's my journal entry:
    """
}