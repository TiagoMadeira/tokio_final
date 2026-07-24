import api from '../api/client'
import type { Post } from '../types';
import type { PostCreate } from '../types';


class PostService {
  async getAllPosts(): Promise<Post[]> {
    try {
      const response = await api.get<Post[]>('posts');
      return response.data;
      } catch (error) {
      // The error thrown here is the one from the interceptor
      throw error; 
    }
  }

  async getPostById(id: number): Promise<Post> {
    const response = await api.get<Post>(`posts/${id}`);
    return response.data;
  }

  async createPost(post: PostCreate): Promise<Post> {
    const response = await api.post<Post>('posts', post);
    return response.data;
  }

  async updatePost(id: number, post: Post): Promise<Post> {
    const response = await api.patch<Post>(`posts/${id}`, post);
    return response.data;
  }

  async deletePost(id: number): Promise<void> {
    await api.delete(`posts/${id}`);
  }
}

export default new PostService();