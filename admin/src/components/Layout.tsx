import { NavLink, Outlet } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { useAuth } from '../lib/auth';
import { api } from '../api/client';

type Item = { to: string; label: string; perm: string; icon: string; badge?: number };

export default function Layout() {
  const { admin, can, signOut } = useAuth();
  const dash = useQuery({ queryKey: ['dashboard'], queryFn: () => api<{ alerts: { fraudAndSecurity: number; pendingApprovals: number; reconciliationExceptions: number } }>('/dashboard'), enabled: can('dashboard.read'), refetchInterval: 60_000 });
  const alerts = dash.data?.alerts;
  const groups: [string, Item[]][] = [
    ['Overview', [{ to: '/', label: 'Dashboard', perm: 'dashboard.read', icon: '◧' }]],
    ['Customers', [
      { to: '/users', label: 'Users', perm: 'users.read', icon: '◉' },
      { to: '/kyc', label: 'KYC review', perm: 'kyc.review', icon: '◈' },
      { to: '/support', label: 'Support', perm: 'support.read', icon: '✉' },
    ]],
    ['Money', [
      { to: '/transactions', label: 'Transactions', perm: 'transactions.read', icon: '⇄' },
      { to: '/approvals', label: 'Approvals', perm: 'transactions.reverse.approve', icon: '✓', badge: alerts?.pendingApprovals },
      { to: '/callbacks', label: 'Provider callbacks', perm: 'callbacks.read', icon: '↯' },
      { to: '/reconciliation', label: 'Reconciliation', perm: 'reconciliation.read', icon: '≡', badge: alerts?.reconciliationExceptions },
      { to: '/finance', label: 'Finance & providers', perm: 'finance.read', icon: '◔' },
    ]],
    ['Growth', [
      { to: '/campaigns', label: 'Campaigns', perm: 'campaigns.read', icon: '★' },
    ]],
    ['Security', [
      { to: '/security', label: 'Security events', perm: 'security.read', icon: '⚑', badge: alerts?.fraudAndSecurity },
      { to: '/audit', label: 'Audit log', perm: 'audit.read', icon: '⌘' },
      { to: '/admins', label: 'Administrators', perm: 'admins.manage', icon: '⚙' },
    ]],
  ];
  return (
    <div className="shell">
      <aside className="sidebar" aria-label="Main navigation">
        <div className="brand"><img src="/favicon.svg" width={30} height={30} alt="" /><div>Pesa<small>Operations</small></div></div>
        {groups.map(([group, items]) => {
          const visible = items.filter((i) => can(i.perm));
          if (!visible.length) return null;
          return (
            <div key={group}>
              <div className="nav-group">{group}</div>
              {visible.map((i) => (
                <NavLink key={i.to} to={i.to} end={i.to === '/'} className={({ isActive }) => `nav-link${isActive ? ' active' : ''}`}>
                  <span aria-hidden>{i.icon}</span>{i.label}{i.badge ? <span className="nav-badge">{i.badge}</span> : null}
                </NavLink>
              ))}
            </div>
          );
        })}
        <div className="sidebar-foot">
          <div style={{ color: '#fff', fontWeight: 600 }}>{admin?.name}</div>
          <div>{admin?.roles.map((r) => r.replace(/_/g, ' ').toLowerCase()).join(', ')}</div>
          <div className="row" style={{ marginTop: 8 }}>
            <NavLink to="/account" className="nav-link" style={{ padding: '4px 0' }}>Account</NavLink>
            <span className="spacer" />
            <button className="btn btn-sm" onClick={() => void signOut()}>Sign out</button>
          </div>
        </div>
      </aside>
      <main className="main"><Outlet /></main>
    </div>
  );
}
