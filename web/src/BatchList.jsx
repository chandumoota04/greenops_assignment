import { useEffect, useState } from 'react'
import { Link, useLocation, useNavigate } from 'react-router-dom'
import { deleteBatch, listBatches } from './api.js'
import { expiryLabel, expiryTone, formatDay } from './dates.js'

function formatQuantity(quantity) {
  return Number(quantity).toLocaleString('en-IE', { maximumFractionDigits: 2 })
}

export default function BatchList() {
  const location = useLocation()
  const navigate = useNavigate()
  const [query, setQuery] = useState({ q: '', hideExpired: false })
  const [state, setState] = useState({ loading: true, error: '', batches: [] })
  const [confirmId, setConfirmId] = useState(null)
  const [reloadKey, setReloadKey] = useState(0)
  const [actionError, setActionError] = useState('')
  const [flash, setFlash] = useState(location.state?.flash || '')

  // Browsers keep history state across a reload, so clear it once the message is shown.
  useEffect(() => {
    if (location.state?.flash) navigate('.', { replace: true, state: null })
  }, [location.state, navigate])

  useEffect(() => {
    let current = true
    // Small delay so typing in the search box sends one request, not one per key.
    const timer = setTimeout(() => {
      listBatches(query)
        .then((batches) => current && setState({ loading: false, error: '', batches }))
        .catch((err) => current && setState({ loading: false, error: err.message, batches: [] }))
    }, 250)
    return () => {
      current = false
      clearTimeout(timer)
    }
  }, [query, reloadKey])

  async function confirmDelete(id) {
    setActionError('')
    try {
      await deleteBatch(id)
      setConfirmId(null)
      setFlash('Batch deleted.')
      setReloadKey((k) => k + 1)
    } catch (err) {
      setActionError(err.message)
    }
  }

  const { loading, error, batches } = state
  const filtered = query.q !== '' || query.hideExpired
  const soon = batches.filter((b) => b.daysToExpiry >= 0 && b.daysToExpiry <= 2).length
  const expired = batches.filter((b) => b.daysToExpiry < 0).length

  return (
    <>
      <header className="page-head">
        <div>
          <h1>Surplus food batches</h1>
          <p className="muted">Batches available for collection, soonest expiry first.</p>
        </div>
        <Link to="/batches/new" className="button primary">Add batch</Link>
      </header>

      {flash && <p className="flash" role="status">{flash}</p>}

      <section className="stats" aria-label="Summary">
        <div className="stat"><span className="stat-label">{filtered ? 'Matching batches' : 'Batches listed'}</span><strong>{loading ? '–' : batches.length}</strong></div>
        <div className="stat soon"><span className="stat-label">Expire within 2 days</span><strong>{loading ? '–' : soon}</strong></div>
        <div className="stat expired"><span className="stat-label">Past expiry date</span><strong>{loading ? '–' : expired}</strong></div>
      </section>

      <section className="panel">
        <div className="toolbar">
          <label className="search">
            <span className="visually-hidden">Search by item name</span>
            <input
              type="search"
              placeholder="Search by item name"
              maxLength={80}
              value={query.q}
              onChange={(e) => setQuery((old) => ({ ...old, q: e.target.value }))}
            />
          </label>
          <label className="check">
            <input
              type="checkbox"
              checked={query.hideExpired}
              onChange={(e) => setQuery((old) => ({ ...old, hideExpired: e.target.checked }))}
            />
            Hide expired batches
          </label>
        </div>

        {actionError && <p className="error-box" role="alert">{actionError}</p>}

        {loading && <p className="notice">Loading batches…</p>}
        {!loading && error && (
          <div className="error-box" role="alert">
            <p>{error}</p>
            <button type="button" className="button" onClick={() => { setState((s) => ({ ...s, loading: true })); setReloadKey((k) => k + 1) }}>
              Try again
            </button>
          </div>
        )}
        {!loading && !error && batches.length === 0 && (
          <div className="empty">
            {filtered ? (
              <>
                <p>No batches match this search.</p>
                <button type="button" className="button" onClick={() => setQuery({ q: '', hideExpired: false })}>Clear search</button>
              </>
            ) : (
              <>
                <p>No batches recorded yet.</p>
                <Link to="/batches/new" className="button primary">Add the first batch</Link>
              </>
            )}
          </div>
        )}

        {!loading && !error && batches.length > 0 && (
          <ul className="batch-grid">
            {batches.map((batch) => (
              <li key={batch.id} className="batch-card">
                <div className="batch-top">
                  <h2 className="item-name">{batch.itemName}</h2>
                  <span className={`tag ${expiryTone(batch.daysToExpiry)}`}>{expiryLabel(batch.daysToExpiry)}</span>
                </div>
                <p className="qty"><strong>{formatQuantity(batch.quantity)}</strong> {batch.unit}</p>
                <p className="expiry">Expires {formatDay(batch.expiryDate)}</p>
                {batch.collectionNote && <p className="note">{batch.collectionNote}</p>}
                {confirmId === batch.id ? (
                  <div className="card-actions confirm" role="group" aria-label="Confirm delete">
                    <span>Delete this batch?</span>
                    <button type="button" className="button danger" onClick={() => confirmDelete(batch.id)}>Yes, delete</button>
                    <button type="button" className="button" onClick={() => setConfirmId(null)}>Keep</button>
                  </div>
                ) : (
                  <div className="card-actions">
                    <Link to={`/batches/${batch.id}/edit`} className="button">Edit</Link>
                    <button type="button" className="button ghost-danger" onClick={() => setConfirmId(batch.id)}>Delete</button>
                  </div>
                )}
              </li>
            ))}
          </ul>
        )}
      </section>
    </>
  )
}
