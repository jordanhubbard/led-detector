#!/bin/bash
set -e

APP_PATH="$1"
FRAMEWORKS_PATH="$APP_PATH/Contents/Frameworks"
BINARY_PATH="$APP_PATH/Contents/MacOS/CameraEdgeDetector"

echo "Bundling dependencies for $APP_PATH"

# Create Frameworks directory if it doesn't exist
mkdir -p "$FRAMEWORKS_PATH"

# Function to copy and fix a dylib
fix_dylib() {
    local dylib=$1
    local lib_name=$(basename "$dylib")
    
    # Skip if already copied
    if [ -f "$FRAMEWORKS_PATH/$lib_name" ]; then
        return
    fi
    
    # Skip system libraries
    if [[ "$dylib" == /usr/lib/* ]] || [[ "$dylib" == /System/* ]]; then
        return
    fi
    
    # Copy the library
    if [ -f "$dylib" ]; then
        echo "Copying $lib_name..."
        cp "$dylib" "$FRAMEWORKS_PATH/"
        chmod +w "$FRAMEWORKS_PATH/$lib_name"
        
        # Fix the library's own install name
        install_name_tool -id "@executable_path/../Frameworks/$lib_name" "$FRAMEWORKS_PATH/$lib_name" 2>/dev/null || true
        
        # Fix dependencies of this library
        otool -L "$FRAMEWORKS_PATH/$lib_name" | grep -v ":" | grep -v "@" | awk '{print $1}' | while read dep; do
            if [[ "$dep" == /opt/homebrew/* ]] || [[ "$dep" == /usr/local/* ]]; then
                dep_name=$(basename "$dep")
                if [ -f "/opt/homebrew/opt/"*"/lib/$dep_name" ] || [ -f "/opt/homebrew/lib/$dep_name" ]; then
                    install_name_tool -change "$dep" "@executable_path/../Frameworks/$dep_name" "$FRAMEWORKS_PATH/$lib_name" 2>/dev/null || true
                fi
            fi
        done
    fi
}

# Get all Homebrew dependencies from the binary
echo "Finding dependencies..."
otool -L "$BINARY_PATH" | grep -E "(homebrew|usr/local)" | awk '{print $1}' | while read dylib; do
    fix_dylib "$dylib"
    
    # Recursively fix dependencies of dependencies
    if [ -f "$FRAMEWORKS_PATH/$(basename $dylib)" ]; then
        otool -L "$FRAMEWORKS_PATH/$(basename $dylib)" | grep -E "(homebrew|usr/local)" | awk '{print $1}' | while read dep; do
            fix_dylib "$dep"
        done
    fi
done

# Re-sign the app (ad-hoc signature)
echo "Re-signing app..."
codesign --force --deep --sign - "$APP_PATH" 2>/dev/null || true

echo "✅ Done! App size:"
du -sh "$APP_PATH"
