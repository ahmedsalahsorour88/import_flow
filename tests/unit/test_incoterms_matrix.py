import unittest
from pathlib import Path
from modules.incoterms.incoterms_matrix import (
    IncotermsMatrix,
    Party,
    TransportMode,
    CostCategory,
    Incoterm,
)


class TestIncotermsMatrix(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        cls.matrix = IncotermsMatrix.from_json_file("incoterms_data.json")

    def test_load_all_11_incoterms(self):
        terms = self.matrix.list_terms()
        self.assertEqual(len(terms), 11)
        expected = ["EXW", "FCA", "FAS", "FOB", "CFR", "CIF", "CPT", "CIP", "DAP", "DPU", "DDP"]
        for code in expected:
            self.assertIn(code, terms)

    def test_load_all_17_cost_categories(self):
        categories = self.matrix.list_categories()
        self.assertEqual(len(categories), 17)
        keys = [c.key for c in categories]
        self.assertIn("trucking_origin", keys)
        self.assertIn("ocean_freight", keys)
        self.assertIn("dthc", keys)
        self.assertIn("customs_duty_tax", keys)
        self.assertIn("demurrage_detention", keys)

    def test_contractual_categories_count(self):
        contractual = [c for c in self.matrix.list_categories(icc_defined_only=False) if not c.is_icc_defined]
        self.assertEqual(len(contractual), 6)
        contractual_keys = {c.key for c in contractual}
        expected_keys = {
            "disclaim_letter",
            "port_congestion",
            "demurrage_detention",
            "compliance_fees",
            "form_4_lc",
            "storage_warehousing",
        }
        self.assertEqual(contractual_keys, expected_keys)

    def test_icc_defined_only_filter(self):
        icc_only = self.matrix.list_categories(icc_defined_only=True)
        self.assertEqual(len(icc_only), 11)
        for c in icc_only:
            self.assertTrue(c.is_icc_defined)

    def test_exw_responsibilities(self):
        """Under EXW, Buyer pays for all 17 categories."""
        for cat in self.matrix.list_categories():
            self.assertEqual(
                self.matrix.who_pays("EXW", cat.key),
                Party.BUYER,
                f"Under EXW, {cat.key} should be paid by BUYER"
            )

    def test_fob_responsibilities(self):
        """Under FOB, Seller pays origin trucking, export clearance, and OTHC. Buyer pays ocean freight."""
        self.assertEqual(self.matrix.who_pays("FOB", "trucking_origin"), Party.SELLER)
        self.assertEqual(self.matrix.who_pays("FOB", "export_clearance"), Party.SELLER)
        self.assertEqual(self.matrix.who_pays("FOB", "othc"), Party.SELLER)
        self.assertEqual(self.matrix.who_pays("FOB", "ocean_freight"), Party.BUYER)
        self.assertEqual(self.matrix.who_pays("FOB", "insurance"), Party.BUYER)

    def test_cfr_ocean_freight_is_seller(self):
        """Under CFR, Seller pays ocean freight but Buyer pays insurance."""
        self.assertEqual(self.matrix.who_pays("CFR", "ocean_freight"), Party.SELLER)
        self.assertEqual(self.matrix.who_pays("CFR", "insurance"), Party.BUYER)

    def test_cif_ocean_freight_and_insurance_are_seller(self):
        """Under CIF, Seller pays ocean freight AND insurance."""
        self.assertEqual(self.matrix.who_pays("CIF", "ocean_freight"), Party.SELLER)
        self.assertEqual(self.matrix.who_pays("CIF", "insurance"), Party.SELLER)

    def test_cpt_and_cip_dthc(self):
        """Under CPT and CIP, Seller pays destination trucking and DTHC."""
        self.assertEqual(self.matrix.who_pays("CPT", "trucking_destination"), Party.SELLER)
        self.assertEqual(self.matrix.who_pays("CPT", "dthc"), Party.SELLER)
        self.assertEqual(self.matrix.who_pays("CIP", "insurance"), Party.SELLER)
        self.assertEqual(self.matrix.who_pays("CIP", "dthc"), Party.SELLER)

    def test_dap_vs_dpu_dthc(self):
        """Under DAP, DTHC is paid by BUYER. Under DPU, DTHC is paid by SELLER."""
        self.assertEqual(self.matrix.who_pays("DAP", "dthc"), Party.BUYER)
        self.assertEqual(self.matrix.who_pays("DPU", "dthc"), Party.SELLER)

    def test_ddp_exceptions(self):
        """Under DDP, Seller pays import clearance and duty, but Buyer pays Port Congestion and Demurrage."""
        self.assertEqual(self.matrix.who_pays("DDP", "import_clearance"), Party.SELLER)
        self.assertEqual(self.matrix.who_pays("DDP", "customs_duty_tax"), Party.SELLER)
        self.assertEqual(self.matrix.who_pays("DDP", "port_congestion"), Party.BUYER)
        self.assertEqual(self.matrix.who_pays("DDP", "demurrage_detention"), Party.BUYER)

    def test_terms_where_buyer_handles_import(self):
        buyer_import_terms = self.matrix.terms_where_buyer_handles_import()
        self.assertIn("EXW", buyer_import_terms)
        self.assertIn("FOB", buyer_import_terms)
        self.assertIn("CIF", buyer_import_terms)
        self.assertIn("DAP", buyer_import_terms)
        self.assertIn("DPU", buyer_import_terms)
        self.assertNotIn("DDP", buyer_import_terms)
        self.assertEqual(len(buyer_import_terms), 10)

    def test_compare_cpt_and_dap(self):
        cmp = self.matrix.compare("CPT", "DAP")
        p_cpt, p_dap = cmp["dthc"]
        self.assertEqual(p_cpt, Party.SELLER)
        self.assertEqual(p_dap, Party.BUYER)

    def test_party_label_ar(self):
        self.assertEqual(Party.BUYER.label_ar(), "المشتري")
        self.assertEqual(Party.SELLER.label_ar(), "البائع")

    def test_invalid_category_raises_keyerror(self):
        with self.assertRaises(KeyError):
            self.matrix.who_pays("FOB", "non_existent_category")

    def test_to_matrix_dict_format(self):
        m_dict = self.matrix.to_matrix_dict()
        self.assertEqual(len(m_dict), 11)
        self.assertIn("FOB", m_dict)
        self.assertEqual(m_dict["FOB"]["othc"], "SELLER")
        self.assertEqual(m_dict["EXW"]["othc"], "BUYER")


if __name__ == "__main__":
    unittest.main()
