from modules.customs_tariff.nafeza_text_parser import parse_nafeza_tariff_text

sample_text = """رقم البند :
8415820010
نص البند :
آلات وأجهزة تكييف أخر متضمنة وحدة تبريد ، وحدات كاملة .
الضرائب :
ضريبة الوارد :
60.000 %
ضريبة الجدول :
8.000 %
ضريبة قيمه مضافه :
14.000 %
المستندات والأعمال :
ر6722 - اتفاقية صربيا تخفيض 10%

ق4518 - لايصرح باستيراد صنف الا بموافقة مختومة بخاتم شعارجمهوريةمن هـ .ع.ص.وطبقا لملحق8 وتعديلاته

ر6668 - تخفض ض .ج ورسوم بنسبة100%علىسلع صناعيةواردةفى ظل اتفاقية الشراكةالمصرية والمملكة المتحدة

ق9994 - لايفرج عن صنف بضاعة مرشدةللمنطقة الحرة الابحصص لكل مستورد يحددهاجهاز تنفيذى للمنطقةالحرة

ر6704 - فى ظل اتفاق التجارة الحرة بين ج م ع وتجمع الميركسور تخفض الضريبة الجمركية - قائمة هـ

ر7042 - يحصل ضريبة قيمة مضافة بمقدار14% [عام]

ر6607 - تخفض الرسوم الجمركية فى ظل اتفاقيةتركيا بنسبة100% على اصناف واردةبالقائمة 1 برتوكول 1

ر6631 - يعفى من الضريبة الجمركية والرسوم ذات الاثر المماثل الأصناف الواردة من دول الافتا بنسبة100%

ق4547 - يشترط للافراج عن الصنف وارد اتجار أن يكون انتاج مصانع مسجلة من شركات مالكة للعلامة

ق4538 - عدامايرداستخدام خاص وشخصى يشترط للافراج عن الصنف أن يكون من أحد منتجين بـ هـ.ع.ص.و

ر6663 - تخفض ضريبةجمركيةورسوم ذات أثر مماثل بنسبة 100% علىسلع صناعيةواردةفى ظل شراكةأوربيةملحق2

ق4010 - لا يتم استيراد المواد المستنفذه لطبقه الاوزون الابموافقة مسبقة من شئون البيئة

ر6501 - تحصل ضريبة الوارد 20% على ما تستورده المنشآت الفندقيةوالسياحية أو ضريبة الوارد أيهما أقل.

ق9023 - الصنف مخصص للاستعمال كقطع غيار اولـــوازم للسيـــارات اضافة 333-بورسعيد-
"""

tariff, agreements = parse_nafeza_tariff_text(sample_text)

print("=== PARSED TARIFF ===")
print("HS Code:", tariff.hs_code)
print("Description:", tariff.hs_description)
print("Duty Rate:", tariff.customs_duty_rate)
print("VAT Rate:", tariff.vat_rate)
print("Schedule Tax:", tariff.schedule_tax_rate)
print("Requires Inspection:", tariff.requires_inspection)
print("Regulatory Authority:", tariff.regulatory_authority)
print("Prior Approvals:\n", tariff.prior_approval_note)

print("\n=== PARSED AGREEMENTS ===")
print("Total Agreements:", len(agreements))
for ag in agreements:
    print(f"- {ag.publication_notice}: {ag.agreement_name} -> Duty: {ag.preferential_duty_rate}% (Countries: {ag.origin_countries})")
