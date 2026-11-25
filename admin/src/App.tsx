import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom';
import { useAuth } from './lib/auth';
import Layout from './components/Layout';
import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
import { UsersPage, UserDetailPage } from './pages/Users';
import KycPage from './pages/Kyc';
import SupportPage from './pages/Support';
import { TransactionsPage, TransactionDetailPage } from './pages/Transactions';
import ApprovalsPage from './pages/Approvals';
import CallbacksPage from './pages/Callbacks';
import ReconciliationPage from './pages/Reconciliation';
import FinancePage from './pages/Finance';
import CampaignsPage from './pages/Campaigns';
import { SecurityPage, AuditPage } from './pages/Security';
import AdminsPage from './pages/Admins';
import AccountPage from './pages/Account';
import type { ReactElement } from 'react';

function Guard({ perm, children }: { perm: string; children: ReactElement }) {
  const { can } = useAuth();
  return can(perm) ? children : <div className="card empty">You do not have access to this page.</div>;
}

export default function App() {
  const { admin, loading, can } = useAuth();
  if (loading) return <div className="empty">Loading…</div>;
  if (!admin) return <Login />;
  if (admin.mustChangePassword) return <div className="main" style={{ maxWidth: 560, margin: '40px auto' }}><AccountPage /></div>;
  const home = can('dashboard.read') ? <Dashboard /> : <Navigate to={can('users.read') ? '/users' : '/account'} replace />;
  return (
    <BrowserRouter>
      <Routes>
        <Route element={<Layout />}>
          <Route index element={home} />
          <Route path="users" element={<Guard perm="users.read"><UsersPage /></Guard>} />
          <Route path="users/:id" element={<Guard perm="users.read"><UserDetailPage /></Guard>} />
          <Route path="kyc" element={<Guard perm="kyc.review"><KycPage /></Guard>} />
          <Route path="support" element={<Guard perm="support.read"><SupportPage /></Guard>} />
          <Route path="transactions" element={<Guard perm="transactions.read"><TransactionsPage /></Guard>} />
          <Route path="transactions/:id" element={<Guard perm="transactions.read"><TransactionDetailPage /></Guard>} />
          <Route path="approvals" element={<Guard perm="transactions.reverse.approve"><ApprovalsPage /></Guard>} />
          <Route path="callbacks" element={<Guard perm="callbacks.read"><CallbacksPage /></Guard>} />
          <Route path="reconciliation" element={<Guard perm="reconciliation.read"><ReconciliationPage /></Guard>} />
          <Route path="finance" element={<Guard perm="finance.read"><FinancePage /></Guard>} />
          <Route path="campaigns" element={<Guard perm="campaigns.read"><CampaignsPage /></Guard>} />
          <Route path="security" element={<Guard perm="security.read"><SecurityPage /></Guard>} />
          <Route path="audit" element={<Guard perm="audit.read"><AuditPage /></Guard>} />
          <Route path="admins" element={<Guard perm="admins.manage"><AdminsPage /></Guard>} />
          <Route path="account" element={<AccountPage />} />
          <Route path="*" element={<div className="card empty">Page not found</div>} />
        </Route>
      </Routes>
    </BrowserRouter>
  );
}
