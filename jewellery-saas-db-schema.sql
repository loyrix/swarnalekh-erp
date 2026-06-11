-- ============================================
-- JEWELLERY SHOP MANAGEMENT SaaS - DB SCHEMA
-- Multi-tenant PostgreSQL Schema
-- ============================================

-- ==================
-- TENANT & AUTH
-- ==================

CREATE TABLE tenants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shop_name VARCHAR(200) NOT NULL,
    owner_name VARCHAR(150) NOT NULL,
    phone VARCHAR(15) NOT NULL UNIQUE,
    email VARCHAR(200),
    address TEXT,
    city VARCHAR(100),
    state VARCHAR(100),
    pincode VARCHAR(10),
    gstin VARCHAR(20),              -- GST number (optional for small shops)
    pan VARCHAR(15),
    logo_url TEXT,
    subscription_plan VARCHAR(20) DEFAULT 'free',  -- free, silver, gold, platinum
    subscription_expires_at TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    name VARCHAR(150) NOT NULL,
    phone VARCHAR(15) NOT NULL,
    email VARCHAR(200),
    password_hash TEXT NOT NULL,
    role VARCHAR(20) DEFAULT 'staff',  -- owner, manager, staff
    is_active BOOLEAN DEFAULT true,
    last_login_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_users_tenant ON users(tenant_id);
CREATE INDEX idx_users_phone ON users(phone);

-- ==================
-- CUSTOMERS (CRM)
-- ==================

CREATE TABLE customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    name VARCHAR(200) NOT NULL,
    phone VARCHAR(15),
    alt_phone VARCHAR(15),
    email VARCHAR(200),
    address TEXT,
    city VARCHAR(100),
    pincode VARCHAR(10),
    -- KYC
    aadhar_number VARCHAR(20),
    pan_number VARCHAR(15),
    kyc_doc_url TEXT,
    -- Preferences (jewellers track this for families)
    preferred_karat VARCHAR(10),       -- 22K, 18K, etc
    family_details JSONB,              -- { spouse: "name", children: [...], anniversaries: [...] }
    notes TEXT,
    -- Stats (denormalized for quick access)
    total_purchases NUMERIC(14,2) DEFAULT 0,
    total_visits INT DEFAULT 0,
    last_visit_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_customers_tenant ON customers(tenant_id);
CREATE INDEX idx_customers_phone ON customers(tenant_id, phone);
CREATE INDEX idx_customers_name ON customers(tenant_id, name);

-- ==================
-- INVENTORY
-- ==================

CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    name VARCHAR(100) NOT NULL,          -- Ring, Necklace, Bangle, Chain, Earring, etc.
    parent_id UUID REFERENCES categories(id),  -- For sub-categories
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE inventory_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    -- Identification
    tag_number VARCHAR(50),              -- Physical tag / barcode on item
    barcode VARCHAR(100),
    category_id UUID REFERENCES categories(id),
    item_name VARCHAR(200),              -- "22K Gold Mangalsutra"
    description TEXT,
    -- Metal details
    metal_type VARCHAR(20) NOT NULL,     -- gold, silver, platinum, diamond
    karat VARCHAR(10),                   -- 24K, 22K, 18K, 14K
    purity NUMERIC(6,3),                 -- 91.6 for 22K, 75.0 for 18K
    gross_weight NUMERIC(10,3) NOT NULL, -- grams (with stones)
    net_weight NUMERIC(10,3) NOT NULL,   -- grams (metal only)
    -- Stone details
    has_stones BOOLEAN DEFAULT false,
    stone_details JSONB,                 -- [{ type: "diamond", weight: 0.5, count: 3, rate: 50000 }]
    stone_value NUMERIC(12,2) DEFAULT 0,
    -- Pricing
    making_charges_per_gram NUMERIC(10,2),
    making_charges_fixed NUMERIC(10,2),
    making_charges_percent NUMERIC(5,2), -- % of metal value
    wastage_percent NUMERIC(5,2) DEFAULT 0,
    -- Source
    source VARCHAR(20),                  -- purchased, karigar, exchange
    karigar_id UUID,                     -- If made by artisan
    purchase_rate NUMERIC(10,2),         -- Rate at which purchased/made
    purchase_date DATE,
    -- Photos
    photos JSONB,                        -- ["url1", "url2"]
    -- Hallmark
    hallmark_number VARCHAR(50),
    huid VARCHAR(20),                    -- Hallmark Unique ID (mandatory in India now)
    -- Status
    status VARCHAR(20) DEFAULT 'in_stock', -- in_stock, sold, reserved, on_approval, melted
    location VARCHAR(100),               -- Which display / safe / branch
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_inventory_tenant ON inventory_items(tenant_id);
CREATE INDEX idx_inventory_status ON inventory_items(tenant_id, status);
CREATE INDEX idx_inventory_metal ON inventory_items(tenant_id, metal_type, karat);
CREATE INDEX idx_inventory_tag ON inventory_items(tenant_id, tag_number);
CREATE INDEX idx_inventory_barcode ON inventory_items(tenant_id, barcode);

