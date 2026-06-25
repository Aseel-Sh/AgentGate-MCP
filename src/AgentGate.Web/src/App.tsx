import { Link, Route, Routes } from 'react-router-dom'

function HomePage() {
  return (
    <main>
      <h1>AgentGate</h1>
      <p>Controlled MCP tool access for AI agents.</p>
      <Link to="/approvals">View approvals</Link>
    </main>
  )
}

function ApprovalsPage() {
  return (
    <main>
      <h1>Approvals</h1>
      <p>No approval requests yet.</p>
    </main>
  )
}

export default function App() {
  return (
    <Routes>
      <Route path="/" element={<HomePage />} />
      <Route path="/approvals" element={<ApprovalsPage />} />
    </Routes>
  )
}