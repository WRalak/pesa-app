/**
 * Thin fetch wrapper for the admin API. The short-lived (30 min), MFA-backed
 * token lives in sessionStorage (cleared when the tab closes); the CSP served
 * with this app forbids inline/third-party scripts to limit XSS exposure.
 */
export type Money = { amountMinor: number; currency: string; amount: string };
export type Page<T> = { items: T[]; nextCursor: string | null; hasMore: boolean };

export class ApiError extends Error {
  constructor(public status: number, public code: string, message: string, public details?: unknown) {
    super(message);
  }
}

const TOKEN_KEY = 'pesa.admin.token';
let onUnauthorized: (() => void) | null = null;

export const tokenStore = {
  get: () => sessionStorage.getItem(TOKEN_KEY),
  set: (t: string) => sessionStorage.setItem(TOKEN_KEY, t),
  clear: () => sessionStorage.removeItem(TOKEN_KEY),
};

export function setUnauthorizedHandler(fn: () => void) {
  onUnauthorized = fn;
}

const BASE = (import.meta.env.VITE_API_BASE_URL as string | undefined) ?? '';

export async function api<T>(path: string, init: { method?: string; body?: unknown; query?: Record<string, unknown> } = {}): Promise<T> {
  const url = new URL(`${BASE}/admin/v1${path}`, window.location.origin);
  for (const [k, v] of Object.entries(init.query ?? {})) {
    if (v !== undefined && v !== null && v !== '') url.searchParams.set(k, String(v));
  }
  const headers: Record<string, string> = { Accept: 'application/json' };
  const token = tokenStore.get();
  if (token) headers.Authorization = `Bearer ${token}`;
  if (init.body !== undefined) headers['Content-Type'] = 'application/json';
  const res = await fetch(url, { method: init.method ?? 'GET', headers, body: init.body !== undefined ? JSON.stringify(init.body) : undefined });
  if (res.status === 204) return undefined as T;
  const data = await res.json().catch(() => ({}));
  if (!res.ok) {
    const err = data?.error ?? {};
    if (res.status === 401 && token) {
      tokenStore.clear();
      onUnauthorized?.();
    }
    throw new ApiError(res.status, err.code ?? 'ERROR', err.message ?? 'Request failed', err.details);
  }
  return data as T;
}

export const fmtMoney = (m?: Money | null) =>
  m ? `${m.currency} ${Number(m.amount).toLocaleString('en-KE', { minimumFractionDigits: m.amount.includes('.') ? 2 : 0, maximumFractionDigits: 2 })}` : '—';

export const fmtDate = (d?: string | null) =>
  d ? new Intl.DateTimeFormat('en-KE', { dateStyle: 'medium', timeStyle: 'short', timeZone: 'Africa/Nairobi' }).format(new Date(d)) : '—';
