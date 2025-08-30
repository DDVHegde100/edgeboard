# EdgeBoard

**The Professional macOS Edge Overlay for Productivity Power Users**

EdgeBoard is a next-generation, always-on-top overlay for macOS, designed to supercharge your workflow. With a beautiful glassmorphism UI, global hotkeys, and seamless clipboard management, EdgeBoard keeps your most important tools just a swipe or shortcut away—without ever getting in your way.

---

## Features

- **Clipboard Manager**: Searchable, filterable clipboard history with instant previews
- **Global Hotkey**: Toggle the overlay from anywhere (default: <kbd>Cmd</kbd> + <kbd>Ctrl</kbd> + <kbd>V</kbd>)
- **Menu Bar Integration**: Quick access and status from the macOS menu bar
- **Dark/Light Mode**: One-click theme toggle for day or night
- **Glassmorphism UI**: Modern, animated, and 4K-ready overlay
- **Extensible**: Built to support future widgets (launcher, notes, timers, etc.)

---

## Architecture

```
┌─────────────────────────────┐
│      React/TypeScript       │  ← Modern UI (WebView)
├─────────────────────────────┤
│      Swift (macOS)          │  ← Overlay, hotkeys, window mgmt
├─────────────────────────────┤
│      C (Clipboard Core)     │  ← Fast, low-level clipboard ops
└─────────────────────────────┘
```

**Tech Stack:** Swift, C, React, TypeScript, WebKit, SCSS

---

## Getting Started

```bash
# Clone the repository
git clone https://github.com/DDVHegde100/edgeboard.git
cd edgeboard

# Install UI dependencies
npm install

# Build native (Swift/C) components
make build-native

# Run the development server (UI)
npm run dev

# Or build and run the native overlay directly
swiftc -O -framework Cocoa -framework WebKit src/native/swift/main_improved.swift -o build/native/EdgeBoard
./build/native/EdgeBoard
```

---

## Usage

- **Toggle Overlay:** <kbd>Cmd</kbd> + <kbd>Ctrl</kbd> + <kbd>V</kbd>
- **Search Clipboard:** Type in the search bar at the top
- **Copy Item:** Click any clipboard entry
- **Theme Toggle:** Click the moon/sun icon in the overlay header
- **Close Overlay:** Click the <kbd>✕</kbd> button or use the hotkey again
- **Menu Bar:** Click the "EB" icon for quick access

---

## Project Structure

```
edgeboard/
├── src/
│   ├── native/          # Swift and C code (overlay, clipboard)
│   ├── ui/              # React/TypeScript UI
│   └── shared/          # Shared utilities and types
├── assets/              # Icons, images, screenshots
├── scripts/             # Build and development scripts
└── docs/                # Documentation and guides
```

---

## Roadmap & Status

- [x] Modern overlay window with glassmorphism
- [x] Clipboard history, search, and preview
- [x] Global hotkey and menu bar integration
- [x] Dark/light mode toggle
- [ ] Quick launcher, notes, timers, widgets (coming soon)

See [docs/ROADMAP.md](docs/ROADMAP.md) for detailed progress.

---

## Contributing

Contributions are welcome! Please read the [contributing guidelines](docs/CONTRIBUTING.md) before submitting pull requests.

---

## 📄 License

MIT License © 2025 DDVHegde100
