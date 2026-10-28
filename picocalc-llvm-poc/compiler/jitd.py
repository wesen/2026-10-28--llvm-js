#!/usr/bin/env python3
"""A SEPARATE Unix-domain socket compiler daemon. Target/simulator never links LLVM.
Protocol: one JSON request line: {source, output, base, opt}; response {ok, meta/error}.
This is for trusted local development; no authentication, secure sandbox or quotas.
"""
import argparse
import json
import os
from pathlib import Path
import socketserver
from compile import compile_js

class Handler(socketserver.StreamRequestHandler):
    def handle(self):
        for raw in self.rfile:
            try:
                req=json.loads(raw)
                if not isinstance(req.get('source'),str) or len(req['source'])>65536:
                    raise ValueError('source must be a string <=64KB')
                output=Path(req['output']).resolve()
                # daemon writes only beneath the explicitly configured output root
                if not output.is_relative_to(self.server.outdir):
                    raise ValueError('output must be inside configured output directory')
                meta=compile_js(req['source'],output,int(req.get('base',0x100000)),str(req.get('opt','2')),str(req.get('language','js')),str(req.get('backend','llvm')))
                reply={'ok':True,'output':str(output),'meta':meta}
            except Exception as e:
                reply={'ok':False,'error':str(e)}
            self.wfile.write((json.dumps(reply)+'\n').encode())

class Server(socketserver.ThreadingUnixStreamServer):
    daemon_threads=True
    allow_reuse_address=True

def main():
    ap=argparse.ArgumentParser();ap.add_argument('--socket',type=Path,required=True)
    ap.add_argument('--outdir',type=Path,required=True);a=ap.parse_args()
    a.outdir.mkdir(parents=True,exist_ok=True)
    a.socket.parent.mkdir(parents=True,exist_ok=True)
    try:a.socket.unlink()
    except FileNotFoundError:pass
    with Server(str(a.socket),Handler) as server:
        server.outdir=a.outdir.resolve()
        os.chmod(a.socket,0o600)
        print(json.dumps({'jitd':'ready','socket':str(a.socket),'outdir':str(server.outdir)}),flush=True)
        server.serve_forever()
if __name__=='__main__':main()
