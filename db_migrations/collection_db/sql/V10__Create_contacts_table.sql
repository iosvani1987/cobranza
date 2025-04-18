-- 1. Crear tipos enumerados para las opciones
CREATE TYPE contact_source_type AS ENUM (
    'Credit File', 
    'Investigation', 
    'Search Warrant', 
    'Other'
);

CREATE TYPE contact_medium_type AS ENUM (
    'Phone',
    'Email',
    'Whatsapp',
    'Facebook',
    'Other Social Media'
);

CREATE TYPE contact_label_type AS ENUM (
    'Mobile',
    'Landline',
    'Work',
    'Personal',
    'Family'
);

CREATE TYPE contact_status_type AS ENUM (
    'Active',
    'Inactive',
    'Pending Verification'
);

--2. Create the debtor contacts table
CREATE TABLE IF NOT EXISTS collection.debtor_contacts (
    id SERIAL PRIMARY KEY,
    debtor_id INT NOT NULL REFERENCES collection.debtors(id) ON DELETE CASCADE,
    
    -- Source information
    contact_source contact_source_type NOT NULL,
    source_notes VARCHAR(200),
    
    -- Contact details
    contact_type contact_medium_type NOT NULL,
    contact_value VARCHAR(100) NOT NULL,
    contact_label contact_label_type NOT NULL,
    
    -- Metadata and status
    is_primary BOOLEAN DEFAULT FALSE,
    has_contact BOOLEAN NOT NULL DEFAULT FALSE,
    status contact_status_type NOT NULL DEFAULT 'Pending Verification',
    
    -- Audit fields
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT unique_contact UNIQUE (debtor_id, contact_type, contact_value),
    CONSTRAINT primary_contact_check CHECK (
        (is_primary = TRUE AND has_contact = TRUE) OR 
        is_primary = FALSE
    )
);

--3. Create indexes for performance
CREATE INDEX idx_debtor_contacts_debtor ON collection.debtor_contacts(debtor_id);
CREATE INDEX idx_debtor_contacts_main ON collection.debtor_contacts(debtor_id) WHERE is_primary = TRUE;
CREATE INDEX idx_debtor_contacts_value ON collection.debtor_contacts(contact_value);
