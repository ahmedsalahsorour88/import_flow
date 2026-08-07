from sqlalchemy.orm import Session

from .model import ExternalServiceProvider
from .schemas import ExternalServiceProviderCreate


# ==================================================
# Create Provider
# ==================================================

def create_provider(
    db: Session,
    provider_data: ExternalServiceProviderCreate
) -> ExternalServiceProvider:

    provider = ExternalServiceProvider(

        partner_name=provider_data.partner_name,

        partner_type=provider_data.partner_type,

        contact_person=provider_data.contact_person,

        phone=provider_data.phone,

        mobile=provider_data.mobile,

        email=(
            str(provider_data.email)
            if provider_data.email
            else None
        ),

        address=provider_data.address,

        country=provider_data.country,

        payment_type=provider_data.payment_type,

        credit_limit=provider_data.credit_limit,

        notes=provider_data.notes,

        created_by=provider_data.created_by
    )

    db.add(provider)

    db.commit()

    db.refresh(provider)

    # ==============================================
    # Generate Partner Code
    # ==============================================

    provider.partner_code = (
        f"ESP-{provider.provider_id:06d}"
    )

    db.commit()

    db.refresh(provider)

    return provider


# ==================================================
# Get Active Providers
# ==================================================

def get_providers(
    db: Session
) -> list[ExternalServiceProvider]:

    return (
        db.query(ExternalServiceProvider)
        .filter(
            ExternalServiceProvider.is_active == True
        )
        .order_by(
            ExternalServiceProvider.provider_id
        )
        .all()
    )


# ==================================================
# Get All Providers
# ==================================================

def get_all_providers(
    db: Session
) -> list[ExternalServiceProvider]:

    return (
        db.query(ExternalServiceProvider)
        .order_by(
            ExternalServiceProvider.provider_id
        )
        .all()
    )


# ==================================================
# Get Provider By ID
# ==================================================

def get_provider_by_id(
    db: Session,
    provider_id: int
) -> ExternalServiceProvider | None:

    return (
        db.query(ExternalServiceProvider)
        .filter(
            ExternalServiceProvider.provider_id == provider_id
        )
        .first()
    )


# ==================================================
# Check Partner Name Exists
# ==================================================

def partner_name_exists(
    db: Session,
    partner_name: str,
    partner_type: str
) -> bool:

    return (
        db.query(ExternalServiceProvider)
        .filter(
            ExternalServiceProvider.partner_name == partner_name,
            ExternalServiceProvider.partner_type == partner_type
        )
        .first()
        is not None
    )


# ==================================================
# Save Updates
# ==================================================

def update_provider(
    db: Session,
    provider: ExternalServiceProvider
) -> ExternalServiceProvider:

    db.commit()

    db.refresh(provider)

    return provider


# ==================================================
# Soft Delete
# ==================================================

def delete_provider(
    db: Session,
    provider: ExternalServiceProvider
) -> ExternalServiceProvider:

    provider.is_active = False

    db.commit()

    db.refresh(provider)

    return provider


# ==================================================
# Restore Provider
# ==================================================

def restore_provider(
    db: Session,
    provider: ExternalServiceProvider
) -> ExternalServiceProvider:

    provider.is_active = True

    db.commit()

    db.refresh(provider)

    return provider