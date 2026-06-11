# SwarnaLekh Jewellery ERP

## Single Source Of Truth

The only product plan for this repository is:

[`docs/source-of-truth/jewellery-erp-system-flow.pdf`](docs/source-of-truth/jewellery-erp-system-flow.pdf)

Every product decision, implementation phase, test plan, and future agent task must follow that PDF. If any code, comment, migration, old idea, generated artifact, or external memory conflicts with the PDF, the PDF wins.

Do not add or implement features that are not in the PDF unless the PDF is explicitly updated by the owner.

## Product Scope From The PDF

SwarnaLekh is a jewellery ERP for jewellery shops, retail jewellery stores, and gold loan businesses.

The active product contains only these business areas:

- Login and role-based access
- Dashboard
- Inventory management
- Mortgage / gold loan management
- Billing and invoice management
- Reports
- Search and filters
- Responsive mobile/tablet/desktop UI
- Security basics: secure login, role-based access, backup, activity logs, invoice protection
- Admin/staff user management where required for role-based access
- Shop profile/settings where required for invoice and business identity

## Out Of Scope Unless The PDF Changes

Do not build or plan these as active product features:

- KYC as a standalone module
- Schemes
- Ledger
- Notifications
- Subscription tiers
- Super-admin product management
- Offline-first sync
- Standalone CRM
- Non-PDF analytics
- Any extra module not named in the PDF

If old database tables or dormant code exist for non-PDF areas, they must not appear in the active UI or implementation plan.

## Implementation Strategy

Use a requirement traceability approach:

1. Extract each PDF requirement into the tracker below.
2. Implement by full business journey, not isolated screens.
3. For every requirement, verify UI, API, DB, role access, side effects, tests, and mobile UX.
4. Mark a requirement complete only when it works end-to-end.
5. Keep frontend and backend payloads in sync. Do not show fields in the UI that the backend does not support.

## Definition Of Done

A PDF requirement is complete only when all of these are true:

- Mobile UI exists and matches the PDF flow.
- Backend API exists and validates the same fields the UI sends.
- Database stores the required business data.
- Admin/staff role access behaves as defined in the PDF.
- Dashboard/reports/security side effects update after the action.
- Loading, empty, error, and success states exist.
- Keyboard, safe area, scrolling, and touch behavior work on mobile.
- Backend tests and Flutter tests/analyzer/build pass where applicable.
- The flow has been manually verified from the app.

## Navigation Target

Primary navigation should stay focused on:

- Dashboard
- Inventory
- Mortgage
- Billing
- Reports

Admin-only secondary areas can live under profile/settings:

- Shop Profile
- Security
- User Management

## End-To-End Business Journeys

### Journey 1: Inventory To Billing

Add Stock -> View Inventory -> Search Product -> Create Bill -> Generate Invoice -> Reduce Stock -> Mark Product Sold -> Sold Products -> Dashboard/Reports Updated

This is the highest-priority money flow.

### Journey 2: Mortgage / Gold Loan

Add Mortgage -> Active Loan -> Collect Interest/Principal -> Receipt -> Pending Balance Updated -> Close Loan -> Closed Loans -> Dashboard/Reports Updated

### Journey 3: Billing History And Reports

New Bill -> Invoice History -> Reprint/Download/Share -> Daily Sales -> Monthly Sales -> GST Report

### Journey 4: Security And Admin

Login -> Role-Based Access -> Mutating Action -> Activity Log -> Backup Export -> Logout

## Progress Tracker

