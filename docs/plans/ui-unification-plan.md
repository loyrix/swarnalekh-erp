# SwarnaLekh — End-to-End Completion Plan

> **Living tracker.** Update the Status columns and check boxes as work lands.
> **Goal is not just UI** — it is a fully functional, tested product. A phase is **DONE only when
> 100% end-to-end**: UI polished on the shared kit, backend complete & correct, typed models,
> all 4 UI states (loading/empty/error/success), l10n (en/hi/gu), widget + logic + API tests
> covering edge cases, `flutter analyze` clean, `flutter test` + `apps/api` Jest green,
> README tracker updated. No half-migrations, no "code exists" ≠ done.

**Ordering (owner's rule):**

1. **Stage A** — features that are already **complete** → polish UI & design to perfection.
2. **Stage B** — features that are **partially complete** → finish functionality + polish.
3. **Stage C** — features **remaining** → build from scratch, functional + tested.

**Prerequisite:** **Stage 0** builds the shared design-system kit + tokens first, so every polish/build
in A–C is uniform and never redone. (This is the only thing that must precede the owner's ordering.)

**Layout style (recommended, agreed):** hybrid — keep low-click tabbed module screens
(`SectionSwitch`) for browsing; move heavy create/edit forms to **full-screen routes** (not fixed-width dialogs).

**Sources:** [PDF](../source-of-truth/jewellery-erp-system-flow.pdf) · [PRODUCTION_BLOCKERS](../../PRODUCTION_BLOCKERS.md) · [AGENTS](../../AGENTS.md)

---

## Completion matrix (drives the ordering)

| Feature                                                          | API                                                                   | Mobile UI           | Tests   | Class         |
| ---------------------------------------------------------------- | --------------------------------------------------------------------- | ------------------- | ------- | ------------- |
| Dashboard                                                        | ✅ bootstrap/stats                                                    | ✅                  | ✅      | A (polish)    |
| Inventory                                                        | ✅ 10 routes                                                          | ✅                  | ✅      | A (polish)    |
| Mortgage (+partial payments)                                     | ✅ 8 routes                                                           | ✅                  | ✅      | A (polish)    |
| Reports                                                          | ✅ overview/export                                                    | ✅                  | ✅      | A (polish)    |
| User Mgmt / Shop Profile / Rates / Customers                     | ✅                                                                    | ✅                  | partial | A (polish)    |
| Billing / Invoice                                                | ✅ `/preview` + `FOR UPDATE` lock + idempotency (server-only pricing) | ✅                  | ✅      | ✅ B1 done    |
| Security (audit/backup/invoice protection)                       | ✅ global audit interceptor + soft-delete-safe `forTenant`            | ✅                  | ✅      | ✅ B2 done    |
| Auth onboarding (email/pass + Google/Apple)                      | 🟡 self-owned `/auth/register`+`/auth/login` (B3a); Google/Apple B3c  | ✅ email/pass (B3b) | ✅      | B (finish)    |
| Invoice partial-payments                                         | ❌ model only                                                         | ❌                  | ❌      | C (scratch)   |
| Robust PDF / CSV-Excel export / image storage / full-text search | ❌                                                                    | ❌                  | ❌      | C (hardening) |

---

## Progress Overview

| Phase  | Title                                                                      | Status                                         |
| ------ | -------------------------------------------------------------------------- | ---------------------------------------------- |
| 0      | Foundation: tokens, cleanup, design-system kit + tests                     | ✅ Done (2026-07-01)                           |
| **A1** | Dashboard — polish                                                         | ✅ Done (2026-07-01)                           |
| **A2** | Inventory — polish                                                         | ✅ Done (2026-07-01)                           |
| **A3** | Mortgage — polish                                                          | ✅ Done (2026-07-01)                           |
| **A4** | Reports — polish                                                           | ✅ Done (2026-07-01)                           |
| **A5** | Support screens (User Mgmt, Shop Profile, Rates, Customers) — polish       | ✅ Done (2026-07-01)                           |
| **B1** | Billing/Invoice — finish (server pricing + integrity) + polish             | ✅ Done (2026-07-01)                           |
| **B2** | Security — finish (global audit, backup, invoice protection) + polish      | ✅ Done (2026-07-02)                           |
| **B3** | Auth onboarding — self-owned email/password + Google/Apple (drop Supabase) | 🟡 B3a+B3b done; B3c Google/Apple (2026-07-02) |
| **C1** | Invoice partial-payments — build                                           | ⬜                                             |
| **C2** | Robust invoice PDF generation — build                                      | ⬜                                             |
| **C3** | CSV/Excel export — build                                                   | ⬜                                             |
| **C4** | Image storage → Supabase Storage — build                                   | ⬜                                             |
| **C5** | Full-text search — build                                                   | ⬜                                             |
| **V**  | Visual-richness redesign pass (final, post-migration)                      | ⬜                                             |

Legend: ⬜ Not started · 🟡 In progress · ✅ Done (full DoD) · ⏸️ Blocked

---

## Design principles (every phase)

1. One widget per concept — no two screens implement the same pattern differently.
2. Search always visible; advanced filters in a bottom sheet.
3. Heavy forms = full-screen routes, keyboard-safe, sticky save bar. AlertDialog only for ≤3 fields / confirmations.
4. Typed models, not `Map<String,dynamic>`.
5. All 4 states on every data view.
6. Every user-facing string localized (en/hi/gu).
7. Backend owns all money/weight/tax/stock math; UI shows server numbers.
8. Large touch targets, minimal vertical waste on phones.

---

## Stage 0 — Foundation (must precede A–C) — ✅ DONE 2026-07-01

**Why first:** the polish in Stage A must be uniform; building it per-screen then unifying later wastes the work.

**Reality corrections found during build (verify-before-assume):**

- Design tokens **already existed** (`AppSpacing`, `AppRadius`, `AppShadows`) — only added the missing canonical breakpoint helper.
- A staff redirect guard **already existed** in `app_shell` but was load-time only — refactored to a pure `isRestrictedRoute` and now also enforced on mid-session navigation.
- The shared library was **already rich** (`CompactDataRow`, `CompactStatStrip`, `EmptyState`, `Shimmer*`, `SearchFilterBar`, `KeyboardAwareScrollView`, `GoldButton`, `SectionSwitch`) — so the kit **composes/adopts** these rather than rebuilding, avoiding a 3rd parallel system.

- [x] `AppBreakpoints` + `AppDensity.isCompact/isExpanded/pick` in [app_theme.dart](../../apps/mobile/lib/core/theme/app_theme.dart) (replaces 9 scattered width thresholds) — `test/app_breakpoints_test.dart`.
- [x] Cleanup off-plan empty scaffolding: mobile `features/{schemes,ledger,notifications,staff,stage}` + API empty dirs `{scheme,ledger,notification,subscription,sync,audit,rate,user}` removed. **Kept `apps/super-admin`** and empty in-scope `features/settings`. Verified zero imports first.
- [x] Staff admin-only-route guard: pure `isRestrictedRoute(role, location)` in [app_permissions.dart](../../apps/mobile/lib/features/auth/application/app_permissions.dart) + `didUpdateWidget` enforcement in [app_shell.dart](../../apps/mobile/lib/shared/layouts/app_shell.dart) — tests in `test/app_permissions_test.dart`.
- [x] **Design-system kit** in `shared/widgets/`, each with widget tests; one-stop barrel [app_kit.dart](../../apps/mobile/lib/shared/widgets/app_kit.dart):

| Widget                                 | Status        | Purpose                                                                               |
| -------------------------------------- | ------------- | ------------------------------------------------------------------------------------- |
| `CompactStatStrip` (adopted canonical) | ✅ existing   | one responsive stat display                                                           |
| `CompactDataRow` (adopted canonical)   | ✅ existing   | canonical touch row (replaces DataTables)                                             |
| `AppFilterSheet`                       | ✅ new + test | advanced filters in a bottom sheet (search stays on-screen)                           |
| `AppFormScaffold`                      | ✅ new + test | full-screen keyboard-safe form route + sticky save bar (replaces fixed-width dialogs) |
| `AppSectionScaffold`                   | ✅ new + test | module page: header + `SectionSwitch` + pull-to-refresh + body                        |
| `AppDetailSheet`                       | ✅ new + test | standard read-only detail                                                             |
| `AppStateView`                         | ✅ new + test | `AsyncValue` → shimmer / empty / error+retry / data                                   |

- [x] l10n added (en/hi/gu): `commonRetry/ErrorTitle/ErrorBody/Filters/Clear/Apply`; `flutter gen-l10n` run.
- [x] **Verified:** `flutter analyze` clean; `flutter test` = 64 passed. (API untouched beyond deleting empty dirs → no build impact.)

**Stage 0 DoD:** ✅ met. No feature screen redesigned yet — that begins in Stage A.

---

## Stage A — Polish completed features (functional already; make UI perfect + re-verify)

> Each A-phase: migrate the screen onto the kit, introduce typed models, ensure 4 states + l10n,
> add/upgrade widget tests, keep existing API tests green. "Polish" here = uniform, compact, touch-first,
> plus fixing any small correctness nits found (e.g. remove "(Mock)" label, price-display consistency).

### A1 — Dashboard

- [ ] `AppStatStrip` for the summary cards (PDF: gold/silver wt, revenue, pending interest, active loans, today's sales, bills).
- [ ] Quick actions → horizontal chip row routing into full-screen forms (Add Stock / New Bill / Add Mortgage / Search).
- [ ] Trim welcome banner on mobile; remove "(Mock)" chart label; ensure displayed selling price matches billing (consistency nit from blocker #3).
- [ ] Tests: stat rendering, empty/error state, role-based quick actions.

### A2 — Inventory (2,454-line file)

- [ ] Typed `InventoryItem` model (kill ~20 `Map` reads).
- [ ] `AppSectionScaffold` tabs: Stock · Sold · Reports. Replace **3 DataTables** with `AppListRow`.
- [ ] Add/Edit Stock → full-screen `AppFormScaffold` route (Product/Weight/Price/Image, auto net-weight & price preview), reused by dashboard quick action. Detail via `AppDetailSheet`. Filters via kit.
- [ ] Decompose into `inventory_stock_tab.dart`, `inventory_sold_tab.dart`, `inventory_form_page.dart`, `inventory_detail_sheet.dart`, `ocr_review_page.dart` (<400 lines each).
- [ ] Edge tests: empty/ no-results; no image / missing purity / zero stone wt / qty>1; long names, ₹ formatting, decimals; add/edit/delete(soft) reflects in list & billing; filter combos.

### A3 — Mortgage (1,353-line file)

- [ ] Typed `MortgageLoan` / `Payment` models (kill ~13 `Map` reads).
- [ ] `AppSectionScaffold` tabs: Active · Closed · Reports. Replace 150px metric boxes with compact `AppListRow`.
- [ ] Add Mortgage + Collect Interest → full-screen `AppFormScaffold` routes (Customer/Gold/Loan). Loan detail + receipt via `AppDetailSheet`. `AppStatStrip` for dashboard cards.
- [ ] Edge tests: partial vs full collection → outstanding updates; full → moves to Closed; optional KYC/photo; empty lists; interest across overdue.

### A4 — Reports

- [ ] `AppFilterBar` + sheet (was 6 inline fields). Report rows → `AppListRow`. Keep Inventory/Billing/Mortgage groups.
- [ ] Confirm staff cannot reach (guard from Stage 0).
- [ ] Tests: filter emits correct query; group rendering; empty state.

### A5 — Support screens (User Mgmt, Shop Profile, Rates, Customers)

- [ ] Migrate each onto the kit (list rows, forms as routes where heavy, stat/detail patterns). Typed models. l10n. 4 states.
- [ ] Customers: split the single 555-line file if it grows; ensure used consistently by billing & mortgage pickers.
- [ ] Tests: CRUD flows, validation, empty/error.

**Stage A DoD (per phase):** screen on kit, typed models, 4 states, l10n, widget tests for listed edges, analyze + `flutter test` green, README updated.

---

## Stage B — Finish partially-complete features (functionality + polish + tests)

### B1 — Billing / Invoice (biggest; correctness + UI)

Backend first (removes UI-vs-charged drift and oversell):

- [ ] `POST /invoices/preview` — same DTO as create, returns server-computed line items + totals (gold value/making/GST/final) via existing `calculateItemPrice`/`calculateInvoiceTotals`. Jest tests.
- [ ] `FOR UPDATE` row lock on unique-item stock check in invoice creation (blocker #4). Jest concurrency test.
- [ ] Idempotency key on `POST /invoices` (blocker #5). Jest duplicate-submit test.
      Mobile:
- [ ] Typed `Invoice`/`InvoiceLine` models (kill ~29 `Map` reads). "New Bill" calls `/preview` (debounced) and **shows server totals**; relegate [billing_pricing_calculations.dart](../../apps/mobile/lib/features/billing/application/billing_pricing_calculations.dart) to optimistic hint or delete.
- [ ] `AppSectionScaffold`: New Bill · History · Reports. New Bill = full-screen `AppFormScaffold` route (customer → product search/add → live preview → payment → generate); no 720/860px dialogs. Replace bill-preview DataTable with compact rows. Detail via `AppDetailSheet` (keep print/pdf/share/WhatsApp). `AppStatStrip`.
- [ ] Edge tests: multi-item, qty>1, old-gold exchange, GST on/off, rounding; sold-item reselling blocked; preview total == created total (assert equality); history filters.

### B2 — Security (audit / backup / invoice protection)

- [ ] Make `AuditLogInterceptor` **global** (blocker: currently opt-in) — verify tenant-scoped, no PII leak. Jest test it fires on mutations.
- [ ] Activity-logs screen on the kit (list rows + filters); wire `GET security/activity-logs` with pagination.
- [ ] Backup: expose/verify `GET security/backup` flow in UI; confirm scope & auth.
- [ ] Invoice protection: verification code/QR already on PDF — confirm the verify path is reachable & documented.
- [ ] Soft-delete: auto-filter `deletedAt: null` in `PrismaService.forTenant()` (blocker #6) + regression test that soft-deleted rows never surface.

### B3 — Auth onboarding

- [ ] Password reset flow (request + confirm) end-to-end (screen + endpoint/Supabase).
- [ ] Harden register: idempotent tenant creation; clear error states; ensure `tenant/register` + Supabase user creation are consistent (webhook or in-app).
- [ ] Tests: register happy path + duplicate; reset flow; unauthenticated redirects.

**Stage B DoD:** functionality complete & correct (blockers closed), UI on kit, typed models, l10n, widget + API tests for edges, both test suites green.

---

## Stage C — Build remaining from scratch

### C1 — Invoice partial-payments

- [ ] `Payment` module for invoices: `POST /invoices/:id/payments`, list, receipt (mirror mortgage payments). Update invoice balance/status transactionally. Jest tests.
- [ ] Mobile: record-payment form + payment history on invoice detail. Widget tests.

### C2 — Robust invoice PDF generation

- [ ] Replace hand-rolled `renderTextPdf` with a real PDF lib (pagination, Unicode/RTL, font embedding, logo/QR/GST). Snapshot/golden test on a long, special-char invoice.

### C3 — CSV/Excel export

- [ ] Add CSV (and/or xlsx) export to reports alongside PDF; server endpoint + mobile export menu. Tests on row/format correctness.

### C4 — Image storage → Supabase Storage

- [ ] Move shop logo, inventory photos, mortgage KYC from base64-in-DB to Supabase Storage (signed URLs, CDN). Strip images from list queries; add size validation + compression. Migration + tests.

### C5 — Full-text search

- [ ] PostgreSQL `tsvector` search for products/customers/invoices (replace `ILIKE`). Index + query + tests; wire into the unified `AppFilterBar`.

**Stage C DoD:** each feature functional end-to-end, UI on kit where user-facing, tests covering edges, suites green, README updated.

---

## Stage V — Visual-richness redesign pass (FINAL, after all migrations)

> Owner decision (2026-07-01): migrations use the current compact kit now; a dedicated
> visual pass comes last so every screen inherits the upgrade at once via the shared kit.

**Owner's design constraints (must honor):**

- **NOT big cards.** This is a phone + tablet app — large cards waste space and show less. Keep rows compact.
- Goal is **"more detail, easily, with rich UI/UX"** — increase information density _and_ visual quality at the same time (better typography hierarchy, spacing, color/status cues, thumbnails, glanceable key figures), without making items taller.
- Richness lives in both the **compact list row** (denser but clearer) and the **detail sheet** (fully rich).
- Uniform across the app — upgrade the shared kit widgets (`CompactDataRow`, `CompactStatStrip`, `AppDetailSheet`, empty/section headers), not per-screen, so all screens change together.

**Scope:** redesign the shared kit visuals only (no feature-logic changes), then visually QA every screen at 375 / 393 / 768 / 1280. Keep all tests green.

---

## Verification commands (per phase, before ✅)

```bash
cd apps/mobile && flutter gen-l10n
cd apps/mobile && flutter analyze
cd apps/mobile && flutter test
pnpm --dir apps/api test --runInBand      # when API touched
pnpm vercel:build:api                      # before closing a stage
```

Manual matrix: iPhone SE (375) · iPhone 15 (393) · iPad Mini (768) · Desktop (1280):
no horizontal overflow, forms usable with keyboard open, bottom nav visible, tap targets ≥44px.

---

## Resume pointer (update at end of each work session)

- **Current phase:** B3 — Auth onboarding — 🟡 **PIVOT: dropping Supabase, owning auth ourselves.** Owner decision (2026-07-02): email/password register+login + Google/Apple OAuth, no Supabase dependency; mobile-OTP deferred to the very end. OAuth creds not ready → Google/Apple scaffolded behind env config; existing users migrated (nullable password, admin-set); password reset = admin-set for now. Phased: **B3a backend (DONE)** → **B3b mobile swap (DONE)** → B3c Google/Apple + env cleanup.
- **B3a DONE (2026-07-02, pushed 2924b93):** the existing `JwtAuthGuard` already verifies HS256 tokens signed with `AUTH_JWT_SECRET`/`JWT_SECRET` (Supabase JWKS is only the RS256/ES256 fallback), so issuing our own HS256 JWT needed **no guard change**. Added `auth.token.ts` (pure `signAuthToken`, 30-day TTL), `auth.dto.ts`, `auth.service.ts` `register()`/`login()`/`hashPassword()`; `@Public POST /auth/register`+`/auth/login`. Admin-set password in user-management (`PATCH /users/:id/password` + optional password on create). Dep `bcryptjs`. **api 68 → 81.** Owner confirmed reusing the existing `JWT_SECRET` env (fallback) — no new var needed.
- **B3b DONE (2026-07-02, committed):** mobile fully off Supabase (only `main.dart` + `auth_provider.dart` used it). New `features/auth/data/models/{auth_user,auth_session}.dart`, `data/auth_repository.dart` (`RegisterRequest`, `login`/`register`), `application/auth_controller.dart` (`Notifier<AuthState>`; JWT in `flutter_secure_storage`, seeds `ApiClient`, login/register/logout). `main.dart` restores token pre-frame via `initialAuthTokenProvider` override (no login flash); removed `Supabase.initialize`. `ApiClient.onUnauthorized` → 401-on-authed-request auto-logout. Router simplified (login/signup only; **`/register` + registration-check removed**). `signup_screen` is now the full register form (shop+owner+email+password). **Deleted** `auth_provider.dart`/`registration_screen.dart`/`otp_screen.dart`; **removed `supabase_flutter`**. Tests `auth_models_test`+`auth_screens_test`. Verified analyze clean, **flutter test 133 → 141**, web build green (needed `flutter clean` — stale web_plugin_registrant referenced Supabase's removed transitive plugins). Leftover: mobile `.env`/`sync_mobile_env.mjs` still pass SUPABASE defines (ignored now) + backend `/tenant/register` unused — clean up in B3c.
- **Prev — B2 Security ✅ (2026-07-02, pushed b026ccc):** `forTenant` soft-delete hardening (`scopeReadWhere`) + activity-log screen migrated onto kit (524 → ~380). audit interceptor was already global; api 62 → 68, flutter test 133. See git history + memory.
- **B1 done (2026-07-01, committed+pushed 30595e1):** Billing server pricing (`/invoices/preview`), `FOR UPDATE` lock, idempotency; mobile billing migrated onto kit (screen 2,005 → ~430), client pricing deleted. See git history + memory for detail.
- **Prev:** A5 Support screens complete; Stage A fully done & pushed (…ba32372). **Customers** (555→163): typed `Customer` + repo + provider, `AppStateView`, `CompactDataRow` rows, form → `AppFormScaffold` route (`customer_form_page`). **User Management** (557→285): `UsersRepository`+provider, `AppStateView`, `CompactDataRow` rows + `ItemActionsMenu`, form → route (`user_form_page`), kept onboarding tip + admin-only guard + deactivate confirm. **Rates** + **Shop Profile/Tenant**: light polish (already clean single-form screens — added real error+retry state via `AppErrorView`, `GoldButton`/app_kit). Verified: mobile analyze clean, `flutter test` = 111 (+8), api unchanged (59).
- **Prev:** A4 Reports (987→478); A3 Mortgage (1,353→344); A2 Inventory (2,454→699); A1 Dashboard (real sales trend). Screen decomposed **987 → 478 lines**: 7 typed report models + `ReportsData` (`reports_data.dart`) + `ReportsRepository` (+`ReportsQuery`) + Riverpod family provider; screen now `ConsumerStatefulWidget` on `AppSectionScaffold` (Inventory/Billing/Mortgage groups) + `AppStateView`; the **6-field filter bar → `AppFilterSheet`** (search stays on-screen); report rows now render via **`CompactDataRow`** through a reusable `ReportSection` widget (+`ReportRow` view-model); typed-model→row mappers keep the screen `Map`-free; admin-only empty-state kept (guard covers `/reports`). No new l10n needed. Verified: mobile analyze clean, `flutter test` = 103 (+7), api unchanged (59).
- **Prev:** A3 Mortgage complete — 1,353 → 344 lines; A2 Inventory — 2,454 → 699; A1 Dashboard — real 7-day sales trend + kit. Screen decomposed **1,353 → 344 lines**: typed `MortgageLoan`/`Ornament`/`Payment`/`Dashboard` + `MortgageRepository` (+`MortgageQuery`) + Riverpod providers; screen now `ConsumerStatefulWidget` on `AppSectionScaffold` (Active/Closed/All) + `AppStateView`; **tall StatCard + 150px metric boxes replaced** with `CompactStatStrip` + `CompactDataRow` loan rows; create loan / collect payment / close loan → full-screen `AppFormScaffold` routes (`mortgage_form_page`/`collect_payment_page`/`close_loan_page`, KYC image + loan-date preserved, shared `mortgage_form_helpers`); loan detail + payment receipts + Collect/Close via `AppDetailSheet` (`mortgage_detail_sheet`). Verified: mobile analyze clean, `flutter test` = 96 (+11), api unchanged (59).
- **Prev:** A2 Inventory complete (2026-07-01). Screen decomposed **2,454 → 699 lines**; all 3 DataTables → `CompactDataRow`; forms → full-screen routes; OCR strings localized. Screen decomposed **2,454 → 699 lines** across typed model/repo/providers + `inventory_form_page` (full-screen `AppFormScaffold` route, pricing auto-calc + image upload preserved) + `ocr_review_page` (full-screen route, **DataTable removed**, hardcoded OCR strings localized) + `inventory_detail_sheet` (`AppDetailSheet`) + `inventory_format`. Screen now `ConsumerStatefulWidget` on `AppSectionScaffold` + `AppStateView`; **all 3 DataTables replaced with `CompactDataRow`** (mobile & wide); filters in `AppFilterSheet`; search always visible. New l10n (en/hi/gu) for OCR fields + generic validations. Verified: mobile analyze clean, `flutter test` = 85 (+14), api unchanged (59).
- **Prev:** A1 Dashboard complete (2026-07-01). Delivered: real **7-day salesTrend** in backend `dashboard.getStats` (+ spec; replaced fabricated chart data); typed `DashboardData`/`DashboardStats`/`SalesTrendPoint` + `DashboardRepository` + Riverpod `dashboardProvider`; screen rewritten as `ConsumerWidget` on `AppStateView` (real loading/error+retry/data), unified `CompactStatStrip` (retired tall `_DashboardStatCard`), **localized date** via `intl DateFormat` (removed hardcoded English month/day arrays), cleaned quick actions (removed bogus `/reports?focus=search`). Verified: mobile analyze clean, `flutter test` = 71, `apps/api` test = 59.
- **Next action:** B3c — Google & Apple sign-in on mobile + backend token verifiers, scaffolded behind env config (light up when Google client IDs / Apple service ID are added). Also clean up leftover Supabase env plumbing (mobile `.env`, `sync_mobile_env.mjs`) and the now-unused `/tenant/register`. Await owner "go".
- **A2 follow-up (minor):** `inventory_form_page.dart` (821) and `inventory_list_screen.dart` (699) exceed the 400-line target but are cohesive; split further only if they grow. Inventory "Reports" tab (PDF stock-reports) not built — no backend endpoint yet; revisit in reports/hardening.
- **Deferred nit:** ✅ resolved in B1 — all client-side Dart pricing removed (`billing_pricing_calculations.dart` deleted); the server is the sole pricing source, so dashboard/invoice totals can no longer drift.
- **Open questions for owner:** none. Awaiting "go" to start B3 (Auth onboarding).
- **Kit usage note:** import `package:swarnbook/shared/widgets/app_kit.dart` in feature screens; do not build bespoke stat/row/form/filter widgets.
