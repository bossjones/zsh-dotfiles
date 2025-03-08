#!/usr/bin/env python3

import os
import sys
import subprocess
from pathlib import Path
import math
from typing import List, Union, Set
from collections.abc import Iterator

def is_video_file(path: Path) -> bool:
    """Check if the given path is a video file based on its extension.

    Args:
        path: Path to check

    Returns:
        bool: True if the file has a video extension, False otherwise

    Example:
        >>> is_video_file(Path("video.mp4"))
        True
        >>> is_video_file(Path("image.jpg"))
        False
    """
    VIDEO_EXTENSIONS: set[str] = {'.mp4', '.avi', '.mov', '.mkv', '.flv', '.wmv', '.m4v'}
    return path.is_file() and path.suffix.lower() in VIDEO_EXTENSIONS

def find_video_files(path: Path) -> Iterator[Path]:
    """Recursively find all video files in the given directory.

    Args:
        path: Path to search for video files. Can be a file or directory.

    Returns:
        Iterator[Path]: Iterator yielding paths to video files

    Yields:
        Path: Path to each video file found

    Example:
        >>> for video in find_video_files(Path("videos/")):
        ...     print(video)
        videos/file1.mp4
        videos/subdir/file2.avi
    """
    if path.is_file():
        if is_video_file(path):
            yield path
    else:
        for item in path.rglob("*"):
            if is_video_file(item):
                yield item

def print_video_tree(path: Path, prefix: str = "", is_last: bool = True) -> None:
    """Print a tree-like view of video files in the directory.

    Creates a hierarchical visualization of video files and their containing directories.

    Args:
        path: Root path to start printing from
        prefix: Current line prefix for indentation and tree structure
        is_last: Whether this item is the last in its group

    Example:
        >>> print_video_tree(Path("videos/"))
        videos/
        ├── folder1
        │   ├── video1.mp4
        │   └── video2.mp4
        └── folder2
            └── video3.mp4
    """
    if path.is_file():
        connector = "└── " if is_last else "├── "
        print(f"{prefix}{connector}{path.name}")
        return

    # Print the root directory
    if prefix == "":
        print(path.name)
        prefix = "    "

    # Get all video files and directories with videos
    items: list[Path] = []
    dirs_with_videos: set[Path] = set()

    for item in find_video_files(path):
        items.append(item)
        dirs_with_videos.add(item.parent)

    # Sort items for consistent output
    items.sort()

    # Print the tree
    printed_dirs: set[Path] = set()
    for i, item in enumerate(items):
        # Handle directories
        rel_parents = item.relative_to(path).parents
        for parent in reversed(list(rel_parents)[:-1]):
            if parent not in printed_dirs:
                connector = "└── " if i == len(items) - 1 else "├── "
                print(f"{prefix}{connector}{parent}")
                prefix += "    " if i == len(items) - 1 else "│   "
                printed_dirs.add(parent)

        # Print the file
        is_last_in_dir = i == len(items) - 1 or items[i + 1].parent != item.parent
        connector = "└── " if is_last_in_dir else "├── "
        print(f"{prefix}{connector}{item.name}")

def resolve_path(path_str: str) -> Path:
    """Resolve the provided path to an absolute path.

    Handles both relative and home directory paths, expanding them to absolute paths.

    Args:
        path_str: Input path to the video file or directory

    Returns:
        Path: Resolved absolute path

    Raises:
        FileNotFoundError: If the path does not exist

    Example:
        >>> resolve_path("~/videos/file.mp4")
        PosixPath('/home/user/videos/file.mp4')
    """
    path = Path(path_str).expanduser().resolve()
    if not path.exists():
        raise FileNotFoundError(f"Path not found: {path}")
    return path

def get_video_duration(video_path: Path) -> float:
    """Get the duration of the video in seconds using ffprobe.

    Args:
        video_path: Path to the video file

    Returns:
        float: Duration of the video in seconds

    Raises:
        RuntimeError: If ffprobe fails to get video duration

    Example:
        >>> get_video_duration(Path("video.mp4"))
        123.45
    """
    cmd = [
        'ffprobe',
        '-v', 'error',
        '-show_entries', 'format=duration',
        '-of', 'default=noprint_wrappers=1:nokey=1',
        str(video_path)
    ]

    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        raise RuntimeError(f"Failed to get video duration: {result.stderr}")

    return float(result.stdout.strip())

