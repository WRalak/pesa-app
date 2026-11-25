import { useState } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { api, fmtDate, fmtMoney, type Money } from '../api/client';
import { Badge, ErrorBox, Kpi, Modal, PageHead } from '../components/ui';
import { useAuth } from '../lib/auth';

type Summary = { providers: { provider: string; currency: string; byStatus: Record<string, { count: number; amount: Money }>; feeRevenue: Money; settledVolume: Money }[]; reversals: { id: string; reference: string; status: string; amount: Money; requestedAt: string | null; completedAt: string | null }[]; reconciliation: Record<string, number>; note: string };
type Fee = { type: string; minAmountMinor: number; maxAmountMinor: number; fixedMinor: number; bps: number };
type Provider = { code: string; name: string; kind?: string; enabled: boolean; maintenance?: boolean; priority?: number; sandbox?: boolean; countries?: string[]; currencies?: string[]; fees: Fee[]; active: boolean; unconfigured?: boolean };

const toMajor = (m: number) => (m / 100).toFixed(2);

export default function FinancePage() {
  const { can } = useAuth();
  const qc = useQueryClient();
  const s = useQuery({ queryKey: ['finance'], queryFn: () => api<Summary>('/finance/summary') });
  const p = useQuery({ queryKey: ['providers'], queryFn: () => api<{ items: Provider[] }>('/providers') });
  const [edit, setEdit] = useState<Provider | null>(null);
  const [fees, setFees] = useState<{ type: string; minAmount: string; maxAmount: string; fixed: string; bps: number }[]>([]);
  const [reason, setReason] = useState('');
  const [error, setError] = useState<unknown>(null);
  const totalFees = s.data?.providers.reduce((a, x) => a + x.feeRevenue.amountMinor, 0) ?? 0;
  const totalVol = s.data?.providers.reduce((a, x) => a + x.settledVolume.amountMinor, 0) ?? 0;
  return (
    <>
      <PageHead title="Finance & providers" subtitle="Last 30 days" />
      <ErrorBox error={s.error ?? p.error} />
      {s.data && (
        <>
          <div className="alert alert-info">{s.data.note}</div>
          <div className="grid grid-4">
            <Kpi accent label="Fee revenue" value={fmtMoney({ amountMinor: totalFees, currency: 'KES', amount: toMajor(totalFees) })} />
            <Kpi label="Successful volume" value={fmtMoney({ amountMinor: totalVol, currency: 'KES', amount: toMajor(totalVol) })} />
            <Kpi label="Reversals" value={s.data.reversals.length} sub={`${s.data.reversals.filter((r) => r.status === 'REVERSED').length} confirmed by provider`} />
            <Kpi label="Recon exceptions" value={Object.entries(s.data.reconciliation).filter(([k]) => !['MATCHED', 'AUTO_RESOLVED'].includes(k)).reduce((a, [, n]) => a + n, 0)} sub={`${s.data.reconciliation.MATCHED ?? 0} matched`} />
          </div>
          <div className="card" style={{ marginTop: 16 }}><h2 style={{ marginBottom: 12 }}>By provider</h2>
            <table><thead><tr><th>Provider</th><th className="num">Successful</th><th className="num">Failed</th><th className="num">Pending</th><th className="num">Volume</th><th className="num">Fees</th></tr></thead><tbody>
              {s.data.providers.map((x) => <tr key={x.provider}><td><strong>{x.provider}</strong></td><td className="num">{x.byStatus.SUCCESSFUL?.count ?? 0}</td><td className="num">{x.byStatus.FAILED?.count ?? 0}</td><td className="num">{(x.byStatus.PENDING?.count ?? 0) + (x.byStatus.PROCESSING?.count ?? 0)}</td><td className="num">{fmtMoney(x.settledVolume)}</td><td className="num">{fmtMoney(x.feeRevenue)}</td></tr>)}
            </tbody></table>
          </div>
          <div className="card" style={{ marginTop: 16 }}><h2 style={{ marginBottom: 12 }}>Refunds & reversals</h2>
            {s.data.reversals.length === 0 ? <div className="empty">None in this period</div> : <table><tbody>{s.data.reversals.map((r) => <tr key={r.id}><td><a className="mono" href={`/transactions/${r.id}`}>{r.reference}</a></td><td><Badge value={r.status} /></td><td className="num">{fmtMoney(r.amount)}</td><td>requested {fmtDate(r.requestedAt)}</td></tr>)}</tbody></table>}
          </div>
        </>
      )}
      <div className="card" style={{ marginTop: 16 }}><h2 style={{ marginBottom: 12 }}>Payment providers</h2>
        <table><thead><tr><th>Code</th><th>Name</th><th>State</th><th>Fee rules</th><th /></tr></thead><tbody>
          {p.data?.items.map((x) => <tr key={x.code}><td className="mono">{x.code}</td><td>{x.name}</td><td>{!x.active ? <Badge value="DISABLED" /> : x.maintenance ? <Badge value="PAUSED" /> : <Badge value="ACTIVE" />} {x.sandbox && <span className="chip">sandbox</span>}</td><td>{x.fees.length}</td>
            <td>{can('providers.manage') && <button className="btn btn-sm" onClick={() => { setEdit(x); setFees(x.fees.map((f) => ({ type: f.type, minAmount: toMajor(f.minAmountMinor), maxAmount: toMajor(Math.min(f.maxAmountMinor, 99_999_999_999)), fixed: toMajor(f.fixedMinor), bps: f.bps }))); setReason(''); }}>Configure</button>}</td></tr>)}
        </tbody></table>
      </div>
      {edit && (
        <Modal title={`Configure ${edit.code}`} onClose={() => setEdit(null)}>
          <ErrorBox error={error} />
          <div className="row" style={{ marginBottom: 12 }}>
            <label className="row"><input type="checkbox" checked={edit.enabled} onChange={(e) => setEdit({ ...edit, enabled: e.target.checked })} /> Enabled</label>
            <label className="row"><input type="checkbox" checked={Boolean(edit.maintenance)} onChange={(e) => setEdit({ ...edit, maintenance: e.target.checked })} /> Maintenance mode</label>
          </div>
          <h3 style={{ fontSize: 14, margin: '8px 0' }}>Fee rules (KES)</h3>
          {fees.map((f, i) => (
            <div key={i} className="row" style={{ marginBottom: 6 }}>
              <select className="input" style={{ width: 130 }} value={f.type} onChange={(e) => setFees(fees.map((x, j) => (j === i ? { ...x, type: e.target.value } : x)))} aria-label="Type">{['SEND_MONEY', 'PAYBILL', 'BUY_GOODS', 'AIRTIME', 'UTILITY', 'DEPOSIT', 'BANK_TRANSFER'].map((t) => <option key={t}>{t}</option>)}</select>
              <input className="input" style={{ width: 80 }} value={f.minAmount} onChange={(e) => setFees(fees.map((x, j) => (j === i ? { ...x, minAmount: e.target.value } : x)))} aria-label="Min" />
              <input className="input" style={{ width: 100 }} value={f.maxAmount} onChange={(e) => setFees(fees.map((x, j) => (j === i ? { ...x, maxAmount: e.target.value } : x)))} aria-label="Max" />
              <input className="input" style={{ width: 70 }} value={f.fixed} onChange={(e) => setFees(fees.map((x, j) => (j === i ? { ...x, fixed: e.target.value } : x)))} aria-label="Fixed" />
              <input className="input" style={{ width: 70 }} type="number" value={f.bps} onChange={(e) => setFees(fees.map((x, j) => (j === i ? { ...x, bps: Number(e.target.value) } : x)))} aria-label="Basis points" />
              <button className="btn btn-sm btn-ghost" onClick={() => setFees(fees.filter((_, j) => j !== i))} aria-label="Remove rule">✕</button>
            </div>
          ))}
          <p className="faint" style={{ fontSize: 12 }}>Columns: type · min · max · fixed fee · basis points (100 bps = 1%).</p>
          <button className="btn btn-sm" onClick={() => setFees([...fees, { type: 'PAYBILL', minAmount: '0', maxAmount: '150000', fixed: '0', bps: 0 }])}>Add rule</button>
          <div className="field" style={{ marginTop: 14 }}><label htmlFor="why">Reason for change</label><input id="why" className="input" value={reason} onChange={(e) => setReason(e.target.value)} /></div>
          <div className="row"><span className="spacer" /><button className="btn btn-primary" disabled={reason.length < 5} onClick={async () => {
            setError(null);
            try {
              await api(`/providers/${edit.code}`, { method: 'PUT', body: { name: edit.name, kind: edit.kind ?? 'AGGREGATOR', enabled: edit.enabled, maintenance: Boolean(edit.maintenance), priority: edit.priority ?? 100, countries: edit.countries ?? ['KE'], currencies: edit.currencies ?? ['KES'], sandbox: edit.sandbox ?? true, fees, reason } });
              setEdit(null); await qc.invalidateQueries({ queryKey: ['providers'] });
            } catch (e) { setError(e); }
          }}>Save</button></div>
        </Modal>
      )}
    </>
  );
}
