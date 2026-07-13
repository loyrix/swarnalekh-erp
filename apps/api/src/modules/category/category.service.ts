import {
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service.js';
import { CreateCategoryDto, UpdateCategoryDto } from './category.dto.js';

/// Master list of Indian gold-ornament categories seeded for every shop.
/// Prefixes drive tag numbers (RG-01, CN-01, …) and are unique per tenant.
export const DEFAULT_CATEGORIES: ReadonlyArray<{
  name: string;
  prefix: string;
}> = [
  { name: 'Ring', prefix: 'RG' },
  { name: 'Chain', prefix: 'CN' },
  { name: 'Mangalsutra', prefix: 'MS' },
  { name: 'Necklace', prefix: 'NK' },
  { name: 'Bangle', prefix: 'BG' },
  { name: 'Bracelet', prefix: 'BR' },
  { name: 'Earrings', prefix: 'ER' },
  { name: 'Pendant', prefix: 'PD' },
  { name: 'Anklet (Payal)', prefix: 'AK' },
  { name: 'Nose Pin (Nath)', prefix: 'NP' },
  { name: 'Kada', prefix: 'KD' },
  { name: 'Haar', prefix: 'HR' },
  { name: 'Maang Tikka', prefix: 'MT' },
  { name: 'Toe Ring (Bichhiya)', prefix: 'TR' },
  { name: 'Coin', prefix: 'CO' },
  { name: 'Locket', prefix: 'LK' },
  { name: 'Studs', prefix: 'SD' },
  { name: 'Choker', prefix: 'CK' },
  { name: 'Waist Chain (Kamarbandh)', prefix: 'WC' },
  { name: 'Armlet (Bajubandh)', prefix: 'AR' },
];

@Injectable()
export class CategoryService {
  constructor(private readonly prisma: PrismaService) {}

  /// Lists the tenant's categories, lazily seeding the default master list
  /// for new shops and backfilling prefixes onto legacy free-text categories
  /// so every category can generate tags.
  async list(tenantId: string) {
    await this.ensureSeeded(tenantId);

    const [categories, inStockCounts, totalCounts] = await Promise.all([
      this.prisma.category.findMany({
        where: { tenantId },
        orderBy: { name: 'asc' },
      }),
      this.prisma.inventoryItem.groupBy({
        by: ['categoryId'],
        where: { tenantId, deletedAt: null, status: 'in_stock' },
        _count: { _all: true },
      }),
      this.prisma.inventoryItem.groupBy({
        by: ['categoryId'],
        where: { tenantId, deletedAt: null },
        _count: { _all: true },
      }),
    ]);

    const inStockByCategory = new Map(
      inStockCounts.map((row) => [row.categoryId, row._count._all]),
    );
    const totalByCategory = new Map(
      totalCounts.map((row) => [row.categoryId, row._count._all]),
    );

    return categories.map((category) => ({
      id: category.id,
      name: category.name,
      prefix: category.prefix,
      minStockThreshold: category.minStockThreshold,
      active: category.active,
      inStockCount: inStockByCategory.get(category.id) ?? 0,
      itemCount: totalByCategory.get(category.id) ?? 0,
    }));
  }

  async create(tenantId: string, dto: CreateCategoryDto) {
    const name = dto.name.trim();
    if (!name) throw new ConflictException('Category name is required');

    const duplicate = await this.prisma.category.findFirst({
      where: { tenantId, name: { equals: name, mode: 'insensitive' } },
      select: { id: true },
    });
    if (duplicate) {
      throw new ConflictException(`Category "${name}" already exists`);
    }

    const prefix = dto.prefix ?? (await this.derivePrefix(tenantId, name));
    await this.assertPrefixFree(tenantId, prefix);

    return this.prisma.category.create({
      data: {
        tenantId,
        name,
        prefix,
        minStockThreshold: dto.minStockThreshold ?? 0,
      },
    });
  }

  async update(tenantId: string, id: string, dto: UpdateCategoryDto) {
    const category = await this.prisma.category.findFirst({
      where: { id, tenantId },
    });
    if (!category) throw new NotFoundException('Category not found');

    if (dto.prefix && dto.prefix !== category.prefix) {
      await this.assertPrefixFree(tenantId, dto.prefix, id);
    }

    return this.prisma.category.update({
      where: { id },
      data: {
        name: dto.name?.trim() || undefined,
        prefix: dto.prefix,
        minStockThreshold: dto.minStockThreshold,
        active: dto.active,
      },
    });
  }

  async remove(tenantId: string, id: string) {
    const category = await this.prisma.category.findFirst({
      where: { id, tenantId },
      select: { id: true },
    });
    if (!category) throw new NotFoundException('Category not found');

    const itemCount = await this.prisma.inventoryItem.count({
      where: { tenantId, categoryId: id, deletedAt: null },
    });
    if (itemCount > 0) {
      throw new ConflictException(
        'Category has inventory items — deactivate it instead',
      );
    }

    await this.prisma.category.delete({ where: { id } });
    return { deleted: true };
  }

  /// Seeds the default master list once per tenant (matching by name so a
  /// legacy "Ring" created from free text is upgraded, not duplicated) and
  /// backfills prefixes onto any remaining prefix-less categories.
  private async ensureSeeded(tenantId: string) {
    const existing = await this.prisma.category.findMany({
      where: { tenantId },
      select: { id: true, name: true, prefix: true },
    });
    const byName = new Map(
      existing.map((c) => [this.normalizeName(c.name), c]),
    );
    const usedPrefixes = new Set(
      existing.map((c) => c.prefix).filter(Boolean) as string[],
    );

    for (const seed of DEFAULT_CATEGORIES) {
      const match = byName.get(this.normalizeName(seed.name));
      if (!match) {
        if (usedPrefixes.has(seed.prefix)) continue; // owner claimed it
        await this.prisma.category.create({
          data: { tenantId, name: seed.name, prefix: seed.prefix },
        });
        usedPrefixes.add(seed.prefix);
      } else if (!match.prefix && !usedPrefixes.has(seed.prefix)) {
        await this.prisma.category.update({
          where: { id: match.id },
          data: { prefix: seed.prefix },
        });
        usedPrefixes.add(seed.prefix);
      }
    }

    // Legacy free-text categories that matched nothing: derive a prefix from
    // the name so they can generate tags too.
    const leftover = await this.prisma.category.findMany({
      where: { tenantId, prefix: null },
      select: { id: true, name: true },
    });
    for (const category of leftover) {
      const prefix = this.uniquePrefixFor(category.name, usedPrefixes);
      if (!prefix) continue;
      await this.prisma.category.update({
        where: { id: category.id },
        data: { prefix },
      });
      usedPrefixes.add(prefix);
    }
  }

  private normalizeName(name: string) {
    // "Anklet (Payal)" and "anklet" should match.
    return name
      .toLowerCase()
      .replace(/\s*\(.*\)\s*/g, '')
      .trim();
  }

  private async derivePrefix(tenantId: string, name: string) {
    const existing = await this.prisma.category.findMany({
      where: { tenantId, prefix: { not: null } },
      select: { prefix: true },
    });
    const used = new Set(existing.map((c) => c.prefix) as string[]);
    const prefix = this.uniquePrefixFor(name, used);
    if (!prefix) {
      throw new ConflictException(
        'Could not derive a unique prefix — provide one explicitly',
      );
    }
    return prefix;
  }

  /// First two letters, then first+third, … then letter pairs with a digit;
  /// returns null only if everything plausible is taken.
  private uniquePrefixFor(name: string, used: Set<string>): string | null {
    const letters = name.toUpperCase().replace(/[^A-Z]/g, '');
    if (letters.length < 2) return null;

    const candidates: string[] = [];
    candidates.push(letters.slice(0, 2));
    for (let i = 2; i < letters.length; i++) {
      candidates.push(letters[0] + letters[i]);
    }
    if (letters.length >= 3) candidates.push(letters.slice(0, 3));

    for (const candidate of candidates) {
      if (!used.has(candidate)) return candidate;
    }
    return null;
  }

  private async assertPrefixFree(
    tenantId: string,
    prefix: string,
    excludeId?: string,
  ) {
    const clash = await this.prisma.category.findFirst({
      where: {
        tenantId,
        prefix,
        ...(excludeId ? { id: { not: excludeId } } : {}),
      },
      select: { id: true, name: true },
    });
    if (clash) {
      throw new ConflictException(
        `Prefix ${prefix} is already used by "${clash.name}"`,
      );
    }
  }
}
