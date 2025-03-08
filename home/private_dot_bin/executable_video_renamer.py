#!/usr/bin/env python3

import cv2
import pytesseract
import os
from pathlib import Path
import argparse
import re
from typing import Tuple, Optional

class VideoTextExtractor:
    """
    A class to extract text from video files and suggest new filenames based on the content.
    """
    def __init__(self, min_confidence: float = 60):
        self.min_confidence = min_confidence

    def extract_first_frame(self, video_path: str) -> cv2.Mat | None:
        """
        Extract the first frame from a video file.

        Args:
            video_path: Path to the video file

        Returns:
            The first frame as a numpy array, or None if extraction fails
        """
        try:
            cap = cv2.VideoCapture(video_path)
            ret, frame = cap.read()
            cap.release()

            if not ret:
                print(f"Could not read frame from {video_path}")
                return None

            return frame

        except Exception as e:
            print(f"Error extracting frame: {str(e)}")
            return None

    def preprocess_frame(self, frame: cv2.Mat) -> cv2.Mat:
        """
        Preprocess the frame to improve OCR accuracy.

        Args:
            frame: Input frame

        Returns:
            Preprocessed frame
        """
        # Convert to grayscale
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)

        # Apply thresholding to get black text on white background
        _, binary = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)

        return binary

    def extract_text(self, frame: cv2.Mat) -> str:
        """
        Extract text from a frame using pytesseract.

        Args:
            frame: Input frame

        Returns:
            Extracted text
        """
        # Get detailed OCR data
        ocr_data = pytesseract.image_to_data(frame, output_type=pytesseract.Output.DICT)

        # Filter text by confidence
        confident_text = []
        for i, conf in enumerate(ocr_data['conf']):
            if conf > self.min_confidence:
                text = ocr_data['text'][i].strip()
                if text:  # Only add non-empty strings
                    confident_text.append(text)

        return ' '.join(confident_text)

    def suggest_filename(self, text: str) -> str:
        """
        Generate a filename suggestion based on extracted text.

        Args:
            text: Extracted text

        Returns:
            Suggested filename
        """
        # Remove special characters and spaces, keeping only alphanumeric, underscore, hyphen
        clean_text = re.sub(r'[^\w\s-]', '', text)
        # Replace spaces with underscores and convert to lowercase
        filename = clean_text.strip().replace(' ', '_').lower()
        # Remove consecutive underscores
        filename = re.sub(r'_+', '_', filename)
        # Remove leading/trailing underscores
        filename = filename.strip('_')
        # Limit length to 32 chars for better filesystem compatibility
        filename = filename[:32]
        return filename

    def process_video(self, video_path: str) -> tuple[str | None, str | None]:
        """
        Process a video file and suggest a new filename.

        Args:
            video_path: Path to the video file

        Returns:
            Tuple of (extracted text, suggested filename) or (None, None) if processing fails
        """
        frame = self.extract_first_frame(video_path)
        if frame is None:
            return None, None

        processed_frame = self.preprocess_frame(frame)
        extracted_text = self.extract_text(processed_frame)

        if not extracted_text:
            print("No text detected in the frame")
            return None, None

        suggested_filename = self.suggest_filename(extracted_text)
        return extracted_text, suggested_filename

def process_path(path: Path, dry_run: bool = True, force: bool = False) -> None:
    """
    Process a path which can be either a file or directory.

    Args:
        path: Path to process
        dry_run: If True, only show suggested changes without renaming
        force: If True, skip confirmation prompt when renaming
    """
    if path.is_file() and path.suffix.lower() in ['.mp4', '.mov', '.avi', '.mkv']:
        rename_video(str(path), dry_run)
    elif path.is_dir():
        for item in path.rglob('*'):
            if item.is_file() and item.suffix.lower() in ['.mp4', '.mov', '.avi', '.mkv']:
                rename_video(str(item), dry_run, force)

def rename_video(video_path: str, dry_run: bool = True, force: bool = False) -> None:
    """
    Main function to process and rename a video file.

    Args:
        video_path: Path to the video file
        dry_run: If True, only show suggested changes without renaming
        force: If True, skip confirmation prompt when renaming
    """
    extractor = VideoTextExtractor()
    video_path_obj = Path(video_path)

    # Skip hidden files
    if video_path_obj.name.startswith('.'):
        return

    # Get the original file extension
    original_extension = video_path_obj.suffix

    # Process the video
    extracted_text, suggested_filename = extractor.process_video(video_path)

    if not suggested_filename:
        print(f"\nCould not generate a new filename for: {video_path_obj.name}")
        return

    # Create new filename with original extension
    new_filename = f"{suggested_filename}{original_extension}"
    new_path = str(video_path_obj.parent / new_filename)

    # Skip if the file already has the suggested name
    if video_path_obj.name == new_filename:
        return

    # Show the suggested change
    print(f"\nExtracted text: {extracted_text}")
    print(f"Current filename: {video_path_obj.name}")
    print(f"Suggested filename: {new_filename}")

    if dry_run:
        print("\nThis is a dry run. Use --execute to perform the rename operation.")
        return

    # Skip confirmation if force is True
    if force or input("\nDo you want to rename the file? (y/n): ").lower() == 'y':
        try:
            # Check if target file already exists
            if Path(new_path).exists():
                print(f"Error: Target file already exists: {new_filename}")
                return
            os.rename(video_path, new_path)
            print(f"File renamed successfully to: {new_filename}")
        except Exception as e:
            print(f"Error renaming file: {str(e)}")
    else:
        print("Operation cancelled")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Extract text from video and suggest filename")
    parser.add_argument("path", help="Path to video file or directory")
    parser.add_argument("--execute", action="store_true",
                      help="Execute the rename operation (default is dry run)")
    parser.add_argument("--force", action="store_true",
                      help="Skip confirmation prompt when renaming")

    args = parser.parse_args()
    process_path(Path(args.path), dry_run=not args.execute, force=args.force)
