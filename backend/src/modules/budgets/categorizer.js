/**
 * Deterministic, on-device-equivalent categoriser. Runs locally (no data leaves
 * the platform). Rules are ordered; the first match wins. The AI insights
 * module may later refine categories, but only with user consent.
 */
const RULES = [
  { test: ({ type }) => type === 'AIRTIME', category: 'airtime_data' },
  { test: ({ type, counterparty }) => type === 'UTILITY' && /KPLC|WATER/.test(counterparty?.utilityCode ?? ''), category: 'utilities' },
  { test: ({ type, counterparty }) => type === 'UTILITY' && /DSTV|ZUKU|GOTV|SHOWMAX/.test(counterparty?.utilityCode ?? ''), category: 'entertainment' },
  { test: ({ type }) => type === 'DEPOSIT', category: 'savings' },
  { test: ({ text }) => /\b(naivas|carrefour|quickmart|chandarana|tuskys|magunas|supermarket|grocer|mama mboga|butcher|hotel|restaurant|java|kfc|chicken inn|pizza|cafe)\b/.test(text), category: 'food' },
  { test: ({ text }) => /\b(uber|bolt|little cab|matatu|fare|sacco|fuel|petrol|shell|total ?energies|rubis|parking|sgr|kenya railways)\b/.test(text), category: 'transport' },
  { test: ({ text }) => /\b(rent|landlord|caretaker|apartment|house)\b/.test(text), category: 'rent' },
  { test: ({ text }) => /\b(school|fees|university|college|helb|tuition|kcse|books)\b/.test(text), category: 'education' },
  { test: ({ text }) => /\b(hospital|clinic|pharmacy|chemist|nhif|sha|medical|dental)\b/.test(text), category: 'health' },
  { test: ({ text }) => /\b(safaricom home|zuku|faiba|internet|wifi|data bundle)\b/.test(text), category: 'utilities' },
  { test: ({ text }) => /\b(netflix|showmax|spotify|cinema|betting|sportpesa|odibets|club)\b/.test(text), category: 'entertainment' },
  { test: ({ text }) => /\b(jumia|kilimall|shop|boutique|mall|electronics)\b/.test(text), category: 'shopping' },
  { test: ({ type }) => type === 'SEND_MONEY', category: 'transfers' },
  { test: ({ type }) => type === 'BANK_TRANSFER', category: 'transfers' },
];

export function categorize({ type, description = '', counterparty = {} }) {
  const text = `${description} ${counterparty.name ?? ''} ${counterparty.accountNumber ?? ''}`.toLowerCase();
  for (const rule of RULES) {
    if (rule.test({ type, text, counterparty })) return { category: rule.category, source: 'RULE' };
  }
  return { category: 'uncategorised', source: 'DEFAULT' };
}
