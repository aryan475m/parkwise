-- ============================================================================
-- ParkWise Smart Parking System — Master Setup Script
-- Usage in SQL*Plus:
--   CONNECT <your_username>/<your_password>@<your_dsn>
--   @run_setup.sql
-- ============================================================================
SET SERVEROUTPUT ON
SET ECHO ON

@01_schema.sql
@02_seed_data.sql
@03_procedures_triggers.sql

COMMIT;
PROMPT ============================================================================
PROMPT ParkWise backend setup completed successfully!
PROMPT ============================================================================
