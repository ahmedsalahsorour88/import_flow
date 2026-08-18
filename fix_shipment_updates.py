import re

service_file = 'modules/shipment_updates/service.py'
router_file = 'modules/shipment_updates/router.py'

with open(service_file, 'r', encoding='utf-8') as f:
    service_content = f.read()

wrappers = '''
def get_all_update_logs_service(db: Session, import_file_id: int = None, update_category: str = None, target_phase: str = None, search: str = None):
    return repo.get_all_update_logs(db, import_file_id=import_file_id, update_category=update_category, target_phase=target_phase, search=search)

def get_update_log_by_id_service(db: Session, update_id: int):
    return repo.get_update_log_by_id(db, update_id)

def soft_delete_update_log_service(db: Session, update_id: int):
    return repo.soft_delete_update_log(db, update_id)
'''

if 'get_all_update_logs_service' not in service_content:
    service_content += wrappers
    with open(service_file, 'w', encoding='utf-8') as f:
        f.write(service_content)

with open(router_file, 'r', encoding='utf-8') as f:
    router_content = f.read()

router_content = re.sub(r'import modules\.shipment_updates\.repository as repo\n', '', router_content)
router_content = router_content.replace('repo.get_all_update_logs', 'service.get_all_update_logs_service')
router_content = router_content.replace('repo.get_update_log_by_id', 'service.get_update_log_by_id_service')
router_content = router_content.replace('repo.soft_delete_update_log', 'service.soft_delete_update_log_service')

with open(router_file, 'w', encoding='utf-8') as f:
    f.write(router_content)

print('shipment_updates fixed')
