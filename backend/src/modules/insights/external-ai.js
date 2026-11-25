import Anthropic from '@anthropic-ai/sdk';
import { zodOutputFormat } from '@anthropic-ai/sdk/helpers/zod';
import { z } from 'zod/v4';
import { config } from '../../config/env.js';
import { logger } from '../../lib/logger.js';

/**
 * OPTIONAL external narrative generation with Claude.
 *
 * Safeguards (privacy-by-design):
 *  - Disabled unless AI_EXTERNAL_PROVIDER=anthropic and an API key is set.
 *  - Called only for users who gave explicit `externalAiProcessing` consent.
 *  - Receives ONLY aggregated, de-identified figures (category totals and
 *    averages). No names, phone numbers, references, merchants or free text.
 *  - Output is advisory text; the model has no tools and cannot act.
 */
const NarrativeSchema = z.object({
  summary: z.string(),
  tips: z.array(z.string()),
});

let client;
function getClient() {
  client ??= new Anthropic({ apiKey: config.AI_API_KEY, timeout: 30_000, maxRetries: 2 });
  return client;
}

export function externalAiAvailable() {
  return config.AI_EXTERNAL_PROVIDER === 'anthropic' && Boolean(config.AI_API_KEY);
}

/** Builds the de-identified payload. Exported for tests that assert no PII leaks. */
export function buildAggregatePayload({ currency, month, incomeMinor, expenseMinor, byCategory, avgByCategory }, minorUnits) {
  const toUnits = (m) => Math.round(m / 10 ** minorUnits);
  return {
    currency,
    month,
    income: toUnits(incomeMinor),
    spending: toUnits(expenseMinor),
    categories: Object.fromEntries(Object.entries(byCategory).map(([k, v]) => [k, toUnits(v)])),
    threeMonthAverages: Object.fromEntries(Object.entries(avgByCategory ?? {}).map(([k, v]) => [k, toUnits(v)])),
  };
}

export async function generateNarrative(payload, locale = 'en-KE') {
  const language = locale.startsWith('sw') ? 'Swahili' : 'English';
  const response = await getClient().beta.messages.create({
    model: 'claude-opus-5-5',
    max_tokens: 2000,
    betas: ['server-side-fallback-2026-07-01'],
    fallbacks: 'default',
    output_config: { effort: 'low', format: zodOutputFormat(NarrativeSchema) },
    system: `You write short, friendly monthly money summaries for a personal finance app used in East Africa. Write in ${language}. Use only the figures provided. Do not give investment, credit or legal advice and do not recommend specific financial products. Keep the summary under 80 words and give at most 3 practical budgeting tips.`,
    messages: [{ role: 'user', content: `Aggregated monthly figures (whole currency units):\n${JSON.stringify(payload)}` }],
  });
  if (response.stop_reason === 'refusal' || response.stop_reason === 'max_tokens') {
    logger.warn({ stopReason: response.stop_reason }, 'AI narrative not produced');
    return null;
  }
  const text = response.content.find((b) => b.type === 'text')?.text;
  if (!text) return null;
  const parsed = NarrativeSchema.safeParse(JSON.parse(text));
  return parsed.success ? parsed.data : null;
}
