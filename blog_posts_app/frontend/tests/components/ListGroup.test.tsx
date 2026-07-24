import { render, screen, fireEvent, cleanup } from '@testing-library/react';
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import '@testing-library/jest-dom/vitest';
import ListGroup from '../../src/components/ListGroup';
import { Post } from '../../src/types';

// Mock the child component to isolate ListGroup
vi.mock('../../src/components/PostItem', () => ({
  default: ({ post, onDelete, onEdit }: any) => (
    <div data-testid="post-item">
      <span>{post.title}</span>
      <button onClick={onEdit}>Edit</button>
      <button onClick={onDelete}>Delete</button>
    </div>
  ),
}));

describe('ListGroup', () => {
  const mockPosts: Post[] = [
    { id: 1, title: 'Post 1', content: 'Content 1', author: "Test Author"},
    { id: 2, title: 'Post 2', content: 'Content 2', author: "Test Author"},
  ];
  const mockOnDelete = vi.fn();
  const mockOnEdit = vi.fn();

  afterEach(() => {
        cleanup(); // This clears the DOM after every test
    });

  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('renders the heading correctly', () => {
    render(
      <ListGroup 
        items={[]} 
        heading="Recent News" 
        onDeletePost={mockOnDelete} 
        onEditPost={mockOnEdit} 
      />
    );
    expect(screen.getByText('Recent News')).toBeInTheDocument();
  });

  it('shows the empty state message when there are no items', () => {
    render(
      <ListGroup 
        items={[]} 
        heading="Posts" 
        onDeletePost={mockOnDelete} 
        onEditPost={mockOnEdit} 
      />
    );
    expect(screen.getByText(/no posts found/i)).toBeInTheDocument();
  });

  it('renders the correct number of PostItem components', () => {
    render(
      <ListGroup 
        items={mockPosts} 
        heading="Posts" 
        onDeletePost={mockOnDelete} 
        onEditPost={mockOnEdit} 
      />
    );
    const items = screen.getAllByTestId('post-item');
    expect(items).toHaveLength(2);
    expect(screen.getByText('Post 1')).toBeInTheDocument();
    expect(screen.getByText('Post 2')).toBeInTheDocument();
  });

  it('calls onEditPost with the correct data when an edit button is clicked', () => {
    render(
      <ListGroup 
        items={mockPosts} 
        heading="Posts" 
        onDeletePost={mockOnDelete} 
        onEditPost={mockOnEdit} 
      />
    );
    
    // Find buttons in the first post
    const editButtons = screen.getAllByRole('button', { name: /edit/i });
    fireEvent.click(editButtons[0]);

    expect(mockOnEdit).toHaveBeenCalledWith(mockPosts[0]);
  });

  it('calls onDeletePost with the correct ID when a delete button is clicked', () => {
    render(
      <ListGroup 
        items={mockPosts} 
        heading="Posts" 
        onDeletePost={mockOnDelete} 
        onEditPost={mockOnEdit} 
      />
    );
    
    const deleteButtons = screen.getAllByRole('button', { name: /delete/i });
    fireEvent.click(deleteButtons[1]); // Click second post delete

    expect(mockOnDelete).toHaveBeenCalledWith(mockPosts[1].id);
  });
});