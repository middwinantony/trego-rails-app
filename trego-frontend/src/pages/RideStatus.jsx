import { useEffect, useState, useCallback } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import MainLayout from '../layouts/MainLayout'
import Button from '../components/Button'
import { getRideById, cancelRide } from '../services/api'

const POLL_INTERVAL_MS = 5000
const TERMINAL_STATUSES = new Set(['completed', 'cancelled'])

/*
 * Rider-facing lifecycle:
 *   requested  → Finding a driver
 *   assigned   → Driver assigned
 *   accepted   → Driver on the way
 *   started    → En route
 *   completed  → Completed
 *   cancelled  → Cancelled
 */
const STATUS_CONFIG = {
  requested: { label: 'Finding a driver…', step: 1, color: 'blue' },
  assigned:  { label: 'Driver assigned',   step: 2, color: 'purple' },
  accepted:  { label: 'Driver on the way', step: 3, color: 'indigo' },
  started:   { label: 'En route',          step: 4, color: 'yellow' },
  completed: { label: 'Completed',         step: 5, color: 'green' },
  cancelled: { label: 'Cancelled',         step: 0, color: 'red' },
}

const STEP_BADGE = {
  blue:   'bg-blue-100 text-blue-700 border-blue-200',
  purple: 'bg-purple-100 text-purple-700 border-purple-200',
  indigo: 'bg-indigo-100 text-indigo-700 border-indigo-200',
  yellow: 'bg-yellow-100 text-yellow-800 border-yellow-200',
  green:  'bg-green-100 text-green-700 border-green-200',
  red:    'bg-red-100 text-red-600 border-red-200',
}

const STEP_DOT = {
  blue:   'bg-blue-500',
  purple: 'bg-purple-500',
  indigo: 'bg-indigo-500',
  yellow: 'bg-yellow-400',
  green:  'bg-green-500',
  red:    'bg-red-500',
}

const ORDERED_STEPS = ['requested', 'assigned', 'accepted', 'started', 'completed']

function StatusStepper({ currentStatus }) {
  const currentStep = STATUS_CONFIG[currentStatus]?.step ?? 0
  const isCancelled = currentStatus === 'cancelled'

  if (isCancelled) return null

  return (
    <div className="flex items-center gap-1 mb-6">
      {ORDERED_STEPS.map((s, i) => {
        const step = STATUS_CONFIG[s].step
        const isActive = step === currentStep
        const isDone = step < currentStep

        return (
          <div key={s} className="flex items-center flex-1">
            <div
              className={`h-2 rounded-full transition-all duration-500 ${
                isDone ? 'bg-yellow-400' : isActive ? 'bg-yellow-400 animate-pulse' : 'bg-gray-200'
              } ${i === 0 ? 'w-full' : 'w-full'}`}
            />
          </div>
        )
      })}
    </div>
  )
}

