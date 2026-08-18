import re

service_file = 'modules/smart_document_upload/service.py'
router_file = 'modules/smart_document_upload/router.py'

with open(service_file, 'r', encoding='utf-8') as f:
    service_content = f.read()

wrappers = '''
def get_upload_sessions_service(db: Session, module_name: str = None, skip: int = 0, limit: int = 50):
    return repo.get_upload_sessions(db, module_name=module_name, skip=skip, limit=limit)

def get_upload_session_by_id_service(db: Session, session_id: int):
    return repo.get_upload_session_by_id(db, session_id)

def soft_delete_upload_session_service(db: Session, session_id: int):
    return repo.soft_delete_upload_session(db, session_id)
'''

if 'get_upload_sessions_service' not in service_content:
    service_content += wrappers
    with open(service_file, 'w', encoding='utf-8') as f:
        f.write(service_content)

with open(router_file, 'r', encoding='utf-8') as f:
    router_content = f.read()

router_content = re.sub(r'import modules\.smart_document_upload\.repository as repo\n', '', router_content)
router_content = router_content.replace('repo.get_upload_sessions', 'service.get_upload_sessions_service')
router_content = router_content.replace('repo.get_upload_session_by_id', 'service.get_upload_session_by_id_service')
router_content = router_content.replace('repo.soft_delete_upload_session', 'service.soft_delete_upload_session_service')

with open(router_file, 'w', encoding='utf-8') as f:
    f.write(router_content)

print('smart_document_upload fixed')
