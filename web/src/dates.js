const dayFormat = new Intl.DateTimeFormat('en-IE', { weekday: 'short', day: 'numeric', month: 'short', year: 'numeric' })

// Dates arrive as yyyy-mm-dd; building the Date from parts avoids a UTC shift.
export function formatDay(isoDate) {
  const [y, m, d] = isoDate.split('-').map(Number)
  return dayFormat.format(new Date(y, m - 1, d))
}

export function expiryLabel(days) {
  if (days < 0) return 'Expired'
  if (days === 0) return 'Today'
  if (days === 1) return 'due tomorrow'
  return `In ${days} days`
}

export function expiryTone(days) {
  if (days < 0) return 'expired'
  if (days <= 2) return 'soon'
  return 'later'
}
