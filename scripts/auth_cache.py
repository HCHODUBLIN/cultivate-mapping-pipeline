"""Run this once from the terminal to cache the MFA token before running dbt."""
import pathlib
import yaml
import snowflake.connector

# Read credentials from the same profiles.yml that dbt uses.
profiles_path = pathlib.Path.home() / ".dbt" / "profiles.yml"
with open(profiles_path) as f:
    profiles = yaml.safe_load(f)

creds = profiles["cultivate"]["outputs"]["dev"]

passcode = input("Enter your TOTP code from your authenticator app: ").strip()
conn = snowflake.connector.connect(
    account=creds["account"],
    user=creds["user"],
    password=creds["password"],
    warehouse=creds["warehouse"],
    database=creds["database"],
    schema=creds["schema"],
    role=creds["role"],
    authenticator="username_password_mfa",
    passcode=passcode,
    client_request_mfa_token=True,
    client_store_temporary_credential=True,
)
conn.cursor().execute("SELECT CURRENT_USER()").fetchone()
conn.close()
print("MFA token cached successfully. You can now run dbt without being prompted.")
