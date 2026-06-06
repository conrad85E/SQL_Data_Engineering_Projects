INSERT INTO company_dim (company_id, name)
SELECT
    company_id,
    name
FROM read_csv('https://storage.googleapis.com/sql_de/company_dim.csv',
    AUTO_DETECT=true);