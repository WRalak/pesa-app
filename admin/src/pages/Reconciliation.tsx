import { useState } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import { api, fmtDate, fmtMoney, type Money } from '../api/client';
import { Badge, DataTable, ErrorBox, Modal, PageHead, ReasonDialog } from '../components/ui';
import { useAuth } from '../lib/auth';

type R = { id: string; runId: string; provider: string; reference?: string; transactionId?: string; externalRef?: string; internalStatus?: string; providerStatus?: string; internalAmount: Money | null; providerAmount: Money | null; result: string; resolution: string; resolutionNote?: string; createdAt: string };

export default function ReconciliationPage() {
  const qc = useQueryClient();
  const { can } = useAuth();
  const [resolution, setResolution] = useState('OPEN');
  const [runOpen, setRunOpen] = useState(false);
  const [resolve, setResolve] = useState<{ rec: R; to: 'RESOLVED' | 'ESCALATED' } | null>(null);
  const today = new Date().toISOString().slice(0, 10);
  const [form, setForm] = useState({ provider: 'mock', from: new Date(Date.now() - 86_400_000).toISOString().slice(0, 10), to: today });
  const [summary, setSummary] = useState<Record<string, unknown> | null>(null);
  const [error, setError] = useState<unknown>(null);
  return (
    <>
      <PageHead title="Reconciliation" subtitle="Ledger vs provider settlement. Non-terminal payments auto-resolve; conflicts are never auto-changed."
        actions={can('reconciliation.run') && <button className="btn btn-primary" onClick={() => setRunOpen(true)}>Run reconciliation</button>} />
      {summary && <div className="alert alert-info mono">{JSON.stringify(summary)}</div>}
      <div className="filters">{['OPEN', 'ESCALATED', 'RESOLVED', 'NOT_REQUIRED'].map((s) => <button key={s} className={`btn btn-sm ${resolution === s ? 'btn-primary' : ''}`} onClick={() => setResolution(s)}>{s.replace('_', ' ').toLowerCase()}</button>)}</div>
      <DataTable<R> queryKey={['recon']} path="/reconciliation/records" query={{ resolution }} rowKey={(r) => r.id}
        columns={[
          { key: 'run', header: 'Run', render: (r) => <span className="mono faint">{r.runId}</span> },
          { key: 'ref', header: 'Transaction', render: (r) => (r.transactionId ? <a className="mono" href={`/transactions/${r.transactionId}`}>{r.reference}</a> : <span className="mono">{r.externalRef ?? '—'}</span>) },
          { key: 'res', header: 'Result', render: (r) => <Badge value={r.result} /> },
          { key: 'st', header: 'Ours → provider', render: (r) => `${r.internalStatus ?? '—'} → ${r.providerStatus ?? '—'}` },
          { key: 'amt', header: 'Amounts', className: 'num', render: (r) => `${fmtMoney(r.internalAmount)} / ${fmtMoney(r.providerAmount)}` },
          { key: 'at', header: 'When', render: (r) => fmtDate(r.createdAt) },
          { key: 'act', header: '', render: (r) => (can('reconciliation.resolve') && ['OPEN', 'ESCALATED'].includes(r.resolution) ? <div className="row"><button className="btn btn-sm" onClick={() => setResolve({ rec: r, to: 'ESCALATED' })}>Escalate</button><button className="btn btn-sm btn-primary" onClick={() => setResolve({ rec: r, to: 'RESOLVED' })}>Resolve</button></div> : <Badge value={r.resolution} />) },
        ]} />
      {runOpen && (
        <Modal title="Run reconciliation" onClose={() => setRunOpen(false)}>
          <ErrorBox error={error} />
          <div className="field"><label htmlFor="p">Provider</label><input id="p" className="input" value={form.provider} onChange={(e) => setForm({ ...form, provider: e.target.value })} /></div>
          <div className="grid grid-2"><div className="field"><label htmlFor="f">From</label><input id="f" type="date" className="input" value={form.from} onChange={(e) => setForm({ ...form, from: e.target.value })} /></div>
            <div className="field"><label htmlFor="t">To (exclusive)</label><input id="t" type="date" className="input" value={form.to} onChange={(e) => setForm({ ...form, to: e.target.value })} /></div></div>
          <div className="row"><span className="spacer" /><button className="btn btn-primary" onClick={async () => {
            setError(null);
            try { setSummary(await api('/reconciliation/runs', { method: 'POST', body: { provider: form.provider, from: new Date(form.from).toISOString(), to: new Date(new Date(form.to).getTime() + 86_400_000).toISOString() } })); setRunOpen(false); await qc.invalidateQueries({ queryKey: ['recon'] }); } catch (e) { setError(e); }
          }}>Run</button></div>
        </Modal>
      )}
      {resolve && <ReasonDialog title={resolve.to === 'RESOLVED' ? 'Resolve exception' : 'Escalate exception'} description="This records the outcome of your investigation. It does not change the transaction." confirmLabel={resolve.to === 'RESOLVED' ? 'Mark resolved' : 'Escalate'} onClose={() => setResolve(null)} onConfirm={async (note) => { await api(`/reconciliation/records/${resolve.rec.id}/resolve`, { method: 'POST', body: { resolution: resolve.to, note } }); await qc.invalidateQueries({ queryKey: ['recon'] }); }} />}
    </>
  );
}
