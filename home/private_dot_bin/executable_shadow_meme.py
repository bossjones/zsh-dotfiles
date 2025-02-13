#!/usr/bin/env python3
# pylint: disable=pointless-string-statement
# pylint: disable=broad-exception-caught
from __future__ import annotations

import argparse
import os
import sys
from typing import Tuple

from PIL import Image, ImageFilter

"""Command line tool to create meme images with enhanced shadow effects.

This module provides functionality to add customizable shadow effects to images,
making them suitable for meme creation. It supports various shadow parameters
including offset, color, blur radius, and opacity.

Example:
    $ python executable_shadow_meme.py input.png output.png -o 20,20 -c 128,128,128

Note:
    All paths support environment variable expansion and ~ for home directory.
"""


def create_enhanced_shadow_meme(
    base_image_path: str,
    shadow_offset: Tuple[int, int] = (20, 20),
    shadow_color: Tuple[int, int, int] = (128, 128, 128),
    blur_radius: float = 5,
    shadow_opacity: int = 128,
) -> Image.Image:
    """Create a meme image with an enhanced shadow effect.

    Args:
        base_image_path: Path to the input image file.
        shadow_offset: Tuple of (x, y) pixels to offset the shadow. Defaults to (20, 20).
        shadow_color: Tuple of (r, g, b) values for shadow color. Defaults to (128, 128, 128).
        blur_radius: Gaussian blur radius for the shadow. Defaults to 5.
        shadow_opacity: Shadow opacity value (0-255). Defaults to 128.

    Returns:
        PIL.Image.Image: The processed image with shadow effect.

    Raises:
        FileNotFoundError: If the input image file doesn't exist.
        OSError: If there's an error reading the image file.
        SystemExit: If there's an error processing the image.
    """
    try:
        img = Image.open(base_image_path).convert("RGBA")
    except FileNotFoundError as e:
        print(f"Error: Input file not found: {e}")
        sys.exit(1)
    except OSError as e:
        print(f"Error opening image: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"Unexpected error opening image: {e}")
        sys.exit(1)

    # Create shadow
    shadow = img.copy()
    shadow = shadow.convert("L")
    shadow = shadow.filter(ImageFilter.GaussianBlur(blur_radius))

    # Apply shadow color and opacity
    shadow_colored = Image.new("RGBA", shadow.size, shadow_color + (shadow_opacity,))
    shadow.putalpha(shadow_colored.split()[3])

    # Combine images
    new_width = img.width + abs(shadow_offset[0])
    new_height = img.height + abs(shadow_offset[1])
    combined = Image.new("RGBA", (new_width, new_height), (0, 0, 0, 0))

    shadow_pos = (max(shadow_offset[0], 0), max(shadow_offset[1], 0))
    image_pos = (max(-shadow_offset[0], 0), max(-shadow_offset[1], 0))

    combined.paste(shadow, shadow_pos, shadow)
    combined.paste(img, image_pos, img)

    return combined


def parse_color(color_str: str) -> Tuple[int, int, int]:
    """Parse a color string into RGB values.

    Args:
        color_str: String in format 'r,g,b' with values between 0-255.

    Returns:
        Tuple[int, int, int]: A tuple of (red, green, blue) integer values.

    Raises:
        argparse.ArgumentTypeError: If the color string format is invalid or values are out of range.
    """
    try:
        r, g, b = map(int, color_str.split(","))
        if not all(0 <= x <= 255 for x in (r, g, b)):
            raise ValueError("Color values must be between 0 and 255")
        return (r, g, b)
    except ValueError as e:
        raise argparse.ArgumentTypeError(str(e))
    except Exception:
        raise argparse.ArgumentTypeError(
            "Color must be in format 'r,g,b' with values between 0-255"
        )


def parse_offset(offset_str: str) -> Tuple[int, int]:
    """Parse an offset string into x,y coordinates.

    Args:
        offset_str: String in format 'x,y'.

    Returns:
        Tuple[int, int]: A tuple of (x, y) integer values representing pixel offsets.

    Raises:
        argparse.ArgumentTypeError: If the offset string format is invalid or cannot be parsed.
    """
    try:
        x, y = map(int, offset_str.split(","))
        return (x, y)
    except ValueError:
        raise argparse.ArgumentTypeError("Offset values must be integers")
    except Exception:
        raise argparse.ArgumentTypeError("Offset must be in format 'x,y'")


def expand_path(path: str) -> str:
    """Expand user and environment variables in path and return absolute path.

    Args:
        path: Input path that may contain ~ or environment variables.

    Returns:
        str: Absolute path with all variables expanded.

    Example:
        >>> expand_path("~/images/meme.png")
        '/home/user/images/meme.png'
    """
    expanded_path = os.path.expanduser(os.path.expandvars(path))
    return os.path.abspath(expanded_path)


def ensure_directory_exists(file_path: str) -> None:
    """Ensure the directory for the given file path exists.

    Creates all necessary parent directories for the given file path if they don't exist.

    Args:
        file_path: Path to a file for which the directory should exist.

    Raises:
        SystemExit: If there's an error creating the directory (e.g., permissions).
        OSError: If directory creation fails due to filesystem errors.
    """
    directory = os.path.dirname(file_path)
    if directory and not os.path.exists(directory):
        try:
            os.makedirs(directory)
            print(f"Created directory: {directory}")
        except OSError as e:
            print(f"Error creating directory {directory}: {e}")
            sys.exit(1)


def main() -> None:
    """Process command line arguments and create shadow meme images.

    This function handles the command-line interface for the shadow meme creator.
    It parses arguments, validates input/output paths, and orchestrates the
    image processing.

    Raises:
        SystemExit: If there are errors with input/output paths or image processing.
    """
    parser = argparse.ArgumentParser(
        description="Create a meme image with shadow effect"
    )

    parser.add_argument(
        "input_image", help="Path to the input image (supports ~ for home directory)"
    )

    parser.add_argument(
        "output_image", help="Path for the output image (supports ~ for home directory)"
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

    # Expand paths
    input_path = expand_path(args.input_image)
    output_path = expand_path(args.output_image)

    # Check if input file exists
    if not os.path.exists(input_path):
        print(f"Error: Input file does not exist: {input_path}")
        sys.exit(1)

    # Ensure output directory exists
    ensure_directory_exists(output_path)

    try:
        result = create_enhanced_shadow_meme(
            input_path,
            shadow_offset=args.offset,
            shadow_color=args.color,
            blur_radius=args.blur,
            shadow_opacity=args.opacity,
        )

        result.save(output_path)
        print(f"Successfully created shadow meme: {output_path}")

    except OSError as e:
        print(f"Error saving output image: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"Error creating shadow meme: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
