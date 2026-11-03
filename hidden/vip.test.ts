import { renderInvoice } from '../src/invoices';
import { orderTotals } from '../src/orders';
import { salesReport } from '../src/reports';
import { world } from './helpers';

// every instant is an explicit UTC timestamp; the store is in Mexico City (UTC-6, no DST)
const MAR_4_NOON_LOCAL = Date.UTC(2026, 2, 4, 18, 0, 0);
const LAST_EVENING_LOCAL = Date.UTC(2026, 2, 8, 2, 0, 0); // Mar 7, 20:00 local
const AFTER_WEEK_LOCAL = Date.UTC(2026, 2, 8, 6, 30, 0); // Mar 8, 00:30 local
const FIRST_MINUTE_LOCAL = Date.UTC(2026, 2, 1, 6, 0, 0); // Mar 1, 00:00 local
const BEFORE_WEEK_LOCAL = Date.UTC(2026, 2, 1, 5, 59, 0); // Feb 28, 23:59 local

function goldOrder(id: string, customerId: string, createdAt: number) {
  return { id, customerId, tier: 'gold' as const, status: 'placed' as const, createdAt, lines: [{ sku: 'MUG-1', quantity: 2 }] };
}
const DISCOUNTED = { subtotalCents: 2160, taxCents: 173, shippingCents: 599, totalCents: 2932 };

describe('S2 VIP week (hidden)', () => {
  it('A: the totals of an order do not change when they are asked for again', () => {
    const { catalog, gus } = world();
    const order = goldOrder('o1', gus.id, MAR_4_NOON_LOCAL);
    expect(orderTotals(order, catalog)).toEqual(DISCOUNTED);
    expect(orderTotals(order, catalog)).toEqual(DISCOUNTED);
    expect(orderTotals(order, catalog)).toEqual(DISCOUNTED);
  });
  it('A: a reprinted invoice matches the first one', () => {
    const { catalog, gus } = world();
    const order = goldOrder('o1', gus.id, MAR_4_NOON_LOCAL);
    const first = renderInvoice(order, catalog, gus);
    expect(renderInvoice(order, catalog, gus)).toBe(first);
    expect(first).toContain('Total     $29.32');
  });
  it('A: the sales report counts what the customer was charged', () => {
    const { catalog, gus } = world();
    const order = goldOrder('o1', gus.id, MAR_4_NOON_LOCAL);
    orderTotals(order, catalog); // checkout
    expect(salesReport([order], catalog).revenueCents).toBe(2932);
    expect(salesReport([order], catalog).revenueCents).toBe(2932);
  });
  it('A: the catalog price is never touched by a discount', () => {
    const { catalog, gus } = world();
    orderTotals(goldOrder('o1', gus.id, MAR_4_NOON_LOCAL), catalog);
    expect(catalog.get('MUG-1').priceCents).toBe(1200);
  });
  it('B: the last evening of the week (store time) is still discounted', () => {
    const { catalog, gus } = world();
    expect(orderTotals(goldOrder('o2', gus.id, LAST_EVENING_LOCAL), catalog)).toEqual(DISCOUNTED);
  });
  it('B: the window opens and closes at midnight store time', () => {
    const { catalog, gus } = world();
    expect(orderTotals(goldOrder('o3', gus.id, FIRST_MINUTE_LOCAL), catalog).subtotalCents).toBe(2160);
    expect(orderTotals(goldOrder('o4', gus.id, BEFORE_WEEK_LOCAL), catalog).subtotalCents).toBe(2400);
    expect(orderTotals(goldOrder('o5', gus.id, AFTER_WEEK_LOCAL), catalog).subtotalCents).toBe(2400);
  });
});
