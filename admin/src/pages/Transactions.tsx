import { useState } from 'react';
import { useNavigate, useParams, useSearchParams } from 'react-router-dom';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { api, fmtDate, fmtMoney, type Money } from '../api/client';
import { Badge, DataTable, ErrorBox, PageHead, ReasonDialog } from '../components/ui';
import { useAuth } from '../lib/auth';

type Tx = { id: string; reference: string; userId: string; type: string; status: string; statusReason: string | null; amount: Money; fee: Money; total: Money; provider: string; description: string | null; externalRef: string | null; providerRequestId: string | null; createdAt: string; completedAt: string | null; counterparty: Record<string, string | null>; risk?: { score: number; flags: string[]; reviewRequired: boolean }; reversal?: { requestedAt?: string; reason?: string } | null; ip?: string; deviceId?: string };

export function TransactionsPage() {
  const nav = useNavigate();
  const [params] = useSearchParams();
  const [f, setF] = useState({ q: '', status: params.get('status') ?? '', type: '', provider: '', reviewRequired: '', from: '', to: '' });
  const [applied, setApplied] = useState(f);
  return (
    <>
      <PageHead title="Transactions" subtitle="Search, monitor and investigate. Financial fields cannot be edited." />
      <form className="filters" onSubmit={(e) => { e.preventDefault(); setApplied(f); }}>
        <input className="input" placeholder="Reference / receipt / provider id" value={f.q} onChange={(e) => setF({ ...f, q: e.target.value })} aria-label="Search" />
        <select className="input" value={f.status} onChange={(e) => setF({ ...f, status: e.target.value })} aria-label="Status"><option value="">Any status</option>{['INITIATED', 'PENDING', 'PROCESSING', 'SUCCESSFUL', 'FAILED', 'REVERSED'].map((s) => <option key={s}>{s}</option>)}</select>
        <select className="input" value={f.type} onChange={(e) => setF({ ...f, type: e.target.value })} aria-label="Type"><option value="">Any type</option>{['SEND_MONEY', 'PAYBILL', 'BUY_GOODS', 'AIRTIME', 'UTILITY', 'DEPOSIT', 'CARD_PAYMENT', 'BANK_TRANSFER'].map((s) => <option key={s}>{s}</option>)}</select>
        <input className="input" placeholder="Provider" value={f.provider} onChange={(e) => setF({ ...f, provider: e.target.value })} aria-label="Provider" />
        <input className="input" type="date" value={f.from} onChange={(e) => setF({ ...f, from: e.target.value })} aria-label="From" />
        <input className="input" type="date" value={f.to} onChange={(e) => setF({ ...f, to: e.target.value })} aria-label="To" />
        <label className="row" style={{ fontWeight: 500 }}><input type="checkbox" checked={f.reviewRequired === 'true'} onChange={(e) => setF({ ...f, reviewRequired: e.target.checked ? 'true' : '' })} /> Needs review</label>
        <button className="btn btn-primary">Apply</button>
      </form>
      <DataTable<Tx> queryKey={['txs']} path="/transactions" query={applied} rowKey={(t) => t.id} onRowClick={(t) => nav(`/transactions/${t.id}`)}
        columns={[
          { key: 'ref', header: 'Reference', render: (t) => <span className="mono">{t.reference}</span> },
          { key: 'type', header: 'Type', render: (t) => t.type.replace(/_/g, ' ').toLowerCase() },
          { key: 'desc', header: 'Description', render: (t) => <span className="muted">{t.description}</span> },
          { key: 'status', header: 'Status', render: (t) => <>{<Badge value={t.status} />} {t.risk?.reviewRequired && <Badge value="HIGH" />}</> },
          { key: 'provider', header: 'Provider', render: (t) => t.provider },
          { key: 'amount', header: 'Amount', className: 'num', render: (t) => fmtMoney(t.amount) },
          { key: 'at', header: 'Created', render: (t) => fmtDate(t.createdAt) },
        ]} />
    </>
  );
}

type Detail = { transaction: Tx; events: { kind: string; from: string | null; to: string; source: string; actorId: string | null; reason: string | null; at: string }[]; callbacks: { id: string; outcome: string; processingStatus: string; note: string | null; signatureValid: boolean; receivedAt: string; payload: unknown }[]; approvals: { id: string; status: string; reason: string; createdAt: string }[]; note: string };

