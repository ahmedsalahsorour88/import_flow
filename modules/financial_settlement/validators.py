from typing import List, Dict, Any
from fastapi import HTTPException

def validate_expense_invoice(invoice_no: str, amount_fx: float, exchange_rate: float) -> None:
    if not invoice_no or not invoice_no.strip():
        raise HTTPException(status_code=400, detail="يلزم إدخال رقم الفاتورة أو الإيصال المالي للمصروف.")
    if amount_fx <= 0:
        raise HTTPException(status_code=400, detail="مبلغ الفاتورة يجب أن يكون أكبر من الصفر.")
    if exchange_rate <= 0:
        raise HTTPException(status_code=400, detail="سعر الصرف يجب أن يكون أكبر من الصفر.")

def validate_items_allocation_readiness(items: List[Dict[str, Any]]) -> None:
    if not items or len(items) == 0:
        raise HTTPException(
            status_code=400,
            detail="لا توجد بنود أصناف بالشحنة لإجراء توزيع التكاليف وحساب الـ Landed Cost.",
        )
