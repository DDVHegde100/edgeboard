import React, { useState, useEffect } from 'react';

const App: React.FC = () => {
  const [isReady, setIsReady] = useState(false);
  const [time, setTime] = useState(new Date());

  useEffect(() => {
    setIsReady(true);
    
    // Update time every second
    const timer = setInterval(() => {
      setTime(new Date());
    }, 1000);

    return () => clearInterval(timer);
  }, []);

  if (!isReady) {
    return (
      <div className="loading">
        <div className="loading-spinner"></div>
        <p>Loading EdgeBoard...</p>
      </div>
    );
  }

  return (
    <div className="edgeboard-app">
      {/* Header */}
      <div className="header gradient-header">
        <div className="logo">
          <span className="logo-icon gradient-logo">EdgeBoard</span>
        </div>
        <div className="time">
          {time.toLocaleTimeString([], { 
            hour: '2-digit', 
            minute: '2-digit' 
          })}
        </div>
      </div>

      {/* Main Content */}
      <div className="main-content">
        <div className="glass-panel pro-glass">
          <h2 className="gradient-title">Welcome to EdgeBoard</h2>
          <p className="subtitle">Your productivity overlay is ready!</p>

          <div className="quick-stats">
            <div className="stat-item">
              <span className="stat-label">Status</span>
              <span className="stat-value online">Online</span>
            </div>
            <div className="stat-item">
              <span className="stat-label">Version</span>
              <span className="stat-value">0.1.0</span>
            </div>
          </div>

          <div className="action-buttons">
            <button className="btn primary gradient-btn">Clipboard</button>
            <button className="btn secondary glass-btn">Launcher</button>
            <button className="btn secondary glass-btn">Monitor</button>
          </div>
        </div>
      </div>

      {/* Footer */}
      <div className="footer">
        <span>Ready for productivity</span>
      </div>
    </div>
  );
}

export default App;
