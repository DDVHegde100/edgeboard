// Test setup file for Jest
import '@testing-library/jest-dom';

// Mock window.edgeboard for testing
(global as any).window = {
  edgeboard: {
    getClipboard: jest.fn(),
    setClipboard: jest.fn(),
    getSystemInfo: jest.fn(),
    openApp: jest.fn(),
    sendNotification: jest.fn(),
  }
};

// Mock ResizeObserver
global.ResizeObserver = jest.fn().mockImplementation(() => ({
  observe: jest.fn(),
  unobserve: jest.fn(),
  disconnect: jest.fn(),
}));

// Mock IntersectionObserver
global.IntersectionObserver = jest.fn().mockImplementation(() => ({
  observe: jest.fn(),
  unobserve: jest.fn(),
  disconnect: jest.fn(),
}));
