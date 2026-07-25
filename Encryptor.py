import sys
import os
import argparse
import json
import base64
import hashlib
from cryptography.hazmat.primitives.ciphers.aead import AESGCM

########################################################
def derive_key(password: str) -> bytes:
    return hashlib.sha256(password.encode()).digest()

########################################################
def encrypt_data(key: bytes, data: bytes) -> bytes:
    aesgcm = AESGCM(key)
    nonce  = os.urandom(12)
    ct = aesgcm.encrypt(nonce, data, None)
    return nonce + ct

########################################################
def main():
    p = argparse.ArgumentParser(description="Encrypt PE Assembly and Arguments")
    p.add_argument("assembly",                        help="Path to .NET assembly (.exe)")
    p.add_argument("-k", "--key",    required=True,   help="Encryption key")
    p.add_argument("-a", "--args",   default="",      help='Arguments string')
    p.add_argument("-o", "--output", default="P.txt", help="Output file path - Default P.txt - leave it like that!!")
    args = p.parse_args()

    if not os.path.exists(args.assembly):
        print(f"[!] File not found: {args.assembly}")
        return

    with open(args.assembly, "rb") as fp:
        asm_bytes = fp.read()

    payload_bytes = json.dumps({
        "pe_base64":  base64.b64encode(asm_bytes).decode(),
        "arguments":  args.args
    }).encode()

    key_bytes = derive_key(args.key)
    encrypted_payload = encrypt_data(key_bytes, payload_bytes)

    with open(args.output, "wb") as fp:
        fp.write(encrypted_payload)

    print(f"""
  [+] Payload encrypted (AES-256-GCM)
      Source    : {args.assembly} ({len(asm_bytes):,} bytes)
      Arguments : '{args.args}'
      Output    : {args.output} ({len(encrypted_payload):,} bytes)
      Key       : {args.key}
""")

if __name__ == "__main__":
    main()
