from typing import Dict, List, Tuple
from .container_specs import ContainerSpec


def to_meters(value: float, unit: str = "mm") -> float:
    """
    Converts dimension values in mm, cm, or m to meters.
    """
    unit_clean = unit.lower().strip()
    if unit_clean in ("mm", "millimeter", "millimeters"):
        return value / 1000.0
    elif unit_clean in ("cm", "centimeter", "centimeters"):
        return value / 100.0
    elif unit_clean in ("m", "meter", "meters"):
        return float(value)
    else:
        # Default fallback assume mm if value > 100, cm if > 10, else m
        if value > 500:
            return value / 1000.0
        elif value > 20:
            return value / 100.0
        return float(value)


def calculate_package_cbm(length: float, width: float, height: float, qty: int, unit: str = "mm") -> float:
    l_m = to_meters(length, unit)
    w_m = to_meters(width, unit)
    h_m = to_meters(height, unit)
    return round(l_m * w_m * h_m * qty, 4)


def calculate_package_floor_area(length: float, width: float, qty: int, unit: str = "mm") -> float:
    l_m = to_meters(length, unit)
    w_m = to_meters(width, unit)
    return round(l_m * w_m * qty, 4)


def fits_dimension(length: float, width: float, height: float, unit: str, container: ContainerSpec) -> bool:
    l_m = to_meters(length, unit)
    w_m = to_meters(width, unit)
    h_m = to_meters(height, unit)

    normal_fit = (
        l_m <= container.internal_length
        and w_m <= container.internal_width
        and h_m <= container.internal_height
    )
    rotated_fit = (
        w_m <= container.internal_length
        and l_m <= container.internal_width
        and h_m <= container.internal_height
    )
    return normal_fit or rotated_fit


def fits_door(length: float, width: float, height: float, unit: str, container: ContainerSpec) -> bool:
    l_m = to_meters(length, unit)
    w_m = to_meters(width, unit)
    h_m = to_meters(height, unit)

    width_entry = (w_m <= container.door_width and h_m <= container.door_height)
    length_entry = (l_m <= container.door_width and h_m <= container.door_height)

    return width_entry or length_entry


def check_height_clearance(height: float, unit: str, container: ContainerSpec, min_clearance_m: float = 0.10) -> bool:
    h_m = to_meters(height, unit)
    door_clearance_ok = (container.door_height - h_m) >= min_clearance_m
    internal_clearance_ok = (container.internal_height - h_m) >= min_clearance_m
    return door_clearance_ok and internal_clearance_ok


def check_2d_floor_packing(packages: List[Dict], container: ContainerSpec) -> Tuple[bool, str]:
    """
    Checks if non-stackable packages fit on container floor area.
    Evaluates total floor area and 2D arrangement along container length & width.
    """
    total_floor_area_req = 0.0
    for pkg in packages:
        if not pkg.get("stackable", False):
            l_m = to_meters(pkg["length"], pkg.get("unit", "mm"))
            w_m = to_meters(pkg["width"], pkg.get("unit", "mm"))
            qty = pkg.get("qty", 1)
            total_floor_area_req += (l_m * w_m * qty)

    if total_floor_area_req > container.total_floor_area:
        return False, f"Required floor area ({total_floor_area_req:.2f} m²) exceeds container floor area ({container.total_floor_area:.2f} m²)"

    # Layout arrangement check for non-stackable items
    # Check end-to-end placement along container length
    cum_length_normal = 0.0
    cum_length_rotated = 0.0
    max_width_normal = 0.0
    max_width_rotated = 0.0

    for pkg in packages:
        if not pkg.get("stackable", False):
            l_m = to_meters(pkg["length"], pkg.get("unit", "mm"))
            w_m = to_meters(pkg["width"], pkg.get("unit", "mm"))
            qty = pkg.get("qty", 1)

            # Normal orientation: length along container length, width along container width
            cum_length_normal += (l_m * qty)
            if w_m > max_width_normal:
                max_width_normal = w_m

            # Rotated orientation: width along container length, length along container width
            cum_length_rotated += (w_m * qty)
            if l_m > max_width_rotated:
                max_width_rotated = l_m

    normal_layout_ok = (cum_length_normal <= container.internal_length and max_width_normal <= container.internal_width)
    rotated_layout_ok = (cum_length_rotated <= container.internal_length and max_width_rotated <= container.internal_width)

    if not (normal_layout_ok or rotated_layout_ok):
        return False, f"Floor arrangement geometry check failed (Length sum: {cum_length_normal:.2f}m vs container max: {container.internal_length:.2f}m)"

    return True, "Floor layout arrangement is feasible"
