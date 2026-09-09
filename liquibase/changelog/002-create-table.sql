--liquibase formatted sql

--changeset paylite:002
CREATE TABLE IF NOT EXISTS paylite.employee (
    employee_id   BIGSERIAL    PRIMARY KEY,
    employee_name VARCHAR(100) NOT NULL,
    department    VARCHAR(100),
    salary        NUMERIC(12,2),
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

--rollback DROP TABLE paylite.employee;

-- The rollback block is the UNDO instruction for this changeset.
-- Liquibase executes this SQL when rolling back changeset paylite:002.
--
-- Rollback order - Liquibase rolls back in REVERSE order:
--   Forward:  001 (schema) -> 002 (table)
--   Rollback: 002 (table)  -> 001 (schema)
--
-- This is correct because you cannot drop a schema that still contains tables.
-- Liquibase enforces this automatically when you rollback multiple changesets.
--
-- DROP TABLE vs DROP TABLE IF EXISTS:
--   Liquibase already knows the changeset was applied (it is in DATABASECHANGELOG),
--   so the table is expected to exist - plain DROP TABLE is fine here.
