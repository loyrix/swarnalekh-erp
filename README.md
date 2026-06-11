# SwarnaLekh Jewellery ERP

SwarnaLekh is a jewellery ERP for jewellery shops, retail jewellery stores, and gold loan businesses.

The product scope is now governed by the PDF:

`/Users/satyamjaiswal/Downloads/Jewellery ERP System Flow (1).pdf`

If any repository document conflicts with that PDF, the PDF wins.

## PDF-Aligned Scope

The active product contains only these flows:

- Login and role-based access
- Main dashboard
- Inventory management
- Mortgage / gold loan management
- Billing and invoice management
- Reports required by inventory, billing, and mortgage
- Global search and filters
- Mobile responsive, touch-friendly UI
- Security basics: secure login, role access, data backup, activity logs, invoice protection

The active navigation should center on:

- Dashboard
- Inventory
- Mortgage
- Billing
- Reports / summaries where required

## Out Of Scope Unless The PDF Changes

Do not plan or build these as active product promises:

- Schemes
- Ledger
- Subscription tiers
- Standalone multilingual roadmap
- Offline-first sync
- Advanced CRM
- Super-admin product management
- External live rate automation as a core module

Customer records are supporting data for billing and mortgage flows, not a separate primary ERP pillar in the PDF.

## Core Flows

### Login

- Username and password login
- Mobile number login is optional
- Admin and staff roles
- Remember session and logout

### Dashboard

Show operational summary cards:

- Total gold weight
- Total silver weight
- Total inventory value
- Monthly revenue
- Pending interest amount
- Active mortgage loans
- Today's sales
- Total bills generated

Quick actions:

- Add Stock
- Create Bill
- Add Mortgage
- Search Product
- Search Customer

### Inventory

Inventory supports:

- Dashboard
- Add Stock
- View Inventory
- Sold Products
- Product Details
- Stock Reports

Important product fields:

- Product image
- Product name
- Category
- Design number
- Purity
- Gross weight
- Stone weight
- Net weight
- Purchase price
- Selling price
- Making charges
- Stock status
- Branch

Statuses:

- Available
- Sold
- Reserved

### Mortgage / Gold Loan

Mortgage supports:

- Dashboard
- Add Mortgage
- Active Loans
- Collect Interest
- Closed Loans
- Mortgage Reports

Important loan data:

- Customer name, mobile number, address
- Aadhaar number
- PAN number
- Photo ID and customer photo where needed
- Ornament type, purity, gross weight, net weight
- Loan amount, interest rate, loan date
- Monthly interest, total payable, due date, pending balance

### Billing And Invoice

Billing supports:

- Dashboard
- New Bill
- Invoice History
- Sales Reports

The billing flow:

1. Select or enter customer.
2. Search inventory.
3. Select product.
4. Auto-fill product data.
5. Calculate bill.
6. Select payment method.
7. Generate invoice.
8. Reduce inventory and mark sold.
9. Save invoice history and update dashboard.

Payment methods:

- Cash
- UPI
- Debit Card
- Credit Card
- Bank Transfer

Invoice should include:

- Shop logo
- Invoice number
- Customer details
- Product details
- GST breakdown
- Payment method
- Optional QR code

## Reports

Reports are part of the PDF scope only for:

- Current stock
- Sold products
- Low stock
- Daily sales
- Monthly sales
- GST
- Active loans
- Interest collection
- Closed loans

## Tech Stack

- Flutter for mobile and web
- NestJS API
- Prisma with PostgreSQL
- Provider-neutral bearer JWT auth
- pnpm monorepo

## Common Commands

```bash
pnpm install
pnpm vercel:build:api
pnpm --dir apps/api test --runInBand
cd apps/mobile && flutter analyze
cd apps/mobile && flutter test
```

## Local Mobile Builds

GitHub Actions are not configured. API deployment is handled by Vercel on commit/push.

Local mobile builds read `apps/mobile/.env` through `--dart-define-from-file`.

```bash
pnpm mobile:env:sync
pnpm mobile:apk
```

Before commits, the tracked hook in `.githooks/pre-commit` runs formatting, tests, builds, Flutter analyzer, Flutter tests, and Flutter web build.
