"""Draws the README art: the hero banner and the menu preview in light and dark."""
import sys
from xml.sax.saxutils import escape
out = sys.argv[1] if len(sys.argv) > 1 else __import__("os").path.dirname(__file__) or "."
FONT = "-apple-system, BlinkMacSystemFont, 'SF Pro Text', 'Helvetica Neue', Helvetica, Arial, sans-serif"

def glyph(cx, cy, r, ink="#fff"):
    # The menu bar icon: a glass disc with a check, at centre (cx, cy), radius r.
    s = r / 50
    return f'''<g transform="translate({cx - r} {cy - r}) scale({s})">
  <circle cx="50" cy="50" r="46" fill="{ink}" fill-opacity=".22" stroke="{ink}" stroke-opacity=".55" stroke-width="2.5"/>
  <path d="M30 51 L44 65 L71 37" fill="none" stroke="{ink}" stroke-width="9" stroke-linecap="round" stroke-linejoin="round"/>
</g>'''

def banner(dark):
    # Apple product-page style: centred, quiet background, the icon, one headline.
    w, h = 1280, 640
    bg, ink, sub = ("#000000", "#F5F5F7", "#A1A1A6") if dark else ("#FBFBFD", "#1D1D1F", "#6E6E73")
    S = 196                      # icon size
    ix, iy = (w - S) / 2, 92
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}" font-family="{FONT}" role="img" aria-label="Claude Code - Auto Approver. Stop babysitting permission prompts.">
<defs>
  <linearGradient id="word" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#FF8A5B"/><stop offset="1" stop-color="#D93A22"/></linearGradient>
  <radialGradient id="halo" cx=".5" cy=".5" r=".5"><stop offset="0" stop-color="#FF7A4D" stop-opacity="{.30 if dark else .20}"/><stop offset="1" stop-color="#FF7A4D" stop-opacity="0"/></radialGradient>
  <filter id="lift" x="-40%" y="-40%" width="180%" height="180%"><feDropShadow dx="0" dy="16" stdDeviation="18" flood-color="#7a2410" flood-opacity="{.55 if dark else .28}"/></filter>
</defs>
<rect width="{w}" height="{h}" rx="28" fill="{bg}"/>
<ellipse cx="{w/2}" cy="{iy + S/2}" rx="330" ry="210" fill="url(#halo)"/>
<image href="icon.png" x="{ix}" y="{iy}" width="{S}" height="{S}" filter="url(#lift)"/>
<text x="{w/2}" y="378" text-anchor="middle" font-size="26" font-weight="600" fill="{sub}" letter-spacing=".2">Claude Code</text>
<text x="{w/2}" y="452" text-anchor="middle" font-size="80" font-weight="700" letter-spacing="-2.4" fill="{ink}">Auto Approver<tspan fill="url(#word)">.</tspan></text>
<text x="{w/2}" y="506" text-anchor="middle" font-size="30" font-weight="500" letter-spacing="-.3" fill="{sub}">Stop babysitting permission prompts.</text>
<g font-size="19" font-weight="500">
  <rect x="{w/2 - 178}" y="544" width="168" height="44" rx="22" fill="#0071E3"/>
  <text x="{w/2 - 94}" y="572" text-anchor="middle" fill="#fff">Download</text>
  <text x="{w/2 + 26}" y="572" fill="{"#2997FF" if dark else "#0066CC"}">For macOS and Windows ›</text>
