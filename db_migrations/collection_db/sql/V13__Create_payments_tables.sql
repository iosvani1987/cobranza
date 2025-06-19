CREATE TYPE promise_status AS ENUM (
    'Draft',            -- Promesa en creación (solo para formales)
    'Pending',          -- Promesa activa no vencida
    'PartiallyFulfilled', -- Pago parcial recibido
    'Fulfilled',        -- Promesa cumplida completamente
    'Broken',           -- Promesa no cumplida
    'Rescheduled',      -- Promesa reagendada
    'Cancelled'         -- Promesa cancelada (solo para informales)
);

CREATE TYPE promise_type AS ENUM (
    'Formal', 
    'Informal'
);

CREATE TYPE payment_frequency AS ENUM (
    'Weekly',
    'Biweekly',
    'Monthly',
    'Custom'
);

CREATE TABLE collection.payment_promises (
    promise_id SERIAL PRIMARY KEY,
    debtor_id INT NOT NULL REFERENCES collection.debtors(id) ON DELETE CASCADE,
    credit_id INT NOT NULL REFERENCES collection.credits(id) ON DELETE CASCADE,
    
    -- Promise classification
    promise_type promise_type NOT NULL,
    is_initial_deposit_required BOOLEAN GENERATED ALWAYS AS (
        CASE WHEN promise_type = 'Formal' THEN TRUE ELSE FALSE END
    ) STORED,
    
    -- Promise details
    promised_amount DECIMAL(12,2) NOT NULL CHECK (promised_amount > 0),
    initial_deposit_amount DECIMAL(12,2) CHECK (
        (promise_type = 'Formal' AND initial_deposit_amount > 0) OR
        (promise_type = 'Informal' AND initial_deposit_amount IS NULL)
    ),
    promised_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    due_date TIMESTAMP NOT NULL,
    
    -- Payment schedule (for formal promises)
    payment_frequency payment_frequency,
    number_of_payments INT CHECK (
        (promise_type = 'Formal' AND number_of_payments > 0) OR
        (promise_type = 'Informal' AND number_of_payments IS NULL)
    ),
    next_payment_date TIMESTAMP CHECK (
        (promise_type = 'Formal' AND next_payment_date IS NOT NULL) OR
        (promise_type = 'Informal' AND next_payment_date IS NULL)
    ),
    
    -- Tracking and status
    status promise_status NOT NULL DEFAULT 'Pending',
    remaining_amount DECIMAL(12,2) GENERATED ALWAYS AS (promised_amount - initial_deposit_amount) STORED,

    -- Additional information
    verbal_agreement_details TEXT CHECK (
        (promise_type = 'Informal' AND verbal_agreement_details IS NOT NULL) OR
        (promise_type = 'Formal' AND verbal_agreement_details IS NULL)
    ),
    cancellation_reason TEXT CHECK (
        (status = 'Cancelled' AND cancellation_reason IS NOT NULL) OR
        (status <> 'Cancelled' AND cancellation_reason IS NULL)
    ),
    
    -- Audit
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50) NOT NULL,
    updated_by VARCHAR(50),
    
    -- Constraints
    CONSTRAINT valid_dates CHECK (due_date > promised_date),
    CONSTRAINT formal_promise_requirements CHECK (
        (promise_type = 'Formal' AND 
         payment_frequency IS NOT NULL AND 
         number_of_payments IS NOT NULL AND
         next_payment_date IS NOT NULL) OR
        promise_type = 'Informal'
    ),
    CONSTRAINT initial_deposit_constraint CHECK (
        (promise_type = 'Formal' AND initial_deposit_amount > 0 AND initial_deposit_amount < promised_amount) OR
        promise_type = 'Informal'
    )
);

-- Payments table for tracking payments made against promises
CREATE TYPE payment_status AS ENUM (
    'PendingVerification', -- Pago reportado pero no confirmado
    'Confirmed',         -- Pago verificado y aplicado
    'Rejected',          -- Pago inválido o rechazado
    'Reversed'           -- Pago revertido (contracargo)
);

