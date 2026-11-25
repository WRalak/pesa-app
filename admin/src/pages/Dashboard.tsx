import { useQuery } from '@tanstack/react-query';
import { Area, AreaChart, CartesianGrid, ResponsiveContainer, Tooltip, XAxis, YAxis } from 'recharts';
import { api, fmtMoney, type Money } from '../api/client';
import { Badge, ErrorBox, Kpi, PageHead } from '../components/ui';

type Dash = {
  users: { total: number; new7d: number; active30d: number; kyc: Record<string, number> };
  transactions24h: { total: number; byStatus: Record<string, { count: number; valueMinor: number }>; successfulValue: Money };
  volume30d: { date: string; count: number; value: Money }[];
  providers: { provider: string; successRate: number | null; completed: number; avgCompletionSeconds: number | null }[];
  alerts: { fraudAndSecurity: number; stalePending: number; reconciliationExceptions: number; pendingApprovals: number };
  health: { mongo: string; redis: string; queues: Record<string, Record<string, number> | null> };
};

export default function Dashboard() {
  const q = useQuery({ queryKey: ['dashboard'], queryFn: () => api<Dash>('/dashboard'), refetchInterval: 30_000 });
  const d = q.data;
  const s = d?.transactions24h.byStatus;
  const n = (x?: number) => (x ?? 0).toLocaleString('en-KE');
  return (
    <>
      <PageHead title="Dashboard" subtitle="Live operational overview · refreshes every 30 seconds" />
      <ErrorBox error={q.error} />
      {d && (
        <>
          <div className="grid grid-4">
            <Kpi accent label="Successful value (24h)" value={fmtMoney(d.transactions24h.successfulValue)} sub={`${n(s?.SUCCESSFUL.count)} successful payments`} />
            <Kpi label="Registered users" value={n(d.users.total)} sub={`+${n(d.users.new7d)} this week · ${n(d.users.active30d)} active (30d)`} />
            <Kpi label="Transactions (24h)" value={n(d.transactions24h.total)} sub={<>{n(s?.FAILED.count)} failed · {n((s?.PENDING.count ?? 0) + (s?.PROCESSING.count ?? 0))} in flight</>} />
            <Kpi label="KYC" value={`${n(d.users.kyc.VERIFIED)} verified`} sub={`${n(d.users.kyc.PENDING)} awaiting review`} />
          </div>
          <div className="grid grid-4" style={{ marginTop: 16 }}>
            {[
              ['Fraud & security alerts', d.alerts.fraudAndSecurity, '/security'],
              ['Stuck pending (>15 min)', d.alerts.stalePending, '/transactions?status=PENDING'],
              ['Reconciliation exceptions', d.alerts.reconciliationExceptions, '/reconciliation'],
              ['Approvals waiting', d.alerts.pendingApprovals, '/approvals'],
            ].map(([label, value, href]) => (
              <a key={label as string} href={href as string} className="card kpi" style={{ textDecoration: 'none', borderColor: Number(value) > 0 ? 'var(--coral-500)' : undefined }}>
                <div className="label">{label}</div><div className="value" style={{ color: Number(value) > 0 ? 'var(--coral-500)' : undefined }}>{n(value as number)}</div>
              </a>
            ))}
          </div>
          <div className="grid" style={{ gridTemplateColumns: '2fr 1fr', marginTop: 16 }}>
            <div className="card">
              <div className="card-head"><h2>Successful volume · 30 days</h2></div>
              <div style={{ height: 260 }}>
                <ResponsiveContainer>
                  <AreaChart data={d.volume30d.map((v) => ({ date: v.date.slice(5), value: Number(v.value.amount), count: v.count }))} margin={{ left: 0, right: 8, top: 8 }}>
                    <defs><linearGradient id="g" x1="0" x2="0" y1="0" y2="1"><stop offset="0%" stopColor="#10B981" stopOpacity={0.35} /><stop offset="100%" stopColor="#10B981" stopOpacity={0} /></linearGradient></defs>
                    <CartesianGrid stroke="var(--border)" vertical={false} />
                    <XAxis dataKey="date" tick={{ fontSize: 11, fill: 'var(--text-3)' }} axisLine={false} tickLine={false} />
                    <YAxis tick={{ fontSize: 11, fill: 'var(--text-3)' }} axisLine={false} tickLine={false} width={70} tickFormatter={(v: number) => v.toLocaleString('en-KE', { notation: 'compact' })} />
                    <Tooltip contentStyle={{ background: 'var(--surface)', border: '1px solid var(--border)', borderRadius: 10 }} formatter={(v) => [`KES ${Number(v).toLocaleString('en-KE')}`, 'Volume']} />
                    <Area type="monotone" dataKey="value" stroke="#059669" strokeWidth={2} fill="url(#g)" />
                  </AreaChart>
                </ResponsiveContainer>
              </div>
            </div>
            <div className="card">
              <div className="card-head"><h2>Provider performance · 7d</h2></div>
              {d.providers.length === 0 && <div className="empty">No completed payments yet</div>}
              {d.providers.map((p) => (
                <div key={p.provider} style={{ marginBottom: 14 }}>
                  <div className="row"><strong>{p.provider}</strong><span className="spacer" /><span className="num">{p.successRate ?? '—'}%</span></div>
                  <div style={{ height: 8, background: 'var(--surface-2)', borderRadius: 99, marginTop: 6, overflow: 'hidden' }}>
                    <div style={{ width: `${p.successRate ?? 0}%`, height: '100%', background: (p.successRate ?? 0) > 90 ? 'var(--emerald-500)' : 'var(--gold-500)' }} />
                  </div>
                  <div className="faint" style={{ fontSize: 12, marginTop: 4 }}>{p.completed} completed · avg {p.avgCompletionSeconds ?? '—'}s to confirm</div>
                </div>
              ))}
              <div className="card-head" style={{ marginTop: 18 }}><h2>System health</h2></div>
              <div className="row"><span>MongoDB</span><Badge value={d.health.mongo} /><span>Redis</span><Badge value={d.health.redis} /></div>
              {Object.entries(d.health.queues).map(([q2, c]) => (
                <div key={q2} className="row faint" style={{ fontSize: 12, marginTop: 6 }}><span className="mono">{q2}</span><span className="spacer" />{c ? `${c.waiting} waiting · ${c.active} active · ${c.failed} failed` : 'unavailable'}</div>
              ))}
            </div>
          </div>
        </>
      )}
    </>
  );
}
