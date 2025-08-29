import Cocoa
import WebKit

class EdgeBoardApp: NSObject, NSApplicationDelegate {
    var overlayWindow: NSWindow!
    var webView: WKWebView!
    var isVisible = false
    var statusItem: NSStatusItem?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusBarItem()
        setupOverlayWindow()
        setupWebView()
        loadLocalHTML()
        
        // Hide dock icon and make it a background app
        NSApp.setActivationPolicy(.accessory)
        
        // Register global hotkey (Cmd+Shift+E)
        setupGlobalHotkey()
    }
    
    func setupStatusBarItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem?.button {
            button.title = "⚡"
            button.action = #selector(toggleOverlay)
            button.target = self
            button.toolTip = "EdgeBoard - Click to toggle overlay"
        }
    }
    
    func setupOverlayWindow() {
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        
        // Create a narrow overlay window on the right edge
        let windowRect = NSRect(
            x: screenFrame.maxX - 350,  // 350px wide, 20px from edge
            y: screenFrame.minY + 100,  // 100px from bottom
            width: 320,
            height: screenFrame.height - 200  // Leave 100px top and bottom
        )
        
        overlayWindow = NSWindow(
            contentRect: windowRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        // Configure overlay properties
        overlayWindow.level = NSWindow.Level.screenSaver  // Always on top
        overlayWindow.isOpaque = false
        overlayWindow.backgroundColor = NSColor.clear
        overlayWindow.hasShadow = true
        overlayWindow.ignoresMouseEvents = false
        overlayWindow.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        
        // Initially hidden
        overlayWindow.orderOut(nil)
    }
    
    func setupWebView() {
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")
        
        // Allow transparent background
        config.setValue(false, forKey: "drawsBackground")
        
        webView = WKWebView(frame: overlayWindow.contentView!.bounds, configuration: config)
        webView.autoresizingMask = [.width, .height]
        webView.setValue(false, forKey: "drawsBackground")
        
        // Add edge detection for mouse interactions
        addMouseTrackingArea()
        
        overlayWindow.contentView?.addSubview(webView)
    }
    
    func addMouseTrackingArea() {
        let trackingArea = NSTrackingArea(
            rect: webView.bounds,
            options: [.activeAlways, .mouseEnteredAndExited, .mouseMoved],
            owner: self,
            userInfo: nil
        )
        webView.addTrackingArea(trackingArea)
    }
    
    func setupGlobalHotkey() {
        // Note: In a production app, you'd use proper hotkey registration
        // For now, we'll use the status bar item
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
    
    func loadLocalHTML() {
        let htmlContent = """
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
                    font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Display', sans-serif;
                    background: transparent;
                    overflow-x: hidden;
                    color: white;
                }
                
                .edgeboard-overlay {
                    width: 100vw;
                    height: 100vh;
                    background: linear-gradient(135deg, 
                        rgba(0, 0, 0, 0.7) 0%, 
                        rgba(30, 30, 30, 0.8) 100%);
                    backdrop-filter: blur(20px);
                    -webkit-backdrop-filter: blur(20px);
                    border-left: 1px solid rgba(255, 255, 255, 0.1);
                    display: flex;
                    flex-direction: column;
                }
                
                .header {
                    padding: 20px 16px 16px 16px;
                    border-bottom: 1px solid rgba(255, 255, 255, 0.1);
                    text-align: center;
                }
                
                .logo {
                    font-size: 18px;
                    font-weight: 600;
                    margin-bottom: 8px;
                }
                
                .time {
                    font-family: 'SF Mono', monospace;
                    font-size: 14px;
                    opacity: 0.7;
                }
                
                .main-content {
                    flex: 1;
                    padding: 20px 16px;
                    overflow-y: auto;
                }
                
                .widget {
                    background: rgba(255, 255, 255, 0.05);
                    border: 1px solid rgba(255, 255, 255, 0.1);
                    border-radius: 12px;
                    padding: 16px;
                    margin-bottom: 16px;
                    transition: all 0.2s ease;
                    cursor: pointer;
                }
                
                .widget:hover {
                    background: rgba(255, 255, 255, 0.1);
                    transform: translateX(-2px);
                }
                
                .widget h3 {
                    font-size: 14px;
                    margin-bottom: 8px;
                    display: flex;
                    align-items: center;
                    gap: 8px;
                }
                
                .widget p {
                    font-size: 12px;
                    opacity: 0.7;
                    line-height: 1.4;
                }
                
                .quick-actions {
                    display: grid;
                    grid-template-columns: 1fr 1fr;
                    gap: 12px;
                    margin-bottom: 20px;
                }
                
                .action-btn {
                    background: rgba(0, 122, 255, 0.2);
                    border: 1px solid rgba(0, 122, 255, 0.3);
                    border-radius: 8px;
                    padding: 12px 8px;
                    color: white;
                    font-size: 12px;
                    text-align: center;
                    cursor: pointer;
                    transition: all 0.2s ease;
                }
                
                .action-btn:hover {
                    background: rgba(0, 122, 255, 0.3);
                    transform: translateY(-1px);
                }
                
                .system-stats {
                    display: flex;
                    justify-content: space-between;
                    font-size: 11px;
                    margin-top: 8px;
                }
                
                .stat {
                    text-align: center;
                }
                
                .stat-value {
                    font-weight: 600;
                    color: #34C759;
                }
                
                .footer {
                    padding: 12px 16px;
                    border-top: 1px solid rgba(255, 255, 255, 0.1);
                    text-align: center;
                    font-size: 11px;
                    opacity: 0.5;
                }
                
                ::-webkit-scrollbar {
                    width: 4px;
                }
                
                ::-webkit-scrollbar-track {
                    background: transparent;
                }
                
                ::-webkit-scrollbar-thumb {
                    background: rgba(255, 255, 255, 0.2);
                    border-radius: 2px;
                }
            </style>
        </head>
        <body>
            <div class="edgeboard-overlay">
                <div class="header">
                    <div class="logo">⚡ EdgeBoard</div>
                    <div class="time" id="time"></div>
                </div>
                
                <div class="main-content">
                    <div class="quick-actions">
                        <div class="action-btn" onclick="alert('Clipboard feature coming soon!')">
                            📋 Clipboard
                        </div>
                        <div class="action-btn" onclick="alert('Launcher feature coming soon!')">
                            🚀 Launch
                        </div>
                        <div class="action-btn" onclick="alert('Notes feature coming soon!')">
                            📝 Notes
                        </div>
                        <div class="action-btn" onclick="alert('Timer feature coming soon!')">
                            ⏱️ Timer
                        </div>
                    </div>
                    
                    <div class="widget">
                        <h3>📊 System Monitor</h3>
                        <p>Real-time system performance</p>
                        <div class="system-stats">
                            <div class="stat">
                                <div>CPU</div>
                                <div class="stat-value">12%</div>
                            </div>
                            <div class="stat">
                                <div>Memory</div>
                                <div class="stat-value">6.2GB</div>
                            </div>
                            <div class="stat">
                                <div>Disk</div>
                                <div class="stat-value">45%</div>
                            </div>
                        </div>
                    </div>
                    
                    <div class="widget">
                        <h3>🌤️ Weather</h3>
                        <p>Current conditions and forecast</p>
                    </div>
                    
                    <div class="widget">
                        <h3>📋 Recent Clips</h3>
                        <p>Your clipboard history (empty)</p>
                    </div>
                    
                    <div class="widget">
                        <h3>⚡ Quick Notes</h3>
                        <p>Capture thoughts instantly</p>
                    </div>
                </div>
                
                <div class="footer">
                    EdgeBoard v0.1.0 - Ready
                </div>
            </div>
            
            <script>
                // Update time every second
                function updateTime() {
                    const now = new Date();
                    const timeString = now.toLocaleTimeString([], { 
                        hour: '2-digit', 
                        minute: '2-digit',
                        second: '2-digit'
                    });
                    document.getElementById('time').textContent = timeString;
                }
                
                updateTime();
                setInterval(updateTime, 1000);
                
                // Simulate system stats updates
                setInterval(() => {
                    const stats = document.querySelectorAll('.stat-value');
                    if (stats[0]) stats[0].textContent = Math.floor(Math.random() * 50) + '%';
                    if (stats[1]) stats[1].textContent = (Math.random() * 8 + 4).toFixed(1) + 'GB';
                    if (stats[2]) stats[2].textContent = Math.floor(Math.random() * 30 + 40) + '%';
                }, 3000);
            </script>
        </body>
        </html>
        """
        
        webView.loadHTMLString(htmlContent, baseURL: nil)
    }
}

// Main entry point
let app = NSApplication.shared
let delegate = EdgeBoardApp()
app.delegate = delegate
app.run()
