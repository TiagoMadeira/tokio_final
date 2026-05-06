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

  const handleSubmit = async (e: React.SubmitEvent) => {
    e.preventDefault();
    if (!post.id) return;

    setLoading(true);
    try {
      const updated = await PostService.updatePost(post.id, formData);
      onUpdate(updated);
    } catch (err) {
      alert("Error updating post.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <>
      {/* Dark Backdrop */}
      <div 
        className="modal-backdrop show" 
        style={{ backgroundColor: 'rgba(0,0,0,0.5)' }} 
        onClick={onCancel}
      ></div>

      {/* Modal Dialog */}
      <div className="modal show d-block" tabIndex={-1} role="dialog">
        <div className="modal-dialog modal-dialog-centered" role="document">
          <div className="modal-content shadow-lg">
            <div className="modal-header">
              <h5 className="modal-title">Edit Post</h5>
              <button type="button" className="btn-close" onClick={onCancel}></button>
            </div>
            <form onSubmit={handleSubmit}>
              <div className="modal-body">
                <div className="mb-3">
                  <label className="form-label">Title</label>
                  <input 
                    className="form-control" 
                    value={formData.title}
                    onChange={e => setFormData({...formData, title: e.target.value})}
                    required 
                  />
                </div>
                <div className="mb-3">
                  <label className="form-label">Content</label>
                  <textarea 
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
      </div>
    </>
  );
};

export default EditPostModal;