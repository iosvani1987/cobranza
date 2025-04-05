-- Create a function to set the end_date
CREATE OR REPLACE FUNCTION set_end_date()
RETURNS TRIGGER AS $$
BEGIN
    NEW.end_date := NEW.investment_date + INTERVAL '10 months';
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create a trigger that uses the function before insert
CREATE TRIGGER before_insert_investment
BEFORE INSERT ON collection.investment
FOR EACH ROW EXECUTE FUNCTION set_end_date();