-- Daily gold/silver rates
CREATE TABLE daily_rates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    rate_date DATE NOT NULL,
    metal_type VARCHAR(20) NOT NULL,     -- gold, silver, platinum
    karat VARCHAR(10),                   -- For gold: 24K, 22K, 18K
    rate_per_gram NUMERIC(10,2) NOT NULL,
    source VARCHAR(50) DEFAULT 'manual', -- manual, ibja_api
    set_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(tenant_id, rate_date, metal_type, karat)
);

-- Karigars (artisans)
CREATE TABLE karigars (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    name VARCHAR(200) NOT NULL,
    phone VARCHAR(15),
    specialization VARCHAR(100),         -- Ring making, chain, kundan, etc.
    address TEXT,
    balance NUMERIC(12,2) DEFAULT 0,     -- Outstanding metal/money
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- ==================
-- BILLING & INVOICES
-- ==================

CREATE TABLE invoices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    invoice_number VARCHAR(50) NOT NULL, -- Auto-generated: INV-2026-0001
    invoice_date DATE NOT NULL DEFAULT CURRENT_DATE,
    customer_id UUID REFERENCES customers(id),
    -- Customer snapshot (in case customer record changes later)
    customer_name VARCHAR(200),
    customer_phone VARCHAR(15),
    customer_gstin VARCHAR(20),
    -- Type
    invoice_type VARCHAR(20) DEFAULT 'sale', -- sale, purchase, exchange, repair
    -- Totals
    subtotal NUMERIC(14,2) NOT NULL,
    total_making_charges NUMERIC(12,2) DEFAULT 0,
    total_stone_value NUMERIC(12,2) DEFAULT 0,
    discount_amount NUMERIC(12,2) DEFAULT 0,
    discount_percent NUMERIC(5,2),
    -- Old gold exchange
    old_gold_weight NUMERIC(10,3) DEFAULT 0,
    old_gold_karat VARCHAR(10),
    old_gold_rate NUMERIC(10,2),
    old_gold_value NUMERIC(12,2) DEFAULT 0,
    -- Tax
    taxable_amount NUMERIC(14,2) NOT NULL,
    cgst_percent NUMERIC(5,2) DEFAULT 1.5,
    cgst_amount NUMERIC(12,2) DEFAULT 0,
    sgst_percent NUMERIC(5,2) DEFAULT 1.5,
    sgst_amount NUMERIC(12,2) DEFAULT 0,
    igst_percent NUMERIC(5,2) DEFAULT 0,
    igst_amount NUMERIC(12,2) DEFAULT 0,
    total_tax NUMERIC(12,2) DEFAULT 0,
    -- Grand total
    grand_total NUMERIC(14,2) NOT NULL,
    round_off NUMERIC(5,2) DEFAULT 0,
    -- Payment
    payment_mode VARCHAR(30),            -- cash, upi, card, mixed, credit
    amount_paid NUMERIC(14,2) DEFAULT 0,
    balance_due NUMERIC(14,2) DEFAULT 0,
    -- Metadata
    notes TEXT,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_invoices_tenant ON invoices(tenant_id);
CREATE INDEX idx_invoices_customer ON invoices(tenant_id, customer_id);
CREATE INDEX idx_invoices_date ON invoices(tenant_id, invoice_date);
CREATE INDEX idx_invoices_number ON invoices(tenant_id, invoice_number);

CREATE TABLE invoice_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_id UUID NOT NULL REFERENCES invoices(id),
    inventory_item_id UUID REFERENCES inventory_items(id),
    -- Item snapshot
    item_name VARCHAR(200),
    metal_type VARCHAR(20),
    karat VARCHAR(10),
    gross_weight NUMERIC(10,3),
    net_weight NUMERIC(10,3),
    rate_per_gram NUMERIC(10,2),
    metal_value NUMERIC(12,2),
    making_charges NUMERIC(10,2),
    stone_value NUMERIC(12,2) DEFAULT 0,
    wastage_value NUMERIC(10,2) DEFAULT 0,
    hallmark_number VARCHAR(50),
    huid VARCHAR(20),
    item_total NUMERIC(12,2) NOT NULL
);

CREATE INDEX idx_invoice_items_invoice ON invoice_items(invoice_id);

-- Payment tracking (for partial / mixed payments)
CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    invoice_id UUID REFERENCES invoices(id),
    customer_id UUID REFERENCES customers(id),
    amount NUMERIC(14,2) NOT NULL,
    payment_mode VARCHAR(30) NOT NULL,   -- cash, upi, card, bank_transfer, cheque
    payment_date DATE DEFAULT CURRENT_DATE,
    reference_number VARCHAR(100),       -- UPI ref, cheque no, etc.
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- ==================
-- SCHEMES (Monthly Gold Saving Plans)
-- ==================

