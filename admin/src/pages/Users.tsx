import { useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { api, fmtDate, fmtMoney, type Money } from '../api/client';
import { Badge, DataTable, ErrorBox, PageHead, ReasonDialog } from '../components/ui';
import { useAuth } from '../lib/auth';

type U = { id: string; phone: string; email: string | null; name: string | null; status: string; kycStatus: string; kycTier: string; country: string; restrictions: string[]; lastLoginAt: string | null; createdAt: string; piiMasked: boolean; suspensionReason: string | null };

export function UsersPage() {
  const nav = useNavigate();
  const [q, setQ] = useState('');
  const [status, setStatus] = useState('');
  const [search, setSearch] = useState('');
  return (
    <>
      <PageHead title="Users" subtitle="Search by phone, email, name, referral code or user id" />
      <form className="filters" onSubmit={(e) => { e.preventDefault(); setSearch(q); }}>
        <input className="input" style={{ minWidth: 280 }} placeholder="0712 345 678, name@email.com…" value={q} onChange={(e) => setQ(e.target.value)} aria-label="Search users" />
        <select className="input" value={status} onChange={(e) => setStatus(e.target.value)} aria-label="Status">
          <option value="">All statuses</option>{['ACTIVE', 'PENDING_VERIFICATION', 'SUSPENDED', 'CLOSED'].map((s) => <option key={s}>{s}</option>)}
        </select>
        <button className="btn btn-primary">Search</button>
      </form>
      <DataTable<U> queryKey={['users']} path="/users" query={{ q: search, status }} rowKey={(u) => u.id} onRowClick={(u) => nav(`/users/${u.id}`)}
        columns={[
          { key: 'name', header: 'Name', render: (u) => <strong>{u.name || '—'}</strong> },
          { key: 'phone', header: 'Phone', render: (u) => <span className="mono">{u.phone}</span> },
          { key: 'status', header: 'Status', render: (u) => <Badge value={u.status} /> },
          { key: 'kyc', header: 'KYC', render: (u) => <><Badge value={u.kycStatus} /> <span className="faint">{u.kycTier.replace('_', ' ')}</span></> },
          { key: 'last', header: 'Last sign-in', render: (u) => fmtDate(u.lastLoginAt) },
          { key: 'joined', header: 'Joined', render: (u) => fmtDate(u.createdAt) },
        ]} />
    </>
  );
}

type Detail = {
  user: U;
  kyc: { id: string; idType: string; idNumberLast4: string; fullName: string; status: string; rejectionReason: string | null; submittedAt: string }[];
  devices: { id: string; name: string; platform: string; trusted: boolean; revoked: boolean; lastSeenAt: string; lastIp?: string }[];
  activeSessions: number;
  recentTransactions: { id: string; reference: string; type: string; status: string; amount: Money; createdAt: string; risk?: { flags: string[] } }[];
  securityEvents: { id: string; type: string; severity: string; at: string }[];
  tickets: { id: string; reference: string; subject: string; status: string }[];
};

const RESTRICTIONS = ['NO_PAYMENTS', 'NO_WITHDRAWALS', 'NO_LOGIN', 'REVIEW_REQUIRED'];

export function UserDetailPage() {
  const { id } = useParams();
  const nav = useNavigate();
  const qc = useQueryClient();
  const { can } = useAuth();
  const q = useQuery({ queryKey: ['user', id], queryFn: () => api<Detail>(`/users/${id}`) });
  const [dialog, setDialog] = useState<null | 'suspend' | 'reactivate' | 'revoke' | 'restrict'>(null);
  const [restrictions, setRestrictions] = useState<string[]>([]);
  const refresh = () => qc.invalidateQueries({ queryKey: ['user', id] });
  const d = q.data;
  return (
    <>
      <PageHead title={d?.user.name || 'User'} subtitle={d ? `${d.user.phone} · ${d.user.country} · joined ${fmtDate(d.user.createdAt)}` : undefined}
        actions={d && <>
          {can('users.suspend') && d.user.status !== 'SUSPENDED' && <button className="btn btn-danger" onClick={() => setDialog('suspend')}>Suspend</button>}
          {can('users.suspend') && d.user.status === 'SUSPENDED' && <button className="btn btn-primary" onClick={() => setDialog('reactivate')}>Reactivate</button>}
          {can('users.restrict') && <button className="btn" onClick={() => { setRestrictions(d.user.restrictions); setDialog('restrict'); }}>Restrictions</button>}
          {can('security.manage') && <button className="btn" onClick={() => setDialog('revoke')}>Sign out everywhere</button>}
        </>} />
      <ErrorBox error={q.error} />
      {d && (
        <>
          {d.user.piiMasked && <div className="alert alert-info">Personal data is masked for your role.</div>}
          {d.user.status === 'SUSPENDED' && <div className="alert alert-warn">Suspended: {d.user.suspensionReason}</div>}
          <div className="grid grid-3">
            <div className="card"><h2 style={{ marginBottom: 12 }}>Account</h2>
              <dl className="dl">
                <dt>Status</dt><dd><Badge value={d.user.status} /></dd>
                <dt>KYC</dt><dd><Badge value={d.user.kycStatus} /> {d.user.kycTier}</dd>
                <dt>Email</dt><dd>{d.user.email ?? '—'}</dd>
                <dt>Restrictions</dt><dd>{d.user.restrictions.length ? <div className="chip-list">{d.user.restrictions.map((r) => <span key={r} className="chip">{r}</span>)}</div> : 'None'}</dd>
                <dt>Active sessions</dt><dd>{d.activeSessions}</dd>
                <dt>Last sign-in</dt><dd>{fmtDate(d.user.lastLoginAt)}</dd>
              </dl>
            </div>
            <div className="card"><h2 style={{ marginBottom: 12 }}>Devices</h2>
              {d.devices.length === 0 && <div className="faint">No devices</div>}
              {d.devices.map((x) => <div key={x.id} className="row" style={{ marginBottom: 8 }}><strong>{x.name}</strong><span className="faint">{x.platform}</span><span className="spacer" />{x.revoked ? <Badge value="REVOKED" /> : x.trusted ? <Badge value="VERIFIED" /> : <Badge value="PENDING" />}</div>)}
            </div>
            <div className="card"><h2 style={{ marginBottom: 12 }}>Security events</h2>
              {d.securityEvents.length === 0 && <div className="faint">None</div>}
              {d.securityEvents.slice(0, 8).map((e) => <div key={e.id} className="row" style={{ marginBottom: 6 }}><Badge value={e.severity} /><span>{e.type.replace(/_/g, ' ').toLowerCase()}</span><span className="spacer" /><span className="faint">{fmtDate(e.at)}</span></div>)}
            </div>
          </div>
          <div className="grid grid-2" style={{ marginTop: 16 }}>
            <div className="card"><h2 style={{ marginBottom: 12 }}>Recent transactions</h2>
              <table><tbody>{d.recentTransactions.map((t) => (
                <tr key={t.id} className="clickable" onClick={() => nav(`/transactions/${t.id}`)}>
                  <td className="mono">{t.reference}</td><td>{t.type.replace(/_/g, ' ').toLowerCase()}</td><td><Badge value={t.status} /></td><td className="num">{fmtMoney(t.amount)}</td>
                </tr>))}</tbody></table>
              {d.recentTransactions.length === 0 && <div className="empty">No transactions</div>}
            </div>
            <div className="card"><h2 style={{ marginBottom: 12 }}>KYC submissions & tickets</h2>
              {d.kyc.map((k) => <div key={k.id} className="row" style={{ marginBottom: 8 }}><span>{k.idType.replace('_', ' ')} ••{k.idNumberLast4}</span><Badge value={k.status} /><span className="spacer" /><span className="faint">{fmtDate(k.submittedAt)}</span></div>)}
              {d.tickets.map((t) => <div key={t.id} className="row" style={{ marginBottom: 8 }}><span className="mono">{t.reference}</span><span>{t.subject}</span><span className="spacer" /><Badge value={t.status} /></div>)}
              {!d.kyc.length && !d.tickets.length && <div className="faint">None</div>}
            </div>
          </div>
        </>
      )}
      {dialog === 'suspend' && <ReasonDialog danger title="Suspend account" description="The user is signed out everywhere and cannot sign in or pay until reactivated." confirmLabel="Suspend" onClose={() => setDialog(null)} onConfirm={async (reason) => { await api(`/users/${id}/suspend`, { method: 'POST', body: { reason } }); await refresh(); }} />}
      {dialog === 'reactivate' && <ReasonDialog title="Reactivate account" confirmLabel="Reactivate" onClose={() => setDialog(null)} onConfirm={async (reason) => { await api(`/users/${id}/reactivate`, { method: 'POST', body: { reason } }); await refresh(); }} />}
      {dialog === 'revoke' && <ReasonDialog title="Sign out of all sessions" confirmLabel="Revoke sessions" onClose={() => setDialog(null)} onConfirm={async (reason) => { await api(`/users/${id}/revoke-sessions`, { method: 'POST', body: { reason } }); await refresh(); }} />}
      {dialog === 'restrict' && <ReasonDialog title="Account restrictions" confirmLabel="Save restrictions" onClose={() => setDialog(null)}
        extra={<div className="field">{RESTRICTIONS.map((r) => <label key={r} className="row" style={{ fontWeight: 500 }}><input type="checkbox" checked={restrictions.includes(r)} onChange={(e) => setRestrictions(e.target.checked ? [...restrictions, r] : restrictions.filter((x) => x !== r))} />{r.replace(/_/g, ' ').toLowerCase()}</label>)}</div>}
        onConfirm={async (reason) => { await api(`/users/${id}/restrictions`, { method: 'PUT', body: { restrictions, reason } }); await refresh(); }} />}
    </>
  );
}
