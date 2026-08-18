import os

repo_path = 'modules/import_companies/service.py'
with open(repo_path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace('def update_import_company(', 'from modules.audit_logs.service import AuditLogService\n\ndef update_import_company(')

# update create_import_company
create_str = """    result = create_company(db, company_data)
    AuditLogService(db).log_activity(
        entity_type="ImportCompany",
        entity_id=result.company_id,
        entity_code=result.importer_id,
        action="CREATE",
        new_data={"importer_name": result.importer_name, "importer_id": result.importer_id, "vat_id": result.vat_id}
    )
    return add_days_to_renew(result)"""
content = content.replace('    result = create_company(db, company_data)\n    return add_days_to_renew(result)', create_str)

# update update_import_company
update_str = """    update_dict = company_data.model_dump(
        exclude_unset=True,
        exclude_none=True
    )

    old_data = {
        k: getattr(company, k, None)
        for k in update_dict.keys()
    }

    updated_company = update_company_data(db, company, update_dict)
    
    AuditLogService(db).log_activity(
        entity_type="ImportCompany",
        entity_id=updated_company.company_id,
        entity_code=updated_company.importer_id,
        action="UPDATE",
        old_data=old_data,
        new_data=update_dict,
    )
    
    return add_days_to_renew(updated_company)"""
content = content.replace("""    update_dict = company_data.model_dump(
        exclude_unset=True,
        exclude_none=True
    )

    updated_company = update_company_data(db, company, update_dict)
    return add_days_to_renew(updated_company)""", update_str)

# delete_import_company
del_str = """    deleted_company = repo_delete_company(db, company)
    AuditLogService(db).log_activity(
        entity_type="ImportCompany",
        entity_id=deleted_company.company_id,
        entity_code=deleted_company.importer_id,
        action="DELETE",
    )
    return add_days_to_renew(deleted_company)"""
content = content.replace('    deleted_company = repo_delete_company(db, company)\n    return add_days_to_renew(deleted_company)', del_str)

# restore_import_company
res_str = """    restored_company = repo_restore_company(db, company)
    AuditLogService(db).log_activity(
        entity_type="ImportCompany",
        entity_id=restored_company.company_id,
        entity_code=restored_company.importer_id,
        action="RESTORE",
    )
    return add_days_to_renew(restored_company)"""
content = content.replace('    restored_company = repo_restore_company(db, company)\n    return add_days_to_renew(restored_company)', res_str)

with open(repo_path, 'w', encoding='utf-8') as f:
    f.write(content)
