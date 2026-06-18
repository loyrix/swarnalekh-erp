# AGENTS.md

## Mission

Build SwarnaLekh strictly from the repo-local Jewellery ERP PDF:

[`docs/source-of-truth/jewellery-erp-system-flow.pdf`](docs/source-of-truth/jewellery-erp-system-flow.pdf)

The PDF is the product source of truth. The root `README.md` is the implementation tracker. This file is the coding-agent operating manual.

## Core Agent Rules

These rules adapt Karpathy-style coding-agent guidance for this repository:

1. Think before coding.
   - Do not guess silently.
   - State assumptions when they matter.
   - If the PDF, frontend, backend, and DB disagree, stop and surface the conflict before implementing.
   - Ask only when the answer cannot be found from the PDF or code.

2. Simplicity first.
   - Implement the minimum code that completes the PDF requirement end-to-end.
   - Do not add speculative abstractions, placeholder modules, or non-PDF features.
   - Prefer existing project patterns over new architecture.

3. Surgical changes.
   - Touch only files required for the current PDF requirement.
   - Do not refactor unrelated code.
   - Do not remove dormant non-PDF DB tables unless the task explicitly includes cleanup.
   - Hide or avoid visible non-PDF UI features unless the owner asks for deletion.

4. Success criteria over activity.
   - Every task must end with a clear verification result.
   - A feature is not complete because code exists; it is complete when UI, API, DB, roles, tests, and business side effects work together.

## PDF-Only Scope

Allowed active product areas:

- Login and role-based access
- Dashboard
- Inventory
- Mortgage / gold loan
- Billing and invoices
- Reports
- Search and filters
- Security: secure login, role access, backup, activity logs, invoice protection
- Admin/staff user management
- Shop profile/settings needed for business identity and invoices

Do not create active product flows for:

- Standalone KYC
- Schemes
- Ledger
- Notifications
- Subscription tiers
- Super-admin management
- Offline-first sync
- Standalone CRM
- Any module not present in the PDF

## Coding Standards

### General

- Follow existing file structure and naming.
- Keep edits small and readable.
- Use typed DTOs/models instead of dynamic maps where the surrounding code supports it.
- Keep validation rules consistent between frontend and backend.
- Use existing shared business logic before duplicating calculations.
- Do not hard-code business rules in only the frontend.
- Any money, weight, tax, stock, invoice, or mortgage calculation must be verified on the backend.

### Backend

- Backend stays on NestJS.
- Use Prisma for database access.
- Keep APIs tenant-scoped and role-protected.
- Add or update DTO validation when payloads change.
- Do not expose frontend fields that the API ignores.
- Do not accept backend fields that the frontend cannot intentionally provide unless they are system-managed.
- Business side effects must happen transactionally where needed, especially billing stock reduction and mortgage payments.

### Flutter

- Follow the existing Riverpod, GoRouter, theme, and feature folder patterns.
- Every screen must handle loading, empty, error, and success states where applicable.
- Every form/dialog must be keyboard-safe and scrollable on phone screens.
- Respect safe areas, status bars, bottom navigation, and touch target sizes.
- Do not add visible UI text directly in widgets unless it is not user-facing.

## Localization Rules

Every user-facing UI string must be localized.

When adding or changing UI text:

1. Add/update the key in:
   - `apps/mobile/lib/l10n/app_en.arb`
   - `apps/mobile/lib/l10n/app_hi.arb`
   - `apps/mobile/lib/l10n/app_gu.arb`
2. Use `AppLocalizations.of(context)!` from the widget.
3. Keep placeholders consistent across all locales.
4. Regenerate localizations if generated files are not updated automatically:

```bash
cd apps/mobile && flutter gen-l10n
```

5. Run:

```bash
cd apps/mobile && flutter analyze
cd apps/mobile && flutter test
```

Hard-coded labels, buttons, validation errors, snackbars, dialog titles, empty states, table headers, and menu items are not acceptable.

## Definition Of Done For Any Feature

A requirement can be marked complete only when:

- It maps to a PDF requirement.
- UI sends exactly what the backend supports.
- Backend validates and persists exactly what the UI promises.
- DB schema supports the data without hidden lossy fields.
- Admin/staff permissions match the PDF.
- Dashboard/reports/security side effects update correctly.
- Tests cover the important business logic.
- Flutter analyzer and relevant tests pass.
- README tracker status is updated.

## Required Verification Commands

Use the smallest relevant set while developing, then run the full set before a phase is complete:

```bash
pnpm --dir apps/api test --runInBand
pnpm vercel:build:api
cd apps/mobile && flutter analyze
cd apps/mobile && flutter test
```

For Android release verification:

```bash
pnpm mobile:env:sync
pnpm mobile:apk
```

## Final Reminder

Read the PDF first. Read the README tracker second. Then implement the smallest complete vertical slice. If tempted to add anything outside the PDF, do not.
