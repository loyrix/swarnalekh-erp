# Refinement Plan — July 2026 (Onyx Champagne + Page-by-Page Requirements)

> Source requirements: [docs/requirements/2026-07-12-page-by-page-requirements.md](../requirements/2026-07-12-page-by-page-requirements.md)
> Theme: **Onyx · Champagne** ([design concept](../design-concepts/06-onyx-champagne.html)) — see requirements §0 for tokens + type decision (no custom serif; platform sans, semibold, tabular numerals).
>
> Workflow: same rules as [ui-unification-plan.md](ui-unification-plan.md) — phase-by-phase, each phase 100% end-to-end (typed models, 4 UI states, l10n en/hi/gu, tests, analyze/test green) before the next. **Do not start a phase until owner says go.**
>
> **Resume pointer: R0 + R1 COMPLETE, committed (210b7ec theme, 7b49033 categories). Next up = R2 Add Inventory rework (awaiting owner go).**

## Phase overview & ordering

Ordering follows the shared-foundation-first rule: theme tokens (R0) and the category/tag backend (R1) underpin everything else; then page phases in walkthrough order.

| Phase | Scope                                                                                   | Depends on          | Status             |
| ----- | --------------------------------------------------------------------------------------- | ------------------- | ------------------ |
| R0    | Onyx Champagne theme migration (tokens + kit)                                           | —                   | ✅ done 2026-07-13 |
| R1    | Category master + per-shop tag sequences + min-stock thresholds (backend + settings UI) | —                   | ✅ done 2026-07-13 |
| R2    | Add Inventory form rework (req §1)                                                      | R1                  | ⬜ not started     |
| R3    | HUID receipts rework (req §2)                                                           | R1                  | ⬜ not started     |
| R4    | View Inventory + Sold Products rework (req §3–4)                                        | R1 (categories), R0 | ⬜ not started     |
| R5    | Dashboard rework (req §5 + out-of-stock tile)                                           | R1 (thresholds), R0 | ⬜ not started     |

---

## R0 — Onyx Champagne theme migration

Swap the app's visual tokens to Onyx Champagne app-wide via `app_theme.dart` (no per-screen restyling — the kit propagates it).

- Map concept CSS vars → `AppColors` (light+dark): bg/surface/surface-2/border/line, text/muted/faint, accent trio (`#9C7C3E`/`#6E5622`/`#C1A05C` light; `#C6A25E`/`#DCBE86` dark), accent tint/line, metal colours (gold/silver/platinum/diamond/rose), status ok/info/warn/danger.
- Radii: lg 8 / md 6 / sm 5 (squarer than current); 1px hairline borders; subtle shadow, no glow.
- Type: platform sans; semibold headings/figures; `FontFeature.tabularFigures()` for all amounts/weights.
- Kit alignment: 3px left accent bars on list rows (`CompactDataRow`), tinted icon tiles on stat tiles (`CompactStatStrip`), uppercase letter-spaced section labels with gold tick, pill-style selects/chips per concept.
- Verify every module screen in light + dark (golden-eye pass), no hardcoded old-palette colours left (`grep` old hex values).

**DoD:** analyze clean, flutter test green, both themes verified on all module screens; no functional changes.

## R1 — Category master, tag sequences, min-stock thresholds (foundation)

Backend + minimal settings UI that R2–R5 all depend on.

- **Category master list** (Prisma model, tenant-scoped, seeded): Ring RG, Chain CN, Mangalsutra MS, Necklace NK, Bangle BG, Bracelet BR, Earrings ER, Pendant PD, Anklet/Payal AK, Nose Pin NP, Kada KD, Haar HR, Maang Tikka MT, Toe Ring TR, Coin CO, Locket LK, Studs ST, Choker CH, Waist Chain WC, Armlet AR (+ owner-extensible). Fields: name, prefix (unique per tenant), minStockThreshold (int, default 0), active.
- **Tag generation:** per-shop (tenant) auto-increment per category — `PREFIX-<n>` from 01, natural growth (RG-99 → RG-100). Server-side, race-safe (tx + unique constraint on tag; same FOR-UPDATE pattern as invoice numbers). `InventoryItem.tagNumber` unique per tenant.
- **Endpoints:** categories CRUD (admin), used by dropdowns; tag assigned server-side on item create (manual + HUID import paths).
- **Settings UI:** simple category list screen (name, prefix, min-stock threshold) — AppFormScaffold/AppListRow, admin-only.
- Migration note: existing items keep old `barcode` value; tag backfill strategy = leave legacy items untagged (display '—') unless owner asks for backfill.

**DoD:** Prisma migration applied; API specs for sequence uniqueness/race, threshold CRUD; mobile settings screen typed + 4 states + l10n + tests; suites green.

## R2 — Add Inventory form rework (req §1)

- Remove Design Number field; add Category dropdown (from R1) + read-only auto Tag Number (assigned on save, shown in success/detail).
- Weight: single decimal-grams inputs (up to 5 dp), no pre-filled zeros, remove mg controls; Net Weight auto-calculated (gross − stone), read-only.
- Remove Price Details section and Branch field (branch comes from global dashboard-level context).
- Compact image section: camera + gallery capture, no URL field.

**DoD:** form on AppFormScaffold, validation, l10n, widget tests (incl. tag display + net-weight calc), API create path updated + specs, suites green.

## R3 — HUID receipts rework (req §2)

