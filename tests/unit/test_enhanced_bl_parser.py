import pytest
from modules.import_documentation.ai_document_parser import (
    extract_draft_bl_with_ai,
    _heuristic_multi_carrier_extractor,
    clean_bl_boilerplate,
    extract_spatial_pdf_text_and_boxes,
)


MSC_SAMPLE_RAW_OCR = """
 0 Zero
PORT OF DISCHARGE AGENT:
Mediterranean Shipping Co. (Misr Maritime 
Agency)55, Sultan Hussein Street
P.O. Box 670
Alexandria Old Port
Phone : +20 3 488 4000
Fax : +20 3 488 4001
"Port-To-Port" or "Combined 
Transport"(see Clause 1) 
SHAW EUROPE LTD
BUILDING E
BLACKADDIE RD SANQUHAR
DG4 6DB. UNITED KINGDOM
SHIPPER: 
NO. OF RIDER PAGES
 Lloyds/IMO Number: 9720196
CARRIER'S AGENTS ENDORSEMENTS: (Include Agent(s) at POD)
ARCHI Brands for Corpet and Floor Trading
St.81 with st.18 building 44, 3rd floor
SARAYAT EL MAADI, Cairo- Egypt
CONSIGNEE: This B/L is not negotiable unless marked "To Order" or "To Order of ..." here.
NOTIFY PARTIES : (No responsibility shall attach to Carrier or to his Agent for failure to notify - see 
Clause 20)
ARCHI Brands for Corpet and Floor Trading
St.81 with st.18 building 44, 3rd floor
SARAYAT EL MAADI, Cairo- Egypt
VESSEL AND VOYAGE NO (see Clause 8 & 9)
Sanquhar
PLACE OF RECEIPT: (Combined Transport ONLY - see Clause 1 & 5.2)
PORT OF DISCHARGE PLACE OF DELIVERY : (Combined Transport ONLY - see Clause 1 & 5.2)
London Gateway Port
PORT OF LOADING
BOOKING REF. (or) SHIPPER'S REF. 
P A R T I C U L A R S F U R N I S H E D B Y T H E S H I P P E R - N O T C H E C K E D B Y C A R R I E R - C A R R I E R N O T R E S P O N S I B L E (see Clause 14)
Container Numbers, Seal
Numbers and Marks
Description of Packages and Goods
(Continued on attached Bill of Lading Rider pages(s), if applicable)
 Gross Cargo 
Weight
Measurement
DRAFT
VAT No: 759-552-827
VAT No: 759-552-827
MSC GISELLE - NL630A
EBKG18064984
MEDURE910647
SCAC Code: MEDU
MEDITERRANEAN SHIPPING COMPANY S.A.
Website: www.msc.com
BILL OF LADING No. 
XXXXXXXXXXXXXXXX Alexandria El Dekheila, EGYPT XXXXXXXXXXXXXXXX
This carriage is subject to the MSC Sea Waybill or Bill of Lading Terms and Conditions found at the back of this document, as 
well as to the MSC Agency Terms and Conditions available at www.msc.com/en/carrier-terms which are incorporated by reference.
SHIPPER'S LOAD, STOW AND COUNT;FCL/FCL;SAID TO CONTAIN
31 Pallet(s) 1 X 40' HIGH CUBE CONTAINING
31 PALLETS OF FLOORING
ACID: 7595528271019210013
EGYPTIAN IMPORTER TAX ID: 759552827
SHIPPER REGISTRATION TYPE: VAT NUMBER
SHIPPER ID: GB428102677
SHIPPER COUNTRY: UNITED KINGDOM
SHIPPER COUNTRY CODE: GB
FREIGHT PREPAID
Seal Number:
40' HIGH CUBE
BEAU5851356 20,030.000 kgs.
177345
Tare Weight: 3,700 kgs.
Marks and Numbers: N/A
Carrier has no liability or responsibility whatsoever for thermal loss or 
damage to the goods by reason of natural variations in atmospheric 
temperatures during the winter period, and / or caused by inadequate packing 
of the Goods for carriage in dry-van containers, and / or inherent vice of the 
Goods, in such temperatures.
Total Items: 31 Total : 20,030.000 kgs.
Freight Prepaid
"""


def test_msc_bl_heuristic_extraction():
    """Verify that multi-carrier heuristic extractor cleanly parses the MSC B/L sample without boilerplate noise."""
    res = _heuristic_multi_carrier_extractor(MSC_SAMPLE_RAW_OCR)

    # 1. ACID & Tax IDs
    assert res.get("acid_number") == "7595528271019210013"
    assert res.get("importer_tax_id") == "759552827"
    assert res.get("shipper_reg_id") == "GB428102677"
    assert res.get("shipper_country_code") == "GB"

    # 2. B/L No and Booking
    assert res.get("draft_bl_number") == "MEDURE910647"
    assert res.get("booking_no") == "EBKG18064984"

    # 3. Shipper Extraction (must contain Shaw Europe and not IMO or Rider pages)
    shipper = res.get("shipper", "")
    assert "SHAW EUROPE" in shipper
    assert "9720196" not in shipper
    assert "RIDER" not in shipper

    # 4. Consignee Extraction (must contain ARCHI Brands and NOT 'This B/L is not negotiable')
    consignee = res.get("consignee", "")
    assert "ARCHI Brands" in consignee or "Corpet" in consignee
    assert "not negotiable" not in consignee.lower()

    # 5. Vessel, Voyage & Ports
    assert "MSC GISELLE" in res.get("vessel_name", "")
    assert res.get("voyage_number") == "NL630A"
    assert "London Gateway" in res.get("pol", "")
    assert "Alexandria" in res.get("pod", "")

    # 6. Gross Weight & Containers
    assert res.get("total_gross_weight_kg") == 20030.0
    containers = res.get("containers", [])
    assert len(containers) >= 1
    c1 = containers[0]
    assert c1["container_no"] == "BEAU5851356"
    assert c1["seal_no"] == "177345"
    assert c1["gross_weight_kg"] == 20030.0


def test_clean_bl_boilerplate():
    """Verify that boilerplate cleaner removes legal clauses."""
    sample = 'CONSIGNEE: This B/L is not negotiable unless marked "To Order" or "To Order of ..." here. ARCHI BRANDS'
    cleaned = clean_bl_boilerplate(sample)
    assert "not negotiable" not in cleaned.lower()
    assert "ARCHI BRANDS" in cleaned


def test_extract_draft_bl_with_ai_fallback():
    """Verify end-to-end extract_draft_bl_with_ai returns valid guardrails and data."""
    res = extract_draft_bl_with_ai(MSC_SAMPLE_RAW_OCR)
    assert res.get("draft_bl_number") == "MEDURE910647"
    assert res.get("total_gross_weight_kg") == 20030.0
    assert "_guardrails" in res
    assert res["_guardrails"]["extraction_status"] == "EXTRACTION_COMPLETE"