| ID  | Area      | Requirement                                  | Status      | Notes                                                      |
| --- | --------- | -------------------------------------------- | ----------- | ---------------------------------------------------------- |
| A1  | Alignment | PDF is the only source of truth              | Complete    | Repo-local PDF plus README/AGENTS instructions             |
| A2  | Alignment | Remove/hide visible non-PDF features         | Pending     | Audit UI before implementation                             |
| A3  | Alignment | SwarnaLekh branding everywhere               | Partial     | Needs final visible audit                                  |
| L1  | Login     | Username/password or email/password login    | Built       | Current app uses email/password                            |
| L2  | Login     | Mobile login optional                        | Not Started | Optional in PDF                                            |
| L3  | Login     | Remember session and logout                  | Built       | Needs final smoke test                                     |
| L4  | Roles     | Admin and staff role-based access            | Built       | Needs final matrix tests                                   |
| D1  | Dashboard | Gold stock, silver stock, inventory value    | Built       | Verify live data                                           |
| D2  | Dashboard | Monthly revenue, today sales, total bills    | Built       | Verify live data                                           |
| D3  | Dashboard | Pending interest and active loans            | Built       | Verify live data                                           |
| D4  | Dashboard | Sold products summary                        | Pending     | Missing PDF dashboard item                                 |
| D5  | Dashboard | Quick actions                                | Built       | Verify role visibility                                     |
| D6  | Dashboard | Optional charts                              | Pending     | Monthly sales, stock trend, loan collection, daily billing |
| I1  | Inventory | Add stock form fields from PDF               | Partial     | Cleanup field alignment                                    |
| I2  | Inventory | Net weight auto-calculation                  | Built       | Verify with tests                                          |
| I3  | Inventory | Making/final selling price auto-calculation  | Built       | Verify consistency                                         |
| I4  | Inventory | Explicit selling price stored                | Built       | Used as the primary billing line price                     |
| I5  | Inventory | Inventory table columns                      | Built       | Verify exact PDF columns                                   |
| I6  | Inventory | Product details                              | Built       | Dialog-based                                               |
| I7  | Inventory | Sold products list                           | Built       | Data comes from invoices                                   |
| I8  | Inventory | Alerts: low/out/high value/unsold            | Built       | Verify data correctness                                    |
| B1  | Billing   | New bill customer + inventory selection      | Built       | Verify full mobile UX                                      |
| B2  | Billing   | Use inventory selling price in bill          | Built       | Backend and Flutter preview use saved selling price first  |
| B3  | Billing   | Frontend/backend totals match                | Built       | Explicit price flow covered, rate fallback preserved       |
| B4  | Billing   | Payment methods from PDF                     | Built       | Cash, UPI, cards, bank transfer                            |
| B5  | Billing   | Generate invoice and reduce stock            | Built       | Covered by invoice service regression tests                |
| B6  | Billing   | Invoice history search/filter                | Partial     | Verify customer/date/invoice search                        |
| B7  | Billing   | Reprint/download/share invoice               | Partial     | Needs production-grade verification                        |
| B8  | Billing   | Branded invoice PDF with shop logo           | Pending     | Current PDF is too basic                                   |
| B9  | Billing   | Optional QR code                             | Pending     | Optional per PDF                                           |
| M1  | Mortgage  | Add mortgage with customer/gold/loan details | Built       | Verify fields and validation                               |
| M2  | Mortgage  | Aadhaar/PAN/photo/customer photo support     | Built       | Verify frontend/backend sync                               |
| M3  | Mortgage  | Interest/payable/due/pending calculations    | Built       | Verify with tests                                          |
| M4  | Mortgage  | Collect interest/principal                   | Built       | Verify payment history                                     |
| M5  | Mortgage  | Receipt generation                           | Built       | Needs production-grade verification                        |
| M6  | Mortgage  | Close loan                                   | Built       | Needs full-flow test                                       |
| R1  | Reports   | Inventory reports                            | Built       | Current stock, sold products, low stock                    |
| R2  | Reports   | Billing reports                              | Built       | Daily, monthly, GST                                        |
| R3  | Reports   | Mortgage reports                             | Built       | Active, interest collection, closed                        |
| R4  | Reports   | Search and filters                           | Partial     | Verify date/category/branch/status                         |
| S1  | Security  | Activity logs                                | Built       | Mutating API calls are logged                              |
| S2  | Security  | Backup export                                | Built       | Needs final verification                                   |
| S3  | Security  | Invoice protection                           | Partial     | Verify invoice code/QR behavior                            |
| U1  | Users     | Admin/staff management                       | Partial     | Auth onboarding is incomplete                              |
| UX1 | UX        | Safe areas and status/navigation bars        | Partial     | Needs premium pass                                         |
| UX2 | UX        | Keyboard-safe scrollable forms               | Partial     | Needs all forms/dialogs verified                           |
| UX3 | UX        | Premium mobile/tablet responsive UI          | Partial     | Needs final polish pass                                    |
| T1  | Tests     | Backend tests for business flows             | Partial     | Extend where gaps are fixed                                |
| T2  | Tests     | Flutter tests/analyzer/build                 | Partial     | Run after each phase                                       |
| T3  | Release   | Android release APK                          | Partial     | Generate after final regression                            |

## Implementation Order

1. PDF alignment cleanup: hide/remove visible non-PDF features.
2. Inventory selling price to billing price flow.
3. Billing totals, invoice history, branded PDF, logo, and share/download.
4. Dashboard missing PDF items and live data verification.
5. Mortgage full-flow verification and receipt polish.
6. Reports filters and export verification.
7. Security/user management completion.
8. Premium UX pass for safe areas, keyboard, scrolling, and responsive layouts.
9. Final tests, Android build, and manual business journey verification.

## Required Verification After Each Phase

Run the relevant tests and checks after each implementation phase:

```bash
pnpm --dir apps/api test --runInBand
pnpm vercel:build:api
cd apps/mobile && flutter analyze
cd apps/mobile && flutter test
```

For release verification:

```bash
pnpm mobile:env:sync
pnpm mobile:apk
```

## Environment Notes

- Backend: NestJS API
- Database: Prisma with PostgreSQL
- Mobile app: Flutter
- API deployment: Vercel on commit/push
- Mobile builds: local Android Studio/Xcode or local scripts
- Flutter build-time env should come from `apps/mobile/.env`

## Agent Instruction

Before making changes, read this README, `AGENTS.md`, and the repo-local PDF. Do not rely on removed docs, memory from older phases, or non-PDF ideas. Work only from the tracker above and update this README whenever a requirement status changes.
