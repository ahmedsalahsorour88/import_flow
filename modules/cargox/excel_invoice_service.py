"""
Standard Excel Commercial Invoice Service (BP-025 / CGX-002).
Generates official Excel invoice templates with Defined Names (Named Ranges) and structured InvoiceItems Table,
parses supplier-filled templates without hardcoded cell references, and computes side-by-side comparison matrices.
"""

import io
import re
from typing import Dict, Any, List, Optional
import openpyxl
from openpyxl.styles import Font, Alignment, PatternFill, Border, Side
from openpyxl.worksheet.table import Table, TableStyleInfo
from openpyxl.workbook.defined_name import DefinedName

from modules.cargox.schemas import (
    StandardInvoicePayload,
    StandardInvoiceLineItem,
    StandardInvoiceComparisonResponse,
    StandardInvoiceComparisonRow,
    StandardInvoiceLineComparisonRow,
)


def _sanitize_str(val: Any) -> str:
    if val is None:
        return ""
    return str(val).strip()


def _safe_float(val: Any, default: float = 0.0) -> float:
    if val is None:
        return default
    if isinstance(val, (int, float)):
        return float(val)
    try:
        s = str(val).replace(",", "").replace("$", "").replace("€", "").replace("EGP", "").strip()
        return float(s)
    except (ValueError, TypeError):
        return default


