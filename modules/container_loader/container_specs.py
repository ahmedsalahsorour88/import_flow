from dataclasses import dataclass
from typing import List, Dict


@dataclass
class ContainerSpec:
    code: str
    name: str
    internal_length: float  # in meters
    internal_width: float   # in meters
    internal_height: float  # in meters
    door_width: float       # in meters
    door_height: float      # in meters
    max_payload: float      # in kg

    @property
    def total_cbm_capacity(self) -> float:
        return round(self.internal_length * self.internal_width * self.internal_height, 3)

    @property
    def total_floor_area(self) -> float:
        return round(self.internal_length * self.internal_width, 3)


STANDARD_CONTAINERS: List[ContainerSpec] = [
    ContainerSpec(
        code="20GP",
        name="20' General Purpose Container",
        internal_length=5.90,
        internal_width=2.35,
        internal_height=2.39,
        door_width=2.34,
        door_height=2.28,
        max_payload=21700.0,
    ),
    ContainerSpec(
        code="40GP",
        name="40' General Purpose Container",
        internal_length=12.03,
        internal_width=2.35,
        internal_height=2.39,
        door_width=2.34,
        door_height=2.28,
        max_payload=26500.0,
    ),
    ContainerSpec(
        code="40HC",
        name="40' High Cube Container",
        internal_length=12.03,
        internal_width=2.35,
        internal_height=2.69,
        door_width=2.34,
        door_height=2.58,
        max_payload=26500.0,
    ),
    ContainerSpec(
        code="45HC",
        name="45' High Cube Container",
        internal_length=13.56,
        internal_width=2.35,
        internal_height=2.69,
        door_width=2.34,
        door_height=2.58,
        max_payload=27700.0,
    ),
]


def get_container_specs_dict() -> Dict[str, ContainerSpec]:
    return {c.code: c for c in STANDARD_CONTAINERS}
