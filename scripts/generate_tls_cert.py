"""
Sorour Logistics ERP — Automated Local Network TLS Certificate Generator
========================================================================
Generates a 2048-bit RSA Self-Signed X.509 TLS Certificate with Subject
Alternative Names (SAN) covering:
- localhost
- 127.0.0.1
- Local Server Hostname
- All detected LAN IPv4 addresses (e.g., 192.168.x.x)

Output:
- certs/server.key (Private Key)
- certs/server.crt (Public Certificate)
"""
import sys
import os
import socket
import ipaddress
from datetime import datetime, timezone, timedelta
from pathlib import Path

from cryptography import x509
from cryptography.x509.oid import NameOID
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.primitives import serialization

ROOT_DIR = Path(__file__).resolve().parent.parent
CERTS_DIR = ROOT_DIR / "certs"


def get_local_ip_addresses():
    """Detects all IPv4 addresses assigned to the local network adapters."""
    ips = set(["127.0.0.1"])
    try:
        hostname = socket.gethostname()
        _, _, addrs = socket.gethostbyname_ex(hostname)
        for addr in addrs:
            if not addr.startswith("169.254."):  # Exclude APIPA
                ips.add(addr)
    except Exception:
        pass

    # Also try connecting out to get active interface
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ips.add(s.getsockname()[0])
        s.close()
    except Exception:
        pass

    return sorted(list(ips))


def generate_self_signed_cert(
    output_dir: Path = CERTS_DIR,
    validity_days: int = 3650,
):
    print("=" * 80)
    print("      Sorour Logistics ERP — Local Network TLS Certificate Generator          ")
    print("=" * 80)

    output_dir.mkdir(parents=True, exist_ok=True)
    key_path = output_dir / "server.key"
    cert_path = output_dir / "server.crt"

    # 1. Generate 2048-bit RSA Private Key
    print("[1/4] Generating 2048-bit RSA Private Key...")
    private_key = rsa.generate_private_key(
        public_exponent=65537,
        key_size=2048,
    )

    # 2. Collect Hostnames and IP Addresses for Subject Alternative Names (SAN)
    hostname = socket.gethostname()
    local_ips = get_local_ip_addresses()
    print(f"[2/4] Configuring Subject Alternative Names (SAN)...")
    print(f"      Hostname: {hostname}")
    print(f"      Local IPs: {', '.join(local_ips)}")

    san_entries = [
        x509.DNSName("localhost"),
        x509.DNSName(hostname),
    ]
    for ip_str in local_ips:
        try:
            ip_obj = ipaddress.ip_address(ip_str)
            san_entries.append(x509.IPAddress(ip_obj))
        except ValueError:
            pass

    # 3. Build X.509 Certificate
    print("[3/4] Building and signing X.509 Certificate...")
    subject = issuer = x509.Name([
        x509.NameAttribute(NameOID.COUNTRY_NAME, "EG"),
        x509.NameAttribute(NameOID.STATE_OR_PROVINCE_NAME, "Cairo"),
        x509.NameAttribute(NameOID.LOCALITY_NAME, "Cairo"),
        x509.NameAttribute(NameOID.ORGANIZATION_NAME, "Sorour Logistics ERP"),
        x509.NameAttribute(NameOID.COMMON_NAME, hostname),
    ])

    now_utc = datetime.now(timezone.utc)
    cert = (
        x509.CertificateBuilder()
        .subject_name(subject)
        .issuer_name(issuer)
        .public_key(private_key.public_key())
        .serial_number(x509.random_serial_number())
        .not_valid_before(now_utc - timedelta(days=1))
        .not_valid_after(now_utc + timedelta(days=validity_days))
        .add_extension(
            x509.SubjectAlternativeName(san_entries),
            critical=False,
        )
        .add_extension(
            x509.BasicConstraints(ca=True, path_length=None),
            critical=True,
        )
        .sign(private_key, hashes.SHA256())
    )

    # 4. Save Key and Certificate
    print(f"[4/4] Writing certificates to {output_dir.name}/...")
    with open(key_path, "wb") as f:
        f.write(
            private_key.private_bytes(
                encoding=serialization.Encoding.PEM,
                format=serialization.PrivateFormat.TraditionalOpenSSL,
                encryption_algorithm=serialization.NoEncryption(),
            )
        )

    with open(cert_path, "wb") as f:
        f.write(cert.public_bytes(serialization.Encoding.PEM))

    print("=" * 80)
    print(f"[SUCCESS] TLS Certificate generated successfully!")
    print(f"  Certificate : {cert_path}")
    print(f"  Private Key : {key_path}")
    print(f"  Validity    : {validity_days} days (10 years)")
    print()
    print("To trust this certificate on client Windows workstations:")
    print(f'  certutil -addstore -f "ROOT" "{cert_path}"')
    print("=" * 80)
    return cert_path, key_path


if __name__ == "__main__":
    generate_self_signed_cert()
