"""Generate native launcher assets from the original PNG (requires ImageMagick)."""

import json
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / 'assets/images/trebino_icon.png'
RES = ROOT / 'android/app/src/main/res'
IOS = ROOT / 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
BACKGROUND = '#FFFBF2'


def render(destination, size, artwork_size, background):
    destination.parent.mkdir(parents=True, exist_ok=True)
    command = [
        'magick', str(SOURCE), '-resize', f'{artwork_size}x{artwork_size}',
        '-gravity', 'center', '-background', background,
        '-extent', f'{size}x{size}',
    ]
    if background != 'none':
        command += ['-alpha', 'remove', '-alpha', 'off']
    subprocess.run([*command, str(destination)], check=True)


for density, scale in [('mdpi', 1), ('hdpi', 1.5), ('xhdpi', 2), ('xxhdpi', 3), ('xxxhdpi', 4)]:
    render(RES / f'mipmap-{density}/ic_launcher.png', round(48 * scale), round(38 * scale), BACKGROUND)
    # Keep the rectangular artwork inside the adaptive icon safe zone.
    render(RES / f'mipmap-{density}/ic_launcher_foreground.png', round(108 * scale), round(56 * scale), 'none')

adaptive = RES / 'mipmap-anydpi-v26/ic_launcher.xml'
adaptive.parent.mkdir(parents=True, exist_ok=True)
adaptive.write_text('''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
</adaptive-icon>
''')
(RES / 'values/ic_launcher_colors.xml').write_text(f'''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">{BACKGROUND}</color>
</resources>
''')

for entry in json.loads((IOS / 'Contents.json').read_text())['images']:
    size = round(float(entry['size'].split('x')[0]) * float(entry['scale'].removesuffix('x')))
    render(IOS / entry['filename'], size, round(size * 0.8), BACKGROUND)

print('Generated Android legacy/adaptive and iOS app icons.')
