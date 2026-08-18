import math
from typing import List, Dict, Optional
from sqlalchemy.orm import Session

from .container_specs import ContainerSpec, STANDARD_CONTAINERS
from .packing import (
    calculate_package_cbm,
    calculate_package_floor_area,
    check_2d_floor_packing,
    check_height_clearance,
    fits_dimension,
    fits_door,
    to_meters,
)
from .repository import get_all_container_specs
from .schemas import (
    CargoPackageSchema,
    ContainerLoaderEvaluationResult,
    ContainerLoaderRequest,
    ContainerOptionEvaluation,
)
from .validators import validate_cargo_packages


def evaluate_container_loading_service(
    request: ContainerLoaderRequest, db: Optional[Session] = None
) -> ContainerLoaderEvaluationResult:
    validate_cargo_packages(request.packages)

    # Determine container specs
    specs = get_all_container_specs(db) if db else STANDARD_CONTAINERS

    # Determine global stackability
    if request.is_stackable_override is not None:
        global_stackable = request.is_stackable_override
    else:
        global_stackable = all(p.stackable for p in request.packages)

    # Aggregate Cargo Totals
    total_weight_kg = 0.0
    total_cbm = 0.0
    total_non_stackable_floor_m2 = 0.0

    pkg_dicts: List[Dict] = []
    for pkg in request.packages:
        pkg_cbm = calculate_package_cbm(pkg.length, pkg.width, pkg.height, pkg.qty, pkg.unit)
        total_cbm += pkg_cbm
        total_weight_kg += (pkg.weight_kg * pkg.qty)

        effective_pkg_stackable = global_stackable if request.is_stackable_override is not None else pkg.stackable
        if not effective_pkg_stackable:
            floor_m2 = calculate_package_floor_area(pkg.length, pkg.width, pkg.qty, pkg.unit)
            total_non_stackable_floor_m2 += floor_m2

        pkg_dicts.append({
            "length": pkg.length,
            "width": pkg.width,
            "height": pkg.height,
            "qty": pkg.qty,
            "weight_kg": pkg.weight_kg,
            "stackable": effective_pkg_stackable,
            "unit": pkg.unit,
        })

    total_cbm = round(total_cbm, 4)
    total_weight_kg = round(total_weight_kg, 2)
    total_non_stackable_floor_m2 = round(total_non_stackable_floor_m2, 4)

    evaluations: List[ContainerOptionEvaluation] = []

    for container in specs:
        reasons_en: List[str] = []
        reasons_ar: List[str] = []
        status = "FIT"

        # Level 1: Weight Check
        if total_weight_kg > container.max_payload:
            status = "OVERWEIGHT"
            reasons_en.append(f"Total cargo weight ({total_weight_kg:,.0f} kg) exceeds container max payload ({container.max_payload:,.0f} kg)")
            reasons_ar.append(f"الوزن الإجمالي للشحنة ({total_weight_kg:,.0f} كجم) يتجاوز حمولة الحاوية القصوى ({container.max_payload:,.0f} كجم)")

        # Level 2: Individual Package Dimension Check
        for i, pkg in enumerate(request.packages, 1):
            if not fits_dimension(pkg.length, pkg.width, pkg.height, pkg.unit, container):
                status = "DIMENSION_EXCEEDED"
                reasons_en.append(f"Package #{i} dimensions exceed container internal dimensions ({container.internal_length}x{container.internal_width}x{container.internal_height} m)")
                reasons_ar.append(f"أبعاد الطرد رقم {i} تتجاوز الأبعاد الداخلية للحاوية")

            # Level 3: Door Opening Check
            if not fits_door(pkg.length, pkg.width, pkg.height, pkg.unit, container):
                status = "DOOR_BLOCKED"
                reasons_en.append(f"Package #{i} cannot pass through container door opening ({container.door_width}x{container.door_height} m)")
                reasons_ar.append(f"الطرد رقم {i} لا يدخل من فتحة باب الحاوية ({container.door_width}×{container.door_height} متر)")

            # Level 4: Height Safety Clearance (Requires >= 10 cm ceiling clearance)
            h_m = to_meters(pkg.height, pkg.unit)
            if h_m >= 2.0 and not check_height_clearance(pkg.height, pkg.unit, container, min_clearance_m=0.10):
                if status == "FIT":
                    status = "CEILING_TOO_TIGHT"
                reasons_en.append(f"Package height ({h_m:.2f} m) has insufficient clearance for forklift loading (Door height: {container.door_height} m, Internal height: {container.internal_height} m)")
                reasons_ar.append(f"ارتفاع الطرد ({h_m:.2f} متر) قريب جداً من سقف/باب الحاوية مما يعوق الشحن بالشوكة ويشكل خطورة (ارتفاع الباب: {container.door_height} متر)")

        # Level 5: 2D Floor Area & Geometry Packing Check for Non-Stackable Cargo
        if not global_stackable:
            floor_ok, floor_reason = check_2d_floor_packing(pkg_dicts, container)
            if not floor_ok:
                if status == "FIT":
                    status = "FLOOR_EXCEEDED"
                reasons_en.append(f"Non-stackable floor arrangement check failed: {floor_reason}")
                reasons_ar.append(f"فشل ترتيب الحمولة على أرضية الحاوية (غير قابلة للرص رأسياً): {floor_reason}")

        # Required Count Calculation
        req_by_cbm = math.ceil(total_cbm / container.total_cbm_capacity) if container.total_cbm_capacity > 0 else 1
        req_by_weight = math.ceil(total_weight_kg / container.max_payload) if container.max_payload > 0 else 1
        req_by_floor = math.ceil(total_non_stackable_floor_m2 / container.total_floor_area) if (not global_stackable and container.total_floor_area > 0) else 1

        req_count = max(req_by_cbm, req_by_weight, req_by_floor, 1)

        total_cap_cbm = req_count * container.total_cbm_capacity
        total_cap_weight = req_count * container.max_payload
        total_cap_floor = req_count * container.total_floor_area

        vol_util = round((total_cbm / total_cap_cbm) * 100.0, 1) if total_cap_cbm > 0 else 0.0
        weight_util = round((total_weight_kg / total_cap_weight) * 100.0, 1) if total_cap_weight > 0 else 0.0
        floor_util = round((total_non_stackable_floor_m2 / total_cap_floor) * 100.0, 1) if (not global_stackable and total_cap_floor > 0) else vol_util

        if status == "FIT":
            reasons_en.append("Cargo fits through door opening and respects payload/dimension limits")
            reasons_ar.append("الحمولة تدخل من باب الحاوية وتتوافق مع أبعاد المساحة والوزن المسموح")
            if not global_stackable:
                reasons_en.append(f"2D floor layout arrangement is feasible ({total_non_stackable_floor_m2:.2f} m² required vs {container.total_floor_area:.2f} m² available)")
                reasons_ar.append(f"ترتيب الطرود على أرضية الحاوية ممكن ومناسب ({total_non_stackable_floor_m2:.2f} م² مطلوب مقارنة بـ {container.total_floor_area:.2f} م² متوفرة)")

        evaluations.append(
            ContainerOptionEvaluation(
                container_code=container.code,
                container_name=container.name,
                status=status,
                required_count=req_count,
                total_cbm=total_cbm,
                total_weight_kg=total_weight_kg,
                floor_area_required_m2=total_non_stackable_floor_m2,
                container_floor_area_m2=container.total_floor_area,
                volume_utilization_pct=min(vol_util, 100.0),
                weight_utilization_pct=min(weight_util, 100.0),
                floor_utilization_pct=min(floor_util, 100.0),
                reasons=reasons_en,
                reasons_ar=reasons_ar,
            )
        )

    # Sort & Select Recommended Container Option
    # Rank priority: Status FIT > FIT count minimum > Highest floor/volume utilization
    def option_score(opt: ContainerOptionEvaluation) -> float:
        status_penalty = 0 if opt.status == "FIT" else 10000
        count_penalty = opt.required_count * 1000
        utilization = opt.floor_utilization_pct if not global_stackable else opt.volume_utilization_pct
        return status_penalty + count_penalty - utilization

    evaluations.sort(key=option_score)

    best_opt = evaluations[0]

    return ContainerLoaderEvaluationResult(
        recommended_container=best_opt.container_code,
        recommended_container_name=best_opt.container_name,
        recommended_count=best_opt.required_count,
        status=best_opt.status,
        total_cbm=total_cbm,
        total_weight_kg=total_weight_kg,
        is_stackable=global_stackable,
        floor_required=not global_stackable,
        floor_utilization_pct=best_opt.floor_utilization_pct,
        volume_utilization_pct=best_opt.volume_utilization_pct,
        weight_utilization_pct=best_opt.weight_utilization_pct,
        reasons=best_opt.reasons,
        reasons_ar=best_opt.reasons_ar,
        all_options=evaluations,
    )


def list_container_specs_service(db: Session) -> List[ContainerSpec]:
    return get_all_container_specs(db)
