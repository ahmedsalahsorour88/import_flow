import re

service_file = 'modules/lifecycle_board/service.py'
router_file = 'modules/lifecycle_board/router.py'

with open(service_file, 'r', encoding='utf-8') as f:
    service_content = f.read()

wrappers = '''
def get_all_activities_service(db: Session, import_file_code: str):
    return repo.get_all_activities(db, import_file_code=import_file_code)
'''

if 'get_all_activities_service' not in service_content:
    service_content += wrappers
    with open(service_file, 'w', encoding='utf-8') as f:
        f.write(service_content)

with open(router_file, 'r', encoding='utf-8') as f:
    router_content = f.read()

router_content = re.sub(r'import modules\.lifecycle_board\.repository as repo\n', '', router_content)
router_content = router_content.replace('repo.get_all_activities', 'service.get_all_activities_service')

with open(router_file, 'w', encoding='utf-8') as f:
    f.write(router_content)

print('lifecycle_board fixed')
