-- CreateTable
CREATE TABLE "mortgage_loans" (
    "id" UUID NOT NULL,
    "tenant_id" UUID NOT NULL,
    "loan_number" VARCHAR(50) NOT NULL,
    "customer_id" UUID,
    "customer_name" VARCHAR(200) NOT NULL,
    "customer_phone" VARCHAR(15),
    "customer_address" TEXT,
    "aadhaar_number" VARCHAR(20),
    "pan_number" VARCHAR(15),
    "photo_id_url" TEXT,
    "customer_photo_url" TEXT,
    "principal_amount" DECIMAL(14,2) NOT NULL,
    "interest_rate_monthly" DECIMAL(5,2) NOT NULL,
    "monthly_interest_amount" DECIMAL(12,2) NOT NULL DEFAULT 0,
    "loan_date" DATE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "due_date" DATE,
    "total_interest_paid" DECIMAL(12,2) NOT NULL DEFAULT 0,
    "total_principal_paid" DECIMAL(14,2) NOT NULL DEFAULT 0,
    "pending_interest_amount" DECIMAL(12,2) NOT NULL DEFAULT 0,
    "outstanding_principal" DECIMAL(14,2) NOT NULL,
    "total_payable_amount" DECIMAL(14,2) NOT NULL DEFAULT 0,
    "status" VARCHAR(20) NOT NULL DEFAULT 'active',
    "notes" TEXT,
    "closed_at" TIMESTAMPTZ,
    "closed_by" UUID,
    "created_by" UUID,
    "deleted_at" TIMESTAMPTZ,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "mortgage_loans_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "mortgage_ornaments" (
    "id" UUID NOT NULL,
    "loan_id" UUID NOT NULL,
    "ornament_type" VARCHAR(100) NOT NULL,
    "purity" VARCHAR(20),
    "gross_weight" DECIMAL(10,3) NOT NULL,
    "net_weight" DECIMAL(10,3) NOT NULL,
    "estimated_value" DECIMAL(14,2),
    "description" TEXT,
    "photos" JSONB,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "mortgage_ornaments_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "mortgage_payments" (
    "id" UUID NOT NULL,
    "tenant_id" UUID NOT NULL,
    "loan_id" UUID NOT NULL,
    "payment_date" DATE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "amount" DECIMAL(14,2) NOT NULL,
    "payment_type" VARCHAR(20) NOT NULL DEFAULT 'interest',
    "payment_mode" VARCHAR(30),
    "receipt_number" VARCHAR(50),
    "reference_number" VARCHAR(100),
    "notes" TEXT,
    "collected_by" UUID,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "mortgage_payments_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "mortgage_loans_tenant_id_loan_number_key" ON "mortgage_loans"("tenant_id", "loan_number");

-- CreateIndex
CREATE INDEX "mortgage_loans_tenant_id_idx" ON "mortgage_loans"("tenant_id");

-- CreateIndex
CREATE INDEX "mortgage_loans_tenant_id_status_idx" ON "mortgage_loans"("tenant_id", "status");

-- CreateIndex
CREATE INDEX "mortgage_loans_tenant_id_customer_id_idx" ON "mortgage_loans"("tenant_id", "customer_id");

-- CreateIndex
CREATE INDEX "mortgage_loans_tenant_id_loan_date_idx" ON "mortgage_loans"("tenant_id", "loan_date");

-- CreateIndex
CREATE INDEX "mortgage_ornaments_loan_id_idx" ON "mortgage_ornaments"("loan_id");

-- CreateIndex
CREATE UNIQUE INDEX "mortgage_payments_tenant_id_receipt_number_key" ON "mortgage_payments"("tenant_id", "receipt_number");

-- CreateIndex
CREATE INDEX "mortgage_payments_tenant_id_idx" ON "mortgage_payments"("tenant_id");

-- CreateIndex
CREATE INDEX "mortgage_payments_loan_id_idx" ON "mortgage_payments"("loan_id");

-- CreateIndex
CREATE INDEX "mortgage_payments_tenant_id_payment_date_idx" ON "mortgage_payments"("tenant_id", "payment_date");

-- AddForeignKey
ALTER TABLE "mortgage_loans" ADD CONSTRAINT "mortgage_loans_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "tenants"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "mortgage_loans" ADD CONSTRAINT "mortgage_loans_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "customers"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "mortgage_loans" ADD CONSTRAINT "mortgage_loans_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "mortgage_loans" ADD CONSTRAINT "mortgage_loans_closed_by_fkey" FOREIGN KEY ("closed_by") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "mortgage_ornaments" ADD CONSTRAINT "mortgage_ornaments_loan_id_fkey" FOREIGN KEY ("loan_id") REFERENCES "mortgage_loans"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "mortgage_payments" ADD CONSTRAINT "mortgage_payments_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "tenants"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "mortgage_payments" ADD CONSTRAINT "mortgage_payments_loan_id_fkey" FOREIGN KEY ("loan_id") REFERENCES "mortgage_loans"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "mortgage_payments" ADD CONSTRAINT "mortgage_payments_collected_by_fkey" FOREIGN KEY ("collected_by") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
