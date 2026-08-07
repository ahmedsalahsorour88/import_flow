from database.database import engine
from sqlalchemy import inspect


inspector = inspect(engine)

columns = inspector.get_columns("suppliers")

for column in columns:
    print(
        column["name"],
        "nullable:",
        column["nullable"]
    )