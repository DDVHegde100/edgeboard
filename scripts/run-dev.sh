#!/bin/bash

# EdgeBoard Development Runner - Native Overlay Mode
# Builds and runs EdgeBoard as a native macOS overlay (no web server needed)

set -e

echo "🚀 Starting EdgeBoard Native Overlay..."

# Kill any existing EdgeBoard processes
echo "🧹 Cleaning up existing processes..."
pkill -f "EdgeBoard" || true

# Build native app
echo "🔨 Building Swift overlay application..."
cd "$(dirname "$0")/.."
mkdir -p build/native

# Compile Swift app
swiftc -O -framework Cocoa -framework WebKit src/native/swift/main.swift -o build/native/EdgeBoard

echo "📱 Launching EdgeBoard overlay..."
echo ""
echo "✅ EdgeBoard is starting!"
echo ""
echo "� How to use:"
echo "   • Click the ⚡ icon in your menu bar to toggle overlay"
echo "   • Overlay slides in from the right edge of your screen"
echo "   • Click outside overlay or menu bar icon to hide"
echo ""
echo "🛑 To stop: Press Ctrl+C or quit from menu bar"
echo ""

# Start native app (this will block until app is quit)
./build/native/EdgeBoard
