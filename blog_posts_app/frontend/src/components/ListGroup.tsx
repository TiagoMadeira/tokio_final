import PostItem from "./PostItem";
import type { Post } from '../types';

interface Props {
    items: Post[],
    heading: string,
    onDeletePost: (id: number) => void;
    onEditPost: (post: Post) => void;
}

function ListGroup ({items, heading, onDeletePost, onEditPost}: Props) {
    return (
        <div className="py-4">
            <div className="d-flex align-items-center justify-content-between mb-4">
                <h2 className="fw-bold text-dark">{heading}</h2>
            </div>

            {items.length === 0 ? (
                <div className="text-center py-5 border rounded bg-light">
                    <p className="text-muted mb-0">No posts found. Be the first to share something!</p>
                </div>
            ) : (
                /* Use a responsive grid: 1 col on mobile, 2 on medium, 3 on large screens */
                <div className="row g-4">
                    {items.map((item) => {
                        
                        const targetId = Number(item.id);
                        return(
                        
                        <div className="col-12 col-md-6 col-lg-4" key={targetId}>
                            <PostItem 
                                post={item} 
                                onDelete={() => onDeletePost(targetId!)} 
                                onEdit={() => onEditPost(item)} 
                            />
                        </div>
                    )})}
                </div>
            )}
        </div>
    );
}

export default ListGroup;