- Show Stone Weight explicitly beside Gross/Net in OCR review (deduction self-explanatory).
- Duplicate guard by HUID ID (per shop): block import if that HUID is currently in stock; allow re-entry once sold (buy-back). Server-side check + friendly client error.
- Category detection from scan → tag auto-generated via R1 on successful import; fallback = user picks category in review before import (open question: confirm fallback UX).
- Remove Quantity and Hallmark fields from review/import.

**DoD:** backend duplicate + tag logic w/ specs; review page updated, l10n, tests; suites green.

## R4 — View Inventory + Sold Products rework (req §3–4)

- **One filter surface:** single AppFilterSheet w/ search, metal, category (R1 dropdown), branch, status, time range; add direct Gold/Silver chips on the list; remove the sold-period widget from the stock tab (sold data lives only in Sold tab).
- **Backend fix:** sold-by-period must use actual sold/invoice date, not `updatedAt` (add `soldAt` or join invoice date); period filter must filter the visible sold list too.
- **Clickable stats:** Total Gold/Silver Weight → karat/purity breakdown sheet; Total Products → metal-wise counts (reuse `metalBreakdown`).
- Remove Out of Stock alert from this page (moves to Dashboard in R5).
- **Sold rows richer:** tag, category, metal/karat, net weight, sold amount, customer, invoice no, date — full row width.

**DoD:** backend sold-date fix + breakdown endpoints w/ specs; screens typed + 4 states + l10n + widget tests; suites green.

## R5 — Dashboard rework (req §5)

- Reorder: Overview details above Sales Trend graph.
- New **Out of Stock / Low Stock tile** driven by R1 per-category thresholds: clickable → list of categories (and their items) at/below threshold.
- Apply global branch selector context here (feeds R2's branch removal) — confirm exact UX with owner at phase start.

**DoD:** backend threshold-status endpoint + specs; dashboard typed + 4 states + l10n + tests; suites green.

---

## Cross-cutting notes

- `barcode` field: UI meaning changes from "Design Number" to nothing (tag lives in its own column). Keep the DB column for legacy data; stop writing it from the form.
- Remaining open questions (in requirements doc): scan-category fallback UX; whether consolidated time filter also filters the in-stock list. Resolve at R3/R4 phase start.
- Relationship to [ui-unification-plan.md](ui-unification-plan.md): C4 (Supabase image storage) and C5 (full-text search) remain parked; R0 effectively replaces/absorbs "Stage V visual richness" as the visual pass, in the Onyx Champagne theme.

## Status log

- 2026-07-13 — Plan created from requirements walkthrough §0–§5. No phase started.
- 2026-07-13 — **R0 COMPLETE.** All tokens swapped in `core/theme/app_theme.dart`: champagne accent set (static `primary` `#C6A25E`, light-mode `colorScheme.primary` → `primaryDark` `#9C7C3E`, on-accent ink text both modes), Onyx neutrals light+dark, status colours retuned (single static values readable on both modes), metals (silver slate `#959DA8`, platinum teal `#63A39A`, rose `#C27F69`), radii squared to 5/6/8/10/12, shadows → 1px hairlines (elevated 8px; goldGlow kept only for the solid primary action per concept), tonal-tile `secondaryContainer` retinted both modes, light focused-input border uses `primaryDark`. Typography: **google_fonts (Inter/Outfit) removed entirely** (dep dropped from pubspec) → platform sans, semibold headings, `FontFeature.tabularFigures()` on all text styles. Stray old-palette hardcodes retuned: login/signup background gradients, dashboard hero gradient, error_toast dark surface, shimmer base colours (brand_mark near-black kept). Verified: `flutter analyze` clean, `flutter test` 171/171 green, `flutter build web` green. On-device visual pass in both modes = owner review. NOT committed yet.
- 2026-07-13 — **R1 COMPLETE.** Backend: `Category` gains `prefix` (unique per tenant, NULLs distinct), `nextSequence`, `minStockThreshold`, `active` — migration `20260713_category_tag_sequences` **applied to Supabase**. New `CategoryModule` (`GET /categories` all roles — lazily seeds the 20-category master list, upgrades legacy free-text categories by name match, derives fallback prefixes; `POST/PATCH/DELETE` admin; delete 409s when items exist). Tag assignment in `inventory.service.create()`: transaction bumps `nextSequence` atomically (row lock = race-safe), formats `RG-05`-style tags (padStart 2, grows naturally), skips clashes with legacy manual tags; caller-provided tagNumber wins; no category → no tag. OCR `importItems` still uses flat `INV-####` — switches to category tags in R3 (category detection). Specs: category.service.spec (7) + inventory tag tests (4) — **api 117 green**. Mobile: `features/categories/` (ShopCategory model, repository, providers, CategoriesScreen admin settings list w/ search + low-stock/inactive badges, CategoryFormPage full-screen form w/ prefix + min-stock validation), route `/categories` (admin-only via kAdminOnlyRoutes) + profile-menu entry, l10n ×3 languages, tests categories_test (5). **flutter test 176 green, analyze clean, web build green.** NOT committed.
- 2026-07-13 — **R0 typography pass 2 (owner feedback: "looks like only colors changed").** Text theme rewritten as a faithful transcription of the concept's type scale: family = "Helvetica Neue" via `ThemeData(fontFamily:)` (iOS/macOS native; Android/web fall back to Roboto = the concept's own fallback); headings semibold w600 only (no w700 headings) with slightly positive tracking (.2–.5); hero figure 44/w600; card heading 17/w600; row title 13.5/w600; body 15 (height 1.5); meta 12; buttons 14/w600; labelSmall 11/w700/tracking 1.0 for eyebrow/status use. Verified analyze clean, 171 tests green, web build green.
