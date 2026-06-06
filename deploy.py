import os
import glob
import snowflake.connector

account  = os.environ["SNOWFLAKE_ACCOUNT"]
user     = os.environ["SNOWFLAKE_USER"]
password = os.environ["SNOWFLAKE_PASSWORD"]

conn = snowflake.connector.connect(
    account=account,
    user=user,
    password=password,
)

cursor = conn.cursor()

# Run every SQL file in migrations/ in alphabetical order
migration_files = sorted(glob.glob("migrations/*.sql"))

if not migration_files:
    print("No migrations found. Nothing to run.")
    cursor.close()
    conn.close()
else:
    for filepath in migration_files:
        print(f"Running {filepath}...")
        with open(filepath, "r") as f:
            sql = f.read()
        for statement in sql.split(";"):
            statement = statement.strip()
            if statement:
                cursor.execute(statement)
        print(f"Done: {filepath}")

    cursor.close()
    conn.close()
    print("All migrations complete.")
