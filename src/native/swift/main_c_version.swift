import Cocoa
import WebKit

// C clipboard function declarations (to be linked with C object files)
@_silgen_name("clipboard_init")
func clipboard_init() -> Int32

@_silgen_name("clipboard_cleanup")
func clipboard_cleanup()

@_silgen_name("clipboard_get_history")
func clipboard_get_history() -> UnsafeMutablePointer<clipboard_history_t>?

@_silgen_name("clipboard_add_to_history")
func clipboard_add_to_history(_ content: UnsafePointer<CChar>?, _ type: Int32, _ sourceApp: UnsafePointer<CChar>?) -> Bool

@_silgen_name("clipboard_get_stats")
func clipboard_get_stats() -> clipboard_stats_t

// C structures
struct clipboard_history_t {
    var items: (clipboard_item_t, clipboard_item_t, clipboard_item_t, clipboard_item_t, clipboard_item_t) // Simplified
    var count: Int32
    var current_index: Int32
    var is_monitoring: Bool
}

struct clipboard_item_t {
    var id: (CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar) // 37 chars
    var type: Int32
    var content: UnsafeMutablePointer<CChar>?
    var content_size: Int
    var metadata: UnsafeMutablePointer<CChar>?
    var timestamp: time_t
    var source_app: (CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar) // 20 chars simplified
    var is_sensitive: Bool
}

struct clipboard_stats_t {
    var total_items: Int32
    var text_items: Int32
    var image_items: Int32
    var file_items: Int32
    var total_size: Int
    var oldest_item: time_t
    var newest_item: time_t
}

class EdgeBoardApp: NSObject, NSApplicationDelegate {
    var overlayWindow: NSWindow!
    var webView: WKWebView!
    var isVisible = false
    var statusItem: NSStatusItem?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize C clipboard system
        let _ = clipboard_init()
        
        setupStatusBarItem()
        setupOverlayWindow()
        setupWebView()
        loadProfessionalHTML()
        
