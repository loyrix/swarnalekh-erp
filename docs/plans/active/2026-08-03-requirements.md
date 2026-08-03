# Swarnabook — Next Phase Requirements

**Status:** sections A and B **implemented** 2026-08-03. C and D deferred.
**Captured:** 2026-08-03
**Scope this phase:** sections **A** and **B**. **C and D are deferred** — will be
done later, confirmed by owner 2026-08-03.

### Answers log (owner, 2026-08-03)

| Q    | Answer                                                                                                 |
| ---- | ------------------------------------------------------------------------------------------------------ |
| 3    | Security measures will **all be implemented after this phase** → see A3 warning                        |
| 3a   | **Ship the trust message now**, verified claims only                                                   |
| 11   | Don't guess GST policy — the owner just types an amount → existing before-GST behaviour left untouched |
| 17   | **Invoice only**, no order tracking                                                                    |
| 9    | Remove discount **completely from the UI**                                                             |
| 10   | Old gold = **rupee amount only**, nothing else                                                         |
| 13   | Placeholder/hint text is fine; **no pre-filled value the user must clear**                             |
| 14   | **Yes** — inventory and on-demand lines may mix on one invoice                                         |
| C, D | **Deferred** to a later phase (still intended, not cancelled)                                          |

**Source:** requirements dictated by owner, one at a time

Sections: **A** Dashboard · **B** Billing · **C** AI Catalogue · **D** Subscriptions

---

## A. Dashboard

Target screen: `apps/mobile/lib/features/dashboard/presentation/screens/dashboard_screen.dart`

### A1 — Remove the analysis graph from the dashboard

**What:** Delete the sales-analysis graph from the dashboard page.

**Where:** `_SalesTrendChart` (dashboard_screen.dart:478) and its call site in the
page body (dashboard_screen.dart:77). Built on `fl_chart` (`LineChart`), fed by
`data.stats.salesTrend`.

**Notes / assumptions:**

- Remove the section entirely, not just hide it — including its `SectionHeader` and
  the surrounding `StaggeredSection` wrapper, so stagger indices stay contiguous.
- The code comment at dashboard_screen.dart:52 references "req §5.1" (overview
  before the trend graph) — that older requirement is superseded here.
- Cleanup to check at build time: the `fl_chart` import (line 1) if nothing else on
  the screen uses it; whether `salesTrend` is consumed elsewhere.

**Q1.** Strip `salesTrend` from the API/model too, or UI-only removal?
_Recommendation: UI-only; leave the API and model alone._

---

### A2 — Trim Quick Actions to non-duplicated entries

**What:** Remove **New Bill**, **Add Item**, and **Add Mortgage** from Quick
Actions — already reachable from the main menu bar. Keep the rest.

**Where:** `_QuickActions` (dashboard_screen.dart:370), `actions` list at lines
380–420.

**Resulting list (keep):**
| Action | Icon | Route | Gated |
|---|---|---|---|
| Set Rates | `sell_rounded` | `/rates` | admin only |
| Search Product | `search_rounded` | `/search` | all roles |
| Search Customer | `person_search_rounded` | `/customers` | all roles |

**Remove:** New Bill (`/billing`), Add Item (`/inventory`), Add Mortgage (`/mortgage`).

**Notes / assumptions:**

- Chip styling, section header, and `Wrap` layout stay as-is.
- **Visible consequence:** non-admin staff will now see only the two search chips.
  Accepted per the stated rationale (the rest live in the menu bar).
- Unused l10n keys (`dashboardNewBill`, `inventoryAddItem`, `dashboardAddMortgage`)
  may be used elsewhere — check before deleting from `app_en.arb`.

---

### A3 — Add a security / trust message

**What:** Add a security message to the dashboard with a fitting icon and copy that
builds trust — jewellery shop owners should feel confident the app is secure and
their data is safe.

**Intent:** credible, premium reassurance — not a generic marketing banner.

**Design constraints:** Onyx Champagne theme, gold-only + status palette; compact
but rich; consistent with existing card/section styling.

**⚠ BLOCKED — answer to Q3 was "we are going to do all once we complete this",
i.e. the security measures are not built yet.**

A trust message must not claim protections that don't exist. Shipping "your data is
encrypted and backed up" before that's true is a false claim to paying shop owners
about the safety of their business records — the exact thing that destroys the trust
this feature is meant to build.

