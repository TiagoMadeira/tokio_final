import { beforeEach, describe, expect, it, vi } from 'vitest';
import axios from 'axios';
import api from '../../src/api/client'; // Adjust the import path to match your file layout

// Mock window.location
const mockLocation = {
  origin: 'http://localhost:3000',
  href: 'http://localhost:3000/dashboard',
};
vi.stubGlobal('location', mockLocation);

describe('API Axios Instance Client', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    localStorage.clear();
    mockLocation.href = 'http://localhost:3000/dashboard';
  });

  describe('Base Configuration', () => {
    it('should configure the correct baseURL', () => {
      expect(api.defaults.baseURL).toBe('/api/');
    });
  });

    describe('Request Interceptor - Security Checks', () => {
    it('should allow valid internal API requests', async () => {
      const config = { url: 'users', headers: axios.AxiosHeaders.from({}) };
      
      // Add [0] here to access the first registered interceptor
      // @ts-ignore
      const requestHandler = api.interceptors.request.handlers[0].fulfilled;
      
      const result = await requestHandler(config as any);
      expect(result).toBeDefined();
    });

    it('should block and throw on unauthorized external domain requests', () => {
      const config = { 
        url: 'https://malicious-external-domain.com', 
        headers: axios.AxiosHeaders.from({}) 
      };
      
      // @ts-ignore
      const requestHandler = api.interceptors.request.handlers[0].fulfilled;

      // Wrap the call in an arrow function to catch synchronous errors
      expect(() => requestHandler(config as any)).toThrow(
        'Security Violation: Unauthorized external request blocked.'
      );
    });

    it('should block and throw if the URL path context escapes /api/', () => {
      const config = { 
        url: 'http://localhost:3000/malicious-path', 
        headers: axios.AxiosHeaders.from({}) 
      };
      
      // @ts-ignore
      const requestHandler = api.interceptors.request.handlers[0].fulfilled;

      // Wrap the call in an arrow function to catch synchronous errors
      expect(() => requestHandler(config as any)).toThrow(
        'Security Violation: Invalid URL pathway context.'
      );
    });
  });

  describe('Request Interceptor - Authentication', () => {
    it('should inject a Bearer token into headers if present in localStorage', async () => {
      localStorage.setItem('authToken', 'test-jwt-token-xyz');
      // Initialize headers correctly using AxiosHeaders
      const config = { url: 'profile', headers: axios.AxiosHeaders.from({}) };
      // @ts-ignore
      const requestHandler = api.interceptors.request.handlers[0].fulfilled;

      // Cast as any to satisfy compiler expectations
      const result = await requestHandler(config as any);
      expect(result.headers.Authorization).toBe('Bearer test-jwt-token-xyz');
    });

    it('should not modify headers if no token exists in localStorage', async () => {
      const config = { url: 'profile', headers: axios.AxiosHeaders.from({}) };
      // @ts-ignore
      const requestHandler = api.interceptors.request.handlers[0].fulfilled;

      const result = await requestHandler(config as any);
      expect(result.headers.Authorization).toBeUndefined();
    });
  });

describe('Response Interceptor - Error Handling', () => {
    // Cast explicitly to any to allow direct invocation in the tests below
    // @ts-ignore
    const errorHandler = api.interceptors.response.handlers[0].rejected as any;

    it('should clear token and redirect to login on 401 Unauthorized errors', async () => {
      localStorage.setItem('authToken', 'expired-token');
      const errorMock = {
        response: {
          status: 401,
        },
      };

      await expect(errorHandler(errorMock)).rejects.toThrow(
        'Session expired. Please login again.'
      );
      expect(localStorage.getItem('authToken')).toBeNull();
      expect(mockLocation.href).toBe('/login');
    });

    it('should yield an Internal Server Error message on a 500 error status code', async () => {
      const errorMock = {
        response: {
          status: 500,
        },
      };

      await expect(errorHandler(errorMock)).rejects.toThrow(
        'Internal server error. Please try again later.'
      );
    });

    it('should fall back to custom backend error details on unhandled response codes', async () => {
      const errorMock = {
        response: {
          status: 400,
          data: { detail: 'Custom validation message from server' },
        },
      };

      await expect(errorHandler(errorMock)).rejects.toThrow(
        'Custom validation message from server'
      );
    });

    it('should generate a network error warning if no response payload is caught', async () => {
      const errorMock = {
        request: {}, // Indicates a connection attempt happened but timed out or failed
      };

      await expect(errorHandler(errorMock)).rejects.toThrow(
        'Network error. Please check if the backend is running.'
      );
    });

    it('should return a default backup string for unknown error exceptions', async () => {
      const errorMock = new Error('Random system crash');

      await expect(errorHandler(errorMock)).rejects.toThrow(
        'An unexpected error occurred'
      );
    });
  });
});