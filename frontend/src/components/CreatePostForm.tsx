import React, { useState } from 'react';
import PostService from '../services/PostService';
import type { PostCreate } from '../types';

interface Props {
  onPostCreated: () => void; // Callback to refresh the list in the parent
}

const CreatePostForm = ({ onPostCreated }: Props) => {
  const [post, setPost] = useState<PostCreate>({ title: '', content: '' });
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: React.SubmitEvent) => {
    e.preventDefault();
    setSubmitting(true);
    try {
      await PostService.createPost(post);
      setPost({ title: '', content: ''}); // Clear form
      onPostCreated(); // Tell parent to refresh the list
    } catch (err:any) {
      setError(err.message);
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <>{error && (
      <div className="alert alert-danger alert-dismissible fade show" role="alert">
        <strong>Error:</strong> {error}
        <button type="button" className="btn-close" onClick={() => setError(null)}></button>
      </div>
    )}
    <form onSubmit={handleSubmit} className="card card-body mb-4 shadow-sm">
      <div className="mb-3">
        <label className="form-label" htmlFor="title" >Title</label>
        <input
          id="title"
          className="form-control" 
          value={post.title}
          onChange={e => setPost({...post, title: e.target.value})}
          required 
        />
      </div>
      <div className="mb-3">
        <label className="form-label" htmlFor="content">Content</label>
        <textarea 
          id="content"
          className="form-control" 
          rows={3}
          value={post.content}
          onChange={e => setPost({...post, content: e.target.value})}
          required 
        />
      </div>
      <div className="d-flex gap-2">
        <button type="submit" className="btn btn-success flex-grow-1" disabled={submitting}>
          {submitting ? 'Publishing...' : 'Publish Post'}
        </button>
      </div>
    </form>
    </>
  );
};

export default CreatePostForm;