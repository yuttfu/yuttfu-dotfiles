"""Export a shared palette in the Codex theme-share format.

This produces an import string only. It never reads or changes Codex user state.
"""
import json

CODE_THEMES = {
    "jellyfish": "dracula", "aurora-x": "tokyo-night", "poimandres": "nord",
    "mocha-teal": "catppuccin", "outrun-night": "dracula", "synthwave": "dracula",
    "dark-matter": "vscode-plus", "amethyst-dark": "dracula",
}


def render(name, palette):
    ansi = palette["ansi"]
    theme = {
        "accent": palette.get("desktop_accent", ansi[6]),
        "accentSource": "custom",
        "contrast": 60,
        "fonts": {"code": "MesloLGS NF", "ui": None},
        "ink": ansi[15],
        "opaqueWindows": False,
        "semanticColors": {"diffAdded": ansi[2], "diffRemoved": ansi[1], "skill": ansi[5]},
        "surface": palette["background"],
    }
    return "codex-theme-v1:" + json.dumps({
        "codeThemeId": CODE_THEMES.get(name, "codex"), "theme": theme, "variant": "dark",
    }, separators=(",", ":"), ensure_ascii=False)
