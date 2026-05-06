export interface Post {
  id: number;
  title: string;
  content: string;
  author: string;
}

export interface PostCreate {
  title: string;
  content: string;
}