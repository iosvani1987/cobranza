-- 1. Crear la tabla de productos primero (será referenciada por credits)
CREATE TABLE IF NOT EXISTS collection.products (
    id SERIAL PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    product_code VARCHAR(20) UNIQUE NOT NULL,
    description TEXT,
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

--2. Crear tipo enumerado para tipos de identificación
CREATE TYPE identification_type AS ENUM (
    'RFC', 
    'CURP', 
    'INE', 
    'NSS',
    'Pasaporte', 
    'Licencia'
);

--3. Crear tipo enumerado para estados civiles
CREATE TYPE marital_status_type AS ENUM (
    'Soltero',
    'Casado',
    'Divorciado',
    'Viudo',
    'Unión Libre',
    'Separado'
);

-- 4. Crear tipo enumerado para sexo
CREATE TYPE gender_type AS ENUM (
    'Masculino',
    'Femenino',
    'Otro'
);

--5. Crear Enum para entidades federativas mexico
CREATE TYPE state_type AS ENUM (
    'Aguascalientes',
    'Baja California',
    'Baja California Sur',
    'Campeche',
    'Coahuila',
    'Colima',
    'Chiapas',
    'Chihuahua',
    'Ciudad de México',
    'Durango',
    'Guanajuato',
    'Guerrero',
    'Hidalgo',
    'Jalisco',
    'México',
    'Michoacán',
    'Morelos',
    'Nayarit',
    'Nuevo León',
    'Oaxaca',
    'Puebla',
    'Querétaro',
    'Quintana Roo',
    'San Luis Potosí',
    'Sinaloa',
    'Sonora',
    'Tabasco',
    'Tamaulipas',
    'Tlaxcala',
    'Veracruz',
    'Yucatán',
    'Zacatecas',
    'Otro'
);

--6. Crear la tabla de deudores
CREATE TABLE IF NOT EXISTS collection.debtors (
    id SERIAL PRIMARY KEY,

    -- Información básica
    name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    second_last_name VARCHAR(100),
    birth_date DATE,
    birth_place VARCHAR(100),
    gender gender_type,
    marital_status marital_status_type,
    nationality VARCHAR(50) DEFAULT 'Mexicana',
    status VARCHAR(20) CHECK (status IN ('processing', 'located', 'not_located', 'died')),
    notes TEXT,

    -- Información laboral
    occupation VARCHAR(100),
    company_name VARCHAR(100),
    company_phone VARCHAR(20),
    monthly_income NUMERIC(12,2),
    employment_seniority VARCHAR(50), -- Ej: "2 años 6 meses"
        
    -- Documentación
    has_ine BOOLEAN DEFAULT FALSE,
    has_proof_of_address BOOLEAN DEFAULT FALSE,
    has_income_proof BOOLEAN DEFAULT FALSE,
    
    -- Metadatos
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50),
    last_updated_by VARCHAR(50)
);

--7. Crear tabla de identificaciones
CREATE TABLE IF NOT EXISTS collection.debtor_identifications (
    id SERIAL PRIMARY KEY,
    debtor_id INT NOT NULL REFERENCES collection.debtors(id) ON DELETE CASCADE,
    identification_type identification_type NOT NULL,
    identification_number VARCHAR(30) NOT NULL,
    issue_date DATE, -- Fecha de emisión
    expiration_date DATE, -- Fecha de expiración
    is_primary BOOLEAN DEFAULT FALSE,
    verification_status VARCHAR(20) CHECK (verification_status IN ('pending', 'verified', 'rejected', 'expired')),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_identification UNIQUE (identification_type, identification_number)
);

--8. Crear la tabla de créditos
CREATE TABLE IF NOT EXISTS collection.credits (
    id SERIAL PRIMARY KEY,
    investment_id INT NOT NULL REFERENCES collection.investment(id) ON DELETE CASCADE,
    product_id INT NOT NULL REFERENCES collection.products(id) ON DELETE RESTRICT,
    debtor_id INT NOT NULL REFERENCES collection.debtors(id) ON DELETE CASCADE,

    -- Información del crédito
    contract_number VARCHAR(20) NOT NULL,
    opening_date DATE NOT NULL, -- Fecha de apertura del crédito
    utilized_amount NUMERIC(15,2) NOT NULL DEFAULT 0, -- Importe Ejercido
    total_financed NUMERIC(15,2), -- Importe Total Financiado
    current_balance NUMERIC(15,2), -- Saldo Actual
    number_of_payments INT NOT NULL DEFAULT 0, -- Número de Pagos
    payment_frequency VARCHAR(20) CHECK (payment_frequency IN ('weekly', 'biweekly', 'monthly', 'quarterly')), -- Frecuencia de Pagos
    payment_amount NUMERIC(15,2), -- Monto de Pagos
    
    -- Seguimiento de pagos
    missed_payment_date DATE NOT NULL, -- Fecha de Impagos de Pagos
    outstanding_capital NUMERIC(15, 2) NOT NULL,
    capital_without_interest NUMERIC(15, 2), -- Capital sin intereses sin moratorios a la fecha de compra
    ordinary_interest NUMERIC(15, 2), -- Intereses Ordinarios
    collection_expense_amount NUMERIC(15, 2), -- Gastos de Cobranza
    balance_date DATE, -- Fecha de Saldo

    -- Clasificación de cobranza
    credit_type VARCHAR(30) CHECK (credit_type IN ('traditional', 'revolving', 'other')) DEFAULT NULL, -- Tipo de Crédito
    contract_type VARCHAR(30) CHECK (contract_type IN ('new', 'renewal', 'other')) DEFAULT NULL, -- Tipo de Contrato
    market_type VARCHAR(30) CHECK (market_type IN ('formal', 'informal', 'other')) DEFAULT NULL, -- Tipo de Mercado

    -- Beneficiario seguro
    beneficiary_name VARCHAR(100),
    beneficiary_relationship VARCHAR(100),
    credit_purpose VARCHAR(100),

    -- Gestión de cobranza
    probability_of_collection SMALLINT NOT NULL DEFAULT 3 CHECK (probability_of_collection BETWEEN 1 AND 5),
    credit_status VARCHAR(20) NOT NULL CHECK (credit_status IN ('active', 'late', 'defaulted', 'restructured', 'paid')),
    collection_stage VARCHAR(20) DEFAULT 'pre_legal' CHECK (collection_stage IN ('pre_legal', 'legal', 'closed')),

    -- Auditoría
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

--9. Crear la tabla de pagarés (relación 1:1 con créditos)
CREATE TABLE IF NOT EXISTS collection.promissory_notes (
    id SERIAL PRIMARY KEY,
    credit_id INT UNIQUE NOT NULL REFERENCES collection.credits(id) ON DELETE CASCADE,
    states_jurisdiction state_type,
    city_jurisdiction VARCHAR(100),
    amount NUMERIC(15,2) NOT NULL,
    has_original BOOLEAN DEFAULT TRUE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP   
);

--10. Índices para mejorar el rendimiento
CREATE INDEX idx_debtor_identifications ON collection.debtor_identifications(debtor_id);
CREATE INDEX idx_credits_investment ON collection.credits(investment_id);
CREATE INDEX idx_credits_product ON collection.credits(product_id);
CREATE INDEX idx_credits_debtor ON collection.credits(debtor_id);
CREATE INDEX idx_credits_status ON collection.credits(credit_status);
CREATE INDEX idx_promissory_credit ON collection.promissory_notes(credit_id);
