import { render, screen, fireEvent, waitFor, cleanup } from '@testing-library/react';
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import '@testing-library/jest-dom/vitest';
import PostsPage from '../../src/pages/Posts';
import PostService from '../../src/services/PostService';

// Mock the Service
vi.mock('../../src/services/PostService', () => ({
  default: {
    getAllPosts: vi.fn(),
    deletePost: vi.fn(),
    createPost: vi.fn(),
    updatePost: vi.fn(),
  },
}));

describe('PostsPage Integration', () => {
  const mockPosts = [
    { id: 1, title: 'First Post', content: 'Content 1', author: 'User A' },
    { id: 2, title: 'Second Post', content: 'Content 2', author: 'User B' },
  ];

  beforeEach(() => {
    vi.clearAllMocks();
    // Default behavior for loading the page
    (PostService.getAllPosts as any).mockResolvedValue(mockPosts);
  });

  afterEach(() => {
    cleanup();
  });

  it('loads and displays posts on mount', async () => {
    render(<PostsPage />);

    // Check if the service was called
    expect(PostService.getAllPosts).toHaveBeenCalled();

    // Check if posts appear on screen
    await waitFor(() => {
      expect(screen.getByText('First Post')).toBeInTheDocument();
      expect(screen.getByText('Second Post')).toBeInTheDocument();
    });
  });

  it('refreshes the list after creating a new post', async () => {
    (PostService.createPost as any).mockResolvedValue({ id: 3, title: 'New Post' });
    
    render(<PostsPage />);

    // Fill out the CreatePostForm (which is inside this page)
    fireEvent.change(screen.getByLabelText(/title/i), { target: { value: 'Third Post' } });
    fireEvent.change(screen.getByLabelText(/content/i), { target: { value: 'Third Content' } });
    
    const submitBtn = screen.getByRole('button', { name: /publish post/i });
    fireEvent.click(submitBtn);

    await waitFor(() => {
      // It should call createPost, then call getAllPosts again to refresh
      expect(PostService.createPost).toHaveBeenCalled();
      expect(PostService.getAllPosts).toHaveBeenCalledTimes(2);
    });
  });

  it('deletes a post and refreshes the list', async () => {
    (PostService.deletePost as any).mockResolvedValue({});
    
    render(<PostsPage />);

    // Wait for posts to load
    const deleteButtons = await screen.findAllByRole('button', { name: /delete/i });
    
    // Click delete on the first post (ID: 1)
    fireEvent.click(deleteButtons[0]);

    await waitFor(() => {
      expect(PostService.deletePost).toHaveBeenCalledWith(1);
      expect(PostService.getAllPosts).toHaveBeenCalledTimes(2);
    });
  });

  it('opens the edit modal when clicking edit', async () => {
    render(<PostsPage />);

    const editButtons = await screen.findAllByRole('button', { name: /edit/i });
    fireEvent.click(editButtons[0]);

    // Check if Modal appears
    expect(screen.getByText('Edit Post')).toBeInTheDocument();
    // Check if it populated the modal with the correct data
    expect(screen.getByDisplayValue('First Post')).toBeInTheDocument();
  });

  it('displays error message if loading posts fails', async () => {
    (PostService.getAllPosts as any).mockRejectedValueOnce(new Error('Network Failure'));
    
    render(<PostsPage />);

    await waitFor(() => {
      expect(screen.getByText(/error:/i)).toBeInTheDocument();
      expect(screen.getByText(/network failure/i)).toBeInTheDocument();
    });
  });
});