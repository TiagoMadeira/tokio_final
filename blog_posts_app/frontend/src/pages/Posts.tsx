import { useEffect, useState } from 'react';
import PostService from '../services/PostService'; // Adjust path as needed
import ListGroup from '../components/ListGroup';
import CreatePostForm from '../components/CreatePostForm';
import EditPostModal from '../components/EditPostModal';
import type { Post } from '../types';

const PostsPage = () => {
  const [posts, setPosts] = useState<Post[]>([]);
  const [editingPost, setEditingPost] = useState<Post | null>(null);
  const [error, setError] = useState<string | null>(null);


  const loadPosts = async () => {
    try {
    const data = await PostService.getAllPosts();
    setPosts(data);
    }catch (err: any) {
      setError(err.message); // This is the message from your interceptor
    }
  };

  const handleDelete = async (id: number) => {
    try {
      await PostService.deletePost(id);
      loadPosts()
    }catch (err: any) {
      setError(err.message); // This is the message from your interceptor
    }
  };
    
  const handleUpdate = async (updatedPost: Post) => {
    if (!updatedPost.id) return;

    try {
      await PostService.updatePost(updatedPost.id, updatedPost);

      loadPosts()
    
      setEditingPost(null); // Close the edit mode
    } catch (err:any) {
      setError(err.message);
    }
  };

  useEffect(() => { loadPosts(); }, []);


  return (
    <div className="container mt-4">
      {/* Error Alert */}
      {error && (
      <div className="alert alert-danger alert-dismissible fade show" role="alert">
        <strong>Error:</strong> {error}
        <button type="button" className="btn-close" onClick={() => setError(null)}></button>
      </div>
    )}
      <ListGroup 
        items={posts} 
        heading="Latest Blog Posts" 
        onDeletePost={handleDelete} 
        onEditPost={(post) => setEditingPost(post)}
      />
      <CreatePostForm
        onPostCreated={() => {loadPosts()}}
      />
          {editingPost && (
      <EditPostModal 
        post = {editingPost}  
        onUpdate={handleUpdate} 
        onCancel={() => setEditingPost(null)} 
      />
    )}
    </div>
  );
};

export default PostsPage;