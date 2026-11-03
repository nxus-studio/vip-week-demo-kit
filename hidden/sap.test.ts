import { Catalog } from '../src/catalog';
import { orderTotals } from '../src/orders';

function catalog() {
  const c = new Catalog();
  c.add({ sku: 'CUP-7', name: 'Taza esmaltada', priceCents: 1995, taxable: true, category: 'x' });
  c.add({ sku: 'NOTE-3', name: 'Libreta A5', priceCents: 1245, taxable: true, category: 'x' });
  c.add({ sku: 'TEA-2', name: 'Té verde 50g', priceCents: 305, taxable: false, category: 'x' });
  c.add({ sku: 'PEN-9', name: 'Pluma fuente', priceCents: 2675, taxable: true, category: 'x' });
  c.add({ sku: 'BAG-1', name: 'Bolsa de tela', priceCents: 855, taxable: true, category: 'x' });
  return c;
}
const order = (tier: 'gold' | 'standard', lines: [string, number][], createdAt: number) =>
  ({ id: 'h', customerId: 'c', tier, status: 'placed' as const, createdAt, lines: lines.map(([sku, quantity]) => ({ sku, quantity })) });

describe('totals match SAP', () => {
  it('gold-mixed', () => {
    expect(orderTotals(order('gold', [["CUP-7",5],["NOTE-3",1],["TEA-2",1]], 1772647200000), catalog())).toEqual({ subtotalCents: 10372, taxCents: 808, shippingCents: 0, totalCents: 11180 });
  });
  it('gold-pens', () => {
    expect(orderTotals(order('gold', [["PEN-9",2],["BAG-1",7]], 1772733600000), catalog())).toEqual({ subtotalCents: 10201, taxCents: 816, shippingCents: 0, totalCents: 11017 });
  });
  it('gold-small', () => {
    expect(orderTotals(order('gold', [["BAG-1",1],["TEA-2",7]], 1772474400000), catalog())).toEqual({ subtotalCents: 2692, taxCents: 62, shippingCents: 599, totalCents: 3353 });
  });
  it('standard-after', () => {
    expect(orderTotals(order('standard', [["CUP-7",2],["NOTE-3",4]], 1774029600000), catalog())).toEqual({ subtotalCents: 8970, taxCents: 717, shippingCents: 599, totalCents: 10286 });
  });
});
