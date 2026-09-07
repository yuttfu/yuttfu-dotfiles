"""Update VS Code's shared color theme without rewriting other JSONC settings."""
import json
from pathlib import Path
import re

THEMES = {
    "jellyfish": "JellyFish", "aurora-x": "Aurora X",
    "poimandres": "poimandres", "mocha-teal": "Catppuccin Mocha",
    "outrun-night": "Outrun Night", "synthwave": "Synthwave x Fluoromachine",
    "dark-matter": "Dark Matter (by Particle)", "amethyst-dark": "Amethyst Dark",
}
COLOR = "workbench.colorTheme"
SHARED = "workbench.settings.applyToAllProfiles"
TOKEN = re.compile(r'\s+|//[^\r\n]*|/\*[\s\S]*?\*/|"(?:\\[^\r\n]|[^"\\\r\n])*"|true|false|null|-?(?:0|[1-9]\d*)(?:\.\d+)?(?:[eE][+-]?\d+)?|[{}\[\],:]')


def parse(text):
    tokens, clean, pos = [], list(text), 0
    while pos < len(text):
        match = TOKEN.match(text, pos)
        if not match:
            raise ValueError("Invalid VS Code settings JSONC")
        value = match.group()
        if value.isspace() or value.startswith(("//", "/*")):
            for i in range(pos, match.end()):
                if clean[i] not in '\r\n': clean[i] = ' '
        else:
            tokens.append((value, pos, match.end()))
        pos = match.end()
    for a, b in zip(tokens, tokens[1:]):
        if a[0] == ',' and b[0] in (']', '}'): clean[a[1]] = ' '
    def unique(pairs):
        result = {}
        for key, value in pairs:
            if key in result: raise ValueError("Duplicate VS Code settings key")
            result[key] = value
        return result
    data = json.loads(''.join(clean), object_pairs_hook=unique)
    if not isinstance(data, dict): raise ValueError("VS Code settings must be an object")
    spans, depth = {}, 0
    for i, token in enumerate(tokens):
        value = token[0]
        if depth == 1 and value.startswith('"') and tokens[i+1][0] == ':':
            start = i + 2
            end, nested = start, 0
            while True:
                v = tokens[end][0]
                if v in ('[', '{'): nested += 1
                elif v in (']', '}'): nested -= 1
                if nested == 0: break
                end += 1
            spans[json.loads(value)] = (start, end)
        if value in ('{', '['): depth += 1
        elif value in ('}', ']'): depth -= 1
    return data, tokens, spans


def render(text, theme, share=True):
    data, tokens, spans = parse(text)
    shared = data.get(SHARED, [])
    if not isinstance(shared, list) or not all(isinstance(v, str) for v in shared):
        raise ValueError("VS Code shared settings must be a string array")
    edits, additions = [], {}
    if COLOR in spans:
        a, b = spans[COLOR]
        if data[COLOR] != theme:
            edits.append((tokens[a][1], tokens[b][2], json.dumps(theme)))
    else:
        additions[COLOR] = theme
    if share and COLOR not in shared:
        if SHARED in spans:
            a, b = spans[SHARED]
            # Add after the final element/comma, keeping comments and whitespace intact.
            previous = tokens[b-1]
            suffix = json.dumps(COLOR)
            insertion = (' ' if previous[0] == ',' else ', ') if shared else ''
            edits.append((previous[2], previous[2], insertion + suffix))
        else:
            additions[SHARED] = [COLOR]
    if additions:
        previous = tokens[-2]
        prefix = '' if previous[0] in ('{', ',') else ','
        newline = '\r\n' if '\r\n' in text else '\n'
        insertion = prefix + newline + (',' + newline).join(
            '  ' + json.dumps(k) + ': ' + json.dumps(v) for k, v in additions.items())
        edits.append((previous[2], previous[2], insertion))
    result = text
    for a, b, replacement in sorted(edits, reverse=True):
        result = result[:a] + replacement + result[b:]
    actual, _, _ = parse(result)
    expected = dict(data, **{COLOR: theme})
    if share:
        expected[SHARED] = shared if COLOR in shared else shared + [COLOR]
    if actual != expected: raise ValueError("VS Code settings update failed validation")
    return result


def prepare(config_dir, name):
    registry = config_dir / 'terminal-themes/vscode.json'
    if not registry.exists(): return {}
    config = json.loads(registry.read_text())
    if not isinstance(config, dict) or not isinstance(config.get('enabled', False), bool):
        raise ValueError("VS Code registration requires a boolean enabled setting")
    if not config.get('enabled', False): return {}
    if not isinstance(config.get('settings'), str):
        raise ValueError("VS Code registration requires a settings path")
    target = Path(config['settings']).expanduser()
    if not target.is_absolute() or target.name != 'settings.json':
        raise ValueError("VS Code settings path must be an absolute settings.json path")
    target = target.resolve()
    if not target.is_file():
        raise ValueError("VS Code settings file is missing; configure terminal-themes/vscode.json")
    targets = {target: True}
    if config.get('profiles') is not None:
        if not isinstance(config['profiles'], str):
            raise ValueError("VS Code profiles path must be a string")
        profiles = Path(config['profiles']).expanduser()
        if not profiles.is_absolute():
            raise ValueError("VS Code profiles path must be absolute")
        # Discover existing profile files on every selection, including new Profiles.
        for path in sorted(profiles.glob('*/settings.json')):
            resolved = path.resolve()
            if not resolved.is_relative_to(profiles.resolve()):
                raise ValueError("VS Code profile settings point outside the registered directory")
            targets.setdefault(resolved, False)
    updates = {}
    for path, shared in targets.items():
        with path.open(newline='') as handle: before = handle.read()
        updates[path] = (before, render(before, THEMES[name], share=shared))
    return updates
