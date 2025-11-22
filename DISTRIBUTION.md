# Distribution Guide

## How Dependencies Work

When you build the app with CocoaPods and Xcode:

1. **OpenCV framework** (~100MB) gets embedded into the `.app` bundle
2. **All dependencies** are statically or dynamically linked into the bundle
3. The resulting `.app` is **completely self-contained**
4. No runtime dependencies need to be installed on the recipient's Mac

## For Development (First Time Setup)

On a fresh Mac that has never seen Homebrew or OpenCV:

```bash
cd /Users/jordanh/Src/camera-recognizes-shit
make setup
```

This automatically:
1. Checks for Xcode
2. Installs Homebrew if needed (prompts for password)
3. Installs OpenCV via Homebrew (~145MB)
4. Configures the Xcode project with proper paths

Then build:
```bash
make build
# or
make run
```

**Note:** Homebrew is preferred over CocoaPods for macOS because:
- OpenCV pods are iOS-only and outdated
- Homebrew provides the latest OpenCV (4.12.0)
- System-wide installation works with all build tools
- No Ruby version conflicts

## For Distribution

### Creating a Distributable Package

```bash
make package
```

This creates `dist/CameraEdgeDetector.app` with everything embedded.

### What Gets Included in the .app Bundle

```
CameraEdgeDetector.app/
├── Contents/
│   ├── MacOS/
│   │   └── CameraEdgeDetector          # Main executable
│   ├── Frameworks/                      # All dependencies here!
│   │   ├── opencv2.framework            # ~100MB OpenCV
│   │   └── ... (other pods)
│   ├── Resources/
│   │   └── ... (app resources)
│   └── Info.plist                       # App metadata + permissions
```

### Sharing the App

**Option 1: Direct .app**
```bash
cd dist
zip -r CameraEdgeDetector.zip CameraEdgeDetector.app
```
Share the .zip file (~50-60MB compressed)

**Option 2: DMG (More Professional)**
```bash
# Create a DMG
hdiutil create -volname "Camera Edge Detector" \
  -srcfolder dist/CameraEdgeDetector.app \
  -ov -format UDZO \
  dist/CameraEdgeDetector.dmg
```

### Recipient Instructions

1. **Download** and unzip the app
2. **Move** to Applications folder (optional but recommended)
3. **First Launch**: Right-click → Open (due to Gatekeeper)
   - Or run: `xattr -cr CameraEdgeDetector.app` to remove quarantine
4. **Grant camera permission** when prompted
5. **Done!** No installation, no dependencies, just run

## Code Signing and Notarization (Optional)

For wider distribution without Gatekeeper warnings:

1. **Code Sign** with your Apple Developer certificate:
   ```bash
   codesign --force --deep --sign "Your Developer ID" \
     dist/CameraEdgeDetector.app
   ```

2. **Notarize** with Apple:
   ```bash
   # Create a ZIP for notarization
   ditto -c -k --keepParent dist/CameraEdgeDetector.app \
     dist/CameraEdgeDetector-notarize.zip
   
   # Submit for notarization (requires Apple Developer account)
   xcrun notarytool submit dist/CameraEdgeDetector-notarize.zip \
     --keychain-profile "YOUR_PROFILE" \
     --wait
   
   # Staple the notarization ticket
   xcrun stapler staple dist/CameraEdgeDetector.app
   ```

## Build Configuration

The app is built in **Release** configuration by default (optimized, smaller size).

To change build configuration, edit the Makefile or use Xcode directly.

## Architecture Support

The app builds for your current architecture by default:
- **Apple Silicon** (M1/M2/M3): arm64
- **Intel**: x86_64

For **universal binary** (both architectures):
- In Xcode: Build Settings → Architectures → "Standard Architectures"
- Or specify in Makefile: `-arch arm64 -arch x86_64`

## Troubleshooting

### "App is damaged and can't be opened"
Run: `xattr -cr /path/to/CameraEdgeDetector.app`

### "Camera permission not working"
The app includes `NSCameraUsageDescription` in Info.plist. If permission isn't prompted:
- System Settings → Privacy & Security → Camera
- Manually add the app

### Large file size
OpenCV is ~100MB. This is normal. The compressed .zip will be ~50-60MB.

## Summary

**For Fresh Mac (Development):**
```bash
make setup
make run
```

**For Distribution:**
```bash
make package
cd dist && zip -r CameraEdgeDetector.zip CameraEdgeDetector.app
```

**For Recipients:**
Download → Unzip → Right-click Open → Grant Camera Permission → Use!
