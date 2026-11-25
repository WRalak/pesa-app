import { useState } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import { api, fmtDate } from '../api/client';
import { Badge, DataTable, ErrorBox, Modal, PageHead } from '../components/ui';
import { useAuth } from '../lib/auth';

type Msg = { id: string; authorType: string; body: string; internal?: boolean; createdAt: string };
type T = { id: string; reference: string; userId: string; category: string; subject: string; status: string; priority: string; messages: Msg[]; createdAt: string; metadata?: { requestedPhone?: string } };

export default function SupportPage() {
  const qc = useQueryClient();
  const { can } = useAuth();
  const [status, setStatus] = useState('OPEN');
  const [open, setOpen] = useState<T | null>(null);
  const [msg, setMsg] = useState('');
  const [internal, setInternal] = useState(false);
  const [next, setNext] = useState('');
  const [error, setError] = useState<unknown>(null);
  return (
    <>
      <PageHead title="Support" subtitle="Customer tickets, including account-recovery requests that need identity checks" />
      <div className="filters">{['OPEN', 'IN_PROGRESS', 'AWAITING_USER', 'RESOLVED', 'CLOSED'].map((s) => <button key={s} className={`btn btn-sm ${status === s ? 'btn-primary' : ''}`} onClick={() => setStatus(s)}>{s.replace('_', ' ').toLowerCase()}</button>)}</div>
      <DataTable<T> queryKey={['tickets']} path="/support/tickets" query={{ status }} rowKey={(t) => t.id} onRowClick={setOpen}
        columns={[
          { key: 'ref', header: 'Reference', render: (t) => <span className="mono">{t.reference}</span> },
          { key: 'subject', header: 'Subject', render: (t) => <strong>{t.subject}</strong> },
          { key: 'cat', header: 'Category', render: (t) => t.category.replace(/_/g, ' ').toLowerCase() },
          { key: 'prio', header: 'Priority', render: (t) => <Badge value={t.priority === 'HIGH' || t.priority === 'URGENT' ? 'HIGH' : 'LOW'} /> },
          { key: 'status', header: 'Status', render: (t) => <Badge value={t.status} /> },
          { key: 'at', header: 'Opened', render: (t) => fmtDate(t.createdAt) },
        ]} />
      {open && (
        <Modal title={`${open.reference} · ${open.subject}`} onClose={() => setOpen(null)}>
          <ErrorBox error={error} />
          {open.category === 'ACCOUNT_RECOVERY' && <div className="alert alert-warn">Phone-change request to {open.metadata?.requestedPhone}. Verify identity against KYC before acting — SIM-swap fraud risk.</div>}
          <ul className="timeline">{open.messages.map((m) => <li key={m.id}><strong>{m.authorType.toLowerCase()}</strong>{m.internal && <span className="chip" style={{ marginLeft: 6 }}>internal</span>} <span className="faint">{fmtDate(m.createdAt)}</span><div>{m.body}</div></li>)}</ul>
          <p><a href={`/users/${open.userId}`}>Open customer profile</a></p>
          {can('support.manage') && (
            <>
              <div className="field"><label htmlFor="msg">Reply</label><textarea id="msg" className="input" rows={3} value={msg} onChange={(e) => setMsg(e.target.value)} /></div>
              <div className="row">
                <label className="row" style={{ fontWeight: 500 }}><input type="checkbox" checked={internal} onChange={(e) => setInternal(e.target.checked)} /> Internal note</label>
                <select className="input" style={{ width: 'auto' }} value={next} onChange={(e) => setNext(e.target.value)} aria-label="Set status"><option value="">Keep status</option>{['IN_PROGRESS', 'AWAITING_USER', 'RESOLVED', 'CLOSED'].map((s) => <option key={s}>{s}</option>)}</select>
                <span className="spacer" />
                <button className="btn btn-primary" disabled={!msg.trim()} onClick={async () => {
                  setError(null);
                  try {
                    const t = await api<T>(`/support/tickets/${open.id}/messages`, { method: 'POST', body: { message: msg, internal, status: next || undefined } });
                    setOpen({ ...open, ...t }); setMsg(''); setNext('');
                    await qc.invalidateQueries({ queryKey: ['tickets'] });
                  } catch (e) { setError(e); }
                }}>Send</button>
              </div>
            </>
          )}
        </Modal>
      )}
    </>
  );
}
