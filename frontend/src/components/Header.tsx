import { Link } from 'react-router-dom';

function Header () {

  // Check if token exists
  const isAuthenticated = !!localStorage.getItem('authToken');

  const handleLogout = () => {
    localStorage.removeItem('authToken');
    window.location.href = '/login'; // Redirect to login after logout
  };

    return(
        <nav className="navbar navbar-expand-lg  navbar-dark bg-primary">
  <a className="navbar-brand" href="#">POSTS</a>
  <div className="collapse navbar-collapse" id="navbarText">
    <ul className="navbar-nav me-auto">
            <li className="nav-item">
              <Link className="nav-link" to="/posts">All Posts</Link>
            </li>
          </ul>

          {/* ms-auto pushes these items to the RIGHT */}
          <ul className="navbar-nav ms-auto">
            {!isAuthenticated ? (
              <>
                <li className="nav-item">
                  <Link className="nav-link" to="/login">Login</Link>
                </li>
                <li className="nav-item">
                  <Link className="nav-link btn btn-outline-light ms-lg-2" to="/register">Sign Up</Link>
                </li>
              </>
            ) : (
              /* Show Logout ONLY if authenticated */
              <li className="nav-item">
                <button 
                  className="nav-link btn btn-link text-white border-0" 
                  onClick={handleLogout}
                >
                  Logout
                </button>
              </li>
            )}
          </ul>
  </div>
</nav>
    )
}

export default Header