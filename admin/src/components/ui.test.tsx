import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { Badge, ReasonDialog } from './ui';
import { fmtMoney } from '../api/client';

describe('Badge', () => {
  it('renders a humanised status with a tone', () => {
    render(<Badge value="SUCCESSFUL" />);
    const el = screen.getByText('successful');
    expect(el).toHaveClass('b-ok');
  });
});

describe('ReasonDialog', () => {
  it('requires a meaningful reason before confirming', async () => {
    const onConfirm = vi.fn().mockResolvedValue(undefined);
    render(<ReasonDialog title="Suspend" onClose={() => {}} onConfirm={onConfirm} confirmLabel="Suspend" />);
    const btn = screen.getByRole('button', { name: 'Suspend' });
    expect(btn).toBeDisabled();
    await userEvent.type(screen.getByLabelText(/Reason/), 'Fraud investigation');
    expect(btn).toBeEnabled();
    await userEvent.click(btn);
    expect(onConfirm).toHaveBeenCalledWith('Fraud investigation');
  });
});

describe('fmtMoney', () => {
  it('formats minor-unit money objects without float maths', () => {
    expect(fmtMoney({ amountMinor: 150050, currency: 'KES', amount: '1500.50' })).toBe('KES 1,500.50');
    expect(fmtMoney({ amountMinor: 1500, currency: 'UGX', amount: '1500' })).toBe('UGX 1,500');
    expect(fmtMoney(null)).toBe('—');
  });
});
