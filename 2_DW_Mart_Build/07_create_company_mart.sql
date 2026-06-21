-- TODOs:
-- 1. 

-- Step 7: Mart - Create company mart
 
-----------------------------------
------ DROP MART IF IT EXISTS -----
-----------------------------------
DROP SCHEMA IF EXISTS company_mart CASCADE;

-----------------------------------
------ CREATE THE MART SCHEMA -----
-----------------------------------
CREATE SCHEMA company_mart;

-----------------------------------
---- CREATE AND POPULATE TABLES ---
-----------------------------------


---- 1. Job title dimension branch consists of 3 tables:
------ 1a. dim_job_title: contains original job titles
------ 1b. dim_job_title_short: contains shortened job titles
------ 1c. bridge_job_title: a bridge btw. original & short job titles

------ 1a. Create Job Title dimension
SELECT '=== Loading Dim Job Title for Company Mart ===' AS info;

CREATE TABLE company_mart.dim_job_title (
    job_title_id    INTEGER     PRIMARY KEY,
    job_title       VARCHAR
)
;

INSERT INTO company_mart.dim_job_title (
    job_title_id,
    job_title
)
SELECT
    ROW_NUMBER() OVER (ORDER BY job_title) AS job_title_id,
    job_title
FROM (
    SELECT DISTINCT job_title
    FROM job_postings_fact
    WHERE job_title IS NOT NULL
)
;

-----------------------------------
------ 1b. Create Job Title Short dimension

SELECT '=== Loading Dim Job Title Short for Company Mart ===' AS info;

CREATE TABLE company_mart.dim_job_title_short (
    job_title_short_id    SMALLINT     PRIMARY KEY,
    job_title_short       VARCHAR
)
;

INSERT INTO company_mart.dim_job_title_short (
    job_title_short_id,
    job_title_short
)
SELECT
    ROW_NUMBER() OVER (ORDER BY job_title_short) AS job_title_short_id,
    job_title_short
FROM (
    SELECT DISTINCT job_title_short
    FROM job_postings_fact
    WHERE job_title_short IS NOT NULL
)
;

------ 1c. Create Bridge table (job_title_short <-> job_title)

SELECT '=== Loading Bridge Job Title for Company Mart ===' AS info;

CREATE TABLE company_mart.bridge_job_title (
    job_title_short_id  SMALLINT,
    job_title_id  INTEGER,
    PRIMARY KEY (job_title_short_id, job_title_id),
    FOREIGN KEY (job_title_short_id) REFERENCES company_mart.dim_job_title_short (job_title_short_id),
    FOREIGN KEY (job_title_id) REFERENCES company_mart.dim_job_title (job_title_id)
)
;

INSERT INTO company_mart.bridge_job_title (
    job_title_short_id,
    job_title_id
)
SELECT DISTINCT
    djts.job_title_short_id,
    djt.job_title_id
FROM job_postings_fact jpf
JOIN company_mart.dim_job_title_short djts
    ON jpf.job_title_short = djts.job_title_short
JOIN company_mart.dim_job_title djt
    ON jpf.job_title = djt.job_title
WHERE
        jpf.job_title IS NOT NULL
    AND jpf.job_title_short IS NOT NULL
;

-----------------------------------
---- 2. Company/Location dimension branch consists of 3 tables:
------ 2a. dim_company: contains names of companies
------ 2b. dim_location: contains job locations
------ 2c. bridge_company_location: a bridge btw. companies and their job locations

------ 2a. Create Location dimension
CREATE TABLE company_mart.dim_location (
    location_id     INTEGER    PRIMARY KEY,
    job_country     VARCHAR,
    job_location    VARCHAR
)
;
INSERT INTO company_mart.dim_location (
    location_id,
    job_country,
    job_location
)
SELECT
    ROW_NUMBER() OVER (ORDER BY job_country, job_location) AS location_id,
    job_country,
    job_location
FROM (
    SELECT DISTINCT
        job_country,
        job_location
    FROM job_postings_fact
    WHERE job_country IS NOT NULL
      AND job_location IS NOT NULL
)
;

------ 2b. Create Company dimension
CREATE TABLE company_mart.dim_company (
    company_id      INTEGER     PRIMARY KEY,
    company_name    VARCHAR
)
;

INSERT INTO company_mart.dim_company (
    company_id,
    company_name
)
SELECT
    company_id,
    name AS company_name
FROM company_dim
;

------ 2c. Create Bridge table (Company <-> Job Location)

