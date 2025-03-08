#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script to detect objects or tweet content in images and draw bounding boxes.

This script uses Google's Generative AI (Gemini) to analyze images and:
1. Detect tweet components (profile picture, username, content) and draw a bounding box
2. Detect general objects in images and draw labeled bounding boxes for each

The script supports command-line arguments for customizing detection mode, input/output paths,
and appearance of the bounding boxes.
"""
import google.generativeai as genai
import PIL.Image
import PIL.ImageDraw
import io
import os
import json
import argparse
import sys
import re
import functools
from typing import Dict, List, Union, Optional, Any, Tuple, Set, Callable, TypeVar, cast
import logging
from pydantic import SecretStr
from pydantic_settings import BaseSettings, SettingsConfigDict
from pathlib import Path
from tenacity import (
    retry,
    stop_after_attempt,
    wait_exponential,
    retry_if_exception_type,
    before_sleep_log,
    RetryCallState
)


# Setup logging
logger = logging.getLogger('bboxes')

# Define a custom exception for Gemini API errors
class GeminiAPIError(Exception):
    """Exception raised for errors in the Gemini API."""
    pass

class Settings(BaseSettings):
    """
    Application settings using pydantic for validation and secure handling of secrets.

    Attributes:
        GEMINI_API_KEY: Google Gemini API key stored as a SecretStr for security.
        GEMINI_MODEL: The Gemini model to use for image processing.
        GEMINI_TEMPERATURE: Temperature setting for deterministic outputs (0.0-1.0).
            Lower values (closer to 0.0) produce more deterministic results.
            Higher values (closer to 1.0) produce more diverse results.
            Default is 0.0 for complete determinism.
        GEMINI_MAX_RETRIES: Maximum number of retry attempts for Gemini API calls.
        GEMINI_MIN_WAIT: Minimum wait time between retries in seconds.
        GEMINI_MAX_WAIT: Maximum wait time between retries in seconds.
    """
    GEMINI_API_KEY: SecretStr
    GEMINI_MODEL: str = 'gemini-2.0-flash'
    GEMINI_TEMPERATURE: float = 0.0  # Default to deterministic (0.0)
    GEMINI_MAX_RETRIES: int = 3  # Default to 3 retry attempts
    GEMINI_MIN_WAIT: float = 2.0  # Default minimum wait time in seconds
    GEMINI_MAX_WAIT: float = 10.0  # Default maximum wait time in seconds

    # Use SettingsConfigDict instead of Config inner class
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="allow"  # Allow extra fields in the settings
    )

def setup_logging(verbose: bool = False) -> None:
    """
    Configure logging based on the verbose flag.

    Args:
        verbose: If True, enables DEBUG level logging. Otherwise, uses INFO level.
    """
    # Set log level based on verbose flag
    log_level = logging.DEBUG if verbose else logging.INFO

    # Configure the root logger
    logging.basicConfig(
        level=log_level,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S'
    )

    # Set our logger's level
    logger.setLevel(log_level)

    logger.debug("Debug logging enabled")
    logger.info("Logging initialized")


# Load settings with API key
settings = Settings()

# Define the retry mechanism for Gemini API calls
def gemini_retry(
    max_retries: Optional[int] = None,
    min_wait: Optional[float] = None,
    max_wait: Optional[float] = None
) -> Callable[[Callable[..., Any]], Callable[..., Any]]:
    """
    Retry decorator specifically for Gemini API calls.

    Args:
        max_retries: Maximum number of retry attempts. If None, uses settings.GEMINI_MAX_RETRIES.
        min_wait: Minimum wait time between retries in seconds. If None, uses settings.GEMINI_MIN_WAIT.
        max_wait: Maximum wait time between retries in seconds. If None, uses settings.GEMINI_MAX_WAIT.

    Returns:
        A decorator function that can be applied to functions making Gemini API calls.
    """
    # Use settings values if not explicitly provided
    _max_retries = max_retries if max_retries is not None else settings.GEMINI_MAX_RETRIES
    _min_wait = min_wait if min_wait is not None else settings.GEMINI_MIN_WAIT
    _max_wait = max_wait if max_wait is not None else settings.GEMINI_MAX_WAIT

    # Define the before sleep function for logging
    def _before_sleep(retry_state: RetryCallState) -> None:
        exception = retry_state.outcome.exception() if retry_state.outcome and retry_state.outcome.failed else None
        exception_name = exception.__class__.__name__ if exception else "Unknown error"

        logger.warning(
            f"Gemini API call failed with {exception_name}. "
            f"Retrying in {retry_state.next_action.sleep:.2f} seconds... "
            f"(Attempt {retry_state.attempt_number}/{_max_retries})"
        )

        # Log the full exception details at debug level
        if exception:
            logger.debug(f"Exception details: {str(exception)}")

    # Create the retry decorator
    return retry(
        reraise=True,  # Re-raise the last exception if all retries fail
        stop=stop_after_attempt(_max_retries),
        wait=wait_exponential(multiplier=1, min=_min_wait, max=_max_wait),
        retry=(
            retry_if_exception_type(ConnectionError) |
            retry_if_exception_type(TimeoutError) |
            retry_if_exception_type(GeminiAPIError) |
            retry_if_exception_type(Exception)
        ),
        before_sleep=_before_sleep,
    )

# Add this function to wrap the Gemini API call
@gemini_retry()
def generate_gemini_content(
    model: genai.GenerativeModel,
    prompt_parts: List[Union[Dict[str, Union[str, bytes]], str]]
) -> Any:
    """
    Make a call to the Gemini API with retry mechanism.

    Args:
        model: The Gemini model instance
        prompt_parts: The prompt parts to send to the model

    Returns:
        The response from the Gemini model

    Raises:
        GeminiAPIError: If there's an error in the Gemini API call
    """
    try:
        response = model.generate_content(prompt_parts)
        response.resolve()
        return response
    except Exception as e:
        # Wrap the original exception in our custom exception
        raise GeminiAPIError(f"Error in Gemini API call: {str(e)}") from e


# Configure Gemini with the API key from settings
try:
    genai.configure(api_key=settings.GEMINI_API_KEY.get_secret_value())
    logger.debug("Gemini API configured successfully")
except Exception as e:
    logger.error(f"Failed to configure Gemini API: {e}")
    print(f"Error: Failed to configure Gemini API. Please check your API key. Error: {e}")
    sys.exit(1)

def resolve_path(path: str) -> str:
    """
    Resolves a path string, handling relative paths, home directory expansion, etc.

    Expands common path formats:
    - Relative paths (./image.jpg, ../image.jpg)
    - Home directory paths (~/image.jpg)
    - Absolute paths (/path/to/image.jpg)

    Args:
        path: A file path string that may contain path shortcuts

    Returns:
        str: The resolved absolute path
    """
    # Expand user directory (handles ~ at the beginning of the path)
    expanded_path = os.path.expanduser(path)

    # Get the absolute path to resolve any relative paths like ./ or ../
    absolute_path = os.path.abspath(expanded_path)

    return absolute_path

def resize_image_with_background(
    image: PIL.Image.Image,
    output_path: str
) -> None:
    """
    Resize an image to 1080x1350 while preserving aspect ratio, centered on a background of its primary color.

    Args:
        image: The PIL Image object to resize
        output_path: Path to save the resized image. Will be modified to include "_larger" before the extension.

    Returns:
        None
    """
    # Create output filename with _larger suffix
    output_dir = os.path.dirname(output_path)
    output_basename = os.path.basename(output_path)
    output_name, output_ext = os.path.splitext(output_basename)
    larger_output_path = os.path.join(output_dir, f"{output_name}_larger{output_ext}")

    logger.debug(f"Will save resized image as: {larger_output_path}")

    # Get primary color (pixel at top-left corner)
    primary_color = image.getpixel((0, 0))
    logger.debug(f"Primary color from top-left pixel: {primary_color}")

    # Target dimensions
    target_width, target_height = 1080, 1350

    # Create new image with primary color background
    background = PIL.Image.new('RGB', (target_width, target_height), primary_color)

    # Calculate resize dimensions while preserving aspect ratio
    img_width, img_height = image.size
    aspect_ratio = img_width / img_height

    if aspect_ratio > (target_width / target_height):  # Image is wider
        new_width = target_width
        new_height = int(new_width / aspect_ratio)
    else:  # Image is taller
        new_height = target_height
        new_width = int(new_height * aspect_ratio)

    logger.debug(f"Resizing from {img_width}x{img_height} to {new_width}x{new_height} to preserve aspect ratio")

    # Resize image
    resized_img = image.resize((new_width, new_height), PIL.Image.Resampling.LANCZOS)

    # Calculate position to paste (center)
    paste_x = (target_width - new_width) // 2
    paste_y = (target_height - new_height) // 2

    # Paste resized image onto background
    background.paste(resized_img, (paste_x, paste_y))

    # Save the result with high quality
    background.save(larger_output_path, quality=92)
    logger.info(f"Resized image saved to {larger_output_path}")
    print(f"Resized image saved to {larger_output_path}")

def is_valid_image(file_path: str) -> bool:
    """
    Check if a file is a valid image that can be processed.

    Args:
        file_path: Path to the file to check

    Returns:
        bool: True if the file is a valid image, False otherwise
    """
    # Skip hidden files
    if os.path.basename(file_path).startswith('.'):
        return False

    # Valid image extensions
    valid_extensions: Set[str] = {'.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'}

    # Check file extension
    file_ext = os.path.splitext(file_path)[1].lower()
    if file_ext not in valid_extensions:
        return False

    # Try to open the file as an image
    try:
        with PIL.Image.open(file_path) as img:
            img.verify()  # Verify it's an image
        return True
    except Exception:
        logger.debug(f"File {file_path} is not a valid image")
        return False

def process_path(
    path: str,
    output_path: Optional[str] = None,
    mode: str = "tweet",
    box_color: str = "red",
    box_width: int = 4,
    label: Optional[str] = None,
    autocrop: bool = False,
    crop_percent: float = 100.0,
    resize: bool = False,
    temperature: float = settings.GEMINI_TEMPERATURE
) -> int:
    """
    Process a path which can be either a file or directory.

    Args:
        path: Path to process (file or directory)
        output_path: Path for the output file(s). If None, default naming is used.
        mode: Detection mode ('tweet' or 'general')
        box_color: Color of the bounding box
        box_width: Width of the bounding box line
        label: Custom label for the bounding box
        autocrop: If True, crop the image to the detected area
        crop_percent: Percentage of tweet height to include when cropping
        resize: If True, resize the cropped image to 1080x1350
        temperature: Temperature setting for the Gemini model (0.0-1.0).
                    Defaults to settings.GEMINI_TEMPERATURE (deterministic).

    Returns:
        int: 0 for success, non-zero for failure
    """
    path_obj = Path(path)
    success_count = 0
    failure_count = 0

    if path_obj.is_file():
        # Process a single file
        if is_valid_image(str(path_obj)):
            result = process_single_image(
                str(path_obj), output_path, mode, box_color,
                box_width, label, autocrop, crop_percent, resize, temperature
            )
            return 0 if result else 1
        else:
            logger.error(f"Not a valid image file: {path}")
            print(f"Error: Not a valid image file: {path}")
            return 1

    elif path_obj.is_dir():
        # Process all image files in the directory
        logger.info(f"Processing all images in directory: {path}")
        print(f"Processing all images in directory: {path}")

        for item in path_obj.glob('*'):
            if item.is_file() and is_valid_image(str(item)):
                # For directories, we need to generate output paths for each file
                if output_path:
                    # If explicit output directory is provided, use it
                    output_dir = Path(output_path)
                    if not output_dir.exists():
                        output_dir.mkdir(parents=True, exist_ok=True)

                    # Create output filename based on input filename with suffix
                    input_name, input_ext = os.path.splitext(item.name)
                    suffix = "_cropped" if autocrop else "_bbox"
                    output_filename = f"{input_name}{suffix}{input_ext}"
                    file_output_path = str(output_dir / output_filename)
                else:
                    # Generate output path based on input file
                    input_name, input_ext = os.path.splitext(item.name)
                    suffix = "_cropped" if autocrop else "_bbox"
                    output_filename = f"{input_name}{suffix}{input_ext}"
                    file_output_path = str(item.parent / output_filename)

                logger.info(f"Processing image: {item.name}")
                print(f"Processing image: {item.name}")

                result = process_single_image(
                    str(item), file_output_path, mode, box_color,
                    box_width, label, autocrop, crop_percent, resize, temperature
                )

                if result:
                    success_count += 1
                else:
                    failure_count += 1

        logger.info(f"Processing completed. Successful: {success_count}, Failed: {failure_count}")
        print(f"Processing completed. Successful: {success_count}, Failed: {failure_count}")

        return 0 if failure_count == 0 else 1
    else:
        logger.error(f"Path does not exist: {path}")
        print(f"Error: Path does not exist: {path}")
        return 1

def process_single_image(
    image_path: str,
    output_path: str,
    mode: str = "tweet",
    box_color: str = "red",
    box_width: int = 4,
    label: Optional[str] = None,
    autocrop: bool = False,
    crop_percent: float = 100.0,
    resize: bool = False,
    temperature: float = settings.GEMINI_TEMPERATURE
) -> bool:
    """
    Process a single image file.

    Args:
        image_path: Path to the input image file
        output_path: Path to save the output image with bounding box
        mode: Detection mode ('tweet' or 'general')
        box_color: Color of the bounding box (name or hex code)
        box_width: Width of the bounding box line
        label: Custom label for the bounding box
        autocrop: If True, crop the image to the detected area
        crop_percent: Percentage of tweet height to include when cropping
        resize: If True, resize the cropped image to 1080x1350
        temperature: Temperature setting for the Gemini model (0.0-1.0).
                    Defaults to settings.GEMINI_TEMPERATURE (deterministic).

    Returns:
        bool: True if processing succeeded, False otherwise
    """
    try:
        if mode == "tweet":
            logger.info(f"Using tweet content detection mode for {image_path}")
            detect_tweet_content(
                image_path,
                output_path,
                box_color=box_color,
                box_width=box_width,
                label=label,
                autocrop=autocrop,
                crop_percent=crop_percent,
                resize=resize,
                temperature=temperature
            )
        else:  # general mode
            logger.info(f"Using general object detection mode for {image_path}")
            detect_objects_and_draw_boxes(
                image_path,
                output_path,
                box_color=box_color,
                box_width=box_width,
                autocrop=autocrop,
                resize=resize,
                temperature=temperature
            )
        logger.info(f"Successfully processed: {image_path}")
        return True
    except Exception as e:
        logger.exception(f"Error processing image {image_path}: {e}")
        print(f"Error processing image {image_path}: {e}")
        return False

def parse_args() -> argparse.Namespace:
    """
    Parse command line arguments for the bounding box script.

    Returns:
        argparse.Namespace: The parsed command line arguments.
    """
    # Create examples for the help text
    examples = """
