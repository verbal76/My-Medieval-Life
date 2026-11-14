"""Read a Godot FileAccess.open_compressed file (GCPF, gzip or deflate blocks). Usage: gcpf.py FILE > out"""
import struct,sys,zlib
def read(path):
    b=open(path,'rb').read()
    assert b[:4]==b'GCPF'
    mode,bs,total=struct.unpack('<III',b[4:16])
    n=(total+bs-1)//bs
    sizes=struct.unpack('<%dI'%n,b[16:16+4*n]); off=16+4*n; out=bytearray()
    for s in sizes:
        out+=zlib.decompress(b[off:off+s],wbits=31 if mode==3 else 15); off+=s
    return bytes(out[:total])
if __name__=='__main__':
    sys.stdout.buffer.write(read(sys.argv[1]))