CREATE TABLE company_mart.bridge_company_location (
    company_id      INTEGER,
    location_id     INTEGER,
    PRIMARY KEY (company_id, location_id),
    FOREIGN KEY (company_id) REFERENCES company_mart.dim_company (company_id),
    FOREIGN KEY (location_id) REFERENCES company_mart.dim_location (location_id)
)
;

INSERT INTO company_mart.bridge_company_location (
    company_id,
    location_id
)
SELECT DISTINCT
    jpf.company_id,
    dl.location_id
FROM job_postings_fact jpf
JOIN company_mart.dim_location dl
    ON jpf.job_country = dl.job_country
   AND jpf.job_location = dl.job_location
WHERE jpf.company_id IS NOT NULL
;

-----------------------------------

---- 3. Date/Month dimension branch consists of 1 table:
------ 3a. dim_date_month: contains year & month of job postings

CREATE TABLE company_mart.dim_date_month (
    month_start_date    DATE        PRIMARY KEY,
    year                SMALLINT,
    month               TINYINT
)
;

INSERT INTO company_mart.dim_date_month (
    month_start_date,
    year,
    month
)
SELECT DISTINCT
    DATE_TRUNC('month', job_posted_date)::DATE AS month_start_date,
    EXTRACT(year FROM job_posted_date) AS year,
    EXTRACT(month FROM job_posted_date) AS month
FROM job_postings_fact
WHERE job_posted_date IS NOT NULL
;

-----------------------------------

---- 4. FACT table: Companies & Their monthly hiring Stats

CREATE TABLE company_mart.fact_company_hiring_monthly (
    company_id              INTEGER,
    job_title_short_id      SMALLINT,
    month_start_date        DATE,
    job_country             VARCHAR,
    postings_count          INTEGER,
    median_salary_year      DOUBLE,
    min_salary_year         DOUBLE,
    max_salary_year         DOUBLE,
    remote_share            DOUBLE,
    health_insurance_share  DOUBLE,
    no_degree_mention_share DOUBLE,
    PRIMARY KEY (company_id, job_title_short_id, month_start_date, job_country),
    FOREIGN KEY (company_id) REFERENCES company_mart.dim_company (company_id),
    FOREIGN KEY (job_title_short_id) REFERENCES company_mart.dim_job_title_short (job_title_short_id),
    FOREIGN KEY (month_start_date) REFERENCES company_mart.dim_date_month (month_start_date)
)
;

INSERT INTO company_mart.fact_company_hiring_monthly (
    company_id,
    job_title_short_id,
    month_start_date,
    job_country,
    postings_count,
    median_salary_year,
    min_salary_year,
    max_salary_year,
    remote_share,
    health_insurance_share,
    no_degree_mention_share
)
SELECT
    jpf.company_id,
    djts.job_title_short_id,
    DATE_TRUNC('month', jpf.job_posted_date) AS month_start_date,
    jpf.job_country,
    COUNT(*) AS postings_count,
    MEDIAN(jpf.salary_year_avg) AS median_salary_year,
    MIN(jpf.salary_year_avg) AS min_salary_year,
    MAX(jpf.salary_year_avg) AS max_salary_year,
    AVG(CASE WHEN job_work_from_home = true THEN 1 ELSE 0 END) AS remote_share,
    AVG(CASE WHEN job_health_insurance = true THEN 1 ELSE 0 END) AS health_insurance_share,
    AVG(CASE WHEN job_no_degree_mention = true THEN 1 ELSE 0 END) AS no_degree_mention_share

FROM job_postings_fact jpf
JOIN company_mart.dim_job_title_short djts
    ON jpf.job_title_short = djts.job_title_short
WHERE
        jpf.company_id IS NOT NULL
    AND jpf.job_posted_date IS NOT NULL
    AND jpf.job_country IS NOT NULL
GROUP BY
    jpf.company_id,
    djts.job_title_short_id,
    month_start_date,
    jpf.job_country
;


-----------------------------------
--------- MART VALIDATION ---------
-----------------------------------
SELECT 'Job Title Dimension' AS table_name, COUNT(*) AS record_count FROM company_mart.dim_job_title
UNION ALL
SELECT 'Job Title Short Dimension', COUNT(*) FROM company_mart.dim_job_title_short
UNION ALL
SELECT 'Job Title Bridge', COUNT(*) FROM company_mart.bridge_job_title
UNION ALL
SELECT 'Location Dimension', COUNT(*) FROM company_mart.dim_location
UNION ALL
SELECT 'Company Dimension', COUNT(*) FROM company_mart.dim_company
UNION ALL
SELECT 'Company Location Bridge', COUNT(*) FROM company_mart.bridge_company_location
UNION ALL
SELECT 'Date Month Dimension', COUNT(*) FROM company_mart.dim_date_month
UNION ALL
SELECT 'Company Hiring Monthly Fact', COUNT(*) FROM company_mart.fact_company_hiring_monthly;