CREATE TABLE schemes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    scheme_name VARCHAR(200) NOT NULL,   -- "Diwali Gold Scheme 2026"
    duration_months INT NOT NULL,        -- 11, 12, 18, 24
    monthly_amount NUMERIC(10,2),        -- Fixed monthly (if applicable)
    bonus_description TEXT,              -- "12th month free" or "5% bonus on maturity"
    bonus_type VARCHAR(20),              -- free_month, percentage, fixed_amount
    bonus_value NUMERIC(10,2),
    is_active BOOLEAN DEFAULT true,
    start_date DATE,
    end_date DATE,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE scheme_enrollments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    scheme_id UUID NOT NULL REFERENCES schemes(id),
    customer_id UUID NOT NULL REFERENCES customers(id),
    enrollment_number VARCHAR(50),       -- SCHEME-2026-0001
    enrollment_date DATE DEFAULT CURRENT_DATE,
    monthly_amount NUMERIC(10,2) NOT NULL,
    total_months INT NOT NULL,
    -- Status tracking
    months_paid INT DEFAULT 0,
    total_paid NUMERIC(12,2) DEFAULT 0,
    maturity_date DATE,
    maturity_value NUMERIC(12,2),        -- Calculated maturity amount
    status VARCHAR(20) DEFAULT 'active', -- active, matured, redeemed, cancelled
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_enrollments_tenant ON scheme_enrollments(tenant_id);
CREATE INDEX idx_enrollments_customer ON scheme_enrollments(customer_id);
CREATE INDEX idx_enrollments_status ON scheme_enrollments(tenant_id, status);

CREATE TABLE scheme_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    enrollment_id UUID NOT NULL REFERENCES scheme_enrollments(id),
    payment_date DATE DEFAULT CURRENT_DATE,
    amount NUMERIC(10,2) NOT NULL,
    month_number INT NOT NULL,           -- Which month's installment
    payment_mode VARCHAR(30),
    receipt_number VARCHAR(50),
    collected_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_scheme_payments_enrollment ON scheme_payments(enrollment_id);

-- ==================
-- PERSONAL LEDGER (Generic Party Accounts)
-- ==================
-- NOTE: This is intentionally generic — "party accounts" with
-- debit/credit entries. The jeweller uses it however they want.
-- No explicit "gold loan" or "black money" labeling anywhere.

CREATE TABLE ledger_parties (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    name VARCHAR(200) NOT NULL,
    phone VARCHAR(15),
    address TEXT,
    party_type VARCHAR(30) DEFAULT 'general', -- general, supplier, karigar
    notes TEXT,
    current_balance NUMERIC(14,2) DEFAULT 0,  -- +ve = they owe us, -ve = we owe them
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_ledger_parties_tenant ON ledger_parties(tenant_id);

CREATE TABLE ledger_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    party_id UUID NOT NULL REFERENCES ledger_parties(id),
    entry_date DATE DEFAULT CURRENT_DATE,
    entry_type VARCHAR(20) NOT NULL,     -- debit (they owe more), credit (they paid)
    amount NUMERIC(14,2) NOT NULL,
    -- Optional interest tracking
    principal_amount NUMERIC(14,2),
    interest_rate_monthly NUMERIC(5,2),  -- e.g., 2.0 means 2% per month
    interest_amount NUMERIC(12,2),
    -- Collateral (generic — could be gold, property docs, anything)
    collateral_description TEXT,
    collateral_weight NUMERIC(10,3),     -- grams if applicable
    collateral_photos JSONB,             -- ["url1", "url2"]
    -- Dates
    due_date DATE,
    settled_at TIMESTAMPTZ,              -- When fully repaid
    -- Status
    status VARCHAR(20) DEFAULT 'open',   -- open, partial, settled
    notes TEXT,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_ledger_entries_party ON ledger_entries(party_id);
CREATE INDEX idx_ledger_entries_status ON ledger_entries(tenant_id, status);
CREATE INDEX idx_ledger_entries_date ON ledger_entries(tenant_id, entry_date);

-- ==================
-- NOTIFICATIONS
-- ==================

CREATE TABLE notification_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    template_name VARCHAR(100),          -- scheme_reminder, birthday_wish, payment_due
    channel VARCHAR(20) DEFAULT 'whatsapp', -- whatsapp, sms
    message_template TEXT NOT NULL,      -- "Dear {customer_name}, your scheme payment of ₹{amount} is due..."
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE notification_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    customer_id UUID REFERENCES customers(id),
    channel VARCHAR(20),
    template_id UUID REFERENCES notification_templates(id),
    message_content TEXT,
    phone VARCHAR(15),
    status VARCHAR(20) DEFAULT 'queued', -- queued, sent, delivered, failed
    sent_at TIMESTAMPTZ,
    error_message TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_notification_log_tenant ON notification_log(tenant_id);
CREATE INDEX idx_notification_log_status ON notification_log(tenant_id, status);

-- ==================
-- AUDIT LOG (important for trust)
-- ==================

CREATE TABLE audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    user_id UUID REFERENCES users(id),
    action VARCHAR(50) NOT NULL,         -- create, update, delete, login, rate_change
    entity_type VARCHAR(50),             -- invoice, inventory_item, customer, etc.
    entity_id UUID,
    old_values JSONB,
    new_values JSONB,
    ip_address VARCHAR(50),
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_audit_tenant_date ON audit_log(tenant_id, created_at DESC);
