#!/bin/bash
set -e

APP_PATH="$1"
FRAMEWORKS_PATH="$APP_PATH/Contents/Frameworks"
BINARY_PATH="$APP_PATH/Contents/MacOS/CameraEdgeDetector"

echo "🔍 Bundling dependencies..."
mkdir -p "$FRAMEWORKS_PATH"

# Copy dependencies iteratively (max 5 levels deep)
for iteration in 1 2 3 4 5; do
    echo "Pass $iteration..."
    
    # Find all current Homebrew dependencies
    find "$APP_PATH/Contents" -type f \( -name "CameraEdgeDetector" -o -name "*.dylib" \) -exec otool -L {} \; 2>/dev/null | \
        grep -E "(homebrew|usr/local)" | awk '{print $1}' | sort -u | while read dep; do
        
        dep_name=$(basename "$dep")
        
        # Skip if already copied
        [ -f "$FRAMEWORKS_PATH/$dep_name" ] && continue
        
        # Copy if exists
        if [ -f "$dep" ]; then
            echo "  → $dep_name"
            cp "$dep" "$FRAMEWORKS_PATH/"
            chmod +w "$FRAMEWORKS_PATH/$dep_name"
        fi
    done
done

echo "🔧 Fixing install names..."

# Fix main binary
otool -L "$BINARY_PATH" | grep -E "(homebrew|usr/local)" | awk '{print $1}' | while read dep; do
    dep_name=$(basename "$dep")
    install_name_tool -change "$dep" "@executable_path/../Frameworks/$dep_name" "$BINARY_PATH" 2>/dev/null || true
done

# Fix all dylibs
for lib in "$FRAMEWORKS_PATH"/*.dylib; do
    [ -f "$lib" ] || continue
    
    lib_name=$(basename "$lib")
    
    # Fix ID
    install_name_tool -id "@executable_path/../Frameworks/$lib_name" "$lib" 2>/dev/null || true
    
    # Fix dependencies
    otool -L "$lib" | grep -E "(homebrew|usr/local)" | awk '{print $1}' | while read dep; do
        dep_name=$(basename "$dep")
        [ -f "$FRAMEWORKS_PATH/$dep_name" ] && install_name_tool -change "$dep" "@executable_path/../Frameworks/$dep_name" "$lib" 2>/dev/null || true
    done
done

echo "✍️  Re-signing..."
codesign --force --deep --sign - "$APP_PATH" 2>/dev/null || true

echo "✅ Done!"
du -sh "$APP_PATH"
ls "$FRAMEWORKS_PATH" | wc -l | xargs echo "📊 Libraries bundled:"