**What is verifiably true _today_** (checked 2026-08-03) and may be stated now:

- Passwords are hashed with **bcrypt** — `bcryptjs` in `apps/api/package.json:40`
- Auth tokens are held in **`flutter_secure_storage`** (Keychain / Android
  Keystore) — `apps/mobile/pubspec.yaml:40`
- **Per-tenant data isolation** is enforced throughout the API — `tenantId` appears
  in 42 places in `invoice.service.ts` alone; every query is tenant-scoped

**Not yet true** — must not be claimed until built: encryption at rest, automated
backups, device/app lock (`local_auth` is not a dependency), any certification.

**Recommended path:** build A3 now using only the three verified claims above
(honest and already meaningful), and revisit the copy after the security work lands.
Alternative: defer A3 entirely to ship alongside that work.

**Q2.** Placement — quiet footer note, or a card in the space the chart vacates (A1)?
**Q3a.** Ship A3 now with verified claims only, or defer A3 until the security work
is done? _Recommendation: ship now with verified claims._
**Q4.** English only, or full l10n like the rest of the strings?
**Q5.** Static text, or tappable into a "How we protect your data" detail screen?

---

## B. Billing

Main file: `apps/mobile/lib/features/billing/presentation/screens/create_invoice_page.dart`

### B1 — 🔴 BUG (blocker): crash on Create Invoice → select inventory item → set rate

**Repro (owner):** Billing → Create Invoice → select an item from inventory → set
the rate → red error screen.

**Observed** (Android emulator, Medium Phone API 36.1, 2026-08-02):

```
'package:flutter/src/widgets/framework.dart': Failed assertion:
line 6279 pos 12: '_dependents.isEmpty': is not true.
```

The error surface replaces the page body only — app bar and bottom nav stay alive,
so it's a build-time failure inside the Billing route subtree, not a process crash.

**What the assertion means:** fires in `InheritedElement.debugDeactivated()` — an
`InheritedWidget` element was deactivated while descendants were still registered as
dependents. Typically a subtree torn down or reparented while something below still
holds an `.of(context)` dependency. Debug-mode assertion, so it may be invisible in
release while still indicating a real lifecycle fault.

**Prime suspect:** `_editPricing()` (line 362) — the rate-editing modal sheet.
Creates a local `TextEditingController field` (line 369) and calls `field.dispose()`
at **line 425 immediately after `await showModalBottomSheet` returns**, while the
sheet route may still be animating out with its `TextField` mounted. The repro
ending at "set the rate" fits.

**Other candidates:** the inventory picker sheet; `_setQuantity()` →
`_schedulePreview()` (line 357); a preview result arriving after the sheet closes
and rebuilding a subtree mid-teardown.

**Not yet root-caused** — needs a run against the repro for the full stack trace.

**Q6.** Does it reproduce on any inventory item, or only rate-priced/gold items?
**Q7.** Only the Gold Rate card, or also Making Charge / GST / Discount? (All four
go through the same `_editPricing` — if it's all of them, that confirms the suspect;
if only the rate, the cause is elsewhere.)
**Q8.** Debug build only, or does release misbehave too?

---

### B2 — Remove the Discount section

**What:** Remove the discount input from Create Invoice.

**Where:** `_discountField()` (line 1492, rendered from line 1449); `_discount`
controller (line 49, defaults to `'0'`, disposed line 91); submit payload
`discountAmount:` (line 216).

**Notes / assumptions:**

- The **display** of discount in the preview (lines 1332–1335) and full-preview
  sheet (lines 1870–1874) is already conditional on `discountAmount > 0`, so it
  simply never renders with no input. Leaving that read-only display keeps
  historical invoices with a discount rendering correctly.
- Backend keeps `discountAmount` (DTO + `calculateInvoiceTotals`); we stop sending
  it rather than removing server support.

**✅ ANSWERED (Q9): remove discount completely from the UI.**

Scope of "completely from the UI" as I'm reading it:

- **Remove:** the input field, its controller, the submit payload, **and** the
  discount rows in the create-invoice preview (lines 1332–1335) and full-preview
  sheet (lines 1870–1874) — all part of the create flow.
