import React, { useState } from 'react';
import PostService from '../services/PostService';
import type { Post } from '../types';

interface Props {
  post: Post;
  onUpdate: (updatedPost: Post) => void;
  onCancel: () => void;
}

const EditPostModal = ({ post, onUpdate, onCancel }: Props) => {
  const [formData, setFormData] = useState<Post>({ ...post });
  const [loading, setLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: React.SubmitEvent) => {
    e.preventDefault();
    if (!post.id) return;

    setLoading(true);
    setError(null); // Clear previous errors
    try {
      const updated = await PostService.updatePost(post.id, formData);
      onUpdate(updated);
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <>
      {/* Dark Backdrop */}
      <button  
        className="modal-backdrop show" 
        style={{ backgroundColor: 'rgba(0,0,0,0.5)' }} 
        onClick={onCancel}
        aria-label="Cancel" 
      ></button >

      {/* Modal Dialog */}
      <dialog className="modal show d-block" tabIndex={-1} role="dialog">
        <div className="modal-dialog modal-dialog-centered">
          <div className="modal-content shadow-lg">
            <div className="modal-header">
              <h5 className="modal-title">Edit Post</h5>
              <button type="button" className="btn-close" onClick={onCancel}></button>
            </div>
            <form onSubmit={handleSubmit}>
              <div className="modal-body">
                 {/* Inline Error Alert */}
                {error && (
                  <div className="alert alert-danger py-2 small" role="alert">
                    <strong>Error:</strong> {error}
                  </div>
                )}
                <div className="mb-3">
                  <label className="form-label" htmlFor="title">Title</label>
                  <input 
                    id = "title"
                    className="form-control" 
                    value={formData.title}
                    onChange={e => setFormData({...formData, title: e.target.value})}
                    required 
                  />
                </div>
                <div className="mb-3">
                  <label className="form-label" htmlFor="content">Content</label>
                  <textarea 
                     id = "content"
                    className="form-control" 
                    rows={4}
                    value={formData.content}
                    onChange={e => setFormData({...formData, content: e.target.value})}
                    required 
                  />
                </div>
              </div>
              <div className="modal-footer">
                <button type="button" className="btn btn-secondary" onClick={onCancel}>
                  Cancel
                </button>
                <button type="submit" className="btn btn-primary" disabled={loading}>
                  {loading ? 'Saving...' : 'Save Changes'}
                </button>
              </div>
            </form>
          </div>
        </div>
      </dialog>
    </>
  );
};

export default EditPostModal;