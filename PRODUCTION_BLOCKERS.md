# SwarnaLekh — Production Blockers & Gaps

_Documented during pre-live audit. Currently in testing; will address iteratively._

---

## 🔴 Critical Blockers (Fix Before Launch)

| #   | Area                       | Issue                                                                                                                                  | Impact                                                                                |
| --- | -------------------------- | -------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------- |
| 1   | **Billing Module**         | `apps/api/src/modules/billing/` empty — no API for "Create Bill" workflow (customer + inventory selection → pricing preview → invoice) | Mobile billing screen calls `/invoices` directly; no dedicated bill creation endpoint |
| 2   | **Auth Onboarding**        | No signup/password/reset — `registerTenant()` requires external Supabase `providerUserId`                                              | First-time shop owner cannot register via app                                         |
| 3   | **Selling Price Display**  | Dashboard (`InventoryService.getOverview`) shows calculated price; billing uses explicit `sellingPrice`                                | Inconsistent pricing shown to user vs. charged                                        |
| 4   | **Stock Race Condition**   | Invoice creation checks `status === 'sold'` without `FOR UPDATE` lock                                                                  | Concurrent invoices for same unique item → oversell                                   |
| 5   | **No Idempotency**         | `POST /invoices` lacks idempotency key                                                                                                 | Duplicate submissions = duplicate invoices + double stock reduction                   |
| 6   | **Soft-Delete Leak**       | `PrismaService.forTenant()` doesn't auto-filter `deletedAt: null`; services manually add it (easy to miss)                             | Soft-deleted data leaks in queries (e.g., `ReportService`)                            |
| 7   | **Payment Module Missing** | `Payment` model + relations exist but no module/controller/service                                                                     | Cannot record partial payments against existing invoices                              |
| 8   | **PDF Generation**         | Hand-rolled PDF writer (`renderTextPdf`) — no pagination, font embedding, RTL, Unicode safety                                          | Breaks on long invoices, special chars, multi-page                                    |

---

## 🟡 Medium Gaps (Post-Launch Sprint)

| Area          | Gap                                                                   |
| ------------- | --------------------------------------------------------------------- |
| Search        | Only `ILIKE` — no PostgreSQL `tsvector` full-text                     |
| Export        | Reports PDF-only — no CSV/Excel                                       |
| Audit Log     | `AuditLogInterceptor` not global — only on endpoints that remember it |
| Webhooks      | No Supabase `user.created` → auto-create tenant user                  |
| Rate Limiting | None — no throttling, CAPTCHA, abuse protection                       |
| Health Checks | Only `/auth/health` — no DB/Redis/dependency checks for K8s           |
| Migrations    | No documented rollback strategy                                       |

---

## 🖼️ Image Storage (Current: Base64 in DB)

| Type             | Storage                                              | Concerns                                      |
| ---------------- | ---------------------------------------------------- | --------------------------------------------- |
| Shop Logo        | `Tenant.logoUrl` (TEXT, data URI)                    | DB bloat, no CDN, backup size                 |
| Inventory Photos | `InventoryItem.photos` (JSON array of data URIs)     | List queries pull all base64; memory pressure |
| Mortgage KYC     | `MortgageLoan.photoIdUrl`, `customerPhotoUrl` (TEXT) | Same                                          |

**Quick wins:** Strip images from list queries (`select: { photos: false }`), add byte-size validation on mobile, compress more aggressively (72% @ 800px).

**Proper fix:** Move to **Supabase Storage** — signed URLs, CDN, 1GB free, same auth.

---

## ✅ Already Solid

- Multi-tenant isolation (`forTenant()` + manual `tenantId`)
- Role-based access (owner/admin/staff)
- Shared business logic (`@swarnbook/business-logic`) with tests
- Invoice PDF: shop logo, QR, verification code, GST breakdown
- Mortgage full flow (create → collect → receipt → close) with tests
- Mobile: Riverpod + GoRouter + l10n (EN/HI/GU) + keyboard-safe forms
- Test coverage on inventory, invoice, mortgage, reports

---

## 🎯 Immediate Fix Order

1. Implement `BillingModule` (customer + inventory → invoice)
2. Add auth onboarding (`POST /auth/register` → Supabase user + tenant + owner)
3. Fix selling price display consistency (dashboard = explicit when set)
4. Add `FOR UPDATE` lock in invoice creation
5. Add idempotency key to invoice creation
6. Enable global audit interceptor + soft-delete filter in `forTenant()`

---

_Last updated: 2026-06-14 — Pre-live audit_
