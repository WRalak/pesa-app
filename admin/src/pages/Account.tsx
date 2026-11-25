import { useState } from 'react';
import { api } from '../api/client';
import { ErrorBox, PageHead } from '../components/ui';
import { useAuth } from '../lib/auth';

export default function AccountPage() {
  const [cur, setCur] = useState('');
  const [next, setNext] = useState('');
  const [done, setDone] = useState(false);
  const [error, setError] = useState<unknown>(null);
  const { admin, reload } = useAuth();
  return (
    <>
      <PageHead title="Account" subtitle="Change your password. Use a unique passphrase of at least 12 characters." />
      <div className="card" style={{ maxWidth: 460 }}>
        <ErrorBox error={error} />
        {admin?.mustChangePassword && <div className="alert alert-warn">You are using a temporary password. Set your own to continue.</div>}
        {done && <div className="alert alert-info">Password changed.</div>}
        <form onSubmit={async (e) => { e.preventDefault(); setError(null); try { await api('/auth/password', { method: 'POST', body: { currentPassword: cur, newPassword: next } }); setDone(true); setCur(''); setNext(''); await reload(); } catch (x) { setError(x); } }}>
          <div className="field"><label htmlFor="c">Current password</label><input id="c" type="password" className="input" autoComplete="current-password" value={cur} onChange={(e) => setCur(e.target.value)} /></div>
          <div className="field"><label htmlFor="n">New password</label><input id="n" type="password" className="input" autoComplete="new-password" minLength={12} value={next} onChange={(e) => setNext(e.target.value)} /></div>
          <button className="btn btn-primary" disabled={!cur || next.length < 12}>Update password</button>
        </form>
      </div>
    </>
  );
}
