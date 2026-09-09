--liquibase formatted sql

--changeset paylite:001
-- Marks the start of a changeset. Everything below this line (until the next
-- --changeset or end of file) is ONE atomic unit of work.

CREATE SCHEMA IF NOT EXISTS paylite;

--rollback DROP SCHEMA paylite;


-- The rollback block is the UNDO instruction for this changeset.
-- Liquibase executes this when you run:
--   liquibase rollbackCount 1  -> undo the last 1 changeset
--   liquibase rollback <tag>   -> undo back to a named tag
--
-- DROP SCHEMA paylite drops the schema AND everything inside it (tables, sequences, etc.)
-- This is the exact reverse of CREATE SCHEMA above.
--
-- Without a --rollback block, Liquibase will refuse to roll back this changeset
-- because it cannot auto-generate the undo SQL for DDL statements.
