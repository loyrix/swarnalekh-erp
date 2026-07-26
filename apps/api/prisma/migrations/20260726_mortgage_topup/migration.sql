-- Global mortgage top-up interest policy: "separate" (top-up accrues from its
-- own date) or "merge" (folds into the original loan from day one).
ALTER TABLE "tenants"
  ADD COLUMN "mortgage_topup_mode" VARCHAR(20) NOT NULL DEFAULT 'separate';

-- A principal top-up added to an existing mortgage loan.
CREATE TABLE "mortgage_topups" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "tenant_id" UUID NOT NULL,
  "loan_id" UUID NOT NULL,
  "amount" DECIMAL(14,2) NOT NULL,
  "topup_date" DATE NOT NULL DEFAULT CURRENT_DATE,
  "notes" TEXT,
  "created_by" UUID,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT "mortgage_topups_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "mortgage_topups_tenant_id_idx" ON "mortgage_topups" ("tenant_id");
CREATE INDEX "mortgage_topups_loan_id_idx" ON "mortgage_topups" ("loan_id");

ALTER TABLE "mortgage_topups"
  ADD CONSTRAINT "mortgage_topups_tenant_id_fkey"
  FOREIGN KEY ("tenant_id") REFERENCES "tenants"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "mortgage_topups"
  ADD CONSTRAINT "mortgage_topups_loan_id_fkey"
  FOREIGN KEY ("loan_id") REFERENCES "mortgage_loans"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
