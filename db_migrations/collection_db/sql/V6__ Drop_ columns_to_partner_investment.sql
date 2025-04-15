DO $$
BEGIN
    -- Check and drop the 'date_created' column if it exists
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name='partner_investment' 
               AND table_schema='collection'
               AND column_name='date_created') THEN
        ALTER TABLE collection.partner_investment DROP COLUMN date_created;
    END IF;

    -- Check and drop the 'active' column if it exists
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name='partner_investment' 
               AND table_schema='collection'
               AND column_name='active') THEN
        ALTER TABLE collection.partner_investment DROP COLUMN active;
    END IF;
END $$;