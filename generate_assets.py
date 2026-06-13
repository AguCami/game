from PIL import Image, ImageDraw, ImageFilter, ImageFont
import math
import os

os.makedirs("/home/user/game/assets/sprites", exist_ok=True)

# ---- menu_bg.png ----
def make_menu_bg():
    w, h = 540, 960
    img = Image.new("RGB", (w, h))
    draw = ImageDraw.Draw(img)

    # Sky gradient (dark blue to slightly lighter at horizon)
    for y in range(h//2):
        t = y / (h//2)
        r = int(5 + t*20)
        g = int(5 + t*25)
        b = int(30 + t*60)
        draw.line([(0,y),(w,y)], fill=(r,g,b))

    # Stars
    import random
    random.seed(42)
    for _ in range(200):
        sx = random.randint(0, w)
        sy = random.randint(0, h//3)
        br = random.randint(150, 255)
        draw.point((sx, sy), fill=(br, br, br))

    # Crowd band
    crowd_y = h//2 - 60
    for y in range(crowd_y, crowd_y+80):
        for x in range(0, w, 4):
            r = random.randint(80, 200)
            g = random.randint(20, 120)
            b = random.randint(20, 120)
            draw.rectangle([x, y, x+3, y+3], fill=(r,g,b))

    # Floodlight towers
    for tx in [60, w-60]:
        # Tower pole
        draw.rectangle([tx-6, h//4, tx+6, crowd_y+40], fill=(80,80,90))
        # Light housing
        draw.rectangle([tx-20, h//4-20, tx+20, h//4+10], fill=(100,100,110))
        # Glow
        for r in range(50, 0, -5):
            alpha_val = int(80 * (1 - r/50))
            light_layer = Image.new("RGBA", (w, h), (0,0,0,0))
            ld = ImageDraw.Draw(light_layer)
            ld.ellipse([tx-r, h//4-20-r, tx+r, h//4-20+r], fill=(255,255,200,alpha_val))
            img_rgba = img.convert("RGBA")
            img_rgba = Image.alpha_composite(img_rgba, light_layer)
            img = img_rgba.convert("RGB")
            draw = ImageDraw.Draw(img)

    # Pitch (green)
    pitch_top = h//2 + 20
    for y in range(pitch_top, h):
        t = (y - pitch_top) / (h - pitch_top)
        g_val = int(80 + t*40)
        draw.line([(0,y),(w,y)], fill=(20, g_val, 20))

    # Field markings
    lc = (255, 255, 255, 200)
    # Halfway line
    draw.line([(0, pitch_top+20), (w, pitch_top+20)], fill=(200,200,200), width=3)
    # Center circle (perspective squished)
    cx, cy = w//2, pitch_top + 120
    draw.ellipse([cx-80, cy-30, cx+80, cy+30], outline=(200,200,200), width=2)
    draw.point((cx, cy), fill=(200,200,200))
    # Penalty box at bottom
    pb_w = 240
    pb_h = 100
    draw.rectangle([w//2-pb_w//2, h-pb_h-20, w//2+pb_w//2, h-20], outline=(200,200,200), width=2)

    img.save("/home/user/game/assets/sprites/menu_bg.png")
    print("menu_bg.png done")

# ---- stadium.png ----
def make_stadium():
    w, h = 1100, 1400
    img = Image.new("RGB", (w, h), (15, 20, 15))
    draw = ImageDraw.Draw(img)

    # Crowd border
    crowd_size = 100
    for y in range(0, h):
        for x in range(0, crowd_size):
            import random
            random.seed(x*1000+y)
            r = random.randint(60,180)
            g2 = random.randint(20,100)
            b = random.randint(20,100)
            draw.point((x, y), fill=(r,g2,b))
        for x in range(w-crowd_size, w):
            random.seed(x*1000+y+99999)
            r = random.randint(60,180)
            g2 = random.randint(20,100)
            b = random.randint(20,100)
            draw.point((x, y), fill=(r,g2,b))
    for x in range(0, w):
        for y in range(0, crowd_size):
            import random
            random.seed(x+y*10000)
            r = random.randint(60,180)
            g2 = random.randint(20,100)
            b = random.randint(20,100)
            draw.point((x, y), fill=(r,g2,b))
        for y in range(h-crowd_size, h):
            random.seed(x+y*10000+888)
            r = random.randint(60,180)
            g2 = random.randint(20,100)
            b = random.randint(20,100)
            draw.point((x, y), fill=(r,g2,b))

    # Green pitch
    px1, py1 = crowd_size+10, crowd_size+10
    px2, py2 = w-crowd_size-10, h-crowd_size-10

    # Alternating grass stripes
    stripe_w = (px2-px1)//10
    for i in range(10):
        col = (30, 100, 30) if i%2==0 else (25, 85, 25)
        draw.rectangle([px1+i*stripe_w, py1, px1+(i+1)*stripe_w, py2], fill=col)

    # Field markings white
    lw = 3
    mc = (220, 220, 220)
    # Border
    draw.rectangle([px1, py1, px2, py2], outline=mc, width=lw)
    # Halfway line
    mid_y = (py1+py2)//2
    draw.line([(px1, mid_y), (px2, mid_y)], fill=mc, width=lw)
    # Center circle
    cx = (px1+px2)//2
    cy = mid_y
    cr = 100
    draw.ellipse([cx-cr, cy-cr, cx+cr, cy+cr], outline=mc, width=lw)
    draw.ellipse([cx-5, cy-5, cx+5, cy+5], fill=mc)
    # Penalty boxes
    pb_w2 = 250
    pb_h2 = 120
    # Top penalty box
    draw.rectangle([cx-pb_w2, py1, cx+pb_w2, py1+pb_h2], outline=mc, width=lw)
    # Top goal box
    draw.rectangle([cx-100, py1, cx+100, py1+50], outline=mc, width=lw)
    # Bottom penalty box
    draw.rectangle([cx-pb_w2, py2-pb_h2, cx+pb_w2, py2], outline=mc, width=lw)
    draw.rectangle([cx-100, py2-50, cx+100, py2], outline=mc, width=lw)
    # Corner arcs
    r_corner = 30
    draw.arc([px1-r_corner, py1-r_corner, px1+r_corner, py1+r_corner], 0, 90, fill=mc, width=lw)
    draw.arc([px2-r_corner, py1-r_corner, px2+r_corner, py1+r_corner], 90, 180, fill=mc, width=lw)
    draw.arc([px1-r_corner, py2-r_corner, px1+r_corner, py2+r_corner], 270, 360, fill=mc, width=lw)
    draw.arc([px2-r_corner, py2-r_corner, px2+r_corner, py2+r_corner], 180, 270, fill=mc, width=lw)

    img.save("/home/user/game/assets/sprites/stadium.png")
    print("stadium.png done")

# ---- stick_base.png ----
def make_stick_base():
    img = Image.new("RGBA", (120, 120), (0,0,0,0))
    draw = ImageDraw.Draw(img)
    cx, cy, r = 60, 60, 50
    # Outer ring
    draw.ellipse([cx-r, cy-r, cx+r, cy+r], fill=(60,60,70,180), outline=(120,120,130,220), width=3)
    img.save("/home/user/game/assets/sprites/stick_base.png")
    print("stick_base.png done")

# ---- stick_knob.png ----
def make_stick_knob():
    img = Image.new("RGBA", (60, 60), (0,0,0,0))
    draw = ImageDraw.Draw(img)
    margin = 5
    r = 8
    # Rounded rect
    draw.rounded_rectangle([margin, margin, 60-margin, 60-margin], radius=r, fill=(220,220,230,230), outline=(140,140,150,255), width=2)
    img.save("/home/user/game/assets/sprites/stick_knob.png")
    print("stick_knob.png done")

# ---- arrow.png ----
def make_arrow():
    img = Image.new("RGBA", (80, 80), (0,0,0,0))
    draw = ImageDraw.Draw(img)
    gold = (255, 200, 0, 255)
    dark = (100, 70, 0, 255)
    # Arrow shape pointing up
    # Head: triangle top
    arrow_pts = [
        (40, 5),   # tip
        (10, 40),  # left wing
        (25, 40),  # inner left
        (25, 72),  # bottom left
        (55, 72),  # bottom right
        (55, 40),  # inner right
        (70, 40),  # right wing
    ]
    # Outline
    outline_pts = [(x-1, y-1) for x,y in arrow_pts]
    draw.polygon(arrow_pts, fill=gold, outline=dark)
    img.save("/home/user/game/assets/sprites/arrow.png")
    print("arrow.png done")

# ---- icon_multishot.png ----
def make_icon_multishot():
    img = Image.new("RGBA", (120, 120), (15, 20, 45, 255))
    draw = ImageDraw.Draw(img)

    # Draw 3 soccer balls with fire glow
    balls = [(30, 75), (60, 50), (90, 75)]
    for bx, by in balls:
        r = 18
        # Fire glow
        for gr in range(28, 0, -4):
            alpha = int(120 * (1 - gr/28))
            glow = Image.new("RGBA", (120, 120), (0,0,0,0))
            gd = ImageDraw.Draw(glow)
            gd.ellipse([bx-gr, by-gr, bx+gr, by+gr], fill=(255, 100, 0, alpha))
            img = Image.alpha_composite(img, glow)
        draw = ImageDraw.Draw(img)
        # Ball
        draw.ellipse([bx-r, by-r, bx+r, by+r], fill=(240,240,240,255), outline=(30,30,30,255), width=2)
        # Pentagon pattern (simplified hexagons)
        draw.ellipse([bx-7, by-7, bx+7, by+7], fill=(30,30,30,255))
        for angle in range(0, 360, 72):
            ax = bx + int(12 * math.cos(math.radians(angle)))
            ay = by + int(12 * math.sin(math.radians(angle)))
            draw.ellipse([ax-4, ay-4, ax+4, ay+4], fill=(30,30,30,255))

    img.save("/home/user/game/assets/sprites/icon_multishot.png")
    print("icon_multishot.png done")

# ---- icon_speedboost.png ----
def make_icon_speedboost():
    img = Image.new("RGBA", (120, 120), (15, 20, 45, 255))
    draw = ImageDraw.Draw(img)

    # Electric glow
    glow = Image.new("RGBA", (120, 120), (0,0,0,0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse([20, 20, 100, 100], fill=(0, 100, 255, 40))
    img = Image.alpha_composite(img, glow)
    draw = ImageDraw.Draw(img)

    # Lightning bolt
    bolt = [(60, 10), (35, 60), (55, 60), (40, 110), (75, 55), (55, 55), (75, 10)]
    draw.polygon(bolt, fill=(255, 230, 0, 255), outline=(200, 150, 0, 255), width=2)

    # Boot outline (simplified)
    boot = [(80, 80), (90, 80), (95, 88), (85, 95), (65, 95), (60, 90), (65, 80), (75, 75), (80, 80)]
    draw.polygon(boot, outline=(255,255,255,200), width=2)

    img.save("/home/user/game/assets/sprites/icon_speedboost.png")
    print("icon_speedboost.png done")

# ---- icon_forcefield.png ----
def make_icon_forcefield():
    img = Image.new("RGBA", (120, 120), (15, 20, 45, 255))

    cx, cy = 60, 60
    # Concentric glowing circles
    for r in range(50, 5, -8):
        alpha = int(180 * (1 - r/50)) + 30
        b_val = min(255, 150 + (50-r)*3)
        layer = Image.new("RGBA", (120, 120), (0,0,0,0))
        ld = ImageDraw.Draw(layer)
        ld.ellipse([cx-r, cy-r, cx+r, cy+r], outline=(50, 150, b_val, alpha), width=3)
        img = Image.alpha_composite(img, layer)

    # Bright outer ring
    draw = ImageDraw.Draw(img)
    draw.ellipse([cx-48, cy-48, cx+48, cy+48], outline=(100, 200, 255, 220), width=4)
    draw.ellipse([cx-35, cy-35, cx+35, cy+35], outline=(150, 220, 255, 180), width=3)
    draw.ellipse([cx-22, cy-22, cx+22, cy+22], outline=(200, 240, 255, 150), width=2)
    # Center glow
    draw.ellipse([cx-8, cy-8, cx+8, cy+8], fill=(180, 230, 255, 200))

    img.save("/home/user/game/assets/sprites/icon_forcefield.png")
    print("icon_forcefield.png done")

if __name__ == "__main__":
    make_menu_bg()
    make_stadium()
    make_stick_base()
    make_stick_knob()
    make_arrow()
    make_icon_multishot()
    make_icon_speedboost()
    make_icon_forcefield()
    print("All assets generated!")
