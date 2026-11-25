import { useState } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import { api, fmtDate } from '../api/client';
import { Badge, DataTable, ErrorBox, PageHead } from '../components/ui';
import { useAuth } from '../lib/auth';

type E = { id: string; type: string; severity: string; userId: string | null; adminId: string | null; ip: string; details: Record<string, unknown> | null; acknowledged: boolean; at: string };
type L = { seq: number; actorType: string; actorId: string; action: string; resourceType: string; resourceId: string; outcome: string; ip: string; metadata: unknown; at: string; hash: string };

export function SecurityPage() {
  const qc = useQueryClient();
  const { can } = useAuth();
  const [filter, setFilter] = useState<Record<string, string>>({ unacknowledged: 'true' });
  const [error, setError] = useState<unknown>(null);
  return (
    <>
      <PageHead title="Security events" subtitle="Suspicious logins, lockouts, token reuse, rejected callbacks, fraud flags and admin sign-ins" />
      <ErrorBox error={error} />
      <div className="filters">
        {[['Unacknowledged', { unacknowledged: 'true' }], ['High & critical', { severity: 'HIGH' }], ['Critical', { severity: 'CRITICAL' }], ['Admin activity', { admin: 'true' }], ['All', {}]].map(([label, f]) => (
          <button key={label as string} className={`btn btn-sm ${JSON.stringify(filter) === JSON.stringify(f) ? 'btn-primary' : ''}`} onClick={() => setFilter(f as Record<string, string>)}>{label as string}</button>
        ))}
      </div>
      <DataTable<E> queryKey={['security']} path="/security/events" query={filter} rowKey={(e) => e.id}
        columns={[
          { key: 'at', header: 'When', render: (e) => fmtDate(e.at) },
          { key: 'sev', header: 'Severity', render: (e) => <Badge value={e.severity} /> },
          { key: 'type', header: 'Event', render: (e) => e.type.replace(/_/g, ' ').toLowerCase() },
          { key: 'who', header: 'Subject', render: (e) => (e.userId ? <a href={`/users/${e.userId}`}>user</a> : e.adminId ? 'admin' : '—') },
          { key: 'ip', header: 'IP', render: (e) => <span className="mono">{e.ip ?? '—'}</span> },
          { key: 'details', header: 'Details', render: (e) => <span className="faint mono" style={{ fontSize: 11 }}>{e.details ? JSON.stringify(e.details).slice(0, 80) : ''}</span> },
          { key: 'ack', header: '', render: (e) => (e.acknowledged ? <span className="faint">acknowledged</span> : can('security.manage') && <button className="btn btn-sm" onClick={async () => { setError(null); try { await api(`/security/events/${e.id}/acknowledge`, { method: 'POST', body: {} }); await qc.invalidateQueries({ queryKey: ['security'] }); } catch (x) { setError(x); } }}>Acknowledge</button>) },
        ]} />
    </>
  );
}

export function AuditPage() {
  const [action, setAction] = useState('');
  const [applied, setApplied] = useState('');
  const [verify, setVerify] = useState<{ valid: boolean; checked: number; brokenAt?: number } | null>(null);
  return (
    <>
      <PageHead title="Audit log" subtitle="Append-only and hash-chained. Any deletion or edit breaks the chain."
        actions={<button className="btn btn-primary" onClick={async () => setVerify(await api('/audit-logs/verify'))}>Verify integrity</button>} />
      {verify && <div className={`alert ${verify.valid ? 'alert-info' : 'alert-error'}`}>{verify.valid ? `Chain intact — ${verify.checked} entries verified.` : `Chain BROKEN at entry #${verify.brokenAt}. Escalate immediately.`}</div>}
      <form className="filters" onSubmit={(e) => { e.preventDefault(); setApplied(action); }}>
        <input className="input" placeholder="Action prefix, e.g. admin.reversal" value={action} onChange={(e) => setAction(e.target.value)} aria-label="Action" />
        <button className="btn btn-primary">Filter</button>
      </form>
      <DataTable<L> queryKey={['audit']} path="/audit-logs" query={{ action: applied }} rowKey={(l) => String(l.seq)}
        columns={[
          { key: 'seq', header: '#', render: (l) => l.seq },
          { key: 'at', header: 'When', render: (l) => fmtDate(l.at) },
          { key: 'actor', header: 'Actor', render: (l) => <>{l.actorType.toLowerCase()} <span className="mono faint">{l.actorId?.slice(-6)}</span></> },
          { key: 'action', header: 'Action', render: (l) => <span className="mono">{l.action}</span> },
          { key: 'res', header: 'Resource', render: (l) => <>{l.resourceType} <span className="mono faint">{l.resourceId?.slice(-8)}</span></> },
          { key: 'meta', header: 'Details', render: (l) => <span className="faint mono" style={{ fontSize: 11 }}>{l.metadata ? JSON.stringify(l.metadata).slice(0, 90) : ''}</span> },
          { key: 'hash', header: 'Hash', render: (l) => <span className="mono faint">{l.hash.slice(0, 10)}…</span> },
        ]} />
    </>
  );
}
