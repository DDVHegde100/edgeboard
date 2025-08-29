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
            button.toolTip = "EdgeBoard - Professional Productivity Overlay"
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
                    background: rgba(18, 18, 18, 0.95);
                    backdrop-filter: blur(40px) saturate(180%);
                    -webkit-backdrop-filter: blur(40px) saturate(180%);
                    border: 1px solid rgba(255, 255, 255, 0.1);
                    border-radius: 20px;
                    box-shadow: 
                        0 20px 60px rgba(0, 0, 0, 0.5),
                        0 0 0 1px rgba(255, 255, 255, 0.08),
                        inset 0 1px 0 rgba(255, 255, 255, 0.1);
                    margin: 16px;
                    height: calc(100vh - 32px);
                    display: flex;
                    flex-direction: column;
                    position: relative;
                    overflow: hidden;
                }
                
                .header {
                    background: linear-gradient(135deg, rgba(99, 102, 241, 0.9), rgba(139, 92, 246, 0.9));
                    padding: 20px 24px;
                    border-radius: 20px 20px 0 0;
                    backdrop-filter: blur(10px);
                    -webkit-backdrop-filter: blur(10px);
                    position: relative;
                    overflow: hidden;
                }
                
                .header::before {
                    content: '';
                    position: absolute;
                    top: 0;
                    left: 0;
                    right: 0;
                    bottom: 0;
                    background: linear-gradient(45deg, rgba(255, 255, 255, 0.1) 0%, transparent 50%);
                    pointer-events: none;
                }
                
                .header h1 {
                    font-size: 20px;
                    font-weight: 700;
                    text-shadow: 0 2px 8px rgba(0, 0, 0, 0.3);
                    margin-bottom: 6px;
                    position: relative;
                }
                
                .header .subtitle {
                    font-size: 13px;
                    opacity: 0.9;
                    font-weight: 500;
                    position: relative;
                }
                
                .content {
                    flex: 1;
                    padding: 24px;
                    overflow-y: auto;
                    scrollbar-width: thin;
                    scrollbar-color: rgba(255, 255, 255, 0.3) transparent;
                }
                
                .content::-webkit-scrollbar {
                    width: 6px;
                }
                
                .content::-webkit-scrollbar-track {
                    background: transparent;
                }
                
                .content::-webkit-scrollbar-thumb {
                    background: rgba(255, 255, 255, 0.2);
                    border-radius: 3px;
                    transition: background 0.2s ease;
                }
                
                .content::-webkit-scrollbar-thumb:hover {
                    background: rgba(255, 255, 255, 0.4);
                }
                
                .section {
                    margin-bottom: 32px;
                }
                
                .section-title {
                    font-size: 16px;
                    font-weight: 600;
                    margin-bottom: 16px;
                    color: rgba(255, 255, 255, 0.95);
                    display: flex;
                    align-items: center;
                    gap: 10px;
                }
                
                .section-title .icon {
                    font-size: 18px;
                    filter: drop-shadow(0 2px 4px rgba(0, 0, 0, 0.3));
                }
                
                .clipboard-history {
                    background: rgba(255, 255, 255, 0.06);
                    border: 1px solid rgba(255, 255, 255, 0.12);
                    border-radius: 16px;
                    overflow: hidden;
                    backdrop-filter: blur(10px);
                    -webkit-backdrop-filter: blur(10px);
                }
                
                .clipboard-item {
                    padding: 16px 20px;
                    border-bottom: 1px solid rgba(255, 255, 255, 0.06);
                    cursor: pointer;
                    transition: all 0.3s cubic-bezier(0.25, 0.46, 0.45, 0.94);
                    display: flex;
                    align-items: center;
                    gap: 16px;
                    position: relative;
                    overflow: hidden;
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
                    width: 3px;
                    background: linear-gradient(to bottom, rgba(99, 102, 241, 0.8), rgba(139, 92, 246, 0.8));
                    opacity: 0;
                    transition: opacity 0.3s ease;
                }
                
                .clipboard-item:hover::before {
                    opacity: 1;
                }
                
                .clipboard-item:hover {
                    background: rgba(255, 255, 255, 0.08);
                    transform: translateX(2px);
                    border-left: 3px solid transparent;
                }
                
                .clipboard-item:active {
                    transform: translateX(1px) scale(0.99);
                    background: rgba(99, 102, 241, 0.15);
                }
                
                .clipboard-type {
                    background: linear-gradient(135deg, rgba(99, 102, 241, 0.8), rgba(139, 92, 246, 0.8));
                    color: white;
                    padding: 6px 12px;
                    border-radius: 8px;
                    font-size: 11px;
                    font-weight: 600;
                    text-transform: uppercase;
                    letter-spacing: 0.8px;
                    min-width: 48px;
                    text-align: center;
                    box-shadow: 0 4px 12px rgba(99, 102, 241, 0.3);
                    text-shadow: 0 1px 2px rgba(0, 0, 0, 0.3);
                }
                
                .clipboard-content {
                    flex: 1;
                    font-size: 14px;
                    opacity: 0.9;
                    white-space: nowrap;
                    overflow: hidden;
                    text-overflow: ellipsis;
                    max-width: 180px;
                    font-weight: 400;
                    line-height: 1.4;
                }
                
                .clipboard-time {
                    font-size: 12px;
                    opacity: 0.6;
                    margin-left: auto;
                    font-weight: 500;
                    color: rgba(255, 255, 255, 0.7);
                }
                
                .stats {
                    display: grid;
                    grid-template-columns: 1fr 1fr;
                    gap: 16px;
                }
                
                .stat-card {
                    background: rgba(255, 255, 255, 0.06);
                    border: 1px solid rgba(255, 255, 255, 0.12);
                    border-radius: 12px;
                    padding: 20px 16px;
                    text-align: center;
                    backdrop-filter: blur(10px);
                    -webkit-backdrop-filter: blur(10px);
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
                    height: 2px;
                    background: linear-gradient(90deg, rgba(99, 102, 241, 0.8), rgba(139, 92, 246, 0.8));
                }
                
                .stat-card:hover {
                    background: rgba(255, 255, 255, 0.08);
                    transform: translateY(-2px);
                    box-shadow: 0 8px 25px rgba(0, 0, 0, 0.2);
                }
                
                .stat-number {
                    font-size: 24px;
                    font-weight: 700;
                    color: #818CF8;
                    margin-bottom: 8px;
                    text-shadow: 0 2px 4px rgba(0, 0, 0, 0.3);
                }
                
                .stat-label {
                    font-size: 12px;
                    opacity: 0.7;
                    text-transform: uppercase;
                    letter-spacing: 1px;
                    font-weight: 600;
                }
                
                .footer {
                    padding: 16px 24px;
                    background: rgba(0, 0, 0, 0.4);
                    border-top: 1px solid rgba(255, 255, 255, 0.08);
                    font-size: 12px;
                    opacity: 0.7;
                    text-align: center;
                    font-weight: 500;
                    backdrop-filter: blur(10px);
                    -webkit-backdrop-filter: blur(10px);
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
                
                @keyframes pulseGlow {
                    0%, 100% { 
                        box-shadow: 0 0 5px rgba(99, 102, 241, 0.4);
                    }
                    50% { 
                        box-shadow: 0 0 20px rgba(99, 102, 241, 0.8), 0 0 30px rgba(139, 92, 246, 0.6);
                    }
                }
                
                .clipboard-item {
                    animation: slideInUp 0.4s cubic-bezier(0.25, 0.46, 0.45, 0.94);
                }
                
                .clipboard-item:nth-child(1) { animation-delay: 0.1s; }
                .clipboard-item:nth-child(2) { animation-delay: 0.15s; }
                .clipboard-item:nth-child(3) { animation-delay: 0.2s; }
                .clipboard-item:nth-child(4) { animation-delay: 0.25s; }
                .clipboard-item:nth-child(5) { animation-delay: 0.3s; }
                
                .loading {
                    text-align: center;
                    padding: 40px 20px;
                    opacity: 0.7;
                    font-size: 14px;
                }
                
                .empty-state {
                    text-align: center;
                    padding: 60px 20px;
                    opacity: 0.6;
                }
                
                .empty-state-icon {
                    font-size: 48px;
                    margin-bottom: 16px;
                    opacity: 0.4;
                    filter: drop-shadow(0 4px 8px rgba(0, 0, 0, 0.3));
                }
                
                .copy-feedback {
                    animation: pulseGlow 0.6s ease-out;
                }
                
                .feature-grid {
                    display: grid;
                    grid-template-columns: 1fr 1fr;
                    gap: 12px;
                    margin-top: 20px;
                }
                
                .feature-item {
                    background: rgba(255, 255, 255, 0.04);
                    border: 1px solid rgba(255, 255, 255, 0.08);
                    border-radius: 10px;
                    padding: 12px;
                    text-align: center;
                    font-size: 11px;
                    transition: all 0.3s ease;
                }
                
                .feature-item:hover {
                    background: rgba(255, 255, 255, 0.06);
                    transform: scale(1.02);
                }
                
                .feature-icon {
                    font-size: 16px;
                    margin-bottom: 6px;
                    display: block;
                }
            </style>
        </head>
        <body>
            <div class="overlay-container">
                <div class="header">
                    <h1>⚡ EdgeBoard</h1>
                    <div class="subtitle">Professional Productivity Suite</div>
                </div>
                
                <div class="content">
                    <div class="section">
                        <div class="section-title">
                            <span class="icon">📋</span>
                            Clipboard History
                        </div>
                        <div class="clipboard-history" id="clipboardHistory">
                            <div class="loading">Initializing clipboard manager...</div>
                        </div>
                    </div>
                    
                    <div class="section">
                        <div class="section-title">
                            <span class="icon">📊</span>
                            Quick Stats
                        </div>
                        <div class="stats" id="stats">
                            <div class="stat-card">
                                <div class="stat-number" id="totalItems">12</div>
                                <div class="stat-label">Total Items</div>
                            </div>
                            <div class="stat-card">
                                <div class="stat-number" id="todayItems">8</div>
                                <div class="stat-label">Today</div>
                            </div>
                        </div>
                    </div>
                    
                    <div class="section">
                        <div class="section-title">
                            <span class="icon">🛠</span>
                            Quick Tools
                        </div>
                        <div class="feature-grid">
                            <div class="feature-item" onclick="clearHistory()">
                                <span class="feature-icon">🗑</span>
                                Clear History
                            </div>
                            <div class="feature-item" onclick="exportHistory()">
                                <span class="feature-icon">📤</span>
                                Export
                            </div>
                            <div class="feature-item" onclick="toggleMonitoring()">
                                <span class="feature-icon">👁</span>
                                Monitor
                            </div>
                            <div class="feature-item" onclick="showSettings()">
                                <span class="feature-icon">⚙️</span>
                                Settings
                            </div>
                        </div>
                    </div>
                </div>
                
                <div class="footer">
                    Click any item to copy • EdgeBoard Professional v1.0
                </div>
            </div>
            
            <script>
                // Professional demo data with realistic clipboard content
                const professionalClipboardData = [
                    { type: 'TEXT', content: 'import SwiftUI\\nstruct ContentView: View {', time: '2 min ago', size: '156 bytes' },
                    { type: 'URL', content: 'https://developer.apple.com/documentation/swiftui', time: '5 min ago', size: '52 bytes' },
                    { type: 'TEXT', content: 'func applicationDidFinishLaunching(_ notification: Notification)', time: '8 min ago', size: '68 bytes' },
                    { type: 'FILE', content: 'EdgeBoard.xcodeproj', time: '12 min ago', size: '2.1 MB' },
                    { type: 'TEXT', content: 'NSWindow.Level.floating', time: '15 min ago', size: '24 bytes' },
                    { type: 'CODE', content: 'git commit -m "Add professional UI enhancements"', time: '18 min ago', size: '47 bytes' },
                    { type: 'TEXT', content: 'Professional Productivity Overlay', time: '22 min ago', size: '34 bytes' }
                ];
                
                function loadClipboardHistory() {
                    const historyContainer = document.getElementById('clipboardHistory');
                    
                    if (professionalClipboardData.length === 0) {
                        historyContainer.innerHTML = `
                            <div class="empty-state">
                                <div class="empty-state-icon">📝</div>
                                <div>Your clipboard history will appear here</div>
                            </div>
                        `;
                        return;
                    }
                    
                    historyContainer.innerHTML = professionalClipboardData.map((item, index) => `
                        <div class="clipboard-item" onclick="copyToClipboard('${item.content.replace(/'/g, "\\'")}', this)" style="animation-delay: ${index * 0.05}s">
                            <div class="clipboard-type">${item.type}</div>
                            <div class="clipboard-content" title="${item.content.replace(/'/g, "&apos;")}">${item.content}</div>
                            <div class="clipboard-time">${item.time}</div>
                        </div>
                    `).join('');
                }
                
                function loadStats() {
                    document.getElementById('totalItems').textContent = professionalClipboardData.length;
                    document.getElementById('todayItems').textContent = professionalClipboardData.filter(item => 
                        item.time.includes('min ago') || item.time.includes('hour ago')
                    ).length;
                }
                
                function copyToClipboard(content, element) {
                    console.log('Copying to clipboard:', content);
                    
                    // Add professional visual feedback
                    element.classList.add('copy-feedback');
                    const originalBg = element.style.background;
                    element.style.background = 'rgba(99, 102, 241, 0.25)';
                    
                    // Create floating notification
                    showCopyNotification('Copied to clipboard!');
                    
                    setTimeout(() => {
                        element.style.background = originalBg;
                        element.classList.remove('copy-feedback');
                    }, 600);
                }
                
                function showCopyNotification(message) {
                    // This would integrate with macOS notifications in the full implementation
                    console.log('Notification:', message);
                }
                
                function clearHistory() {
                    if (confirm('Clear all clipboard history?')) {
                        professionalClipboardData.length = 0;
                        loadClipboardHistory();
                        loadStats();
                        showCopyNotification('History cleared');
                    }
                }
                
                function exportHistory() {
                    showCopyNotification('Export feature coming soon');
                }
                
                function toggleMonitoring() {
                    showCopyNotification('Monitoring toggled');
                }
                
                function showSettings() {
                    showCopyNotification('Settings panel coming soon');
                }
                
                // Initialize the professional interface
                document.addEventListener('DOMContentLoaded', function() {
                    setTimeout(() => {
                        loadClipboardHistory();
                        loadStats();
                    }, 300);
                    
                    // Auto-refresh every 30 seconds
                    setInterval(() => {
                        loadStats();
                    }, 30000);
                });
            </script>
        </body>
        </html>
        """
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Cleanup resources
    }
}

// Main entry point
let app = NSApplication.shared
let delegate = EdgeBoardApp()
app.delegate = delegate
app.run()
