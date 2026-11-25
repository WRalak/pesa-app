import jwt from 'jsonwebtoken';
import { config } from '../../config/env.js';
import { logger } from '../../lib/logger.js';

/**
 * Firebase Cloud Messaging HTTP v1 adapter. Uses the service-account JSON
 * (from Secrets Manager) to mint short-lived OAuth tokens. Disabled unless
 * FCM_ENABLED=true; payloads never contain balances or secrets.
 */
let cachedToken;

async function accessToken(sa) {
  if (cachedToken && cachedToken.exp > Date.now() + 60_000) return cachedToken.value;
  const now = Math.floor(Date.now() / 1000);
  const assertion = jwt.sign({
    iss: sa.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  }, sa.private_key, { algorithm: 'RS256' });
  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({ grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer', assertion }),
    signal: AbortSignal.timeout(10_000),
  });
  if (!res.ok) throw new Error(`FCM auth failed ${res.status}`);
  const body = await res.json();
  cachedToken = { value: body.access_token, exp: Date.now() + body.expires_in * 1000 };
  return cachedToken.value;
}

/** Returns 'SENT' | 'INVALID_TOKEN' | 'SKIPPED'. */
export async function sendPush(token, { title, body, data }) {
  if (!config.FCM_ENABLED || !config.FCM_SERVICE_ACCOUNT_JSON) return 'SKIPPED';
  const sa = JSON.parse(config.FCM_SERVICE_ACCOUNT_JSON);
  const res = await fetch(`https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${await accessToken(sa)}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({
      message: {
        token,
        notification: { title, body },
        data: Object.fromEntries(Object.entries(data ?? {}).map(([k, v]) => [k, String(v)])),
        android: { priority: 'high', notification: { channel_id: 'pesa_default' } },
      },
    }),
    signal: AbortSignal.timeout(10_000),
  });
  if (res.status === 404 || res.status === 400) return 'INVALID_TOKEN';
  if (!res.ok) {
    logger.warn({ status: res.status }, 'FCM send failed');
    throw new Error(`FCM send failed ${res.status}`);
  }
  return 'SENT';
}
