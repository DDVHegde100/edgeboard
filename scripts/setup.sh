#!/bin/bash

# EdgeBoard Development Setup Script
# This script sets up the development environment for EdgeBoard

set -e  # Exit on any error

echo "🚀 Setting up EdgeBoard development environment..."

# Check for required tools
echo "📋 Checking prerequisites..."

# Check for Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is required but not installed. Please install Node.js 18+ and try again."
    exit 1
fi

# Check Node.js version
NODE_VERSION=$(node -v | cut -d'v' -f2)
NODE_MAJOR=$(echo $NODE_VERSION | cut -d'.' -f1)
if [ "$NODE_MAJOR" -lt 18 ]; then
    echo "❌ Node.js 18+ is required. Current version: $NODE_VERSION"
    exit 1
fi

# Check for npm
if ! command -v npm &> /dev/null; then
    echo "❌ npm is required but not installed."
    exit 1
fi

# Check for Xcode Command Line Tools
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Xcode Command Line Tools are required. Please install with:"
    echo "   xcode-select --install"
    exit 1
fi

# Check for Swift
if ! command -v swift &> /dev/null; then
    echo "❌ Swift is required but not installed. Please install Xcode."
    exit 1
fi

# Check for Clang
if ! command -v clang &> /dev/null; then
    echo "❌ Clang is required but not installed."
    exit 1
fi

echo "✅ All prerequisites satisfied!"

# Install Node.js dependencies
echo "📦 Installing Node.js dependencies..."
npm install

# Create build directories
echo "📁 Creating build directories..."
mkdir -p build/native
mkdir -p build/ui
mkdir -p dist

# Build native components
echo "🔨 Building native components..."
cd src/native
make clean && make all
cd ../..

# Build UI components
echo "🎨 Building UI components..."
npm run build:ui

echo "✅ Development environment setup complete!"
echo ""
echo "🎉 You're ready to start developing EdgeBoard!"
echo ""
echo "Next steps:"
echo "  1. Start development server: npm run dev"
echo "  2. Open another terminal and run: npm run watch:native"
echo "  3. Begin coding and enjoy hot reload!"
echo ""
echo "📚 Documentation:"
echo "  - Architecture: docs/ARCHITECTURE.md"
echo "  - Contributing: docs/CONTRIBUTING.md"
echo "  - Roadmap: docs/ROADMAP.md"
