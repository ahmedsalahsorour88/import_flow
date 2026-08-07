from fastapi import APIRouter

router = APIRouter()


@router.get("/")
def shipments_home():
    return {
        "module": "Shipments",
        "status": "working"
    }