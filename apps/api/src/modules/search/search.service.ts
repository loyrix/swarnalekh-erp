import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service.js';
import { SearchQueryDto } from './search.dto.js';

/** A single cross-entity search hit. `score` is used only for ordering. */
export interface CustomerHit {
  id: string;
  name: string;
  phone: string | null;
  city: string | null;
  score: number;
}

export interface InventoryHit {
  id: string;
  tagNumber: string | null;
  itemName: string | null;
  category: string | null;
  metalType: string;
  status: string;
  sellingPrice: number | null;
  score: number;
}

export interface InvoiceHit {
  id: string;
  invoiceNumber: string;
  customerName: string | null;
  invoiceDate: string;
  grandTotal: number;
  balanceDue: number;
  score: number;
}

export interface SearchResults {
  query: string;
  customers: CustomerHit[];
  inventory: InventoryHit[];
  invoices: InvoiceHit[];
  total: number;
}

const DEFAULT_LIMIT = 5;
/** Rows pulled per entity before JS ranking trims to `limit`. */
const FETCH_MULTIPLIER = 4;

@Injectable()
export class SearchService {
  constructor(private readonly prisma: PrismaService) {}

  async search(
    tenantId: string,
    query: SearchQueryDto,
  ): Promise<SearchResults> {
    const term = (query.q ?? '').trim();
    const limit = query.limit ?? DEFAULT_LIMIT;
    if (term.length === 0) {
      return {
        query: '',
        customers: [],
        inventory: [],
        invoices: [],
        total: 0,
      };
    }

    const fetchTake = limit * FETCH_MULTIPLIER;
    const [customers, inventory, invoices] = await Promise.all([
      this.searchCustomers(tenantId, term, fetchTake),
      this.searchInventory(tenantId, term, fetchTake),
      this.searchInvoices(tenantId, term, fetchTake),
    ]);

    const trimmedCustomers = this.rank(customers).slice(0, limit);
    const trimmedInventory = this.rank(inventory).slice(0, limit);
    const trimmedInvoices = this.rank(invoices).slice(0, limit);

    return {
      query: term,
      customers: trimmedCustomers,
      inventory: trimmedInventory,
      invoices: trimmedInvoices,
      total:
        trimmedCustomers.length +
        trimmedInventory.length +
        trimmedInvoices.length,
    };
  }

  private async searchCustomers(
    tenantId: string,
    term: string,
    take: number,
  ): Promise<CustomerHit[]> {
    const rows = await this.prisma.customer.findMany({
      where: {
        tenantId,
        deletedAt: null,
        OR: [
          { name: { contains: term, mode: 'insensitive' } },
          { phone: { contains: term } },
          { altPhone: { contains: term } },
          { email: { contains: term, mode: 'insensitive' } },
          { city: { contains: term, mode: 'insensitive' } },
        ],
      },
      take,
    });
    return rows.map((c) => ({
      id: c.id,
      name: c.name,
      phone: c.phone ?? null,
      city: c.city ?? null,
      score: Math.max(
        this.scoreField(term, c.phone, 3),
        this.scoreField(term, c.altPhone, 3),
        this.scoreField(term, c.name, 2),
        this.scoreField(term, c.email, 1),
        this.scoreField(term, c.city, 1),
      ),
    }));
  }

  private async searchInventory(
    tenantId: string,
    term: string,
    take: number,
  ): Promise<InventoryHit[]> {
    const rows = await this.prisma.inventoryItem.findMany({
      where: {
        tenantId,
        deletedAt: null,
        OR: [
          { tagNumber: { contains: term, mode: 'insensitive' } },
          { barcode: { contains: term, mode: 'insensitive' } },
          { itemName: { contains: term, mode: 'insensitive' } },
          { hallmarkNumber: { contains: term, mode: 'insensitive' } },
          { huid: { contains: term, mode: 'insensitive' } },
        ],
      },
      include: { category: { select: { name: true } } },
      take,
    });
    return rows.map((item) => ({
      id: item.id,
      tagNumber: item.tagNumber ?? null,
      itemName: item.itemName ?? null,
      category: item.category?.name ?? null,
      metalType: item.metalType,
      status: item.status,
      sellingPrice: this.toNumber(item.sellingPrice),
      score: Math.max(
        this.scoreField(term, item.tagNumber, 3),
        this.scoreField(term, item.barcode, 3),
        this.scoreField(term, item.hallmarkNumber, 3),
        this.scoreField(term, item.huid, 3),
        this.scoreField(term, item.itemName, 2),
      ),
    }));
  }

  private async searchInvoices(
    tenantId: string,
    term: string,
    take: number,
  ): Promise<InvoiceHit[]> {
    const rows = await this.prisma.invoice.findMany({
      where: {
        tenantId,
        deletedAt: null,
        OR: [
          { invoiceNumber: { contains: term, mode: 'insensitive' } },
          { customerName: { contains: term, mode: 'insensitive' } },
          { customerPhone: { contains: term } },
        ],
      },
      take,
    });
    return rows.map((inv) => ({
      id: inv.id,
      invoiceNumber: inv.invoiceNumber,
      customerName: inv.customerName ?? null,
      invoiceDate: inv.invoiceDate.toISOString().slice(0, 10),
      grandTotal: this.toNumber(inv.grandTotal) ?? 0,
      balanceDue: this.toNumber(inv.balanceDue) ?? 0,
      score: Math.max(
        this.scoreField(term, inv.invoiceNumber, 3),
        this.scoreField(term, inv.customerPhone, 3),
        this.scoreField(term, inv.customerName, 2),
      ),
    }));
  }

  /** Higher score = better match: exact ×3, prefix ×2, substring ×1 of weight. */
  private scoreField(
    term: string,
    value: string | null | undefined,
    weight: number,
  ): number {
    if (!value) return 0;
    const v = value.toLowerCase();
    const t = term.toLowerCase();
    if (v === t) return weight * 3;
    if (v.startsWith(t)) return weight * 2;
    if (v.includes(t)) return weight * 1;
    return 0;
  }

  private rank<T extends { score: number }>(hits: T[]): T[] {
    return [...hits].sort((a, b) => b.score - a.score);
  }

  private toNumber(value: unknown): number | null {
    if (value == null) return null;
    if (typeof value === 'number') return value;
    if (
      typeof value === 'object' &&
      'toNumber' in value &&
      typeof (value as { toNumber: () => number }).toNumber === 'function'
    ) {
      return (value as { toNumber: () => number }).toNumber();
    }
    const n = Number(value);
    return Number.isNaN(n) ? null : n;
  }
}
