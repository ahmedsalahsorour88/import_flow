"""
ImportFlow ERP — App Icon Generator
Generates high-resolution multi-size Windows .ico file for ImportFlow ERP.
"""
from PIL import Image, ImageDraw, ImageFont
from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parent
ICON_PATHS = [
    ROOT_DIR / "frontend" / "windows" / "runner" / "resources" / "app_icon.ico",
    ROOT_DIR / "dist" / "app_icon.ico",
    ROOT_DIR / "installer" / "app_icon.ico",
]

def create_icon_image(size):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # 1. Rounded rectangle background
    # Colors: Flat Charcoal #2C3E50 -> Deep Blue #1A252F gradient simulation
    radius = int(size * 0.22)
    margin = int(size * 0.04)
    
    # Outer Glow/Shadow
    draw.rounded_rectangle(
        [margin, margin, size - margin, size - margin],
        radius=radius,
        fill=(44, 62, 80, 255), # Flat Charcoal
        outline=(52, 152, 219, 255), # Flat Cobalt border
        width=max(1, int(size * 0.04))
    )

    # Inner Accent Box (Cargo Container Graphic)
    c_left = int(size * 0.22)
    c_top = int(size * 0.22)
    c_right = int(size * 0.78)
    c_bottom = int(size * 0.78)
    
    # Draw Modern Shipping Container Shape
    draw.rounded_rectangle(
        [c_left, c_top, c_right, c_bottom],
        radius=int(size * 0.08),
        fill=(52, 152, 219, 255), # Cobalt Blue
        outline=(236, 240, 241, 255), # Cloud White
        width=max(1, int(size * 0.03))
    )

    # Container Vertical Ribs
    rib_width = max(1, int(size * 0.025))
    step = (c_right - c_left) // 5
    for i in range(1, 5):
        x = c_left + i * step
        draw.line([(x, c_top + int(size * 0.06)), (x, c_bottom - int(size * 0.06))], fill=(41, 128, 185, 255), width=rib_width)

    # Green Success Check / Forward Arrow Accent (Customs Passed / Flow)
    arrow_color = (39, 174, 96, 255) # Flat Emerald
    # Draw Emerald Shield / Arrow in bottom right
    s_x = int(size * 0.55)
    s_y = int(size * 0.55)
    s_r = int(size * 0.88)
    s_b = int(size * 0.88)
    draw.rounded_rectangle(
        [s_x, s_y, s_r, s_b],
        radius=int(size * 0.08),
        fill=arrow_color,
        outline=(255, 255, 255, 255),
        width=max(1, int(size * 0.03))
    )

    # Draw checkmark inside emerald box
    chk_p1 = (int(s_x + size * 0.07), int(s_y + size * 0.16))
    chk_p2 = (int(s_x + size * 0.14), int(s_y + size * 0.24))
    chk_p3 = (int(s_x + size * 0.26), int(s_y + size * 0.09))
    draw.line([chk_p1, chk_p2, chk_p3], fill=(255, 255, 255, 255), width=max(2, int(size * 0.04)), joint="curve")

    return img

def generate_ico():
    sizes = [256, 128, 64, 48, 32, 16]
    images = [create_icon_image(s) for s in sizes]
    
    for p in ICON_PATHS:
        p.parent.mkdir(parents=True, exist_ok=True)
        images[0].save(p, format="ICO", sizes=[(s, s) for s in sizes])
        print(f"Generated custom .ico at: {p}")

if __name__ == "__main__":
    generate_ico()
