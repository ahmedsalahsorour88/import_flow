import re

service_file = 'modules/container_loader/service.py'
router_file = 'modules/container_loader/router.py'

with open(service_file, 'r', encoding='utf-8') as f:
    service_content = f.read()

if 'def list_container_specs_service' not in service_content:
    service_content += '''

def list_container_specs_service(db: Session) -> List[ContainerSpec]:
    return get_all_container_specs(db)
'''
    with open(service_file, 'w', encoding='utf-8') as f:
        f.write(service_content)

with open(router_file, 'r', encoding='utf-8') as f:
    router_content = f.read()

router_content = re.sub(r'from \.repository import get_all_container_specs\n', '', router_content)
router_content = re.sub(r'from \.service import evaluate_container_loading_service', 'from .service import evaluate_container_loading_service, list_container_specs_service', router_content)
router_content = router_content.replace('get_all_container_specs(db)', 'list_container_specs_service(db)')

with open(router_file, 'w', encoding='utf-8') as f:
    f.write(router_content)

print('container_loader fixed')
