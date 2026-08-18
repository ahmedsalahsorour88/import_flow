import re

service_file = 'modules/import_documentation/service.py'
router_file = 'modules/import_documentation/router.py'

with open(service_file, 'r', encoding='utf-8') as f:
    service_content = f.read()

wrappers = '''
def get_all_acid_sessions_service(db: Session, include_inactive: bool = False, search: str = None, import_file_id: int = None, status: str = None):
    return repo.get_all_acid_sessions(db, include_inactive=include_inactive, search=search, import_file_id=import_file_id, status=status)

def get_acid_session_by_id_service(db: Session, acid_id: int):
    return repo.get_acid_session_by_id(db, acid_id)

def soft_delete_acid_session_service(db: Session, acid_id: int):
    return repo.soft_delete_acid_session(db, acid_id)

def get_all_banking_documents_service(db: Session, import_file_id: int = None):
    return repo.get_all_banking_documents(db, import_file_id=import_file_id)

def get_banking_document_by_id_service(db: Session, bank_doc_id: int):
    return repo.get_banking_document_by_id(db, bank_doc_id)

def get_all_shipment_documents_service(db: Session, import_file_id: int = None):
    return repo.get_all_shipment_documents(db, import_file_id=import_file_id)

def get_draft_bl_reviews_service(db: Session, include_inactive: bool = False, import_file_id: int = None, status: str = None, search: str = None):
    return repo.get_draft_bl_reviews(db, include_inactive=include_inactive, import_file_id=import_file_id, status=status, search=search)

def get_draft_bl_review_by_id_service(db: Session, review_id: int, include_inactive: bool = True):
    return repo.get_draft_bl_review_by_id(db, review_id, include_inactive=include_inactive)

def get_coo_reviews_service(db: Session, include_inactive: bool = False, import_file_id: int = None, status: str = None, search: str = None):
    return repo.get_coo_reviews(db, include_inactive=include_inactive, import_file_id=import_file_id, status=status, search=search)

def get_inspection_reviews_service(db: Session, include_inactive: bool = False, import_file_id: int = None, status: str = None, search: str = None):
    return repo.get_inspection_reviews(db, include_inactive=include_inactive, import_file_id=import_file_id, status=status, search=search)
'''

if 'get_all_acid_sessions_service' not in service_content:
    service_content += wrappers
    with open(service_file, 'w', encoding='utf-8') as f:
        f.write(service_content)

with open(router_file, 'r', encoding='utf-8') as f:
    router_content = f.read()

router_content = re.sub(r'import modules\.import_documentation\.repository as repo\n', '', router_content)
router_content = router_content.replace('repo.get_all_acid_sessions', 'service.get_all_acid_sessions_service')
router_content = router_content.replace('repo.get_acid_session_by_id', 'service.get_acid_session_by_id_service')
router_content = router_content.replace('repo.soft_delete_acid_session', 'service.soft_delete_acid_session_service')
router_content = router_content.replace('repo.get_all_banking_documents', 'service.get_all_banking_documents_service')
router_content = router_content.replace('repo.get_banking_document_by_id', 'service.get_banking_document_by_id_service')
router_content = router_content.replace('repo.get_all_shipment_documents', 'service.get_all_shipment_documents_service')
router_content = router_content.replace('repo.get_draft_bl_reviews', 'service.get_draft_bl_reviews_service')
router_content = router_content.replace('repo.get_draft_bl_review_by_id', 'service.get_draft_bl_review_by_id_service')
router_content = router_content.replace('repo.get_coo_reviews', 'service.get_coo_reviews_service')
router_content = router_content.replace('repo.get_inspection_reviews', 'service.get_inspection_reviews_service')

with open(router_file, 'w', encoding='utf-8') as f:
    f.write(router_content)

print('import_documentation fixed')
