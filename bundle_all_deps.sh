#!/bin/bash
set -e

APP_PATH="$1"
FRAMEWORKS_PATH="$APP_PATH/Contents/Frameworks"
BINARY_PATH="$APP_PATH/Contents/MacOS/CameraEdgeDetector"

echo "🔍 Bundling ALL dependencies for $APP_PATH"
mkdir -p "$FRAMEWORKS_PATH"

# Get all Homebrew dependencies recursively
echo "📦 Collecting dependencies..."
all_deps=$(mktemp)

# Function to recursively find deps
find_deps() {
    local file=$1
    otool -L "$file" 2>/dev/null | tail -n +2 | awk '{print $1}' | grep -E "(homebrew|usr/local)" | while read dep; do
        if [ -f "$dep" ]; then
            echo "$dep" >> "$all_deps"
            find_deps "$dep"
        fi
    done
}

find_deps "$BINARY_PATH"

# Copy unique dependencies
echo "📥 Copying libraries..."
sort -u "$all_deps" | while read dep; do
    if [ -f "$dep" ]; then
        dep_name=$(basename "$dep")
        if [ ! -f "$FRAMEWORKS_PATH/$dep_name" ]; then
            echo "  → $dep_name"
            cp "$dep" "$FRAMEWORKS_PATH/"
            chmod +w "$FRAMEWORKS_PATH/$dep_name"
        fi
    fi
done

rm "$all_deps"

# Now fix all install names
echo "🔧 Fixing install names..."

# Fix the main binary
otool -L "$BINARY_PATH" | tail -n +2 | grep -E "(homebrew|usr/local)" | awk '{print $1}' | while read dep; do
    dep_name=$(basename "$dep")
    install_name_tool -change "$dep" "@executable_path/../Frameworks/$dep_name" "$BINARY_PATH" 2>/dev/null || true
done

# Fix all libraries
for lib in "$FRAMEWORKS_PATH"/*.dylib; do
    if [ -f "$lib" ]; then
        lib_name=$(basename "$lib")
        
        # Fix the library's own ID
        install_name_tool -id "@executable_path/../Frameworks/$lib_name" "$lib" 2>/dev/null || true
        
        # Fix its dependencies
        otool -L "$lib" | tail -n +2 | grep -E "(homebrew|usr/local)" | awk '{print $1}' | while read dep; do
            dep_name=$(basename "$dep")
            if [ -f "$FRAMEWORKS_PATH/$dep_name" ]; then
                install_name_tool -change "$dep" "@executable_path/../Frameworks/$dep_name" "$lib" 2>/dev/null || true
            fi
        done
    fi
done

# Re-sign
echo "✍️  Re-signing..."
codesign --force --deep --sign - "$APP_PATH" 2>/dev/null || true

echo "✅ Done!"
du -sh "$APP_PATH"
echo "📊 Framework count: $(ls -1 $FRAMEWORKS_PATH/*.dylib 2>/dev/null | wc -l)"
