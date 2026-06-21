/*
Question:
    What are the most in-demand skills for Data Engineers for Remote positions?
Algorithm:
    1. Construct the final Table by Joining tables with necessary columns.
    2. Filter the Table on Job Title and Remote Positions.
    3. Aggregate by counting occurences of Skills
    4. Order the Counts and Output Top 10 most frequently asked skills.
*/

SELECT
    sd.skills,
    COUNT(jpf.*) AS demand_count
FROM job_postings_fact jpf
    JOIN skills_job_dim sjd
      ON jpf.job_id = sjd.job_id
    JOIN skills_dim sd
      ON sjd.skill_id = sd.skill_id
WHERE
    jpf.job_title_short = 'Data Engineer'
    AND jpf.job_work_from_home = TRUE
GROUP BY
    sd.skills
ORDER BY
    COUNT(sd.skills) DESC
LIMIT 10
;

/*
Takeaways:
    As expected SQL and Python lead the list of top in-demand skills
    for Data Engineers.
    As for Cloud services AWS and Azure are the most popular, following right after.
    The only Big Data tool in the list is Spark.
    Most popular data pipeline tools (Airflow, Snowflake, Databricks) are also in the list.
    Java and GCP round out the TOP 10 most requested skills.
┌────────────┬──────────────┐
│   skills   │ demand_count │
│  varchar   │    int64     │
├────────────┼──────────────┤
│ sql        │        29221 │
│ python     │        28776 │
│ aws        │        17823 │
│ azure      │        14143 │
│ spark      │        12799 │
│ airflow    │         9996 │
│ snowflake  │         8639 │
│ databricks │         8183 │
│ java       │         7267 │
│ gcp        │         6446 │
├────────────┴──────────────┤
│ 10 rows         2 columns │
└───────────────────────────┘
*/
