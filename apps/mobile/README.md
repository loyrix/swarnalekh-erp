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
flutter build web --dart-define-from-file=.env
flutter build apk --release --dart-define-from-file=.env
```

Create `apps/mobile/.env` from `apps/mobile/.env.example` before running builds:

```bash
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key
API_BASE_URL=https://swarnalekh-erp-api.vercel.app/api/v1
```

Supabase is currently only the mobile login provider. API authorization uses a
provider-neutral bearer JWT, so the backend can move to another auth provider
or AWS-hosted Postgres without changing the ERP module code.

From the repository root, these commands read `apps/mobile/.env` automatically:

```bash
pnpm mobile:web
pnpm mobile:apk
pnpm mobile:aab
```

Android Studio Gradle builds also read `apps/mobile/.env`. For Android Studio Flutter run configurations, add this once under Additional run args if the IDE does not pick up Gradle settings:

```bash
--dart-define-from-file=.env
```

## Build And Test Approach

GitHub Actions are not configured. Build and test locally through Flutter, Android Studio, Xcode, and the tracked pre-commit hook.
