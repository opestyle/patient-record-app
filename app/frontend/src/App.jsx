import { useEffect, useState } from 'react';

const initialPatientState = {
  name: '',
  age: '',
  gender: '',
  contact: '',
  diagnosis: '',
  prescription: '',
};

function LoginForm({ onLogin }) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [submitting, setSubmitting] = useState(false);

  const handleSubmit = async (event) => {
    event.preventDefault();
    setSubmitting(true);
    setError('');
    try {
      const response = await fetch('/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: new URLSearchParams({ username: email, password }),
      });
      if (!response.ok) {
        setError('Incorrect email or password.');
        return;
      }
      const data = await response.json();
      onLogin(data.access_token);
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="app-shell">
      <h1>Patient Records Portal</h1>
      <form onSubmit={handleSubmit} className="card">
        <input
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          placeholder="Email"
          type="email"
          required
        />
        <input
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          placeholder="Password"
          type="password"
          required
        />
        <button type="submit" disabled={submitting}>
          {submitting ? 'Signing in...' : 'Sign in'}
        </button>
        {error ? <p>{error}</p> : null}
      </form>
    </div>
  );
}

function App() {
  const [token, setToken] = useState(() => localStorage.getItem('token'));
  const [form, setForm] = useState(initialPatientState);
  const [patients, setPatients] = useState([]);
  const [message, setMessage] = useState('');

  const handleLogin = (accessToken) => {
    localStorage.setItem('token', accessToken);
    setToken(accessToken);
  };

  const handleLogout = () => {
    localStorage.removeItem('token');
    setToken(null);
  };

  const authedFetch = async (url, options = {}) => {
    const response = await fetch(url, {
      ...options,
      headers: {
        ...options.headers,
        Authorization: `Bearer ${token}`,
      },
    });
    if (response.status === 401) {
      handleLogout();
    }
    return response;
  };

  const loadPatients = async () => {
    const response = await authedFetch('/api/patients');
    if (!response.ok) return;
    const data = await response.json();
    setPatients(data);
  };

  useEffect(() => {
    if (token) {
      loadPatients();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [token]);

  if (!token) {
    return <LoginForm onLogin={handleLogin} />;
  }

  const handleSubmit = async (event) => {
    event.preventDefault();
    const response = await authedFetch('/api/patients', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        ...form,
        age: Number(form.age),
      }),
    });

    if (response.ok) {
      setMessage('Patient saved successfully.');
      setForm(initialPatientState);
      loadPatients();
    } else {
      setMessage('Unable to save patient.');
    }
  };

  return (
    <div className="app-shell">
      <h1>Patient Records Portal</h1>
      <p>
        Register patients, track diagnoses, and manage prescriptions.{' '}
        <button type="button" onClick={handleLogout}>
          Sign out
        </button>
      </p>
      <form onSubmit={handleSubmit} className="card">
        <input value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} placeholder="Name" required />
        <input value={form.age} onChange={(e) => setForm({ ...form, age: e.target.value })} placeholder="Age" required type="number" />
        <input value={form.gender} onChange={(e) => setForm({ ...form, gender: e.target.value })} placeholder="Gender" required />
        <input value={form.contact} onChange={(e) => setForm({ ...form, contact: e.target.value })} placeholder="Contact" required />
        <textarea value={form.diagnosis} onChange={(e) => setForm({ ...form, diagnosis: e.target.value })} placeholder="Diagnosis" />
        <textarea value={form.prescription} onChange={(e) => setForm({ ...form, prescription: e.target.value })} placeholder="Prescription" />
        <button type="submit">Create Patient</button>
      </form>
      {message ? <p>{message}</p> : null}
      <div className="card">
        <h2>Recent Patients</h2>
        <ul>
          {patients.map((patient) => (
            <li key={patient.id}>
              <strong>{patient.name}</strong> — {patient.gender}, {patient.age} years
            </li>
          ))}
        </ul>
      </div>
    </div>
  );
}

export default App;
