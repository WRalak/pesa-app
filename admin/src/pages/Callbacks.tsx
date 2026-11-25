import { useState } from 'react';
import { fmtDate } from '../api/client';
import { Badge, DataTable, PageHead } from '../components/ui';

type C = { id: string; provider: string; outcome: string | null; processingStatus: string; note: string | null; signatureValid: boolean; sourceIp: string; transactionId: string | null; providerRequestId: string | null; receivedAt: string };

export default function CallbacksPage() {
  const [status, setStatus] = useState('');
  return (
    <>
      <PageHead title="Provider callbacks" subtitle="Every webhook received, verified and deduplicated. Rejected callbacks indicate spoofing attempts." />
      <div className="filters">{['', 'APPLIED', 'DUPLICATE', 'ORPHANED', 'REJECTED', 'IGNORED', 'ERROR'].map((s) => <button key={s} className={`btn btn-sm ${status === s ? 'btn-primary' : ''}`} onClick={() => setStatus(s)}>{s ? s.toLowerCase() : 'all'}</button>)}</div>
      <DataTable<C> queryKey={['callbacks']} path="/callbacks" query={{ processingStatus: status }} rowKey={(c) => c.id}
        columns={[
          { key: 'at', header: 'Received', render: (c) => fmtDate(c.receivedAt) },
          { key: 'p', header: 'Provider', render: (c) => c.provider },
          { key: 'o', header: 'Outcome', render: (c) => c.outcome ?? '—' },
          { key: 's', header: 'Processing', render: (c) => <><Badge value={c.processingStatus} /> <span className="faint">{c.note}</span></> },
          { key: 'sig', header: 'Verified', render: (c) => (c.signatureValid ? 'yes' : <Badge value="REJECTED" />) },
          { key: 'ip', header: 'Source IP', render: (c) => <span className="mono">{c.sourceIp}</span> },
          { key: 't', header: 'Transaction', render: (c) => (c.transactionId ? <a href={`/transactions/${c.transactionId}`}>open</a> : <span className="mono faint">{c.providerRequestId}</span>) },
        ]} />
    </>
  );
}
