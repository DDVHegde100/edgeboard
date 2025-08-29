// Shared TypeScript interfaces for EdgeBoard
import { ReactNode } from 'react';

// Native Bridge Interface
export interface EdgeBoardNativeBridge {
  // Clipboard operations
  getClipboard(): Promise<string>;
  setClipboard(content: string): Promise<void>;
  getClipboardHistory(): Promise<ClipboardItem[]>;
  
  // System operations
  getSystemInfo(): Promise<SystemInfo>;
  openApp(appName: string): Promise<void>;
  searchFiles(query: string): Promise<FileSearchResult[]>;
  
  // Window operations
  setWindowPosition(x: number, y: number): Promise<void>;
  setWindowSize(width: number, height: number): Promise<void>;
  
  // Notifications
  sendNotification(title: string, body: string): Promise<void>;
}

// Clipboard types
export interface ClipboardItem {
  id: string;
  content: string;
  type: 'text' | 'image' | 'file' | 'rich';
  timestamp: Date;
  source?: string;
}

// System monitoring types
export interface SystemInfo {
  cpu: {
    usage: number;
    temperature?: number;
  };
  memory: {
    used: number;
    total: number;
    pressure: 'normal' | 'warning' | 'critical';
  };
  disk: {
    used: number;
    total: number;
  };
  network: {
    upload: number;
    download: number;
  };
}

// File search types
export interface FileSearchResult {
  name: string;
  path: string;
  type: 'file' | 'directory' | 'application';
  size?: number;
  lastModified?: Date;
  icon?: string;
}

// Application types
export interface AppInfo {
  name: string;
  bundleId: string;
  path: string;
  icon?: string;
  isRunning: boolean;
}

// Settings and configuration
export interface UserSettings {
  appearance: {
    theme: 'light' | 'dark' | 'auto';
    glassmorphism: boolean;
    animations: boolean;
  };
  behavior: {
    autoStart: boolean;
    position: 'left' | 'right' | 'top' | 'bottom';
    hotkey: string;
    alwaysOnTop: boolean;
  };
  features: {
    clipboard: {
      enabled: boolean;
      maxHistory: number;
      syncAcrossDevices: boolean;
    };
    quickLauncher: {
      enabled: boolean;
      includeFiles: boolean;
      maxResults: number;
    };
    systemMonitor: {
      enabled: boolean;
      updateInterval: number;
    };
  };
}

// Component prop types
export interface BaseComponentProps {
  className?: string;
  children?: ReactNode;
}

export interface PanelProps extends BaseComponentProps {
  title?: string;
  collapsible?: boolean;
  defaultCollapsed?: boolean;
}

// Error types
export interface EdgeBoardError {
  code: string;
  message: string;
  details?: any;
  timestamp: Date;
}

// Window declaration for TypeScript
declare global {
  interface Window {
    edgeboard: EdgeBoardNativeBridge;
  }
}
