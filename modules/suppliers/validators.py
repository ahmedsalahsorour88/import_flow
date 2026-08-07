from fastapi import HTTPException
from sqlalchemy.orm import Session

from .repository import supplier_exists

from .schemas import SupplierCreate


# ==================================================
# Validate Supplier
# ==================================================

def validate_supplier(
    db: Session,
    supplier: SupplierCreate
) -> None:


    # ==============================================
    # Duplicate Supplier
    # ==============================================

    if supplier_exists(

        db,

        supplier.registration_type,

        supplier.foreign_exporter_id

    ):

        raise HTTPException(

            status_code=400,

            detail=(
                "Supplier already exists "
                "with the same Registration Type "
                "and Foreign Exporter ID."
            )

        )


    # ==============================================
    # Company Name
    # ==============================================

    if not supplier.company_name.strip():

        raise HTTPException(

            status_code=400,

            detail="Company Name is required."

        )


    # ==============================================
    # Registration Type
    # ==============================================

    if not supplier.registration_type.strip():

        raise HTTPException(

            status_code=400,

            detail="Registration Type is required."

        )


    # ==============================================
    # Foreign Exporter ID
    # ==============================================

    if not supplier.foreign_exporter_id.strip():

        raise HTTPException(

            status_code=400,

            detail="Foreign Exporter ID is required."

        )


    # ==============================================
    # Country
    # ==============================================

    if not supplier.foreign_exporter_country.strip():

        raise HTTPException(

            status_code=400,

            detail="Foreign Exporter Country is required."

        )


    # ==============================================
    # Country Code
    # ==============================================

    supplier.foreign_exporter_country_code = (
        supplier.foreign_exporter_country_code
        .strip()
        .upper()
    )


    if len(
        supplier.foreign_exporter_country_code
    ) not in (2, 3):

        raise HTTPException(

            status_code=400,

            detail=(
                "Country Code must contain "
                "2 or 3 characters."
            )

        )


    # ==============================================
    # Address
    # ==============================================

    if not supplier.address.strip():

        raise HTTPException(

            status_code=400,

            detail="Address is required."

        )