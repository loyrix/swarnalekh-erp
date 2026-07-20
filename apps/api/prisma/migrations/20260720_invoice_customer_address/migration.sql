-- Store the customer's billing address on the invoice snapshot so the printable
-- bill can render a full "Bill To" block (walk-in and saved customers alike).
ALTER TABLE "invoices" ADD COLUMN "customer_address" TEXT;
