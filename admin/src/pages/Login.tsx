import { useEffect, useState } from 'react';
import QRCode from 'qrcode';
import { api } from '../api/client';
import { useAuth } from '../lib/auth';
import { ErrorBox } from '../components/ui';

type Step = { kind: 'password' } | { kind: 'verify'; mfaToken: string } | { kind: 'enroll'; mfaToken: string; secret?: string; qr?: string };

export default function Login() {
  const { signIn } = useAuth();
  const [step, setStep] = useState<Step>({ kind: 'password' });
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [code, setCode] = useState('');
  const [error, setError] = useState<unknown>(null);
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    if (step.kind !== 'enroll' || step.secret) return;
    api<{ secret: string; otpauthUri: string }>('/auth/mfa/setup', { method: 'POST', body: { mfaToken: step.mfaToken } })
      .then(async (r) => setStep({ ...step, secret: r.secret, qr: await QRCode.toDataURL(r.otpauthUri, { margin: 1, width: 200 }) }))
      .catch(setError);
  }, [step]);

  async function run(fn: () => Promise<void>) {
    setBusy(true); setError(null);
    try { await fn(); } catch (e) { setError(e); } finally { setBusy(false); }
  }

  return (
    <div className="auth-wrap">
      <section className="auth-hero">
        <div className="brand" style={{ padding: 0 }}><img src="/favicon.svg" width={34} height={34} alt="" /> Pesa <small>Operations console</small></div>
        <div>
          <h1>Run the platform with confidence.</h1>
          <p style={{ color: '#A9C0D4', maxWidth: 440 }}>Every privileged action is MFA-protected, permission-checked and written to a tamper-evident audit log.</p>
        </div>
        <p style={{ color: '#6E8499', fontSize: 12 }}>Authorised personnel only. Activity is monitored.</p>
      </section>
      <section className="auth-form">
        <div className="auth-card">
          <h1 style={{ marginBottom: 6 }}>{step.kind === 'password' ? 'Sign in' : step.kind === 'enroll' ? 'Set up two-factor' : 'Two-factor check'}</h1>
          <p className="muted" style={{ marginTop: 0 }}>
            {step.kind === 'password' && 'Use your administrator email and password.'}
            {step.kind === 'verify' && 'Enter the 6-digit code from your authenticator app.'}
            {step.kind === 'enroll' && 'Scan this code with an authenticator app (Google Authenticator, 1Password, Authy), then enter the 6-digit code.'}
          </p>
          <ErrorBox error={error} />
          {step.kind === 'password' ? (
            <form onSubmit={(e) => { e.preventDefault(); void run(async () => {
              const r = await api<{ next: 'MFA_VERIFY' | 'MFA_ENROLL'; mfaToken: string }>('/auth/login', { method: 'POST', body: { email, password } });
              setPassword('');
              setStep(r.next === 'MFA_ENROLL' ? { kind: 'enroll', mfaToken: r.mfaToken } : { kind: 'verify', mfaToken: r.mfaToken });
            }); }}>
              <div className="field"><label htmlFor="email">Email</label><input id="email" className="input" type="email" autoComplete="username" required value={email} onChange={(e) => setEmail(e.target.value)} /></div>
              <div className="field"><label htmlFor="password">Password</label><input id="password" className="input" type="password" autoComplete="current-password" required value={password} onChange={(e) => setPassword(e.target.value)} /></div>
              <button className="btn btn-primary" style={{ width: '100%', justifyContent: 'center' }} disabled={busy}>{busy ? 'Checking…' : 'Continue'}</button>
            </form>
          ) : (
            <form onSubmit={(e) => { e.preventDefault(); void run(async () => {
              const path = step.kind === 'enroll' ? '/auth/mfa/enroll' : '/auth/mfa/verify';
              const r = await api<{ accessToken: string }>(path, { method: 'POST', body: { mfaToken: step.mfaToken, code } });
              await signIn(r.accessToken);
            }); }}>
              {step.kind === 'enroll' && (
                <div style={{ textAlign: 'center', marginBottom: 14 }}>
                  {step.qr ? <img src={step.qr} alt="Authenticator QR code" width={200} height={200} style={{ borderRadius: 12, background: '#fff' }} /> : <div className="empty">Preparing…</div>}
                  {step.secret && <p className="mono faint" style={{ wordBreak: 'break-all' }}>{step.secret}</p>}
                </div>
              )}
              <div className="field"><label htmlFor="code">Authentication code</label>
                <input id="code" className="input mono" inputMode="numeric" autoComplete="one-time-code" maxLength={6} pattern="\d{6}" required value={code} onChange={(e) => setCode(e.target.value.replace(/\D/g, ''))} autoFocus />
              </div>
              <button className="btn btn-primary" style={{ width: '100%', justifyContent: 'center' }} disabled={busy || code.length !== 6}>{busy ? 'Verifying…' : 'Verify and sign in'}</button>
              <button type="button" className="btn btn-ghost" style={{ width: '100%', justifyContent: 'center', marginTop: 8 }} onClick={() => { setStep({ kind: 'password' }); setCode(''); }}>Start over</button>
            </form>
          )}
        </div>
      </section>
    </div>
  );
}