export function TransactionDetailPage() {
  const { id } = useParams();
  const qc = useQueryClient();
  const { can } = useAuth();
  const q = useQuery({ queryKey: ['tx', id], queryFn: () => api<Detail>(`/transactions/${id}`) });
  const [dialog, setDialog] = useState<null | 'flag' | 'unflag' | 'reverse'>(null);
  const [msg, setMsg] = useState<string | null>(null);
  const refresh = () => qc.invalidateQueries({ queryKey: ['tx', id] });
  const d = q.data;
  const t = d?.transaction;
  return (
    <>
      <PageHead title={t ? t.reference : 'Transaction'} subtitle={t?.description ?? undefined}
        actions={t && <>
          <button className="btn" onClick={async () => { const r = await api<{ status: string }>(`/transactions/${id}/check-status`, { method: 'POST' }); setMsg(`Provider status: ${r.status}`); await refresh(); }}>Check with provider</button>
          {can('transactions.flag') && (t.risk?.reviewRequired ? <button className="btn" onClick={() => setDialog('unflag')}>Clear flag</button> : <button className="btn" onClick={() => setDialog('flag')}>Flag for review</button>)}
          {can('transactions.reverse.request') && t.status === 'SUCCESSFUL' && !t.reversal?.requestedAt && <button className="btn btn-danger" onClick={() => setDialog('reverse')}>Request reversal</button>}
        </>} />
      <ErrorBox error={q.error} />
      {msg && <div className="alert alert-info">{msg}</div>}
      {d && t && (
        <>
          <div className="alert alert-info">{d.note}</div>
          <div className="grid grid-2">
            <div className="card"><h2 style={{ marginBottom: 12 }}>Details</h2>
              <dl className="dl">
                <dt>Status</dt><dd><Badge value={t.status} /> {t.statusReason && <span className="muted">{t.statusReason}</span>}</dd>
                <dt>Amount</dt><dd className="mono">{fmtMoney(t.amount)} + fee {fmtMoney(t.fee)} = <strong>{fmtMoney(t.total)}</strong></dd>
                <dt>Type</dt><dd>{t.type}</dd>
                <dt>Provider</dt><dd>{t.provider} · <span className="mono">{t.providerRequestId ?? '—'}</span></dd>
                <dt>Provider receipt</dt><dd className="mono">{t.externalRef ?? '—'}</dd>
                <dt>Counterparty</dt><dd>{Object.entries(t.counterparty).filter(([, v]) => v).map(([k, v]) => `${k}: ${v}`).join(' · ') || '—'}</dd>
                <dt>Customer</dt><dd><a href={`/users/${t.userId}`}>Open profile</a></dd>
                <dt>Risk</dt><dd>score {t.risk?.score ?? 0} {t.risk?.flags?.map((x) => <span key={x} className="chip" style={{ marginLeft: 4 }}>{x}</span>)}</dd>
                <dt>Created / completed</dt><dd>{fmtDate(t.createdAt)} → {fmtDate(t.completedAt)}</dd>
                {t.reversal?.requestedAt && <><dt>Reversal</dt><dd>Requested {fmtDate(t.reversal.requestedAt)} — awaiting provider confirmation{t.reversal.reason ? ` (${t.reversal.reason})` : ''}</dd></>}
              </dl>
            </div>
            <div className="card"><h2 style={{ marginBottom: 12 }}>Immutable event history</h2>
              <ul className="timeline">{d.events.map((e, i) => (
                <li key={i}><strong>{e.kind === 'STATUS_CHANGE' ? `${e.from ?? '∅'} → ${e.to}` : e.kind.replace(/_/g, ' ').toLowerCase()}</strong> <span className="faint">via {e.source.toLowerCase().replace('_', ' ')}</span>
                  <div className="faint" style={{ fontSize: 12 }}>{fmtDate(e.at)}{e.reason ? ` · ${e.reason}` : ''}</div></li>
              ))}</ul>
            </div>
          </div>
          {d.callbacks.length > 0 && (
            <div className="card" style={{ marginTop: 16 }}><h2 style={{ marginBottom: 12 }}>Provider callbacks</h2>
              <table><thead><tr><th>Received</th><th>Outcome</th><th>Processing</th><th>Signature</th><th>Payload</th></tr></thead><tbody>
                {d.callbacks.map((c) => <tr key={c.id}><td>{fmtDate(c.receivedAt)}</td><td>{c.outcome}</td><td><Badge value={c.processingStatus} /> <span className="faint">{c.note}</span></td><td>{c.signatureValid ? 'valid' : 'invalid'}</td><td><code className="mono" style={{ fontSize: 11 }}>{JSON.stringify(c.payload)}</code></td></tr>)}
              </tbody></table>
            </div>
          )}
        </>
      )}
      {dialog === 'flag' && <ReasonDialog title="Flag for investigation" confirmLabel="Flag" onClose={() => setDialog(null)} onConfirm={async (reason) => { await api(`/transactions/${id}/flag`, { method: 'POST', body: { flagged: true, reason } }); await refresh(); }} />}
      {dialog === 'unflag' && <ReasonDialog title="Clear review flag" confirmLabel="Clear flag" onClose={() => setDialog(null)} onConfirm={async (reason) => { await api(`/transactions/${id}/flag`, { method: 'POST', body: { flagged: false, reason } }); await refresh(); }} />}
      {dialog === 'reverse' && <ReasonDialog danger title="Request a reversal" description="A second finance administrator must approve this. The transaction only becomes REVERSED after the provider confirms." confirmLabel="Submit for approval" onClose={() => setDialog(null)} onConfirm={async (reason) => { await api(`/transactions/${id}/reversal-requests`, { method: 'POST', body: { reason } }); setMsg('Reversal request submitted for approval.'); await refresh(); }} />}
    </>
  );
}
