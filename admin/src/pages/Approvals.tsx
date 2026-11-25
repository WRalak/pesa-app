import { useState } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import { api, fmtDate, fmtMoney, type Money } from '../api/client';
import { Badge, DataTable, ErrorBox, PageHead } from '../components/ui';

type A = { id: string; type: string; resourceId: string; payload: { reference: string }; amount: Money | null; reason: string; status: string; createdAt: string; mine: boolean };

export default function ApprovalsPage() {
  const qc = useQueryClient();
  const [status, setStatus] = useState('PENDING');
  const [error, setError] = useState<unknown>(null);
  const [note, setNote] = useState<string | null>(null);
  const decide = async (a: A, decision: 'APPROVE' | 'REJECT') => {
    setError(null);
    try {
      const r = await api<{ note?: string }>(`/approvals/${a.id}/decision`, { method: 'POST', body: { decision } });
      setNote(r.note ?? `Request ${decision === 'APPROVE' ? 'approved' : 'rejected'}.`);
      await qc.invalidateQueries({ queryKey: ['approvals'] });
    } catch (e) { setError(e); }
  };
  return (
    <>
      <PageHead title="Approvals" subtitle="Maker-checker queue. You cannot approve a request you raised." />
      <ErrorBox error={error} />
      {note && <div className="alert alert-info">{note}</div>}
      <div className="filters">{['PENDING', 'APPROVED', 'REJECTED', 'FAILED'].map((s) => <button key={s} className={`btn btn-sm ${status === s ? 'btn-primary' : ''}`} onClick={() => setStatus(s)}>{s.toLowerCase()}</button>)}</div>
      <DataTable<A> queryKey={['approvals']} path="/approvals" query={{ status }} rowKey={(a) => a.id}
        columns={[
          { key: 'type', header: 'Type', render: (a) => a.type.replace(/_/g, ' ').toLowerCase() },
          { key: 'ref', header: 'Transaction', render: (a) => <a className="mono" href={`/transactions/${a.resourceId}`}>{a.payload.reference}</a> },
          { key: 'amt', header: 'Amount', className: 'num', render: (a) => fmtMoney(a.amount) },
          { key: 'reason', header: 'Reason', render: (a) => a.reason },
          { key: 'at', header: 'Requested', render: (a) => <>{fmtDate(a.createdAt)} {a.mine && <span className="chip">you</span>}</> },
          { key: 'act', header: '', render: (a) => a.status === 'PENDING' ? <div className="row"><button className="btn btn-sm" disabled={a.mine} onClick={() => void decide(a, 'REJECT')}>Reject</button><button className="btn btn-sm btn-danger" disabled={a.mine} onClick={() => void decide(a, 'APPROVE')}>Approve reversal</button></div> : <Badge value={a.status} /> },
        ]} />
    </>
  );
}
