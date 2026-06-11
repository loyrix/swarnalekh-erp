# SwarnaLekh Flutter App

## Source Of Truth

The Flutter app must follow:

`/Users/satyamjaiswal/Downloads/Jewellery ERP System Flow (1).pdf`

## Active Screens

Primary navigation should expose only PDF-aligned product areas:

- Dashboard
- Inventory
- Mortgage / Gold Loan
- Billing / Invoice
- Reports where implemented

Supporting screens:

- Login
- Registration / shop setup
- Settings or user management for Admin only

Do not expose placeholder screens for schemes, ledger, subscription, or super-admin flows.

## PDF UI Rules

- Minimal clicks
- Large buttons
- Simple tables
- Fast forms
- Mobile responsive
- Clean spacing
- Easy navigation
- Search visible everywhere
- Important actions highlighted
- Simple dashboard
- Readable fonts
- Avoid cluttered screens
- Clear icons
- Keep forms short and fast

## Dashboard Requirements

Show:

- Total gold stock
- Total silver stock
- Total inventory value
- Monthly revenue
- Pending mortgage interest
- Active mortgage loans
- Today's sales
- Total bills generated

Quick actions:

- Add Stock
- Create Bill
- Add Mortgage
- Search Product
- Search Customer

## Inventory Requirements

Use a table/list first experience with:

- Search product
- Search design number
- Filters
- Add Stock
- Product Details
- Sold Products
- Stock Reports

## Mortgage Requirements

Add screens for:

- Mortgage dashboard
- Add Mortgage
- Active Loans
- Collect Interest
- Closed Loans
- Mortgage Reports

## Billing Requirements

Add screens for:

- New Bill
- Product search and selection
- Bill calculation
- Payment method selection
- Invoice generation
- Invoice history

## Commands

```bash
flutter pub get
flutter analyze
flutter test
flutter build web \
  --dart-define=SUPABASE_URL=<supabase-url> \
  --dart-define=SUPABASE_ANON_KEY=<supabase-anon-key> \
  --dart-define=API_BASE_URL=<api-base-url>
flutter build apk --release \
  --dart-define=SUPABASE_URL=<supabase-url> \
  --dart-define=SUPABASE_ANON_KEY=<supabase-anon-key> \
  --dart-define=API_BASE_URL=<api-base-url>
```

## GitHub Actions Build Config

The build workflow only creates artifacts. It does not deploy.

Set these repository variables or secrets before running the workflow:

- `API_BASE_URL`: Vercel API URL ending in `/api/v1`
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

Artifacts produced:

- `swarnalekh-web`
- `swarnalekh-android-apk`
- `swarnalekh-android-aab`