function RideStatus() {
  const { id } = useParams()
  const navigate = useNavigate()

  // Load stored pickup/dropoff (only available from create response)
  const stored = (() => {
    try {
      const raw = localStorage.getItem('trego_active_ride')
      return raw ? JSON.parse(raw) : null
    } catch {
      return null
    }
  })()

  const [ride, setRide] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [cancelling, setCancelling] = useState(false)

  const fetchRide = useCallback(async () => {
    try {
      const { data } = await getRideById(id)
      setRide(data)
      setError('')

      // Clear active ride from localStorage when terminal
      if (TERMINAL_STATUSES.has(data.status)) {
        localStorage.removeItem('trego_active_ride')
      }
    } catch (err) {
      const msg =
        err.response?.data?.error ||
        err.response?.data?.errors ||
        'Unable to load ride status.'
      setError(typeof msg === 'string' ? msg : msg[0])
    } finally {
      setLoading(false)
    }
  }, [id])

  useEffect(() => {
    fetchRide()

    const interval = setInterval(() => {
      if (ride && TERMINAL_STATUSES.has(ride.status)) return
      fetchRide()
    }, POLL_INTERVAL_MS)

    return () => clearInterval(interval)
  }, [fetchRide, ride?.status])

  async function handleCancel() {
    setCancelling(true)
    try {
      await cancelRide(id)
      await fetchRide()
    } catch (err) {
      const msg = err.response?.data?.error || 'Could not cancel ride.'
      setError(msg)
    } finally {
      setCancelling(false)
    }
  }

  const config = ride ? STATUS_CONFIG[ride.status] : null
  const canCancel = ride && ['requested', 'assigned', 'accepted'].includes(ride.status)

  // ── Loading skeleton ────────────────────────────────────────────────────────
  if (loading) {
    return (
      <MainLayout>
        <div className="animate-pulse space-y-4">
          <div className="h-6 bg-gray-200 rounded w-1/3" />
          <div className="h-4 bg-gray-200 rounded w-1/2" />
          <div className="h-32 bg-gray-200 rounded-xl" />
        </div>
      </MainLayout>
    )
  }

  // ── Error state ─────────────────────────────────────────────────────────────
  if (error && !ride) {
    return (
      <MainLayout>
        <div className="text-center py-20">
          <p className="text-3xl mb-3">⚠️</p>
          <p className="font-medium text-gray-700 mb-1">Something went wrong</p>
          <p className="text-sm text-gray-400 mb-6">{error}</p>
          <Button onClick={() => navigate('/')}>Back to Home</Button>
        </div>
      </MainLayout>
    )
  }

  return (
    <MainLayout>
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-gray-900">Your Ride</h1>
        <p className="text-sm text-gray-400 mt-0.5">Ride #{id}</p>
      </div>

      {/* Error banner (poll errors while ride is visible) */}
      {error && (
        <div className="mb-4 rounded-lg bg-red-50 border border-red-200 px-4 py-3 text-sm text-red-700">
          {error}
        </div>
      )}

      {/* Progress stepper */}
      {ride && <StatusStepper currentStatus={ride.status} />}

      {/* Status card */}
      {ride && config && (
        <div className="bg-white rounded-xl border border-gray-200 p-5 shadow-sm mb-4">
          {/* Status badge */}
          <div className="flex items-center gap-3 mb-5">
            <span className={`h-3 w-3 rounded-full flex-shrink-0 ${STEP_DOT[config.color]}`} />
            <span className={`text-sm font-semibold px-3 py-1 rounded-full border ${STEP_BADGE[config.color]}`}>
              {config.label}
            </span>
            {!TERMINAL_STATUSES.has(ride.status) && (
              <span className="ml-auto text-xs text-gray-400">Updates every 5s</span>
            )}
          </div>

          {/* Route */}
          {stored && (
            <div className="space-y-2 text-sm mb-5 border-t border-gray-100 pt-4">
              <div className="flex items-start gap-2">
                <span className="mt-1 h-2 w-2 rounded-full bg-green-500 flex-shrink-0" />
                <div>
                  <p className="text-xs text-gray-400 mb-0.5">Pickup</p>
                  <p className="text-gray-800 font-medium">{stored.pickup_location}</p>
                </div>
              </div>
              <div className="flex items-start gap-2">
                <span className="mt-1 h-2 w-2 rounded-full bg-red-500 flex-shrink-0" />
                <div>
                  <p className="text-xs text-gray-400 mb-0.5">Drop-off</p>
                  <p className="text-gray-800 font-medium">{stored.dropoff_location}</p>
                </div>
              </div>
            </div>
          )}

          {/* Driver info (shown once assigned) */}
          {ride.driver && (
            <div className="border-t border-gray-100 pt-4 text-sm">
              <p className="text-xs text-gray-400 mb-0.5">Your driver</p>
              <p className="font-medium text-gray-800">{ride.driver.first_name}</p>
            </div>
          )}

          {/* Completion message */}
          {ride.status === 'completed' && (
            <div className="mt-4 rounded-lg bg-green-50 border border-green-200 px-4 py-3 text-sm text-green-700 font-medium">
              You've arrived! Thanks for riding with Trego.
            </div>
          )}

          {/* Cancellation message */}
          {ride.status === 'cancelled' && (
            <div className="mt-4 rounded-lg bg-red-50 border border-red-200 px-4 py-3 text-sm text-red-600 font-medium">
              This ride was cancelled.
            </div>
          )}
        </div>
      )}

      {/* Actions */}
      <div className="flex flex-col gap-3">
        {canCancel && (
          <Button
            variant="danger"
            onClick={handleCancel}
            disabled={cancelling}
            className="w-full"
          >
            {cancelling ? 'Cancelling…' : 'Cancel Ride'}
          </Button>
        )}
        {TERMINAL_STATUSES.has(ride?.status) && (
          <Button onClick={() => navigate('/')} className="w-full">
            Back to Home
          </Button>
        )}
      </div>
    </MainLayout>
  )
}

export default RideStatus
