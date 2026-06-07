"""
clone_dev.py — Refresh DEV_DB as a zero-copy clone of ENTERPRISE_DB.

Run this at the start of a sprint or before testing a major change.
Zero-copy clone means Snowflake doesn't physically duplicate data —
it's instant and costs nothing extra until DEV diverges from PROD.

Usage:
    python clone_dev.py

Required env vars (same as deploy.py):
    SNOWFLAKE_ACCOUNT, SNOWFLAKE_USER, SNOWFLAKE_PASSWORD
"""

import os
import snowflake.connector

# Support both GitHub Secrets naming (SNOWFLAKE_*) and local .env naming (SNOWSQL_*)
account  = os.environ.get("SNOWFLAKE_ACCOUNT") or os.environ["SNOWSQL_ACCOUNT"]
user     = os.environ.get("SNOWFLAKE_USER")    or os.environ["SNOWSQL_USER"]
password = os.environ.get("SNOWFLAKE_PASSWORD") or os.environ.get("SNOWSQL_PWD", "")

conn = snowflake.connector.connect(
    account=account,
    user=user,
    password=password,
)
cursor = conn.cursor()

print("Cloning ENTERPRISE_DB -> DEV_DB ...")

# Drop the existing DEV_DB so the clone is a fresh snapshot of PROD.
# IF EXISTS means this is safe to run on first time too.
cursor.execute("USE ROLE ACCOUNTADMIN")
cursor.execute("DROP DATABASE IF EXISTS DEV_DB")

# Zero-copy clone: no data is duplicated — Snowflake uses metadata pointers.
# Any writes in DEV_DB after this point are isolated from ENTERPRISE_DB.
cursor.execute("CREATE DATABASE DEV_DB CLONE ENTERPRISE_DB")

# Grant the dev role access to the cloned database
cursor.execute("GRANT USAGE  ON DATABASE DEV_DB TO ROLE AI_ENGINEER_ROLE")
cursor.execute("GRANT USAGE  ON ALL SCHEMAS IN DATABASE DEV_DB TO ROLE AI_ENGINEER_ROLE")
cursor.execute("GRANT SELECT ON ALL TABLES  IN DATABASE DEV_DB TO ROLE AI_ENGINEER_ROLE")

print("Done. DEV_DB is now a fresh clone of ENTERPRISE_DB.")
print("Developers can now run migrations against DEV_DB safely.")

cursor.close()
conn.close()
