ALTER TABLE collection.investment DROP COLUMN IF EXISTS id_partner_inv;

ALTER TABLE collection.partner_investment
ADD CONSTRAINT unique_partner_investment UNIQUE (partner_id, investment_id),
ADD CONSTRAINT valid_percentage CHECK (percentage > 0 AND percentage <= 100);

CREATE OR REPLACE FUNCTION validate_investment_percentage()
RETURNS TRIGGER AS $$
DECLARE
    total_percentage NUMERIC(10, 2);
BEGIN
    SELECT SUM(percentage) INTO total_percentage
    FROM collection.partner_investment
    WHERE investment_id = NEW.investment_id;
    
    IF total_percentage > 100 THEN
        RAISE EXCEPTION 'La suma de porcentajes para la inversión % no puede exceder 100%%', NEW.investment_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_investment_percentage
AFTER INSERT OR UPDATE ON collection.partner_investment
FOR EACH ROW EXECUTE FUNCTION validate_investment_percentage();