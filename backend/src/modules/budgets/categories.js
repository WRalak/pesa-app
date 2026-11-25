/**
 * Default spending/income categories. Keys are stable identifiers; labels are
 * localised on the client. Users may add custom categories (stored per budget).
 */
export const EXPENSE_CATEGORIES = [
  { key: 'food', label: 'Food & groceries', icon: 'restaurant' },
  { key: 'transport', label: 'Transport', icon: 'directions_bus' },
  { key: 'rent', label: 'Rent & housing', icon: 'home' },
  { key: 'utilities', label: 'Utilities', icon: 'bolt' },
  { key: 'airtime_data', label: 'Airtime & data', icon: 'smartphone' },
  { key: 'education', label: 'Education', icon: 'school' },
  { key: 'health', label: 'Health', icon: 'medical_services' },
  { key: 'entertainment', label: 'Entertainment', icon: 'movie' },
  { key: 'shopping', label: 'Shopping', icon: 'shopping_bag' },
  { key: 'family', label: 'Family & support', icon: 'family_restroom' },
  { key: 'business', label: 'Business', icon: 'storefront' },
  { key: 'savings', label: 'Savings', icon: 'savings' },
  { key: 'fees', label: 'Fees & charges', icon: 'receipt_long' },
  { key: 'transfers', label: 'Transfers', icon: 'swap_horiz' },
  { key: 'uncategorised', label: 'Other', icon: 'category' },
];

export const INCOME_CATEGORIES = [
  { key: 'salary', label: 'Salary', icon: 'payments' },
  { key: 'business_income', label: 'Business income', icon: 'storefront' },
  { key: 'freelance', label: 'Freelance', icon: 'work' },
  { key: 'gifts', label: 'Gifts & support', icon: 'redeem' },
  { key: 'investments', label: 'Investments', icon: 'trending_up' },
  { key: 'other_income', label: 'Other income', icon: 'add_card' },
];

export const EXPENSE_KEYS = EXPENSE_CATEGORIES.map((c) => c.key);
export const INCOME_KEYS = INCOME_CATEGORIES.map((c) => c.key);
