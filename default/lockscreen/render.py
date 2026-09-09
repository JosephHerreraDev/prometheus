#!/usr/bin/env python3
"""Render native hyprlock and QML styling from one Prometheus palette."""
import json
from pathlib import Path
import sys


def render(output: Path):
    source = Path(__file__).parent
    style = json.loads((source / 'style.json').read_text())
    output.mkdir(parents=True, exist_ok=True)
    properties = []
    for key, value in style.items():
        kind = 'string' if isinstance(value, str) else 'real'
        properties.append(f'    readonly property {kind} {key}: {json.dumps(value)}')
    (output / 'Style.qml').write_text('import QtQuick\nQtObject {\n' + '\n'.join(properties) + '\n}\n')
    mapping = {
        'FONT': style['font'],
        'COLOR': 'rgb(' + style['foreground'].lstrip('#') + ')',
        'BACKGROUND_COLOR': 'rgb(' + style['background'].lstrip('#') + ')',
        'CLOCK_SIZE': style['clockSize'], 'DATE_SIZE': style['dateSize'],
        'USER_SIZE': style['userSize'], 'INPUT_WIDTH': style['inputWidth'],
        'INPUT_HEIGHT': style['inputHeight'], 'RADIUS': style['radius'],
        'INPUT_COLOR': 'rgba(' + style['foreground'].lstrip('#') + f"{round(style['inputOpacity'] * 255):02x})",
    }
    template = (source / 'hyprlock.conf.tpl').read_text()
    for key, value in mapping.items():
        template = template.replace('@' + key + '@', str(value))
    (output / 'hyprlock.conf').write_text(template)


if __name__ == '__main__':
    if len(sys.argv) != 2:
        sys.exit('Usage: render.py <output directory>')
    render(Path(sys.argv[1]))
