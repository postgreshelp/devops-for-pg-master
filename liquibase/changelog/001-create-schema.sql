--liquibase formatted sql
-- This line MUST be the first line of every Liquibase SQL changelog file.
-- It tells Liquibase this file uses the SQL format (not XML/YAML/JSON).

--changeset paylite:001
-- Marks the start of a changeset. Everything below this line (until the next
-- --changeset or end of file) is ONE atomic unit of work.
--
-- Format: --changeset <author>:<id>
--   author : who wrote this changeset (used for tracking)
--   id     : must be unique within this author
--
-- Together, author:id forms the unique key Liquibase stores in DATABASECHANGELOG.
-- Once applied, Liquibase will NEVER run this changeset again on the same database.
--
-- IDEMPOTENCY - IF NOT EXISTS:
--   Without IF NOT EXISTS, re-running this outside Liquibase would error.
--   Liquibase's own tracking prevents re-runs, but IF NOT EXISTS is good
--   defensive practice and makes the SQL safe to run manually too.

CREATE SCHEMA IF NOT EXISTS paylite;
-- Creates the paylite schema (namespace) that all PayLite tables will live in.
-- Schema = a logical grouping of tables, like a folder inside a database.
-- After this runs: paylite.employee, paylite.payroll, etc. are valid object names.

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
