import { useEffect, useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import { UNITS, createBatch, getBatch, updateBatch } from './api.js'

const EMPTY = { itemName: '', quantity: '', unit: '', expiryDate: '', collectionNote: '' }

// Local date as yyyy-mm-dd; toISOString alone would give the UTC date.
function todayIso() {
  const now = new Date()
  return new Date(now.getTime() - now.getTimezoneOffset() * 60000).toISOString().slice(0, 10)
}

// The same rules as the API, so most mistakes are shown before a request is sent.
function validate(values, editing) {
  const errors = {}
  const name = values.itemName.trim()
  if (!name) errors.itemName = 'Item name is required'
  else if (name.length < 2 || name.length > 80) errors.itemName = 'Item name must be 2 to 80 characters'
  if (values.quantity === '') errors.quantity = 'Quantity is required'
  else if (!(Number(values.quantity) > 0)) errors.quantity = 'Quantity must be more than zero'
  else if (Number(values.quantity) > 99999) errors.quantity = 'Quantity is too large'
  else if (!/^\d+(\.\d{1,2})?$/.test(values.quantity)) errors.quantity = 'Quantity can have at most 2 decimal places'
  if (!values.unit) errors.unit = 'Choose a unit'
  if (!values.expiryDate) errors.expiryDate = 'Expiry date is required'
  else if (!editing && values.expiryDate < todayIso()) errors.expiryDate = 'Expiry date cannot be in the past'
  if (values.collectionNote.length > 300) errors.collectionNote = 'Collection note must be at most 300 characters'
  return errors
}

function Field({ label, name, error, hint, children }) {
  return (
    <div className={error ? 'field has-error' : 'field'}>
      <label htmlFor={name}>{label}</label>
      {children}
      {hint && !error && <span className="hint">{hint}</span>}
      {error && <span className="field-error" id={`${name}-error`}>{error}</span>}
    </div>
  )
}

export default function BatchForm() {
  const { id } = useParams()
  const editing = Boolean(id)
  const navigate = useNavigate()
  const [values, setValues] = useState(EMPTY)
  const [errors, setErrors] = useState({})
  const [formError, setFormError] = useState('')
  const [loading, setLoading] = useState(editing)
  const [saving, setSaving] = useState(false)

  useEffect(() => {
    if (!editing) return
    let current = true
    getBatch(id)
      .then((b) => current && setValues({
        itemName: b.itemName, quantity: String(b.quantity), unit: b.unit,
        expiryDate: b.expiryDate, collectionNote: b.collectionNote ?? '',
      }))
      .catch((err) => current && setFormError(err.status === 404 ? 'This batch no longer exists.' : err.message))
      .finally(() => current && setLoading(false))
    return () => { current = false }
  }, [editing, id])

  function change(e) {
    const { name, value } = e.target
    setValues((old) => ({ ...old, [name]: value }))
    setErrors((old) => ({ ...old, [name]: undefined }))
  }

  async function submit(e) {
    e.preventDefault()
    setFormError('')
    const found = validate(values, editing)
    setErrors(found)
    if (Object.keys(found).length) return
    const payload = { ...values, itemName: values.itemName.trim(), quantity: Number(values.quantity) }
    setSaving(true)
    try {
      if (editing) await updateBatch(id, payload)
      else await createBatch(payload)
      navigate('/', { state: { flash: editing ? 'Batch updated.' : 'Batch added.' } })
    } catch (err) {
      setErrors(err.fields ?? {})
      setFormError(err.message)
      setSaving(false)
    }
  }

  const describedBy = (name) => (errors[name] ? `${name}-error` : undefined)

  if (loading) return <p className="notice">Loading batch…</p>

  return (
    <>
      <header className="page-head">
        <div>
          <h1>{editing ? 'Edit batch' : 'Add batch'}</h1>
          <p className="muted">{editing ? 'Change the details and save.' : 'Record a surplus batch that is ready for collection.'}</p>
        </div>
      </header>
      <form className="panel form" onSubmit={submit} noValidate>
        {formError && <p className="error-box" role="alert">{formError}</p>}
        <Field label="Item name" name="itemName" error={errors.itemName}>
          <input id="itemName" name="itemName" value={values.itemName} onChange={change} maxLength={80}
            aria-invalid={Boolean(errors.itemName)} aria-describedby={describedBy('itemName')} />
        </Field>
        <div className="row">
          <Field label="Quantity" name="quantity" error={errors.quantity}>
            <input id="quantity" name="quantity" inputMode="decimal" value={values.quantity} onChange={change}
              aria-invalid={Boolean(errors.quantity)} aria-describedby={describedBy('quantity')} />
          </Field>
          <Field label="Unit" name="unit" error={errors.unit}>
            <select id="unit" name="unit" value={values.unit} onChange={change}
              aria-invalid={Boolean(errors.unit)} aria-describedby={describedBy('unit')}>
              <option value="">Choose…</option>
              {UNITS.map((u) => <option key={u} value={u}>{u}</option>)}
            </select>
          </Field>
          <Field label="Expiry date" name="expiryDate" error={errors.expiryDate}>
            <input id="expiryDate" name="expiryDate" type="date" value={values.expiryDate} onChange={change}
              min={editing ? undefined : todayIso()}
              aria-invalid={Boolean(errors.expiryDate)} aria-describedby={describedBy('expiryDate')} />
          </Field>
        </div>
        <Field label="Collection note (optional)" name="collectionNote" error={errors.collectionNote}
          hint={`${values.collectionNote.length}/300, for example where and when to collect`}>
          <textarea id="collectionNote" name="collectionNote" rows={3} value={values.collectionNote} onChange={change}
            aria-invalid={Boolean(errors.collectionNote)} aria-describedby={describedBy('collectionNote')} />
        </Field>
        <div className="actions">
          <button type="submit" className="button primary" disabled={saving}>
            {saving ? 'Saving…' : editing ? 'Save changes' : 'Add batch'}
          </button>
          <Link to="/" className="button">Cancel</Link>
        </div>
      </form>
    </>
  )
}
