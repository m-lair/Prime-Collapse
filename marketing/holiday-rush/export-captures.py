#!/usr/bin/env python3
"""Export App Store event media by cropping actual game screenshots with CoreGraphics."""
import argparse
import json
from pathlib import Path
import subprocess


def pixels(path):
    output = subprocess.check_output(['sips', '-g', 'pixelWidth', '-g', 'pixelHeight', str(path)], text=True)
    values = {}
    for line in output.splitlines():
        key, _, value = line.strip().partition(':')
        if key in ('pixelWidth', 'pixelHeight'):
            values[key] = int(value)
    return values['pixelWidth'], values['pixelHeight']


def export(source, target, ratio, minimum, maximum, top=0):
    width, height = pixels(source)
    if not 0 <= top < height:
        raise ValueError('Top crop must be within the source image')
    unit = min(width // ratio[0], (height - top) // ratio[1], maximum[0] // ratio[0], maximum[1] // ratio[1])
    crop = (ratio[0] * unit, ratio[1] * unit)
    if crop[0] < minimum[0] or crop[1] < minimum[1]:
        raise ValueError(f'{source}: {width}x{height} is too small for {target.name}; capture at native resolution')
    offset_x = (width - crop[0]) // 2
    subprocess.run(['swift', str(Path(__file__).with_name('crop-capture.swift')), str(source), str(target),
                    str(crop[0]), str(crop[1]), str(offset_x), str(top)], check=True, capture_output=True)
    if pixels(target) != crop:
        raise ValueError(f'Unexpected export dimensions: {target}')
    return {'source': str(source.resolve()), 'output': target.name, 'pixels': list(crop),
            'cropOrigin': [offset_x, top],
            'transformation': 'native screenshot crop and PNG encoding only; no artwork or upscaling'}


parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--landscape', type=Path, required=True)
parser.add_argument('--portrait', type=Path, required=True)
parser.add_argument('--portrait-top', type=int, default=0, help='Native pixels to exclude above portrait/social content')
args = parser.parse_args()
folder = Path(__file__).resolve().parent
outputs = [export(args.landscape, folder / 'event-card.png', (16, 9), (1920, 1080), (3840, 2160)),
           export(args.portrait, folder / 'event-detail.png', (9, 16), (1080, 1920), (2160, 3840), args.portrait_top),
           export(args.portrait, folder / 'social-capture.png', (1, 1), (1080, 1080), (2160, 2160), args.portrait_top)]
(folder / 'capture-provenance.json').write_text(json.dumps({'assets': outputs}, indent=2) + '\n')
print(json.dumps(outputs, indent=2))
