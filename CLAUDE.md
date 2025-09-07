# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## App Purpose & Philosophy

**Freewrite is a minimal thinking tool, NOT a writing application.** 

The app implements the freewriting methodology developed in 1973 - continuous writing for a set time without editing, designed to bypass the inner critic and unlock authentic thoughts. It's digital therapy software for self-discovery and problem-solving.

**Core Philosophy:**
- **"Invisible until needed"** - Features must disappear during use or enhance thinking
- **Deliberate constraints** - No backspace, timed sessions, minimal UI by design
- **Thinking amplifier** - Not for polished writing, but for mental breakthroughs
- **Post-session reflection** - AI integration for analyzing raw thoughts, not writing assistance

**What it deliberately ISN'T:**
- Text editor or note-taking app
- Writing software with formatting/themes
- Productivity tool with analytics
- Document management system

## Development Commands

**Project Management (XcodeGen):**
- `make generate` - Generate Xcode project from YAML
- `make build` - Build the project  
- `make check` - Build and run unit tests (development verification)
- `make clean` - Remove generated files

**Setup:**
- New developers: Install XcodeGen (`brew install xcodegen`), then `make generate`

## Modern Architecture (Swift 6+)

**Minimal Feature Structure:**
```
Sources/
├── App/                    # App entry point
│   ├── freewriteApp.swift  # Main app with DI configuration
│   └── ContentView.swift   # Primary thinking interface
├── Core/                   # Essential business logic only
│   ├── DependencyContainer/# DI system
│   ├── Models/            # DTOs, Constants, Errors
│   └── Services/          # Core services only
└── Features/              # Minimal feature modules
    └── Writing/           # Core thinking interface only
```

**Core Services (Essential Only):**
- **FileManagementService**: Invisible auto-save, crash recovery
- **FreewriteTimer**: Pressure-creating constraint tool
- **AIIntegrationService**: Post-session reflection partner
- **PDFExportService**: Basic export for completed sessions

## Key Implementation Principles

**Timer as Thinking Tool:**
- Creates urgency to bypass writer's block
- Forces continuous output without self-editing
- Scroll-based adjustment (no UI interruption)
- Audio completion cues for natural flow

**Constraint Enforcement:**
- No backspace/delete key functionality
- No copy/paste editing of previous text
- Text selection limitations to prevent editing
- Forward-momentum only writing

**Invisible Infrastructure:**
- Zero-latency background saves
- Crash recovery without user awareness
- Memory optimization for long sessions
- Never interrupt flow state

**AI Integration Philosophy:**
- Only after sessions complete (350+ chars)
- For reflection, not writing assistance
- Smart URL generation with clipboard fallback
- Prompts designed for self-discovery

## Swift 6 Concurrency Guidelines

**Actor Isolation:**
- All ViewModels: `@MainActor @Observable final class`
- Service protocols: `@MainActor protocol ServiceProtocol: Sendable`
- File operations: Properly isolated async methods
- Timer operations: Main actor for UI integration

**Sendable Compliance:**
- DTOs: All `Sendable` structs with immutable data
- Services: `@unchecked Sendable` where thread-safety is ensured
- Containers: NSLock-based thread safety in ServiceRegistry

## Development Guidelines

**Feature Development Rules:**
1. **Does this help thinking?** If no, don't build it
2. **Does this add UI complexity?** If yes, reconsider
3. **Would the author approve?** Honor the "dumb little app" philosophy
4. **Does it create choices?** Avoid feature creep and decision paralysis

**Code Quality:**
- Files < 350 lines, functions < 45 lines (Google Swift Style Guide)
- Swift 6 strict concurrency compliance required
- Protocol-based architecture for testability
- Comprehensive error handling with specific error types

**Core Constraints to Preserve:**
- `\n\n` prefix requirement for all text (formatting constraint)
- UUID-based entry identification system
- Auto-save with zero user awareness
- 15-minute default sessions, 45-minute maximum
- No spellcheck, markdown, or formatting features

**Success Metrics:**
- User forgets they're using software during sessions
- Zero interruptions to the thinking process
- Perfect reliability - never lose a thought
- Seamless AI handoff for post-session reflection
- Fast, invisible operation under all conditions

## Forbidden Features

**Do NOT implement:**
- Font selection systems or theme customization
- Writing analytics, word count targets, or productivity metrics
- Advanced settings or preference systems  
- Complex UI components or animations
- Document organization or management features
- Spell check, grammar check, or text formatting
- Rich text editing or markdown support

The app should feel like **digital paper with a timer** - simple, reliable, invisible until the thinking is done.

## Project Management

**XcodeGen Configuration:**
- `project.yml` - Single source of truth for project structure
- Automatic Swift Package Manager integration
- No `.xcodeproj` in version control (generated)
- Minimal target organization focused on core functionality