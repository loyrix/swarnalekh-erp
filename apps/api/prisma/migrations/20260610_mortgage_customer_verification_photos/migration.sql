DO $$
BEGIN
  IF to_regclass('mortgage_loans') IS NOT NULL THEN
    ALTER TABLE "mortgage_loans"
    ADD COLUMN IF NOT EXISTS "photo_id_url" TEXT,
    ADD COLUMN IF NOT EXISTS "customer_photo_url" TEXT;
  END IF;
END $$;
