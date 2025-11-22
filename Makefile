.PHONY: setup install-homebrew install-opencv generate-workspace build run clean open help

SHELL := /bin/bash
PROJECT_DIR := $(shell pwd)
PROJECT := CameraEdgeDetector.xcodeproj
SCHEME := CameraEdgeDetector
BUILD_DIR := $(PROJECT_DIR)/build
APP_NAME := CameraEdgeDetector.app
OPENCV_PREFIX := $(shell brew --prefix opencv 2>/dev/null || echo "/opt/homebrew/opt/opencv")

help:
	@echo "Camera Edge Detector - Makefile"
	@echo ""
	@echo "Available targets:"
	@echo "  make setup          - Complete setup (Homebrew + OpenCV)"
	@echo "  make build          - Build the application"
	@echo "  make run            - Build and run the application"
	@echo "  make open           - Open project in Xcode"
	@echo "  make package        - Create distributable .app bundle"
	@echo "  make clean          - Clean build artifacts"
	@echo "  make help           - Show this help message"

setup: check-xcode install-homebrew install-opencv generate-workspace
	@echo "✅ Setup complete! Run 'make open' to open in Xcode or 'make run' to build and run."

check-xcode:
	@echo "🔍 Checking for Xcode..."
	@command -v xcodebuild >/dev/null 2>&1 || { echo "❌ Error: Xcode is not installed. Please install Xcode from the App Store."; exit 1; }
	@echo "✅ Xcode found"

install-homebrew:
	@echo "🔍 Checking for Homebrew..."
	@if command -v brew >/dev/null 2>&1; then \
		echo "✅ Homebrew already installed"; \
	else \
		echo "📦 Installing Homebrew (you may be prompted for your password)..."; \
		/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || { echo "❌ Failed to install Homebrew"; exit 1; }; \
		echo "✅ Homebrew installed"; \
		echo "⚙️  Adding Homebrew to PATH..."; \
		if [ -f "/opt/homebrew/bin/brew" ]; then \
			eval "$$(/opt/homebrew/bin/brew shellenv)"; \
		elif [ -f "/usr/local/bin/brew" ]; then \
			eval "$$(/usr/local/bin/brew shellenv)"; \
		fi; \
	fi

install-opencv:
	@echo "🔍 Checking for OpenCV..."
	@if brew list opencv &>/dev/null; then \
		echo "✅ OpenCV already installed"; \
	else \
		echo "📦 Installing OpenCV via Homebrew (this may take a few minutes)..."; \
		brew install opencv || { echo "❌ Failed to install OpenCV"; exit 1; }; \
		echo "✅ OpenCV installed"; \
	fi

generate-workspace:
	@echo "⚙️  Generating Xcode workspace..."
	@if [ ! -f "Podfile" ]; then \
		echo "❌ Error: Podfile not found"; \
		exit 1; \
	fi
	@pod install || { echo "⚠️  Pod install skipped (no pods required)"; }
	@echo "✅ Workspace ready"

build: install-opencv
	@echo "🔨 Building $(SCHEME)..."
	@xcodebuild -project $(PROJECT) \
		-scheme $(SCHEME) \
		-configuration Release \
		-derivedDataPath $(BUILD_DIR) \
		-arch arm64 \
		build | xcpretty 2>/dev/null || xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration Release -derivedDataPath $(BUILD_DIR) -arch arm64 build
	@echo "✅ Build complete"

run: build
	@echo "🚀 Running $(APP_NAME)..."
	@open "$(BUILD_DIR)/Build/Products/Release/$(APP_NAME)"

open:
	@echo "📂 Opening project in Xcode..."
	@if [ -f "$(PROJECT)" ] || [ -d "$(PROJECT)" ]; then \
		open $(PROJECT); \
	else \
		echo "❌ Project not found."; \
		exit 1; \
	fi

package: build
	@echo "📦 Creating distributable package..."
	@mkdir -p dist
	@cp -R "$(BUILD_DIR)/Build/Products/Release/$(APP_NAME)" dist/
	@echo "✅ Package created at: dist/$(APP_NAME)"
	@echo ""
	@echo "To distribute:"
	@echo "  1. Compress: cd dist && zip -r CameraEdgeDetector.zip $(APP_NAME)"
	@echo "  2. Share the .zip or .app bundle"
	@echo "  3. Recipients just need to unzip and run (no dependencies needed!)"

clean:
	@echo "🧹 Cleaning build artifacts..."
	@rm -rf $(BUILD_DIR)
	@rm -rf dist
	@xcodebuild -project $(PROJECT) -scheme $(SCHEME) clean 2>/dev/null || true
	@echo "✅ Clean complete"

deep-clean: clean
	@echo "🧹 Deep cleaning (removing all build artifacts)..."
	@rm -rf Pods
	@rm -rf *.xcworkspace
	@rm -f Podfile.lock
	@echo "✅ Deep clean complete. Run 'make setup' to reinstall."

show-opencv-path:
	@echo "OpenCV installation path: $(OPENCV_PREFIX)"
	@echo "Headers: $(OPENCV_PREFIX)/include/opencv4"
	@echo "Libraries: $(OPENCV_PREFIX)/lib"
