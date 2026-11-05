#!/usr/bin/env python3
"""Generate workflow.svg + workflow-dark.svg (diagram-design default skin, system fonts)."""
from pathlib import Path

SKINS = {
    "workflow": dict(paper="#f5f5f5", paper2="#ececec", node="#ffffff", ink="#2d3142",
                     muted="#4f5d75", soft="#5a6580", accent="#bf4520",
                     tint="rgba(191,69,32,0.08)", tag="rgba(45,49,66,0.40)",
                     dots="rgba(45,49,66,0.10)", rule="rgba(45,49,66,0.10)"),
    "workflow-dark": dict(paper="#2d3142", paper2="#393e53", node="#393e53", ink="#f5f5f5",
                          muted="#bfc0c0", soft="#949eb2", accent="#f08a59",
                          tint="rgba(240,138,89,0.12)", tag="rgba(245,245,245,0.40)",
                          dots="rgba(245,245,245,0.10)", rule="rgba(245,245,245,0.12)"),
}
SANS = "'Geist', system-ui, -apple-system, 'Segoe UI', sans-serif"
MONO = "'Geist Mono', ui-monospace, SFMono-Regular, Menlo, monospace"
W, H = 1000, 424

MODES = [  # name, sublabel line 1, line 2
    ("research", "WebSearch · agent-browser", "Chrome · last30days"),
    ("hack", "Opus plans → Sonnet builds", "opus-reviewer · impeccable"),
    ("study", "you write, I hint", "never full solutions"),
    ("project", "graphify → build → review", "security-audit · push on OK"),
    ("real", "verdict → why", "what would change it"),
]
MW, MH, GAP, X0, MY = 176, 64, 12, 36, 160


def tag(x, y, w, label, color, stroke):
    return (f'<rect x="{x}" y="{y}" width="{w}" height="12" rx="2" fill="none" stroke="{stroke}" stroke-width="0.8"/>'
            f'<text x="{x + w / 2}" y="{y + 9}" fill="{color}" font-size="7" font-family="{MONO}" '
            f'text-anchor="middle" letter-spacing="0.08em">{label}</text>')


