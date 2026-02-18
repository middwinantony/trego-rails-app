import axios from 'axios'

const axiosInstance = axios.create({
  baseURL: 'http://localhost:3000',
})

// Attach JWT token from localStorage on every request
axiosInstance.interceptors.request.use((config) => {
  const token = localStorage.getItem('trego_token')
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

// On 401, clear stored auth and redirect to login
axiosInstance.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem('trego_token')
      localStorage.removeItem('trego_user')
      localStorage.removeItem('trego_active_ride')
      window.location.href = '/login'
    }
    return Promise.reject(error)
  }
)

export default axiosInstance
