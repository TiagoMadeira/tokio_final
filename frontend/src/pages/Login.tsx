import { useState, type ChangeEvent, type SubmitEvent } from 'react';
import axios, { type AxiosResponse } from 'axios';


interface LoginResponse {
  access_token: string;
  token_type: string;
}


function Login () {
    const [credentials, setCredentials] = useState({
    username: '',
    password: ''
  });

    const [errorMsg, setErrorMsg] = useState<string | null>(null);

    const handleChange = (e: ChangeEvent<HTMLInputElement>) => {
        const { name, value } = e.target;
        setCredentials((prev) => ({
        ...prev,
        [name]: value
        }));
    };

    const handleSubmit = async (e: SubmitEvent<HTMLFormElement>) => {
        e.preventDefault();
        setErrorMsg(null);

         const data = new FormData();
            data.append('username', credentials.username);
            data.append('password', credentials.password);

        try {
            const response: AxiosResponse<LoginResponse> = await axios.postForm(
            "/api/login",
            data,
            );

            let access_token  = response.data.access_token;
            localStorage.setItem('authToken', access_token);
            console.log('Login successful!');
            window.location.href = '/posts'
      
            } catch (err) {
                console.log({err})
                if (axios.isAxiosError(err)) {
                const serverResponse = err.response?.data as { detail?: string };
    
                const errorMessage = serverResponse?.detail || "Login failed";
                setErrorMsg(errorMessage);
            }
        }
    }

    return (

        <div className = "card">
            <h5 className="card-header">Login</h5>
            <div className="card-body">
                {/* 1. Conditionally show the error message */}
                {errorMsg && (
                <div className="alert alert-danger py-2 small" role="alert">
                {errorMsg}
                </div>
                )}
        <form onSubmit={handleSubmit} method="POST">
            <div className="form-group">
                <label htmlFor="username">Username</label>
                <input type="text" 
                    className="form-control" 
                    name="username" 
                    aria-describedby="emailHelp"
                    onChange={handleChange}
                    required/>
            </div>
            <div className="form-group">
                <label htmlFor="password">Password</label>
                <input type="password"
                    className="form-control" 
                    name="password"
                    onChange={handleChange}
                    required/>
            </div>
            <button type="submit" className="btn btn-primary">Submit</button>
        </form>
        </div>
        </div>
    )
}

export default Login