import { useNavigate } from 'react-router-dom'
import { useAuth } from '../contexts/AuthContext'

function MainLayout({ children }) {
  const { isAuthenticated, logout } = useAuth()
  const navigate = useNavigate()

  function handleLogout() {
    logout()
    navigate('/login')
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <header className="bg-black text-yellow-400 px-6 py-4 shadow-md">
        <div className="max-w-2xl mx-auto flex items-center justify-between">
          <span className="text-2xl font-bold tracking-tight">Trego</span>
          {isAuthenticated && (
            <button
              onClick={handleLogout}
              className="text-xs text-yellow-400/70 hover:text-yellow-400 transition-colors"
            >
              Sign out
            </button>
          )}
        </div>
      </header>
      <main className="max-w-2xl mx-auto px-6 py-8">
        {children}
      </main>
    </div>
  )
}

export default MainLayout
