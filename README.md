# Camera Edge Detector

Real-time edge detection using your Mac's built-in camera with OpenCV and Swift.

## Quick Start (Automated Setup)

```bash
make setup    # Installs Homebrew + OpenCV automatically
make run      # Build and run the app
```

Or manually:
```bash
make help     # See all available commands
```

That's it! The Makefile will:
- Install Homebrew if not present (requires password)
- Install OpenCV via Homebrew
- Configure the Xcode project
- Build and run

## Manual Setup Instructions

1. **Install Homebrew** (if not already installed):
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

2. **Install OpenCV**:
   ```bash
   brew install opencv
   ```

3. **Open the project in Xcode**:
   ```bash
   open CameraEdgeDetector.xcodeproj
   ```

4. **Build and Run**:
   - Select your Mac as the target device
   - Press Cmd+R to build and run
   - Grant camera permissions when prompted

## Distribution

The built application is **fully self-contained** with all dependencies embedded. To distribute:

```bash
make package
```

This creates a standalone `CameraEdgeDetector.app` in the `dist/` folder that includes:
- All OpenCV frameworks (embedded in the .app bundle)
- All dependencies
- No installation required on the recipient's Mac

Recipients can simply:
1. Download/unzip the app
2. Drag to Applications folder
3. Run (may need to right-click → Open on first launch due to Gatekeeper)
4. Grant camera permissions when prompted

## Available Make Commands

- `make setup` - Complete automated setup (Homebrew + OpenCV)
- `make build` - Build the application
- `make run` - Build and run the application
- `make open` - Open project in Xcode
- `make package` - Create distributable .app bundle
- `make clean` - Clean build artifacts
- `make show-opencv-path` - Display OpenCV installation paths

## Features

- Real-time video capture from built-in camera
- Canny edge detection using OpenCV
- Edges displayed in green overlay
- SwiftUI-based interface
- Runs natively on Apple Silicon (M1/M2/M3) and Intel Macs

## How It Works

- **AVFoundation**: Captures video frames from the camera
- **OpenCV**: Processes frames using Canny edge detection (Gaussian blur → Canny algorithm → green overlay)
- **Objective-C++ Bridge**: Connects Swift code to OpenCV C++ library
- **SwiftUI**: Displays the processed video feed in real-time

## System Requirements

- macOS 13.0 or later
- Xcode 15.0 or later (for building)
- Built-in or external camera