Examples:
    # Basic usage with default parameters (tweet mode)
    # Output will be saved as input_filename_bbox.ext
    python bboxes.py --image-path "my_tweet.jpg"

    # Process all images in a directory
    python bboxes.py --image-path "path/to/image/directory"

    # Process directory with custom output directory
    python bboxes.py --image-path "input/directory" --output-path "output/directory"

    # Specify an image path and output
    python bboxes.py --image-path "my_tweet.jpg" --output-path "result.jpg"

    # Use general object detection mode
    python bboxes.py --mode "general" --image-path "photo.jpg"

    # Customize the bounding box
    python bboxes.py --image-path "tweet.png" --box-color "blue" --box-width 5 --label "Twitter Post"

    # Crop to the detected area instead of drawing a box
    python bboxes.py --image-path "tweet.jpg" --autocrop

    # Crop with custom percentage (to fine-tune where the bottom crop occurs)
    python bboxes.py --image-path "tweet.jpg" --autocrop --crop-percent 90.0

    # Crop and resize to 1080x1350 with primary color background
    python bboxes.py --image-path "tweet.jpg" --autocrop --resize

    # Override the default deterministic temperature setting (0.0)
    python bboxes.py --image-path "tweet.jpg" --temperature 0.2

    # Enable debug logging
    python bboxes.py --verbose --image-path "image.jpg"
    """

    parser = argparse.ArgumentParser(
        description="Detect objects or tweet content in images and draw bounding boxes",
        epilog=examples,
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument(
        "--image-path", type=str, required=False,
        help="Path to the input image file or directory containing images"
    )
    parser.add_argument(
        "--output-path", type=str,
        help="Path to save the output image or directory for multiple images"
    )
    parser.add_argument(
        "--mode", type=str, choices=["tweet", "general"], default="tweet",
        help="Detection mode: 'tweet' for tweet content or 'general' for all objects"
    )
    parser.add_argument(
        "--box-color", type=str, default="red",
        help="Color of the bounding box (name or hex code)"
    )
    parser.add_argument(
        "--box-width", type=int, default=4,
        help="Width of the bounding box line"
    )
    parser.add_argument(
        "--label", type=str,
        help="Custom label for the bounding box (tweet mode only)"
    )
    parser.add_argument(
        "--autocrop", action="store_true",
        help="Crop image to the detected area instead of drawing a bounding box"
    )
    parser.add_argument(
        "--crop-percent", type=float, default=100.0,
        help="When using --autocrop with tweets, percentage of tweet height to include (default: 100.0)"
    )
    parser.add_argument(
        "--resize", action="store_true",
        help="When used with --autocrop, resize the output to 1080x1350 and center it on a background of the primary color"
    )
    parser.add_argument(
        "--temperature", type=float, default=settings.GEMINI_TEMPERATURE,
        help=f"Temperature setting for the Gemini model (0.0-1.0). Lower values produce more consistent results. (default: {settings.GEMINI_TEMPERATURE} - deterministic)"
    )
    parser.add_argument(
        "--verbose", action="store_true",
        help="Enable verbose debug logging"
    )

    return parser.parse_args()

def detect_tweet_content(
    image_path: str,
    output_path: str = "tweet_with_box.jpg",
    box_color: str = "red",
    box_width: int = 4,
    label: Optional[str] = None,
    autocrop: bool = False,
    crop_percent: float = 92.0,
    resize: bool = False,
    temperature: float = settings.GEMINI_TEMPERATURE
) -> None:
    """
    Detects tweet content in an image using Gemini, draws a bounding box, and saves the result.

    This function uses the Gemini generative model to identify tweet components in the
    provided image. It either draws a bounding box around the main tweet content or crops
    the image to that content, depending on the autocrop parameter.

    Args:
        image_path: Path to the input image file containing a tweet.
        output_path: Path to save the output image with bounding box. Defaults to "tweet_with_box.jpg".
        box_color: Color of the bounding box (name or hex code). Defaults to "red".
        box_width: Width of the bounding box line. Defaults to 4.
        label: Custom label for the bounding box. Defaults to "Tweet Content".
        autocrop: If True, crop the image to the detected area instead of drawing a box. Defaults to False.
        crop_percent: Percentage of tweet height to include when cropping. Defaults to 92.0.
        resize: If True and autocrop is True, resize the cropped image to 1080x1350. Defaults to False.
        temperature: Temperature setting for the Gemini model (0.0-1.0).
                    Defaults to settings.GEMINI_TEMPERATURE (deterministic).

    Returns:
        None

    Raises:
        FileNotFoundError: If the image file doesn't exist.
        Exception: If there's an error processing the image or in the Gemini API.
    """
    try:
        logger.info(f"Detecting tweet content in {image_path}")
        logger.debug(f"Using box color: {box_color}, width: {box_width}, label: {label}, autocrop: {autocrop}, crop_percent: {crop_percent}, resize: {resize}, temperature: {temperature}")

        model = genai.GenerativeModel(settings.GEMINI_MODEL, generation_config={"temperature": temperature})
        logger.debug(f"Initialized Gemini model: {settings.GEMINI_MODEL} with temperature: {temperature}")

        img = PIL.Image.open(image_path)
        img_byte_arr = io.BytesIO()
        img.save(img_byte_arr, format='JPEG')
        img_byte_arr = img_byte_arr.getvalue()
        logger.debug(f"Image loaded and converted, size: {len(img_byte_arr)} bytes")

        img_part: Dict[str, Union[str, bytes]] = {"mime_type": "image/jpeg", "data": img_byte_arr}

        prompt_parts: List[Union[Dict[str, Union[str, bytes]], str]] = [
            img_part,
            """You're looking at a screenshot of a tweet. Create a precise bounding box around the MAIN TWEET CONTENT ONLY.

            The bounding box MUST include:
            1. The user's profile picture/avatar (usually circular)
            2. The username and @handle
            3. The "Follow" button
            4. The entire tweet text/content - CRITICALLY IMPORTANT TO INCLUDE ALL TEXT, INCLUDING ANY EMOJI OR SPECIAL CHARACTERS

            This is a single cohesive unit that forms the main tweet. Make sure the box captures ALL of this content.

            The bounding box MUST exclude:
            1. The navigation elements and header
            2. The date/timestamp (generally a line like "11:34 PM · 2/28/25")
            3. The view count (e.g., "2M Views")
            4. Like/retweet/view counts and all engagement metrics
            5. Any replies or comments below the main tweet
            6. Any UI elements at the bottom of the screen

            VERY IMPORTANT: Draw the bottom boundary of the box ABOVE the timestamp and view count row.
            The timestamp is generally shown in a smaller font below the tweet content, often with a dot separator and view count.

            Make sure your coordinates cover the ENTIRE tweet content from the profile picture to the end of the tweet text.
            When in doubt, make the bounding box LARGER rather than smaller to ensure no text is cut off.

            It is better to include a bit more space than to cut off any part of the text!

            Return only a JSON object with the exact coordinates as:
            {"xmin": [left coordinate], "ymin": [top coordinate], "xmax": [right coordinate], "ymax": [bottom coordinate]}

            The coordinates should be NORMALIZED to a range of 0-1000, where 0 represents the left/top edge and 1000 represents the right/bottom edge of the image."""
        ]

        logger.debug("Sending prompt to Gemini")
        # Use the retry mechanism for the API call
        response = generate_gemini_content(model, prompt_parts)
        logger.debug("Received response from Gemini")

        json_string: str = response.text
        logger.debug(f"Raw response: {json_string}")

        try:
            # Try to find the JSON object in the response text
            json_pattern = r'\{.*?\}'
            match = re.search(json_pattern, json_string, re.DOTALL)

            if match:
                json_string = match.group(0)
                logger.debug(f"Extracted JSON: {json_string}")

            # Clean up malformed JSON with square brackets around values
            json_string = re.sub(r'\[\s*(\d+)\s*\]', r'\1', json_string)
            logger.debug(f"Cleaned JSON: {json_string}")

            tweet_box: Dict[str, Any] = json.loads(json_string)
        except json.JSONDecodeError:
            logger.error(f"Invalid JSON response from Gemini: {json_string}")
            print(f"Error: Invalid JSON response from Gemini: {json_string}")

            # Attempt to manually extract coordinates if JSON parsing fails
            try:
                logger.debug("Attempting manual coordinate extraction")
                xmin_match = re.search(r'"xmin":\s*\[?(\d+)', json_string)
                ymin_match = re.search(r'"ymin":\s*\[?(\d+)', json_string)
                xmax_match = re.search(r'"xmax":\s*\[?(\d+)', json_string)
                ymax_match = re.search(r'"ymax":\s*\[?(\d+)', json_string)

                if all([xmin_match, ymin_match, xmax_match, ymax_match]):
                    tweet_box = {
                        'xmin': int(xmin_match.group(1)),
                        'ymin': int(ymin_match.group(1)),
                        'xmax': int(xmax_match.group(1)),
                        'ymax': int(ymax_match.group(1))
                    }
                    logger.debug(f"Manually extracted coordinates: {tweet_box}")
                else:
                    logger.error("Could not manually extract coordinates")
                    return
            except Exception as e:
                logger.exception(f"Failed to manually extract coordinates: {e}")
                return

        # Check if we have valid coordinates
        required_keys = ['xmin', 'ymin', 'xmax', 'ymax']
        if all(key in tweet_box for key in required_keys):
            xmin: float = float(tweet_box['xmin'])
            ymin: float = float(tweet_box['ymin'])
            xmax: float = float(tweet_box['xmax'])
            ymax: float = float(tweet_box['ymax'])

            logger.debug(f"Bounding box coordinates: xmin={xmin}, ymin={ymin}, xmax={xmax}, ymax={ymax}")

            # Validate coordinates
            if all(isinstance(coord, (int, float)) for coord in [xmin, ymin, xmax, ymax]):
                # Convert normalized coordinates (0-1000 range) to absolute pixel coordinates
                width, height = img.size
                abs_xmin = int(xmin / 1000 * width)
                abs_ymin = int(ymin / 1000 * height)
                abs_xmax = int(xmax / 1000 * width)
                abs_ymax = int(ymax / 1000 * height)
                logger.debug(f"Converted to absolute coordinates: xmin={abs_xmin}, ymin={abs_ymin}, xmax={abs_xmax}, ymax={abs_ymax}")

                # Add padding to ensure we capture all content
                # Horizontal padding (5% of width on each side)
                h_padding = int(width * 0.05)
                # Vertical padding (5% of detected height for top, but no padding at the bottom to exclude timestamp/view count)
                v_padding_top = int((abs_ymax - abs_ymin) * 0.05)

                # For autocrop, we want to exclude the timestamp and view count at the bottom
                # Create smarter padding calculations based on whether we're cropping or drawing boxes
                if autocrop:
                    # When cropping, reduce bottom padding to exclude timestamp
                    # Estimate the position of timestamp (typically about 92-95% of the way down from the top of the tweet)
                    # Find approximate height of tweet content excluding timestamp
                    tweet_content_height = abs_ymax - abs_ymin
                    # Target approximately 92% of the tweet height to cut off timestamp
                    timestamp_position = abs_ymin + int(tweet_content_height * crop_percent / 100)

                    # Apply more precise padding for cropping
                    padded_xmin = max(0, abs_xmin - h_padding)
                    padded_ymin = max(0, abs_ymin - v_padding_top)
                    padded_xmax = min(width, abs_xmax + h_padding)
                    # Use the estimated timestamp position instead of the full ymax
                    padded_ymax = min(height, timestamp_position)

                    logger.debug(f"Cropping with tighter bottom margin to exclude timestamp: ymax={padded_ymax}")
                    logger.debug(f"Original height: {abs_ymax-abs_ymin}px, Cropped height: {padded_ymax-padded_ymin}px, Crop percent: {crop_percent}%")
                    logger.debug(f"Removed approximately {abs_ymax-timestamp_position}px from bottom to exclude timestamp/views")
                else:
                    # For drawing boxes, use normal padding to show the full tweet
                    v_padding_bottom = int((abs_ymax - abs_ymin) * 0.10)

                    # Apply standard padding for drawing boxes
                    padded_xmin = max(0, abs_xmin - h_padding)
                    padded_ymin = max(0, abs_ymin - v_padding_top)
                    padded_xmax = min(width, abs_xmax + h_padding)
                    padded_ymax = min(height, abs_ymax + v_padding_bottom)

                logger.debug(f"Added padding to coordinates: xmin={padded_xmin}, ymin={padded_ymin}, xmax={padded_xmax}, ymax={padded_ymax}")

                if autocrop:
                    # Crop the image to the padded bounding box
                    cropped_img = img.crop((padded_xmin, padded_ymin, padded_xmax, padded_ymax))

                    # Either resize the cropped image or just save it
                    if resize:
                        logger.info("Resizing cropped image to 1080x1350")
                        resize_image_with_background(cropped_img, output_path)
                    else:
                        cropped_img.save(output_path)
                        logger.info(f"Cropped image saved to {output_path}")
                        print(f"Cropped image saved to {output_path}")
                else:
                    # Draw using padded coordinates
                    draw = PIL.ImageDraw.Draw(img)
                    draw.rectangle([(padded_xmin, padded_ymin), (padded_xmax, padded_ymax)], outline=box_color, width=box_width)

                    # Use custom label or default
                    box_label = label if label else "Tweet Content"
                    draw.text((padded_xmin, padded_ymin - 20), box_label, fill=box_color)
                    logger.debug(f"Drew bounding box with label: {box_label}")

                    img.save(output_path)
                    logger.info(f"Image with tweet content box saved to {output_path}")
                    print(f"Image with tweet content box saved to {output_path}")
            else:
                logger.warning(f"Invalid bounding box coordinates: {tweet_box}")
                print(f"Warning: Invalid bounding box coordinates: {tweet_box}")
        else:
            logger.error(f"Missing required coordinates in response: {tweet_box}")
            print(f"Error: Missing required coordinates in response: {tweet_box}")

    except Exception as e:
        logger.exception(f"Error processing image: {e}")
        print(f"Error processing image: {e}")
        import traceback
        traceback.print_exc()


def detect_objects_and_draw_boxes(
    image_path: str,
    output_path: str = "output_with_boxes.jpg",
    box_color: str = "red",
    box_width: int = 3,
    autocrop: bool = False,
    resize: bool = False,
    temperature: float = settings.GEMINI_TEMPERATURE
) -> None:
    """
    Detects objects in an image using Gemini, draws bounding boxes, and saves the result.

    This function uses the Gemini generative model to identify objects in the provided
    image. It then either draws bounding boxes around each detected object or crops
    the image to each object, depending on the autocrop parameter.

    Args:
        image_path: Path to the input image file.
        output_path: Path to save the output image with bounding boxes. Defaults to "output_with_boxes.jpg".
        box_color: Color of the bounding box (name or hex code). Defaults to "red".
        box_width: Width of the bounding box line. Defaults to 3.
        autocrop: If True, save individual cropped images for each object instead of drawing boxes. Defaults to False.
        resize: If True and autocrop is True, resize the cropped images to 1080x1350. Defaults to False.
        temperature: Temperature setting for the Gemini model (0.0-1.0).
                    Defaults to settings.GEMINI_TEMPERATURE (deterministic).

    Returns:
        None

    Raises:
        FileNotFoundError: If the image file doesn't exist.
        Exception: If there's an error processing the image or in the Gemini API.
    """
    try:
        logger.info(f"Detecting objects in {image_path}")
        logger.debug(f"Using box color: {box_color}, width: {box_width}, autocrop: {autocrop}, resize: {resize}, temperature: {temperature}")

        model = genai.GenerativeModel(settings.GEMINI_MODEL, generation_config={"temperature": temperature})
        logger.debug(f"Initialized Gemini model: {settings.GEMINI_MODEL} with temperature: {temperature}")

        img = PIL.Image.open(image_path)
        img_byte_arr = io.BytesIO()
        img.save(img_byte_arr, format='JPEG')
        img_byte_arr = img_byte_arr.getvalue()
        logger.debug(f"Image loaded and converted, size: {len(img_byte_arr)} bytes")

        img_part: Dict[str, Union[str, bytes]] = {"mime_type": "image/jpeg", "data": img_byte_arr}

        prompt_parts: List[Union[Dict[str, Union[str, bytes]], str]] = [
            img_part,
            "Identify and provide bounding box coordinates for all objects in the image. Return the results in JSON format. Each object should have 'label', 'xmin', 'ymin', 'xmax', and 'ymax' fields. The coordinates should be NORMALIZED to a range of 0-1000, where 0 represents the left/top edge and 1000 represents the right/bottom edge of the image. If there are no objects, return an empty JSON array. Example: [{'label': 'dog', 'xmin': 100, 'ymin': 200, 'xmax': 400, 'ymax': 600}, {'label': 'cat', 'xmin': 500, 'ymin': 300, 'xmax': 800, 'ymax': 700}]"
        ]

        logger.debug("Sending prompt to Gemini")
        response = model.generate_content(prompt_parts)
        response.resolve()
        logger.debug("Received response from Gemini")

        json_string: str = response.text
        logger.debug(f"Raw response: {json_string}")

        try:
            # Clean up malformed JSON with square brackets around values
            json_string = re.sub(r'\[\s*(\d+)\s*\]', r'\1', json_string)
            logger.debug(f"Cleaned JSON data: {json_string}")

            object_data: List[Dict[str, Any]] = json.loads(json_string)
            logger.debug(f"Parsed JSON data with {len(object_data)} objects")
        except json.JSONDecodeError:
            logger.error(f"Invalid JSON response from Gemini: {json_string}")
            print(f"Error: Invalid JSON response from Gemini: {json_string}")
            # No manual extraction for object detection as it's more complex
            return

        if isinstance(object_data, list):
            width, height = img.size
            object_count = 0

            # Initialize draw only if we're not autocropping
            # This fixes the linter error about using draw before assignment
            draw = None
            if not autocrop:
                # Draw bounding boxes on the original image
                draw = PIL.ImageDraw.Draw(img)

            for i, obj in enumerate(object_data):
                xmin: Optional[float] = obj.get('xmin')
                ymin: Optional[float] = obj.get('ymin')
                xmax: Optional[float] = obj.get('xmax')
                ymax: Optional[float] = obj.get('ymax')
                label: str = obj.get('label', 'Object')  # Default label if not present

                logger.debug(f"Processing object: {label} at coordinates: xmin={xmin}, ymin={ymin}, xmax={xmax}, ymax={ymax}")

                if all(isinstance(coord, (int, float)) for coord in [xmin, ymin, xmax, ymax]): #check if coordinates are valid numbers.
                    # Convert normalized coordinates (0-1000 range) to absolute pixel coordinates
                    abs_xmin = int(xmin / 1000 * width)
                    abs_ymin = int(ymin / 1000 * height)
                    abs_xmax = int(xmax / 1000 * width)
                    abs_ymax = int(ymax / 1000 * height)
                    logger.debug(f"Converted to absolute coordinates: xmin={abs_xmin}, ymin={abs_ymin}, xmax={abs_xmax}, ymax={abs_ymax}")

                    # Add padding to ensure we capture all content
                    # Horizontal padding (3% of width on each side)
                    h_padding = int(width * 0.03)

                    if autocrop:
                        # For autocropping, use tighter padding to avoid including unwanted elements
                        # Vertical padding (5% of detected height)
                        v_padding = int((abs_ymax - abs_ymin) * 0.05)
                    else:
                        # For drawing boxes, use more generous padding
                        # Vertical padding (8% of detected height for top and bottom)
                        v_padding = int((abs_ymax - abs_ymin) * 0.08)

                    # Apply padding while ensuring we don't go out of bounds
                    padded_xmin = max(0, abs_xmin - h_padding)
                    padded_ymin = max(0, abs_ymin - v_padding)
                    padded_xmax = min(width, abs_xmax + h_padding)
                    padded_ymax = min(height, abs_ymax + v_padding)

                    logger.debug(f"Added padding to coordinates: xmin={padded_xmin}, ymin={padded_ymin}, xmax={padded_xmax}, ymax={padded_ymax}")

                    if autocrop:
                        # For autocrop, create a unique filename for each object
                        # Get the base output path and extension
                        output_dir = os.path.dirname(output_path)
                        output_basename = os.path.basename(output_path)
                        output_name, output_ext = os.path.splitext(output_basename)

                        # Create a unique filename for each object
                        object_output = os.path.join(
                            output_dir,
                            f"{output_name}_{i+1}_{label.lower().replace(' ', '_')}{output_ext}"
                        )

                        # Crop the image to the padded bounding box
                        cropped_img = img.crop((padded_xmin, padded_ymin, padded_xmax, padded_ymax))

                        # Either resize the cropped image or just save it
                        if resize:
                            logger.info(f"Resizing cropped image of {label} to 1080x1350")
                            resize_image_with_background(cropped_img, object_output)
                        else:
                            cropped_img.save(object_output)
                            logger.info(f"Cropped image for {label} saved to {object_output}")
                            print(f"Cropped image for {label} saved to {object_output}")
                    else:
                        # Draw using padded coordinates
                        draw.rectangle([(padded_xmin, padded_ymin), (padded_xmax, padded_ymax)], outline=box_color, width=box_width)
                        draw.text((padded_xmin, padded_ymin - 10), label, fill=box_color) #draw the label above the bounding box.
                        logger.debug(f"Drew bounding box for object: {label}")

                    object_count += 1
                else:
                    logger.warning(f"Invalid bounding box coordinates for {label}: {obj}")
                    print(f"Warning: Invalid bounding box coordinates for {label}: {obj}")

            if not autocrop and object_count > 0:
                img.save(output_path)
                logger.info(f"Image with {object_count} bounding boxes saved to {output_path}")
                print(f"Image with bounding boxes saved to {output_path}")
            elif not autocrop and object_count == 0:
                logger.warning("No valid objects detected to draw bounding boxes")
                print("Warning: No valid objects detected to draw bounding boxes")
        else:
            logger.error("Gemini returned results that are not a list")
            print("Gemini returned results that are not a list. Check the output.")

    except Exception as e:
        logger.exception(f"Error processing image: {e}")
        print(f"Error processing image: {e}")
        import traceback
        traceback.print_exc()

def main() -> int:
    """
    Main function to process images and draw bounding boxes.

    Returns:
        int: Exit code (0 for success, non-zero for failure).
    """
    args = parse_args()

    # Set up logging based on verbose flag
    setup_logging(args.verbose)

    logger.info("Starting bounding box detection")
    logger.debug(f"Arguments: {args}")

    # Default image path if not provided
    image_file = args.image_path or "tweet_screenshot.jpg"

    # Resolve path to handle relative paths, home directory paths, etc.
    image_path = resolve_path(image_file)

    logger.debug(f"Using image path: {image_path}")

    if not os.path.exists(image_path):
        logger.error(f"Path '{image_path}' not found")
        print(f"Error: Path '{image_path}' not found.")
        return 1

    # Handle output path (could be None at this point)
    output_path = args.output_path

    # If output_path is provided but image_path is a directory,
    # output_path should be treated as a directory
    if output_path and os.path.isdir(image_path):
        # Ensure output directory exists
        os.makedirs(output_path, exist_ok=True)
        logger.debug(f"Ensuring output directory exists: {output_path}")

    # If output_path is not provided and image_path is a file,
    # generate a default output path
    elif not output_path and os.path.isfile(image_path):
        # Generate default output path based on input filename
        # Split the image path into directory, filename, and extension
        input_dir = os.path.dirname(image_path)
        input_basename = os.path.basename(image_path)
        input_name, input_ext = os.path.splitext(input_basename)

        # Create default output filename suffix based on mode
        if args.autocrop:
            suffix = "_cropped"
        else:
            suffix = "_bbox"

        default_output_name = f"{input_name}{suffix}{input_ext}"

        # Combine with the original directory to keep in same location
        output_path = os.path.join(input_dir, default_output_name)
        logger.debug(f"Generated default output path: {output_path}")

    # If output_path is provided and image_path is a file,
    # resolve the output path
    elif output_path and os.path.isfile(image_path):
        output_path = resolve_path(output_path)
        logger.debug(f"Resolved output path: {output_path}")

    # Create output directory if it's a file path and its directory doesn't exist
    if output_path and not os.path.isdir(image_path):
        output_dir = os.path.dirname(output_path)
        if output_dir and not os.path.exists(output_dir):
            try:
                os.makedirs(output_dir)
                logger.info(f"Created output directory: {output_dir}")
                print(f"Created output directory: {output_dir}")
            except OSError as e:
                logger.error(f"Error creating output directory: {e}")
                print(f"Error creating output directory: {e}")
                return 1

    # Process the path (file or directory)
    return process_path(
        image_path,
        output_path,
        mode=args.mode,
        box_color=args.box_color,
        box_width=args.box_width,
        label=args.label,
        autocrop=args.autocrop,
        crop_percent=args.crop_percent,
        resize=args.resize,
        temperature=args.temperature
    )

if __name__ == "__main__":
    sys.exit(main())
