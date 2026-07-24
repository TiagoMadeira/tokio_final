import { render, screen, fireEvent, cleanup } from '@testing-library/react';
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { MemoryRouter } from 'react-router-dom';
import '@testing-library/jest-dom/vitest';
import Header from '../../src/components/Header';

describe('Header Component', () => {
  // Mock window.location.href
  const originalLocation = window.location;

    afterEach(() => {
        cleanup(); // This clears the DOM after every test
    });
    
  beforeEach(() => {
    localStorage.clear();
    vi.clearAllMocks();
    
    // We have to delete and re-assign window.location to mock it
    // @ts-ignore
    delete window.location;
    window.location = { ...originalLocation, href: '' } as any;
  });

  it('renders Login and Sign Up links when NOT authenticated', () => {
    render(
      <MemoryRouter>
        <Header />
      </MemoryRouter>
    );

    expect(screen.getByText(/login/i)).toBeInTheDocument();
    expect(screen.getByText(/sign up/i)).toBeInTheDocument();
    expect(screen.queryByText(/logout/i)).not.toBeInTheDocument();
  });

  it('renders Logout button when authenticated', () => {
    localStorage.setItem('authToken', 'fake-token');

    render(
      <MemoryRouter>
        <Header />
      </MemoryRouter>
    );

    expect(screen.getByRole('button', { name: /logout/i })).toBeInTheDocument();
    expect(screen.queryByText(/login/i)).not.toBeInTheDocument();
  });

  it('clears token and redirects on logout click', () => {
    localStorage.setItem('authToken', 'fake-token');

    render(
      <MemoryRouter>
        <Header />
      </MemoryRouter>
    );

    const logoutBtn = screen.getByRole('button', { name: /logout/i });
    fireEvent.click(logoutBtn);

    expect(localStorage.getItem('authToken')).toBeNull();
    expect(window.location.href).toBe('/login');
  });

  it('always shows the All Posts link', () => {
    render(
      <MemoryRouter>
        <Header />
      </MemoryRouter>
    );
    expect(screen.getByText(/all posts/i)).toBeInTheDocument();
  });
});