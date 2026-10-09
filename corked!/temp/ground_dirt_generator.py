"""Corked! dirt v2: A/B blend + scattered rocks of mixed sizes.

One shared tileable base, several rock layouts on top. Rocks never cross the
tile edge, so the variants can sit next to each other in any order and the
seams still match (the base underneath is identical and wraps).
"""
import numpy as np
from PIL import Image, ImageDraw
from scipy.spatial import cKDTree

RES = 512                       # 3 m tile -> ~0.59 cm per pixel

# ---------------------------------------------------------------- base ----
def periodic_noise(cells, seed):
    r = np.random.default_rng(seed)
    g = r.random((cells, cells))
    g = np.vstack([g, g[:1]]); g = np.hstack([g, g[:, :1]])
    im = Image.fromarray((g * 255).astype(np.uint8)).resize((RES + 1, RES + 1), Image.BICUBIC)
    return np.asarray(im, dtype=float)[:RES, :RES] / 255.0

def fbm(seed, base, octaves=3, gain=0.5):
    out = np.zeros((RES, RES)); amp = 1.0; tot = 0
    for o in range(octaves):
        out += amp * periodic_noise(base * 2 ** o, seed + o * 17)
        tot += amp; amp *= gain
    out /= tot; out -= out.min(); out /= out.max()
    return out

def clods(n, seed, strength, line):
    r = np.random.default_rng(seed)
    pts = r.random((n * n, 2))
    big = np.vstack([pts + np.array([dx, dy]) for dx in (-1, 0, 1) for dy in (-1, 0, 1)])
    bid = np.tile(np.arange(len(pts)), 9)
    ys, xs = np.mgrid[0:RES, 0:RES]
    q = np.stack([(xs + .5) / RES, (ys + .5) / RES], -1).reshape(-1, 2)
    dist, idx = cKDTree(big).query(q, k=2)
    edge = (dist[:, 1] - dist[:, 0]).reshape(RES, RES)
    val = r.uniform(-1, 1, len(pts))[bid[idx[:, 0]]].reshape(RES, RES)
    seam = np.clip(1 - edge / (0.9 / n * 0.12), 0, 1)
    return 1 + val * strength - seam * line

def lerp3(a, b, t):
    return a[None, None, :] * (1 - t[..., None]) + b[None, None, :] * t[..., None]

