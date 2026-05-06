import axios from 'axios';

const api = axios.create({
  baseURL: '/api/', // Base path for the Nginx proxy
});

// Request Interceptor
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('authToken'); 
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
  }, (error) => {
  return Promise.reject(error);
  });

// Response (Error) Interceptor
// Add a response interceptor
api.interceptors.response.use(
  (response) => response, // Just return the response if successful
  (error) => {
    let message = "An unexpected error occurred";

    if (error.response) {
      // The server responded with a status code outside the 2xx range
      switch (error.response.status) {

        case 401:
          message = "Session expired. Please login again.";
          localStorage.removeItem('authToken'); window.location.href = '/login';
          break;

        case 500:
          message = "Internal server error. Please try again later.";
          break;
          
        default:
          message = error.response.data?.detail || message;
      }
    } else if (error.request) {
      // The request was made but no response was received (Network error)
      message = "Network error. Please check if the backend is running.";
    }
    
    // Create a custom error object to throw
    return Promise.reject(new Error(message));
  }
);


export default api;