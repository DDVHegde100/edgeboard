import Cocoa

class WindowManager: NSObject {
    let window: NSWindow
    
    init(contentRect: NSRect) {
        self.window = NSWindow(
            contentRect: contentRect,
            styleMask: [.borderless, .resizable],
            backing: .buffered,
            defer: false
        )
        super.init()
        configureWindow()
    }
    
    private func configureWindow() {
        window.level = .floating
        window.isOpaque = false
        window.backgroundColor = NSColor.clear
        window.hasShadow = true
        window.ignoresMouseEvents = false
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        window.setFrameAutosaveName("EdgeBoardOverlay")
    }
    
    func moveToScreenEdge(edge: NSRectEdge) {
        guard let screen = window.screen ?? NSScreen.main else { return }
        var frame = window.frame
        switch edge {
        case .minX:
            frame.origin.x = screen.frame.minX
        case .maxX:
            frame.origin.x = screen.frame.maxX - frame.width
        case .minY:
            frame.origin.y = screen.frame.minY
        case .maxY:
            frame.origin.y = screen.frame.maxY - frame.height
        default:
            break
        }
        window.setFrame(frame, display: true, animate: true)
    }
    
    func resize(to size: NSSize) {
        var frame = window.frame
        frame.size = size
        window.setFrame(frame, display: true, animate: true)
    }
    
    func setAlwaysOnTop(_ enabled: Bool) {
        window.level = enabled ? .floating : .normal
    }
}
