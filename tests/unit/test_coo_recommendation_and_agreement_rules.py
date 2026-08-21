import pytest
from modules.import_documentation.service import classify_coo_certificate_type, _normalize_str, _fuzzy_match


def test_coo_recommendation_eu_countries():
    for country in ["Italy", "Lithuania", "Germany", "France", "Spain", "Austria", "Poland", "إيطاليا", "ألمانيا"]:
        res = classify_coo_certificate_type(country)
        assert res["recommended_type"] == "EUR.1"
        assert res["is_manual_choice_required"] is False
        assert "EUR.1" in res["allowed_types"]


def test_coo_recommendation_china():
    for country in ["China", "PRC", "People's Republic of China", "CN", "الصين"]:
        res = classify_coo_certificate_type(country)
        assert res["recommended_type"] == "China Certificate of Origin (CCPIT)"
        assert res["is_manual_choice_required"] is False


def test_coo_recommendation_dual_agadir_gafta():
    for country in ["Jordan", "Tunisia", "Morocco", "Palestine", "Lebanon", "Egypt", "الأردن", "المغرب"]:
        res = classify_coo_certificate_type(country)
        assert res["recommended_type"] is None
        assert res["is_manual_choice_required"] is True
        assert set(res["allowed_types"]) == {"Agadir Agreement", "GAFTA"}


def test_coo_recommendation_gafta_only():
    for country in ["Saudi Arabia", "United Arab Emirates", "Kuwait", "Oman", "Qatar", "Bahrain", "Algeria", "Iraq", "Libya", "Sudan", "Syria", "Yemen", "السعودية", "الإمارات"]:
        res = classify_coo_certificate_type(country)
        assert res["recommended_type"] == "GAFTA"
        assert res["is_manual_choice_required"] is False


def test_coo_recommendation_arab_league_non_agadir_gafta():
    for country in ["Mauritania", "Somalia", "Djibouti", "Comoros", "موريتانيا", "جيبوتي"]:
        res = classify_coo_certificate_type(country)
        assert res["recommended_type"] == "Form A / GSP"
        assert res["is_manual_choice_required"] is False


def test_coo_recommendation_unclassified_general():
    for country in ["USA", "Japan", "South Korea", "India", "Turkey", "Brazil"]:
        res = classify_coo_certificate_type(country)
        assert res["recommended_type"] is None
        assert res["is_manual_choice_required"] is True
        assert len(res["allowed_types"]) >= 5


def test_exporter_reg_id_normalization_and_matching():
    # Exporter company name with or without registration/VAT ID prefix should match seamlessly
    sys_name = "G.I. Industrial Holding S.p.A."
    draft_names = [
        "01982510305, G.I. Industrial Holding S.p.A.",
        "IT01982510305, G.I. Industrial Holding S.p.A.",
        "G.I. Industrial Holding S.p.A.",
    ]
    for dn in draft_names:
        matched, ratio = _fuzzy_match(sys_name, dn)
        assert matched is True
        assert ratio >= 0.95

    narbutas_sys = "UAB NARBUTAS INTERNATIONAL"
    narbutas_draft = "LT300591314, UAB NARBUTAS INTERNATIONAL"
    matched, ratio = _fuzzy_match(narbutas_sys, narbutas_draft)
    assert matched is True
    assert ratio >= 0.95
