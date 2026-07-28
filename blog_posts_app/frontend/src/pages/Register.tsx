import React, { useState, type ChangeEvent, type SubmitEvent } from 'react';
import axios from 'axios';
import {useNavigate} from "react-router"

// Define the registration state
interface RegisterState {
  username: string;
  full_name: string
  email: string;
  password: string;
  confirmPassword: string;
}

const RegisterPage: React.FC = () => {
  const [formData, setFormData] = useState<RegisterState>({
    username: '',
    full_name: '',
    email: '',
    password: '',
    confirmPassword: ''
  });
  
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  const navigate = useNavigate();

  const handleChange = (e: ChangeEvent<HTMLInputElement>) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  const handleSubmit = async (e: SubmitEvent<HTMLFormElement>) => {
    e.preventDefault();
    setErrorMsg(null);

    try {
      // POST request to your registration endpoint
      const response = await axios.post("/api/register", {
        username: formData.username,
        full_name: formData.full_name,
        email: formData.email,
        password: formData.password,
        confirm_password: formData.confirmPassword,
      });
      if (response.status === 201 || response.status === 200) {
      
      // 2. Show a success message to the user
      alert("Registration successful! Redirecting to login...");

      // 3. Redirect to the login page after a short delay
      setTimeout(() => {
        navigate('/login');
      }, 2000);
    }
    } catch (err) {
        if (axios.isAxiosError(err)) {
     // 1. Tell TypeScript that data contains a 'detail' string
        const serverResponse = err.response?.data as { detail?: string };
    
        // 2. Access the detail field
        const errorMessage = serverResponse?.detail || "An unexpected error occurred";

        setErrorMsg(errorMessage)
        }
    }
  };

  return (
        <div className = "card">
            <h5 className="card-header">Create Account</h5>
            <div className="card-body">
                {/* 1. Conditionally show the error message */}
                {errorMsg && (
                <div className="alert alert-danger py-2 small" role="alert">
                {errorMsg}
                </div>
                )}
            <form onSubmit={handleSubmit}>
                <div className="form-group">
                    <label htmlFor="username" >Username</label>
                    <input className="form-control" type="text" id= "username" name="username" value={formData.username} onChange={handleChange} required />
                </div>
                <div className="form-group">
                    <label htmlFor="full_name" >Full Name</label>
                    <input className="form-control" type="text" id= "full_name" name="full_name" value={formData.full_name} onChange={handleChange} required />
                </div>
                <div className="form-group"> 
                    <label htmlFor="email" >Email</label>
                    <input className="form-control" type="email" id= "email" name="email" value={formData.email} onChange={handleChange} required />
                </div>
                <div className="form-group">
                    <label htmlFor="password" >Password</label>
                    <input className="form-control" type="password" id= "password" name="password" value={formData.password} onChange={handleChange} required />
                </div>
                <div className="form-group">
                    <label htmlFor="confirmPassword">Confirm Password</label>
                    <input className="form-control" type="password" id= "confirmPassword" name="confirmPassword" value={formData.confirmPassword} onChange={handleChange} required />
                </div>
                <button type="submit" className="btn btn-primary">Register</button>
            </form>
            </div>
        </div>
 
  );
};

export default RegisterPage;