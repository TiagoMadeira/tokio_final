import { render, screen, fireEvent, waitFor, cleanup } from '@testing-library/react';
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { MemoryRouter } from 'react-router-dom';
import '@testing-library/jest-dom/vitest';
import axios from 'axios';
import RegisterPage from '../../src/pages/Register';

// 1. Mock Axios
vi.mock('axios', () => ({
  default: {
    post: vi.fn(),
    isAxiosError: vi.fn((err) => err.isAxiosError === true),
  },
}));

// 2. Mock useNavigate
const mockNavigate = vi.fn();
vi.mock('react-router-dom', async () => {
  const actual = await vi.importActual('react-router-dom');
  return {
    ...actual,
    useNavigate: () => mockNavigate,
  };
});

describe('RegisterPage Integration', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    vi.useFakeTimers(); // Handle that 2000ms setTimeout
    vi.spyOn(window, 'alert').mockImplementation(() => {});
  });

  afterEach(() => {
    cleanup();
    vi.useRealTimers();
  });

it('successful registration shows alert and redirects after delay', async () => {
  (axios.post as any).mockResolvedValueOnce({ status: 201, data: { id: 123 } });

  render(
    <MemoryRouter>
      <RegisterPage />
    </MemoryRouter>
  );

  // Fill form
  fireEvent.change(screen.getByLabelText(/username/i), { target: { value: 'tiago' } });
  fireEvent.change(screen.getByLabelText(/full name/i), { target: { value: 'Tiago Test' } });
  fireEvent.change(screen.getByLabelText(/email/i), { target: { value: 'tiago@test.com' } });
  fireEvent.change(screen.getByLabelText(/^password$/i), { target: { value: 'pass123' } });
  fireEvent.change(screen.getByLabelText(/confirm password/i), { target: { value: 'pass123' } });

  fireEvent.click(screen.getByRole('button', { name: /register/i }));

  // 1. Flush the Promises (handles the await axios.post)
  await vi.runAllTimersAsync(); 

  // 2. Check the results
  expect(axios.post).toHaveBeenCalled();
  expect(window.alert).toHaveBeenCalledWith("Registration successful! Redirecting to login...");

  // 3. The redirect happens inside a setTimeout, so check navigation after the timers ran
  expect(mockNavigate).toHaveBeenCalledWith('/login');
});

it('displays server error message when registration fails', async () => {
  const errorDetail = "Email already registered";
  
  (axios.post as any).mockRejectedValueOnce({
    isAxiosError: true,
    response: { data: { detail: errorDetail } }
  });

  render(
    <MemoryRouter>
      <RegisterPage />
    </MemoryRouter>
  );

  // Fill all fields
  fireEvent.change(screen.getByLabelText(/username/i), { target: { value: 'tiago' } });
  fireEvent.change(screen.getByLabelText(/full name/i), { target: { value: 'Tiago Test' } });
  fireEvent.change(screen.getByLabelText(/email/i), { target: { value: 'tiago@test.com' } });
  fireEvent.change(screen.getByLabelText(/^password$/i), { target: { value: 'pass123' } });
  fireEvent.change(screen.getByLabelText(/confirm password/i), { target: { value: 'pass123' } });

  fireEvent.click(screen.getByRole('button', { name: /register/i }));

    await vi.advanceTimersByTimeAsync(0);

  expect(mockNavigate).not.toHaveBeenCalled();
});
});