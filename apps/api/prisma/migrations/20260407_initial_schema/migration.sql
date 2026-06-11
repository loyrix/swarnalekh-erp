-- CreateSchema
CREATE SCHEMA IF NOT EXISTS "public";

-- CreateTable
CREATE TABLE "tenants" (
    "id" UUID NOT NULL,
    "shop_name" VARCHAR(200) NOT NULL,
    "owner_name" VARCHAR(150) NOT NULL,
    "phone" VARCHAR(15),
    "email" VARCHAR(200),
    "address" TEXT,
    "city" VARCHAR(100),
    "state" VARCHAR(100),
    "pincode" VARCHAR(10),
    "gstin" VARCHAR(20),
    "pan" VARCHAR(15),
    "logo_url" TEXT,
    "subscription_plan" VARCHAR(20) NOT NULL DEFAULT 'free',
    "subscription_expires_at" TIMESTAMPTZ,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "tenants_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "users" (
    "id" UUID NOT NULL,
    "tenant_id" UUID NOT NULL,
    "name" VARCHAR(150) NOT NULL,
    "auth_user_id" UUID,
    "phone" VARCHAR(15),
    "email" VARCHAR(200),
    "password_hash" TEXT,
    "role" VARCHAR(20) NOT NULL DEFAULT 'staff',
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "last_login_at" TIMESTAMPTZ,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "customers" (
    "id" UUID NOT NULL,
    "tenant_id" UUID NOT NULL,
    "name" VARCHAR(200) NOT NULL,
    "phone" VARCHAR(15),
    "alt_phone" VARCHAR(15),
    "email" VARCHAR(200),
    "address" TEXT,
    "city" VARCHAR(100),
    "pincode" VARCHAR(10),
    "aadhar_number" VARCHAR(20),
    "pan_number" VARCHAR(15),
    "kyc_doc_url" TEXT,
    "preferred_karat" VARCHAR(10),
    "family_details" JSONB,
    "notes" TEXT,
    "total_purchases" DECIMAL(14,2) NOT NULL DEFAULT 0,
    "total_visits" INTEGER NOT NULL DEFAULT 0,
    "last_visit_at" TIMESTAMPTZ,
    "deleted_at" TIMESTAMPTZ,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "customers_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "categories" (
    "id" UUID NOT NULL,
    "tenant_id" UUID NOT NULL,
    "name" VARCHAR(100) NOT NULL,
    "parent_id" UUID,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "categories_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "inventory_items" (
    "id" UUID NOT NULL,
    "tenant_id" UUID NOT NULL,
    "tag_number" VARCHAR(50),
    "barcode" VARCHAR(100),
    "category_id" UUID,
    "item_name" VARCHAR(200),
    "description" TEXT,
    "metal_type" VARCHAR(20) NOT NULL,
    "karat" VARCHAR(10),
    "purity" DECIMAL(6,3),
    "gross_weight" DECIMAL(10,3) NOT NULL,
    "net_weight" DECIMAL(10,3) NOT NULL,
    "has_stones" BOOLEAN NOT NULL DEFAULT false,
    "stone_details" JSONB,
    "stone_value" DECIMAL(12,2) NOT NULL DEFAULT 0,
    "making_charges_per_gram" DECIMAL(10,2),
    "making_charges_fixed" DECIMAL(10,2),
    "making_charges_percent" DECIMAL(5,2),
    "wastage_percent" DECIMAL(5,2) NOT NULL DEFAULT 0,
    "source" VARCHAR(20),
    "karigar_id" UUID,
    "purchase_rate" DECIMAL(10,2),
    "purchase_date" DATE,
    "photos" JSONB,
    "hallmark_number" VARCHAR(50),
    "huid" VARCHAR(20),
    "status" VARCHAR(20) NOT NULL DEFAULT 'in_stock',
    "location" VARCHAR(100),
    "deleted_at" TIMESTAMPTZ,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "inventory_items_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "daily_rates" (
    "id" UUID NOT NULL,
    "tenant_id" UUID NOT NULL,
    "rate_date" DATE NOT NULL,
    "metal_type" VARCHAR(20) NOT NULL,
    "karat" VARCHAR(10),
    "rate_per_gram" DECIMAL(10,2) NOT NULL,
    "source" VARCHAR(50) NOT NULL DEFAULT 'manual',
    "set_by" UUID,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "daily_rates_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "karigars" (
    "id" UUID NOT NULL,
    "tenant_id" UUID NOT NULL,
    "name" VARCHAR(200) NOT NULL,
    "phone" VARCHAR(15),
    "specialization" VARCHAR(100),
    "address" TEXT,
    "balance" DECIMAL(12,2) NOT NULL DEFAULT 0,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "karigars_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "invoices" (
    "id" UUID NOT NULL,
    "tenant_id" UUID NOT NULL,
    "invoice_number" VARCHAR(50) NOT NULL,
    "invoice_date" DATE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "customer_id" UUID,
    "customer_name" VARCHAR(200),
    "customer_phone" VARCHAR(15),
    "customer_gstin" VARCHAR(20),
    "invoice_type" VARCHAR(20) NOT NULL DEFAULT 'sale',
    "subtotal" DECIMAL(14,2) NOT NULL,
    "total_making_charges" DECIMAL(12,2) NOT NULL DEFAULT 0,
    "total_stone_value" DECIMAL(12,2) NOT NULL DEFAULT 0,
    "discount_amount" DECIMAL(12,2) NOT NULL DEFAULT 0,
    "discount_percent" DECIMAL(5,2),
    "old_gold_weight" DECIMAL(10,3) NOT NULL DEFAULT 0,
    "old_gold_karat" VARCHAR(10),
    "old_gold_rate" DECIMAL(10,2),
    "old_gold_value" DECIMAL(12,2) NOT NULL DEFAULT 0,
    "taxable_amount" DECIMAL(14,2) NOT NULL,
    "cgst_percent" DECIMAL(5,2) NOT NULL DEFAULT 1.5,
    "cgst_amount" DECIMAL(12,2) NOT NULL DEFAULT 0,
    "sgst_percent" DECIMAL(5,2) NOT NULL DEFAULT 1.5,
    "sgst_amount" DECIMAL(12,2) NOT NULL DEFAULT 0,
    "igst_percent" DECIMAL(5,2) NOT NULL DEFAULT 0,
    "igst_amount" DECIMAL(12,2) NOT NULL DEFAULT 0,
    "total_tax" DECIMAL(12,2) NOT NULL DEFAULT 0,
    "grand_total" DECIMAL(14,2) NOT NULL,
    "round_off" DECIMAL(5,2) NOT NULL DEFAULT 0,
    "payment_mode" VARCHAR(30),
    "amount_paid" DECIMAL(14,2) NOT NULL DEFAULT 0,
    "balance_due" DECIMAL(14,2) NOT NULL DEFAULT 0,
    "notes" TEXT,
    "created_by" UUID,
    "deleted_at" TIMESTAMPTZ,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "invoices_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "invoice_items" (
    "id" UUID NOT NULL,
    "invoice_id" UUID NOT NULL,
    "inventory_item_id" UUID,
    "item_name" VARCHAR(200),
    "metal_type" VARCHAR(20),
    "karat" VARCHAR(10),
    "gross_weight" DECIMAL(10,3),
    "net_weight" DECIMAL(10,3),
    "rate_per_gram" DECIMAL(10,2),
    "metal_value" DECIMAL(12,2),
    "making_charges" DECIMAL(10,2),
    "stone_value" DECIMAL(12,2) NOT NULL DEFAULT 0,
    "wastage_value" DECIMAL(10,2) NOT NULL DEFAULT 0,
    "hallmark_number" VARCHAR(50),
    "huid" VARCHAR(20),
    "item_total" DECIMAL(12,2) NOT NULL,

    CONSTRAINT "invoice_items_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "payments" (
    "id" UUID NOT NULL,
    "tenant_id" UUID NOT NULL,
    "invoice_id" UUID,
    "customer_id" UUID,
    "amount" DECIMAL(14,2) NOT NULL,
    "payment_mode" VARCHAR(30) NOT NULL,
    "payment_date" DATE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "reference_number" VARCHAR(100),
    "notes" TEXT,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "payments_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "schemes" (
    "id" UUID NOT NULL,
    "tenant_id" UUID NOT NULL,
    "scheme_name" VARCHAR(200) NOT NULL,
    "duration_months" INTEGER NOT NULL,
    "monthly_amount" DECIMAL(10,2),
    "bonus_description" TEXT,
    "bonus_type" VARCHAR(20),
    "bonus_value" DECIMAL(10,2),
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "start_date" DATE,
    "end_date" DATE,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "schemes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "scheme_enrollments" (
    "id" UUID NOT NULL,
    "tenant_id" UUID NOT NULL,
    "scheme_id" UUID NOT NULL,
    "customer_id" UUID NOT NULL,
    "enrollment_number" VARCHAR(50),
    "enrollment_date" DATE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "monthly_amount" DECIMAL(10,2) NOT NULL,
    "total_months" INTEGER NOT NULL,
    "months_paid" INTEGER NOT NULL DEFAULT 0,
    "total_paid" DECIMAL(12,2) NOT NULL DEFAULT 0,
    "maturity_date" DATE,
    "maturity_value" DECIMAL(12,2),
    "status" VARCHAR(20) NOT NULL DEFAULT 'active',
    "notes" TEXT,
    "deleted_at" TIMESTAMPTZ,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "scheme_enrollments_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "scheme_payments" (
    "id" UUID NOT NULL,
    "enrollment_id" UUID NOT NULL,
    "payment_date" DATE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "amount" DECIMAL(10,2) NOT NULL,
    "month_number" INTEGER NOT NULL,
    "payment_mode" VARCHAR(30),
    "receipt_number" VARCHAR(50),
    "collected_by" UUID,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "scheme_payments_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ledger_parties" (
    "id" UUID NOT NULL,
    "tenant_id" UUID NOT NULL,
    "name" VARCHAR(200) NOT NULL,
    "phone" VARCHAR(15),
    "address" TEXT,
    "party_type" VARCHAR(30) NOT NULL DEFAULT 'general',
    "notes" TEXT,
    "current_balance" DECIMAL(14,2) NOT NULL DEFAULT 0,
    "deleted_at" TIMESTAMPTZ,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "ledger_parties_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ledger_entries" (
    "id" UUID NOT NULL,
    "tenant_id" UUID NOT NULL,
    "party_id" UUID NOT NULL,
    "entry_date" DATE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "entry_type" VARCHAR(20) NOT NULL,
    "amount" DECIMAL(14,2) NOT NULL,
    "principal_amount" DECIMAL(14,2),
    "interest_rate_monthly" DECIMAL(5,2),
    "interest_amount" DECIMAL(12,2),
    "collateral_description" TEXT,
    "collateral_weight" DECIMAL(10,3),
    "collateral_photos" JSONB,
    "due_date" DATE,
    "settled_at" TIMESTAMPTZ,
    "status" VARCHAR(20) NOT NULL DEFAULT 'open',
    "notes" TEXT,
    "created_by" UUID,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ledger_entries_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "notification_templates" (
    "id" UUID NOT NULL,
    "tenant_id" UUID NOT NULL,
    "template_name" VARCHAR(100),
    "channel" VARCHAR(20) NOT NULL DEFAULT 'whatsapp',
    "message_template" TEXT NOT NULL,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "notification_templates_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "notification_log" (
    "id" UUID NOT NULL,
    "tenant_id" UUID NOT NULL,
    "customer_id" UUID,
    "channel" VARCHAR(20),
    "template_id" UUID,
    "message_content" TEXT,
    "phone" VARCHAR(15),
    "status" VARCHAR(20) NOT NULL DEFAULT 'queued',
    "sent_at" TIMESTAMPTZ,
    "error_message" TEXT,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "notification_log_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "audit_log" (
    "id" UUID NOT NULL,
    "tenant_id" UUID NOT NULL,
    "user_id" UUID,
    "action" VARCHAR(50) NOT NULL,
    "entity_type" VARCHAR(50),
    "entity_id" UUID,
    "old_values" JSONB,
    "new_values" JSONB,
    "ip_address" VARCHAR(50),
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "audit_log_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "tenants_phone_key" ON "tenants"("phone");

-- CreateIndex
CREATE UNIQUE INDEX "users_auth_user_id_key" ON "users"("auth_user_id");

-- CreateIndex
CREATE INDEX "users_tenant_id_idx" ON "users"("tenant_id");

-- CreateIndex
CREATE INDEX "users_phone_idx" ON "users"("phone");

-- CreateIndex
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");

-- CreateIndex
CREATE INDEX "customers_tenant_id_idx" ON "customers"("tenant_id");

-- CreateIndex
CREATE INDEX "customers_tenant_id_phone_idx" ON "customers"("tenant_id", "phone");

-- CreateIndex
CREATE INDEX "customers_tenant_id_name_idx" ON "customers"("tenant_id", "name");

-- CreateIndex
CREATE INDEX "categories_tenant_id_idx" ON "categories"("tenant_id");

-- CreateIndex
CREATE INDEX "inventory_items_tenant_id_idx" ON "inventory_items"("tenant_id");

-- CreateIndex
CREATE INDEX "inventory_items_tenant_id_status_idx" ON "inventory_items"("tenant_id", "status");

-- CreateIndex
CREATE INDEX "inventory_items_tenant_id_metal_type_karat_idx" ON "inventory_items"("tenant_id", "metal_type", "karat");

-- CreateIndex
CREATE INDEX "inventory_items_tenant_id_tag_number_idx" ON "inventory_items"("tenant_id", "tag_number");

-- CreateIndex
CREATE INDEX "inventory_items_tenant_id_barcode_idx" ON "inventory_items"("tenant_id", "barcode");

-- CreateIndex
CREATE UNIQUE INDEX "daily_rates_tenant_id_rate_date_metal_type_karat_key" ON "daily_rates"("tenant_id", "rate_date", "metal_type", "karat");

-- CreateIndex
CREATE INDEX "karigars_tenant_id_idx" ON "karigars"("tenant_id");

-- CreateIndex
CREATE INDEX "invoices_tenant_id_idx" ON "invoices"("tenant_id");

-- CreateIndex
CREATE INDEX "invoices_tenant_id_customer_id_idx" ON "invoices"("tenant_id", "customer_id");

-- CreateIndex
CREATE INDEX "invoices_tenant_id_invoice_date_idx" ON "invoices"("tenant_id", "invoice_date");

-- CreateIndex
CREATE INDEX "invoices_tenant_id_invoice_number_idx" ON "invoices"("tenant_id", "invoice_number");

-- CreateIndex
CREATE INDEX "invoice_items_invoice_id_idx" ON "invoice_items"("invoice_id");

-- CreateIndex
CREATE INDEX "payments_tenant_id_idx" ON "payments"("tenant_id");

-- CreateIndex
CREATE INDEX "schemes_tenant_id_idx" ON "schemes"("tenant_id");

-- CreateIndex
CREATE INDEX "scheme_enrollments_tenant_id_idx" ON "scheme_enrollments"("tenant_id");

-- CreateIndex
CREATE INDEX "scheme_enrollments_customer_id_idx" ON "scheme_enrollments"("customer_id");

-- CreateIndex
CREATE INDEX "scheme_enrollments_tenant_id_status_idx" ON "scheme_enrollments"("tenant_id", "status");

-- CreateIndex
CREATE INDEX "scheme_payments_enrollment_id_idx" ON "scheme_payments"("enrollment_id");

-- CreateIndex
CREATE INDEX "ledger_parties_tenant_id_idx" ON "ledger_parties"("tenant_id");

-- CreateIndex
CREATE INDEX "ledger_entries_party_id_idx" ON "ledger_entries"("party_id");

-- CreateIndex
CREATE INDEX "ledger_entries_tenant_id_status_idx" ON "ledger_entries"("tenant_id", "status");

-- CreateIndex
CREATE INDEX "ledger_entries_tenant_id_entry_date_idx" ON "ledger_entries"("tenant_id", "entry_date");

-- CreateIndex
CREATE INDEX "notification_templates_tenant_id_idx" ON "notification_templates"("tenant_id");

-- CreateIndex
CREATE INDEX "notification_log_tenant_id_idx" ON "notification_log"("tenant_id");

-- CreateIndex
CREATE INDEX "notification_log_tenant_id_status_idx" ON "notification_log"("tenant_id", "status");

-- CreateIndex
CREATE INDEX "audit_log_tenant_id_created_at_idx" ON "audit_log"("tenant_id", "created_at" DESC);

-- AddForeignKey
ALTER TABLE "users" ADD CONSTRAINT "users_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "tenants"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "customers" ADD CONSTRAINT "customers_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "tenants"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "categories" ADD CONSTRAINT "categories_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "tenants"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "categories" ADD CONSTRAINT "categories_parent_id_fkey" FOREIGN KEY ("parent_id") REFERENCES "categories"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "inventory_items" ADD CONSTRAINT "inventory_items_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "tenants"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "inventory_items" ADD CONSTRAINT "inventory_items_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "categories"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "inventory_items" ADD CONSTRAINT "inventory_items_karigar_id_fkey" FOREIGN KEY ("karigar_id") REFERENCES "karigars"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "daily_rates" ADD CONSTRAINT "daily_rates_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "tenants"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "daily_rates" ADD CONSTRAINT "daily_rates_set_by_fkey" FOREIGN KEY ("set_by") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "karigars" ADD CONSTRAINT "karigars_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "tenants"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "invoices" ADD CONSTRAINT "invoices_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "tenants"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "invoices" ADD CONSTRAINT "invoices_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "customers"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "invoices" ADD CONSTRAINT "invoices_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "invoice_items" ADD CONSTRAINT "invoice_items_invoice_id_fkey" FOREIGN KEY ("invoice_id") REFERENCES "invoices"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "invoice_items" ADD CONSTRAINT "invoice_items_inventory_item_id_fkey" FOREIGN KEY ("inventory_item_id") REFERENCES "inventory_items"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "payments" ADD CONSTRAINT "payments_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "tenants"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "payments" ADD CONSTRAINT "payments_invoice_id_fkey" FOREIGN KEY ("invoice_id") REFERENCES "invoices"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "payments" ADD CONSTRAINT "payments_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "customers"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "schemes" ADD CONSTRAINT "schemes_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "tenants"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "scheme_enrollments" ADD CONSTRAINT "scheme_enrollments_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "tenants"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "scheme_enrollments" ADD CONSTRAINT "scheme_enrollments_scheme_id_fkey" FOREIGN KEY ("scheme_id") REFERENCES "schemes"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "scheme_enrollments" ADD CONSTRAINT "scheme_enrollments_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "customers"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "scheme_payments" ADD CONSTRAINT "scheme_payments_enrollment_id_fkey" FOREIGN KEY ("enrollment_id") REFERENCES "scheme_enrollments"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "scheme_payments" ADD CONSTRAINT "scheme_payments_collected_by_fkey" FOREIGN KEY ("collected_by") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ledger_parties" ADD CONSTRAINT "ledger_parties_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "tenants"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ledger_entries" ADD CONSTRAINT "ledger_entries_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "tenants"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ledger_entries" ADD CONSTRAINT "ledger_entries_party_id_fkey" FOREIGN KEY ("party_id") REFERENCES "ledger_parties"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ledger_entries" ADD CONSTRAINT "ledger_entries_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "notification_templates" ADD CONSTRAINT "notification_templates_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "tenants"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "notification_log" ADD CONSTRAINT "notification_log_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "tenants"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "notification_log" ADD CONSTRAINT "notification_log_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "customers"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "notification_log" ADD CONSTRAINT "notification_log_template_id_fkey" FOREIGN KEY ("template_id") REFERENCES "notification_templates"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "audit_log" ADD CONSTRAINT "audit_log_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "tenants"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "audit_log" ADD CONSTRAINT "audit_log_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
