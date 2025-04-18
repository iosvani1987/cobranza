-- Create enum types for option fields (keeping only necessary ones)
CREATE TYPE address_source_type AS ENUM (
    'Credit File', 
    'Third Party', 
    'Credit Bureau', 
    'Investigation', 
    'Search Warrant', 
    'RPP', 
    'Other'
);

CREATE TYPE address_type AS ENUM (
    'Owned',
    'Rented',
    'Family',
    'Work',
    'Other'
);

CREATE TYPE address_condition_type AS ENUM (
    'Normal',
    'Abandoned',
    'Vandalized'
);

CREATE TYPE address_status_type AS ENUM (
    'Active',
    'Inactive',
    'Under Review'
);

-- Create zones table first
CREATE TABLE IF NOT EXISTS collection.zones (
    id SERIAL PRIMARY KEY,
    zone_name VARCHAR(50) NOT NULL,
    description TEXT,
    
    -- Polygon defined by northwest and southeast points
    northwest_lat DECIMAL(10, 8) NOT NULL,
    northwest_lng DECIMAL(11, 8) NOT NULL,
    southeast_lat DECIMAL(10, 8) NOT NULL,
    southeast_lng DECIMAL(11, 8) NOT NULL,
    
    -- Zone characteristics
    collection_difficulty INT CHECK (collection_difficulty BETWEEN 1 AND 5),
    
    -- Audit fields
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create the debtor addresses table with zone relationship
CREATE TABLE IF NOT EXISTS collection.debtor_addresses (
    id SERIAL PRIMARY KEY,
    debtor_id INT NOT NULL REFERENCES collection.debtors(id) ON DELETE CASCADE,
    zone_id INT REFERENCES collection.zones(id) ON DELETE SET NULL,

    -- Source information
    source address_source_type NOT NULL,
    source_notes VARCHAR(200),
    
    -- Address details
    address_type address_type NOT NULL,
    street VARCHAR(100) NOT NULL,
    neighborhood VARCHAR(100),
    city VARCHAR(100) NOT NULL,
    state VARCHAR(50) NOT NULL,
    postal_code VARCHAR(10),
    reference_points VARCHAR(200),
    
    -- Metadata
    is_primary BOOLEAN DEFAULT FALSE,
    condition address_condition_type,
    description TEXT,
    
    -- Geolocation
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    
    -- Media
    facade_image VARCHAR(255),
    
    -- Tracking
    status address_status_type NOT NULL DEFAULT 'Active',
    
    -- Audit fields
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50),
    updated_by VARCHAR(50),
    
    -- Constraints
    CONSTRAINT valid_coordinates CHECK (
        (latitude IS NULL AND longitude IS NULL) OR
        (latitude BETWEEN -90 AND 90 AND longitude BETWEEN -180 AND 180)
    )
);

-- Create indexes for performance
CREATE INDEX idx_debtor_addresses_debtor ON collection.debtor_addresses(debtor_id);
CREATE INDEX idx_debtor_addresses_location ON collection.debtor_addresses(state, city);
CREATE INDEX idx_debtor_addresses_zone ON collection.debtor_addresses(zone_id);
CREATE INDEX idx_debtor_addresses_coords ON collection.debtor_addresses(latitude, longitude);