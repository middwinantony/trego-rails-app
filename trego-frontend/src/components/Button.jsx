function Button({ children, onClick, variant = 'primary', disabled = false, type = 'button', className = '' }) {
  const base = 'inline-flex items-center justify-center px-5 py-2.5 rounded-lg font-semibold text-sm transition-colors duration-150 focus:outline-none focus:ring-2 focus:ring-offset-2'

  const variants = {
    primary: 'bg-yellow-400 text-black hover:bg-yellow-300 focus:ring-yellow-400 disabled:bg-yellow-200 disabled:text-yellow-700 disabled:cursor-not-allowed',
    secondary: 'bg-white text-black border border-gray-300 hover:bg-gray-50 focus:ring-gray-400 disabled:bg-gray-100 disabled:text-gray-400 disabled:cursor-not-allowed',
    danger: 'bg-red-600 text-white hover:bg-red-500 focus:ring-red-500 disabled:bg-red-300 disabled:cursor-not-allowed',
  }

  return (
    <button
      type={type}
      onClick={onClick}
      disabled={disabled}
      className={`${base} ${variants[variant]} ${className}`}
    >
      {children}
    </button>
  )
}

export default Button
