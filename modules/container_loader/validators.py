from typing import List
from .schemas import CargoPackageSchema


def validate_cargo_packages(packages: List[CargoPackageSchema]) -> None:
    if not packages:
        raise ValueError("At least one cargo package must be provided.")

    for i, pkg in enumerate(packages, 1):
        if pkg.length <= 0 or pkg.width <= 0 or pkg.height <= 0:
            raise ValueError(f"Package #{i} must have positive length, width, and height dimensions.")
        if pkg.qty < 1:
            raise ValueError(f"Package #{i} quantity must be at least 1.")
        if pkg.weight_kg < 0:
            raise ValueError(f"Package #{i} weight cannot be negative.")
