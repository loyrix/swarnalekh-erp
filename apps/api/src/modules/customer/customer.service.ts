import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateCustomerDto, UpdateCustomerDto } from './customer.dto';

@Injectable()
export class CustomerService {
  constructor(private readonly prisma: PrismaService) {}

  async findAll(
    tenantId: string,
    options?: { limit?: number; search?: string },
  ) {
    return this.prisma.customer.findMany({
      where: {
        tenantId,
        deletedAt: null,
        ...(options?.search
          ? {
              OR: [
                { name: { contains: options.search, mode: 'insensitive' } },
                { phone: { contains: options.search } },
                { email: { contains: options.search, mode: 'insensitive' } },
              ],
            }
          : {}),
      },
      orderBy: { createdAt: 'desc' },
      ...(options?.limit ? { take: options.limit } : {}),
    });
  }

  async findOne(tenantId: string, id: string) {
    const customer = await this.prisma.customer.findFirst({
      where: { id, tenantId, deletedAt: null },
    });
    if (!customer) {
      throw new NotFoundException('Customer not found');
    }
    return customer;
  }

  async create(tenantId: string, dto: CreateCustomerDto) {
    return this.prisma.customer.create({
      data: { tenantId, ...dto },
    });
  }

  async update(tenantId: string, id: string, dto: UpdateCustomerDto) {
    await this.findOne(tenantId, id); // Verify exists + tenant match
    return this.prisma.customer.update({
      where: { id },
      data: dto,
    });
  }

  async remove(tenantId: string, id: string) {
    await this.findOne(tenantId, id);
    // Soft delete
    return this.prisma.customer.update({
      where: { id },
      data: { deletedAt: new Date() },
    });
  }

  async count(tenantId: string) {
    return this.prisma.customer.count({
      where: { tenantId, deletedAt: null },
    });
  }
}
