-- Add idempotency key to invoices to dedupe duplicate submissions.
ALTER TABLE "invoices" ADD COLUMN "idempotency_key" VARCHAR(80);

-- Unique per tenant; NULL keys remain distinct in Postgres so non-idempotent
-- creates are unaffected.
CREATE UNIQUE INDEX "invoices_tenant_id_idempotency_key_key"
  ON "invoices" ("tenant_id", "idempotency_key");
