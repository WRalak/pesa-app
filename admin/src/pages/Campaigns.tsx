import { useState } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import { api, fmtDate, fmtMoney, type Money } from '../api/client';
import { Badge, DataTable, ErrorBox, Modal, PageHead } from '../components/ui';
import { useAuth } from '../lib/auth';

type C = { id: string; code: string; name: string; type: string; status: string; startsAt: string; endsAt?: string; rules: Record<string, unknown>; budgetUsed: Money; totalBudget: Money | null };
type NC = { id: string; title: string; status: string; sentCount: number; scheduledAt: string };
type Ref = { id: string; referrerId: string; refereeId: string; status: string; fraudSignals: string[]; createdAt: string };

export default function CampaignsPage() {
  const qc = useQueryClient();
  const { can } = useAuth();
  const [tab, setTab] = useState<'rewards' | 'notifications' | 'referrals'>('rewards');
  const [create, setCreate] = useState(false);
  const [notify, setNotify] = useState(false);
  const [error, setError] = useState<unknown>(null);
  const [form, setForm] = useState({ code: '', name: '', description: '', type: 'CASHBACK', startsAt: new Date().toISOString().slice(0, 10), endsAt: '', transactionTypes: 'AIRTIME', cashbackBps: 200, maxReward: '50', pointsPerUnit: 1, totalBudget: '' });
  const [msg, setMsg] = useState({ title: '', body: '' });
  const setStatus = async (c: C, status: string) => { setError(null); try { await api(`/campaigns/${c.id}/status`, { method: 'POST', body: { status } }); await qc.invalidateQueries({ queryKey: ['campaigns'] }); } catch (e) { setError(e); } };
  return (
    <>
      <PageHead title="Campaigns" subtitle="Rewards, cashback, referrals and promotional messages — all rules are configuration."
        actions={can('campaigns.manage') && <><button className="btn" onClick={() => setNotify(true)} disabled={!can('notifications.campaign')}>New message</button><button className="btn btn-primary" onClick={() => setCreate(true)}>New campaign</button></>} />
      <ErrorBox error={error} />
      <div className="filters">{(['rewards', 'notifications', 'referrals'] as const).map((t) => <button key={t} className={`btn btn-sm ${tab === t ? 'btn-primary' : ''}`} onClick={() => setTab(t)}>{t}</button>)}</div>
      {tab === 'rewards' && <DataTable<C> queryKey={['campaigns']} path="/campaigns" rowKey={(c) => c.id}
        columns={[
          { key: 'code', header: 'Code', render: (c) => <span className="mono">{c.code}</span> },
          { key: 'name', header: 'Name', render: (c) => <strong>{c.name}</strong> },
          { key: 'type', header: 'Type', render: (c) => c.type.toLowerCase().replace('_', ' ') },
          { key: 'status', header: 'Status', render: (c) => <Badge value={c.status} /> },
          { key: 'budget', header: 'Budget used', className: 'num', render: (c) => (c.totalBudget ? `${fmtMoney(c.budgetUsed)} / ${fmtMoney(c.totalBudget)}` : '—') },
          { key: 'dates', header: 'Runs', render: (c) => `${fmtDate(c.startsAt)}${c.endsAt ? ` → ${fmtDate(c.endsAt)}` : ''}` },
          { key: 'act', header: '', render: (c) => can('campaigns.manage') && <div className="row">
            {['DRAFT', 'PAUSED'].includes(c.status) && <button className="btn btn-sm btn-primary" onClick={() => void setStatus(c, 'ACTIVE')}>Activate</button>}
            {c.status === 'ACTIVE' && <button className="btn btn-sm" onClick={() => void setStatus(c, 'PAUSED')}>Pause</button>}
            {c.status !== 'ENDED' && <button className="btn btn-sm" onClick={() => void setStatus(c, 'ENDED')}>End</button>}
          </div> },
        ]} />}
      {tab === 'notifications' && <DataTable<NC> queryKey={['ncampaigns']} path="/notification-campaigns" rowKey={(c) => c.id}
        columns={[{ key: 't', header: 'Title', render: (c) => c.title }, { key: 's', header: 'Status', render: (c) => <Badge value={c.status} /> }, { key: 'n', header: 'Recipients', className: 'num', render: (c) => c.sentCount.toLocaleString() }, { key: 'at', header: 'Scheduled', render: (c) => fmtDate(c.scheduledAt) }]} />}
      {tab === 'referrals' && <DataTable<Ref> queryKey={['referrals']} path="/referrals" rowKey={(r) => r.id}
        columns={[{ key: 'r', header: 'Referrer', render: (r) => <a href={`/users/${r.referrerId}`} className="mono">{r.referrerId.slice(-8)}</a> }, { key: 'e', header: 'Referee', render: (r) => <a href={`/users/${r.refereeId}`} className="mono">{r.refereeId.slice(-8)}</a> }, { key: 's', header: 'Status', render: (r) => <Badge value={r.status} /> }, { key: 'f', header: 'Fraud signals', render: (r) => r.fraudSignals.map((f) => <span key={f} className="chip">{f}</span>) }, { key: 'at', header: 'Created', render: (r) => fmtDate(r.createdAt) }]} />}
      {create && (
        <Modal title="New reward campaign" onClose={() => setCreate(false)}>
          <ErrorBox error={error} />
          <div className="grid grid-2">
            <div className="field"><label htmlFor="code">Code</label><input id="code" className="input mono" value={form.code} onChange={(e) => setForm({ ...form, code: e.target.value.toUpperCase().replace(/[^A-Z0-9_]/g, '') })} /></div>
            <div className="field"><label htmlFor="type">Type</label><select id="type" className="input" value={form.type} onChange={(e) => setForm({ ...form, type: e.target.value })}>{['CASHBACK', 'POINTS', 'PARTNER_DEAL'].map((t) => <option key={t}>{t}</option>)}</select></div>
          </div>
          <div className="field"><label htmlFor="name">Name</label><input id="name" className="input" value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} /></div>
          <div className="field"><label htmlFor="desc">Description (shown to customers)</label><input id="desc" className="input" value={form.description} onChange={(e) => setForm({ ...form, description: e.target.value })} /></div>
          <div className="grid grid-2">
            <div className="field"><label htmlFor="tt">Transaction types (comma separated)</label><input id="tt" className="input" value={form.transactionTypes} onChange={(e) => setForm({ ...form, transactionTypes: e.target.value })} /></div>
            {form.type === 'CASHBACK' ? <div className="field"><label htmlFor="bps">Cashback (basis points)</label><input id="bps" type="number" className="input" value={form.cashbackBps} onChange={(e) => setForm({ ...form, cashbackBps: Number(e.target.value) })} /></div>
              : <div className="field"><label htmlFor="ppu">Points per KES 100</label><input id="ppu" type="number" className="input" value={form.pointsPerUnit} onChange={(e) => setForm({ ...form, pointsPerUnit: Number(e.target.value) })} /></div>}
            <div className="field"><label htmlFor="max">Max reward per txn (KES)</label><input id="max" className="input" value={form.maxReward} onChange={(e) => setForm({ ...form, maxReward: e.target.value })} /></div>
            <div className="field"><label htmlFor="bud">Total budget (KES, optional)</label><input id="bud" className="input" value={form.totalBudget} onChange={(e) => setForm({ ...form, totalBudget: e.target.value })} /></div>
            <div className="field"><label htmlFor="sa">Starts</label><input id="sa" type="date" className="input" value={form.startsAt} onChange={(e) => setForm({ ...form, startsAt: e.target.value })} /></div>
            <div className="field"><label htmlFor="ea">Ends (optional)</label><input id="ea" type="date" className="input" value={form.endsAt} onChange={(e) => setForm({ ...form, endsAt: e.target.value })} /></div>
          </div>
          <div className="row"><span className="spacer" /><button className="btn btn-primary" disabled={form.code.length < 3 || !form.name} onClick={async () => {
            setError(null);
            try {
              const types = form.transactionTypes.split(',').map((x) => x.trim()).filter(Boolean);
              await api('/campaigns', { method: 'POST', body: {
                code: form.code, name: form.name, description: form.description || undefined, type: form.type, startsAt: new Date(form.startsAt).toISOString(), endsAt: form.endsAt ? new Date(form.endsAt).toISOString() : undefined,
                rules: { transactionTypes: types.length ? types : undefined, ...(form.type === 'CASHBACK' ? { cashbackBps: form.cashbackBps, maxReward: form.maxReward || undefined } : { pointsPerUnit: form.pointsPerUnit }) },
                totalBudget: form.totalBudget || undefined,
              } });
              setCreate(false); await qc.invalidateQueries({ queryKey: ['campaigns'] });
            } catch (e) { setError(e); }
          }}>Create as draft</button></div>
        </Modal>
      )}
      {notify && (
        <Modal title="Promotional message" onClose={() => setNotify(false)}>
          <div className="alert alert-info">Sent only to customers who opted in to marketing. Security and transaction alerts are separate.</div>
          <ErrorBox error={error} />
          <div className="field"><label htmlFor="nt">Title</label><input id="nt" className="input" maxLength={120} value={msg.title} onChange={(e) => setMsg({ ...msg, title: e.target.value })} /></div>
          <div className="field"><label htmlFor="nb">Message</label><textarea id="nb" className="input" rows={3} maxLength={500} value={msg.body} onChange={(e) => setMsg({ ...msg, body: e.target.value })} /></div>
          <div className="row"><span className="spacer" /><button className="btn btn-primary" disabled={msg.title.length < 3 || msg.body.length < 3} onClick={async () => {
            setError(null);
            try { await api('/notification-campaigns', { method: 'POST', body: msg }); setNotify(false); setMsg({ title: '', body: '' }); setTab('notifications'); await qc.invalidateQueries({ queryKey: ['ncampaigns'] }); } catch (e) { setError(e); }
          }}>Send now</button></div>
        </Modal>
      )}
    </>
  );
}
