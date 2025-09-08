# Makefile - Claude Code Development Optimized
.PHONY: generate build test-unit test-integration test-ui check clean help

.DEFAULT_GOAL := help

## Generate: Generate Xcode project from YAML
generate:
	@echo "🏗️  Generating Xcode project..."
	@xcodegen generate
	@echo "✅ Project generated"

## Build: Build the project
build: generate
	@echo "🔨 Building project..."
	@xcodebuild build -project Freewrite.xcodeproj -scheme Freewrite -quiet

## Test-unit: Run unit tests only (fast)
test-unit: generate
	@echo "🧪 Running unit tests..."
	@xcodebuild test \
		-project Freewrite.xcodeproj \
		-scheme Freewrite \
		-destination 'platform=macOS' \
		-only-testing FreewriteTests \
		-quiet

## Test-integration: Run integration tests
test-integration: generate
	@echo "🔄 Running integration tests..."
	@xcodebuild test \
		-project Freewrite.xcodeproj \
		-scheme Freewrite \
		-destination 'platform=macOS' \
		-only-testing FreewriteIntegrationTests \
		-quiet

## Test-ui: Run UI tests
test-ui: generate
	@echo "🖥️  Running UI tests..."
	@xcodebuild test \
		-project Freewrite.xcodeproj \
		-scheme Freewrite \
		-destination 'platform=macOS' \
		-only-testing FreewriteUITests \
		-quiet

## Check: Build and run unit tests (development verification)
check: build test-unit
	@echo "✅ Project healthy"

## Clean: Remove generated files
clean:
	@echo "🧹 Cleaning..."
	@rm -rf Freewrite.xcodeproj .xcodegen DerivedData
	@echo "✅ Cleaned"

## Help: Show available commands
help:
	@echo "📋 Available commands:"
	@grep -E '^## [A-Za-z-]+:.*' $(MAKEFILE_LIST) | \
		sed 's/## \([A-Za-z-]*\): \(.*\)/  \1: \2/' | \
		sort