import pytest
from unittest.mock import MagicMock
from modules.smart_document_upload.extractors.purchase_order import PurchaseOrderExtractor
from modules.purchase_orders.service import PurchaseOrderService
from modules.purchase_orders.model import PurchaseOrder, PackingListItem

def test_high_precision_weight_extraction():
    sample_text = 'TOTAL: 144 CTNS 720 PCS 10510 KGS 10080 KGS 66 CBM'
    extractor = PurchaseOrderExtractor()
    items = extractor._extract_packing_list_items(sample_text)
    assert len(items) == 1
    item = items[0]
    assert item['gross_weight_unit_kg'] == 10510.0 / 144.0
    assert item['gross_weight_unit_kg'] != 72.99
    assert abs(item['gross_weight_unit_kg'] - 72.98611111111111) < 1e-10
    assert item['total_gross_weight_kg'] == 10510.0
    assert item['qty_pkg'] == 144.0
    assert item['qty_pcs'] == 720.0

def test_high_precision_weight_calculation_service():
    mock_repo = MagicMock()
    mock_db = MagicMock()
    service = PurchaseOrderService(mock_db)
    service.repo = mock_repo
    
    mock_po = MagicMock(spec=PurchaseOrder)
    mock_po.line_items = []
    
    mock_item = MagicMock(spec=PackingListItem)
    mock_item.item_code = 'ACOUSTIC-01'
    mock_item.qty_pcs = 720.0
    mock_item.qty_pkg = 144.0
    mock_item.net_weight_unit_kg = 70.0
    mock_item.gross_weight_unit_kg = 72.98611111111111
    mock_item.total_gross_weight_kg = 0.0  # Will be auto calculated as 144 * 72.98611111111111
    mock_item.total_net_weight_kg = 0.0    # Will be auto calculated as 144 * 70
    mock_item.length_cm = 284.0
    mock_item.width_cm = 122.0
    mock_item.height_cm = 2.4
    mock_item.total_cbm = 66.0
    mock_item.chargeable_weight_kg = 0.0
    mock_item.hs_code = '39219000'
    
    mock_po.packing_list_items = [mock_item]
    mock_repo.get_by_id.return_value = mock_po
    
    report = service.get_packing_list_report(1)
    assert abs(report.total_gross_weight_kg - 10510.0) < 1e-6
    assert abs(report.total_net_weight_kg - 10080.0) < 1e-6
