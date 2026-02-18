import { useNavigate } from 'react-router-dom'
import MainLayout from '../layouts/MainLayout'
import Button from '../components/Button'

const STATUS_STYLES = {
  requested: 'bg-blue-100 text-blue-700',
  assigned:  'bg-purple-100 text-purple-700',
  accepted:  'bg-indigo-100 text-indigo-700',
  started:   'bg-yellow-100 text-yellow-800',
  completed: 'bg-green-100 text-green-700',
  cancelled: 'bg-red-100 text-red-600',
}

const STATUS_LABELS = {
  requested: 'Finding a driver…',
  assigned:  'Driver assigned',
  accepted:  'Driver on the way',
  started:   'En route',
  completed: 'Completed',
  cancelled: 'Cancelled',
}

function RiderHome() {
  const navigate = useNavigate()

  // Read the active ride stored after booking
  const activeRide = (() => {
    try {
      const raw = localStorage.getItem('trego_active_ride')
      return raw ? JSON.parse(raw) : null
    } catch {
      return null
    }
  })()

  return (
    <MainLayout>
      {/* Page header */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900">Welcome back</h1>
        <p className="mt-1 text-gray-500">Where are you headed today?</p>
      </div>

      {/* Active ride card — shown when there's a ride in progress */}
      {activeRide ? (
        <div className="mb-10 bg-white rounded-xl border border-gray-200 p-5 shadow-sm">
          <div className="flex items-center justify-between mb-4">
            <p className="font-semibold text-gray-900 text-sm">Active ride</p>
            <span className={`text-xs font-semibold px-2.5 py-1 rounded-full capitalize ${STATUS_STYLES.requested}`}>
              {STATUS_LABELS.requested}
            </span>
          </div>
          <div className="space-y-2 text-sm mb-4">
            <div className="flex items-start gap-2">
              <span className="mt-1 h-2 w-2 rounded-full bg-green-500 flex-shrink-0" />
              <span className="text-gray-700">{activeRide.pickup_location}</span>
            </div>
            <div className="flex items-start gap-2">
              <span className="mt-1 h-2 w-2 rounded-full bg-red-500 flex-shrink-0" />
              <span className="text-gray-700">{activeRide.dropoff_location}</span>
            </div>
          </div>
          <Button onClick={() => navigate(`/rides/${activeRide.id}`)} className="w-full">
            Track Ride
          </Button>
        </div>
      ) : (
        /* Book CTA — shown when no active ride */
        <Button onClick={() => navigate('/book')} className="w-full mb-10 py-3 text-base">
          Book a Ride
        </Button>
      )}

      {/* Empty ride history */}
      {!activeRide && (
        <section>
          <h2 className="text-lg font-semibold text-gray-800 mb-4">Your Rides</h2>
          <div className="text-center py-16 bg-white rounded-xl border border-dashed border-gray-200">
            <p className="text-4xl mb-3">🚗</p>
            <p className="font-medium text-gray-600">No rides yet</p>
            <p className="text-sm text-gray-400 mt-1">Book your first ride and it will show up here.</p>
          </div>
        </section>
      )}
    </MainLayout>
  )
}

export default RiderHome
