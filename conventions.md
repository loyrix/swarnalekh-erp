# SwarnaLekh Conventions

## Scope Rule

All conventions in this file are subordinate to:

`/Users/satyamjaiswal/Downloads/Jewellery ERP System Flow (1).pdf`

Only PDF-defined modules should be treated as active product scope.

## Active API Areas

Base path:

`/api/v1`

Active endpoint groups:

- `/auth`
- `/tenant`
- `/dashboard`
- `/inventory`
- `/mortgages`
- `/invoices` or existing billing invoice paths
- `/reports` only for PDF-defined reports

Supporting customer endpoints are allowed only because billing and mortgage require customer records.

Do not add active endpoint groups for schemes, ledger, subscriptions, sync, or super-admin flows.

## Data Conventions

All tenant-owned records must include:

- `tenantId`
- `createdAt`
- `updatedAt`

Soft-deletable business records should include:

- `deletedAt`

Audited records should include:

- `createdBy`
- update or close actor fields where useful

Use transactions when one user action touches more than one business table.

Examples:

- Create invoice and mark inventory item sold.
- Collect mortgage interest and update loan balance.
- Close mortgage loan and create closure payment.

## Inventory Conventions

Inventory status values:

- `available`
- `sold`
- `reserved`

Inventory fields should map to the PDF:

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
- Branch
- Stock status

Inventory search should support:

- Product name
- Design number
- Category
- Branch
- Status

## Mortgage Conventions

Mortgage status values:

- `active`
- `closed`

Mortgage workflows:

- Add mortgage
- List active loans
- Collect interest
- Close loan
- View closed loans
- Mortgage reports

Mortgage calculations should include:

- Monthly interest
- Total payable amount
- Due date
- Pending balance

Mortgage payment actions should generate receipts and preserve payment history.

## Billing Conventions

Billing workflow:

1. Select or enter customer.
2. Search inventory.
3. Select product.
4. Auto-fill product data.
5. Calculate bill.
6. Select payment method.
7. Generate invoice.
8. Reduce inventory.
9. Save invoice history.

Payment methods:

- `cash`
- `upi`
- `debit_card`
- `credit_card`
- `bank_transfer`

Invoices should preserve snapshots of customer details, product details, GST breakdown, payment method, and totals.

## Reports Conventions

Reports are operational summaries, not a separate analytics product.

Allowed report families:

- Inventory: current stock, sold products, low stock
- Billing: daily sales, monthly sales, GST
- Mortgage: active loans, interest collection, closed loans

## Flutter Navigation Conventions

Primary navigation should expose only:

- Dashboard
- Inventory
- Mortgage
- Billing
- Reports where implemented

Settings/user management may be available to Admin only.

Do not expose placeholder product modules.

## Verification Commands

```bash
pnpm verify:precommit
pnpm --dir apps/api test --runInBand
cd apps/mobile && flutter analyze
cd apps/mobile && flutter test
```
