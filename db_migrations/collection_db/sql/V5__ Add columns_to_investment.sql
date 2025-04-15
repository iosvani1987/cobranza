-- Create a type for the portfolio_type
CREATE TYPE portfolio_type AS ENUM ('personal', 'automotive', 'mortgage');

-- Add the column portfolio_type to the investment table
ALTER TABLE collection.investment 
ADD COLUMN portfolio_type portfolio_type NOT NULL DEFAULT 'personal';

-- Add the column description to the investment table
ALTER TABLE collection.investment 
ADD COLUMN description VARCHAR(50);
