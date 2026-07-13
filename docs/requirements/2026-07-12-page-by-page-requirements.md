# Page-by-Page Requirements — Planning Session (2026-07-12)

> Captured from owner walkthrough, page by page. This doc grows as each page is reviewed.
> Status: **planning only — not yet implemented.**

---

## 0. Global — Theme decision (confirmed 2026-07-13)

**Chosen theme: Onyx · Champagne** — [docs/design-concepts/06-onyx-champagne.html](../design-concepts/06-onyx-champagne.html). All the page changes in this doc are to be built in this theme.

Key characteristics (from the concept file):

- **Sharp monochrome base + one restrained champagne-gold accent** (brand, primary action, trend line, hairlines). Status & metal colours preserved.
- Light: bg `#F4F4F5`, surface `#FFFFFF`, text `#161619`, accent `#9C7C3E` (ink `#6E5622`, bright `#C1A05C`).
- Dark: bg `#0A0A0C`, surface `#151517`, text `#F3F3F5`, accent `#C6A25E`.
- Metal palette: gold `#9C7C3E`/`#C4A15C`, silver `#7C858F`, platinum-teal, diamond-blue, rose.
- Status: ok `#2F9A5F`, info `#3F72D6`, warn `#C67D18`, danger `#CB463F` (brighter dark-mode variants).
- Geometry: small radii (8/6/5px — squarer than typical), 1px hairline borders, subtle 1px shadows, no glow.
- Type: sans body; headings/figures in a serif-slot currently set to Helvetica Neue, semi-bold, tabular numerals for amounts.
- Signature details: 3px left accent bars on list rows, tinted 34px icon tiles on KPI cards, uppercase letter-spaced section eyebrows with gold tick, pill-selects with accent tint.

This supersedes the previous "Signature Premium" look as the target for the upcoming UI pass; existing structural kit rules (filledTonal icon buttons etc.) carry over unless they conflict with Onyx Champagne tokens.

**Type decision (owner delegated, 2026-07-13):** no custom serif font. The concept's "serif" slot is Helvetica-style; in Flutter we use the platform default sans (SF Pro / Roboto) with semibold weights for headings/figures and tabular numerals for all amounts. No new font assets.

**Implementation plan:** [docs/plans/2026-07-refinement-plan.md](../plans/2026-07-refinement-plan.md)

---

## 1. Add Inventory Page

### 1.1 Replace Design Number with auto-generated Tag Number (category-based)

- **Remove** the "Design Number" free-text field (currently stored in the backend `barcode` field).
- Add a **Category** dropdown of gold ornament types (pre-created master list covering all common Indian gold ornament kinds): Ring, Chain, Mangalsutra, Necklace, Bangle, Bracelet, Earrings, Pendant, Anklet (Payal), Nose Pin (Nath), Kada, Haar, Tikka (Maang Tikka), Toe Ring (Bichhiya), Coin, Locket, Studs, Choker, Waist Chain (Kamarbandh), Armlet (Bajubandh), etc. — final list to be confirmed.
- On selecting a category, the **Tag Number is auto-generated** from a per-category prefix + auto-incremented sequence, unique per category. Examples:
  - RING → `RG-01`, `RG-02`, …
  - CHAIN → `CN-01`, `CN-02`, …
- Prework: define the full category master list with a unique 2-letter (or short) prefix for each category before implementation.

### 1.2 Weight Details simplification

- Currently `0` is pre-selected/pre-filled in Gross Weight and other weight fields — remove the pre-filled zeros (fields start empty).
- **Net Weight is currently not editable** — (noted as part of current behavior to fix alongside this cleanup).
- **Remove the separate milligrams section** entirely. User enters weight as a single decimal grams value (e.g. 10.5 gms) — no separate gm/mg inputs.
- Remove all extra fields/controls related to the gm/mg split that are no longer needed.

### 1.3 Remove Price Details section

- Remove the entire **Price Details** section from Add Inventory. Rationale: this page adds items to stock, it does not sell them — pricing belongs to billing/sale time.

### 1.4 Remove Branch field

- Remove the **Branch** selector from the Add Inventory form.
- Branch should be selected once at the dashboard/main-page level (global context), not per item.

### 1.5 Compact image upload

- Current Upload Image section takes too much area — make it **compact**.
- Support **two capture paths**: pick from gallery/upload **and** click a photo with the camera directly.
- **Remove the "Product Image URL"** input from this section.

### Decisions (Add Inventory) — confirmed by owner 2026-07-13

- **Tag sequence scope: per shop** (one sequence per category across the whole shop, not per branch). Padding grows naturally (`RG-99` → `RG-100`).
- **Weight input: decimal grams, up to 5 decimal places.**
- **Net Weight: auto-calculated** (gross − stone/less weight), not editable.

---

## 2. HUID Receipts Page (HUID scan → import to inventory)

### 2.1 Show Stone Weight after scan

- After a HUID image is scanned, the system deducts stone weight from Gross Weight to compute Net Weight, but the **stone weight itself is not shown**.
- The user sees a reduced net weight and doesn't know why. **Display the Stone Weight explicitly** alongside Gross and Net so the deduction is self-explanatory.