- **Keep:** the discount display in `invoice_detail_sheet.dart` and
  `invoice_pdf.dart`. Those render **historical invoices**; any past invoice with a
  discount would silently misstate its total if the line vanished. Flagging rather
  than asking, since deleting it would corrupt existing records' presentation.
- **Keep:** `discountAmount` in the DB/API — removing it would break stored invoices.

---

### B3 — Old gold replacement as a visible, selectable option

**What:** Make old-gold replacement a visible option. When selected, the user inputs
**only the old gold amount**, which is deducted from the total automatically and
reflected in the final bill.

**✅ Finding — the backend already supports this:**

- Schema `apps/api/prisma/schema.prisma:292-296` — `oldGoldWeight`, `oldGoldKarat`,
  `oldGoldRate`, `oldGoldValue`
- DTO `apps/api/src/modules/invoice/invoice.dto.ts:125-141`
- Service `apps/api/src/modules/invoice/invoice.service.ts:341-344` —
  `oldGoldValue = calculateOldGoldValue(weight, rate)`, fed into
  `calculateInvoiceTotals` as a deduction
- Already rendered in the final bill: `invoice_detail_sheet.dart`, `invoice_pdf.dart`

**The gap is the Create Invoice UI only** — it never collects or sends these fields.

**⚠ Conflict to resolve:** the server derives `oldGoldValue` from **weight × rate**;
the requirement asks for a **flat ₹ amount**.

| Option                               | How                                                                                | Trade-off                                                                                                                            |
| ------------------------------------ | ---------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| **a. Direct value field**            | New optional `oldGoldValue` on the DTO; server uses it verbatim, skips weight×rate | Cleanest match. Needs a DTO/service change (no migration).                                                                           |
| **b. weight=1, rate=amount**         | UI fakes inputs so the existing calc yields the amount                             | No backend change, but stores nonsense in `oldGoldWeight`/`oldGoldRate` and corrupts future old-gold reporting. **Not recommended.** |
| **c. Collect weight + karat + rate** | Keep the server model, ask for all three                                           | Contradicts "only input old gold amount".                                                                                            |

**✅ ANSWERED (Q10): option (a) — rupee amount only, no weight or karat.**
So the UI collects a single ₹ field, and the API needs a new optional `oldGoldValue`
on the DTO that the service uses verbatim, bypassing the weight×rate calculation.
`oldGoldWeight` / `oldGoldKarat` / `oldGoldRate` stay in the schema (existing
invoices use them) but are simply not sent from this flow.

**Q11.** _(still open)_ Does old gold deduct **before or after GST**? i.e. is GST
charged on the full item value and old gold knocked off the final payable, or is the
old-gold value taken off the taxable base first? These give different totals and
different tax liability. I'll confirm what `calculateInvoiceTotals` does today and
propose, but you should confirm which is correct for your billing practice.
**Q12.** _(still open)_ Toggle/checkbox that reveals the field, or an always-visible
optional field? _Recommendation: a toggle — keeps the default invoice uncluttered,
matches "it should be a visible option"._

---

### B4 — No `0` defaults in inputs

**What:** Inputs must not be pre-filled with `0`. Tapping an input should show an
empty field — no default at all.

**Where (confirmed pre-filled `'0'`):** `_discount` (line 49, moot after B2),
`_amountPaid` (line 50).

**Notes / assumptions:**

- Start controllers empty and treat empty as `0` at submit — parse sites already use
  `double.tryParse(...) ?? 0` (e.g. line 216), so empty is safe.
- Applies to the new old-gold field (B3) too.
- Sweep the other pricing fields (`_goldRate`, `_makingPerGram`, `_gstPercent`) and
  the `_editPricing` sheet, which seeds from the current controller text (line 369).

**✅ ANSWERED (Q13): placeholder/hint text with a message is fine — what must go is
any pre-filled value the user has to clear before typing.**

So: `hintText` stays (and should be a helpful message, not a bare `0`); controllers
start empty. Applies to every input in the create flow, including the new old-gold
field.

---

### B5 — Two billing modes: Inventory Sell vs On-Demand Making

**What:** Billing only handles selling existing inventory. There's no path for a
customer who places a **custom order made to spec**. Add that.

