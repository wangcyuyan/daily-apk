import zlib, struct, os

def make_png(path, size, bg, c1, c2):
    raw = bytearray()
    cx1, cy, r = size*0.33, size*0.5, size*0.16
    cx2 = size*0.67
    for y in range(size):
        raw.append(0)  # filter type 0
        for x in range(size):
            d1 = (x-cx1)**2 + (y-cy)**2
            d2 = (x-cx2)**2 + (y-cy)**2
            if d1 <= r*r:
                col = c1
            elif d2 <= r*r:
                col = c2
            else:
                col = bg
            raw += bytes(col)
    def chunk(typ, data):
        c = zlib.crc32(typ+data) & 0xffffffff
        return struct.pack(">I", len(data)) + typ + data + struct.pack(">I", c)
    sig = b"\x89PNG\r\n\x1a\n"
    ihdr = struct.pack(">IIBBBBB", size, size, 8, 6, 0, 0, 0)  # 8-bit RGBA
    idat = zlib.compress(bytes(raw), 9)
    png = sig + chunk(b"IHDR", ihdr) + chunk(b"IDAT", idat) + chunk(b"IEND", b"")
    with open(path, "wb") as f:
        f.write(png)

out = os.path.dirname(os.path.abspath(__file__))
bg = (21,21,31,255)
green = (76,175,80,255)
red = (229,57,53,255)
make_png(os.path.join(out, "icon-192.png"), 192, bg, green, red)
make_png(os.path.join(out, "icon-512.png"), 512, bg, green, red)
print("icons written:", os.path.join(out, "icon-192.png"), os.path.join(out, "icon-512.png"))
