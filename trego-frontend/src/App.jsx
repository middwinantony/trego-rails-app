import { BrowserRouter, Routes, Route } from 'react-router-dom'
import { AuthProvider } from './contexts/AuthContext'
import ProtectedRoute from './components/ProtectedRoute'
import Login from './pages/Login'
import RiderHome from './pages/RiderHome'
import BookRide from './pages/BookRide'
import RideStatus from './pages/RideStatus'

function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <Routes>
          <Route path="/login" element={<Login />} />
          <Route path="/" element={<ProtectedRoute><RiderHome /></ProtectedRoute>} />
          <Route path="/book" element={<ProtectedRoute><BookRide /></ProtectedRoute>} />
          <Route path="/rides/:id" element={<ProtectedRoute><RideStatus /></ProtectedRoute>} />
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  )
}

export default App
