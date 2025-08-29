import Cocoa
import WebKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var webView: WKWebView!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupWindow()
        setupWebView()
        loadReactApp()
        
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
    
    func setupWindow() {
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 400, height: 600)
        let windowRect = NSRect(
            x: screenFrame.maxX - 420,  // 20px from right edge
            y: screenFrame.midY - 300,  // Centered vertically
            width: 400,
            height: 600
        )
        
        window = NSWindow(
            contentRect: windowRect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "EdgeBoard"
        window.level = .floating  // Always on top
        window.isOpaque = false
        window.backgroundColor = NSColor.clear
        window.hasShadow = true
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
    }
    
    func setupWebView() {
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")
        
        webView = WKWebView(frame: window.contentView!.bounds, configuration: config)
        webView.autoresizingMask = [.width, .height]
        webView.setValue(false, forKey: "drawsBackground")
        
        window.contentView?.addSubview(webView)
    }
    
    func loadReactApp() {
        // In development, load from webpack dev server
        if let url = URL(string: "http://localhost:3000") {
            webView.load(URLRequest(url: url))
        } else {
            // Fallback to local file
            loadLocalHTML()
        }
    }
    
    func loadLocalHTML() {
        let htmlContent = """
        <!DOCTYPE html>
        <html>
        <head>
            <title>EdgeBoard</title>
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                    background: linear-gradient(135deg, rgba(74, 144, 226, 0.3), rgba(143, 148, 251, 0.3));
                    color: white;
                    margin: 0;
                    padding: 20px;
                    text-align: center;
                    height: 100vh;
                    display: flex;
                    flex-direction: column;
                    justify-content: center;
                }
                .glass {
                    background: rgba(255, 255, 255, 0.1);
                    border: 1px solid rgba(255, 255, 255, 0.2);
                    border-radius: 16px;
                    padding: 30px;
                    backdrop-filter: blur(20px);
                    -webkit-backdrop-filter: blur(20px);
                }
                h1 { margin: 0 0 10px 0; }
                p { opacity: 0.8; margin: 0; }
            </style>
        </head>
        <body>
            <div class="glass">
                <h1>⚡ EdgeBoard</h1>
                <p>Your productivity overlay is ready!</p>
                <p style="margin-top: 20px; font-size: 14px;">React app will load here...</p>
            </div>
        </body>
        </html>
        """
        
        webView.loadHTMLString(htmlContent, baseURL: nil)
    }
}

// Main entry point
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