**Proposed shape (owner's):**

1. **Inventory Sell Billing** — existing flow, unchanged.
2. **On-Demand Making Billing** — new section, mostly **manual** fields:
   - Gold weight
   - Price fetched automatically from the gold weight (weight × current rate)
   - Purity option (karat selector)
   - Other fields entered by hand

**Constraint from owner:** _"it should be very simple thing"_ — simplicity is an
explicit acceptance criterion, not a nice-to-have.

**✅ Server-support finding (checked 2026-08-03): the database already allows it.**

- `InvoiceItem.inventoryItemId` is **nullable** (`String?`) — schema.prisma:340,
  nullable relation at line 359
- Each line already stores a **full snapshot** independent of inventory: `itemName`,
  `metalType`, `karat`, `grossWeight`, `netWeight`, `ratePerGram`, `metalValue`,
  `makingCharges`, `stoneValue`, `wastageValue`, `itemTotal` (schema.prisma:342-355)

What blocks a manual line is only the **API layer**:

- `CreateInvoiceItemDto.inventoryItemId` is `@IsString() @IsNotEmpty()` —
  invoice.dto.ts:42-45
- `invoice.service.ts:177-186` locks and looks up the inventory row, throwing
  `Inventory item ... not found` when absent, and drives pricing/stock from it

**Consequences:**

- **No DB migration needed.** Work = make `inventoryItemId` optional in the DTO, add
  manual fields, branch the service to skip the inventory lookup + stock decrement
  for manual lines.
- **Mixing inventory and on-demand lines on one invoice is already supported by the
  data model** (per-line nullable FK). So mixing is a _product_ decision, not a
  structural constraint.

**Notes / assumptions:**

- Rate lookup for "fetch price from gold weight" should reuse the existing rates
  source that drives inventory pricing (`/rates` + server-side `ratePerGram`
  resolution), not a new one.
- Making charge / GST / old gold / amount paid behave the same in both modes so the
  bill and PDF stay one format.

**✅ ANSWERED (Q14): yes — inventory and on-demand lines may mix on one invoice.**

This makes it a **per-line type**, not a per-invoice mode. Consequences:

- The DTO change is per line: `inventoryItemId` becomes optional, and a manual line
  carries its own `itemName` / `karat` / `netWeight` / `ratePerGram` / making.
- The service branches **per line**: inventory lines keep the lock + stock
  decrement; manual lines skip both and price from the entered weight × rate.
- Q15's "two separate entry points" is now largely ruled out — if both kinds live on
  one invoice, there's one Create Invoice screen with two ways to _add a line_.

**Q15.** _(still open, reframed)_ Given lines can mix: how does the owner add a
manual line — an "Add custom item" button next to the inventory picker, or a
segmented Inventory/Custom toggle inside the add-item sheet?
_Recommendation: a second button — fewest taps, and both paths stay visible._
**Q16.** _(still open)_ Which fields are manual beyond gold weight and purity?
(making charge/gram, stone value, wastage %, item name/description?)
_Recommendation, matching "keep it very simple": item name, gold weight, purity,
making charge — and nothing else in v1._
**Q17.** _(still open)_ Does an on-demand order need **order tracking** (pending →
ready → delivered), or is it just an invoice at point of sale? _This is the one that
could double the size of B5 — recommend invoice-only for v1._

---

## C. AI Catalogue (new feature)

### C1 — Generate design variations from a customer's description

**Problem:** A customer arrives with a design in mind. It isn't in stock and isn't
in the catalogue — nothing to show them, no way to pin down what they want.

**What:** An **AI catalogue** where owner and customer discuss and visualise a
design. The owner enters what the customer wants; the app generates **5 variations
in a single image**.

**Input modes (all three):** text prompt · reference image · voice (STT).

**✅ Existing infrastructure — a major de-risker:**

- `@google/genai` ^1.49.0 — `apps/api/package.json:28`
- `GEMINI_API_KEY` + `GEMINI_INVENTORY_MODEL` config —
  `apps/api/src/modules/inventory/inventory.service.ts:61,248`
- A working `ai.models.generateContent` call with inline base64 image input
  (inventory.service.ts:253-279), currently used for hallmark-receipt OCR

Same SDK, same key, same server-side convention. New: an **image-generating** model
(the current one is configured for JSON text at `temperature: 0`) and a new module.

**Genuinely missing:**

- An image-generation model choice on the Gemini side
- **STT on mobile** — nothing in `apps/mobile/pubspec.yaml` provides speech input;
  needs a package plus mic permissions (iOS + Android)
- Storage for generated designs, if they persist
- A new API module + mobile feature module

**Q18.** "5 variations in a single image" — one composited grid (cheaper, one call,
easy to WhatsApp) or 5 separate images in a gallery (better for picking and
refining)? _The wording says single image; confirming because it shapes the flow._
**Q19.** Is it **iterative**? "Discuss" implies "like #3 but thicker" → regenerate,
which needs conversation state rather than one-shot.
**Q20.** Do designs **persist** as a real catalogue (DB table + browsable gallery),
or are they throwaway per conversation?
**Q21.** Should an approved design **convert into a B5 on-demand order/invoice**?
_This link is what makes the feature close sales rather than demo well._
**Q22.** Per-tenant **cost/quota** controls — image generation is billed per call in
a multi-tenant app. Who pays, and what's the cap?
**Q23.** Does a generated render need a visible **disclaimer** before being shown to
a customer, so nobody promises a piece the karigar can't reproduce?
**Q24.** Voice input language — Hindi / regional, or English only? _This drives the
STT choice more than anything else._

**Sizing:** substantially larger than all of A and B combined — new API module, new
mobile feature, a new AI capability, mic permissions, possibly a new table. Treat as
its own phase.

---

## D. Subscriptions / Monetisation

### D1 — Subscription plans via RevenueCat

**Status: ⚠ still in discussion — pricing not decided.** Documented so groundwork
can be planned; do not build paywall copy or price points yet.

**Decided:** RevenueCat as the subscription layer; payments through **App Store and
Play Store in-app purchase** (stores handle the money, no direct gateway).

**Not decided:** price points · tier structure and contents · trial length /
free-tier limits.

**Existing groundwork:**

- `Tenant.subscriptionPlan` (`String @default("free")`) and
  `Tenant.subscriptionExpiresAt` — `apps/api/prisma/schema.prisma:33-34`
- Flows to the client: set at tenant creation (`tenant.service.ts:51`,
  `auth.service.ts:99`), returned on login (`auth.service.ts:209,278`), parsed into
  mobile models (`tenant_profile.dart:40`, `auth_user.dart:27`)
- **Nothing enforces it.** A grep for any plan comparison, guard, or `isPro`-style
  check across `apps/api/src` and `apps/mobile/lib` returns nothing. Every tenant is
  `'free'`; no feature is gated. The field is currently decorative.

**So the real work is entitlement enforcement, not plumbing a plan field.**

**Architecture notes:**

- **Server-side entitlement is mandatory** — the API must be source of truth via
  RevenueCat webhooks, not the client, or the paywall is trivially bypassed.
  `subscriptionExpiresAt` needs to be checked on protected routes.
- Intended flow: owner buys → RevenueCat webhook → API sets `subscriptionPlan` +
  `subscriptionExpiresAt` on the **tenant** → all staff inherit it.
- `apps/super-admin` should probably see and override a tenant's plan (comps,
  support, manual extensions).