def build(slug, c):
    o = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}" '
         f'role="img" aria-labelledby="{slug}-title {slug}-desc">',
         f'<title id="{slug}-title">Claude Code setup: /mode workflow</title>',
         f'<desc id="{slug}-desc">The /mode command branches into five working modes: research, hack, study, '
         f'project and real; global CLAUDE.md rules apply in every mode, and /recheck with update-all.sh keeps the tools current.</desc>',
         f'<defs><pattern id="{slug}-dots" width="22" height="22" patternUnits="userSpaceOnUse">'
         f'<circle cx="1" cy="1" r="0.9" fill="{c["dots"]}"/></pattern></defs>',
         f'<rect width="100%" height="100%" fill="{c["paper"]}"/>',
         f'<rect width="100%" height="100%" fill="url(#{slug}-dots)" opacity="0.55"/>']

    # connectors first: root drop, bus, child drops
    cx = [X0 + i * (MW + GAP) + MW / 2 for i in range(5)]
    o.append(f'<path d="M 500 88 L 500 {MY}" fill="none" stroke="{c["muted"]}" stroke-width="1"/>')
    o.append(f'<path d="M {cx[0]} {MY} L {cx[0]} 124 L {cx[4]} 124 L {cx[4]} {MY}" fill="none" stroke="{c["muted"]}" stroke-width="1"/>')
    for x in (cx[1], cx[3]):
        o.append(f'<path d="M {x} 124 L {x} {MY}" fill="none" stroke="{c["muted"]}" stroke-width="1"/>')

    # root (focal)
    o.append(f'<rect x="420" y="40" width="160" height="48" rx="6" fill="{c["paper"]}"/>'
             f'<rect x="420" y="40" width="160" height="48" rx="6" fill="{c["tint"]}" stroke="{c["accent"]}" stroke-width="1"/>'
             + tag(428, 48, 28, "CMD", c["accent"], c["accent"]) +
             f'<text x="500" y="72" fill="{c["ink"]}" font-size="14" font-weight="600" font-family="{SANS}" text-anchor="middle">/mode</text>'
             f'<text x="500" y="83" fill="{c["muted"]}" font-size="9" font-family="{MONO}" text-anchor="middle">picker · or /mode &lt;name&gt;</text>')

    # modes
    for i, (name, l1, l2) in enumerate(MODES):
        x = X0 + i * (MW + GAP)
        o.append(f'<rect x="{x}" y="{MY}" width="{MW}" height="{MH}" rx="6" fill="{c["paper"]}"/>'
                 f'<rect x="{x}" y="{MY}" width="{MW}" height="{MH}" rx="6" fill="{c["node"]}" stroke="{c["ink"]}" stroke-width="1"/>'
                 + tag(x + 8, MY + 8, 32, "MODE", c["ink"], c["tag"]) +
                 f'<text x="{x + MW / 2}" y="{MY + 34}" fill="{c["ink"]}" font-size="12" font-weight="600" font-family="{SANS}" text-anchor="middle">{name}</text>'
                 f'<text x="{x + MW / 2}" y="{MY + 47}" fill="{c["muted"]}" font-size="9" font-family="{MONO}" text-anchor="middle">{l1}</text>'
                 f'<text x="{x + MW / 2}" y="{MY + 58}" fill="{c["muted"]}" font-size="9" font-family="{MONO}" text-anchor="middle">{l2}</text>')

    # always-on layer + maintenance
    o.append(f'<text x="{X0}" y="264" fill="{c["soft"]}" font-size="8" font-family="{MONO}" letter-spacing="0.18em">APPLIES IN EVERY MODE</text>')
    bw = 4 * (MW + GAP) - GAP
    o.append(f'<rect x="{X0}" y="272" width="{bw}" height="56" rx="6" fill="{c["paper2"]}" stroke="{c["muted"]}" stroke-width="0.8" stroke-dasharray="5,4"/>'
             f'<text x="{X0 + 16}" y="296" fill="{c["ink"]}" font-size="12" font-weight="600" font-family="{SANS}">CLAUDE.md · global rules</text>'
             f'<text x="{X0 + 16}" y="314" fill="{c["muted"]}" font-size="9" font-family="{MONO}">honesty, no sugarcoating · concise · ask, don\'t assume · opusplan: Opus plans, Sonnet builds</text>')
    mx = X0 + 4 * (MW + GAP)
    o.append(f'<text x="{mx}" y="264" fill="{c["soft"]}" font-size="8" font-family="{MONO}" letter-spacing="0.18em">MAINTENANCE</text>'
             f'<rect x="{mx}" y="272" width="{MW}" height="56" rx="6" fill="{c["paper"]}"/>'
             f'<rect x="{mx}" y="272" width="{MW}" height="56" rx="6" fill="{c["node"]}" stroke="{c["muted"]}" stroke-width="0.8"/>'
             f'<text x="{mx + MW / 2}" y="296" fill="{c["ink"]}" font-size="12" font-weight="600" font-family="{SANS}" text-anchor="middle">/recheck</text>'
             f'<text x="{mx + MW / 2}" y="314" fill="{c["muted"]}" font-size="9" font-family="{MONO}" text-anchor="middle">+ backup/update-all.sh</text>')

    # legend strip
    o.append(f'<line x1="{X0}" y1="360" x2="{W - X0}" y2="360" stroke="{c["rule"]}" stroke-width="0.8"/>'
             f'<text x="{X0}" y="378" fill="{c["muted"]}" font-size="8" font-family="{MONO}" letter-spacing="0.18em">LEGEND</text>')
    items = [("Command · focal", c["tint"], c["accent"], 1, ""),
             ("Mode", c["node"], c["ink"], 1, ""),
             ("Always-on rules", c["paper2"], c["muted"], 0.8, ' stroke-dasharray="3,2"'),
             ("Maintenance", c["node"], c["muted"], 0.8, "")]
    x = X0
    for label, fill, stroke, sw, dash in items:
        o.append(f'<rect x="{x}" y="392" width="14" height="10" rx="2" fill="{fill}" stroke="{stroke}" stroke-width="{sw}"{dash}/>'
                 f'<text x="{x + 20}" y="400" fill="{c["muted"]}" font-size="8.5" font-family="{SANS}">{label}</text>')
        x += 150
    o.append('</svg>')
    return "\n".join(o)


here = Path(__file__).parent
for slug, skin in SKINS.items():
    (here / f"{slug}.svg").write_text(build(slug, skin) + "\n")
    print("wrote", here / f"{slug}.svg")
