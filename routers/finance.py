from fastapi import APIRouter

router = APIRouter()


@router.get("/")
def finance_home():
    return {
        "module": "Finance",
        "status": "working"
    }