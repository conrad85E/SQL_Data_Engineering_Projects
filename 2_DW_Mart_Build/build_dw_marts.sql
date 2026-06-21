-- duckdb dw_marts.duckdb -c ".read build_dw_marts.sql"

-- Step 1: DW - Create star schema tables
.read 01_create_tables_dw.sql

-- Step 2: DW - Load data from CSV files into tables
.read 02_load_schema_dw.sql

-- Step 3: Mart - Create flat mart
.read 03_create_flat_mart.sql

-- Step 4: Mart - Create Skills Demand mart
.read 04_create_skills_mart.sql

-- Step 5: Mart - Create Priority mart
.read 05_create_priority_mart.sql

-- Step 6: Mart - Update Priority mart
.read 06_update_priority_mart.sql

-- Step 7: Mart - Create company mart
.read 07_create_company_mart.sql