import { useState, type ReactNode } from 'react';
import { useInfiniteQuery } from '@tanstack/react-query';
import { api, ApiError, type Page } from '../api/client';

const STATUS_TONE: Record<string, string> = {
  SUCCESSFUL: 'b-ok', ACTIVE: 'b-ok', VERIFIED: 'b-ok', APPLIED: 'b-ok', MATCHED: 'b-ok', AUTO_RESOLVED: 'b-ok', RESOLVED: 'b-ok', APPROVED: 'b-ok', REWARDED: 'b-ok', SENT: 'b-ok', ok: 'b-ok',
  PENDING: 'b-warn', PROCESSING: 'b-warn', INITIATED: 'b-warn', PENDING_VERIFICATION: 'b-warn', OPEN: 'b-warn', IN_PROGRESS: 'b-warn', DRAFT: 'b-neutral', PAUSED: 'b-neutral', SCHEDULED: 'b-info', QUALIFIED: 'b-info', MEDIUM: 'b-warn', AWAITING_USER: 'b-info',
  FAILED: 'b-danger', REVERSED: 'b-info', SUSPENDED: 'b-danger', REJECTED: 'b-danger', ERROR: 'b-danger', HIGH: 'b-danger', CRITICAL: 'b-danger', STATUS_MISMATCH: 'b-danger', AMOUNT_MISMATCH: 'b-danger', MISSING_INTERNAL: 'b-danger', MISSING_AT_PROVIDER: 'b-danger', ORPHANED: 'b-warn', ESCALATED: 'b-danger', DISABLED: 'b-danger', down: 'b-danger',
  CLOSED: 'b-neutral', ENDED: 'b-neutral', LOW: 'b-neutral', DUPLICATE: 'b-neutral', IGNORED: 'b-neutral', NOT_REQUIRED: 'b-neutral', NOT_STARTED: 'b-neutral',
};

export function Badge({ value }: { value?: string | null }) {
  if (!value) return <span className="faint">—</span>;
  return <span className={`badge ${STATUS_TONE[value] ?? 'b-neutral'}`}>{value.replace(/_/g, ' ').toLowerCase()}</span>;
}

export function PageHead({ title, subtitle, actions }: { title: string; subtitle?: string; actions?: ReactNode }) {
  return (
    <div className="page-head">
      <div><h1>{title}</h1>{subtitle && <p>{subtitle}</p>}</div>
      {actions && <div className="row">{actions}</div>}
    </div>
  );
}

export function ErrorBox({ error }: { error: unknown }) {
  if (!error) return null;
  const msg = error instanceof ApiError ? error.message : 'Something went wrong';
  return <div className="alert alert-error" role="alert">{msg}</div>;
}

export function Modal({ title, onClose, children }: { title: string; onClose: () => void; children: ReactNode }) {
  return (
    <div className="modal-backdrop" onClick={onClose} role="presentation">
      <div className="modal" role="dialog" aria-modal="true" aria-label={title} onClick={(e) => e.stopPropagation()}>
        <h2>{title}</h2>
        {children}
      </div>
    </div>
  );
}

/** Every privileged action asks for a reason that is written to the audit log. */
export function ReasonDialog({ title, description, confirmLabel = 'Confirm', danger, onClose, onConfirm, extra }: {
  title: string; description?: string; confirmLabel?: string; danger?: boolean; onClose: () => void;
  onConfirm: (reason: string) => Promise<unknown>; extra?: ReactNode;
}) {
  const [reason, setReason] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<unknown>(null);
  return (
    <Modal title={title} onClose={onClose}>
      {description && <p className="muted">{description}</p>}
      <ErrorBox error={error} />
      {extra}
      <div className="field">
        <label htmlFor="reason">Reason (recorded in the audit log)</label>
        <textarea id="reason" className="input" rows={3} value={reason} onChange={(e) => setReason(e.target.value)} />
      </div>
      <div className="row">
        <span className="spacer" />
        <button className="btn" onClick={onClose}>Cancel</button>
        <button className={`btn ${danger ? 'btn-danger' : 'btn-primary'}`} disabled={reason.trim().length < 5 || busy}
          onClick={async () => { setBusy(true); setError(null); try { await onConfirm(reason.trim()); onClose(); } catch (e) { setError(e); } finally { setBusy(false); } }}>
          {busy ? 'Working…' : confirmLabel}
        </button>
      </div>
    </Modal>
  );
}

export type Column<T> = { key: string; header: string; render: (row: T) => ReactNode; className?: string };

/** Cursor-paginated table backed by the API's `nextCursor`. */
export function DataTable<T>({ queryKey, path, query, columns, onRowClick, empty = 'Nothing here yet', rowKey }: {
  queryKey: unknown[]; path: string; query?: Record<string, unknown>; columns: Column<T>[]; onRowClick?: (row: T) => void; empty?: string; rowKey: (row: T) => string;
}) {
  const q = useInfiniteQuery({
    queryKey: [...queryKey, query],
    queryFn: ({ pageParam }) => api<Page<T>>(path, { query: { ...query, cursor: pageParam, limit: 25 } }),
    initialPageParam: undefined as string | undefined,
    getNextPageParam: (last) => last.nextCursor ?? undefined,
  });
  const rows = q.data?.pages.flatMap((p) => p.items) ?? [];
  return (
    <div className="card">
      <ErrorBox error={q.error} />
      <div className="table-wrap">
        <table>
          <thead><tr>{columns.map((c) => <th key={c.key} className={c.className}>{c.header}</th>)}</tr></thead>
          <tbody>
            {rows.map((r) => (
              <tr key={rowKey(r)} className={onRowClick ? 'clickable' : undefined} onClick={onRowClick ? () => onRowClick(r) : undefined}>
                {columns.map((c) => <td key={c.key} className={c.className}>{c.render(r)}</td>)}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      {q.isLoading && <div className="empty">Loading…</div>}
      {!q.isLoading && rows.length === 0 && <div className="empty">{empty}</div>}
      {q.hasNextPage && <div className="pager"><button className="btn btn-sm" disabled={q.isFetchingNextPage} onClick={() => q.fetchNextPage()}>{q.isFetchingNextPage ? 'Loading…' : 'Load more'}</button></div>}
    </div>
  );
}

export function Kpi({ label, value, sub, accent }: { label: string; value: ReactNode; sub?: ReactNode; accent?: boolean }) {
  return <div className={`card kpi${accent ? ' accent' : ''}`}><div className="label">{label}</div><div className="value">{value}</div>{sub && <div className="sub">{sub}</div>}</div>;
}
