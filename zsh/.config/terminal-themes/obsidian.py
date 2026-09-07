"""Color-only AnuPpuccin adapter. Vault registration is explicit and optional."""
import colorsys
import json
from pathlib import Path
import sys

MARKER = "/* Managed by terminal-theme; edit terminal-themes/palettes.json instead. */"
SNIPPET = "desktop-current"


def rgb(color):
    return ", ".join(str(int(color[i:i+2], 16)) for i in (1, 3, 5))


def render(name, palette, colors, mix):
    a, c = palette["ansi"], colors
    # Override the palette primitives used by AnuPpuccin, including its cards,
    # headings and rainbow folders. Do not change the theme's layout settings.
    tokens = dict(rosewater=mix(a[1], c["text"], .55), flamingo=a[9], pink=a[13],
                  mauve=a[5], red=a[1], maroon=a[9], peach=a[11], yellow=a[3],
                  green=a[2], teal=a[6], sky=a[14], sapphire=a[4], blue=a[4],
                  lavender=a[12], text=c["text"], subtext1=mix(c["text"], c["base"], .15),
                  subtext0=c["subtext0"], overlay2=mix(c["text"], c["base"], .35),
                  overlay1=mix(c["text"], c["base"], .45), overlay0=c["overlay0"],
                  surface2=mix(c["base"], c["text"], .25), surface1=c["surface1"],
                  surface0=c["surface0"], base=c["base"], mantle=c["mantle"],
                  crust=c["crust"], accent=c["lavender"])
    lines = [MARKER, f"/* Theme: {name}. Disable this snippet to restore your theme colors. */",
             "body.theme-dark {"]
    lines += [f"  --ctp-{key}: {rgb(value)} !important;" for key, value in tokens.items()]
    accent = c["lavender"]
    h, lightness, saturation = colorsys.rgb_to_hls(*(int(accent[i:i+2], 16)/255 for i in (1,3,5)))
    variables = {
        "accent-h": f"{h*360:.2f}", "accent-s": f"{saturation*100:.2f}%", "accent-l": f"{lightness*100:.2f}%",
        "color-accent-hsl": f"{h*360:.2f}, {saturation*100:.2f}%, {lightness*100:.2f}%",
        "color-accent": accent, "color-accent-1": accent, "color-accent-2": mix(accent,c["text"],.15),
        "interactive-accent": accent, "interactive-accent-hover": mix(accent,c["text"],.15),
        "interactive-accent-rgb": rgb(accent), "text-accent": accent, "text-accent-hover": mix(accent,c["text"],.15),
        "text-normal": c["text"], "text-muted": c["subtext0"], "text-faint": c["overlay0"],
        "text-on-accent": c["base"], "text-selection": f"rgba({rgb(accent)}, 0.25)",
        "link-color": accent, "link-color-hover": mix(accent,c["text"],.15),
        "link-external-color": accent, "link-external-color-hover": mix(accent,c["text"],.15),
        "code-normal": c["text"], "code-comment": c["overlay0"], "code-function": a[4],
        "code-keyword": a[5], "code-string": a[2], "code-value": a[3], "code-operator": a[6],
        "code-property": a[6], "code-punctuation": c["subtext0"], "code-important": a[1],
    }
    lines += [f"  --{key}: {value} !important;" for key, value in variables.items()]
    return "\n".join(lines + ["}", ""])


def outputs(config_dir, name, palette, colors, mix):
    registry = config_dir / "terminal-themes/obsidian-vaults.json"
    if not registry.exists():
        return {}
    settings = json.loads(registry.read_text())
    vaults = settings.get("vaults") if isinstance(settings, dict) else None
    if not isinstance(vaults, list) or not all(isinstance(v, str) and v.strip() for v in vaults):
        raise ValueError("obsidian-vaults.json must contain a list of vault paths")
    content = render(name, palette, colors, mix)
    result = {}
    for entry in vaults:
        vault = Path(entry).expanduser()
        if not vault.is_absolute():
            raise ValueError("Obsidian vault paths must be absolute or start with ~/")
        config = (vault / ".obsidian").resolve()
        if not config.is_dir():
            print(f"Obsidian: skipping unavailable vault {vault}", file=sys.stderr)
            continue
        target = (config / "snippets" / f"{SNIPPET}.css").resolve()
        if not target.is_relative_to(config):
            raise ValueError(f"Obsidian snippet must stay inside its vault configuration: {target}")
        result[target] = content
    return result