def generate_standard_invoice_excel_bytes(payload: StandardInvoicePayload) -> bytes:
    """
    Generates an authentic Excel Commercial Invoice workbook (.xlsx).
    Configures all 36+ Defined Names (Named Ranges) and the structured InvoiceItems Table
    with formulas for line totals, subtotal, and total amount.
    """
    wb = openpyxl.Workbook()
    ws = wb.active
    ws.title = "Commercial Invoice"

    header_fill = PatternFill(start_color="2C3E50", end_color="2C3E50", fill_type="solid")
    table_hdr_fill = PatternFill(start_color="34495E", end_color="34495E", fill_type="solid")
    accent_fill = PatternFill(start_color="ECF0F1", end_color="ECF0F1", fill_type="solid")
    gold_fill = PatternFill(start_color="FEF9E7", end_color="FEF9E7", fill_type="solid")
    white_font = Font(name="Segoe UI", size=10, bold=True, color="FFFFFF")
    bold_font = Font(name="Segoe UI", size=9, bold=True, color="2C3E50")
    regular_font = Font(name="Segoe UI", size=9, color="333333")
    title_font = Font(name="Segoe UI", size=14, bold=True, color="27AE60")
    thin_border = Border(
        left=Side(style="thin", color="BDC3C7"),
        right=Side(style="thin", color="BDC3C7"),
        top=Side(style="thin", color="BDC3C7"),
        bottom=Side(style="thin", color="BDC3C7"),
    )

    ws["B2"] = payload.invoice_type.upper()
    ws["B2"].font = title_font
    ws["B2"].alignment = Alignment(vertical="center")

    named_range_mapping = {
        "SellerName": ("D2", payload.seller_name or "Foreign Exporter Name"),
        "SellerRegistrationCode": ("D3", payload.seller_tax_id or "VAT/TAX ID"),
        "SellerCode": ("D3", payload.seller_tax_id or "VAT/TAX ID"),
        "SellerAddress": ("D4", payload.seller_address or ""),
        "SellerCity": ("D5", payload.seller_city or ""),
        "SellerCountryCode": ("F5", payload.seller_country_code or "IT"),
        "SellerContactName": ("D6", payload.seller_contact_name or ""),
        "SellerPhone": ("F6", payload.seller_phone or ""),
        "SellerFax": ("H6", payload.seller_fax or ""),
        "SellerContactEmail": ("D7", payload.seller_email or ""),
        "SellerWebSite": ("F7", payload.seller_website or ""),
        "BuyerName": ("B9", payload.buyer_name or "Egyptian Importing Company"),
        "BuyerAddress": ("B10", payload.buyer_address or ""),
        "BuyerCode": ("B11", payload.buyer_tax_id or "123456789"),
        "BuyerContactName": ("D9", payload.buyer_contact_name or ""),
        "BuyerPhone": ("F9", payload.buyer_phone or ""),
        "BuyerFax": ("H9", payload.buyer_fax or ""),
        "BuyerContactEmail": ("D10", payload.buyer_email or ""),
        "ACIDNumber": ("D11", payload.acid_number or "PENDING"),
        "InvoiceType": ("B12", payload.invoice_type),
        "InvoiceNumber": ("B13", payload.invoice_number or "INV-2026-001"),
        "InvoiceDate": ("D13", payload.invoice_date or "2026-08-21"),
        "PurchaseOrderNumber": ("B14", payload.purchase_order_number or ""),
        "PurchaseOrderDate": ("D14", payload.purchase_order_date or ""),
        "ProformaInvoiceNumber": ("H12", payload.proforma_invoice_number or ""),
        "OriginPort": ("F13", payload.origin_port or ""),
        "DestinationPort": ("F14", payload.destination_port or "EGALY"),
        "CurrencyCode": ("B15", payload.currency_code or "EUR"),
        "IncoTerm": ("D15", payload.incoterm or "EXW"),
        "GrossWeight": ("H13", payload.gross_weight),
        "NetWeight": ("H14", payload.net_weight),
        "WeightUnit": ("H15", payload.weight_unit or "KGM"),
    }

    labels = {
        "C2": "Exporter:",
        "C3": "Registration #:",
        "C4": "Address:",
        "C5": "City Code:",
        "E5": "Country:",
        "C6": "Exporter Contact:",
        "E6": "Phone:",
        "G6": "Fax:",
        "C7": "Email:",
        "E7": "Web Site:",
        "A9": "Export To:",
        "A10": "Address:",
        "A11": "Egypt Tax Code:",
        "C9": "Importer Contact:",
        "E9": "Phone:",
        "G9": "Fax:",
        "C10": "Email:",
        "C11": "ACID #:",
        "A12": "Doc Type:",
        "G12": "Proforma Inv #:",
        "A13": "Invoice #:",
        "C13": "Invoice Date:",
        "E13": "Origin Port:",
        "G13": "Gross Weight:",
        "A14": "PO #:",
        "C14": "PO Date:",
        "E14": "Destination Port:",
        "G14": "Net Weight:",
        "A15": "Currency:",
        "C15": "Inco Term:",
        "G15": "Weight Unit:",
    }

    for cell_pos, label_text in labels.items():
        cell = ws[cell_pos]
        cell.value = label_text
        cell.font = bold_font
        cell.fill = accent_fill
        cell.alignment = Alignment(horizontal="right", vertical="center")

    for name, (cell_coord, val) in named_range_mapping.items():
        cell = ws[cell_coord]
        cell.value = val
        cell.font = regular_font
        cell.border = thin_border
        dname = DefinedName(name, attr_text=f"'{ws.title}'!${cell_coord[0]}${cell_coord[1:]}")
        wb.defined_names.add(dname)

    start_row = 18
    table_headers = [
        "#", "Product Code", "TradeMarkOwner/Manufacturer", "Brand Name", "Model",
        "HS Tariff Code", "Country of Origin", "Description", "Quantity", "Qty Unit",
        "Expiry Date", "Unit Price", "Unit price basis", "Gross Weight", "Net Weight", "Total"
    ]

    for col_idx, header_title in enumerate(table_headers, start=1):
        col_letter = openpyxl.utils.get_column_letter(col_idx)
        cell = ws[f"{col_letter}{start_row}"]
        cell.value = header_title
        cell.font = white_font
        cell.fill = table_hdr_fill
        cell.alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)

    items = payload.items or [
        StandardInvoiceLineItem(
            index=1,
            product_code="ITEM-001",
            manufacturer=payload.seller_name or "Manufacturer",
            brand_name="Brand",
            model="Model-A",
            hs_code="940310",
            country_of_origin=payload.seller_country_code or "IT",
            description="Office Furniture Set",
            quantity=10.0,
            qty_unit="SET",
            expiry_date="",
            unit_price=250.0,
            unit_price_basis="SET",
            gross_weight_kg=120.0,
            net_weight_kg=110.0,
            total_amount=2500.0,
        )
    ]

    current_row = start_row + 1
    for item in items:
        ws[f"A{current_row}"] = item.index
        ws[f"B{current_row}"] = item.product_code or ""
        ws[f"C{current_row}"] = item.manufacturer or ""
        ws[f"D{current_row}"] = item.brand_name or ""
        ws[f"E{current_row}"] = item.model or ""
        ws[f"F{current_row}"] = item.hs_code
        ws[f"G{current_row}"] = item.country_of_origin
        ws[f"H{current_row}"] = item.description
        ws[f"I{current_row}"] = item.quantity
        ws[f"J{current_row}"] = item.qty_unit
        ws[f"K{current_row}"] = item.expiry_date or ""
        ws[f"L{current_row}"] = item.unit_price
        ws[f"M{current_row}"] = item.unit_price_basis or "PCS"
        ws[f"N{current_row}"] = item.gross_weight_kg
        ws[f"O{current_row}"] = item.net_weight_kg
        ws[f"P{current_row}"] = f"=I{current_row}*L{current_row}"

        for col_idx in range(1, 17):
            col_letter = openpyxl.utils.get_column_letter(col_idx)
            cell = ws[f"{col_letter}{current_row}"]
            cell.font = regular_font
            cell.border = thin_border
            if col_idx in (1, 6, 7, 10, 13):
                cell.alignment = Alignment(horizontal="center")
            elif col_idx in (9, 12, 14, 15, 16):
                cell.alignment = Alignment(horizontal="right")
                if col_idx in (12, 16):
                    cell.number_format = "#,##0.00"

        current_row += 1

    end_row = max(current_row - 1, start_row + 1)
    table_range = f"A{start_row}:P{end_row}"
    tab = Table(displayName="InvoiceItems", ref=table_range)
    style = TableStyleInfo(name="TableStyleMedium9", showFirstColumn=False, showLastColumn=False, showRowStripes=True, showColumnStripes=False)
    tab.tableStyleInfo = style
    ws.add_table(tab)

    totals_start_row = end_row + 2
    ws[f"O{totals_start_row}"] = "Invoice Subtotal"
    ws[f"P{totals_start_row}"] = f"=SUM(P{start_row+1}:P{end_row})"
    ws[f"O{totals_start_row}"].font = bold_font
    ws[f"P{totals_start_row}"].font = bold_font
    ws[f"P{totals_start_row}"].number_format = "#,##0.00"
    wb.defined_names.add(DefinedName("InvoiceSubtotal", attr_text=f"'{ws.title}'!$P${totals_start_row}"))

    ws[f"O{totals_start_row+1}"] = "Freight Cost"
    ws[f"P{totals_start_row+1}"] = payload.freight_cost
    ws[f"O{totals_start_row+1}"].font = bold_font
    ws[f"P{totals_start_row+1}"].number_format = "#,##0.00"
    wb.defined_names.add(DefinedName("FreightCost", attr_text=f"'{ws.title}'!$P${totals_start_row+1}"))

    ws[f"O{totals_start_row+2}"] = "Insurance Cost"
    ws[f"P{totals_start_row+2}"] = payload.insurance_cost
    ws[f"O{totals_start_row+2}"].font = bold_font
    ws[f"P{totals_start_row+2}"].number_format = "#,##0.00"
    wb.defined_names.add(DefinedName("InsuranceCost", attr_text=f"'{ws.title}'!$P${totals_start_row+2}"))

    ws[f"O{totals_start_row+3}"] = "Other Costs"
    ws[f"P{totals_start_row+3}"] = payload.other_costs
    ws[f"O{totals_start_row+3}"].font = bold_font
    ws[f"P{totals_start_row+3}"].number_format = "#,##0.00"
    wb.defined_names.add(DefinedName("OtherCosts", attr_text=f"'{ws.title}'!$P${totals_start_row+3}"))

    ws[f"O{totals_start_row+4}"] = "Total Amount"
    ws[f"P{totals_start_row+4}"] = f"=P{totals_start_row}+P{totals_start_row+1}+P{totals_start_row+2}+P{totals_start_row+3}"
    ws[f"O{totals_start_row+4}"].font = Font(name="Segoe UI", size=10, bold=True, color="27AE60")
    ws[f"P{totals_start_row+4}"].font = Font(name="Segoe UI", size=10, bold=True, color="27AE60")
    ws[f"P{totals_start_row+4}"].fill = gold_fill
    ws[f"P{totals_start_row+4}"].number_format = "#,##0.00"
    wb.defined_names.add(DefinedName("TotalAmount", attr_text=f"'{ws.title}'!$P${totals_start_row+4}"))

    col_widths = {"A": 6, "B": 22, "C": 28, "D": 22, "E": 18, "F": 16, "G": 18, "H": 34, "I": 12, "J": 12, "K": 14, "L": 14, "M": 16, "N": 14, "O": 18, "P": 18}
    for col_letter, width in col_widths.items():
        ws.column_dimensions[col_letter].width = width

    output = io.BytesIO()
    wb.save(output)
    return output.getvalue()


