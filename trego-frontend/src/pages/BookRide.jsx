import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import MainLayout from '../layouts/MainLayout'
import Button from '../components/Button'
import { createRide } from '../services/api'

function BookRide() {
  const navigate = useNavigate()

  const [form, setForm] = useState({
    pickup_location: '',
    dropoff_location: '',
  })
  const [fieldErrors, setFieldErrors] = useState({})
  const [loading, setLoading] = useState(false)
  const [apiError, setApiError] = useState('')

  function handleChange(e) {
    const { name, value } = e.target
    setForm((prev) => ({ ...prev, [name]: value }))
    if (fieldErrors[name]) {
      setFieldErrors((prev) => ({ ...prev, [name]: '' }))
    }
    if (apiError) setApiError('')
  }

  function validate() {
    const next = {}
    if (!form.pickup_location.trim()) next.pickup_location = 'Pickup location is required.'
    if (!form.dropoff_location.trim()) next.dropoff_location = 'Drop-off location is required.'
    return next
  }

  async function handleSubmit(e) {
    e.preventDefault()

    const errs = validate()
    if (Object.keys(errs).length > 0) {
      setFieldErrors(errs)
      return
    }

    const payload = {
      pickup_location: form.pickup_location.trim(),
      dropoff_location: form.dropoff_location.trim(),
    }

    console.log('Book ride payload:', payload)
    setLoading(true)
    setApiError('')

    try {
      const { data: ride } = await createRide(payload)

      // Persist ride data locally — the show endpoint only returns { id, status, driver }
      // so we store pickup/dropoff from the create response to display on the status page.
      localStorage.setItem('trego_active_ride', JSON.stringify({
        id: ride.id,
        pickup_location: payload.pickup_location,
        dropoff_location: payload.dropoff_location,
      }))

      navigate(`/rides/${ride.id}`)
    } catch (err) {
      const msg =
        err.response?.data?.errors ||
        err.response?.data?.error ||
        'Something went wrong. Please try again.'
      setApiError(typeof msg === 'string' ? msg : msg[0])
    } finally {
      setLoading(false)
    }
  }

  const isDisabled = loading || !form.pickup_location.trim() || !form.dropoff_location.trim()

  return (
    <MainLayout>
      {/* Back link */}
      <button
        onClick={() => navigate('/')}
        className="text-sm text-gray-500 hover:text-gray-700 mb-6 flex items-center gap-1"
      >
        ← Back
      </button>

      <h1 className="text-2xl font-bold text-gray-900 mb-1">Book a Ride</h1>
      <p className="text-gray-500 text-sm mb-8">Enter your pickup and drop-off locations.</p>

      {/* API error banner */}
      {apiError && (
        <div className="mb-6 rounded-lg bg-red-50 border border-red-200 px-4 py-3 text-sm text-red-700">
          {apiError}
        </div>
      )}

      <form onSubmit={handleSubmit} noValidate className="space-y-6">
        {/* Pickup */}
        <div>
          <label htmlFor="pickup_location" className="block text-sm font-medium text-gray-700 mb-1.5">
            Pickup location
          </label>
          <input
            id="pickup_location"
            name="pickup_location"
            type="text"
            value={form.pickup_location}
            onChange={handleChange}
            disabled={loading}
            placeholder="e.g. 123 Main St"
            className={`w-full rounded-lg border px-4 py-3 text-sm text-gray-900 placeholder-gray-400 outline-none transition-colors
              focus:ring-2 focus:ring-yellow-400 focus:border-yellow-400 disabled:bg-gray-100 disabled:cursor-not-allowed
              ${fieldErrors.pickup_location ? 'border-red-400 bg-red-50' : 'border-gray-300 bg-white'}`}
          />
          {fieldErrors.pickup_location && (
            <p className="mt-1.5 text-xs text-red-600">{fieldErrors.pickup_location}</p>
          )}
        </div>

        {/* Dropoff */}
        <div>
          <label htmlFor="dropoff_location" className="block text-sm font-medium text-gray-700 mb-1.5">
            Drop-off location
          </label>
          <input
            id="dropoff_location"
            name="dropoff_location"
            type="text"
            value={form.dropoff_location}
            onChange={handleChange}
            disabled={loading}
            placeholder="e.g. Airport Terminal 2"
            className={`w-full rounded-lg border px-4 py-3 text-sm text-gray-900 placeholder-gray-400 outline-none transition-colors
              focus:ring-2 focus:ring-yellow-400 focus:border-yellow-400 disabled:bg-gray-100 disabled:cursor-not-allowed
              ${fieldErrors.dropoff_location ? 'border-red-400 bg-red-50' : 'border-gray-300 bg-white'}`}
          />
          {fieldErrors.dropoff_location && (
            <p className="mt-1.5 text-xs text-red-600">{fieldErrors.dropoff_location}</p>
          )}
        </div>

        {/* Submit */}
        <Button type="submit" disabled={isDisabled} className="w-full py-3 text-base">
          {loading ? 'Booking…' : isDisabled ? 'Enter locations to continue' : 'Confirm Booking'}
        </Button>
      </form>
    </MainLayout>
  )
}

export default BookRide
