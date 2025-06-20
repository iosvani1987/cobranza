ALTER TABLE collection.debtors
ADD COLUMN economic_dependents INT 
DEFAULT 0
CHECK (economic_dependents >= 0);