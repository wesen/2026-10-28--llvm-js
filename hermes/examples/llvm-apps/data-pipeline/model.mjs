export class InvalidRecord extends Error {
  constructor(index, reason) { super(reason); this.index = index; this.reason = reason; }
}
export function validate(row, index, seen) {
  if (!row || typeof row.id !== 'string' || !/^order-\d+$/.test(row.id))
    throw new InvalidRecord(index, 'id');
  if (seen.has(row.id)) throw new InvalidRecord(index, 'duplicate');
  if (!Number.isSafeInteger(row.cents) || row.cents < 0)
    throw new InvalidRecord(index, 'amount');
  if (!Array.isArray(row.items) || row.items.some(x => !Number.isSafeInteger(x.qty) || x.qty < 1))
    throw new InvalidRecord(index, 'items');
  seen.add(row.id);
  return {...row, customer: row.customer.trim().toLowerCase(),
    units: row.items.reduce((sum, item) => sum + item.qty, 0)};
}
export function summarize(rows) {
  const seen = new Set(), groups = new Map(), rejected = [];
  for (const [index, source] of rows.entries()) {
    let row;
    try { row = validate(source, index, seen); }
    catch (error) {
      if (!(error instanceof InvalidRecord)) throw error;
      rejected.push({index: error.index, reason: error.reason}); continue;
    }
    let group = groups.get(row.region);
    if (!group) { group = {region: row.region, orders: 0, cents: 0, units: 0, customers: new Set()}; groups.set(row.region, group); }
    group.orders++; group.cents += row.cents; group.units += row.units;
    group.customers.add(row.customer);
  }
  const regions = [...groups.values()].map(g => ({region:g.region, orders:g.orders,
    cents:g.cents, units:g.units, customers:g.customers.size})).sort((a,b)=>a.region.localeCompare(b.region));
  return {accepted: seen.size, rejected, totalCents:regions.reduce((n,g)=>n+g.cents,0), regions};
}
