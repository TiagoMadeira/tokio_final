import { render, screen, fireEvent, cleanup } from '@testing-library/react';
import { describe, it, expect, vi, afterEach } from 'vitest';
import '@testing-library/jest-dom/vitest';
import PostItem from '../../src/components/PostItem';
import type { Post } from '../../src/types';

describe('PostItem Component', () => {
  const mockPost: Post = {
    id: 1,
    title: 'Test Post Title',
    author: 'John Doe',
    content: 'This is the test content of the post.'
  };

  const mockOnDelete = vi.fn();
  const mockOnEdit = vi.fn();

  afterEach(() => {
    cleanup();
    vi.clearAllMocks();
  });

  it('renders the post details correctly', () => {
    render(<PostItem post={mockPost} />);

    expect(screen.getByText(mockPost.title)).toBeInTheDocument();
    expect(screen.getByText(`Author: ${mockPost.author}`)).toBeInTheDocument();
    expect(screen.getByText(mockPost.content)).toBeInTheDocument();
  });

  it('calls onEdit when the Edit button is clicked', () => {
    render(<PostItem post={mockPost} onEdit={mockOnEdit} />);
    
    const editButton = screen.getByRole('button', { name: /edit/i });
    fireEvent.click(editButton);

    expect(mockOnEdit).toHaveBeenCalledTimes(1);
  });

  it('calls onDelete when the Delete button is clicked', () => {
    render(<PostItem post={mockPost} onDelete={mockOnDelete} />);
    
    const deleteButton = screen.getByRole('button', { name: /delete/i });
    fireEvent.click(deleteButton);

    expect(mockOnDelete).toHaveBeenCalledTimes(1);
  });

  it('does not crash if optional callbacks are not provided', () => {
    render(<PostItem post={mockPost} />);
    
    const editButton = screen.getByRole('button', { name: /edit/i });
    const deleteButton = screen.getByRole('button', { name: /delete/i });

    // Clicking should not throw errors even if props are undefined
    expect(() => fireEvent.click(editButton)).not.toThrow();
    expect(() => fireEvent.click(deleteButton)).not.toThrow();
  });
});