# SwarnaLekh PDF Status

## Source Of Truth

This status tracks the repository against:

`/Users/satyamjaiswal/Downloads/Jewellery ERP System Flow (1).pdf`

## Current Status

The backend has started moving toward the PDF flow.

The app still needs visible navigation and screens aligned to the PDF, especially Mortgage and Reports.

## Done

- SwarnaLekh branding is in place.
- NestJS remains the backend.
- Vercel API configuration exists.
- Inventory, billing, supporting customer records, and dashboard code already exist from earlier work.
- Mortgage / gold loan database models exist.
- Mortgage API module exists.
- Mortgage service tests exist.
- Shared mortgage interest helpers exist.
- Pre-commit verification hook exists.

## Partial Against PDF

- Dashboard: exists, but must be checked against PDF cards and quick actions.
- Inventory: exists, but must align to PDF table columns, add-stock sections, sold-products flow, and reports.
- Billing: exists, but must align to PDF bill table, payment methods, invoice features, and automatic inventory reduction.
- Reports: only PDF-defined reports should remain visible.
- Security: login exists, but Admin/Staff access needs verification against the PDF.
- Search/filter: must be made visible across inventory, invoice history, mortgage, and reports.

## Missing Or Next

- Mortgage UI screens.
- Mortgage navigation entry.
- Active loans, collect interest, closed loans UI.
- PDF-aligned dashboard quick actions.
- Inventory product details page if incomplete.
- Sold products page if incomplete.
- Invoice history search by customer, date, and invoice number.
- Report pages for inventory, billing, and mortgage.
- Activity logs and invoice protection plan.

## Removed From Status Tracking

These are no longer tracked as active work:

- Schemes
- Ledger
- Subscription tiers
- Multilingual feature status
- Offline sync
- Super-admin
- External rate provider work

## Next Task

Update Flutter navigation and routes so the visible app matches the PDF:

- Dashboard
- Inventory
- Mortgage
- Billing
- Reports where implemented

Then build the Mortgage UI because the backend foundation already exists.
