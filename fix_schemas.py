import os
import re

files_with_class = [
    'modules/audit_logs/schemas.py',
    'modules/auth/schemas.py',
    'modules/external_service_providers/schemas.py',
    'modules/notifications/schemas.py',
    'modules/shipment_updates/schemas.py',
    'modules/smart_tasks/schemas.py'
]

for f in files_with_class:
    if not os.path.exists(f): continue
    with open(f, 'r', encoding='utf-8') as file:
        content = file.read()
    
    content = re.sub(r'class\s+Config:\s*from_attributes\s*=\s*True', 'model_config = ConfigDict(from_attributes=True)', content)
    
    if 'ConfigDict' not in content:
        content = content.replace('from pydantic import BaseModel', 'from pydantic import BaseModel, ConfigDict')
    
    with open(f, 'w', encoding='utf-8') as file:
        file.write(content)

files_with_dict = [
    'modules/customs_tariff/schemas.py',
    'modules/incoterms/schemas.py',
    'modules/smart_document_upload/schemas.py'
]

for f in files_with_dict:
    if not os.path.exists(f): continue
    with open(f, 'r', encoding='utf-8') as file:
        content = file.read()
    
    content = content.replace('model_config = {"from_attributes": True}', 'model_config = ConfigDict(from_attributes=True)')
    
    if 'ConfigDict' not in content:
        content = content.replace('from pydantic import BaseModel', 'from pydantic import BaseModel, ConfigDict')
        if 'from pydantic import BaseModel' not in content:
            content = content.replace('from pydantic import ', 'from pydantic import ConfigDict, ')
        
    with open(f, 'w', encoding='utf-8') as file:
        file.write(content)

print('Done replacement.')
