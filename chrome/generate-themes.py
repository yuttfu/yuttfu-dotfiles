#!/usr/bin/env python3
"""Generate native Chrome themes from the shared desktop palette; load manually."""
import argparse
import json
import os
from pathlib import Path
import runpy
import tempfile

DESCRIPTION = "Local color adaptation from the shared desktop palette. No scripts or website access."


def render(palette, colors):
    c = colors
    values = {
        'frame': c['mantle'], 'frame_inactive': c['crust'],
        'toolbar': c['surface0'], 'toolbar_text': c['text'],
        'toolbar_button_icon': c['lavender'], 'tab_text': c['text'],
        'tab_background_text': c['subtext0'], 'tab_background_text_inactive': c['overlay0'],
        'background_tab': c['mantle'], 'background_tab_inactive': c['crust'],
        'bookmark_text': c['text'], 'omnibox_background': c['base'],
        'omnibox_text': c['text'], 'ntp_background': c['base'],
        'ntp_text': c['text'], 'ntp_link': c['lavender'], 'ntp_header': c['surface1'],
    }
    return {'manifest_version': 3, 'name': 'Desktop Palette - ' + palette['label'],
            'version': '1.0.0', 'description': DESCRIPTION,
            'theme': {'colors': {k: [int(h[i:i+2], 16) for i in (1, 3, 5)] for k,h in values.items()},
                      'properties': {'ntp_logo_alternate': 1}}}


def main():
    root = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source', type=Path, default=root/'zsh/.config/terminal-themes')
    parser.add_argument('--output', type=Path, default=Path(__file__).resolve().parent/'themes')
    args = parser.parse_args()
    # Reuse the shared palette validation and desktop mapping.
    cli = runpy.run_path(str(args.source.parent.parent/'.local/bin/terminal-theme'))
    palettes = cli['load_palettes'](args.source.parent)
    desktop = runpy.run_path(str(args.source/'desktop.py'))
    outputs = {}
    for name, palette in palettes.items():
        data = render(palette, desktop['desktop_colors'](palette))
        target = (args.output/name/'manifest.json').resolve()
        if target.exists():
            existing = json.loads(target.read_text())
            if existing.get('description') != DESCRIPTION or existing.get('name') != data['name']:
                raise ValueError(f'Refusing to overwrite an unmanaged manifest: {target}')
        outputs[target] = json.dumps(data, ensure_ascii=False, indent=2)+'\n'
    for target, text in outputs.items():
        if target.exists() and target.read_text() == text:
            continue
        target.parent.mkdir(parents=True, exist_ok=True)
        fd, temporary = tempfile.mkstemp(prefix='.theme-', dir=target.parent)
        try:
            with os.fdopen(fd, 'w') as f:
                f.write(text)
            os.chmod(temporary, 0o644)
            os.replace(temporary, target)
        finally:
            if os.path.exists(temporary):
                os.unlink(temporary)
    print(f'Generated {len(outputs)} themes in {args.output}. Load the desired folder in chrome://extensions.')


if __name__ == '__main__':
    main()