**Q25.** **Entitlement is per-tenant (whole shop), not per-user — confirm.** Store
IAP binds a purchase to an Apple/Google _account_, but this app is multi-tenant with
multiple staff per shop. **This mapping is the hardest part of the integration and
needs deciding before any build.**
**Q26.** Confirm **store-IAP-only**, accepting the ~15–30% platform cut and no
web/desktop purchase path? For a B2B tool sold to shop owners, direct billing is
usually cheaper per rupee collected; store IAP is far less work and avoids
payment-compliance burden. Deliberate trade — hard to reverse once live.
**Q27.** Is the **AI catalogue (C1) a paid-tier feature**? It and receipt OCR are
metered Gemini calls with real per-use cost — the strongest paid-tier candidates and
natural per-tier quota levers. _Affects how C1 is built, so decide before C1 starts._
**Q28.** Rough **tier count** (2? 3?) — enough to design gating before prices land.
**Q29.** **Grandfathering** — every existing tenant is `'free'` today. Policy?

**Sequencing:** entitlement architecture (tenant mapping, webhook, server checks)
can be built while pricing is undecided. Paywall UI and copy wait for final numbers.

---

## Implementation status — 2026-08-03

All of A and B shipped. Verification: `flutter analyze` clean · **227** mobile tests
green · **159** API tests green · `nest build` clean.

