"""
City & Port Resolver for CargoX Standard Commercial Invoice & Blockchain Hub.
Provides ultra-fast UN/LOCODE city code resolution and port display name lookups.
"""
from __future__ import annotations

import json
import os
import re
from pathlib import Path
from typing import Dict, List, Optional, Tuple

CACHE_PATH = os.path.join(os.path.dirname(__file__), "templates", "cargox_cities_cache.json")

# In-memory global cache
_CACHE_DATA: Optional[Dict] = None
_CITIES_BY_COUNTRY: Dict[str, List[Tuple[str, str]]] = {}


def _ensure_cache_loaded():
    global _CACHE_DATA, _CITIES_BY_COUNTRY
    if _CACHE_DATA is not None:
        return

    if os.path.exists(CACHE_PATH):
        try:
            with open(CACHE_PATH, "r", encoding="utf-8") as f:
                _CACHE_DATA = json.load(f)
        except Exception:
            _CACHE_DATA = {"ports_and_cities": {}, "all_cities": {}}
    else:
        _CACHE_DATA = {"ports_and_cities": {}, "all_cities": {}}

    # Pre-index all_cities by 2-letter country code for lightning-fast lookups
    all_cities = _CACHE_DATA.get("all_cities", {})
    by_cc: Dict[str, List[Tuple[str, str]]] = {}
    for code, name in all_cities.items():
        cc = code[:2].upper()
        if cc not in by_cc:
            by_cc[cc] = []
        by_cc[cc].append((code, name))

    # Also include any entries from ports_and_cities not already in by_cc
    ports = _CACHE_DATA.get("ports_and_cities", {})
    for code, pdata in ports.items():
        cc = code[:2].upper()
        city_name = pdata.get("city", "")
        if cc not in by_cc:
            by_cc[cc] = []
        # Check if already present
        existing_codes = {c for c, _ in by_cc[cc]}
        if code not in existing_codes:
            by_cc[cc].append((code, city_name))

    # Sort each country's candidate list by length of city name descending (longest match first)
    for cc in by_cc:
        by_cc[cc].sort(key=lambda x: len(x[1]), reverse=True)

    _CITIES_BY_COUNTRY = by_cc


# Common default primary city codes by country ISO code
COUNTRY_DEFAULT_CITY_CODES: Dict[str, str] = {
    "CN": "CNSHA",  # China -> Shanghai
    "KR": "KRSEL",  # Korea -> Seoul
    "EG": "EGALY",  # Egypt -> Alexandria
    "IT": "ITMIL",  # Italy -> Milan
    "DE": "DEHAM",  # Germany -> Hamburg
    "AE": "AEDXB",  # UAE -> Dubai
    "US": "USNYC",  # USA -> New York
    "GB": "GBLON",  # UK -> London
    "FR": "FRPAR",  # France -> Paris
    "TR": "TRIST",  # Turkey -> Istanbul
    "ES": "ESBCN",  # Spain -> Barcelona
    "IN": "INBOM",  # India -> Mumbai
    "JP": "JPTYO",  # Japan -> Tokyo
    "SA": "SAJED",  # Saudi Arabia -> Jeddah
}


