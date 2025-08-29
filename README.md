# EdgeBoard

**A sleek, always-on-top macOS overlay designed for productivity enthusiasts**

EdgeBoard is a modern macOS utility that lives on the edge of your screen, providing powerful everyday tools through an elegant glassmorphism interface. Built with a hybrid architecture combining C (system-level operations), Swift/Objective-C (native macOS windowing), and React/TypeScript (modern UI dashboard), it delivers both performance and polish.

## Design Philosophy

- **Cluely-inspired minimalism**: Clean, functional design language
- **Glassmorphism UI**: Translucent panels with smooth animations
- **Always accessible**: Lives on screen edge, never in the way
- **Native performance**: Low-level system integration for speed

## Architecture

```
┌─────────────────────┐
│   React/TypeScript  │  ← Modern UI Dashboard
│     (WebView)       │
├─────────────────────┤
│  Swift/Objective-C  │  ← Native macOS Windowing
├─────────────────────┤
│         C           │  ← System-level Operations
└─────────────────────┘
```

## Features (Planned)

- **Smart Clipboard Manager**: Advanced clipboard history with search
- **Quick Launcher**: Fast app/file launcher with fuzzy search
- **System Monitor**: Real-time CPU, memory, and network stats
- **Notes & Snippets**: Quick text capture and code snippets
- **Timer & Focus Tools**: Pomodoro timer and focus sessions
- **Weather & Time**: Elegant weather and world clock widgets

## Development Setup

```bash
# Clone the repository
git clone https://github.com/DDVHegde100/edgeboard.git
cd edgeboard

# Install dependencies
npm install

# Build native components
make build-native

# Run development server
npm run dev
```

## Project Structure

```
edgeboard/
├── src/
│   ├── native/          # C and Swift/Objective-C code
│   ├── ui/              # React/TypeScript dashboard
│   └── shared/          # Shared utilities and types
├── assets/              # Icons, images, and resources
├── scripts/             # Build and development scripts
└── docs/                # Documentation and guides
```

## Development Status

This project is in active development. Check the [commit roadmap](docs/ROADMAP.md) for detailed progress tracking.

## License

MIT License

## Contributing

Contributions welcome! Please read our contributing guidelines before submitting PRs.