def get_default_output_dir(video_path: Path) -> Path:
    """Get the default output directory for video segments.

    Creates a directory named after the video in ~/segments/.

    Args:
        video_path: Path to the input video file

    Returns:
        Path: Path to the output directory

    Example:
        >>> get_default_output_dir(Path("~/videos/test.mp4"))
        PosixPath('/home/user/segments/test_segments')
    """
    segments_dir = Path.home() / "segments"
    return segments_dir / f"{video_path.stem}_segments"

def split_video(video_path: Path, output_dir: Path | None = None, segment_duration: int = 58) -> None:
    """Split the video into segments of specified duration while maintaining quality.

    Uses FFmpeg's segment feature with proper encoding settings to ensure seamless playback.
    Creates segments of specified duration and a segments.txt file listing all generated segments.
    If output_dir is not specified, creates segments in ~/segments/video_name_segments/.

    Args:
        video_path: Path to the input video
        output_dir: Directory to store output segments. If None, uses ~/segments/video_name_segments/
        segment_duration: Duration of each segment in seconds (default: 58)

    Raises:
        RuntimeError: If FFmpeg fails to split the video

    Example:
        >>> split_video(Path("input.mp4"), segment_duration=60)
        Splitting video into 5 segments...
        Successfully split video into 5 segments
        Output directory: /home/user/segments/input_segments
    """
    # Use default output directory if none specified
    if output_dir is None:
        output_dir = get_default_output_dir(video_path)

    # Create output directory if it doesn't exist
    output_dir.mkdir(parents=True, exist_ok=True)

    # Get video duration to calculate number of segments
    duration = get_video_duration(video_path)
    num_segments = math.ceil(duration / segment_duration)

    # Prepare the output pattern
    output_pattern = output_dir / f"{video_path.stem}_%03d{video_path.suffix}"

    # FFmpeg command for splitting
    cmd = [
        'ffmpeg',
        '-i', str(video_path),
        '-c', 'copy',  # Copy streams without re-encoding
        '-f', 'segment',
        '-segment_time', str(segment_duration),
        '-reset_timestamps', '1',
        '-segment_list', str(output_dir / 'segments.txt'),
        str(output_pattern)
    ]

    print(f"Splitting video into {num_segments} segments...")
    result = subprocess.run(cmd, capture_output=True, text=True)

    if result.returncode != 0:
        raise RuntimeError(f"Failed to split video: {result.stderr}")

    print(f"Successfully split video into {num_segments} segments")
    print(f"Output directory: {output_dir}")

def main() -> None:
    """Main function to handle command line arguments and execute video splitting.

    Processes either a single video file or recursively processes all videos in a directory.
    For directories, displays a tree view of found videos and prompts for batch processing.
    All output segments are stored in ~/segments/ by default.

    Raises:
        SystemExit: With status 1 if an error occurs or invalid arguments are provided

    Example:
        $ python video_splitter.py video.mp4
        $ python video_splitter.py /path/to/videos/
    """
    if len(sys.argv) != 2:
        print("Usage: python video_splitter.py <path_to_video_or_directory>")
        sys.exit(1)

    try:
        # Resolve the input path
        input_path = resolve_path(sys.argv[1])

        if input_path.is_dir():
            print("\nScanning for video files...")
            print("\nVideo files found:")
            print_video_tree(input_path)

            # Ask user if they want to split all found videos
            videos = list(find_video_files(input_path))
            if videos:
                response = input(f"\nFound {len(videos)} video(s). Would you like to split them all? (y/n): ")
                if response.lower() == 'y':
                    for video_path in videos:
                        print(f"\nProcessing: {video_path}")
                        split_video(video_path)  # Use default output directory
            else:
                print("No video files found in the directory.")
        else:
            # Handle single video file
            split_video(input_path)  # Use default output directory

    except Exception as e:
        print(f"Error: {str(e)}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
