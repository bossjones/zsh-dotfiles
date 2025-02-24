#!/usr/bin/env python3
# pylint: disable=pointless-string-statement
# pylint: disable=broad-exception-caught
from __future__ import annotations

import argparse
import os
import sys
from typing import Tuple

from PIL import Image, ImageFilter

def create_shadow_overlay_meme(
    source_image_path: str,
    template_image_path: str,
    shadow_offset: Tuple[int, int] = (20, 20),
    shadow_color: Tuple[int, int, int] = (128, 128, 128),
    blur_radius: float = 5,
    shadow_opacity: int = 128,
    scale_factor: float = 1.0,
    position: Tuple[int, int] = (0, 0)
) -> Image.Image:
    """Create a meme by overlaying a shadowed version of source image onto a template.

    Args:
        source_image_path: Path to the image to be converted to shadow.
        template_image_path: Path to the template image to overlay shadow onto.
        shadow_offset: Tuple of (x, y) pixels to offset the shadow. Defaults to (20, 20).
        shadow_color: Tuple of (r, g, b) values for shadow color. Defaults to (128, 128, 128).
        blur_radius: Gaussian blur radius for the shadow. Defaults to 5.
        shadow_opacity: Shadow opacity value (0-255). Defaults to 128.
        scale_factor: Scale factor for the source image. Defaults to 1.0.
        position: Position (x, y) to place the shadow on template. Defaults to (0, 0).

    Returns:
        PIL.Image.Image: The processed template with shadow overlay.
    """
    try:
        # Open and convert images
        source = Image.open(source_image_path).convert("RGBA")
        template = Image.open(template_image_path).convert("RGBA")

        # Scale source image if needed
        if scale_factor != 1.0:
            new_size = (int(source.width * scale_factor), int(source.height * scale_factor))
            source = source.resize(new_size, Image.Resampling.LANCZOS)

        # Create shadow from source
        shadow = source.copy()
        shadow = shadow.convert("L")  # Convert to grayscale
        shadow = shadow.filter(ImageFilter.GaussianBlur(blur_radius))

        # Create colored shadow
        shadow_colored = Image.new("RGBA", shadow.size, shadow_color + (shadow_opacity,))
        shadow.putalpha(shadow_colored.split()[3])

        # Create shadow offset version
        offset_shadow = Image.new("RGBA", shadow.size, (0, 0, 0, 0))
        offset_shadow.paste(shadow, shadow_offset, shadow)

        # Create final composition
        result = template.copy()
        paste_position = (position[0], position[1])
        result.paste(offset_shadow, paste_position, offset_shadow)
        result.paste(source, position, source)

        return result

    except Exception as e:
        print(f"Error processing images: {e}")
        sys.exit(1)

def parse_color(color_str: str) -> Tuple[int, int, int]:
    """Parse a color string into RGB values."""
    try:
        r, g, b = map(int, color_str.split(","))
        if not all(0 <= x <= 255 for x in (r, g, b)):
            raise ValueError("Color values must be between 0 and 255")
        return (r, g, b)
    except Exception:
        raise argparse.ArgumentTypeError(
            "Color must be in format 'r,g,b' with values between 0-255"
        )

def parse_offset(offset_str: str) -> Tuple[int, int]:
    """Parse an offset string into x,y coordinates."""
    try:
        x, y = map(int, offset_str.split(","))
        return (x, y)
    except Exception:
        raise argparse.ArgumentTypeError("Offset must be in format 'x,y'")

def parse_position(pos_str: str) -> Tuple[int, int]:
    """Parse a position string into x,y coordinates."""
    try:
        x, y = map(int, pos_str.split(","))
        return (x, y)
    except Exception:
        raise argparse.ArgumentTypeError("Position must be in format 'x,y'")

def expand_path(path: str) -> str:
    """Expand user and environment variables in path and return absolute path."""
    expanded_path = os.path.expanduser(os.path.expandvars(path))
    return os.path.abspath(expanded_path)