CREATE TYPE payment_category AS ENUM (
    'InitialDeposit',
    'Installment',
    'PartialPayment',
    'FullPayment',
    'AdvancePayment'
);

CREATE TABLE collection.payments (
    payment_id SERIAL PRIMARY KEY,
    promise_id INT REFERENCES collection.payment_promises(promise_id) ON DELETE SET NULL,
    debtor_id INT NOT NULL REFERENCES collection.debtors(id) ON DELETE CASCADE,
    credit_id INT NOT NULL REFERENCES collection.credits(id) ON DELETE CASCADE,
    
    -- Payment details
    amount DECIMAL(12,2) NOT NULL CHECK (amount > 0),
    payment_date TIMESTAMP NOT NULL,
    receipt_number VARCHAR(50),
    payment_method VARCHAR(20) NOT NULL CHECK (payment_method IN (
        'Cash', 'BankTransfer', 'CreditCard', 'DebitCard', 'PaymentCenter', 'Other'
    )),
    payment_category payment_category NOT NULL,
    
    -- Status and verification
    status payment_status NOT NULL DEFAULT 'PendingVerification',
    verification_date TIMESTAMP,
    verified_by VARCHAR(50),
    rejection_reason TEXT,
    
    -- Additional information
    bank_reference VARCHAR(100),
    transaction_id VARCHAR(100),
    is_deposit BOOLEAN GENERATED ALWAYS AS (
        CASE WHEN payment_category = 'InitialDeposit' THEN TRUE ELSE FALSE END
    ) STORED,
    
    -- Audit
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50) NOT NULL,
    updated_by VARCHAR(50),
    
    -- Constraints
    CONSTRAINT valid_payment_date CHECK (payment_date <= CURRENT_TIMESTAMP),
    CONSTRAINT receipt_required_for_confirmed CHECK (
        (status IN ('Confirmed', 'Reversed') AND receipt_number IS NOT NULL) OR
        status IN ('PendingVerification', 'Rejected')
    )
);

-- Payment schedule for formal promises
CREATE TABLE collection.promise_payment_schedule (
    schedule_id SERIAL PRIMARY KEY,
    promise_id INT NOT NULL REFERENCES collection.payment_promises(promise_id) ON DELETE CASCADE,
    installment_number INT NOT NULL,
    due_date TIMESTAMP NOT NULL,
    amount DECIMAL(12,2) NOT NULL CHECK (amount > 0),
    status VARCHAR(20) NOT NULL DEFAULT 'Pending' CHECK (status IN (
        'Pending', 'Paid', 'Overdue', 'Cancelled'
    )),
    
    -- Payment reference (if paid)
    payment_id INT REFERENCES collection.payments(payment_id),
    
    -- Audit
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT unique_installment UNIQUE (promise_id, installment_number),
    CONSTRAINT valid_installment_number CHECK (installment_number > 0)
);

-- Indexes for optimization
CREATE INDEX idx_promises_debtor ON collection.payment_promises(debtor_id);
CREATE INDEX idx_promises_credit ON collection.payment_promises(credit_id);
CREATE INDEX idx_promises_status ON collection.payment_promises(status);
CREATE INDEX idx_promises_due_date ON collection.payment_promises(due_date);
CREATE INDEX idx_promises_type ON collection.payment_promises(promise_type);

CREATE INDEX idx_schedule_promise ON collection.promise_payment_schedule(promise_id);
CREATE INDEX idx_schedule_status ON collection.promise_payment_schedule(status);
CREATE INDEX idx_schedule_due_date ON collection.promise_payment_schedule(due_date);

CREATE INDEX idx_payments_debtor ON collection.payments(debtor_id);
CREATE INDEX idx_payments_credit ON collection.payments(credit_id);
CREATE INDEX idx_payments_promise ON collection.payments(promise_id);
CREATE INDEX idx_payments_status ON collection.payments(status);
CREATE INDEX idx_payments_date ON collection.payments(payment_date);
CREATE INDEX idx_payments_category ON collection.payments(payment_category);