### 2.2 Prevent duplicate HUID imports

- The **same HUID image / item must not be uploaded and imported into inventory twice**.
- Deduplicate on the **actual HUID ID** (each HUID is unique per hallmarked item): if a scanned HUID already exists in inventory, block the import and inform the user.

### 2.3 Auto-generate Tag Number on successful import (category-based)

- After a successful import, the **Tag Number must be auto-generated** using the same category-prefix scheme as Add Inventory (see §1.1, e.g. `RG-01`, `CN-01`).
- The **category should be detected during scanning** (from the scanned receipt/item description), and the relevant tag prefix applied automatically.

### 2.4 Remove fields

- Remove **Quantity** field.
- Remove **Hallmark** field (redundant — HUID-scanned items are by definition hallmarked).

### Decisions (HUID Receipts) — confirmed by owner 2026-07-13

- **Duplicate check: per shop.** A HUID currently _in stock_ cannot be imported again; a **sold item's HUID may re-enter** inventory (buy-back case).

### Open questions (HUID Receipts)

- If category can't be confidently detected from the scan, fallback = ask user to pick from the category dropdown before import — confirm.

---

## 3. Inventory → View Inventory Page

### 3.1 Sold products shown twice + broken/scattered filters — code analysis findings

**Why sold appears twice (confirmed in code):**

- The View Inventory tab's stats strip shows a **"Sold Products · {period}" count** with its own period selector (today/month/3m/6m/12m/all/custom) — added in commit `dde6746`.
- Separately there is a whole **"Sold Products" section tab** that lists sold items.
- So one is a _count stat_, the other a _list_ — but to the user it reads as the same data in two places.

**Why the time-range filter "doesn't work" (confirmed in code):**

- The period selector on View Inventory changes **only the sold count** in the stats strip (`inventoryStatsProvider(_soldPeriod)`); the item list, weights, and totals are deliberately period-neutral — so picking a range appears to do nothing.
- Additionally the backend filters sold-by-period using **`updatedAt` as a proxy for sold date** ([inventory.service.ts:282-287](apps/api/src/modules/inventory/inventory.service.ts#L282-L287)) — inaccurate if an item is edited after sale. Should use actual sold/invoice date.
- Filters are scattered across 4 places: search bar, filter sheet (metal/status/category/branch via tune icon), period selector in stats strip, and section tabs.

**Requirement:**

- **Consolidate all filters in one place** (single filter surface for search, metal, category, branch, status, time range).
- Remove the duplication: sold data should live in the Sold Products section; View Inventory shouldn't carry its own sold-period widget.
- Fix period filtering to use the actual sold date, and make the time filter actually filter the visible data.

### 3.2 Out of Stock — use case verified; move to Dashboard

**Code finding:** `alerts.outOfStock` is literally just **the count of sold items** ([inventory.service.ts:321](apps/api/src/modules/inventory/inventory.service.ts#L321)) — for unique jewellery pieces, sold = out of stock, so today it duplicates the "Sold" number and has no independent meaning. (There is a separate `lowStock` alert = bulk items with quantity ≤ 2.)

**Requirement:**

- Rework Out of Stock to be meaningful: **clickable**, showing **which categories/items are out of stock** (e.g. categories with zero in-stock items).
- **Move it to the Dashboard**, remove it from this page.

### 3.3 Total Gold / Silver Weight — clickable karat breakdown

- Total Gold Weight and Total Silver Weight tiles should be **clickable**, opening a breakdown **by karat/purity** for the respective metal (e.g. Gold: 22K x g, 18K y g; Silver by purity).

### 3.4 Direct metal-type filters

- Add **direct Gold / Silver filter chips** on the inventory list (metal filter exists today but is buried in the filter sheet) — one-tap metal-wise view of inventory data.

### 3.5 Total Products — clickable metal-wise count

- Total Products tile should be **clickable**, showing the count split by metal: Gold count / Silver count. (Backend `metalBreakdown` already returns per-metal count/quantity/weight — reuse it.)

---

## 4. Inventory → Sold Products Page

### 4.1 Richer rows — use the full row width

- Current rows show only item name + invoice number + sold date, wasting the row width.
- Show **more details per row**, utilising the full row: e.g. tag number, category, metal/karat, net weight, sold price/amount, customer — final field set to be confirmed at design time.

### Decisions (View Inventory / Sold) — confirmed by owner 2026-07-13

- **Out of Stock = per-category minimum-stock thresholds.** Each category gets a configurable minimum stock level; a category is "out of stock" / low when in-stock count falls at/below its threshold. Shown on Dashboard, clickable to see which categories/items.

### Open questions (View Inventory / Sold)

- After consolidation, should the time-range filter also filter the _in-stock item list_ (by created date), or does time range only make sense for sold data?

---

## 5. Dashboard Page

### 5.1 Section order — Overview above Sales Trend

- Move the **Overview details** section **above** the Sales Trend graph.
- Related (from §3.2): the reworked clickable **Out of Stock** indicator will also live on the Dashboard.

---

_(Next pages will be appended below as the walkthrough continues.)_
