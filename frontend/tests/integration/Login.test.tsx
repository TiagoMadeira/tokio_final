import { render, screen, fireEvent, waitFor, cleanup } from '@testing-library/react';
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import '@testing-library/jest-dom/vitest';
import axios from 'axios';
import Login from '../../src/pages/Login';

// Mock axios
vi.mock('axios', () => ({
  default: {
    postForm: vi.fn(),
    isAxiosError: vi.fn((err) => err.isAxiosError === true),
  },
}));

describe('Login Page Integration', () => {
  const originalLocation = window.location;

  beforeEach(() => {
    localStorage.clear();
    vi.clearAllMocks();
    
    // Mock window.location.href
    // @ts-ignore
    delete window.location;
    window.location = { ...originalLocation, href: '' } as any;
  });

  afterEach(() => {
    cleanup();
  });

  it('successful login saves token and redirects to /posts', async () => {
    const fakeToken = 'secret-jwt-token';
    // Mock successful response
    (axios.postForm as any).mockResolvedValueOnce({
      data: { access_token: fakeToken, token_type: 'bearer' }
    });

    render(<Login />);

    // Simulating user typing
    fireEvent.change(screen.getByLabelText(/username/i), { target: { value: 'tiago_user' } });
    fireEvent.change(screen.getByLabelText(/password/i), { target: { value: 'password123' } });
    
    // Clicking submit
    fireEvent.click(screen.getByRole('button', { name: /submit/i }));

    await waitFor(() => {
      // 1. Verify API was called correctly (using FormData)
      expect(axios.postForm).toHaveBeenCalledWith('/api/login', expect.any(FormData));
      
      // 2. Verify localStorage was updated
      expect(localStorage.getItem('authToken')).toBe(fakeToken);
      
      // 3. Verify redirect happened
      expect(window.location.href).toBe('/posts');
    });
  });

  it('failed login displays error message from server', async () => {
    // Mock an Axios Error
    const errorMessage = 'Invalid credentials';
    (axios.postForm as any).mockRejectedValueOnce({
      isAxiosError: true,
      response: {
        data: { detail: errorMessage }
      }
    });

    render(<Login />);

    fireEvent.change(screen.getByLabelText(/username/i), { target: { value: 'wrong_user' } });
    fireEvent.change(screen.getByLabelText(/password/i), { target: { value: 'wrong_pass' } });
    fireEvent.click(screen.getByRole('button', { name: /submit/i }));

    await waitFor(() => {
      // Verify error alert appears with server message
      const alert = screen.getByRole('alert');
      expect(alert).toHaveTextContent(errorMessage);
    });

    // Verify token was NOT saved and no redirect happened
    expect(localStorage.getItem('authToken')).toBeNull();
    expect(window.location.href).not.toBe('/posts');
  });

  it('shows validation errors if fields are empty (HTML5)', () => {
    render(<Login />);
    
    const submitBtn = screen.getByRole('button', { name: /submit/i });
    fireEvent.click(submitBtn);

    // If HTML5 validation works, axios should never be called
    expect(axios.postForm).not.toHaveBeenCalled();
  });
});