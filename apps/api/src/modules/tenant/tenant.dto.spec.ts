import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { UpdateTenantDto } from './tenant.dto';

describe('UpdateTenantDto', () => {
  it('allows the shop profile fields sent by the mobile app', async () => {
    const dto = plainToInstance(UpdateTenantDto, {
      shopName: 'Kundan Jewellers',
      ownerName: 'Owner',
      email: 'owner@kundan.test',
      phone: '+919876543210',
      address: 'Main Bazaar',
      city: 'Mumbai',
      state: 'Maharashtra',
      pincode: '400001',
      gstin: '27AAAAA0000Z1Z5',
      pan: 'AAAAA0000Z',
    });

    const errors = await validate(dto, {
      whitelist: true,
      forbidNonWhitelisted: true,
    });

    expect(errors).toHaveLength(0);
  });

  it('rejects unknown profile fields', async () => {
    const dto = plainToInstance(UpdateTenantDto, {
      shopName: 'Kundan Jewellers',
      unsupported: 'nope',
    });

    const errors = await validate(dto, {
      whitelist: true,
      forbidNonWhitelisted: true,
    });

    expect(errors).toHaveLength(1);
    expect(errors[0].property).toBe('unsupported');
  });
});
