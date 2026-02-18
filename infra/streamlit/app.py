import os

import pandas as pd
import snowflake.connector
import streamlit as st


st.set_page_config(page_title="CULTIVATE BI Viewer", layout="wide")
st.title("CULTIVATE Snowflake Viewer")


def _required_env() -> list[str]:
    return [
        "SNOWFLAKE_ACCOUNT",
        "SNOWFLAKE_USER",
        "SNOWFLAKE_PASSWORD",
        "SNOWFLAKE_WAREHOUSE",
        "SNOWFLAKE_DATABASE",
        "SNOWFLAKE_SCHEMA",
    ]


def _missing_env() -> list[str]:
    return [k for k in _required_env() if not os.getenv(k)]


@st.cache_resource
def get_connection():
    return snowflake.connector.connect(
        account=os.getenv("SNOWFLAKE_ACCOUNT"),
        user=os.getenv("SNOWFLAKE_USER"),
        password=os.getenv("SNOWFLAKE_PASSWORD"),
        warehouse=os.getenv("SNOWFLAKE_WAREHOUSE"),
        database=os.getenv("SNOWFLAKE_DATABASE"),
        schema=os.getenv("SNOWFLAKE_SCHEMA"),
        role=os.getenv("SNOWFLAKE_ROLE"),
    )


def fetch_df(sql: str) -> pd.DataFrame:
    conn = get_connection()
    with conn.cursor() as cur:
        cur.execute(sql)
        rows = cur.fetchall()
        cols = [d[0] for d in cur.description]
    return pd.DataFrame(rows, columns=cols)


missing = _missing_env()
if missing:
    st.error("Missing environment variables: " + ", ".join(missing))
    st.stop()

default_table = os.getenv("SNOWFLAKE_DEFAULT_TABLE", "V_MART_FSI_POWERBI_EXPORT")
schema_name = os.getenv("SNOWFLAKE_SCHEMA")

st.caption(
    f"Database: {os.getenv('SNOWFLAKE_DATABASE')} | "
    f"Schema: {schema_name} | "
    f"Warehouse: {os.getenv('SNOWFLAKE_WAREHOUSE')}"
)

sql_tables = f"""
SELECT table_name
FROM {os.getenv("SNOWFLAKE_DATABASE")}.information_schema.tables
WHERE table_schema = '{schema_name}'
ORDER BY table_name
"""
tables_df = fetch_df(sql_tables)
table_names = tables_df["TABLE_NAME"].tolist() if not tables_df.empty else []

if not table_names:
    st.warning("No tables/views found in the selected schema.")
    st.stop()

default_index = table_names.index(default_table) if default_table in table_names else 0
selected_table = st.selectbox("Table/View", table_names, index=default_index)
limit = st.slider("Preview row limit", min_value=10, max_value=5000, value=200, step=10)

query = st.text_area(
    "SQL (optional)",
    value=f"SELECT * FROM {selected_table} LIMIT {limit}",
    height=140,
)

if st.button("Run Query", type="primary"):
    try:
        df = fetch_df(query)
        st.success(f"Fetched {len(df)} rows")
        st.dataframe(df, use_container_width=True)
    except Exception as exc:
        st.exception(exc)
