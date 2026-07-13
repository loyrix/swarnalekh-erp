-- Category-driven tag numbers (RG-01, CN-01, …) + per-category minimum-stock
-- thresholds for out-of-stock alerting.
ALTER TABLE "categories"
  ADD COLUMN "prefix" VARCHAR(10),
  ADD COLUMN "next_sequence" INTEGER NOT NULL DEFAULT 1,
  ADD COLUMN "min_stock_threshold" INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN "active" BOOLEAN NOT NULL DEFAULT true;

-- Prefix unique per tenant; NULL prefixes (legacy free-text categories)
-- remain distinct in Postgres so existing rows are unaffected.
CREATE UNIQUE INDEX "categories_tenant_id_prefix_key"
  ON "categories" ("tenant_id", "prefix");
