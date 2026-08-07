from database.database import SessionLocal
from modules.suppliers.model import Supplier


db = SessionLocal()

suppliers = db.query(Supplier).all()

for supplier in suppliers:
    print(
        supplier.supplier_id,
        supplier.supplier_code,
        supplier.company_name
    )

db.close()