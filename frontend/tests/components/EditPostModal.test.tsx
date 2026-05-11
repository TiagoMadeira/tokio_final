import { render, screen, fireEvent, waitFor, cleanup } from '@testing-library/react';
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import '@testing-library/jest-dom/vitest';
import EditPostModal from '../../src/components/EditPostModal';
import PostService from '../../src/services/PostService';
import { Post } from '../../src/types';

vi.mock('../../src/services/PostService', () => ({
  default: {
    updatePost: vi.fn(),
  },
}));

describe('EditPostModal', () => {
  const mockPost: Post = { id: 1, title: 'Old Title', content: 'Old Content', author: 'Test Author' };
  const mockOnUpdate = vi.fn();
  const mockOnCancel = vi.fn();

    afterEach(() => {
        cleanup(); // This clears the DOM after every test
    });
    beforeEach(() => {
        vi.clearAllMocks();
    });

  it('renders with existing post data', () => {
    render(<EditPostModal post={mockPost} onUpdate={mockOnUpdate} onCancel={mockOnCancel} />);
    
    expect(screen.getByLabelText(/title/i)).toHaveValue('Old Title');
    expect(screen.getByLabelText(/content/i)).toHaveValue('Old Content');
  });

  it('calls onCancel when the Close or Cancel button is clicked', () => {
    render(<EditPostModal post={mockPost} onUpdate={mockOnUpdate} onCancel={mockOnCancel} />);
    
    fireEvent.click(screen.getByRole('button', { name: /cancel/i }));
    expect(mockOnCancel).toHaveBeenCalledTimes(1);
  });

  it('submits updated data and calls onUpdate', async () => {
    const updatedPost = { ...mockPost, title: 'New Title' };
    vi.mocked(PostService.updatePost).mockResolvedValueOnce(updatedPost);

    render(<EditPostModal post={mockPost} onUpdate={mockOnUpdate} onCancel={mockOnCancel} />);

    const titleInput = screen.getByLabelText(/title/i);
    fireEvent.change(titleInput, { target: { value: 'New Title' } });
    
    fireEvent.click(screen.getByRole('button', { name: /save changes/i }));

    await waitFor(() => {
      expect(PostService.updatePost).toHaveBeenCalledWith(mockPost.id, expect.objectContaining({
        title: 'New Title'
      }));
      expect(mockOnUpdate).toHaveBeenCalledWith(updatedPost);
    });
  });

  it('shows an error alert message when the service fails', async () => {
    const errorMessage = 'Server Error';
    (PostService.updatePost as any).mockRejectedValueOnce(new Error(errorMessage));

    render(<EditPostModal post={mockPost} onUpdate={mockOnUpdate} onCancel={mockOnCancel} />);
    
    fireEvent.click(screen.getByRole('button', { name: /save changes/i }));

    // Verify the UI alert appears instead of window.alert
    await waitFor(() => {
      const alert = screen.getByRole('alert');
      expect(alert).toBeInTheDocument();
      expect(alert).toHaveTextContent(errorMessage);
    });
    
    expect(mockOnUpdate).not.toHaveBeenCalled();
  });
});