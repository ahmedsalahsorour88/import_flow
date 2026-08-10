import os
import sys
from datetime import date
from decimal import Decimal

sys.path.insert(0, os.path.abspath("."))
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

from database.database import SessionLocal, engine, Base
from modules.customs_tariff.model import CustomsTariff, PreferentialAgreement

Base.metadata.create_all(bind=engine)

def seed_3925900090():
    db = SessionLocal()
    try:
        hs_code = "3925900090"
        print(f"🌱 Seeding HS Code {hs_code} & Nafeza Agreements...")

        # 1. Check or update CustomsTariff
        tariff = db.query(CustomsTariff).filter(CustomsTariff.hs_code == hs_code).first()
        if not tariff:
            tariff = CustomsTariff(
                hs_code=hs_code,
                hs_description="أصناف أخر لتجهيزات البناء من لدائن ، غير مذكورة أو داخلة في مكان أخر .",
                customs_category="بلاستيك ولدائن وتجهيزات بناء",
                customs_duty_rate=Decimal("40.00"),
                vat_rate=Decimal("14.00"),
                schedule_tax_rate=Decimal("0.00"),
                development_fee_rate=Decimal("0.00"),
                import_fee_rate=Decimal("0.00"),
                customs_service_fee_rate=Decimal("1.00"),
                requires_coo=True,
                requires_inspection=True,
                requires_acid=True,
                regulatory_authority="الهيئة العامة للرقابة على الصادرات والواردات (GOEIC)",
                prior_approval_note="ر6722 - اتفاقية صربيا تخفيض 10% | ر6668 - تخفض ض .ج ورسوم بنسبة100%علىسلع صناعيةواردةفى ظل اتفاقية الشراكةالمصرية والمملكة المتحدة | ر6706 - تحصل ض. وارد طبقا للفئات الموضحة قرين كل بند على سلع واردة فى إطار إتفاقيةالميركسور | ر6631 - يعفى من الضريبة الجمركية والرسوم ذات الاثر المماثل الأصناف الواردة من دول الافتا بنسبة100% | ر6607 - تخفض الرسوم الجمركية فى ظل اتفاقيةتركيا بنسبة100% على اصناف واردةبالقائمة 1 برتوكول 1 | ر6663 - تخفض ضريبةجمركيةورسوم ذات أثر مماثل بنسبة 100% علىسلع صناعيةواردةفى ظل شراكةأوربيةملحق2",
                source_url=f"https://www.nafeza.gov.eg/ar/tarrif?code={hs_code}",
                notes="بند معتمد منصة نافذة مع تفاصيل الاتفاقيات التفضيلية الإلزامية",
                is_active=True,
                effective_from=date(2026, 1, 1),
            )
            db.add(tariff)
        else:
            tariff.hs_description = "أصناف أخر لتجهيزات البناء من لدائن ، غير مذكورة أو داخلة في مكان أخر ."
            tariff.customs_duty_rate = Decimal("40.00")
            tariff.vat_rate = Decimal("14.00")
            tariff.schedule_tax_rate = Decimal("0.00")
            tariff.is_active = True
            tariff.prior_approval_note = "ر6722 - اتفاقية صربيا تخفيض 10% | ر6668 - تخفض ض .ج ورسوم بنسبة100%علىسلع صناعيةواردةفى ظل اتفاقية الشراكةالمصرية والمملكة المتحدة | ر6706 - تحصل ض. وارد طبقا للفئات الموضحة قرين كل بند على سلع واردة فى إطار إتفاقيةالميركسور | ر6631 - يعفى من الضريبة الجمركية والرسوم ذات الاثر المماثل الأصناف الواردة من دول الافتا بنسبة100% | ر6607 - تخفض الرسوم الجمركية فى ظل اتفاقيةتركيا بنسبة100% على اصناف واردةبالقائمة 1 برتوكول 1 | ر6663 - تخفض ضريبةجمركيةورسوم ذات أثر مماثل بنسبة 100% علىسلع صناعيةواردةفى ظل شراكةأوربيةملحق2"

        db.commit()
        db.refresh(tariff)

        # 2. Seed the 6 Nafeza Preferential Agreements for this HS Code
        agreements = [
            {
                "agreement_name": "ر6706 - تحصل ض. وارد طبقا للفئات الموضحة قرين كل بند على سلع واردة فى إطار إتفاقيةالميركسور (ضريبة وارد 3%)",
                "origin_countries": "BR,AR,UY,PY",
                "reduction_type": "fixed_rate",
                "reduction_percentage": Decimal("0.925"),
                "conditions_note": "شروط الإعفاء والتطبيق: شهادة منشأ ميركوسور معتمدة + إقرار جمركي مطبق فيه كود البند ر6706 (يجب طلب شهادة المنشأ المعتمدة من المورد الخارجي قبل الشحن)",
            },
            {
                "agreement_name": "ر6722 - اتفاقية صربيا تخفيض 10%",
                "origin_countries": "RS",
                "reduction_type": "percentage_of_duty",
                "reduction_percentage": Decimal("0.10"),
                "conditions_note": "شروط الإعفاء والتطبيق: شهادة منشأ صربية معتمدة رقم ر6722 (يجب طلب شهادة المنشأ المعتمدة من المورد الخارجي)",
            },
            {
                "agreement_name": "ر6668 - تخفض ض .ج ورسوم بنسبة100%علىسلع صناعيةواردةفى ظل اتفاقية الشراكةالمصرية والمملكة المتحدة",
                "origin_countries": "GB",
                "reduction_type": "full_duty_exemption",
                "reduction_percentage": Decimal("1.00"),
                "conditions_note": "شروط الإعفاء والتطبيق: شهادة EUR.1 أو يوروميد المملكة المتحدة ر6668 (يجب التزام المورد بتصدير الشحنة مباشرة ومرفق الشهادة الأصلي)",
            },
            {
                "agreement_name": "ر6631 - يعفى من الضريبة الجمركية والرسوم ذات الاثر المماثل الأصناف الواردة من دول الافتا بنسبة100%",
                "origin_countries": "CH,NO,IS,LI",
                "reduction_type": "full_duty_exemption",
                "reduction_percentage": Decimal("1.00"),
                "conditions_note": "شروط الإعفاء والتطبيق: شهادة حركة EUR.1 إفتا ر6631 (يجب طلبها معتمدة رسمياً من المورد السويسري/النرويجي)",
            },
            {
                "agreement_name": "ر6607 - تخفض الرسوم الجمركية فى ظل اتفاقيةتركيا بنسبة100% على اصناف واردةبالقائمة 1 برتوكول 1",
                "origin_countries": "TR",
                "reduction_type": "full_duty_exemption",
                "reduction_percentage": Decimal("1.00"),
                "conditions_note": "شروط الإعفاء والتطبيق: شهادة حركة EUR.1 تركيا ر6607 قائمة 1 بروتوكول 1 (تخفيض 100% - يجب طلب EUR.1 أصلي من المورد التركي)",
            },
            {
                "agreement_name": "ر6663 - تخفض ضريبةجمركيةورسوم ذات أثر مماثل بنسبة 100% علىسلع صناعيةواردةفى ظل شراكةأوربيةملحق2",
                "origin_countries": "IT,DE,FR,ES,NL,BE,AT,SE,PL,CZ,DK,FI,GR,IE,PT",
                "reduction_type": "full_duty_exemption",
                "reduction_percentage": Decimal("1.00"),
                "conditions_note": "شروط الإعفاء والتطبيق: شهادة EUR.1 أو تصريح مصدّر معتمد على الفاتورة ر6663 ملحق 2 (تخفيض 100% - يرجى طلب شهادة المنشأ الأوروبية أصلي)",
            },
        ]

        for ag in agreements:
            existing = db.query(PreferentialAgreement).filter(
                PreferentialAgreement.hs_code == tariff.hs_code,
                PreferentialAgreement.agreement_name == ag["agreement_name"]
            ).first()
            if not existing:
                db.add(PreferentialAgreement(
                    hs_code=tariff.hs_code,
                    **ag
                ))
            else:
                existing.conditions_note = ag["conditions_note"]
                existing.origin_countries = ag["origin_countries"]
                existing.reduction_percentage = ag["reduction_percentage"]

        db.commit()
        print("✅ Successfully seeded 3925900090 & 6 Nafeza Trade Agreements.")

    except Exception as e:
        db.rollback()
        print(f"❌ Error seeding 3925900090: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    seed_3925900090()