</g>
</svg>'''

def menu(dark):
    c = dict(bg="#2A2A2C" if dark else "#F4F4F6", border="#ffffff1f" if dark else "#0000001a",
             text="#F2F2F7" if dark else "#1C1C1E", dim="#98989F" if dark else "#7C7C83",
             sep="#ffffff1a" if dark else "#0000001a", hl="#0A64D2", bar="#1E1E20" if dark else "#E9E9EC",
             green="#32D74B" if dark else "#28A745", page="#0D1117" if dark else "#FFFFFF")
    W = 820
    x0, y0, mw = 200, 52, 300
    rows = [("title", "Claude Code - Auto Approver 1.0.0"), ("dim", "by Marco Cesarato"), ("sep",),
            ("status", "● Auto-approve on"), ("dim", "Accepts Claude's permission prompts"), ("sep",),
            ("sub", "Pause"), ("subsel", "Skip chats"), ("item", "Open log"), ("item", "GitHub"), ("sep",), ("item", "Quit", "⌘Q")]
    y, parts, sel_y = y0 + 10, [], 0
    for r in rows:
        kind = r[0]
        if kind == "sep":
            parts.append(f'<line x1="{x0+12}" x2="{x0+mw-12}" y1="{y+5}" y2="{y+5}" stroke="{c["sep"]}"/>'); y += 11; continue
        hgt = 26
        tx, ty = x0 + 22, y + 18
        if kind == "subsel":
            parts.append(f'<rect x="{x0+6}" y="{y}" width="{mw-12}" height="{hgt}" rx="6" fill="{c["hl"]}"/>'); sel_y = y
        color = {"title": c["text"], "dim": c["dim"], "status": c["green"]}.get(kind, "#fff" if kind == "subsel" else c["text"])
        size, weight = {"title": (13.5, 600), "dim": (12, 400), "status": (13.5, 600)}.get(kind, (13.5, 400))
        parts.append(f'<text x="{tx}" y="{ty}" font-size="{size}" font-weight="{weight}" fill="{color}">{escape(r[1])}</text>')
        if kind in ("sub", "subsel"):
            parts.append(f'<path d="M{x0+mw-24} {y+8} l5 5 l-5 5" fill="none" stroke="{color}" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>')
        if len(r) > 2:
            parts.append(f'<text x="{x0+mw-20}" y="{ty}" font-size="13" fill="{c["dim"]}" text-anchor="end">{r[2]}</text>')
        y += hgt
    mh = y - y0 + 8
    # The submenu beside the highlighted row: chats open or running, one left to the user.
    sx, sw = x0 + mw - 6, 236
    subs = [("Refactor billing service", False), ("Fix flaky e2e tests", True), ("Write release notes", False)]
    sy = sel_y - 8
    sub = []
    for i, (name, on) in enumerate(subs):
        yy = sy + 8 + i * 26
        if on: sub.append(f'<path d="M{sx+12} {yy+13} l4 4 l8 -9" fill="none" stroke="{c["text"]}" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>')
        sub.append(f'<text x="{sx+32}" y="{yy+18}" font-size="13.5" fill="{c["text"]}">{escape(name)}</text>')
    sh = 8 + len(subs) * 26 + 8
    icon = glyph(x0 + 22, 15, 9, c["text"])
    H = max(y0 + mh, sy + sh + 34) + 36
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}" font-family="{FONT}" role="img" aria-label="The app's menu in the macOS menu bar">
<defs><filter id="s" x="-20%" y="-20%" width="140%" height="140%"><feDropShadow dx="0" dy="10" stdDeviation="14" flood-opacity="{.55 if dark else .18}"/></filter></defs>
<rect width="{W}" height="{H}" rx="18" fill="{c["page"]}"/>
<clipPath id="page"><rect width="{W}" height="{H}" rx="18"/></clipPath>
<rect width="{W}" height="30" fill="{c["bar"]}" clip-path="url(#page)"/>
<rect x="{x0+8}" y="3" width="28" height="24" rx="6" fill="{c["text"]}" fill-opacity=".12"/>
{icon}
<g font-size="13" fill="{c["text"]}"><text x="{W-150}" y="20">Wed 19 Nov  10:42</text></g>
<g filter="url(#s)"><rect x="{x0}" y="{y0}" width="{mw}" height="{mh}" rx="11" fill="{c["bg"]}" stroke="{c["border"]}"/></g>
{''.join(parts)}
<g filter="url(#s)"><rect x="{sx}" y="{sy}" width="{sw}" height="{sh}" rx="11" fill="{c["bg"]}" stroke="{c["border"]}"/></g>
{''.join(sub)}
<text x="{sx+sw}" y="{sy+sh+26}" font-size="12.5" fill="{c["dim"]}" text-anchor="end">✓ prompts left to you</text>
</svg>'''

# Each picture is kept as SVG, its source, and as a 2x PNG, which the README shows: an
# SVG's text falls back to whatever font the reader's system has, a PNG looks the same
# everywhere. The menu's page colour is GitHub's own, light and dark, so it blends in.
import os, re, shutil, subprocess, tempfile
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

# The banner shows the app icon itself: Icon Composer's ictool renders the icon document, in
# Liquid Glass, as icon.png, which the banner's SVG references. It ships inside Xcode.
dev = os.environ.get("DEVELOPER_DIR") or subprocess.run(["xcode-select", "-p"], capture_output=True, text=True).stdout.strip()
if "CommandLineTools" in dev:
    dev = "/Applications/Xcode.app/Contents/Developer"
ictool = os.path.join(dev, "..", "Applications", "Icon Composer.app", "Contents", "Executables", "ictool")
icon = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "macos", "resources", "AppIcon.icon")
subprocess.run([ictool, icon, "--export-image", "--output-file", f"{out}/icon.png", "--platform", "macOS",
                "--rendition", "Default", "--width", "512", "--height", "512", "--scale", "1"],
               check=True, capture_output=True)
print("icon.png written")
for name, svg in [("banner-light", banner(False)), ("banner-dark", banner(True)),
                  ("menu-light", menu(False)), ("menu-dark", menu(True))]:
    path = f"{out}/{name}.svg"
    open(path, "w").write(svg)
    if not os.path.exists(CHROME):
        print(f"{name}.svg written; install Google Chrome to render {name}.png")
        continue
    w, h = re.search(r'viewBox="0 0 (\d+) (\d+)"', svg).groups()
    profile = tempfile.mkdtemp()
    subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars",
                    "--default-background-color=00000000", "--force-device-scale-factor=2",
                    f"--user-data-dir={profile}", f"--window-size={w},{h}",
                    f"--screenshot={os.path.abspath(out)}/{name}.png", "file://" + os.path.abspath(path)],
                   check=True, capture_output=True)
    shutil.rmtree(profile, ignore_errors=True)
    print(f"{name}.svg and {name}.png written")
