CREATE TABLE IF NOT EXISTS collection.partner_investment (
    id SERIAL PRIMARY KEY,
    partner_id INT REFERENCES collection.partner(id),
    investment_id INT REFERENCES collection.investment(id),
    percentage NUMERIC(10, 2) NOT NULL,
    date_created DATE DEFAULT CURRENT_DATE,
    active BOOLEAN DEFAULT TRUE,
    last_updated_date DATE DEFAULT CURRENT_DATE
);

ALTER TABLE collection.investment 
    ADD COLUMN id_partner_inv INT REFERENCES collection.partner_investment(id);

ALTER TABLE collection.investment 
    RENAME COLUMN management_term_date TO end_date;
