import pytest
from modules.smart_document_upload.extractors.customs_broker_quotation import CustomsBrokerQuotationExtractor

def test_customs_broker_quotation_extractor_accuracy():
    extractor = CustomsBrokerQuotationExtractor()
    quote_text = '\n    شركة الأهرام للخدمات الجمركية\n    عرض أسعار ومقايسة تخليص جمركي\n    ميناء الوصول: ميناء الإسكندرية البحري\n    الحاوية: 40HQ\n    \n    أتعاب التخليص الجمركي: 3500 ج.م\n    نولون النقل الداخلي: 19500 ج.م\n    مصاريف الفحص والمعاينة واللجان: 2800 ج.م\n    مصاريف وعوائد الميناء والتفريغ: 8000 ج.م\n    رسوم كشف وكلارك وتعتيق: 1200 ج.م\n    \n    إجمالي المقايسة التقديرية: 35000 ج.م\n    '
    
    result = extractor.extract(quote_text, {})
    
    assert 'الأهرام' in result['broker_name']
    assert 'Alexandria' in result['port_name']
    assert result['clearance_fee'] == 3500.0
    assert result['inland_transport_fee'] == 19500.0
    assert result['inspection_fee'] == 2800.0
    assert result['port_expenses'] == 8000.0
    assert result['total_estimated_clearance_cost'] == 35000.0
    
    catalog = result.get('expenses_catalog', [])
    assert len(catalog) >= 5
    names = [item['expense_name'] for item in catalog]
    assert any('كشف وكلارك وتعتيق' in n for n in names)

def test_customs_broker_quotation_no_hardcoded_overwrite():
    extractor = CustomsBrokerQuotationExtractor()
    quote_text = '\n    مكتب النور للتخليص الجمركي\n    مقايسة حاوية 20ft\n    أتعاب التخليص: 4200 جنيه\n    النقل: 11000 جنيه\n    إكراميات وتعتيق: 850 جنيه\n    رسوم موازين: 350 جنيه\n    الإجمالي: 16400 جنيه\n    '
    
    result = extractor.extract(quote_text, {})
    
    assert 'النور' in result['broker_name']
    assert result['clearance_fee'] == 4200.0
    assert result['inland_transport_fee'] == 11000.0
    assert result['total_estimated_clearance_cost'] == 16400.0
    
    catalog = result.get('expenses_catalog', [])
    names = [c['expense_name'] for c in catalog]
    assert any('إكراميات وتعتيق' in n for n in names)
    assert any('رسوم موازين' in n for n in names)

def test_customs_broker_quotation_english_and_currency_symbols():
    extractor = CustomsBrokerQuotationExtractor()
    quote_text = '\n    Alexandria Customs Clearance Agency\n    Quotation for Port: Sokhna Port\n    Clearance Fee: EGP 5000\n    Inland Transport: EGP 14500\n    Port Handling: EGP 6200\n    Inspection: EGP 1800\n    Storage & Demurrage Coverage: EGP 3000\n    Total Cost: EGP 30500\n    '
    
    result = extractor.extract(quote_text, {})
    
    assert result['clearance_fee'] == 5000.0
    assert result['inland_transport_fee'] == 14500.0
    assert result['port_expenses'] == 6200.0
    assert result['inspection_fee'] == 1800.0
    assert result['total_estimated_clearance_cost'] == 30500.0
    
    catalog = result.get('expenses_catalog', [])
    names = [c['expense_name'] for c in catalog]
    assert any('Storage & Demurrage' in n for n in names)


