import re

service_file = 'modules/financial_approval/service.py'
router_file = 'modules/financial_approval/router.py'

with open(service_file, 'r', encoding='utf-8') as f:
    service_content = f.read()

wrappers = '''
def get_all_payment_requests_service(db: Session, include_inactive: bool = False, search: Optional[str] = None, po_id: Optional[int] = None, supplier_id: Optional[int] = None, status: Optional[str] = None) -> List[PaymentRequestSession]:
    return repo.get_all_payment_requests(db, include_inactive=include_inactive, search=search, po_id=po_id, supplier_id=supplier_id, status=status)

def get_payment_request_by_id_service(db: Session, payment_id: int) -> Optional[PaymentRequestSession]:
    return repo.get_payment_request_by_id(db, payment_id)

def soft_delete_payment_request_service(db: Session, payment_id: int) -> bool:
    return repo.soft_delete_payment_request(db, payment_id)

def restore_payment_request_service(db: Session, payment_id: int) -> bool:
    return repo.restore_payment_request(db, payment_id)

def get_all_import_budgets_service(db: Session, include_inactive: bool = False, search: Optional[str] = None, import_file_id: Optional[int] = None, po_id: Optional[int] = None, budget_status: Optional[str] = None) -> List[ImportBudgetApproval]:
    return repo.get_all_import_budgets(db, include_inactive=include_inactive, search=search, import_file_id=import_file_id, po_id=po_id, budget_status=budget_status)
'''

if 'get_all_payment_requests_service' not in service_content:
    service_content += wrappers
    with open(service_file, 'w', encoding='utf-8') as f:
        f.write(service_content)

with open(router_file, 'r', encoding='utf-8') as f:
    router_content = f.read()

router_content = re.sub(r'import modules\.financial_approval\.repository as repo\n', '', router_content)
router_content = router_content.replace('repo.get_all_payment_requests', 'service.get_all_payment_requests_service')
router_content = router_content.replace('repo.get_payment_request_by_id', 'service.get_payment_request_by_id_service')
router_content = router_content.replace('repo.soft_delete_payment_request', 'service.soft_delete_payment_request_service')
router_content = router_content.replace('repo.restore_payment_request', 'service.restore_payment_request_service')
router_content = router_content.replace('repo.get_all_import_budgets', 'service.get_all_import_budgets_service')

with open(router_file, 'w', encoding='utf-8') as f:
    f.write(router_content)

print('financial_approval fixed')
