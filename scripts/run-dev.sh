#!/bin/bash

# EdgeBoard Development Runner
# Builds and runs EdgeBoard in development mode

set -e

echo "🚀 Starting EdgeBoard Development Environment..."

# Kill any existing processes
echo "🧹 Cleaning up existing processes..."
pkill -f "webpack serve" || true
pkill -f "EdgeBoard" || true

# Build native app
echo "🔨 Building Swift application..."
cd "$(dirname "$0")/.."
mkdir -p build/native
swiftc -O -framework Cocoa -framework WebKit src/native/swift/main.swift -o build/native/EdgeBoard

# Start React dev server in background
echo "⚛️  Starting React development server..."
npm run dev:ui &
REACT_PID=$!

# Wait for React server to start
echo "⏳ Waiting for React server to start..."
sleep 3

# Start native app
echo "📱 Launching EdgeBoard..."
./build/native/EdgeBoard &
NATIVE_PID=$!

echo "✅ EdgeBoard is running!"
echo ""
echo "🌐 React Dev Server: http://localhost:3000"
echo "📱 Native App: Running in background"
echo ""
echo "Press Ctrl+C to stop both processes..."

# Function to cleanup on exit
cleanup() {
    echo ""
    echo "🛑 Stopping EdgeBoard..."
    kill $REACT_PID 2>/dev/null || true
    kill $NATIVE_PID 2>/dev/null || true
    pkill -f "webpack serve" || true
    pkill -f "EdgeBoard" || true
    echo "✅ Cleanup complete"
    exit 0
}

# Set trap to cleanup on Ctrl+C
trap cleanup SIGINT SIGTERM

# Wait for user to stop
wait
