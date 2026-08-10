import unittest
from decimal import Decimal
import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from database.database import Base
from modules.container_loader.packing import to_meters, fits_dimension, fits_door
from modules.container_loader.schemas import CargoPackageSchema, ContainerLoaderRequest
from modules.container_loader.service import evaluate_container_loading_service
from modules.container_loader.container_specs import STANDARD_CONTAINERS, get_container_specs_dict


class TestContainerLoaderModule(unittest.TestCase):

    def setUp(self):
        self.engine = create_engine("sqlite:///:memory:", connect_args={"check_same_thread": False})
        Base.metadata.create_all(bind=self.engine)
        SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=self.engine)
        self.db = SessionLocal()

    def tearDown(self):
        self.db.close()
        Base.metadata.drop_all(bind=self.engine)

    def test_unit_conversions(self):
        self.assertEqual(to_meters(3950, "mm"), 3.95)
        self.assertEqual(to_meters(225, "cm"), 2.25)
        self.assertEqual(to_meters(2.25, "m"), 2.25)

    def test_worked_example_non_stackable_pallets_recommends_40hc(self):
        """
        Worked Example Verification from User Prompt:
        Pallets (Qty 2): 3950 x 2250 x 2250 mm, 2270 kg each, non-stackable.
        Cartons (Qty 2): 275 x 265 x 160 mm, 12 kg each.

        Total CBM = ~40.017 m³
        Total Weight = 4,564 kg
        Status: NON-STACKABLE

        Engine MUST recommend 1 x 40HC (40' High Cube Container) because:
        - 2 Pallets laid end-to-end: 3.95m + 3.95m = 7.90m length (fits <= 12.03m 40HC internal length)
        - Width: 2.25m (fits <= 2.35m 40HC internal width)
        - Height: 2.25m fits 40HC door (2.58m) and internal height (2.69m) with > 30 cm clearance.
        - 40GP is tight/rejected for height loading safety (door 2.28m leaves only 3 cm clearance).
        """
        pkg1 = CargoPackageSchema(
            length=3950.0,
            width=2250.0,
            height=2250.0,
            qty=2,
            weight_kg=2270.0,
            stackable=False,
            unit="mm",
        )
        pkg2 = CargoPackageSchema(
            length=275.0,
            width=265.0,
            height=160.0,
            qty=2,
            weight_kg=12.0,
            stackable=False,
            unit="mm",
        )

        req = ContainerLoaderRequest(packages=[pkg1, pkg2])
        res = evaluate_container_loading_service(req, self.db)

        self.assertEqual(res.recommended_container, "40HC")
        self.assertEqual(res.recommended_count, 1)
        self.assertEqual(res.status, "FIT")
        self.assertTrue(res.floor_required)
        self.assertAlmostEqual(res.total_cbm, 40.017, places=2)
        self.assertAlmostEqual(res.total_weight_kg, 4564.0, places=1)

        # Check options breakdown
        specs_dict = {opt.container_code: opt for opt in res.all_options}
        self.assertIn("40HC", specs_dict)
        self.assertEqual(specs_dict["40HC"].status, "FIT")

    def test_overweight_cargo_rejected_or_multi_container(self):
        """
        Heavy Cargo (35,000 kg) exceeds 40HC payload (26,500 kg), requiring 2 containers.
        """
        pkg = CargoPackageSchema(
            length=1000.0,
            width=1000.0,
            height=1000.0,
            qty=1,
            weight_kg=35000.0,
            stackable=True,
            unit="mm",
        )
        req = ContainerLoaderRequest(packages=[pkg])
        res = evaluate_container_loading_service(req, self.db)

        self.assertGreaterEqual(res.recommended_count, 2)

    def test_oversized_door_package_rejected(self):
        """
        Package height 3.0 m exceeds all standard container door heights (2.28m / 2.58m).
        Status must be DOOR_BLOCKED or DIMENSION_EXCEEDED.
        """
        pkg = CargoPackageSchema(
            length=2000.0,
            width=2000.0,
            height=3000.0,
            qty=1,
            weight_kg=500.0,
            stackable=False,
            unit="mm",
        )
        req = ContainerLoaderRequest(packages=[pkg])
        res = evaluate_container_loading_service(req, self.db)

        for opt in res.all_options:
            self.assertIn(opt.status, ["DOOR_BLOCKED", "DIMENSION_EXCEEDED", "CEILING_TOO_TIGHT"])


if __name__ == "__main__":
    unittest.main()
