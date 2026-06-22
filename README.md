<!--
TODOs:
1. Add info about Project 3: Visualization
-->

# Overview
## Contents
- 🏭 Complete ETL pipeline built in SQL
- 🔢 Exploratory Data Analysis in SQL
- _📈 Data Visualization (in progress)_

## The Idea and the Data
The data for this repo contains Data Job Postings scraped from the Internet by [Luke Barousse](https://github.com/lukebarousse) and stored as CSV files in his Google Cloud Storage.

[Project 1](1_EDA) and [Project 2](2_DW_Mart_Build) were built from scratch following this [Data engineering course](https://youtu.be/UjhFbq4uU2Y) on YouTube hosted by [Luke Barousse](https://github.com/lukebarousse).

The original repo can be found [here](https://github.com/lukebarousse/SQL_Data_Engineering_Course).

## Projects
- [Project 1: Exploratory Data Analysis](1_EDA):
    Data Job market analytics.

- [Project 2: Data Warehouse & Data Marts Build](2_DW_Mart_Build):
    Production ETL pipeline from raw CSVs to Star Schema and Data Marts.

## Detailed overview
Project 1 and Project 2 were done by following the aforementioned [YouTube Course](https://youtu.be/UjhFbq4uU2Y).\
Only the Project 2's [Company Mart](2_DW_Mart_Build/07_create_company_mart.sql) was recreated from scratch from its ER-diagram for learning purposes and the code differs from the [original repo](https://github.com/lukebarousse/SQL_Data_Engineering_Course/blob/main/Projects/2_WH_Mart_Build/07_create_company_mart.sql).

## Tools
- 🐥 **DuckDB:** It's an in-process|SQL|OLAP|Open source Data Warehouse.\
    The DWH and Data Marts were built using a local instance of **DuckDB**. 
- 🦆 **MotherDuck:** The cloud DWH built on **DuckDB**.\
    The complete DWH and Data Marts were deployed into **MotherDuck**.

To get access to the DWH & Marts deployed to MotherDuck read [this](2_DW_Mart_Build/README.md#how-to-get-access-to-this-dwh).
