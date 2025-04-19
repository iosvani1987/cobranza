-- Create enum types for option fields
CREATE TYPE reference_relationship_type AS ENUM (
    'Family',
    'Friend',
    'Coworker',
    'Acquaintance',
    'Spouse',
    'Other'
);

CREATE TYPE reference_status_type AS ENUM (
    'New',
    'Active',
    'Inactive',
    'Verified',
    'Invalid'
);

-- Create the debtor references table
CREATE TABLE IF NOT EXISTS collection.debtor_references (
    id SERIAL PRIMARY KEY,
    debtor_id INT NOT NULL REFERENCES collection.debtors(id) ON DELETE CASCADE,
    
    -- Reference details
    name VARCHAR(100) NOT NULL,
    relationship reference_relationship_type NOT NULL,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(100),
    
    -- Metadata and status
    status reference_status_type NOT NULL DEFAULT 'New',
    attempt_count INT NOT NULL DEFAULT 0,
    
    -- Audit fields
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50),
    updated_by VARCHAR(50),
    
    -- Constraints
    CONSTRAINT unique_reference UNIQUE (debtor_id, name, phone)
);

-- Create indexes for performance
CREATE INDEX idx_debtor_references_debtor ON collection.debtor_references(debtor_id);
CREATE INDEX idx_debtor_references_status ON collection.debtor_references(status);
CREATE INDEX idx_debtor_references_phone ON collection.debtor_references(phone);