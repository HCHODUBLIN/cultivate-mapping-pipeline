# Streamlit Snowflake Viewer

This app connects to Snowflake and previews BI tables/views.

## 1) Install

```bash
cd /Users/hyunjicho/Documents/cultivate-mapping-pipeline
python -m venv .venv
source .venv/bin/activate
pip install -r infra/streamlit/requirements.txt
```

## 2) Set environment variables

```bash
export SNOWFLAKE_ACCOUNT="<your_account>"
export SNOWFLAKE_USER="<your_user>"
export SNOWFLAKE_PASSWORD="<your_password>"
export SNOWFLAKE_ROLE="ACCOUNTADMIN"
export SNOWFLAKE_WAREHOUSE="FSI_WH"
export SNOWFLAKE_DATABASE="CULTIVATE"
export SNOWFLAKE_SCHEMA="BI_PRESENTATION"
export SNOWFLAKE_DEFAULT_TABLE="V_MART_FSI_POWERBI_EXPORT"
```

## 3) Run

```bash
streamlit run infra/streamlit/app.py
```

## 4) Publish BI views first

Run:

`/Users/hyunjicho/Documents/cultivate-mapping-pipeline/snowflake/09_publish_for_bi.sql`

This creates stable BI-facing views in:

`CULTIVATE.BI_PRESENTATION`
