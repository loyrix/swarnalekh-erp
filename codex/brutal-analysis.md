# SwarnaLekh Gap Analysis Against The PDF

## Source Of Truth

This analysis follows:

`/Users/satyamjaiswal/Downloads/Jewellery ERP System Flow (1).pdf`

## Main Finding

The repository had grown around a broader jewellery SaaS idea. The PDF is narrower and clearer:

- Inventory
- Mortgage / gold loan
- Billing / invoice
- Dashboard
- Reports
- Search/filter
- Admin/Staff access

The biggest current risk is not missing breadth. The risk is that the visible app still contains or documents modules that the PDF does not ask for.

## Product Gaps

### Navigation

Current risk:

- Non-PDF modules can appear as active promises.

Needed:

- Remove placeholder navigation for schemes and ledger.
- Add Mortgage as a first-class visible module.
- Keep Reports only for PDF-defined reports.

### Inventory

Needed from PDF:

- Table-first inventory
- Product image, name, category, design number, purity, gross weight, net weight, selling price, status, branch, actions
- Add stock form with product, weight, price, and image sections
- Product details page
- Sold products page
- Stock reports

### Mortgage

Backend foundation exists.

Needed:

- Flutter screens
- Dashboard cards
- Add mortgage form
- Active loans list
- Collect interest flow
- Closed loans list
- Payment receipt display
- Mortgage reports

### Billing

Needed from PDF:

- Customer details
- Inventory search
- Product selection
- Auto-filled product data
- Bill table
- Gold value, making charges, GST, final total
- Payment methods
- Invoice history search
- PDF download and WhatsApp share where feasible

### Reports

Reports must be constrained to:

- Current stock
- Sold products
- Low stock
- Daily sales
- Monthly sales
- GST
- Active loans
- Interest collection
- Closed loans

## Technical Gaps

- Confirm all PDF workflows are tenant-scoped.
- Confirm invoice creation and inventory reduction are transactional.
- Confirm mortgage payment and balance updates are transactional.
- Add service tests where missing.
- Add Flutter tests for key visible assumptions.

## Removed Ideas

These should stop shaping implementation:

- Subscription tiers
- Schemes
- Ledger
- Offline sync
- Standalone multilingual roadmap
- Super-admin
- External rate automation

## Recommended Next Move

Make the visible app match the PDF first:

1. Navigation cleanup.
2. Mortgage UI entry.
3. Dashboard quick actions.
4. Inventory table/product detail/sold products alignment.
5. Billing invoice history and payment flow alignment.
