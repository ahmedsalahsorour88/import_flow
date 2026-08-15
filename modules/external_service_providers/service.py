from typing import List, Optional
from fastapi import HTTPException, status
from sqlalchemy.orm import Session
from .repository import ExternalServiceProviderRepository
from .schemas import PartnerCreate, PartnerResponse, PartnerUpdate
from .validators import ExternalServiceProviderValidator


class ExternalServiceProviderService:
    def __init__(self, db: Session):
        self.repository = ExternalServiceProviderRepository(db)
        self.validator = ExternalServiceProviderValidator(db)

    def generate_partner_code(self) -> str:
        last_id = self.repository.get_last_partner_id()
        next_num = last_id + 1
        return f"ESP-{next_num:06d}"

    def get_all_partners(self, partner_type: Optional[str] = None, include_inactive: bool = False) -> List[PartnerResponse]:
        return self.repository.get_all(partner_type=partner_type, include_inactive=include_inactive)

    def get_partner_by_id(self, provider_id: int) -> PartnerResponse:
        partner = self.repository.get_by_id(provider_id)
        if not partner:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Partner not found")
        return partner

    def create_partner(self, data: PartnerCreate) -> PartnerResponse:
        self.validator.validate_create(data)
        partner_code = self.generate_partner_code()
        return self.repository.create(data, partner_code=partner_code)

    def update_partner(self, provider_id: int, data: PartnerUpdate) -> PartnerResponse:
        partner = self.repository.update(provider_id, data)
        if not partner:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Partner not found")
        return partner

    def soft_delete_partner(self, provider_id: int) -> dict:
        success = self.repository.soft_delete(provider_id)
        if not success:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Partner not found")
        return {"detail": "Partner deactivated successfully"}

    def restore_partner(self, provider_id: int) -> dict:
        success = self.repository.restore(provider_id)
        if not success:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Partner not found")
        return {"detail": "Partner reactivated successfully"}

    def get_partner_statement_of_account(self, provider_id: int):
        partner = self.get_partner_by_id(provider_id)
        p_name = (partner.partner_name or "").strip().lower()

        currency_balances = {}  # { 'USD': {'invoiced': 0.0, 'paid': 0.0}, 'EGP': ... }
        ledger_entries = []

        # 1. Inspect Financial Settlement Expense Invoices
        try:
            from modules.financial_settlement.model import LandedCostSettlementRecord
            from modules.import_files.model import ImportFile

            records = self.repository.db.query(LandedCostSettlementRecord).filter(
                LandedCostSettlementRecord.is_active == True
            ).all()

            for rec in records:
                file_code = None
                if rec.import_file_id:
                    imp_file = self.repository.db.query(ImportFile).filter(
                        ImportFile.import_file_id == rec.import_file_id
                    ).first()
                    if imp_file:
                        file_code = imp_file.file_code

                invoices = rec.expense_invoices or []
                for inv in invoices:
                    inv_provider = (inv.get("provider_name") or "").strip().lower()
                    if p_name in inv_provider or inv_provider in p_name or (inv.get("partner_id") == provider_id):
                        curr = (inv.get("currency") or "EGP").upper()
                        amount_fx = float(inv.get("amount_fx") or inv.get("amount_egp") or 0.0)
                        
                        if curr not in currency_balances:
                            currency_balances[curr] = {"invoiced": 0.0, "paid": 0.0}
                        currency_balances[curr]["invoiced"] += amount_fx

                        inv_no = inv.get("invoice_no") or f"INV-{rec.settlement_code}"
                        inv_date = inv.get("invoice_date") or rec.created_at.strftime("%Y-%m-%d")

                        ledger_entries.append({
                            "entry_id": f"INV-{rec.settlement_id}-{inv_no}",
                            "entry_date": inv_date,
                            "entry_type": "Invoice (فاتورة مستحقة)",
                            "reference_no": inv_no,
                            "description": f"{inv.get('category', 'Expense')} - {rec.settlement_code}",
                            "import_file_code": file_code,
                            "currency": curr,
                            "debit_amount": amount_fx,
                            "credit_amount": 0.0,
                            "running_balance": 0.0,
                            "status": rec.status or "Logged"
                        })
        except Exception:
            pass

        # 2. Inspect Payment Requests (Paid & Approved Payments)
        try:
            from modules.financial_approval.model import PaymentRequestSession
            from modules.import_files.model import ImportFile

            payments = self.repository.db.query(PaymentRequestSession).filter(
                PaymentRequestSession.is_active == True
            ).all()

            for pay in payments:
                pay_supp = (pay.supplier_name or "").strip().lower()
                pay_bene = (pay.beneficiary_name or "").strip().lower()

                if p_name in pay_supp or p_name in pay_bene or pay_supp in p_name:
                    curr = (pay.currency_code or "USD").upper()
                    amt = float(pay.requested_amount or 0.0)

                    if curr not in currency_balances:
                        currency_balances[curr] = {"invoiced": 0.0, "paid": 0.0}

                    # If payment is Paid or Approved, credit it
                    if pay.status in ["Paid", "Approved"]:
                        currency_balances[curr]["paid"] += amt

                    file_code = None
                    if pay.import_file_id:
                        imp_file = self.repository.db.query(ImportFile).filter(
                            ImportFile.import_file_id == pay.import_file_id
                        ).first()
                        if imp_file:
                            file_code = imp_file.file_code

                    p_date = pay.request_date.strftime("%Y-%m-%d") if pay.request_date else pay.created_at.strftime("%Y-%m-%d")

                    ledger_entries.append({
                        "entry_id": f"PAY-{pay.payment_id}",
                        "entry_date": p_date,
                        "entry_type": "Payment (سداد مالي)",
                        "reference_no": pay.payment_code or f"PAY-{pay.payment_id}",
                        "description": f"{pay.title} ({pay.payment_type})",
                        "import_file_code": file_code,
                        "currency": curr,
                        "debit_amount": 0.0,
                        "credit_amount": amt,
                        "running_balance": 0.0,
                        "status": pay.status
                    })
        except Exception:
            pass

        # Ensure at least EGP & USD are represented if empty
        if not currency_balances:
            currency_balances["EGP"] = {"invoiced": 0.0, "paid": 0.0}
            currency_balances["USD"] = {"invoiced": 0.0, "paid": 0.0}

        balances_list = []
        for curr, data in currency_balances.items():
            inv = data["invoiced"]
            pd = data["paid"]
            balances_list.append({
                "currency": curr,
                "total_invoiced": round(inv, 2),
                "total_paid": round(pd, 2),
                "balance_due": round(inv - pd, 2)
            })

        # Sort ledger entries by date
        ledger_entries.sort(key=lambda x: x["entry_date"], reverse=True)

        return {
            "provider_id": partner.provider_id,
            "partner_code": partner.partner_code,
            "partner_name": partner.partner_name,
            "partner_type": partner.partner_type,
            "currency_balances": balances_list,
            "ledger_entries": ledger_entries,
            "total_invoices_count": sum(1 for e in ledger_entries if "Invoice" in e["entry_type"]),
            "total_payments_count": sum(1 for e in ledger_entries if "Payment" in e["entry_type"])
        }