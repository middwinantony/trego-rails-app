import axiosInstance from '../api/axios'

/*
 * Ride object shape (from backend):
 * {
 *   id:                number,
 *   status:            'requested' | 'assigned' | 'accepted' | 'started' | 'completed' | 'cancelled',
 *   pickup_location:   string,   ← present on create response only
 *   dropoff_location:  string,   ← present on create response only
 *   rider_id:          number,   ← present on create response only
 *   driver_id:         number | null,
 *   created_at:        string (ISO 8601),
 *   driver:            { id, first_name } | null   ← present on show response (rider view)
 * }
 *
 * Create ride request body:
 * { ride: { pickup_location, dropoff_location } }
 *
 * Auth endpoints response:
 * { token: string, user: { id, email, role, status, created_at, updated_at } }
 */

// ─── Auth ────────────────────────────────────────────────────────────────────

export function login(email, password) {
  return axiosInstance.post('/api/v1/auth/login', { email, password })
}

export function signup(email, password, password_confirmation) {
  return axiosInstance.post('/api/v1/auth/signup', { email, password, password_confirmation })
}

export function logoutRequest() {
  return axiosInstance.post('/api/v1/auth/logout')
}

// ─── Rides ───────────────────────────────────────────────────────────────────

export function getRideById(id) {
  return axiosInstance.get(`/api/v1/rides/${id}`)
}

export function createRide(data) {
  // data: { pickup_location, dropoff_location }
  return axiosInstance.post('/api/v1/rides', { ride: data })
}

export function cancelRide(id) {
  return axiosInstance.patch(`/api/v1/rides/${id}/cancel`)
}
