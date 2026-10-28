import json
from pathlib import Path
import socket
import subprocess
import sys
import tempfile
import time
import unittest

ROOT=Path(__file__).resolve().parents[1]

class CompilerServiceTests(unittest.TestCase):
    def test_unix_socket_service_and_output_guard(self):
        with tempfile.TemporaryDirectory(prefix='picojitd-test-') as d:
            root=Path(d);sock=root/'service.sock';out=root/'objects';out.mkdir()
            proc=subprocess.Popen([sys.executable,str(ROOT/'compiler/jitd.py'),'--socket',str(sock),'--outdir',str(out)],stdout=subprocess.DEVNULL,stderr=subprocess.PIPE,cwd=ROOT)
            try:
                for _ in range(300):
                    if sock.exists():break
                    time.sleep(.01)
                self.assertTrue(sock.exists(),'no jitd socket')
                def request(o):
                    with socket.socket(socket.AF_UNIX,socket.SOCK_STREAM) as s:
                        s.connect(str(sock));s.sendall((json.dumps(o)+'\n').encode())
                        return json.loads(s.makefile('rb').readline())
                source=(ROOT/'worlds/counter_v1.js').read_text()
                refused=request({'source':source,'output':str(root/'bad.elf'),'base':0x100000})
                self.assertFalse(refused['ok']);self.assertIn('inside',refused['error'])
                accepted=request({'source':source,'output':str(out/'code.elf'),'base':0x100000})
                self.assertTrue(accepted['ok']);self.assertEqual(accepted['meta']['target'],'riscv32-unknown-elf')
                self.assertTrue((out/'code.elf').exists())
                self.assertFalse(accepted['meta']['segments'][0]['flags']&2)
            finally:
                proc.terminate();proc.wait(timeout=5);proc.stderr.close()