| Req                      | Status          | Where                                                                                                                     |
| ------------------------ | --------------- | ------------------------------------------------------------------------------------------------------------------------- |
| A1 chart removed         | ✅              | `dashboard_screen.dart` — `_SalesTrendChart` and the `fl_chart` import deleted; `salesTrend` left in the API/model per Q1 |
| A2 quick actions trimmed | ✅              | `dashboard_screen.dart:_QuickActions` — Set Rates / Search Product / Search Customer remain                               |
| A3 trust card            | ✅              | `dashboard_screen.dart:_SecurityAssuranceCard`, three verified claims, en/hi/gu                                           |
| B1 crash fix             | ✅ (see caveat) | `_EditValueSheet` now owns its controller and disposes it in its own `dispose()`                                          |
| B2 discount removed      | ✅              | field, controller, payload and both preview rows gone; detail sheet + PDF untouched                                       |
| B3 old gold              | ✅              | `oldGoldValue` on DTO + service; toggle + single ₹ field in the UI; shown in preview, detail sheet and PDF                |
| B4 no `0` defaults       | ✅              | controllers start empty; hints retained per Q13                                                                           |
| B5 on-demand lines       | ✅              | optional `inventoryItemId`, `buildOnDemandLine()`, stock-decrement guard; "Add custom" sheet on mobile                    |

**Decisions made while building:**

- **Old gold and GST (Q11):** left exactly as it already behaved — old gold reduces
  the **taxable base before GST** (`business-logic/src/index.ts:146-148`). No tax
  policy was invented; the owner types an amount and it is deducted. If the shop
  wants it applied _after_ GST instead, that is a one-line change plus a test.
- **A direct `oldGoldValue` wins over weight × rate** when both are sent, so older
  clients still work.
- **On-demand lines are priced server-side** from weight × daily rate; the client
  cannot dictate a line total.
- **`fl_chart` left in `pubspec.yaml`** — unused now, but removing a dependency was
  outside the requested scope.

**⚠ B1 verification caveat:** the fix is structurally correct (controller lifetime
now matches the widget that uses it) and a mount/dispose regression test passes, but
**the original crash was not reproduced on a device before or after the fix** — the
create-invoice form needs live API data that the widget-test environment can't
provide. Worth one manual pass through Billing → Create Invoice → select item → set
rate on the emulator to confirm.

---

## Open questions — status after 2026-08-03 answers

**Answered:** 3 (with a consequence — see A3), 9, 10, 13, 14. C and D deferred.

**Still open (A/B only — C and D questions are parked with those sections):**

| #   | Section | Question                                                      | Blocking? |
| --- | ------- | ------------------------------------------------------------- | --------- |
| 1   | A1      | Strip `salesTrend` from API too? _(rec: UI-only)_             | no        |
| 2   | A3      | Placement — footer, or the card slot the chart vacates?       | yes       |
| 3a  | A3      | **Ship A3 now with only verified claims, or defer it?**       | **yes**   |
| 4   | A3      | English only, or full l10n?                                   | yes       |
| 5   | A3      | Static, or tappable detail screen?                            | yes       |
| 6   | B1      | Any item, or only gold/rate-priced?                           | helps     |
| 7   | B1      | Only Gold Rate, or all four pricing fields?                   | helps     |
| 8   | B1      | Debug only, or release too?                                   | helps     |
| 11  | B3      | **Old gold deducts before or after GST?**                     | **yes**   |
| 12  | B3      | Toggle vs always-visible field _(rec: toggle)_                | yes       |
| 15  | B5      | How to add a manual line _(rec: second button)_               | yes       |
| 16  | B5      | Which manual fields _(rec: name, weight, purity, making)_     | yes       |
| 17  | B5      | **Order tracking, or invoice-only?** _(rec: invoice-only v1)_ | **yes**   |

**Deferred with their sections:** 18–24 (C1), 25–29 (D1).

**Unblocked, buildable right now:** A1, A2, B2, B4 — plus the B1 investigation
(6–8 only speed up diagnosis; they don't block starting).
