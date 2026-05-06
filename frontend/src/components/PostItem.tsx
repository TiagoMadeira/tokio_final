
import type { Post } from '../types';

interface PostItemProps {
    post: Post,
    onDelete?: () => void;
    onEdit?: () => void;
}

function PostItem ({post, onDelete, onEdit}: PostItemProps) {

    return (
        <div className = "card h-100 shadow-sm">
        <div className="card-header d-flex justify-content-between align-items-center">
            <h5>{post.title}</h5>
            <p>Author: {post.author}</p>
        </div>
        <div className="card-body">{post.content}</div>
        <div className="card-footer d-flex justify-content-end gap-2">
        <button 
          className="btn btn-outline-primary btn-sm" 
          onClick={onEdit}
        >
          Edit
        </button>
        <button 
          className="btn btn-outline-danger btn-sm" 
          onClick={onDelete}
        >
          Delete
        </button>
        </div>
        </div>
        )
}

export default PostItem