def speckle(img, density, col, seed, size=2):
    r = np.random.default_rng(seed)
    mask = r.random((RES // size, RES // size)) < density
    mask = np.kron(mask, np.ones((size, size)))[:RES, :RES]
    a = mask * r.uniform(0.4, 0.9, (RES, RES))
    return img * (1 - a[..., None]) + np.array(col)[None, None, :] * a[..., None]

# halfway between A (sandy path) and B (vineyard soil)
DARK  = np.array([0.545, 0.375, 0.240])
MID   = np.array([0.665, 0.475, 0.310])
LIGHT = np.array([0.760, 0.575, 0.390])

def base(seed=41):
    lo = fbm(seed, 4); me = fbm(seed + 100, 8); hi = fbm(seed + 200, 32, 2)
    t = np.clip(0.5 + (lo - 0.5) * 0.22 + (me - 0.5) * 0.30, 0, 1)
    img = np.where(t[..., None] < 0.5,
                   lerp3(DARK, MID, np.clip(t * 2, 0, 1)),
                   lerp3(MID, LIGHT, np.clip(t * 2 - 1, 0, 1)))
    dust = np.clip((fbm(seed + 300, 10) - 0.55) * 3.0, 0, 1) * 0.30
    img = img * (1 - dust[..., None]) + (LIGHT * 1.05)[None, None, :] * dust[..., None]
    damp = np.clip((fbm(seed + 400, 9) - 0.62) * 4.0, 0, 1) * 0.45
    img *= (1 - 0.18 * damp)[..., None]
    img *= clods(22, seed + 50, 0.035, 0.025)[..., None]
    img *= clods(55, seed + 60, 0.020, 0.015)[..., None]
    img *= (1 + (hi - 0.5) * 0.22)[..., None]
    img += np.random.default_rng(seed).normal(0, 0.011, (RES, RES, 1))
    img = speckle(img, 0.010, DARK * 0.75, seed + 5)
    img = speckle(img, 0.006, LIGHT * 1.12, seed + 6)
    return img

# --------------------------------------------------------------- rocks ----
STONE = [(0.76, 0.69, 0.58), (0.68, 0.61, 0.51), (0.82, 0.75, 0.63),
         (0.62, 0.56, 0.47), (0.73, 0.64, 0.52), (0.79, 0.70, 0.56)]
LIGHT_DIR = np.array([-0.55, -0.55, 0.63])       # from top-left, above
LIGHT_DIR /= np.linalg.norm(LIGHT_DIR)

def rock(img, cx, cy, R, rseed):
    """One irregular, shaded rock with contact darkening and a cast shadow."""
    rng = np.random.default_rng(int(rseed))
    W = img.shape[1]; H = img.shape[0]
    k = np.arange(2, 6)
    amp = rng.uniform(0.03, 0.11, len(k)) / k * 2.2
    ph = rng.uniform(0, 2 * np.pi, len(k))
    squash = rng.uniform(0.62, 0.95); rot = rng.uniform(0, np.pi)
    col = np.array(STONE[rng.integers(len(STONE))]) * rng.uniform(0.93, 1.05)

    pad = int(R * 2.2) + 3
    x0, x1 = int(max(cx - pad, 0)), int(min(cx + pad, W))
    y0, y1 = int(max(cy - pad, 0)), int(min(cy + pad, H))
    if x1 <= x0 or y1 <= y0:
        return
    yy, xx = np.mgrid[y0:y1, x0:x1].astype(float)
    dx, dy = xx - cx, yy - cy
    u = dx * np.cos(rot) + dy * np.sin(rot)
    v = (-dx * np.sin(rot) + dy * np.cos(rot)) / squash
    th = np.arctan2(v, u)
    edge_r = R * (1 + (amp[:, None, None] * np.cos(k[:, None, None] * th + ph[:, None, None])).sum(0))
    d = np.sqrt(u * u + v * v) / edge_r                       # 0 centre .. 1 rim

    patch = img[y0:y1, x0:x1]

    # cast shadow (down-right) + contact occlusion ring, both on the dirt only
    sx, sy = dx - R * 0.42, dy - R * 0.42
    su = sx * np.cos(rot) + sy * np.sin(rot)
    sv = (-sx * np.sin(rot) + sy * np.cos(rot)) / squash
    sd = np.sqrt(su * su + sv * sv) / (edge_r * 1.08)
    shadow = np.clip((1 - sd) * 2.2, 0, 1) * (d > 1) * 0.32
    ao = np.clip(1 - (d - 1) / 0.35, 0, 1) * (d > 1) * 0.22
    patch *= (1 - np.maximum(shadow, ao))[..., None]

    # dome-ish height with a flattened top, shaded from the light direction
    h = np.clip(1 - d ** 2, 0, 1) ** 0.55 * R * 0.55
    gy, gx = np.gradient(h)
    n = np.stack([-gx, -gy, np.ones_like(h)], -1)
    n /= np.linalg.norm(n, axis=-1, keepdims=True)
    lam = np.clip((n * LIGHT_DIR).sum(-1), 0, 1)
    shade = 0.70 + 0.42 * lam
    grain = 1 + rng.normal(0, 0.035, h.shape)                # mineral speckle
    stone = col[None, None, :] * (shade * grain)[..., None]
    rim = np.clip((d - 0.82) / 0.18, 0, 1)                    # darker silhouette edge
    stone *= (1 - 0.18 * rim)[..., None]
    a = np.clip((1 - d) * R * 0.9, 0, 1)                      # ~1 px anti-aliased edge
    patch[:] = patch * (1 - a[..., None]) + stone * a[..., None]


def wrapped_pebbles(img, count, seed):
    """Small pebbles that cross the tile edge seamlessly. Lives in the shared base,
    so every variant has identical edges and the field shows no empty seam bands."""
    rng = np.random.default_rng(seed)
    big = np.tile(img, (3, 3, 1))
    for _ in range(count):
        cx, cy = rng.uniform(0, RES, 2)
        R = rng.uniform(2.4, 5.0)
        rs = rng.integers(1 << 30)
        for ox in (0, RES, 2 * RES):
            for oy in (0, RES, 2 * RES):
                rock(big, cx + ox, cy + oy, R, rs)
    return big[RES:2 * RES, RES:2 * RES].copy()

def scatter(img, seed):
    rng = np.random.default_rng(seed)
    # tiers: many small, some medium, a few big ones (pixel radius; 1 px ~ 0.6 cm)
    tiers = [(rng.integers(5, 8), 12.0, 22.0),     # 14-26 cm
             (rng.integers(12, 17), 6.5, 11.5),    # 8-14 cm
             (rng.integers(18, 26), 2.6, 5.5)]     # 3-6 cm
    clusters = rng.uniform(55, RES - 55, (3, 2))
    placed = []
    for count, rmin, rmax in tiers:
        for _ in range(count):
            R = rng.uniform(rmin, rmax)
            margin = R * 1.9 + 3                    # keep the whole rock + shadow inside
            for _try in range(40):
                if rng.random() < 0.45:             # clustered
                    c = clusters[rng.integers(len(clusters))]
                    p = c + rng.normal(0, 38, 2)
                else:
                    p = rng.uniform(margin, RES - margin, 2)
                if not (margin <= p[0] <= RES - margin and margin <= p[1] <= RES - margin):
                    continue
                if all(np.hypot(*(p - q)) > (R + r2) * 1.15 for q, r2 in placed):
                    break
            else:
                continue
            placed.append((p, R))
    # draw large first so small pebbles can sit on top of their shadows
    for p, R in sorted(placed, key=lambda t: -t[1]):
        rock(img, p[0], p[1], R, rng.integers(1 << 30))
    return len(placed)

if __name__ == "__main__":
    B = wrapped_pebbles(base(), 34, 777)
    variants = {}
    for i, s in enumerate((101, 202, 303), 1):
        im = B.copy()
        n = scatter(im, s)
        im = np.clip(im, 0, 1)
        variants[f"ground_dirt_{i}"] = im
        Image.fromarray((im * 255).astype(np.uint8), "RGB").save(f"ground_dirt_{i}_albedo.png")
        print(f"ground_dirt_{i}: {n} steiner")

    # preview: one tile up close + a 5x4 field mixing the three variants
    imgs = [Image.fromarray((v * 255).astype(np.uint8), "RGB") for v in variants.values()]
    rng = np.random.default_rng(5)
    W, Hh = 5, 4
    field = Image.new("RGB", (RES * W, RES * Hh))
    for gy in range(Hh):
        for gx in range(W):
            field.paste(imgs[rng.integers(3)], (gx * RES, gy * RES))
    FH = 560
    field = field.resize((int(FH * W / Hh), FH), Image.LANCZOS)
    close = imgs[0].resize((FH, FH), Image.LANCZOS)
    PAD = 14
    sheet = Image.new("RGB", (PAD * 3 + FH + field.width, FH + 60), (242, 240, 236))
    sheet.paste(close, (PAD, PAD)); sheet.paste(field, (PAD * 2 + FH, PAD))
    d = ImageDraw.Draw(sheet)
    d.text((PAD + 4, FH + PAD + 14), "en flis, 3 x 3 m", fill=(40, 38, 34))
    d.text((PAD * 2 + FH + 4, FH + PAD + 14), "5 x 4 fliser, tre varianter blandet", fill=(40, 38, 34))
    sheet.save("dirt_v2_preview.png")
