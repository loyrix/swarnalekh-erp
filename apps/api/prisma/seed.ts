import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('Seeding SwarnaLekh database...\n');

  // ========================
  // 1. Demo Tenant
  // ========================
  const tenantEmail = 'rajesh@shreekrishnajewellers.com';
  const existingTenant = await prisma.tenant.findFirst({
    where: { email: tenantEmail },
  });

  const tenant = existingTenant
    ? await prisma.tenant.update({
        where: { id: existingTenant.id },
        data: {
          shopName: 'Shree Krishna Jewellers',
          ownerName: 'Rajesh Kumar',
          phone: '+919876543210',
          email: tenantEmail,
          address: '123 Gold Market, Main Road',
          city: 'Mumbai',
          state: 'Maharashtra',
          pincode: '400001',
          gstin: '27AABCU9603R1ZM',
          pan: 'AABCU9603R',
          subscriptionPlan: 'pro',
          isActive: true,
        },
      })
    : await prisma.tenant.create({
        data: {
          shopName: 'Shree Krishna Jewellers',
          ownerName: 'Rajesh Kumar',
          phone: '+919876543210',
          email: tenantEmail,
          address: '123 Gold Market, Main Road',
          city: 'Mumbai',
          state: 'Maharashtra',
          pincode: '400001',
          gstin: '27AABCU9603R1ZM',
          pan: 'AABCU9603R',
          subscriptionPlan: 'pro',
          isActive: true,
        },
      });
  console.log(`✅ Tenant: ${tenant.shopName} (${tenant.id})`);

  // ========================
  // 2. Owner User
  // ========================
  const owner = await prisma.user.upsert({
    where: {
      email: 'rajesh@shreekrishnajewellers.com',
    },
    update: {
      name: 'Rajesh Kumar',
      phone: '+919876543210',
      authUserId: null,
      role: 'owner',
      isActive: true,
    },
    create: {
      tenantId: tenant.id,
      name: 'Rajesh Kumar',
      phone: '+919876543210',
      email: 'rajesh@shreekrishnajewellers.com',
      role: 'owner',
      isActive: true,
    },
  });
  console.log(`✅ Owner: ${owner.name} (${owner.role})`);

  // ========================
  // 3. Staff User
  // ========================
  const staff = await prisma.user.upsert({
    where: {
      email: 'amit@shreekrishnajewellers.com',
    },
    update: {
      name: 'Amit Sharma',
      phone: '+919876543211',
      authUserId: null,
      role: 'staff',
      isActive: true,
    },
    create: {
      tenantId: tenant.id,
      name: 'Amit Sharma',
      phone: '+919876543211',
      email: 'amit@shreekrishnajewellers.com',
      role: 'staff',
      isActive: true,
    },
  });
  console.log(`✅ Staff: ${staff.name} (${staff.role})`);

  // ========================
  // 4. Categories
  // ========================
  const goldCategory = await prisma.category.create({
    data: { tenantId: tenant.id, name: 'Gold' },
  });
  const silverCategory = await prisma.category.create({
    data: { tenantId: tenant.id, name: 'Silver' },
  });
  const necklaceCategory = await prisma.category.create({
    data: { tenantId: tenant.id, name: 'Necklaces', parentId: goldCategory.id },
  });
  const ringCategory = await prisma.category.create({
    data: { tenantId: tenant.id, name: 'Rings', parentId: goldCategory.id },
  });
  const bangleCategory = await prisma.category.create({
    data: { tenantId: tenant.id, name: 'Bangles', parentId: goldCategory.id },
  });
  console.log(`✅ Categories: 5 created`);

  // ========================
  // 5. Customers
  // ========================
  const customers = await Promise.all([
    prisma.customer.create({
      data: {
        tenantId: tenant.id,
        name: 'Priya Singh',
        phone: '+919111222333',
        email: 'priya.singh@email.com',
        address: '45 Park Avenue',
        city: 'Mumbai',
        pincode: '400002',
        preferredKarat: '22K',
        totalPurchases: 250000,
        totalVisits: 5,
      },
    }),
    prisma.customer.create({
      data: {
        tenantId: tenant.id,
        name: 'Meena Devi',
        phone: '+919222333444',
        address: '78 Gandhi Nagar',
        city: 'Mumbai',
        pincode: '400003',
        preferredKarat: '24K',
        totalPurchases: 180000,
        totalVisits: 3,
      },
    }),
    prisma.customer.create({
      data: {
        tenantId: tenant.id,
        name: 'Suresh Patel',
        phone: '+919333444555',
        address: '12 Station Road',
        city: 'Mumbai',
        pincode: '400004',
        totalPurchases: 75000,
        totalVisits: 2,
      },
    }),
  ]);
  console.log(`✅ Customers: ${customers.length} created`);

  // ========================
  // 6. Karigar
  // ========================
  const karigar = await prisma.karigar.create({
    data: {
      tenantId: tenant.id,
      name: 'Ramu Sonar',
      phone: '+919444555666',
      specialization: 'Necklaces & Chains',
      address: 'Zaveri Bazaar',
      isActive: true,
    },
  });
  console.log(`✅ Karigar: ${karigar.name}`);

  // ========================
  // 7. Daily Rates (today)
  // ========================
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  await Promise.all([
    prisma.dailyRate.create({
      data: {
        tenantId: tenant.id,
        rateDate: today,
        metalType: 'gold',
        karat: '24K',
        ratePerGram: 7250,
        source: 'manual',
        setBy: owner.id,
      },
    }),
    prisma.dailyRate.create({
      data: {
        tenantId: tenant.id,
        rateDate: today,
        metalType: 'gold',
        karat: '22K',
        ratePerGram: 6650,
        source: 'manual',
        setBy: owner.id,
      },
    }),
    prisma.dailyRate.create({
      data: {
        tenantId: tenant.id,
        rateDate: today,
        metalType: 'gold',
        karat: '18K',
        ratePerGram: 5440,
        source: 'manual',
        setBy: owner.id,
      },
    }),
    prisma.dailyRate.create({
      data: {
        tenantId: tenant.id,
        rateDate: today,
        metalType: 'silver',
        karat: null,
        ratePerGram: 95,
        source: 'manual',
        setBy: owner.id,
      },
    }),
  ]);
  console.log(`✅ Daily rates: 4 set for today`);

  // ========================
  // 8. Inventory Items
  // ========================
  await Promise.all([
    prisma.inventoryItem.create({
      data: {
        tenantId: tenant.id,
        tagNumber: 'GN-001',
        categoryId: necklaceCategory.id,
        itemName: 'Lakshmi Haar (Traditional Necklace)',
        metalType: 'gold',
        karat: '22K',
        purity: 91.667,
        grossWeight: 45.5,
        netWeight: 43.2,
        makingChargesPerGram: 450,
        wastagePercent: 8,
        karigarId: karigar.id,
        hallmarkNumber: 'HM-2024-001',
        huid: 'ABCD1234',
        status: 'in_stock',
        location: 'Display Case A',
      },
    }),
    prisma.inventoryItem.create({
      data: {
        tenantId: tenant.id,
        tagNumber: 'GR-002',
        categoryId: ringCategory.id,
        itemName: 'Solitaire Setting Ring',
        metalType: 'gold',
        karat: '18K',
        purity: 75.0,
        grossWeight: 8.2,
        netWeight: 6.5,
        hasStones: true,
        stoneDetails: {
          type: 'Diamond',
          weight: '0.50ct',
          clarity: 'VS1',
          color: 'F',
        },
        stoneValue: 35000,
        makingChargesFixed: 5500,
        wastagePercent: 5,
        hallmarkNumber: 'HM-2024-002',
        status: 'in_stock',
        location: 'Display Case B',
      },
    }),
    prisma.inventoryItem.create({
      data: {
        tenantId: tenant.id,
        tagNumber: 'GB-003',
        categoryId: bangleCategory.id,
        itemName: 'Plain Gold Bangle (Set of 2)',
        metalType: 'gold',
        karat: '22K',
        purity: 91.667,
        grossWeight: 32.0,
        netWeight: 32.0,
        makingChargesPerGram: 350,
        wastagePercent: 3,
        hallmarkNumber: 'HM-2024-003',
        huid: 'EFGH5678',
        status: 'in_stock',
        location: 'Display Case A',
      },
    }),
    prisma.inventoryItem.create({
      data: {
        tenantId: tenant.id,
        tagNumber: 'SB-004',
        categoryId: silverCategory.id,
        itemName: 'Silver Payal (Anklet Pair)',
        metalType: 'silver',
        grossWeight: 120.0,
        netWeight: 118.5,
        makingChargesPerGram: 25,
        wastagePercent: 2,
        status: 'in_stock',
        location: 'Display Case C',
      },
    }),
  ]);
  console.log(`✅ Inventory: 4 items created`);

  // ========================
  // 9. Scheme
  // ========================
  const scheme = await prisma.scheme.create({
    data: {
      tenantId: tenant.id,
      schemeName: 'Monthly Gold Savings',
      durationMonths: 11,
      monthlyAmount: 5000,
      bonusDescription: '1 month amount free on maturity',
      bonusType: 'fixed',
      bonusValue: 5000,
      isActive: true,
    },
  });
  console.log(`✅ Scheme: ${scheme.schemeName}`);

  // ========================
  // 10. Scheme Enrollment
  // ========================
  const enrollment = await prisma.schemeEnrollment.create({
    data: {
      tenantId: tenant.id,
      schemeId: scheme.id,
      customerId: customers[0].id,
      enrollmentNumber: 'SCH-2024-001',
      monthlyAmount: 5000,
      totalMonths: 11,
      monthsPaid: 3,
      totalPaid: 15000,
      status: 'active',
    },
  });

  // Add 3 scheme payments
  for (let i = 1; i <= 3; i++) {
    await prisma.schemePayment.create({
      data: {
        enrollmentId: enrollment.id,
        amount: 5000,
        monthNumber: i,
        paymentMode: 'cash',
        collectedBy: staff.id,
      },
    });
  }
  console.log(`✅ Scheme enrollment + 3 payments`);

  console.log('\n🎉 Seed complete! Demo tenant ready.');
  console.log(`   Shop: ${tenant.shopName}`);
  console.log(`   Owner phone: ${tenant.phone}`);
}

main()
  .catch((e) => {
    console.error('❌ Seed failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
