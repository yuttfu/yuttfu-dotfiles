"""Generate a consistent desktop palette and apply it through public app CLIs."""
import fcntl
import json
import os
import runpy
from pathlib import Path
import shutil
import subprocess
import tempfile

MARKER = "# Managed by terminal-theme; edit terminal-themes/palettes.json instead."


def mix(first, second, ratio):
    values = [round(int(first[i:i+2], 16) * (1-ratio) + int(second[i:i+2], 16) * ratio)
              for i in (1, 3, 5)]
    return "#" + "".join(f"{v:02x}" for v in values)


def desktop_colors(palette):
    ansi = palette["ansi"]
    base, text = palette["background"], ansi[15]
    accent = palette.get("desktop_accent", ansi[6])
    return dict(base=base, mantle=mix(base, "#000000", .18), crust=ansi[0], text=text,
                subtext0=mix(text, base, .25), overlay0=ansi[8],
                surface0=mix(base, text, .08), surface1=mix(base, text, .18),
                lavender=accent, mauve=ansi[5], teal=ansi[6], green=ansi[2],
                yellow=ansi[3], peach=ansi[3], red=ansi[1],
                active_border=accent, inactive_border=mix(base, accent, .38))


def bundle(config_dir, name, palette, palettes, ghostty_content):
    colors = desktop_colors(palette)
    quote = lambda value: json.dumps(value, ensure_ascii=False)
    lua = ["-- " + MARKER[2:], "return {", f"  id = {quote(name)},",
           f"  label = {quote(palette.get('short_label', palette['label']))},", "  colors = {"]
    lua += [f"    {key} = 0xff{value[1:]}," for key, value in colors.items()]
    lua += [f"    bar_bg = 0xe6{colors['base'][1:]},", "    transparent = 0x00000000,", "  },", "  themes = {"]
    for key, value in palettes.items():
        swatch = desktop_colors(value)
        lua.append(f"    {{ id = {quote(key)}, label = {quote(value['label'])}, "
                   f"accent = 0xff{swatch['lavender'][1:]}, background = 0xff{swatch['base'][1:]} }},")
    lua += ["  },", "}"]
    shell = (MARKER + "\n" + f"BORDER_ACTIVE=0xff{colors['active_border'][1:]}\n"
             + f"BORDER_INACTIVE=0xff{colors['inactive_border'][1:]}\n")
    calendar = dict(managed_by="terminal-theme", theme=name, colors=colors)
    outputs = {
        (config_dir / "ghostty/themes/terminal-current").resolve(): ghostty_content,
        (config_dir / "sketchybar/desktop-theme.lua").resolve(): "\n".join(lua) + "\n",
        (config_dir / "borders/theme-colors.sh").resolve(): shell,
        (config_dir / "terminal-themes/calendar.json").resolve(): json.dumps(calendar, indent=2) + "\n",
    }

    obsidian = runpy.run_path(str(Path(__file__).with_name("obsidian.py")))
    outputs.update(obsidian["outputs"](config_dir, name, palette, colors, mix))
    return outputs

def is_managed(content):
    if content.startswith("/* " + MARKER[2:] + " */\n"):
        return True
    if content.startswith(MARKER + "\n") or content.startswith("-- " + MARKER[2:] + "\n"):
        return True
    try:
        return json.loads(content).get("managed_by") == "terminal-theme"
    except (ValueError, AttributeError):
        return False


def atomic_write(target, content):
    descriptor, temporary = tempfile.mkstemp(prefix=".theme-write-", dir=target.parent)
    try:
        with os.fdopen(descriptor, "w") as handle:
            handle.write(content)
            handle.flush()
            os.fsync(handle.fileno())
        os.chmod(temporary, 0o644)
        os.replace(temporary, target)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def apply_bundle(config_dir, outputs):
    lock_dir = (config_dir / "terminal-themes").resolve()
    lock_dir.mkdir(parents=True, exist_ok=True)
    with (lock_dir / ".theme.lock").open("a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        before = {}
        for target in outputs:
            before[target] = target.read_text() if target.exists() else None
            if before[target] is not None and not is_managed(before[target]):
                raise ValueError(f"Refusing to overwrite an unmanaged file: {target}")
        written = []
        try:
            for target, content in outputs.items():
                if before[target] == content:
                    continue
                target.parent.mkdir(parents=True, exist_ok=True)
                atomic_write(target, content)
                written.append(target)
        except OSError:
            for target in reversed(written):
                if before[target] is None:
                    target.unlink()
                else:
                    atomic_write(target, before[target])
            raise


def refresh_desktop(config_dir):
    env = dict(os.environ, XDG_CONFIG_HOME=str(config_dir),
               PATH="/opt/homebrew/bin:/usr/local/bin:" + os.environ.get("PATH", "/usr/bin:/bin"))
    borders_config = config_dir / "borders/bordersrc"
    if borders_config.is_file():
        result = subprocess.run(["/bin/bash", str(borders_config)], text=True, capture_output=True, timeout=10, env=env)
        if result.returncode:
            print("Borders refresh failed; theme files were saved.")
    sketchybar = shutil.which("sketchybar", path=env["PATH"])
    if sketchybar:
        result = subprocess.run([sketchybar, "--trigger", "desktop_theme_changed"], text=True, capture_output=True, timeout=10, env=env)
        if result.returncode:
            print("SketchyBar refresh failed; theme files were saved.")
