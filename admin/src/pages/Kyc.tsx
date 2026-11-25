import { useState } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import { api, fmtDate } from '../api/client';
import { Badge, DataTable, ErrorBox, Modal, PageHead } from '../components/ui';
import { useAuth } from '../lib/auth';

type K = { id: string; userId: string; idType: string; idNumberLast4: string; fullName: string; dateOfBirth: string; documents: number; status: string; submittedAt: string };

export default function KycPage() {
  const qc = useQueryClient();
  const { can } = useAuth();
  const [status, setStatus] = useState('PENDING');
  const [open, setOpen] = useState<K | null>(null);
  const [tier, setTier] = useState('TIER_1');
  const [reason, setReason] = useState('');
  const [revealed, setRevealed] = useState<string | null>(null);
  const [error, setError] = useState<unknown>(null);
  const decide = async (decision: 'APPROVE' | 'REJECT') => {
    setError(null);
    try {
      await api(`/kyc/${open!.id}/decision`, { method: 'POST', body: { decision, tier, reason: reason || undefined } });
      setOpen(null); setReason(''); setRevealed(null);
      await qc.invalidateQueries({ queryKey: ['kyc'] });
    } catch (e) { setError(e); }
  };
  return (
    <>
      <PageHead title="KYC review" subtitle="Verify identity submissions. Decisions are audited and notify the customer." />
      <div className="filters">
        {['PENDING', 'VERIFIED', 'REJECTED'].map((s) => <button key={s} className={`btn btn-sm ${status === s ? 'btn-primary' : ''}`} onClick={() => setStatus(s)}>{s.toLowerCase()}</button>)}
      </div>
      <DataTable<K> queryKey={['kyc']} path="/kyc" query={{ status }} rowKey={(k) => k.id} onRowClick={(k) => { setOpen(k); setRevealed(null); }}
        columns={[
          { key: 'name', header: 'Full name', render: (k) => <strong>{k.fullName}</strong> },
          { key: 'id', header: 'Document', render: (k) => `${k.idType.replace('_', ' ')} ••${k.idNumberLast4}` },
          { key: 'dob', header: 'Date of birth', render: (k) => new Date(k.dateOfBirth).toLocaleDateString('en-KE') },
          { key: 'docs', header: 'Files', render: (k) => k.documents },
          { key: 'status', header: 'Status', render: (k) => <Badge value={k.status} /> },
          { key: 'at', header: 'Submitted', render: (k) => fmtDate(k.submittedAt) },
        ]} />
      {open && (
        <Modal title={`Review: ${open.fullName}`} onClose={() => setOpen(null)}>
          <ErrorBox error={error} />
          <dl className="dl" style={{ marginBottom: 16 }}>
            <dt>Document</dt><dd>{open.idType.replace('_', ' ')} {revealed ? <span className="mono">{revealed}</span> : <>••{open.idNumberLast4} {can('users.pii.read') && <button className="btn btn-sm" onClick={async () => setRevealed((await api<{ idNumber: string }>(`/kyc/${open.id}/id-number`)).idNumber)}>Reveal (audited)</button>}</>}</dd>
            <dt>Date of birth</dt><dd>{new Date(open.dateOfBirth).toLocaleDateString('en-KE')}</dd>
            <dt>User</dt><dd><a href={`/users/${open.userId}`}>Open profile</a></dd>
          </dl>
          {open.status === 'PENDING' ? (
            <>
              <div className="field"><label htmlFor="tier">Tier to grant on approval</label><select id="tier" className="input" value={tier} onChange={(e) => setTier(e.target.value)}><option>TIER_1</option><option>TIER_2</option></select></div>
              <div className="field"><label htmlFor="r">Rejection reason (shown to the customer)</label><input id="r" className="input" value={reason} onChange={(e) => setReason(e.target.value)} placeholder="e.g. Photo of ID is unreadable" /></div>
              <div className="row"><span className="spacer" /><button className="btn btn-danger" disabled={reason.length < 3} onClick={() => void decide('REJECT')}>Reject</button><button className="btn btn-primary" onClick={() => void decide('APPROVE')}>Approve</button></div>
            </>
          ) : <Badge value={open.status} />}
        </Modal>
      )}
    </>
  );
}
