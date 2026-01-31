-- Snowflake SQL
-- Requires Snowflake connection
-- Run via Snowflake VS Code extension or SnowSQL

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE COMPUTE_WH;
USE DATABASE SNOWFLAKE_LEARNING_DB;
USE SCHEMA PUBLIC;

SET user_name = current_user();
SET schema_name = CONCAT($user_name, '_LOAD_DATA_FROM_CLOUD');
CREATE SCHEMA IF NOT EXISTS IDENTIFIER($schema_name);
USE SCHEMA IDENTIFIER($schema_name);