def parse_standard_invoice_excel_bytes(file_bytes: bytes) -> StandardInvoicePayload:
    """
    Parses a supplier-uploaded Excel Commercial Invoice workbook (.xlsx)
    using Named Ranges (wb.defined_names) and the InvoiceItems structured Table.
    """
    wb = openpyxl.load_workbook(io.BytesIO(file_bytes), data_only=True)
    ws = wb.active

    def get_defined_val(name_key: str) -> Any:
        try:
            if name_key in wb.defined_names:
                dn = wb.defined_names[name_key]
                destinations = list(dn.destinations)
                if destinations:
                    sheet_title, cell_coord = destinations[0]
                    target_ws = wb[sheet_title] if sheet_title in wb.sheetnames else ws
                    return target_ws[cell_coord].value
        except Exception:
            pass
        return None

    fallback_coords = {
        "SellerName": "D2", "SellerRegistrationCode": "D3", "SellerCode": "D3",
        "SellerAddress": "D4", "SellerCity": "D5", "SellerCountryCode": "F5",
        "SellerContactName": "D6", "SellerPhone": "F6", "SellerFax": "H6",
        "SellerContactEmail": "D7", "SellerWebSite": "F7",
        "BuyerName": "B9", "BuyerAddress": "B10", "BuyerCode": "B11",
        "BuyerContactName": "D9", "BuyerPhone": "F9", "BuyerFax": "H9",
        "BuyerContactEmail": "D10", "ACIDNumber": "D11",
        "InvoiceType": "B12", "InvoiceNumber": "B13", "InvoiceDate": "D13",
        "PurchaseOrderNumber": "B14", "PurchaseOrderDate": "D14",
        "ProformaInvoiceNumber": "H12", "OriginPort": "F13",
        "DestinationPort": "F14", "CurrencyCode": "B15", "IncoTerm": "D15",
        "GrossWeight": "H13", "NetWeight": "H14", "WeightUnit": "H15",
    }

    def fetch_field(field_name: str) -> Any:
        val = get_defined_val(field_name)
        if val is not None and str(val).strip() != "":
            return val
        coord = fallback_coords.get(field_name)
        if coord and coord in ws:
            return ws[coord].value
        return None

    seller_name = _sanitize_str(fetch_field("SellerName"))
    seller_tax_id = _sanitize_str(fetch_field("SellerRegistrationCode") or fetch_field("SellerCode"))
    seller_address = _sanitize_str(fetch_field("SellerAddress"))
    seller_city = _sanitize_str(fetch_field("SellerCity"))
    seller_country_code = _sanitize_str(fetch_field("SellerCountryCode"))
    seller_contact_name = _sanitize_str(fetch_field("SellerContactName"))
    seller_phone = _sanitize_str(fetch_field("SellerPhone"))
    seller_fax = _sanitize_str(fetch_field("SellerFax"))
    seller_email = _sanitize_str(fetch_field("SellerContactEmail"))
    seller_website = _sanitize_str(fetch_field("SellerWebSite"))

    buyer_name = _sanitize_str(fetch_field("BuyerName"))
    buyer_address = _sanitize_str(fetch_field("BuyerAddress"))
    buyer_tax_id = _sanitize_str(fetch_field("BuyerCode"))
    buyer_contact_name = _sanitize_str(fetch_field("BuyerContactName"))
    buyer_phone = _sanitize_str(fetch_field("BuyerPhone"))
    buyer_fax = _sanitize_str(fetch_field("BuyerFax"))
    buyer_email = _sanitize_str(fetch_field("BuyerContactEmail"))
    acid_number = _sanitize_str(fetch_field("ACIDNumber"))

    invoice_type = _sanitize_str(fetch_field("InvoiceType")) or "Commercial Invoice"
    invoice_number = _sanitize_str(fetch_field("InvoiceNumber"))
    invoice_date = _sanitize_str(fetch_field("InvoiceDate"))
    purchase_order_number = _sanitize_str(fetch_field("PurchaseOrderNumber"))
    purchase_order_date = _sanitize_str(fetch_field("PurchaseOrderDate"))
    proforma_invoice_number = _sanitize_str(fetch_field("ProformaInvoiceNumber"))
    origin_port = _sanitize_str(fetch_field("OriginPort"))
    destination_port = _sanitize_str(fetch_field("DestinationPort"))
    currency_code = _sanitize_str(fetch_field("CurrencyCode")) or "EUR"
    incoterm = _sanitize_str(fetch_field("IncoTerm")) or "EXW"
    gross_weight = _safe_float(fetch_field("GrossWeight"))
    net_weight = _safe_float(fetch_field("NetWeight"))
    weight_unit = _sanitize_str(fetch_field("WeightUnit")) or "KGM"

    freight_cost = _safe_float(fetch_field("FreightCost"))
    insurance_cost = _safe_float(fetch_field("InsuranceCost"))
    other_costs = _safe_float(fetch_field("OtherCosts"))

    items: List[StandardInvoiceLineItem] = []
    table_range = None
    for tbl in ws.tables.values():
        if tbl.displayName == "InvoiceItems" or "Invoice" in tbl.displayName:
            table_range = tbl.ref
            break

    if table_range:
        min_col, min_row, max_col, max_row = openpyxl.utils.range_boundaries(table_range)
        for row_idx in range(min_row + 1, max_row + 1):
            hs_code = _sanitize_str(ws.cell(row=row_idx, column=6).value)
            desc = _sanitize_str(ws.cell(row=row_idx, column=8).value)
            if not hs_code and not desc:
                continue

            item = StandardInvoiceLineItem(
                index=int(_safe_float(ws.cell(row=row_idx, column=1).value, len(items) + 1)),
                product_code=_sanitize_str(ws.cell(row=row_idx, column=2).value),
                manufacturer=_sanitize_str(ws.cell(row=row_idx, column=3).value),
                brand_name=_sanitize_str(ws.cell(row=row_idx, column=4).value),
                model=_sanitize_str(ws.cell(row=row_idx, column=5).value),
                hs_code=hs_code,
                country_of_origin=_sanitize_str(ws.cell(row=row_idx, column=7).value),
                description=desc,
                quantity=_safe_float(ws.cell(row=row_idx, column=9).value, 1.0),
                qty_unit=_sanitize_str(ws.cell(row=row_idx, column=10).value) or "PCE",
                expiry_date=_sanitize_str(ws.cell(row=row_idx, column=11).value),
                unit_price=_safe_float(ws.cell(row=row_idx, column=12).value),
                unit_price_basis=_sanitize_str(ws.cell(row=row_idx, column=13).value) or "PCS",
                gross_weight_kg=_safe_float(ws.cell(row=row_idx, column=14).value),
                net_weight_kg=_safe_float(ws.cell(row=row_idx, column=15).value),
                total_amount=_safe_float(ws.cell(row=row_idx, column=16).value),
            )
            if item.total_amount == 0.0 and item.quantity > 0 and item.unit_price > 0:
                item.total_amount = round(item.quantity * item.unit_price, 2)
            items.append(item)
    else:
        for r in range(19, ws.max_row + 1):
            col1_val = str(ws.cell(row=r, column=1).value or "").strip()
            col6_hs = str(ws.cell(row=r, column=6).value or "").strip()
            col8_desc = str(ws.cell(row=r, column=8).value or "").strip()
            if "Subtotal" in str(ws.cell(row=r, column=15).value or "") or "Total" in str(ws.cell(row=r, column=15).value or ""):
                break
            if col6_hs or col8_desc:
                item = StandardInvoiceLineItem(
                    index=int(_safe_float(col1_val, len(items) + 1)),
                    product_code=_sanitize_str(ws.cell(row=r, column=2).value),
                    manufacturer=_sanitize_str(ws.cell(row=r, column=3).value),
                    brand_name=_sanitize_str(ws.cell(row=r, column=4).value),
                    model=_sanitize_str(ws.cell(row=r, column=5).value),
                    hs_code=col6_hs,
                    country_of_origin=_sanitize_str(ws.cell(row=r, column=7).value),
                    description=col8_desc,
                    quantity=_safe_float(ws.cell(row=r, column=9).value, 1.0),
                    qty_unit=_sanitize_str(ws.cell(row=r, column=10).value) or "PCE",
                    expiry_date=_sanitize_str(ws.cell(row=r, column=11).value),
                    unit_price=_safe_float(ws.cell(row=r, column=12).value),
                    unit_price_basis=_sanitize_str(ws.cell(row=r, column=13).value) or "PCS",
                    gross_weight_kg=_safe_float(ws.cell(row=r, column=14).value),
                    net_weight_kg=_safe_float(ws.cell(row=r, column=15).value),
                    total_amount=_safe_float(ws.cell(row=r, column=16).value),
                )
                if item.total_amount == 0.0:
                    item.total_amount = round(item.quantity * item.unit_price, 2)
                items.append(item)

    subtotal = sum(i.total_amount for i in items)
    total_amount = round(subtotal + freight_cost + insurance_cost + other_costs, 2)

    return StandardInvoicePayload(
        seller_name=seller_name,
        seller_address=seller_address,
        seller_city=seller_city,
        seller_country_code=seller_country_code,
        seller_tax_id=seller_tax_id,
        seller_contact_name=seller_contact_name,
        seller_phone=seller_phone,
        seller_fax=seller_fax,
        seller_email=seller_email,
        seller_website=seller_website,
        buyer_name=buyer_name,
        buyer_address=buyer_address,
        buyer_tax_id=buyer_tax_id,
        buyer_contact_name=buyer_contact_name,
        buyer_phone=buyer_phone,
        buyer_fax=buyer_fax,
        buyer_email=buyer_email,
        acid_number=acid_number,
        invoice_type=invoice_type,
        invoice_number=invoice_number,
        invoice_date=invoice_date,
        purchase_order_number=purchase_order_number,
        purchase_order_date=purchase_order_date,
        proforma_invoice_number=proforma_invoice_number,
        origin_port=origin_port,
        destination_port=destination_port,
        currency_code=currency_code,
        incoterm=incoterm,
        gross_weight=gross_weight,
        net_weight=net_weight,
        weight_unit=weight_unit,
        items=items,
        subtotal=subtotal,
        freight_cost=freight_cost,
        insurance_cost=insurance_cost,
        other_costs=other_costs,
        total_amount=total_amount,
    )


