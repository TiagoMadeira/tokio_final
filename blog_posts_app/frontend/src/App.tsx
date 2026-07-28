import './App.css'
import { Routes, Route } from 'react-router';
import Login from "./pages/Login"
import Register from "./pages/Register"
import Posts from "./pages/Posts"
import Header from "./components/Header"
function App() {


  return( 
    <>
      <Header />
      {/* 2. Container for your pages */}
      <div className="vh-100 d-flex justify-content-center align-items-center">
        {/* 3. Define which component shows at which URL */}
        <Routes>
          <Route path="/login" element={<Login />} />
          <Route path="/register" element={<Register />} />
          <Route path="/posts" element={<Posts />} />
          <Route path="/" element={<h1>Home Page</h1>} />
        </Routes>
      </div>
    </>
  )
}

export default App
