// One-time admin bootstrap: set (or reset) a user's login password directly in
// the database. Use it to give existing/migrated users (created before we owned
// auth) a password so they can log in — including the owner, who otherwise can't
// reach the in-app "set password" screen.
//
// Usage (from apps/api, with DATABASE_URL in apps/api/.env):
//   pnpm --dir apps/api set-password <email> <newPassword>
// Example:
//   pnpm --dir apps/api set-password jsatyam4@gmail.com 'my-new-strong-pass'

import 'dotenv/config';
import { randomUUID } from 'node:crypto';
import bcrypt from 'bcryptjs';
import prismaPkg from '@prisma/client';

const { PrismaClient } = prismaPkg;

const [, , emailArg, passwordArg] = process.argv;

if (!emailArg || !passwordArg) {
  console.error('Usage: pnpm --dir apps/api set-password <email> <password>');
  process.exit(1);
}

const email = emailArg.trim().toLowerCase();

if (passwordArg.length < 8) {
  console.error('✗ Password must be at least 8 characters.');
  process.exit(1);
}

const prisma = new PrismaClient();

try {
  const user = await prisma.user.findFirst({
    where: { email: { equals: email, mode: 'insensitive' } },
    include: { tenant: { select: { shopName: true, isActive: true } } },
  });

  if (!user) {
    console.error(`✗ No user found with email ${email}.`);
    process.exit(1);
  }

  const passwordHash = await bcrypt.hash(passwordArg, 10);

  await prisma.user.update({
    where: { id: user.id },
    data: {
      passwordHash,
      // Ensure a stable JWT subject exists for first-party login.
      authUserId: user.authUserId ?? randomUUID(),
      isActive: true,
    },
  });

  console.log(
    `✓ Password set for ${email} (role: ${user.role}, shop: ${user.tenant?.shopName ?? '—'}).`,
  );
  if (user.tenant && user.tenant.isActive === false) {
    console.warn(
      '! Note: this tenant is currently suspended (isActive=false); login will be blocked until it is re-activated.',
    );
  }
  console.log('You can now log in with this email and the new password.');
} catch (error) {
  console.error('✗ Failed to set password:', error?.message ?? error);
  process.exit(1);
} finally {
  await prisma.$disconnect();
}