def test_customs_broker_quotation_full_acc_extraction():
    extractor = CustomsBrokerQuotationExtractor()
    quote_text = """
    شركة اسكندرية للأعمال الجمركية (ACC)
    شريف سقسلي
    عرض أسعار ومقايسة تخليص جمركي
    التاريخ: 2026/04/01
    ميناء الإسكندرية والدخيلة

    LCL
    EGP 1,250.00 اتعاب تخليص ( فاتوره)
    EGP 4,750.00 مصاريف تخليص واحد طن
    EGP 1,000.00 مصاريف تخليص كل طن زيادة

    20FT
    EGP 2,500.00 اتعاب تخليص ( فاتوره)
    EGP 7,500.00 مصاريف تخليص ١ حاوية
    EGP 1,500.00 كل حاوية زيادة

    40FT
    EGP 2,500.00 اتعاب تخليص ( فاتوره)
    EGP 7,500.00 مصاريف تخليص ١ حاوية
    EGP 2,000.00 كل حاوية زيادة

    تكاليف اخري : (اجراءات تخليص)
    EGP 1,000.00 ACID تسجيل الشحنة الجمركي المبدئي
    EGP 250.00 - 250.00 بريد - دمغات
    EGP 2,500.00 - 3,500.00 عرض الواردات + اعتماد الايباك
    EGP 5,000.00 عرض امن عام القاهره
    EGP 500.00 - 1,000.00 - 1,500.00 امن عام ( اسكندرية - كفر الشيخ - البحيرة )
    EGP 500.00 وثيقة تامين
    EGP 250.00 عرض اكس راي
    EGP 1,000.00 تطبيق اتفاقيات
    EGP 350.00 الافراج تحت التحفظ
    EGP 250.00 سيل الجمرك والترصيص
    EGP 3,000.00 مطافي ومفرقعات ودمغة موازين
    EGP 3,000.00 افراج نهائي واشعاع وكيمياء
    EGP 750.00 ( 250 / 250 / 250 ) سحب اذن تسليم وتصوير ومنافستو
    EGP 300.00 توكيل
    EGP 1,500.00 تفريغ
    EGP 500.00 فحص كيمياء
    EGP 500.00 فحص اشعاع
    EGP 1,000.00 لجنة فحص خارجي
    EGP 350.00 منافستو
    EGP 250.00 تصوير مستندات
    EGP 500.00 اكراميات ولجان

    النقل من الإسكندرية للقاهرة
    EGP 6,150.00 نقل سيارة 1 طن دبابة للقاهرة
    EGP 8,200.00 نقل سيارة جامبو حتى 4 طن للقاهرة
    EGP 14,150.00 نقل سيارة فرداني حتى 7 طن للقاهرة
    EGP 14,800.00 نقل حاوية 20 قدم وزن اقل من 10 طن للقاهرة
    EGP 16,500.00 نقل حاوية 20 قدم وزن اكبر من 10 طن للقاهرة
    EGP 18,400.00 نقل حاوية 20*2 للقاهرة
    EGP 18,400.00 نقل حاوية 40 قدم للقاهرة

    بياتة الحاويات
    EGP 3,600.00 بياتة شاحنة 20*2
    EGP 3,600.00 بياتة شاحنة 40*1
    EGP 3,000.00 بياتة شاحنة 20*1

    مصاريف الميناء والتعامل
    EGP 1,000.00 كارتة ابوقير
    EGP 3,500.00 تعتيق ونقل وزن داخل الميناء ( قماش )
    """

    result = extractor.extract(quote_text, {})

    assert result['clearance_fee'] == 2500.0
    assert result['inland_transport_fee'] == 18400.0
    assert result['port_expenses'] == 7500.0
    assert result['inspection_fee'] == 2500.0

    catalog = result.get('expenses_catalog', [])
    assert len(catalog) >= 35

    names = [c['expense_name'] for c in catalog]
    # Check LCL fees
    assert any('LCL' in n and 'فاتورة' in n for n in names)
    assert any('LCL' in n and 'واحد طن' in n for n in names)
    # Check 20FT & 40FT fees
    assert any('20' in n and 'أول حاوية' in n for n in names)
    assert any('40' in n and 'أول حاوية' in n for n in names)
    # Check Procedures
    assert any('ACID' in n for n in names)
    assert any('بريد' in n for n in names)
    assert any('الواردات' in n for n in names)
    # Check Transport
    assert any('دبابة' in n for n in names)
    assert any('جامبو' in n for n in names)
    assert any('فرداني' in n for n in names)
    assert any('بياتة' in n for n in names)
    assert any('أبوقير' in n for n in names)

