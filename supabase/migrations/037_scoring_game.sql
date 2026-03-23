-- Scoring Game: extend input_mode enum.
-- Must be committed separately before the new value can be used in INSERTs.
ALTER TYPE input_mode ADD VALUE IF NOT EXISTS 'ScoringGame';