-----------------------------------
----------- SAMPLE DATE -----------
-----------------------------------

SELECT '=== Job Title Dimension Sample ===' AS info;
SELECT * FROM company_mart.dim_job_title LIMIT 5;

SELECT '=== Job Title Short Dimension Sample ===' AS info;
FROM company_mart.dim_job_title_short LIMIT 5;

SELECT '=== Job Title Bridge Sample ===' AS info;
SELECT
    bjt.job_title_short_id,
    djts.job_title_short,
    bjt.job_title_id,
    djt.job_title
FROM company_mart.bridge_job_title bjt
JOIN company_mart.dim_job_title djt
    ON bjt.job_title_id = djt.job_title_id
JOIN company_mart.dim_job_title_short djts
    ON bjt.job_title_short_id = djts.job_title_short_id
WHERE djts.job_title_short = 'Data Engineer'
LIMIT 5;

SELECT '=== Location Dimension Sample ===' AS info;
FROM company_mart.dim_location LIMIT 5;

SELECT '=== Company Dimension Sample ===' AS info;
FROM company_mart.dim_company LIMIT 5;

SELECT '=== Company Location Bridge Sample ===' AS info;
SELECT
    bcl.company_id,
    dc.company_name,
    bcl.location_id,
    dl.job_country,
    dl.job_location
FROM company_mart.bridge_company_location bcl
JOIN company_mart.dim_company dc
    ON bcl.company_id = dc.company_id
JOIN company_mart.dim_location dl
    ON bcl.location_id = dl.location_id
LIMIT 5;

SELECT '=== Date Month Dimension Sample ===' AS info;
FROM company_mart.dim_date_month ORDER BY month_start_date DESC LIMIT 5;

SELECT '=== Company Hiring Fact Sample ===' AS info;
SELECT
    fchm.company_id,
    dc.company_name,
    djts.job_title_short,
    fchm.job_country,
    fchm.month_start_date,
    fchm.postings_count,
    fchm.median_salary_year
FROM company_mart.fact_company_hiring_monthly fchm
JOIN company_mart.dim_company dc
    ON dc.company_id = fchm.company_id
JOIN company_mart.dim_job_title_short djts
    ON djts.job_title_short_id = fchm.job_title_short_id
ORDER BY fchm.postings_count DESC, fchm.median_salary_year DESC
LIMIT 10;




WITH job_postings_prepared AS (
    SELECT
        jpf.company_id,
        djs.job_title_short_id,
        jpf.job_country,
        DATE_TRUNC('month', jpf.job_posted_date)::DATE AS month_start_date,
        jpf.salary_year_avg,
        -- Convert boolean flags to numeric values (1.0 or 0.0)
        CASE WHEN jpf.job_work_from_home = TRUE THEN 1.0 ELSE 0.0 END AS is_remote,
        CASE WHEN jpf.job_health_insurance = TRUE THEN 1.0 ELSE 0.0 END AS has_health_insurance,
        CASE WHEN jpf.job_no_degree_mention = TRUE THEN 1.0 ELSE 0.0 END AS no_degree_required
    FROM
        job_postings_fact jpf
    INNER JOIN company_mart.dim_job_title_short djs 
        ON jpf.job_title_short = djs.job_title_short
    WHERE
        jpf.company_id IS NOT NULL
        AND jpf.job_posted_date IS NOT NULL
        AND jpf.job_country IS NOT NULL
)
SELECT
    company_id,
    job_title_short_id,
    job_country,
    month_start_date,

    COUNT(*) AS postings_count,

    MEDIAN(salary_year_avg) AS median_salary_year,
    MIN(salary_year_avg) AS min_salary_year,
    MAX(salary_year_avg) AS max_salary_year,

    -- ratio of remote-friendly postings in this group (0-1)
    AVG(is_remote) AS remote_share,

    -- ratio of postings that mention health insurance
    AVG(has_health_insurance) AS health_insurance_share,

    -- ratio of postings where "no degree mentioned" is flagged
    AVG(no_degree_required) AS no_degree_mention_share

FROM
    job_postings_prepared
GROUP BY
    company_id,
    job_title_short_id,
    job_country,
    month_start_date;