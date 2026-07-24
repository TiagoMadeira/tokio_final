import { render, screen, fireEvent, waitFor, cleanup  } from '@testing-library/react';
import '@testing-library/jest-dom/vitest';
import { describe, it, expect, vi, beforeEach,afterEach } from 'vitest';
import CreatePostForm from '../../src/components/CreatePostForm';
import PostService from '../../src/services/PostService';

// Mock the PostService
vi.mock('../../src/services/PostService', () => ({
  default: {
    createPost: vi.fn(),
  },
}));

describe('CreatePostForm', () => {
  const mockOnPostCreated = vi.fn();

  afterEach(() => {
    cleanup(); // This clears the DOM after every test
  });

  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('renders the form fields correctly', () => {
    render(<CreatePostForm onPostCreated={mockOnPostCreated} />);
    
    expect(screen.getByLabelText(/title/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/content/i)).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /publish post/i })).toBeInTheDocument();
  });

  it('updates state on input change', () => {
    render(<CreatePostForm onPostCreated={mockOnPostCreated} />);
    
    const titleInput = screen.getByLabelText(/title/i) as HTMLInputElement;
    fireEvent.change(titleInput, { target: { value: 'New Post Title' } });
    
    expect(titleInput.value).toBe('New Post Title');
  });

  it('calls PostService and refreshes list on successful submit', async () => {
    vi.mocked(PostService.createPost).mockResolvedValueOnce({ id: 1, title: 'Test', content: 'Test', author: 'Test author'});
    
    render(<CreatePostForm onPostCreated={mockOnPostCreated} />);
    
    fireEvent.change(screen.getByLabelText(/title/i), { target: { value: 'Hello' } });
    fireEvent.change(screen.getByLabelText(/content/i), { target: { value: 'World' } });
    fireEvent.click(screen.getByRole('button', { name: /publish post/i }));

    // Check if loading state triggers
    expect(screen.getByText(/publishing.../i)).toBeInTheDocument();

    await waitFor(() => {
      expect(PostService.createPost).toHaveBeenCalledWith({ title: 'Hello', content: 'World' });
      expect(mockOnPostCreated).toHaveBeenCalled();
    });

    // Check if form is cleared
    expect((screen.getByLabelText(/title/i) as HTMLInputElement).value).toBe('');
  });

  it('displays error message if submission fails', async () => {
  const errorMessage = 'Network Error';
  vi.mocked(PostService.createPost).mockRejectedValueOnce(new Error(errorMessage));

  render(<CreatePostForm onPostCreated={mockOnPostCreated} />);
  
  // Fill the required fields first!
  fireEvent.change(screen.getByLabelText(/title/i), { target: { value: 'Some Title' } });
  fireEvent.change(screen.getByLabelText(/content/i), { target: { value: 'Some Content' } });
  
  // Now click publish
  fireEvent.click(screen.getByRole('button', { name: /publish post/i }));

  await waitFor(() => {
    // Look for the specific error message text
    expect(screen.getByText(new RegExp(errorMessage, 'i'))).toBeInTheDocument();
  });
  
  expect(mockOnPostCreated).not.toHaveBeenCalled();
});
});