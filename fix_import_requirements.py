import re

service_file = 'modules/import_requirements/service.py'
router_file = 'modules/import_requirements/router.py'

with open(service_file, 'r', encoding='utf-8') as f:
    service_content = f.read()

wrappers = '''
def get_all_assessments_service(db: Session, import_file_id: int = None, overall_status: str = None, risk_level: str = None, search: str = None, include_inactive: bool = False):
    return repo.get_all_assessments(db, import_file_id=import_file_id, overall_status=overall_status, risk_level=risk_level, search=search, include_inactive=include_inactive)

def get_assessment_by_id_service(db: Session, assessment_id: int):
    return repo.get_assessment_by_id(db, assessment_id)

def soft_delete_assessment_service(db: Session, assessment_id: int):
    return repo.soft_delete_assessment(db, assessment_id)
'''

if 'get_all_assessments_service' not in service_content:
    service_content += wrappers
    with open(service_file, 'w', encoding='utf-8') as f:
        f.write(service_content)

with open(router_file, 'r', encoding='utf-8') as f:
    router_content = f.read()

router_content = re.sub(r'import modules\.import_requirements\.repository as repo\n', '', router_content)
router_content = router_content.replace('repo.get_all_assessments', 'service.get_all_assessments_service')
router_content = router_content.replace('repo.get_assessment_by_id', 'service.get_assessment_by_id_service')
router_content = router_content.replace('repo.soft_delete_assessment', 'service.soft_delete_assessment_service')

with open(router_file, 'w', encoding='utf-8') as f:
    f.write(router_content)

print('import_requirements fixed')
