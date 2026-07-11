#!/usr/bin/env python3
"""작업온 브랜드 자산 생성 (외부 다운로드 없이 로컬 렌더).

DESIGN-UI.md 토큰 + web/app/icon.svg("온") 일관성 기반.
- 안전 오렌지 #F4770C, 딥 네이비 #1A2233, 종이톤 #F7F6F3
출력: app/assets/branding/*.png  (flutter_launcher_icons / flutter_native_splash 입력)

렌더러: Pillow(PIL) — rsvg/ImageMagick 미설치 환경 대응.
"""
import os
from PIL import Image, ImageDraw, ImageFont

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "branding")
os.makedirs(OUT, exist_ok=True)

ORANGE = (0xF4, 0x77, 0x0C, 255)
NAVY = (0x1A, 0x22, 0x33, 255)
WHITE = (0xFF, 0xFF, 0xFF, 255)
TRANSPARENT = (0, 0, 0, 0)
FONT_PATH = "/System/Library/Fonts/AppleSDGothicNeo.ttc"

# AppleSDGothicNeo.ttc 는 여러 웨이트를 포함. Heavy/Bold 인덱스 탐색(없으면 0 + stroke 보강).
def load_heavy(size):
    for idx in (6, 4, 2):  # Bold → SemiBold → Medium (AppleSDGothicNeo.ttc)
        try:
            return ImageFont.truetype(FONT_PATH, size, index=idx)
        except Exception:
            continue
    return ImageFont.truetype(FONT_PATH, size, index=0)


def draw_on(img, cx, cy, box, fill, weight_boost=0.0):
    """'온' 글자를 광학 중심에 배치."""
    d = ImageDraw.Draw(img)
    size = int(box)
    font = load_heavy(size)
    stroke = int(size * weight_boost)
    # 실제 잉크 bbox 로 광학 중심 정렬
    l, t, r, b = d.textbbox((0, 0), "온", font=font, stroke_width=stroke)
    gw, gh = r - l, b - t
    x = cx - (l + gw / 2)
    y = cy - (t + gh / 2)
    d.text((x, y), "온", font=font, fill=fill,
           stroke_width=stroke, stroke_fill=fill)


def rounded_square(size, radius, color):
    img = Image.new("RGBA", (size, size), TRANSPARENT)
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([0, 0, size - 1, size - 1], radius=radius, fill=color)
    return img


def icon_master(path, bg, fg, size=1024, full_bleed=True, glyph=0.56):
    """앱 아이콘 마스터: 배경(full bleed) + '온'."""
    img = Image.new("RGBA", (size, size), TRANSPARENT)
    if full_bleed:
        ImageDraw.Draw(img).rectangle([0, 0, size, size], fill=bg)
    else:
        r = int(size * 0.22)
        img.alpha_composite(rounded_square(size, r, bg))
    draw_on(img, size / 2, size / 2 + size * 0.015, size * glyph, fg,
            weight_boost=0.035)
    img.save(path)
    print("wrote", path, img.size)


def icon_foreground(path, fg, size=1024, glyph=0.42):
    """Android adaptive 포그라운드: 투명 배경 + 안전영역 안의 '온'."""
    img = Image.new("RGBA", (size, size), TRANSPARENT)
    draw_on(img, size / 2, size / 2 + size * 0.01, size * glyph, fg,
            weight_boost=0.035)
    img.save(path)
    print("wrote", path, img.size)


def splash_icon(path, size=1152, tile=0.60):
    """스플래시 로고: 투명 여백 + 오렌지 라운드 사각 '온' (종이톤 위에 얹힘)."""
    img = Image.new("RGBA", (size, size), TRANSPARENT)
    t = int(size * tile)
    tile_img = rounded_square(t, int(t * 0.24), ORANGE)
    draw_on(tile_img, t / 2, t / 2 + t * 0.015, t * 0.56, WHITE,
            weight_boost=0.035)
    off = (size - t) // 2
    img.alpha_composite(tile_img, (off, off))
    img.save(path)
    print("wrote", path, img.size)


def splash_android12(path, size=1152, glyph=0.40):
    """Android 12 스플래시 아이콘: 원형 배경 안에 들어갈 '온'(오렌지 배경은 네이티브 설정)."""
    img = Image.new("RGBA", (size, size), TRANSPARENT)
    draw_on(img, size / 2, size / 2 + size * 0.01, size * glyph, WHITE,
            weight_boost=0.035)
    img.save(path)
    print("wrote", path, img.size)


if __name__ == "__main__":
    # 앱 아이콘 (iOS/Android 공통 마스터, full-bleed 오렌지 + 흰 '온' — 웹 파비콘과 통일)
    icon_master(os.path.join(OUT, "icon_master.png"), ORANGE, WHITE)
    # Android adaptive: 배경 단색(오렌지, 설정에서 지정) + 포그라운드 '온'
    icon_foreground(os.path.join(OUT, "icon_foreground.png"), WHITE)
    # iOS 다크 변형: 딥 네이비 배경 + 오렌지 '온'
    icon_master(os.path.join(OUT, "icon_dark.png"), NAVY, ORANGE)
    # iOS 틴트(모노크롬) 변형: 투명 배경 + 흰 '온'(시스템이 틴트 적용, 루미넌스 기준)
    icon_foreground(os.path.join(OUT, "icon_tinted.png"), WHITE, glyph=0.56)
    # 스플래시
    splash_icon(os.path.join(OUT, "splash_icon.png"))
    splash_android12(os.path.join(OUT, "splash_android12.png"))
