import { createContext, useContext, useState } from 'react'

const AuthContext = createContext(null)

export function AuthProvider({ children }) {
  const [token, setToken] = useState(() => localStorage.getItem('trego_token'))
  const [user, setUser] = useState(() => {
    const stored = localStorage.getItem('trego_user')
    return stored ? JSON.parse(stored) : null
  })

  function login(newToken, newUser) {
    localStorage.setItem('trego_token', newToken)
    localStorage.setItem('trego_user', JSON.stringify(newUser))
    setToken(newToken)
    setUser(newUser)
  }

  function logout() {
    localStorage.removeItem('trego_token')
    localStorage.removeItem('trego_user')
    localStorage.removeItem('trego_active_ride')
    setToken(null)
    setUser(null)
  }

  return (
    <AuthContext.Provider value={{ token, user, login, logout, isAuthenticated: !!token }}>
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  return useContext(AuthContext)
}