def resolve_city_code(
    address: Optional[str] = None,
    country_code: Optional[str] = None,
    city_hint: Optional[str] = None,
) -> str:
    """
    Intelligently resolves a 5-letter UN/LOCODE City Code (e.g. 'CNCGS', 'KRSEL', 'EGALY')
    based on the supplier/exporter address, country code, and city name hint.

    Example:
        Address: "No.16 Kangsheng Road, Zhitang Town, Changshu City, Suzhou City,China"
        Country: "CN"
        -> Returns "CNCGS" (Changshu City)
    """
    _ensure_cache_loaded()

    addr_clean = (address or "").strip().lower()
    city_clean = (city_hint or "").strip().lower()
    cc_norm = (country_code or "").strip().upper()

    # If country code not provided, try to infer from address
    if not cc_norm:
        if "china" in addr_clean or "prc" in addr_clean:
            cc_norm = "CN"
        elif "korea" in addr_clean:
            cc_norm = "KR"
        elif "egypt" in addr_clean:
            cc_norm = "EG"
        elif "italy" in addr_clean or "italia" in addr_clean:
            cc_norm = "IT"
        elif "germany" in addr_clean or "deutschland" in addr_clean:
            cc_norm = "DE"
        elif "emirates" in addr_clean or "uae" in addr_clean or "dubai" in addr_clean:
            cc_norm = "AE"
        elif "turkey" in addr_clean or "turkiye" in addr_clean:
            cc_norm = "TR"
        elif "india" in addr_clean:
            cc_norm = "IN"

    # User-specified explicit override / priority rule for Changshu -> CNCGS
    if "changshu" in addr_clean or "changshu" in city_clean:
        return "CNCGS"

    combined_text = f" {city_clean} {addr_clean} "

    # 1. Search in country's candidate list
    if cc_norm and cc_norm in _CITIES_BY_COUNTRY:
        candidates = _CITIES_BY_COUNTRY[cc_norm]
        for code, cname in candidates:
            # Clean suffix words like 'pt', 'apt', 'city'
            clean_name = re.sub(r"\b(pt|apt|city|town|port)\b", "", cname, flags=re.IGNORECASE).strip().lower()
            if len(clean_name) >= 3:
                pattern = r"\b" + re.escape(clean_name) + r"\b"
                if re.search(pattern, combined_text):
                    return code

    # 2. Check full ports & cities dictionary for direct match
    ports = _CACHE_DATA.get("ports_and_cities", {}) if _CACHE_DATA else {}
    if city_clean:
        for code, pdata in ports.items():
            if cc_norm and not code.startswith(cc_norm):
                continue
            p_city = pdata.get("city", "").strip().lower()
            if p_city == city_clean or (len(p_city) >= 4 and p_city in city_clean):
                return code

    # 3. Fallback to default primary city code for country
    if cc_norm in COUNTRY_DEFAULT_CITY_CODES:
        return COUNTRY_DEFAULT_CITY_CODES[cc_norm]

    # 4. If code already seems like a 5-letter UN/LOCODE, return it
    if len(city_clean) == 5 and city_clean.isalpha():
        return city_clean.upper()

    return f"{cc_norm}001" if cc_norm else "CN001"


def resolve_port_display_name(port_code: Optional[str]) -> str:
    """
    Resolves a port code into the official display name format:
    '[Port/City Name]/[Country]'

    Examples:
        'KRSEL' -> 'Seoul - Kimpo apt/KOREA, REPUBLIC OF.'
        'EGALY' -> 'Alexandria/Egypt'
        'CNCGS' -> 'Chenghai Laiwu/CHINA.'
    """
    if not port_code:
        return ""

    code_clean = port_code.strip().upper()
    _ensure_cache_loaded()

    ports = _CACHE_DATA.get("ports_and_cities", {}) if _CACHE_DATA else {}
    if code_clean in ports:
        item = ports[code_clean]
        city = item.get("city", "").strip()
        country = item.get("country", "").strip()
        if city and country:
            return f"{city}/{country}"
        elif city:
            return city

    # Fallback to all_cities
    all_cities = _CACHE_DATA.get("all_cities", {}) if _CACHE_DATA else {}
    if code_clean in all_cities:
        city_name = all_cities[code_clean].strip()
        # Derive country name from country code if possible
        cc = code_clean[:2]
        return f"{city_name}/{cc}"

    # Default fallback if code unknown
    return code_clean


