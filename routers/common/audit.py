from datetime import datetime


# ==================================================
# Set Created Fields
# ==================================================

def set_created_info(
    entity,
    user: str = "system"
):

    entity.created_at = datetime.utcnow()

    entity.updated_at = datetime.utcnow()

    entity.created_by = user

    entity.updated_by = user

    return entity


# ==================================================
# Set Updated Fields
# ==================================================

def set_updated_info(
    entity,
    user: str = "system"
):

    entity.updated_at = datetime.utcnow()

    entity.updated_by = user

    return entity


# ==================================================
# Soft Delete
# ==================================================

def set_deleted_info(
    entity,
    user: str = "system"
):

    entity.is_active = False

    entity.updated_at = datetime.utcnow()

    entity.updated_by = user

    return entity


# ==================================================
# Restore
# ==================================================

def set_restored_info(
    entity,
    user: str = "system"
):

    entity.is_active = True

    entity.updated_at = datetime.utcnow()

    entity.updated_by = user

    return entity