
import { describe, it, expect, vi, beforeEach } from 'vitest';
import PostService from '../../src/services/PostService';
import api from '../../src/api/client';
import type { Post, PostCreate } from '../../src/types';

// Mock the custom axios client
vi.mock('../../src/api/client', () => ({
  default: {
    get: vi.fn(),
    post: vi.fn(),
    patch: vi.fn(),
    delete: vi.fn(),
  },
}));

describe('PostService', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('getAllPosts returns an array of posts', async () => {
    const mockData: Post[] = [{ id: 1, title: 'Title', content: 'Content', author: 'Author' }];
    vi.mocked(api.get).mockResolvedValueOnce({ data: mockData });

    const posts = await PostService.getAllPosts();

    expect(api.get).toHaveBeenCalledWith('posts');
    expect(posts).toEqual(mockData);
  });

  it('getPostById returns a single post', async () => {
    const mockPost: Post = { id: 1, title: 'Title', content: 'Content', author: 'Author' };
    vi.mocked(api.get).mockResolvedValueOnce({ data: mockPost });

    const post = await PostService.getPostById(1);

    expect(api.get).toHaveBeenCalledWith('posts/1');
    expect(post).toEqual(mockPost);
  });

  it('createPost sends post data and returns the new post', async () => {
    const postData: PostCreate = { title: 'New', content: 'New Content' };
    const mockResponse: Post = { id: 99, ...postData, author: 'Author' };
    vi.mocked(api.post).mockResolvedValueOnce({ data: mockResponse });

    const result = await PostService.createPost(postData);

    expect(api.post).toHaveBeenCalledWith('posts', postData);
    expect(result).toEqual(mockResponse);
  });

  it('updatePost sends patch request with correct data', async () => {
    const updatedData: Post = { id: 1, title: 'Updated', content: 'Updated', author: 'Author' };
    vi.mocked(api.patch).mockResolvedValueOnce({ data: updatedData });

    const result = await PostService.updatePost(1, updatedData);

    expect(api.patch).toHaveBeenCalledWith('posts/1', updatedData);
    expect(result).toEqual(updatedData);
  });

  it('deletePost sends delete request', async () => {
    vi.mocked(api.delete).mockResolvedValueOnce({ status: 204 });

    await PostService.deletePost(1);

    expect(api.delete).toHaveBeenCalledWith('posts/1');
  });

  it('getAllPosts propagates errors (from interceptors)', async () => {
    const errorMessage = 'Unauthorized';
    vi.mocked(api.get).mockRejectedValueOnce(new Error(errorMessage));

    await expect(PostService.getAllPosts()).rejects.toThrow(errorMessage);
  });
});