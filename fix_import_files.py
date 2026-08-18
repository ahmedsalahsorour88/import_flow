import re

service_file = 'modules/import_files/service.py'
router_file = 'modules/import_files/router.py'

with open(service_file, 'r', encoding='utf-8') as f:
    service_content = f.read()

wrappers = '''
def get_all_import_files_service(db: Session, include_inactive: bool = False, search: Optional[str] = None, company_id: Optional[int] = None, supplier_id: Optional[int] = None, status: Optional[str] = None, owner: Optional[str] = None):
    return repo.get_all_import_files(db, include_inactive=include_inactive, search=search, company_id=company_id, supplier_id=supplier_id, status=status, owner=owner)

def get_paginated_import_files_service(db: Session, page: int = 1, page_size: int = 50, include_inactive: bool = False, search: Optional[str] = None, company_id: Optional[int] = None, supplier_id: Optional[int] = None, status: Optional[str] = None, owner: Optional[str] = None):
    return repo.get_paginated_import_files(db, include_inactive=include_inactive, search=search, company_id=company_id, supplier_id=supplier_id, status=status, owner=owner, page=page, page_size=page_size)

def get_operational_dashboard_data_service(db: Session, phase: Optional[str] = None, priority: Optional[str] = None, broker_id: Optional[int] = None, broker_name: Optional[str] = None, search: Optional[str] = None):
    return repo.get_operational_dashboard_data(db, phase=phase, priority=priority, broker_id=broker_id, broker_name=broker_name, search=search)

def get_import_file_by_id_service(db: Session, import_file_id: int):
    return repo.get_import_file_by_id(db, import_file_id)

def get_import_file_by_code_service(db: Session, import_file_code: str):
    return repo.get_import_file_by_code(db, import_file_code)

def soft_delete_import_file_service(db: Session, import_file_id: int):
    return repo.soft_delete_import_file(db, import_file_id)
'''

if 'get_all_import_files_service' not in service_content:
    service_content += wrappers
    with open(service_file, 'w', encoding='utf-8') as f:
        f.write(service_content)

with open(router_file, 'r', encoding='utf-8') as f:
    router_content = f.read()

router_content = re.sub(r'import modules\.import_files\.repository as repo\n', '', router_content)
router_content = router_content.replace('repo.get_all_import_files', 'service.get_all_import_files_service')
router_content = router_content.replace('repo.get_paginated_import_files', 'service.get_paginated_import_files_service')
router_content = router_content.replace('repo.get_operational_dashboard_data', 'service.get_operational_dashboard_data_service')
router_content = router_content.replace('repo.get_import_file_by_id', 'service.get_import_file_by_id_service')
router_content = router_content.replace('repo.get_import_file_by_code', 'service.get_import_file_by_code_service')
router_content = router_content.replace('repo.soft_delete_import_file', 'service.soft_delete_import_file_service')

with open(router_file, 'w', encoding='utf-8') as f:
    f.write(router_content)

print('import_files fixed')
