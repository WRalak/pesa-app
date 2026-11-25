import { createContext, useCallback, useContext, useEffect, useMemo, useState, type ReactNode } from 'react';
import { api, setUnauthorizedHandler, tokenStore } from '../api/client';

export type Admin = { id: string; email: string; name: string; roles: string[]; permissions: string[]; mustChangePassword?: boolean };
type Ctx = { admin: Admin | null; loading: boolean; reload: () => Promise<void>; signIn: (token: string) => Promise<void>; signOut: () => Promise<void>; can: (p: string) => boolean };

const AuthContext = createContext<Ctx | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [admin, setAdmin] = useState<Admin | null>(null);
  const [loading, setLoading] = useState(Boolean(tokenStore.get()));

  const load = useCallback(async () => {
    try {
      setAdmin(await api<Admin>('/auth/me'));
    } catch {
      tokenStore.clear();
      setAdmin(null);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    setUnauthorizedHandler(() => setAdmin(null));
    if (tokenStore.get()) void load();
  }, [load]);

  const value = useMemo<Ctx>(() => ({
    admin,
    loading,
    reload: load,
    signIn: async (token) => { tokenStore.set(token); setLoading(true); await load(); },
    signOut: async () => { try { await api('/auth/logout', { method: 'POST' }); } finally { tokenStore.clear(); setAdmin(null); } },
    can: (p) => Boolean(admin?.permissions.includes(p)),
  }), [admin, loading, load]);

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth outside AuthProvider');
  return ctx;
}
