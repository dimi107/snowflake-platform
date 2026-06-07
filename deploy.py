"""
deploy.py — Run SQL migrations against Snowflake.

Supports DEV and PROD environments. Migration files are written targeting
PROD names (ENTERPRISE_DB, AI_WH). When ENV=dev, those names are swapped
automatically so the same SQL runs cleanly against the DEV environment.

Usage:
    SNOWFLAKE_ENV=prod python deploy.py   # default — targets ENTERPRISE_DB
    SNOWFLAKE_ENV=dev  python deploy.py   # targets DEV_DB
"""

import os
import glob
import snowflake.connector

# Support both GitHub Secrets naming (SNOWFLAKE_*) and local .env naming (SNOWSQL_*)
account  = os.environ.get("SNOWFLAKE_ACCOUNT") or os.environ["SNOWSQL_ACCOUNT"]
user     = os.environ.get("SNOWFLAKE_USER")    or os.environ["SNOWSQL_USER"]
password = os.environ.get("SNOWFLAKE_PASSWORD") or os.environ.get("SNOWSQL_PWD", "")
env      = os.environ.get("SNOWFLAKE_ENV", "dev").lower()

# Map environment name → actual Snowflake object names
DB_MAP = {"prod": "ENTERPRISE_DB", "dev": "DEV_DB"}
WH_MAP = {"prod": "AI_WH",         "dev": "DEV_WH"}

if env not in DB_MAP:
    raise ValueError(f"Unknown SNOWFLAKE_ENV '{env}'. Expected: dev or prod.")

target_db = DB_MAP[env]
target_wh = WH_MAP[env]

print(f"Environment : {env.upper()}")
print(f"Database    : {target_db}")
print(f"Warehouse   : {target_wh}")
print()

conn = snowflake.connector.connect(
    account=account,
    user=user,
    password=password,
)
cursor = conn.cursor()

migration_files = sorted(glob.glob("migrations/*.sql"))

if not migration_files:
    print("No migrations found. Nothing to run.")
else:
    for filepath in migration_files:
        print(f"Running {filepath}...")
        with open(filepath, "r") as f:
            sql = f.read()

        # Swap PROD object names → environment-specific names when running in DEV.
        # Migrations are authored against PROD; this keeps them environment-agnostic.
        if env == "dev":
            sql = sql.replace("ENTERPRISE_DB", target_db)
            sql = sql.replace("AI_WH",         target_wh)

        for statement in sql.split(";"):
            statement = statement.strip()
            if statement:
                cursor.execute(statement)

        print(f"Done: {filepath}")

cursor.close()
conn.close()
print(f"\nAll migrations complete ({env.upper()}).")