        // Hide dock icon and make it a background app
        NSApp.setActivationPolicy(.accessory)
    }
    
    func setupStatusBarItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem?.button {
            button.title = "⚡"
            button.action = #selector(toggleOverlay)
            button.target = self
            button.toolTip = "EdgeBoard - Productivity Overlay"
        }
    }
    
    func setupOverlayWindow() {
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        
        // Create a professional overlay window on the right edge
        let windowRect = NSRect(
            x: screenFrame.maxX - 380,  // 380px wide overlay
            y: screenFrame.minY + 80,   // 80px from bottom
            width: 360,
            height: screenFrame.height - 160  // Leave 80px top and bottom
        )
        
        overlayWindow = NSWindow(
            contentRect: windowRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        // Configure overlay properties
        overlayWindow.level = NSWindow.Level.floating
        overlayWindow.isOpaque = false
        overlayWindow.backgroundColor = NSColor.clear
        overlayWindow.hasShadow = true
        overlayWindow.ignoresMouseEvents = false
        overlayWindow.collectionBehavior = [.canJoinAllSpaces, .stationary]
        
        // Initially hidden
        overlayWindow.orderOut(nil)
    }
    
    func setupWebView() {
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")
        
        webView = WKWebView(frame: overlayWindow.contentView!.bounds, configuration: config)
        webView.autoresizingMask = [.width, .height]
        webView.setValue(false, forKey: "drawsBackground")
        
        overlayWindow.contentView?.addSubview(webView)
    }
    
    @objc func toggleOverlay() {
        if isVisible {
            hideOverlay()
        } else {
            showOverlay()
        }
    }
    
    func showOverlay() {
        if !isVisible {
            overlayWindow.orderFront(nil)
            isVisible = true
            
            // Animate in from the right edge
            let currentFrame = overlayWindow.frame
            let hiddenFrame = NSRect(
                x: currentFrame.maxX,
                y: currentFrame.origin.y,
                width: currentFrame.width,
                height: currentFrame.height
            )
            
            overlayWindow.setFrame(hiddenFrame, display: false)
            
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.25
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                overlayWindow.animator().setFrame(currentFrame, display: true)
            }
        }
    }
    
    func hideOverlay() {
        if isVisible {
            let currentFrame = overlayWindow.frame
            let hiddenFrame = NSRect(
                x: currentFrame.maxX,
                y: currentFrame.origin.y,
                width: currentFrame.width,
                height: currentFrame.height
            )
            
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.25
                context.timingFunction = CAMediaTimingFunction(name: .easeIn)
                overlayWindow.animator().setFrame(hiddenFrame, display: true)
            }) {
                self.overlayWindow.orderOut(nil)
                self.isVisible = false
            }
        }
    }
    
    func loadProfessionalHTML() {
        let htmlContent = createProfessionalHTML()
        webView.loadHTMLString(htmlContent, baseURL: nil)
    }
    
    func createProfessionalHTML() -> String {
        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>EdgeBoard</title>
            <style>
                * {
                    margin: 0;
                    padding: 0;
                    box-sizing: border-box;
                }
                
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                    background: transparent;
                    color: white;
                    overflow: hidden;
                    height: 100vh;
                }
                
                .overlay-container {
                    background: rgba(0, 0, 0, 0.85);
                    backdrop-filter: blur(20px);
                    -webkit-backdrop-filter: blur(20px);
                    border: 1px solid rgba(255, 255, 255, 0.1);
                    border-radius: 16px;
                    box-shadow: 
                        0 8px 32px rgba(0, 0, 0, 0.3),
                        0 0 0 1px rgba(255, 255, 255, 0.05);
                    margin: 12px;
                    height: calc(100vh - 24px);
                    display: flex;
                    flex-direction: column;
                    position: relative;
                    overflow: hidden;
                }
                
                .header {
                    background: linear-gradient(135deg, rgba(74, 144, 226, 0.8), rgba(156, 39, 176, 0.8));
                    padding: 16px 20px;
                    border-radius: 16px 16px 0 0;
                    backdrop-filter: blur(10px);
                    -webkit-backdrop-filter: blur(10px);
                }
                
                .header h1 {
                    font-size: 18px;
                    font-weight: 600;
                    text-shadow: 0 2px 4px rgba(0, 0, 0, 0.3);
                    margin-bottom: 4px;
                }
                
                .header .subtitle {
                    font-size: 12px;
                    opacity: 0.9;
                    font-weight: 400;
                }
                
                .content {
                    flex: 1;
                    padding: 20px;
                    overflow-y: auto;
                    scrollbar-width: thin;
                    scrollbar-color: rgba(255, 255, 255, 0.3) transparent;
                }
                
                .content::-webkit-scrollbar {
                    width: 4px;
                }
                
                .content::-webkit-scrollbar-track {
                    background: transparent;
                }
                
                .content::-webkit-scrollbar-thumb {
                    background: rgba(255, 255, 255, 0.3);
                    border-radius: 2px;
                }
                
                .section {
                    margin-bottom: 24px;
                }
                
                .section-title {
                    font-size: 14px;
                    font-weight: 600;
                    margin-bottom: 12px;
                    color: rgba(255, 255, 255, 0.9);
                    display: flex;
                    align-items: center;
                    gap: 8px;
                }
                
                .clipboard-history {
                    background: rgba(255, 255, 255, 0.05);
                    border: 1px solid rgba(255, 255, 255, 0.1);
                    border-radius: 12px;
                    overflow: hidden;
                }
                
                .clipboard-item {
                    padding: 12px 16px;
                    border-bottom: 1px solid rgba(255, 255, 255, 0.05);
                    cursor: pointer;
                    transition: all 0.2s ease;
                    display: flex;
                    align-items: center;
                    gap: 12px;
                }
                
                .clipboard-item:last-child {
                    border-bottom: none;
                }
                
                .clipboard-item:hover {
                    background: rgba(255, 255, 255, 0.1);
                    transform: translateY(-1px);
                }
                
                .clipboard-item:active {
                    transform: translateY(0);
                    background: rgba(255, 255, 255, 0.15);
                }
                
                .clipboard-type {
                    background: rgba(74, 144, 226, 0.6);
                    color: white;
                    padding: 4px 8px;
                    border-radius: 6px;
                    font-size: 10px;
                    font-weight: 500;
                    text-transform: uppercase;
                    letter-spacing: 0.5px;
                    min-width: 40px;
                    text-align: center;
                }
                
                .clipboard-content {
                    flex: 1;
                    font-size: 13px;
                    opacity: 0.9;
                    white-space: nowrap;
                    overflow: hidden;
                    text-overflow: ellipsis;
                    max-width: 200px;
                }
                
                .clipboard-time {
                    font-size: 11px;
                    opacity: 0.6;
                    margin-left: auto;
                }
                
                .stats {
                    display: grid;
                    grid-template-columns: 1fr 1fr;
                    gap: 12px;
                }
                
                .stat-card {
                    background: rgba(255, 255, 255, 0.05);
                    border: 1px solid rgba(255, 255, 255, 0.1);
                    border-radius: 8px;
                    padding: 12px;
                    text-align: center;
                }
                
                .stat-number {
                    font-size: 18px;
                    font-weight: 600;
                    color: #4A90E2;
                    margin-bottom: 4px;
                }
                
                .stat-label {
                    font-size: 11px;
                    opacity: 0.7;
                    text-transform: uppercase;
                    letter-spacing: 0.5px;
                }
                
                .footer {
                    padding: 12px 20px;
                    background: rgba(0, 0, 0, 0.3);
                    border-top: 1px solid rgba(255, 255, 255, 0.05);
                    font-size: 11px;
                    opacity: 0.6;
                    text-align: center;
                }
                
                @keyframes fadeIn {
                    from { opacity: 0; transform: translateY(10px); }
                    to { opacity: 1; transform: translateY(0); }
                }
                
                .clipboard-item {
                    animation: fadeIn 0.3s ease-out;
                }
                
                .loading {
                    text-align: center;
                    padding: 20px;
                    opacity: 0.6;
                }
                
                .empty-state {
                    text-align: center;
                    padding: 40px 20px;
                    opacity: 0.6;
                }
                
                .empty-state-icon {
                    font-size: 32px;
                    margin-bottom: 12px;
                    opacity: 0.4;
                }
            </style>
        </head>
        <body>
            <div class="overlay-container">
                <div class="header">
                    <h1>⚡ EdgeBoard</h1>
                    <div class="subtitle">Professional Productivity Overlay</div>
                </div>
                
                <div class="content">
                    <div class="section">
                        <div class="section-title">
                            📋 Clipboard History
                        </div>
                        <div class="clipboard-history" id="clipboardHistory">
                            <div class="loading">Loading clipboard history...</div>
                        </div>
                    </div>
                    
                    <div class="section">
                        <div class="section-title">
                            📊 Statistics
                        </div>
                        <div class="stats" id="stats">
                            <div class="stat-card">
                                <div class="stat-number" id="totalItems">0</div>
                                <div class="stat-label">Total Items</div>
                            </div>
                            <div class="stat-card">
                                <div class="stat-number" id="textItems">0</div>
                                <div class="stat-label">Text Items</div>
                            </div>
                        </div>
                    </div>
                </div>
                
                <div class="footer">
                    Click any item to copy • EdgeBoard v1.0
                </div>
            </div>
            
            <script>
                // Mock data for demonstration - will be replaced with real C bridge data
                const mockClipboardData = [
                    { type: 'TEXT', content: 'Hello, this is a sample clipboard item', time: '2 min ago' },
                    { type: 'TEXT', content: 'https://github.com/user/repo', time: '5 min ago' },
                    { type: 'TEXT', content: 'Swift is a powerful programming language', time: '10 min ago' },
                    { type: 'FILE', content: 'document.pdf', time: '15 min ago' },
                    { type: 'TEXT', content: 'npm install -g edgeboard', time: '20 min ago' }
                ];
                
                function loadClipboardHistory() {
                    const historyContainer = document.getElementById('clipboardHistory');
                    
                    if (mockClipboardData.length === 0) {
                        historyContainer.innerHTML = `
                            <div class="empty-state">
                                <div class="empty-state-icon">📝</div>
                                <div>No clipboard history yet</div>
                            </div>
                        `;
                        return;
                    }
                    
                    historyContainer.innerHTML = mockClipboardData.map(item => `
                        <div class="clipboard-item" onclick="copyToClipboard('${item.content}')">
                            <div class="clipboard-type">${item.type}</div>
                            <div class="clipboard-content">${item.content}</div>
                            <div class="clipboard-time">${item.time}</div>
                        </div>
                    `).join('');
                }
                
                function loadStats() {
                    document.getElementById('totalItems').textContent = mockClipboardData.length;
                    document.getElementById('textItems').textContent = mockClipboardData.filter(item => item.type === 'TEXT').length;
                }
                
                function copyToClipboard(content) {
                    // This will be replaced with Swift bridge call
                    console.log('Copying to clipboard:', content);
                    
                    // Visual feedback
                    const button = event.target.closest('.clipboard-item');
                    const originalBg = button.style.background;
                    button.style.background = 'rgba(74, 144, 226, 0.3)';
                    setTimeout(() => {
                        button.style.background = originalBg;
                    }, 200);
                }
                
                // Initialize the interface
                document.addEventListener('DOMContentLoaded', function() {
                    loadClipboardHistory();
                    loadStats();
                    
                    // Auto-refresh every 30 seconds
                    setInterval(() => {
                        loadClipboardHistory();
                        loadStats();
                    }, 30000);
                });
            </script>
        </body>
        </html>
        """
    }
    
    // Bridge function to get clipboard data from C layer
    func getClipboardHistoryData() -> [[String: Any]] {
        guard let history = clipboard_get_history() else {
            return []
        }
        
        let _ = Int(history.pointee.count)
        
        // Note: This is a simplified version - in reality you'd iterate through the C array
        // For now, returning mock data until the C bridge is fully connected
        return [
            ["type": "TEXT", "content": "Sample clipboard content", "time": "1 min ago"],
            ["type": "TEXT", "content": "Another clipboard item", "time": "3 min ago"]
        ]
    }
    
    // Bridge function to get stats from C layer
    func getClipboardStats() -> [String: Int] {
        let stats = clipboard_get_stats()
        return [
            "total": Int(stats.total_items),
            "text": Int(stats.text_items),
            "image": Int(stats.image_items),
            "file": Int(stats.file_items)
        ]
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        clipboard_cleanup()
    }
}

// Main entry point
let app = NSApplication.shared
let delegate = EdgeBoardApp()
app.delegate = delegate
app.run()
