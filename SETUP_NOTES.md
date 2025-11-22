# Setup Notes for Camera Edge Detector

## Installation Method: Homebrew

This project uses **Homebrew** to install OpenCV instead of CocoaPods because:
- OpenCV pods in CocoaPods repository are iOS-only (max version 4.3.0)
- macOS requires different build of OpenCV
- Homebrew provides the latest OpenCV (4.12.0) compiled for macOS
- No Ruby version conflicts

## Automated Setup

```bash
make setup
```

This will:
1. Check for Xcode
2. Install Homebrew if not present (prompts for password)
3. Install OpenCV 4.12.0 via Homebrew (~145MB + dependencies)
4. Configure Xcode project with proper header and library search paths

## Code Signing Notes

The project has **Hardened Runtime disabled** for development to allow loading Homebrew-installed OpenCV libraries. This is necessary because:
- Homebrew libraries are not code-signed with a matching Team ID
- macOS Sequoia enforces stricter code signature validation
- For development, disabling hardened runtime allows the app to run

For distribution, you have two options:
1. **Keep hardened runtime disabled** - Works but reduces security
2. **Add library validation exceptions** - More secure but complex

## What Gets Installed

When you run `make setup`:

- **Homebrew** (if not present): Package manager for macOS
- **OpenCV 4.12.0**: Computer vision library (~145MB)
  - Core libraries: imgproc, imgcodecs, videoio, etc.
  - Installed to: `/opt/homebrew/opt/opencv` (Apple Silicon) or `/usr/local/opt/opencv` (Intel)

## Build Configuration

The Xcode project is pre-configured with:
- Header search paths: `/opt/homebrew/opt/opencv/include/opencv4`
- Library search paths: `/opt/homebrew/opt/opencv/lib`
- Linked libraries: core, imgproc, imgcodecs, videoio, highgui, video, features2d, calib3d, objdetect, stitching
- Architecture: arm64 (Apple Silicon native)

## First Run

When you first run the app:
1. App window opens
2. macOS prompts for **Camera permission** - click "Allow"
3. Video feed starts showing with green edge overlay
4. Real-time Canny edge detection applied to camera frames

## Troubleshooting

### App won't start - "Library not loaded" error
The OpenCV libraries can't be found. Run:
```bash
make show-opencv-path
brew list opencv
```

### Build fails with "opencv2/opencv.hpp not found"
OpenCV isn't installed. Run:
```bash
brew install opencv
```

### Camera permission not prompted
Manually grant in System Settings:
- System Settings → Privacy & Security → Camera
- Add CameraEdgeDetector

### "Team ID mismatch" error
This means hardened runtime is enabled. It's already disabled in the project, but if you see this:
1. Open project in Xcode
2. Select CameraEdgeDetector target
3. Signing & Capabilities → Disable "Hardened Runtime"
