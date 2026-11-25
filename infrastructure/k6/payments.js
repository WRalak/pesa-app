/**
 * Load test (sandbox only — uses the mock provider, never real money).
 *
 *   k6 run -e BASE_URL=https://staging-api.example.com -e TOKENS_FILE=tokens.json infrastructure/k6/payments.js
 *
 * TOKENS_FILE: JSON array of {accessToken, pin} for pre-seeded TIER_1 test users
 * (see scripts in docs/TESTING.md). Thresholds encode the performance budget.
 */
import http from 'k6/http';
import { check, sleep } from 'k6';
import { SharedArray } from 'k6/data';
import { uuidv4 } from 'https://jslib.k6.io/k6-utils/1.4.0/index.js';

const BASE = __ENV.BASE_URL || 'http://localhost:4000';
const users = new SharedArray('users', () => JSON.parse(open(__ENV.TOKENS_FILE || './tokens.json')));

export const options = {
  scenarios: {
    browse: { executor: 'ramping-vus', exec: 'browse', startVUs: 0, stages: [{ duration: '1m', target: 200 }, { duration: '3m', target: 200 }, { duration: '30s', target: 0 }] },
    pay: { executor: 'constant-arrival-rate', exec: 'pay', rate: 30, timeUnit: '1s', duration: '4m', preAllocatedVUs: 60 },
  },
  thresholds: {
    'http_req_failed{scenario:browse}': ['rate<0.01'],
    'http_req_duration{name:dashboard}': ['p(95)<400'],
    'http_req_duration{name:transactions}': ['p(95)<300'],
    'http_req_duration{name:pay}': ['p(95)<800'],
  },
};

const auth = (u) => ({ headers: { Authorization: `Bearer ${u.accessToken}`, 'Content-Type': 'application/json' } });

export function browse() {
  const u = users[__VU % users.length];
  check(http.get(`${BASE}/v1/dashboard`, { ...auth(u), tags: { name: 'dashboard' } }), { 'dashboard 200': (r) => r.status === 200 });
  check(http.get(`${BASE}/v1/transactions?limit=20`, { ...auth(u), tags: { name: 'transactions' } }), { 'list 200': (r) => r.status === 200 });
  sleep(1);
}

export function pay() {
  const u = users[Math.floor(Math.random() * users.length)];
  const params = auth(u);
  params.headers['Idempotency-Key'] = uuidv4();
  params.tags = { name: 'pay' };
  const body = JSON.stringify({ type: 'AIRTIME', amount: `${10 + Math.floor(Math.random() * 90)}`, pin: u.pin, confirmDuplicate: true });
  check(http.post(`${BASE}/v1/payments`, body, params), { 'accepted': (r) => r.status === 202 || r.status === 429 });
}
