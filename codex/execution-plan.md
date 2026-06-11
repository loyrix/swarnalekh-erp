# SwarnaLekh PDF-Aligned Execution Plan

## Source Of Truth

This plan follows:

`/Users/satyamjaiswal/Downloads/Jewellery ERP System Flow (1).pdf`

The execution target is a jewellery ERP with:

- Login and role access
- Dashboard
- Inventory
- Mortgage / gold loan
- Billing and invoices
- Operational reports
- Search and filters
- Mobile responsive UI
- Security basics

## Execution Rule

Do not add modules outside the PDF.

Removed from active planning:

- Schemes
- Ledger
- Subscription tiers
- Standalone multilingual roadmap
- Offline sync
- Super-admin workflow
- External rate provider workflow

## Phase 0: Documentation Alignment

Purpose: make repository documents match the PDF.

Tasks:

- Mark the PDF as source of truth.
- Replace old plans with PDF module plans.
- Remove docs for non-PDF plans.
- Update current status and next work order.

Exit condition:

- No planning document promotes a non-PDF module as active scope.

## Phase 1: Navigation And Shell Alignment

Purpose: make the visible product match the PDF.

Tasks:

- Expose Dashboard, Inventory, Mortgage, Billing, and Reports where implemented.
- Hide placeholder Schemes and Ledger navigation.
- Remove active product promises not present in the PDF.
- Add Add Stock, New Bill, Add Mortgage, Search Product, and Search Customer quick actions.

Exit condition:

- Users see only PDF-aligned primary modules.

## Phase 2: Dashboard

Purpose: provide the PDF dashboard summary.

Tasks:

- Total gold stock
- Total silver stock
- Total inventory value
- Monthly revenue
- Pending interest amount
- Active mortgage loans
- Today's sales
- Total bills generated
- Quick actions

Optional:

- Monthly sales graph
- Gold stock trend
- Loan collection graph
- Daily billing summary

Exit condition:

- Dashboard answers the PDF summary questions without unrelated modules.

## Phase 3: Inventory

Purpose: complete the PDF inventory flow.

Tasks:

- Inventory dashboard
- Add stock form
- Inventory table with PDF columns
- Search product and design number
- Filters by category, branch, and status
- Product details page
- Sold products page
- Stock reports
- Automatic stock status update after billing

Exit condition:

- Staff can add, search, inspect, and trust product status.

## Phase 4: Mortgage / Gold Loan

Purpose: complete the PDF mortgage flow.

Tasks:

- Mortgage dashboard
- Add mortgage form
- Active loans
- Collect interest
- Receipt generation
- Pending balance update
- Next due date display
- Close loan
- Closed loans page
- Mortgage reports

Exit condition:

- Staff can create loans, collect interest, and close loans without manual balance tracking.

## Phase 5: Billing And Invoice

Purpose: complete the PDF billing flow.

Tasks:

- New bill flow
- Customer details
- Inventory search and product selection
- Auto-filled product data
- Bill table
- Gold value, making charges, GST, final total
- Payment method selection
- Invoice generation
- Inventory reduction
- Invoice history
- Reprint, PDF download, WhatsApp share where feasible

Exit condition:

- A bill can be generated and inventory is updated automatically.

## Phase 6: Reports

Purpose: add PDF-defined operational reports only.

Inventory:

- Current stock
- Sold products
- Low stock

Billing:

- Daily sales
- Monthly sales
- GST

Mortgage:

- Active loans
- Interest collection
- Closed loans

Exit condition:

- Reports match the PDF and do not become a separate analytics product.

## Phase 7: Security And Polish

Purpose: make the system usable by real staff.

Tasks:

- Role-based access for Admin and Staff
- Activity logs for important actions
- Data backup plan
- Invoice protection
- Loading and error states
- Touch-friendly forms
- Responsive tables
- Search visible everywhere

Exit condition:

- The app feels simple, fast, and professional for shop usage.
