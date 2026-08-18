import os

repo_path = 'modules/suppliers/service.py'
with open(repo_path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace('def update_supplier_service(', 'from modules.audit_logs.service import AuditLogService\n\ndef update_supplier_service(')

# create_supplier_service
create_str = """    supplier = create_supplier(db, supplier_dict)
    
    AuditLogService(db).log_activity(
        entity_type="Supplier",
        entity_id=supplier.supplier_id,
        entity_code=supplier.supplier_code,
        action="CREATE",
        new_data={"supplier_name": supplier.supplier_name, "foreign_exporter_id": supplier.foreign_exporter_id, "country_id": supplier.country_id}
    )
    
    return supplier"""
content = content.replace('    return create_supplier(db, supplier_dict)', create_str)

# update_supplier_service
update_str = """    update_data = supplier_data.model_dump(exclude_unset=True, exclude_none=True)
    old_data = {
        k: getattr(supplier, k, None)
        for k in update_data.keys()
    }
    
    updated = update_supplier(db, supplier, supplier_data)
    
    AuditLogService(db).log_activity(
        entity_type="Supplier",
        entity_id=updated.supplier_id,
        entity_code=updated.supplier_code,
        action="UPDATE",
        old_data=old_data,
        new_data=update_data,
    )
    
    return updated"""
content = content.replace('    return update_supplier(db, supplier, supplier_data)', update_str)

# delete_supplier_service
del_str = """    deleted = soft_delete_supplier(db, supplier)
    AuditLogService(db).log_activity(
        entity_type="Supplier",
        entity_id=deleted.supplier_id,
        entity_code=deleted.supplier_code,
        action="DELETE",
    )
    return deleted"""
content = content.replace('    return soft_delete_supplier(db, supplier)', del_str)

# restore_supplier_service
res_str = """    restored = restore_supplier(db, supplier)
    AuditLogService(db).log_activity(
        entity_type="Supplier",
        entity_id=restored.supplier_id,
        entity_code=restored.supplier_code,
        action="RESTORE",
    )
    return restored"""
content = content.replace('    return restore_supplier(db, supplier)', res_str)

with open(repo_path, 'w', encoding='utf-8') as f:
    f.write(content)
