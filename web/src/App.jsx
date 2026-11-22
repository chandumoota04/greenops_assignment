import { NavLink, Route, Routes, useLocation } from 'react-router-dom'
import BatchList from './BatchList.jsx'
import BatchForm from './BatchForm.jsx'

export default function App() {
  const { pathname } = useLocation()
  return (
    <div className="layout">
      <aside className="sidebar">
        <div className="brand">
          <img src="/favicon.svg" alt="" width="28" height="28" />
          <span>Pantry batches</span>
        </div>
        <nav aria-label="Main">
          <NavLink to="/" end>Batches</NavLink>
          <NavLink to="/batches/new">Add batch</NavLink>
        </nav>
      </aside>
      <main className="content">
        <Routes>
          <Route path="/" element={<BatchList />} />
          <Route path="/batches/new" element={<BatchForm key="new" />} />
          <Route path="/batches/:id/edit" element={<BatchForm key={pathname} />} />
          <Route path="*" element={<p className="notice">That page does not exist.</p>} />
        </Routes>
      </main>
    </div>
  )
}
