import re

service_file = 'modules/smart_tasks/service.py'
router_file = 'modules/smart_tasks/router.py'

with open(service_file, 'r', encoding='utf-8') as f:
    service_content = f.read()

wrappers = '''
def get_all_tasks_service(db: Session, include_inactive: bool = False, task_type: str = None, status: str = None, priority: str = None, import_file_id: int = None, search: str = None):
    return repo.get_all_tasks(db, include_inactive=include_inactive, task_type=task_type, status=status, priority=priority, import_file_id=import_file_id, search=search)

def get_due_and_overdue_tasks_service(db: Session, target_date_str: str = None):
    return repo.get_due_and_overdue_tasks(db, target_date_str=target_date_str)

def get_task_by_id_service(db: Session, task_id: int):
    return repo.get_task_by_id(db, task_id)

def soft_delete_task_service(db: Session, task_id: int):
    return repo.soft_delete_task(db, task_id)

def restore_task_service(db: Session, task_id: int):
    return repo.restore_task(db, task_id)

def generate_phase_tasks_service(db: Session, import_file_id: int) -> dict:
    from modules.import_files.repository import get_import_file_by_id
    import_file = get_import_file_by_id(db, import_file_id)
    if not import_file:
        raise HTTPException(status_code=404, detail="ملف الاستيراد غير موجود.")

    before_count = db.query(SmartTask).filter(
        SmartTask.import_file_id == import_file_id,
        SmartTask.task_type == "System Generated",
        SmartTask.is_active == True,
    ).count()

    auto_generate_system_tasks_for_file(db, import_file)

    after_count = db.query(SmartTask).filter(
        SmartTask.import_file_id == import_file_id,
        SmartTask.task_type == "System Generated",
        SmartTask.is_active == True,
    ).count()

    new_tasks_created = after_count - before_count
    return {
        "import_file_id": import_file_id,
        "current_phase": import_file.current_module,
        "new_tasks_created": new_tasks_created,
        "total_system_tasks": after_count,
        "message": f"تم إنشاء {new_tasks_created} مهمة جديدة تلقائياً للمرحلة {import_file.current_module}",
    }

def complete_phase_tasks_service(db: Session, import_file_id: int, completed_phase: str) -> dict:
    from modules.import_files.repository import get_import_file_by_id
    import_file = get_import_file_by_id(db, import_file_id)
    if not import_file:
        raise HTTPException(status_code=404, detail="ملف الاستيراد غير موجود.")

    auto_close_completed_phase_tasks(db, import_file_id, completed_phase)

    return {
        "import_file_id": import_file_id,
        "completed_phase": completed_phase,
        "message": f"تم إغلاق جميع مهام المرحلة {completed_phase} تلقائياً.",
    }
'''

if 'get_all_tasks_service' not in service_content:
    service_content += wrappers
    with open(service_file, 'w', encoding='utf-8') as f:
        f.write(service_content)

with open(router_file, 'r', encoding='utf-8') as f:
    router_content = f.read()

router_content = re.sub(r'import modules\.smart_tasks\.repository as repo\n', '', router_content)
router_content = router_content.replace('repo.get_all_tasks', 'service.get_all_tasks_service')
router_content = router_content.replace('repo.get_due_and_overdue_tasks', 'service.get_due_and_overdue_tasks_service')
router_content = router_content.replace('repo.get_task_by_id', 'service.get_task_by_id_service')
router_content = router_content.replace('repo.soft_delete_task', 'service.soft_delete_task_service')
router_content = router_content.replace('repo.restore_task', 'service.restore_task_service')

# replace generate_phase_tasks content
generate_phase_match = re.search(r'def generate_phase_tasks\(import_file_id: int, db: Session = Depends\(get_db\)\):\n(.*?)(?=\n\n@router|\Z)', router_content, re.DOTALL)
if generate_phase_match:
    replacement = '    """\n    Medium Priority: Automatic Smart Task Generation on Phase Transition.\n    Call this endpoint whenever an import file advances to a new phase.\n    System will auto-create standard follow-up tasks for the current phase.\n    """\n    return service.generate_phase_tasks_service(db, import_file_id)'
    router_content = router_content[:generate_phase_match.start(1)] + replacement + router_content[generate_phase_match.end(1):]

complete_phase_match = re.search(r'def complete_phase_tasks\(\n    import_file_id: int,\n    completed_phase: str,\n    db: Session = Depends\(get_db\),\n\):\n(.*?)(?=\n\n@router|\Z)', router_content, re.DOTALL)
if complete_phase_match:
    replacement = '    """\n    Medium Priority: Auto-close all system tasks belonging to a completed phase.\n    E.g. when Phase 3 is done, all Phase 3 system tasks become \'Completed\'.\n    """\n    return service.complete_phase_tasks_service(db, import_file_id, completed_phase)'
    router_content = router_content[:complete_phase_match.start(1)] + replacement + router_content[complete_phase_match.end(1):]


with open(router_file, 'w', encoding='utf-8') as f:
    f.write(router_content)

print('smart_tasks fixed')
