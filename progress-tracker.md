# SwarnaLekh Progress Tracker

## Current Source Of Truth

The current source of truth is:

`/Users/satyamjaiswal/Downloads/Jewellery ERP System Flow (1).pdf`

This tracker follows that PDF only.

## Active Product Scope

- Login and role-based access
- Dashboard
- Inventory management
- Mortgage / gold loan management
- Billing and invoice management
- PDF-defined reports
- Search and filters
- Mobile responsive UI
- Security basics

## Removed From Active Scope

- Schemes
- Ledger
- Subscription tiers
- Standalone multilingual roadmap
- Offline-first sync
- Super-admin planning
- External live rate provider planning

## Completed Recently

- Renamed visible app/API branding to SwarnaLekh.
- Kept backend on NestJS.
- Added Vercel API build/deploy configuration.
- Added mortgage / gold loan database models and migration.
- Added mortgage API module for dashboard, loan creation, loan listing, interest collection, closure, and soft delete.
- Added dashboard mortgage metrics.
- Added mortgage interest calculation helpers in shared business logic.
- Added mortgage service tests.
- Added Flutter localization smoke test.
- Added tracked pre-commit hook for formatter, tests, builds, Flutter analyzer, Flutter tests, and Flutter web build.
- Committed locally as `6056971 feat: add SwarnaLekh mortgage foundation`.
- Rewrote repository documentation so the PDF is the active product source of truth.
- Removed non-PDF plan docs for subscriptions and standalone multilingual tracking.
- Updated Flutter primary navigation to Dashboard, Inventory, Mortgage, Billing, and Reports.
- Added first Mortgage / Gold Loan UI for dashboard cards, active/closed loans, add mortgage, collect payment, and close loan.
- Added a PDF-aligned Reports screen for inventory, billing, and mortgage report families.

## Current Git Note

Local `main` is ahead of `origin/main` by one commit.

Push is currently blocked because the configured GitHub remote is not accessible from this machine:

`https://github.com/jsatyam4/swarnabook.git`

GitHub returned `Repository not found`.

## Next Work Order

1. Align Dashboard summary cards fully to the PDF metrics.
2. Align Inventory UI with PDF table, add-stock, product details, and sold-products flows.
3. Align Billing UI with PDF invoice flow and automatic inventory reduction.
4. Replace Reports overview with data-backed PDF reports.
5. Tighten role-based access for Admin and Staff.
6. Run full smoke test across login, inventory, mortgage, billing, reports, and dashboard.

## Verification Baseline

Before the last commit, the full pre-commit pipeline passed:

- Staged Prettier check
- Dart format check
- Workspace tests
- Workspace build
- Flutter analyze
- Flutter test
- Flutter web build
