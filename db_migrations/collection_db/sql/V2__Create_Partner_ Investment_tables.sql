CREATE TABLE IF NOT EXISTS collection.partner (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    second_last_name VARCHAR(50),  -- Optional (not all have second last name)
    phone VARCHAR(20),   -- Use VARCHAR for international formats
    email VARCHAR(100) CHECK (email LIKE '%@%.%'), 
    date_created DATE DEFAULT CURRENT_DATE,
    active BOOLEAN DEFAULT TRUE,
    last_updated_date DATE DEFAULT CURRENT_DATE
);

-- CREATE TABLE IF NOT EXISTS collection.partner_investment (
--     partner_id INT REFERENCES collection.partner(id),
--     investment_id INT REFERENCES collection.investment(id),
--     percentage NUMERIC(10, 2) NOT NULL,
--     date_created DATE DEFAULT CURRENT_DATE,
--     active BOOLEAN DEFAULT TRUE,
--     last_updated_date DATE DEFAULT CURRENT_DATE,
--     PRIMARY KEY (partner_id, investment_id)
-- );

-- Existing table creation
CREATE TABLE IF NOT EXISTS collection.investment (
    id SERIAL PRIMARY KEY,
    -- id_partner_inv INT REFERENCES collection.partner_investment(id),
    portafolio_origin VARCHAR(50) NOT NULL,
    investment_date DATE NOT NULL,
    outstanding_capital NUMERIC(10, 2) NOT NULL,
    investment_amount NUMERIC(10, 2) NOT NULL,
    management_term_date DATE, -- Remove default here
    date_created DATE DEFAULT CURRENT_DATE,
    active BOOLEAN DEFAULT TRUE,
    last_updated_date DATE DEFAULT CURRENT_DATE
);