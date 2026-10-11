"""Build reusable fixed facet cohorts and sparse glints. Python standard library only."""
from pathlib import Path
import math
import random
import struct
import zlib

WIDTH, HEIGHT = 768, 1036
ROOT = Path(__file__).resolve().parents[1]


def png(path, alpha):
    def chunk(kind, data):
        return struct.pack('!I', len(data)) + kind + data + struct.pack('!I', zlib.crc32(kind + data) & 0xffffffff)
    rows = bytearray()
    for y in range(HEIGHT):
        rows.append(0)
        for a in alpha[y * WIDTH:(y + 1) * WIDTH]:
            rows.extend((255, 255, 255, a))
    header = struct.pack('!2I5B', WIDTH, HEIGHT, 8, 6, 0, 0, 0)
    path.write_bytes(b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', header) + chunk(b'IDAT', zlib.compress(rows, 9)) + chunk(b'IEND', b''))


def add(alpha, x, y, value):
    if 0 <= x < WIDTH and 0 <= y < HEIGHT:
        i = y * WIDTH + x
        alpha[i] = max(alpha[i], min(255, round(value)))


def main():
    rng = random.Random(0xB57A03)
    groups = [bytearray(WIDTH * HEIGHT) for _ in range(3)]
    glints = bytearray(WIDTH * HEIGHT)
    for _ in range(16000):
        cx, cy = rng.random() * WIDTH, rng.random() * HEIGHT
        rx, ry = rng.uniform(0.65, 2.8), rng.uniform(0.4, 1.55)
        angle = rng.random() * math.tau
        # Uneven triangular/sliver facets, not radial dots. Fixed normal cohorts.
        vertices = []
        for a in (0, 2.1, 4.4):
            x, y = math.cos(a) * rx, math.sin(a) * ry
            vertices.append((cx + x * math.cos(angle) - y * math.sin(angle),
                             cy + x * math.sin(angle) + y * math.cos(angle)))
        group = groups[rng.randrange(3)]
        brightness = rng.uniform(90, 250)
        v = cy / HEIGHT
        if v < 0.14 or 0.648 < v < 0.73:
            brightness *= 0.28
        elif 0.73 <= v <= 0.918:
            brightness *= 0.10
        min_x, max_x = math.floor(min(x for x, y in vertices)), math.ceil(max(x for x, y in vertices))
        min_y, max_y = math.floor(min(y for x, y in vertices)), math.ceil(max(y for x, y in vertices))
        def inside(x, y):
            signs = [(x - a[0]) * (b[1] - a[1]) - (y - a[1]) * (b[0] - a[0])
                     for a, b in zip(vertices, vertices[1:] + vertices[:1])]
            return all(z >= 0 for z in signs) or all(z <= 0 for z in signs)
        for y in range(min_y, max_y):
            for x in range(min_x, max_x):
                coverage = sum(inside(x + dx, y + dy) for dx, dy in ((.25,.25),(.75,.25),(.25,.75),(.75,.75))) / 4
                add(group, x, y, brightness * coverage)

    positions = []
    while len(positions) < 21:
        x, y = rng.uniform(0.11, 0.90) * WIDTH, rng.uniform(0.17, 0.63) * HEIGHT
        if any(math.hypot(x - px, y - py) < 64 for px, py in positions):
            continue
        positions.append((x, y))
        arm = rng.uniform(5, 11)
        strength = rng.uniform(140, 250)
        for yy in range(math.floor(y - arm), math.ceil(y + arm)):
            for xx in range(math.floor(x - arm), math.ceil(x + arm)):
                dx, dy = abs(xx + 0.5 - x), abs(yy + 0.5 - y)
                core = max(0, 1 - math.hypot(dx, dy) / 1.5)
                cross = max(max(0, 1 - dx / 0.85) * max(0, 1 - dy / arm),
                            max(0, 1 - dy / 0.85) * max(0, 1 - dx / arm))
                add(glints, xx, yy, strength * max(core, cross))
    folder = ROOT / 'html/images/foil'
    folder.mkdir(exist_ok=True)
    png(folder / 'secret-grain.png', groups[0])
    png(folder / 'secret-facets-b.png', groups[1])
    png(folder / 'secret-facets-c.png', groups[2])
    png(folder / 'secret-glints.png', glints)
    print(f'Generated fixed {WIDTH}x{HEIGHT} masks: 16,000 irregular facets in three fixed normal groups and 21 glints.')


if __name__ == '__main__':
    main()
