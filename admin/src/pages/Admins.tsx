import { useState } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { api, fmtDate } from '../api/client';
import { Badge, ErrorBox, Modal, PageHead, ReasonDialog } from '../components/ui';

type A = { id: string; email: string; name: string; roles: string[]; status: string; mfaEnabled: boolean; lastLoginAt: string | null };
type Roles = { roles: { key: string; name: string; permissions: string[] }[]; permissions: { key: string; group: string; description: string }[] };

export default function AdminsPage() {
  const qc = useQueryClient();
  const admins = useQuery({ queryKey: ['admins'], queryFn: () => api<{ items: A[] }>('/admins') });
  const roles = useQuery({ queryKey: ['roles'], queryFn: () => api<Roles>('/roles') });
  const [invite, setInvite] = useState(false);
  const [form, setForm] = useState({ email: '', name: '', roles: [] as string[] });
  const [temp, setTemp] = useState<string | null>(null);
  const [editing, setEditing] = useState<{ admin: A; change: Record<string, unknown>; title: string } | null>(null);
  const [error, setError] = useState<unknown>(null);
  const refresh = () => qc.invalidateQueries({ queryKey: ['admins'] });
  return (
    <>
      <PageHead title="Administrators" subtitle="Role-based access. MFA is mandatory for every administrator." actions={<button className="btn btn-primary" onClick={() => { setInvite(true); setTemp(null); }}>Invite administrator</button>} />
      <ErrorBox error={admins.error} />
      <div className="card"><table>
        <thead><tr><th>Name</th><th>Email</th><th>Roles</th><th>Status</th><th>MFA</th><th>Last sign-in</th><th /></tr></thead>
        <tbody>{admins.data?.items.map((a) => (
          <tr key={a.id}><td><strong>{a.name}</strong></td><td>{a.email}</td><td><div className="chip-list">{a.roles.map((r) => <span key={r} className="chip">{r.replace(/_/g, ' ').toLowerCase()}</span>)}</div></td>
            <td><Badge value={a.status} /></td><td>{a.mfaEnabled ? 'enrolled' : <Badge value="PENDING" />}</td><td>{fmtDate(a.lastLoginAt)}</td>
            <td><div className="row">
              <button className="btn btn-sm" onClick={() => setEditing({ admin: a, change: { status: a.status === 'ACTIVE' ? 'DISABLED' : 'ACTIVE' }, title: a.status === 'ACTIVE' ? `Disable ${a.name}` : `Enable ${a.name}` })}>{a.status === 'ACTIVE' ? 'Disable' : 'Enable'}</button>
              <button className="btn btn-sm" onClick={() => setEditing({ admin: a, change: { resetMfa: true }, title: `Reset MFA for ${a.name}` })}>Reset MFA</button>
            </div></td></tr>
        ))}</tbody></table></div>
      {roles.data && (
        <div className="card" style={{ marginTop: 16 }}><h2 style={{ marginBottom: 12 }}>Role permissions</h2>
          <div className="table-wrap"><table><thead><tr><th>Permission</th>{roles.data.roles.map((r) => <th key={r.key} style={{ textAlign: 'center' }}>{r.name.replace(' Administrator', '')}</th>)}</tr></thead>
            <tbody>{roles.data.permissions.map((p) => <tr key={p.key}><td><span className="mono">{p.key}</span><div className="faint" style={{ fontSize: 12 }}>{p.description}</div></td>{roles.data.roles.map((r) => <td key={r.key} style={{ textAlign: 'center' }}>{r.permissions.includes(p.key) ? '●' : ''}</td>)}</tr>)}</tbody></table></div>
        </div>
      )}
      {invite && (
        <Modal title="Invite administrator" onClose={() => setInvite(false)}>
          <ErrorBox error={error} />
          {temp ? (
            <><div className="alert alert-warn">Temporary password (shown once). Share it through a secure channel. They must enrol MFA and change it at first sign-in.</div><p className="mono" style={{ fontSize: 16 }}>{temp}</p></>
          ) : (
            <>
              <div className="field"><label htmlFor="em">Email</label><input id="em" className="input" type="email" value={form.email} onChange={(e) => setForm({ ...form, email: e.target.value })} /></div>
              <div className="field"><label htmlFor="nm">Name</label><input id="nm" className="input" value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} /></div>
              <div className="field"><label>Roles (least privilege)</label>{roles.data?.roles.map((r) => <label key={r.key} className="row" style={{ fontWeight: 500 }}><input type="checkbox" checked={form.roles.includes(r.key)} onChange={(e) => setForm({ ...form, roles: e.target.checked ? [...form.roles, r.key] : form.roles.filter((x) => x !== r.key) })} />{r.name}</label>)}</div>
              <div className="row"><span className="spacer" /><button className="btn btn-primary" disabled={!form.email || !form.name || !form.roles.length} onClick={async () => {
                setError(null);
                try { const r = await api<{ temporaryPassword: string }>('/admins', { method: 'POST', body: form }); setTemp(r.temporaryPassword); setForm({ email: '', name: '', roles: [] }); await refresh(); } catch (e) { setError(e); }
              }}>Create</button></div>
            </>
          )}
        </Modal>
      )}
      {editing && <ReasonDialog danger title={editing.title} description="Their active sessions are revoked immediately." onClose={() => setEditing(null)} onConfirm={async (reason) => { await api(`/admins/${editing.admin.id}`, { method: 'PATCH', body: { ...editing.change, reason } }); await refresh(); }} />}
    </>
  );
}