def compare_standard_invoice_data(
    import_file_id: int,
    import_file_code: str,
    system_snapshot: StandardInvoicePayload,
    supplier_data: StandardInvoicePayload,
) -> StandardInvoiceComparisonResponse:
    header_comparisons: List[StandardInvoiceComparisonRow] = []
    financial_comparisons: List[StandardInvoiceComparisonRow] = []
    line_item_comparisons: List[StandardInvoiceLineComparisonRow] = []

    critical_count = 0
    warning_count = 0

    sys_acid = _sanitize_str(system_snapshot.acid_number)
    sup_acid = _sanitize_str(supplier_data.acid_number)
    if sys_acid and sup_acid and sys_acid != sup_acid:
        status = "CRITICAL_MISMATCH"
        critical_count += 1
        diff = f"System: {sys_acid} vs Excel: {sup_acid}"
    elif not sup_acid:
        status = "CRITICAL_MISMATCH"
        critical_count += 1
        diff = "Missing in Excel"
    else:
        status = "MATCH"
        diff = None
    header_comparisons.append(
        StandardInvoiceComparisonRow(
            field_key="acid_number",
            field_label_ar="رقم القيد الجمركي المسبق (ACID #)",
            field_label_en="Egyptian ACID Number",
            system_value=sys_acid,
            supplier_value=sup_acid,
            status=status,
            difference=diff,
            notes="19-digit Egyptian Customs Reference",
        )
    )

    sys_exp_tax = _sanitize_str(system_snapshot.seller_tax_id)
    sup_exp_tax = _sanitize_str(supplier_data.seller_tax_id)
    sys_digits = re.sub(r"\D", "", sys_exp_tax)
    sup_digits = re.sub(r"\D", "", sup_exp_tax)
    if sys_digits and sup_digits and sys_digits != sup_digits:
        status = "CRITICAL_MISMATCH"
        critical_count += 1
        diff = f"{sys_exp_tax} != {sup_exp_tax}"
    else:
        status = "MATCH"
        diff = None
    header_comparisons.append(
        StandardInvoiceComparisonRow(
            field_key="seller_tax_id",
            field_label_ar="الرقم الضريبي / تسجيل المصدر (Seller Tax ID)",
            field_label_en="Seller Registration Code",
            system_value=sys_exp_tax,
            supplier_value=sup_exp_tax,
            status=status,
            difference=diff,
        )
    )

    sys_imp_tax = _sanitize_str(system_snapshot.buyer_tax_id)
    sup_imp_tax = _sanitize_str(supplier_data.buyer_tax_id)
    sys_imp_dig = re.sub(r"\D", "", sys_imp_tax)
    sup_imp_dig = re.sub(r"\D", "", sup_imp_tax)
    if sys_imp_dig and sup_imp_dig and sys_imp_dig != sup_imp_dig:
        status = "CRITICAL_MISMATCH"
        critical_count += 1
        diff = f"{sys_imp_tax} != {sup_imp_tax}"
    else:
        status = "MATCH"
        diff = None
    header_comparisons.append(
        StandardInvoiceComparisonRow(
            field_key="buyer_tax_id",
            field_label_ar="الرقم الضريبي للمستورد (Egypt Tax Code)",
            field_label_en="Buyer Egypt Tax Code",
            system_value=sys_imp_tax,
            supplier_value=sup_imp_tax,
            status=status,
            difference=diff,
        )
    )

    sys_curr = (system_snapshot.currency_code or "").upper().strip()
    sup_curr = (supplier_data.currency_code or "").upper().strip()
    if sys_curr and sup_curr and sys_curr != sup_curr:
        status = "CRITICAL_MISMATCH"
        critical_count += 1
        diff = f"Currency Mismatch ({sys_curr} vs {sup_curr})"
    else:
        status = "MATCH"
        diff = None
    header_comparisons.append(
        StandardInvoiceComparisonRow(
            field_key="currency_code",
            field_label_ar="عملة الفاتورة (Currency)",
            field_label_en="Invoice Currency Code",
            system_value=sys_curr,
            supplier_value=sup_curr,
            status=status,
            difference=diff,
        )
    )

    sys_inco = (system_snapshot.incoterm or "").upper().strip()
    sup_inco = (supplier_data.incoterm or "").upper().strip()
    if sys_inco and sup_inco and sys_inco != sup_inco:
        status = "WARNING"
        warning_count += 1
        diff = f"{sys_inco} vs {sup_inco}"
    else:
        status = "MATCH"
        diff = None
    header_comparisons.append(
        StandardInvoiceComparisonRow(
            field_key="incoterm",
            field_label_ar="شرط التسليم (Incoterm)",
            field_label_en="Delivery Incoterm",
            system_value=sys_inco,
            supplier_value=sup_inco,
            status=status,
            difference=diff,
        )
    )

    sys_pod = (system_snapshot.destination_port or "").strip().upper()
    sup_pod = (supplier_data.destination_port or "").strip().upper()
    if sys_pod and sup_pod and sys_pod not in sup_pod and sup_pod not in sys_pod:
        status = "WARNING"
        warning_count += 1
        diff = f"{sys_pod} vs {sup_pod}"
    else:
        status = "MATCH"
        diff = None
    header_comparisons.append(
        StandardInvoiceComparisonRow(
            field_key="destination_port",
            field_label_ar="ميناء الوصول (Destination Port)",
            field_label_en="Destination Port",
            system_value=sys_pod,
            supplier_value=sup_pod,
            status=status,
            difference=diff,
        )
    )

    sys_sub = round(system_snapshot.subtotal, 2)
    sup_sub = round(supplier_data.subtotal, 2)
    diff_val = round(abs(sys_sub - sup_sub), 2)
    if diff_val > 5.0:
        status = "CRITICAL_MISMATCH"
        critical_count += 1
        diff_str = f"Diff: {sup_sub - sys_sub:+.2f} {sys_curr}"
    elif diff_val > 0.01:
        status = "WARNING"
        warning_count += 1
        diff_str = f"Diff: {sup_sub - sys_sub:+.2f} {sys_curr}"
    else:
        status = "MATCH"
        diff_str = None
    financial_comparisons.append(
        StandardInvoiceComparisonRow(
            field_key="subtotal",
            field_label_ar="مجموع البنود (Invoice Subtotal)",
            field_label_en="Invoice Subtotal",
            system_value=f"{sys_sub:,.2f} {sys_curr}",
            supplier_value=f"{sup_sub:,.2f} {sup_curr}",
            status=status,
            difference=diff_str,
        )
    )

    sys_tot = round(system_snapshot.total_amount, 2)
    sup_tot = round(supplier_data.total_amount, 2)
    diff_tot = round(abs(sys_tot - sup_tot), 2)
    if diff_tot > 5.0:
        status = "CRITICAL_MISMATCH"
        critical_count += 1
        diff_str = f"Diff: {sup_tot - sys_tot:+.2f} {sys_curr}"
    elif diff_tot > 0.01:
        status = "WARNING"
        warning_count += 1
        diff_str = f"Diff: {sup_tot - sys_tot:+.2f} {sys_curr}"
    else:
        status = "MATCH"
        diff_str = None
    financial_comparisons.append(
        StandardInvoiceComparisonRow(
            field_key="total_amount",
            field_label_ar="الإجمالي النهائي (Total Amount)",
            field_label_en="Total Commercial Invoice Amount",
            system_value=f"{sys_tot:,.2f} {sys_curr}",
            supplier_value=f"{sup_tot:,.2f} {sup_curr}",
            status=status,
            difference=diff_str,
        )
    )

    sys_items = system_snapshot.items or []
    sup_items = supplier_data.items or []
    max_lines = max(len(sys_items), len(sup_items))

    for idx in range(max_lines):
        s_item = sys_items[idx] if idx < len(sys_items) else None
        u_item = sup_items[idx] if idx < len(sup_items) else None

        line_status = "MATCH"
        note_parts = []

        if s_item and u_item:
            s_hs = re.sub(r"\D", "", s_item.hs_code)
            u_hs = re.sub(r"\D", "", u_item.hs_code)
            if s_hs and u_hs and s_hs[:6] != u_hs[:6]:
                line_status = "CRITICAL_MISMATCH"
                critical_count += 1
                note_parts.append(f"HS Code Mismatch: {s_item.hs_code} vs {u_item.hs_code}")

            if abs(s_item.quantity - u_item.quantity) > 0.01:
                if line_status != "CRITICAL_MISMATCH":
                    line_status = "WARNING"
                warning_count += 1
                note_parts.append(f"Qty Diff: {u_item.quantity - s_item.quantity:+.2f}")

            if abs(s_item.unit_price - u_item.unit_price) > 0.01:
                if line_status != "CRITICAL_MISMATCH":
                    line_status = "WARNING"
                warning_count += 1
                note_parts.append(f"Price Diff: {u_item.unit_price - s_item.unit_price:+.2f}")

            line_item_comparisons.append(
                StandardInvoiceLineComparisonRow(
                    index=idx + 1,
                    product_code=u_item.product_code or s_item.product_code or f"LINE-{idx+1}",
                    hs_code_system=s_item.hs_code,
                    hs_code_supplier=u_item.hs_code,
                    description_system=s_item.description,
                    description_supplier=u_item.description,
                    qty_system=s_item.quantity,
                    qty_supplier=u_item.quantity,
                    unit_price_system=s_item.unit_price,
                    unit_price_supplier=u_item.unit_price,
                    total_system=s_item.total_amount,
                    total_supplier=u_item.total_amount,
                    gross_weight_system=s_item.gross_weight_kg,
                    gross_weight_supplier=u_item.gross_weight_kg,
                    status=line_status,
                    notes=", ".join(note_parts) if note_parts else "Perfect Match",
                )
            )
        elif u_item and not s_item:
            line_item_comparisons.append(
                StandardInvoiceLineComparisonRow(
                    index=idx + 1,
                    product_code=u_item.product_code or f"EXTRA-{idx+1}",
                    hs_code_system=None,
                    hs_code_supplier=u_item.hs_code,
                    description_system=None,
                    description_supplier=u_item.description,
                    qty_system=0.0,
                    qty_supplier=u_item.quantity,
                    unit_price_system=0.0,
                    unit_price_supplier=u_item.unit_price,
                    total_system=0.0,
                    total_supplier=u_item.total_amount,
                    gross_weight_system=0.0,
                    gross_weight_supplier=u_item.gross_weight_kg,
                    status="WARNING",
                    notes="Extra item in Supplier Excel not in PO",
                )
            )
            warning_count += 1
        elif s_item and not u_item:
            line_item_comparisons.append(
                StandardInvoiceLineComparisonRow(
                    index=idx + 1,
                    product_code=s_item.product_code or f"MISSING-{idx+1}",
                    hs_code_system=s_item.hs_code,
                    hs_code_supplier=None,
                    description_system=s_item.description,
                    description_supplier=None,
                    qty_system=s_item.quantity,
                    qty_supplier=0.0,
                    unit_price_system=s_item.unit_price,
                    unit_price_supplier=0.0,
                    total_system=s_item.total_amount,
                    total_supplier=0.0,
                    gross_weight_system=s_item.gross_weight_kg,
                    gross_weight_supplier=0.0,
                    status="CRITICAL_MISMATCH",
                    notes="Item from PO missing in Supplier Excel",
                )
            )
            critical_count += 1

    has_discrepancies = (critical_count > 0 or warning_count > 0)
    has_critical = critical_count > 0

    notice_en = None
    notice_ar = None
    if has_discrepancies:
        notice_en = (
            f"Dear {supplier_data.seller_name or 'Supplier'},\n\n"
            f"We reviewed the Standard Commercial Invoice Excel for Import File [{import_file_code}] (ACID: {sys_acid}).\n"
            f"Please amend the following discrepancies to comply with Egyptian Customs Nafeza requirements:\n"
        )
        notice_ar = (
            f"السادة / {supplier_data.seller_name or 'المورد الأجنبي'},\n\n"
            f"تحية طيبة وبعد، بخصوص مراجعة الفاتورة التجارية المعيارية للملف [{import_file_code}] (رقم ACID: {sys_acid}):\n"
            f"يرجى تصحيح الفروق التالية لتتوافق مع متطلبات مصلحة الجمارك المصرية ومنظومة نافذة:\n"
        )
        for h in header_comparisons:
            if h.status != "MATCH":
                notice_en += f"- {h.field_label_en}: Expected '{h.system_value}' but found '{h.supplier_value}'.\n"
                notice_ar += f"- {h.field_label_ar}: المتوقع '{h.system_value}' والمسجل بالفاتورة '{h.supplier_value}'.\n"
        for l in line_item_comparisons:
            if l.status != "MATCH":
                notice_en += f"- Item #{l.index} [{l.product_code}]: {l.notes}.\n"
                notice_ar += f"- البند #{l.index} [{l.product_code}]: {l.notes}.\n"
        notice_en += "\nThank you for your prompt cooperation.\nImport Documentation Team"
        notice_ar += "\nشاكرين حسن تعاونكم الدائم.\nإدارة التوثيق والاستيراد"

    return StandardInvoiceComparisonResponse(
        import_file_id=import_file_id,
        import_file_code=import_file_code,
        acid_number=sys_acid or sup_acid,
        has_discrepancies=has_discrepancies,
        has_critical_mismatch=has_critical,
        total_discrepancies_count=critical_count + warning_count,
        critical_mismatches_count=critical_count,
        warnings_count=warning_count,
        header_comparisons=header_comparisons,
        financial_comparisons=financial_comparisons,
        line_item_comparisons=line_item_comparisons,
        system_snapshot=system_snapshot,
        supplier_data=supplier_data,
        rectification_notice_en=notice_en,
        rectification_notice_ar=notice_ar,
    )