def get_port_details(port_code: Optional[str]) -> Dict[str, str]:
    """
    Returns dictionary with port city and country.
    """
    if not port_code:
        return {"code": "", "city": "", "country": "", "display": ""}

    code_clean = port_code.strip().upper()
    _ensure_cache_loaded()

    ports = _CACHE_DATA.get("ports_and_cities", {}) if _CACHE_DATA else {}
    if code_clean in ports:
        item = ports[code_clean]
        city = item.get("city", "").strip()
        country = item.get("country", "").strip()
        display = f"{city}/{country}" if country else city
        return {"code": code_clean, "city": city, "country": country, "display": display}

    all_cities = _CACHE_DATA.get("all_cities", {}) if _CACHE_DATA else {}
    if code_clean in all_cities:
        city = all_cities[code_clean].strip()
        country = code_clean[:2]
        display = f"{city}/{country}"
        return {"code": code_clean, "city": city, "country": country, "display": display}

    return {"code": code_clean, "city": code_clean, "country": "", "display": code_clean}


def resolve_port_code(port_input: Optional[str], default_code: str = "EGALY") -> str:
    """
    Resolves any port input (which might be a 5-letter UN/LOCODE like 'LTKLJ' or a name like 'Klaipeda Port')
    into an official 5-letter UN/LOCODE port code.

    Examples:
        'LTKLJ' -> 'LTKLJ'
        'Klaipeda Port' -> 'LTKLJ'
        'Alexandria Port' -> 'EGALY'
        'EGALY' -> 'EGALY'
        'KRSEL' -> 'KRSEL'
        'Shanghai' -> 'CNSHA'
    """
    if not port_input:
        return default_code

    cleaned = port_input.strip()
    if len(cleaned) == 5 and cleaned.isalpha():
        return cleaned.upper()

    _ensure_cache_loaded()
    ports = _CACHE_DATA.get("ports_and_cities", {}) if _CACHE_DATA else {}
    if cleaned.upper() in ports:
        return cleaned.upper()

    # Search by port/city name
    norm_name = re.sub(r"\b(port|pt|apt|harbor|harbour|sea|terminal)\b", "", cleaned, flags=re.IGNORECASE).strip().lower()
    if not norm_name:
        norm_name = cleaned.lower()

    COMMON_PORT_NAMES: Dict[str, str] = {
        "alexandria": "EGALY",
        "damietta": "EGDAM",
        "port said": "EGPSD",
        "sokhna": "EGSOK",
        "cairo": "EGCAI",
        "adabiya": "EGADA",
        "dekheila": "EGEDK",
        "klaipeda": "LTKLJ",
        "vilnius": "LTVNO",
        "shanghai": "CNSHA",
        "ningbo": "CNNGB",
        "qingdao": "CNTAO",
        "shenzhen": "CNSZX",
        "guangzhou": "CNCAN",
        "tianjin": "CNTSN",
        "xiamen": "CNXMN",
        "dalian": "CNDLC",
        "changshu": "CNCGS",
        "seoul": "KRSEL",
        "busan": "KRPUS",
        "incheon": "KRINC",
        "hamburg": "DEHAM",
        "bremen": "DEBRE",
        "rotterdam": "NLRTM",
        "antwerp": "BEANR",
        "milan": "ITMIL",
        "genoa": "ITGOA",
        "la spezia": "ITSPE",
        "naples": "ITNAP",
        "valencia": "ESVLC",
        "barcelona": "ESBCN",
        "dubai": "AEDXB",
        "jebel ali": "AEJEA",
        "abu dhabi": "AEAUH",
        "jeddah": "SAJED",
        "dammam": "SADMM",
        "riyadh": "SARUH",
        "istanbul": "TRIST",
        "izmir": "TRIZM",
        "mersin": "TRMER",
        "singapore": "SGSIN",
    }

    # Direct common port lookup
    for c_name, c_code in COMMON_PORT_NAMES.items():
        if c_name in norm_name or norm_name in c_name:
            return c_code

    # Check ports_and_cities first
    for code, pdata in ports.items():
        pcity = pdata.get("city", "").strip().lower()
        if pcity == norm_name or norm_name in pcity:
            return code

    # Check all_cities
    all_cities = _CACHE_DATA.get("all_cities", {}) if _CACHE_DATA else {}
    for code, cname in all_cities.items():
        if norm_name in cname.lower():
            return code

    # If already 5 alphanumeric characters or fallback
    return default_code or cleaned

