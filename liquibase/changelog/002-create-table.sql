--liquibase formatted sql
-- Liquibase SQL format marker - required as the first line.

--changeset paylite:002
-- Changeset 002 - depends on 001 having run first (paylite schema must exist).
-- Liquibase guarantees order because the master changelog includes 001 before 002.
--
-- If this changeset fails mid-run, Liquibase rolls it back (if the DB supports it)
-- and records a FAILED entry in DATABASECHANGELOG - it will retry on next update.

CREATE TABLE IF NOT EXISTS paylite.employee (
-- paylite.employee
--   paylite  = schema name (created by changeset 001)
--   employee = table name

    employee_id   BIGSERIAL    PRIMARY KEY,
    -- BIGSERIAL = auto-incrementing BIGINT (8-byte integer)
    -- PRIMARY KEY = unique + not null + clustered index
    -- Liquibase does NOT auto-generate surrogate keys - you define them explicitly.

    employee_name VARCHAR(100) NOT NULL,
    -- VARCHAR(100) = variable-length string, max 100 characters
    -- NOT NULL = this column must always have a value

    department    VARCHAR(100),
    -- Nullable - an employee can exist before being assigned to a department

    salary        NUMERIC(12,2),
    -- NUMERIC(12,2) = up to 12 digits total, 2 after the decimal point
    -- Use NUMERIC (not FLOAT) for money - FLOAT has rounding errors

    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    -- TIMESTAMP = date + time, no timezone
    -- DEFAULT CURRENT_TIMESTAMP = auto-filled with the insert time if not provided
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