def ensure_directory_exists(file_path: str) -> None:
    """Ensure the directory for the given file path exists."""
    directory = os.path.dirname(file_path)
    if directory and not os.path.exists(directory):
        try:
            os.makedirs(directory)
            print(f"Created directory: {directory}")
        except Exception as e:
            print(f"Error creating directory {directory}: {e}")
            sys.exit(1)

def print_examples() -> None:
    """Print example usage of the script."""
    examples = """# Basic usage
python shadow_meme_overlay.py source.png template.png output.png

# With custom position and scale
python shadow_meme_overlay.py source.png template.png output.png -p 100,100 -s 0.5

# Full customization
python shadow_meme_overlay.py source.png template.png output.png \\
    -p 100,100 -s 0.75 -o 20,20 -c 64,64,64 -b 8.0 -a 180

# Basic usage (using relative paths)
python shadow_meme_overlay.py hand.png pepe_template.png output.png

# With positioning and scaling
python shadow_meme_overlay.py hand.png pepe_template.png output.png -p 100,100 -s 0.5

# With full customization
python shadow_meme_overlay.py hand.png pepe_template.png output.png \
    -p 100,100 -s 0.75 -o 20,20 -c 64,64,64 -b 8.0 -a 180"""
    print(examples)

def main() -> None:
    """Main function to handle command line interface."""
    parser = argparse.ArgumentParser(
        description="Create a meme by overlaying a shadowed image onto a template"
    )

    parser.add_argument(
        "--example",
        action="store_true",
        help="Show example usage of the script",
    )

    parser.add_argument(
        "source_image",
        nargs="?",
        help="Path to the source image to be shadowed",
    )

    parser.add_argument(
        "template_image",
        nargs="?",
        help="Path to the template image",
    )

    parser.add_argument(
        "output_image",
        nargs="?",
        help="Path for the output image",
    )

    parser.add_argument(
        "-p",
        "--position",
        type=parse_position,
        default="0,0",
        help='Position to place shadow on template "x,y" (default: 0,0)',
    )

    parser.add_argument(
        "-s",
        "--scale",
        type=float,
        default=1.0,
        help="Scale factor for source image (default: 1.0)",
    )

    parser.add_argument(
        "-o",
        "--offset",
        type=parse_offset,
        default="20,20",
        help='Shadow offset in format "x,y" (default: 20,20)',
    )

    parser.add_argument(
        "-c",
        "--color",
        type=parse_color,
        default="128,128,128",
        help='Shadow color in format "r,g,b" (default: 128,128,128)',
    )

    parser.add_argument(
        "-b",
        "--blur",
        type=float,
        default=5.0,
        help="Shadow blur radius (default: 5.0)",
    )

    parser.add_argument(
        "-a",
        "--opacity",
        type=int,
        choices=range(0, 256),
        default=128,
        help="Shadow opacity, 0-255 (default: 128)",
    )

    args = parser.parse_args()

    if args.example:
        print_examples()
        sys.exit(0)

    # Check required arguments
    if not all([args.source_image, args.template_image, args.output_image]):
        parser.error("source_image, template_image, and output_image are required unless using --example")

    # Expand paths
    source_path = expand_path(args.source_image)
    template_path = expand_path(args.template_image)
    output_path = expand_path(args.output_image)

    # Check if input files exist
    for path, name in [(source_path, "Source"), (template_path, "Template")]:
        if not os.path.exists(path):
            print(f"Error: {name} file does not exist: {path}")
            sys.exit(1)

    # Ensure output directory exists
    ensure_directory_exists(output_path)

    try:
        result = create_shadow_overlay_meme(
            source_path,
            template_path,
            shadow_offset=args.offset,
            shadow_color=args.color,
            blur_radius=args.blur,
            shadow_opacity=args.opacity,
            scale_factor=args.scale,
            position=args.position
        )

        result.save(output_path)
        print(f"Successfully created shadow meme: {output_path}")

    except Exception as e:
        print(f"Error creating shadow meme: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
