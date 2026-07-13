"""Generate and verify the site's PBKDF2 access-code hash."""

from __future__ import annotations

import argparse
import getpass
import hashlib
import hmac


SALT = bytes.fromhex("881d9b0da4e5128a4e89cd266c21a8fd")
ITERATIONS = 210_000
PWD = "90d5e727d2454362002e2bb6887a1bf0210c6599b9c1399322661741798c1b4c"


def hash_access_code(access_code: str) -> str:
    """Return a deterministic PBKDF2-HMAC-SHA256 digest for an access code."""
    return hashlib.pbkdf2_hmac(
        "sha256",
        access_code.encode("utf-8"),
        SALT,
        ITERATIONS,
    ).hex()


def verify_access_code(access_code: str, pwd: str = PWD) -> bool:
    """Compare an access code with a stored digest in constant time."""
    return hmac.compare_digest(hash_access_code(access_code), pwd)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "action",
        choices=("hash", "verify"),
        help="hash a new code or verify a code against PWD",
    )
    args = parser.parse_args()
    access_code = getpass.getpass("Access code: ")

    if args.action == "hash":
        print(hash_access_code(access_code))
        return 0

    valid = verify_access_code(access_code)
    print("valid" if valid else "invalid")
    return 0 if valid else 1


if __name__ == "__main__":
    raise SystemExit(main())
