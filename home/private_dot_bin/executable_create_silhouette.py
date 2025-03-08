#!/usr/bin/env python3
from __future__ import annotations

import argparse
import os
import sys
from PIL import Image, ImageOps, ImageFilter, ImageEnhance

# def create_silhouette(
#     image_path: str,
#     output_path: str,
#     silhouette_color: tuple[int, int, int] = (0, 0, 0),
#     contrast: float = 1.2
# ) -> None:
#     """
#     Convert an image to a silhouette effect.
#     """
#     try:
#         with Image.open(image_path) as img:
#             # Convert to RGB
#             img = img.convert('RGB')

#             # Enhance contrast to better define edges
#             enhancer = ImageEnhance.Contrast(img)
#             img = enhancer.enhance(contrast)

#             # Convert to grayscale
#             gray = ImageOps.grayscale(img)

#             # Invert grayscale for light backgrounds
#             inverted = ImageOps.invert(gray)

#             # Thresholding to create a binary mask
#             threshold = 128  # Adjust threshold as needed
#             binary_mask = inverted.point(lambda p: 255 if p > threshold else 0)

#             # Create new image with silhouette color
#             silhouette = Image.new('RGBA', img.size, (*silhouette_color, 255))

#             # Apply binary mask to define the silhouette shape
#             for x in range(img.width):
#                 for y in range(img.height):
#                     if binary_mask.getpixel((x, y)) == 255:
#                         silhouette.putpixel((x, y), (*silhouette_color, 255))
#                     else:
#                         silhouette.putpixel((x, y), (255, 255, 255, 0))  # Transparent background

#             # Save the result
#             silhouette.save(output_path, 'PNG')
#             print(f"Created silhouette: {output_path}")

#     except Exception as e:
#         print(f"Error processing image: {e}")
#         raise

def create_silhouette(
    image_path: str,
    output_path: str,
    silhouette_color: tuple[int, int, int] = (0, 0, 0),
    contrast: float = 1.2
) -> None:
    """
    Convert an image to a silhouette effect with a transparent background.
    """
    try:
        with Image.open(image_path) as img:
            # Convert to RGBA for transparency support
            img = img.convert('RGBA')

            # Enhance contrast to better define edges
            enhancer = ImageEnhance.Contrast(img)
            img = enhancer.enhance(contrast)

            # Convert to grayscale for mask creation
            gray = ImageOps.grayscale(img)

            # Thresholding to create a binary mask
            threshold = 128  # Adjust threshold as needed
            binary_mask = gray.point(lambda p: 255 if p > threshold else 0)

            # Create new image with transparent background
            silhouette = Image.new('RGBA', img.size, (0, 0, 0, 0))

            # Apply binary mask and fill subject with silhouette color
            for x in range(img.width):
                for y in range(img.height):
                    if binary_mask.getpixel((x, y)) == 255:
                        silhouette.putpixel((x, y), (*silhouette_color, 255))  # Solid color for subject
                    else:
                        silhouette.putpixel((x, y), (255, 255, 255, 0))  # Transparent background

            # Save the result
            silhouette.save(output_path, 'PNG')
            print(f"Created silhouette: {output_path}")

    except Exception as e:
        print(f"Error processing image: {e}")
        raise


def create_shadow(
    image_path: str,
    output_path: str,
    shadow_color: tuple[int, int, int] = (0, 0, 0),
    blur: float = 5.0,
    opacity: int = 160,
    contrast: float = 1.2
) -> None:
    """
    Convert an image to a realistic shadow.
    """
    try:
        with Image.open(image_path) as img:
            # Convert to RGB first
            img = img.convert('RGB')

            # Enhance contrast to better define edges
            enhancer = ImageEnhance.Contrast(img)
            img = enhancer.enhance(contrast)

            # Convert to grayscale
            gray = ImageOps.grayscale(img)

            # Invert colors if needed (for light backgrounds)
            gray = ImageOps.invert(gray)

            # Apply gaussian blur for soft edges
            blurred = gray.filter(ImageFilter.GaussianBlur(blur))

            # Create new image with shadow color
            shadow = Image.new('RGBA', img.size, (0, 0, 0, 0))

            # Convert grayscale to alpha mask
            for x in range(img.width):
                for y in range(img.height):
                    pixel_value = blurred.getpixel((x, y))
                    alpha = int((255 - pixel_value) * opacity / 255)
                    shadow.putpixel((x, y), shadow_color + (alpha,))

            # Save the result
            shadow.save(output_path, 'PNG')
            print(f"Created shadow: {output_path}")

    except Exception as e:
        print(f"Error processing image: {e}")
        raise

def parse_color(color_str: str) -> tuple[int, int, int]:
    try:
        r, g, b = map(int, color_str.split(","))
        if not all(0 <= x <= 255 for x in (r, g, b)):
            raise ValueError
        return (r, g, b)
    except:
        raise argparse.ArgumentTypeError("Color must be in format 'r,g,b' with values between 0-255")

# def main() -> None:
#     parser = argparse.ArgumentParser(description="Convert an image to a realistic shadow")

#     parser.add_argument("input_image", help="Path to input image")
#     parser.add_argument("output_image", help="Path for output shadow")

#     parser.add_argument(
#         "-c",
#         "--color",
#         type=parse_color,
#         default="0,100,0",
#         help="Shadow color in format 'r,g,b' (default: 0,100,0)"
#     )

#     parser.add_argument(
#         "-b",
#         "--blur",
#         type=float,
#         default=5.0,
#         help="Blur amount (default: 5.0)"
#     )

#     parser.add_argument(
#         "-o",
#         "--opacity",
#         type=int,
#         default=160,
#         choices=range(0, 256),
#         help="Shadow opacity, 0-255 (default: 160)"
#     )

#     parser.add_argument(
#         "-n",
#         "--contrast",
#         type=float,
#         default=1.2,
#         help="Contrast enhancement (default: 1.2)"
#     )

#     args = parser.parse_args()

#     # Expand paths
#     input_path = os.path.expanduser(args.input_image)
#     output_path = os.path.expanduser(args.output_image)

#     # Create output directory if needed
#     os.makedirs(os.path.dirname(output_path) or '.', exist_ok=True)

#     create_shadow(
#         input_path,
#         output_path,
#         args.color,
#         args.blur,
#         args.opacity,
#         args.contrast
#     )

def main() -> None:
    parser = argparse.ArgumentParser(description="Convert an image to a silhouette effect")

    parser.add_argument("input_image", help="Path to input image")
    parser.add_argument("output_image", help="Path for output silhouette")

    parser.add_argument(
        "-c",
        "--color",
        type=parse_color,
        default="0,0,0",
        help="Silhouette color in format 'r,g,b' (default: 0,0,0)"
    )

    parser.add_argument(
        "-n",
        "--contrast",
        type=float,
        default=1.2,
        help="Contrast enhancement (default: 1.2)"
    )

    args = parser.parse_args()

    # Expand paths
    input_path = os.path.expanduser(args.input_image)
    output_path = os.path.expanduser(args.output_image)

    # Create output directory if needed
    os.makedirs(os.path.dirname(output_path) or '.', exist_ok=True)

    create_silhouette(
        input_path,
        output_path,
        args.color,
        args.contrast
    )


if __name__ == "__main__":
    main()
