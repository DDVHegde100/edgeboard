import Cocoa
import WebKit

class EdgeBoardApp: NSObject, NSApplicationDelegate {
    var overlayWindow: NSWindow!
    var webView: WKWebView!
    var isVisible = false
    var statusItem: NSStatusItem?
    var clipboardHistory: [ClipboardItem] = []
    var clipboardChangeCount: Int = 0
    var clipboardTimer: Timer?
    
    struct ClipboardItem {
        let id: String
        let content: String
        let type: String
        let timestamp: Date
        let size: Int
        
        var timeAgo: String {
            let formatter = RelativeDateTimeFormatter()
            formatter.dateTimeStyle = .named
            return formatter.localizedString(for: timestamp, relativeTo: Date())
        }
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusBarItem()
        setupOverlayWindow()
        setupWebView()
        initializeClipboardMonitoring()
        loadProfessionalHTML()
        
        // Hide dock icon and make it a background app
        NSApp.setActivationPolicy(.accessory)
    }
    
    func initializeClipboardMonitoring() {
        let pasteboard = NSPasteboard.general
        clipboardChangeCount = pasteboard.changeCount
        
        // Add current clipboard content if any
        if let content = pasteboard.string(forType: .string), !content.isEmpty {
            addClipboardItem(content: content, type: "TEXT")
        }
        
        // Start monitoring clipboard changes
        clipboardTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            self.checkClipboardChanges()
        }
    }
    
    func checkClipboardChanges() {
        let pasteboard = NSPasteboard.general
        if pasteboard.changeCount != clipboardChangeCount {
            clipboardChangeCount = pasteboard.changeCount
            
            if let content = pasteboard.string(forType: .string), !content.isEmpty {
                addClipboardItem(content: content, type: determineContentType(content))
                updateUI()
            }
        }
    }
    
    func addClipboardItem(content: String, type: String) {
        let item = ClipboardItem(
            id: UUID().uuidString,
            content: content,
            type: type,
            timestamp: Date(),
            size: content.data(using: .utf8)?.count ?? 0
        )
        
        // Remove duplicates
        clipboardHistory.removeAll { $0.content == content }
        
        // Add to beginning and limit to 50 items
        clipboardHistory.insert(item, at: 0)
        if clipboardHistory.count > 50 {
            clipboardHistory = Array(clipboardHistory.prefix(50))
        }
    }
    
    func determineContentType(_ content: String) -> String {
        if content.hasPrefix("http://") || content.hasPrefix("https://") {
            return "URL"
        } else if content.contains("import ") || content.contains("func ") || content.contains("{") {
            return "CODE"
        } else if content.contains("/") && content.contains(".") && !content.contains(" ") {
            return "PATH"
        } else if content.count < 20 && !content.contains("\\n") {
            return "TEXT"
        } else {
            return "DOCUMENT"
        }
    }
    
    func updateUI() {
        if isVisible {
            // Inject updated data into the web view
            let jsonData = try? JSONSerialization.data(withJSONObject: clipboardHistory.prefix(10).map { item in
                return [
                    "id": item.id,
                    "content": item.content,
                    "type": item.type,
                    "timeAgo": item.timeAgo,
                    "size": "\(item.size) bytes",
                    "preview": self.generatePreview(for: item)
                ]
            })
            if let jsonData = jsonData, let jsonString = String(data: jsonData, encoding: .utf8) {
                let script = "window.updateClipboardData(\(jsonString))"
                webView.evaluateJavaScript(script) { _, _ in }
            }
        }
    }

    func generatePreview(for item: ClipboardItem) -> String {
        switch item.type {
        case "URL":
            return "<a href='\(item.content)' target='_blank' style='color:#8b5cf6;text-decoration:underline;'>\(item.content)</a>"
        case "CODE":
            let code = item.content.replacingOccurrences(of: "<", with: "&lt;").replacingOccurrences(of: ">", with: "&gt;")
            return "<pre style='background:rgba(99,102,241,0.08);padding:8px 12px;border-radius:8px;font-size:12px;overflow-x:auto;'>\(code.prefix(200))</pre>"
        case "TEXT":
            return "<span>\(item.content.prefix(80))\(item.content.count > 80 ? "…" : "")</span>"
        case "DOCUMENT":
            return "<span>\(item.content.prefix(80))\(item.content.count > 80 ? "…" : "")</span>"
        case "PATH":
            return "<span style='color:#34C759;'>\(item.content)</span>"
        default:
            // Try to detect image data (base64 PNG/JPEG)
            if item.content.hasPrefix("data:image/") {
                return "<img src='\(item.content)' style='max-width:60px;max-height:40px;border-radius:6px;box-shadow:0 2px 8px rgba(0,0,0,0.12);' />"
            }
            return "<span>\(item.content.prefix(80))\(item.content.count > 80 ? "…" : "")</span>"
        }
    }
    
    func setupStatusBarItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem?.button {
            button.title = "EB"
            button.action = #selector(toggleOverlay)
            button.target = self
            button.toolTip = "EdgeBoard - Professional Productivity Suite"
        }
    }
    
    func setupOverlayWindow() {
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        
        // Create a professional overlay window on the right edge
        let windowRect = NSRect(
            x: screenFrame.maxX - 400,  // 400px wide overlay
            y: screenFrame.minY + 60,   // 60px from bottom
            width: 380,
            height: screenFrame.height - 120  // Leave 60px top and bottom
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
        
        // Add message handlers for clipboard operations
        let contentController = WKUserContentController()
        contentController.add(self, name: "copyToClipboard")
        contentController.add(self, name: "clearHistory")
        contentController.add(self, name: "exportHistory")
        config.userContentController = contentController
        
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
            updateUI() // Update with latest clipboard data
            
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
                context.duration = 0.3
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
                context.duration = 0.3
                context.timingFunction = CAMediaTimingFunction(name: .easeIn)
                overlayWindow.animator().setFrame(hiddenFrame, display: true)
            }) {
                self.overlayWindow.orderOut(nil)
                self.isVisible = false
            }
        }
    }
    
    func loadProfessionalHTML() {
        let htmlContent = """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>EdgeBoard Professional</title>
            <style>
                * {
                    margin: 0;
                    padding: 0;
                    box-sizing: border-box;
                }
                
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Display', 'Helvetica Neue', sans-serif;
                    background: transparent;
                    color: white;
                    overflow: hidden;
                    height: 100vh;
                    -webkit-font-smoothing: antialiased;
                    text-rendering: optimizeLegibility;
                }
                
                .overlay-container {
                    background: rgba(8, 8, 12, 0.92);
                    backdrop-filter: blur(60px) saturate(200%) brightness(110%);
                    -webkit-backdrop-filter: blur(60px) saturate(200%) brightness(110%);
                    border: 1px solid rgba(255, 255, 255, 0.15);
                    border-radius: 24px;
                    box-shadow: 
                        0 32px 80px rgba(0, 0, 0, 0.6),
                        0 0 0 1px rgba(255, 255, 255, 0.1),
                        inset 0 1px 0 rgba(255, 255, 255, 0.15),
                        inset 0 -1px 0 rgba(0, 0, 0, 0.2);
                    margin: 12px;
                    height: calc(100vh - 24px);
                    display: flex;
                    flex-direction: column;
                    position: relative;
                    overflow: hidden;
                }
                
                .overlay-container::before {
                    content: '';
                    position: absolute;
                    top: 0;
                    left: 0;
                    right: 0;
                    bottom: 0;
                    background: 
                        radial-gradient(circle at 20% 30%, rgba(99, 102, 241, 0.08) 0%, transparent 50%),
                        radial-gradient(circle at 80% 70%, rgba(139, 92, 246, 0.06) 0%, transparent 50%);
                    pointer-events: none;
                    border-radius: 24px;
                }
                
                .header {
                    background: linear-gradient(135deg, 
                        rgba(16, 16, 20, 0.95) 0%,
                        rgba(24, 24, 32, 0.9) 100%);
                    backdrop-filter: blur(20px);
                    -webkit-backdrop-filter: blur(20px);
                    border-bottom: 1px solid rgba(255, 255, 255, 0.08);
                    padding: 24px 28px;
                    border-radius: 24px 24px 0 0;
                    position: relative;
                    overflow: hidden;
                }
                
                .header::before {
                    content: '';
                    position: absolute;
                    top: 0;
                    left: 0;
                    right: 0;
                    height: 1px;
                    background: linear-gradient(90deg, 
                        transparent 0%, 
                        rgba(255, 255, 255, 0.2) 50%, 
                        transparent 100%);
                }
                
                .header h1 {
                    font-size: 22px;
                    font-weight: 700;
                    letter-spacing: -0.5px;
                    margin-bottom: 6px;
                    background: linear-gradient(135deg, #ffffff 0%, #e5e7eb 100%);
                    -webkit-background-clip: text;
                    -webkit-text-fill-color: transparent;
                    background-clip: text;
                }
                
                .header .subtitle {
                    font-size: 13px;
                    opacity: 0.7;
                    font-weight: 500;
                    color: rgba(255, 255, 255, 0.8);
                }
                
                .content {
                    flex: 1;
                    padding: 24px 28px;
                    overflow-y: auto;
                    scrollbar-width: thin;
                    scrollbar-color: rgba(255, 255, 255, 0.2) transparent;
                }
                
                .content::-webkit-scrollbar {
                    width: 8px;
                }
                
                .content::-webkit-scrollbar-track {
                    background: transparent;
                    border-radius: 4px;
                }
                
                .content::-webkit-scrollbar-thumb {
                    background: rgba(255, 255, 255, 0.15);
                    border-radius: 4px;
                    border: 2px solid transparent;
                    background-clip: content-box;
                    transition: all 0.3s ease;
                }
                
                .content::-webkit-scrollbar-thumb:hover {
                    background: rgba(255, 255, 255, 0.25);
                    background-clip: content-box;
                }
                
                .section {
                    margin-bottom: 32px;
                }
                
                .section-title {
                    font-size: 12px;
                    font-weight: 600;
                    margin-bottom: 16px;
                    color: rgba(255, 255, 255, 0.9);
                    text-transform: uppercase;
                    letter-spacing: 1px;
                    opacity: 0.8;
                }
                
                .clipboard-history {
                    background: rgba(255, 255, 255, 0.03);
                    border: 1px solid rgba(255, 255, 255, 0.06);
                    border-radius: 16px;
                    overflow: hidden;
                    backdrop-filter: blur(20px);
                    -webkit-backdrop-filter: blur(20px);
                }
                
                .clipboard-item {
                    padding: 16px 20px;
                    border-bottom: 1px solid rgba(255, 255, 255, 0.04);
                    cursor: pointer;
                    transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
                    display: flex;
                    align-items: center;
                    gap: 16px;
                    position: relative;
                    background: transparent;
                }
                
                .clipboard-item:last-child {
                    border-bottom: none;
                }
                
                .clipboard-item::before {
                    content: '';
                    position: absolute;
                    left: 0;
                    top: 0;
                    bottom: 0;
                    width: 2px;
                    background: linear-gradient(to bottom, 
                        rgba(99, 102, 241, 0.8) 0%, 
                        rgba(139, 92, 246, 0.8) 100%);
                    opacity: 0;
                    transition: opacity 0.3s ease;
                }
                
                .clipboard-item:hover {
                    background: rgba(255, 255, 255, 0.05);
                    transform: translateX(4px);
                    border-left: 2px solid transparent;
                }
                
                .clipboard-item:hover::before {
                    opacity: 1;
                }
                
                .clipboard-item:active {
                    transform: translateX(2px) scale(0.98);
                    background: rgba(99, 102, 241, 0.1);
                }
                
                .clipboard-type {
                    background: linear-gradient(135deg, 
                        rgba(99, 102, 241, 0.2) 0%, 
                        rgba(139, 92, 246, 0.2) 100%);
                    border: 1px solid rgba(99, 102, 241, 0.3);
                    color: rgba(255, 255, 255, 0.9);
                    padding: 6px 12px;
                    border-radius: 8px;
                    font-size: 10px;
                    font-weight: 600;
                    text-transform: uppercase;
                    letter-spacing: 0.5px;
                    min-width: 52px;
                    text-align: center;
                    backdrop-filter: blur(10px);
                    -webkit-backdrop-filter: blur(10px);
                }
                
                .clipboard-content {
                    flex: 1;
                    font-size: 13px;
                    opacity: 0.85;
                    white-space: nowrap;
                    overflow: hidden;
                    text-overflow: ellipsis;
                    max-width: 200px;
                    font-weight: 400;
                    line-height: 1.4;
                }
                
                .clipboard-meta {
                    display: flex;
                    flex-direction: column;
                    align-items: flex-end;
                    gap: 2px;
                }
                
                .clipboard-time {
                    font-size: 11px;
                    opacity: 0.6;
                    font-weight: 500;
                    color: rgba(255, 255, 255, 0.6);
                }
                
                .clipboard-size {
                    font-size: 10px;
                    opacity: 0.4;
                    color: rgba(255, 255, 255, 0.5);
                }
                
                .stats {
                    display: grid;
                    grid-template-columns: 1fr 1fr;
                    gap: 16px;
                }
                
                .stat-card {
                    background: rgba(255, 255, 255, 0.04);
                    border: 1px solid rgba(255, 255, 255, 0.08);
                    border-radius: 12px;
                    padding: 20px 16px;
                    text-align: center;
                    backdrop-filter: blur(20px);
                    -webkit-backdrop-filter: blur(20px);
                    transition: all 0.3s ease;
                    position: relative;
                    overflow: hidden;
                }
                
                .stat-card::before {
                    content: '';
                    position: absolute;
                    top: 0;
                    left: 0;
                    right: 0;
                    height: 1px;
                    background: linear-gradient(90deg, 
                        transparent 0%, 
                        rgba(99, 102, 241, 0.6) 50%, 
                        transparent 100%);
                }
                
                .stat-card:hover {
                    background: rgba(255, 255, 255, 0.06);
                    transform: translateY(-2px);
                    box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
                }
                
                .stat-number {
                    font-size: 24px;
                    font-weight: 700;
                    background: linear-gradient(135deg, #a78bfa 0%, #8b5cf6 100%);
                    -webkit-background-clip: text;
                    -webkit-text-fill-color: transparent;
                    background-clip: text;
                    margin-bottom: 8px;
                }
                
                .stat-label {
                    font-size: 11px;
                    opacity: 0.7;
                    text-transform: uppercase;
                    letter-spacing: 0.8px;
                    font-weight: 600;
                    color: rgba(255, 255, 255, 0.7);
                }
                
                .footer {
                    padding: 16px 28px;
                    background: rgba(0, 0, 0, 0.2);
                    border-top: 1px solid rgba(255, 255, 255, 0.06);
                    font-size: 11px;
                    opacity: 0.6;
                    text-align: center;
                    font-weight: 500;
                    backdrop-filter: blur(20px);
                    -webkit-backdrop-filter: blur(20px);
                    border-radius: 0 0 24px 24px;
                }
                
                .loading, .empty-state {
                    text-align: center;
                    padding: 40px 20px;
                    opacity: 0.6;
                    font-size: 14px;
                }
                
                .controls {
                    display: flex;
                    gap: 8px;
                    margin-bottom: 16px;
                }
                
                .control-btn {
                    background: rgba(255, 255, 255, 0.06);
                    border: 1px solid rgba(255, 255, 255, 0.1);
                    border-radius: 8px;
                    padding: 8px 12px;
                    font-size: 11px;
                    color: rgba(255, 255, 255, 0.8);
                    cursor: pointer;
                    transition: all 0.3s ease;
                    backdrop-filter: blur(10px);
                    -webkit-backdrop-filter: blur(10px);
                    text-transform: uppercase;
                    letter-spacing: 0.5px;
                    font-weight: 600;
                }
                
                .control-btn:hover {
                    background: rgba(255, 255, 255, 0.1);
                    transform: translateY(-1px);
                }
                
                @keyframes slideInUp {
                    from { 
                        opacity: 0; 
                        transform: translateY(20px);
                    }
                    to { 
                        opacity: 1; 
                        transform: translateY(0);
                    }
                }
                
                @keyframes pulseSuccess {
                    0% { 
                        background: rgba(99, 102, 241, 0.1);
                        transform: scale(1);
                    }
                    50% { 
                        background: rgba(99, 102, 241, 0.2);
                        transform: scale(1.02);
                    }
                    100% { 
                        background: rgba(99, 102, 241, 0.1);
                        transform: scale(1);
                    }
                }
                
                .clipboard-item {
                    animation: slideInUp 0.4s cubic-bezier(0.25, 0.46, 0.45, 0.94);
                }
                
                .copy-feedback {
                    animation: pulseSuccess 0.6s ease-out;
                }
            </style>
        </head>
        <body>
            <div class="overlay-container">
                <div class="header">
                    <h1>EdgeBoard</h1>
                    <div class="subtitle">Professional Clipboard Manager</div>
                </div>
                
                <div class="content">
                    <div class="section">
                        <div class="section-title">Recent Clipboard History</div>
                        <div class="controls">
                            <div class="control-btn" onclick="clearHistory()">Clear All</div>
                            <div class="control-btn" onclick="exportHistory()">Export</div>
                        </div>
                        <div class="clipboard-history" id="clipboardHistory">
                            <div class="loading">Loading clipboard history...</div>
                        </div>
                    </div>
                    
                    <div class="section">
                        <div class="section-title">Statistics</div>
                        <div class="stats" id="stats">
                            <div class="stat-card">
                                <div class="stat-number" id="totalItems">0</div>
                                <div class="stat-label">Total Items</div>
                            </div>
                            <div class="stat-card">
                                <div class="stat-number" id="todayItems">0</div>
                                <div class="stat-label">Today</div>
                            </div>
                        </div>
                    </div>
                </div>
                
                <div class="footer">
                    Click any item to copy • EdgeBoard Professional
                </div>
            </div>
            
            <script>
                let clipboardData = [];
                
                window.updateClipboardData = function(data) {
                    clipboardData = data;
                    loadClipboardHistory();
                    loadStats();
                };
                
                function loadClipboardHistory() {
                    const historyContainer = document.getElementById('clipboardHistory');
                    
                    if (clipboardData.length === 0) {
                        historyContainer.innerHTML = `
                            <div class="empty-state">
                                No clipboard history yet<br>
                                <small>Copy something to get started</small>
                            </div>
                        `;
                        return;
                    }
                    
                    historyContainer.innerHTML = clipboardData.map((item, index) => `
                        <div class="clipboard-item" onclick="copyToClipboard('${item.content.replace(/'/g, "\\'").replace(/"/g, '\\\\"')}', this)" style="animation-delay: ${index * 0.05}s">
                            <div class="clipboard-type">${item.type}</div>
                            <div class="clipboard-content" title="${item.content.replace(/'/g, "&apos;").replace(/"/g, "&quot;")}">${item.preview}</div>
                            <div class="clipboard-meta">
                                <div class="clipboard-time">${item.timeAgo}</div>
                                <div class="clipboard-size">${item.size}</div>
                            </div>
                        </div>
                    `).join('');
                }
                
                function loadStats() {
                    document.getElementById('totalItems').textContent = clipboardData.length;
                    const todayCount = clipboardData.filter(item => 
                        item.timeAgo.includes('minute') || item.timeAgo.includes('hour') || item.timeAgo.includes('second')
                    ).length;
                    document.getElementById('todayItems').textContent = todayCount;
                }
                
                function copyToClipboard(content, element) {
                    webkit.messageHandlers.copyToClipboard.postMessage(content);
                    
                    element.classList.add('copy-feedback');
                    setTimeout(() => {
                        element.classList.remove('copy-feedback');
                    }, 600);
                }
                
                function clearHistory() {
                    if (confirm('Clear all clipboard history?')) {
                        webkit.messageHandlers.clearHistory.postMessage(null);
                    }
                }
                
                function exportHistory() {
                    webkit.messageHandlers.exportHistory.postMessage(clipboardData);
                }
                
                document.addEventListener('DOMContentLoaded', function() {
                    loadClipboardHistory();
                    loadStats();
                });
            </script>
        </body>
        </html>
        """
        
        webView.loadHTMLString(htmlContent, baseURL: nil)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        clipboardTimer?.invalidate()
    }
}

// MARK: - WKScriptMessageHandler
extension EdgeBoardApp: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch message.name {
        case "copyToClipboard":
            if let content = message.body as? String {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(content, forType: .string)
            }
        case "clearHistory":
            clipboardHistory.removeAll()
            updateUI()
        case "exportHistory":
            // TODO: Implement export functionality
            print("Export requested")
        default:
            break
        }
    }
}

// Main entry point
let app = NSApplication.shared
let delegate = EdgeBoardApp()
app.delegate = delegate
app.run()
