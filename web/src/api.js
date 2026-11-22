export const UNITS = ['kg', 'g', 'litres', 'ml', 'items', 'packs', 'boxes', 'trays']

export class ApiError extends Error {
  constructor(message, status, fields = {}) {
    super(message)
    this.status = status
    this.fields = fields
  }
}

async function request(path, options = {}) {
  let response
  try {
    response = await fetch(`/api${path}`, {
      headers: { 'Content-Type': 'application/json' },
      ...options,
    })
  } catch {
    throw new ApiError('The server could not be reached. Check your connection and try again.', 0)
  }
  if (response.status === 204) return null
  const body = await response.json().catch(() => ({}))
  if (!response.ok) {
    throw new ApiError(body.message || `Request failed (${response.status})`, response.status, body.fields)
  }
  return body
}

export const listBatches = ({ q, hideExpired }) =>
  request(`/batches?${new URLSearchParams({ q, hideExpired })}`)
export const getBatch = (id) => request(`/batches/${encodeURIComponent(id)}`)
export const createBatch = (batch) => request('/batches', { method: 'POST', body: JSON.stringify(batch) })
export const updateBatch = (id, batch) =>
  request(`/batches/${encodeURIComponent(id)}`, { method: 'PUT', body: JSON.stringify(batch) })
export const deleteBatch = (id) => request(`/batches/${encodeURIComponent(id)}`, { method: 'DELETE' })
