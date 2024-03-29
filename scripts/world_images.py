#!/usr/bin/env python3

from pathlib import Path
from typing import Iterator

import PIL.ImageFilter
from PIL import Image  # requires pillow

import convert_world
import palette
from _common import get_workdir, mine


# dimension of sprite in pixels
DIM_SPRITE = 8
# dimension of sprite sheet in sprites
DIM_SHEET = 16
# number of sprites in sheet
LEN_SHEET = 64
WORLD_MAX_X = DIM_SPRITE * convert_world.WORLD_WIDTH

Sprites = list[Image]


class ColorSwap(PIL.ImageFilter.MultibandFilter):
    def __init__(self, mapping: dict[str, str]):
        self.mapping = mapping
        self.mapping_tuples = {
            palette.hexc_to_rgb(k): palette.hexc_to_rgb(v) for k, v in mapping.items()
        }

    def filter(self, image: Image.Image) -> Image.Image:
        width, height = image.size
        for x in range(width):
            for y in range(height):
                coords = (x, y)
                pix = image.getpixel(coords)
                pix = self.mapping_tuples.get(pix, pix)
                image.putpixel(coords, pix)

        return image


def get_sprites(workdir: Path) -> Sprites:
    spritesheet_path = workdir.joinpath('assets/spritesheet.png')
    spritesheet = Image.open(spritesheet_path)

    sprites = []
    for sprn in range(LEN_SHEET):
        left = (sprn % DIM_SHEET) * DIM_SPRITE
        upper = (sprn // DIM_SHEET) * DIM_SPRITE
        spr = spritesheet.crop((
            left,
            upper,
            left + DIM_SPRITE,
            upper + DIM_SPRITE
        ))
        sprites.append(spr)

    return sprites


def make_image(tiles: convert_world.Tiles, sprites: Sprites) -> Image.Image:
    image = Image.new('RGB',
        (
            DIM_SPRITE * convert_world.WORLD_WIDTH,
            DIM_SPRITE * convert_world.WORLD_HEIGHT
        )
    )

    x = 0
    y = 0
    for sprite_at in tiles:
        sprite_id = convert_world.SPRITES_AT[sprite_at]
        sprn = convert_world.SPRITES_P8_R[sprite_id]
        sprite = sprites[sprn]

        image.paste(sprite,
            (
                x,
                y,
                x + DIM_SPRITE,
                y + DIM_SPRITE
            )
        )

        x += DIM_SPRITE
        if x == WORLD_MAX_X:
            y += DIM_SPRITE
            x = 0

    return image


def do_filter(image: Image.Image) -> Image.Image:
    pal_orig = palette.palette_orig[11]
    pal_pico = palette.PICO_BASE_HEX
    mapping = {pal_pico[i]: pal_orig[i] for i in range(len(pal_orig))}
    filter_ = ColorSwap(mapping)

    image = image.filter(filter_)
    return image


def main():
    workdir = get_workdir()
    sprites = get_sprites(workdir)
    outdir = workdir.joinpath('assets/screens')
    outdir.mkdir(exist_ok=True)

    for world in range(1, 8+1):
        for stage in range(1, 4+1):
            world_path = f'datamined/WORLD{world}{stage}.DAT'
            world_bytes = mine(world_path)
            screens_bytes = convert_world.split_screens(world_bytes)

            for screen in range(1, 5+1):
                scr_bytes = screens_bytes[screen]
                tiles = convert_world.join_bytes(scr_bytes)
                image = make_image(tiles, sprites)
                image_path = outdir.joinpath(f'world{world}{stage}-{screen}.png')
                image.save(image_path)


if __name__ == '__main__':
    main()
