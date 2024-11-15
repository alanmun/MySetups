import os
import subprocess
import re
import datetime
import cv2
import numpy as np
import shutil


def run():
    # get inputs from the user
    youtube_url = input("Enter YouTube URL: ")

    # remove everything after '?' or '&' as long as it isn't ?v=
    cleaned_url = re.split(r"\?[^v]|&", youtube_url)[0]

    if youtube_url != cleaned_url:
        print(f"Cleaned the URL, set to: {cleaned_url}\n")

    start_time = input("Enter start time (HH:MM:SS or MM:SS or specify in seconds, default=0): ") or "0"
    duration = (
        input("Enter duration to capture, or hit enter to use perfect loop mode (in seconds, default=perfect_loop): ")
        or "perfect_loop"
    )
    output_name = input("Enter output file name (without .gif, default=output.gif): ") or "output"

    is_perfect_loop_mode = duration == "perfect_loop"
    if is_perfect_loop_mode:
        duration = 60  # * Good cutoff for maximum loop length

    print("Fetching video URL...")
    try:

        def convert_to_seconds(time_str) -> int:
            # Convert HH:MM:SS or MM:SS format to seconds
            time_parts = time_str.split(":")
            if len(time_parts) == 3:
                hours, minutes, seconds = map(int, time_parts)
                total_seconds = hours * 3600 + minutes * 60 + seconds
            elif len(time_parts) == 2:
                minutes, seconds = map(int, time_parts)
                total_seconds = minutes * 60 + seconds
            else:
                total_seconds = int(time_str)  # Assume it is already in seconds
            return total_seconds

        def convert_to_hhmmss(total_seconds):
            # Convert seconds to HH:MM:SS format
            return str(datetime.timedelta(seconds=total_seconds))

        # Convert times to seconds
        start_seconds = convert_to_seconds(start_time)
        duration_seconds = int(duration)

        # Calculate end time in seconds
        end_time_seconds: int = start_seconds + duration_seconds

        # Convert end time back to HH:MM:SS format
        end_time: str = convert_to_hhmmss(end_time_seconds)

        print(f"Start time is {start_time} (in seconds: {start_seconds}), duration is {duration} seconds.")
        print(f"End time calculated to be {end_time} (in seconds: {end_time_seconds}).")

        temp_video_name = "temp.mp4"

        yt_dlp_command = [
            "yt-dlp",
            "--download-sections",
            f"*{start_time}-{end_time}",
            "-f",
            "bv*[height<=1080]",
            "-o",
            temp_video_name,
            cleaned_url,
        ]

        subprocess.run(yt_dlp_command, check=True)

        fps: float = get_fps(temp_video_name)

        # Step 2: Determine a new duration for a perfect loop, if perfect loop mode is on
        frame_dir = "frames"
        if is_perfect_loop_mode:
            duration = create_perfect_loop(frame_dir, duration, fps)

        output_and_extension = f"{output_name}.gif"
        print("Found fps to be: ", fps)
        # Step 3: Create GIF using the palette. If perfect loop mode is not on, assume duration is perfect already
        gif_command = [
            "ffmpeg",
            "-i",
            temp_video_name,
            "-lavfi",
            f"fps={fps},scale=1920:-1:flags=lanczos,palettegen [p]; [0:v][p] paletteuse=dither=bayer:bayer_scale=5",
            "-y",
            output_and_extension,
        ]

        if is_perfect_loop_mode:
            gif_command.insert(3, str(duration))
            gif_command.insert(3, "-t")
            print("Debug: new command llooks like:", gif_command)

        # * Run ffmpeg
        gif_run = subprocess.run(gif_command)

        if gif_run.returncode == 0:
            print(f"High-quality GIF saved as {output_and_extension}")
        else:
            print("Failed to create GIF: failed during gif creation step.")
    except subprocess.CalledProcessError as e:
        print(f"An error occurred. Ensure yt-dlp is up to date. Here is what failed: {e}")
        if "output_and_extension" in locals() and os.path.exists(output_and_extension):
            os.remove(output_and_extension)
    finally:
        if os.path.exists(temp_video_name):
            os.remove(temp_video_name)
        if os.path.exists(frame_dir):
            shutil.rmtree(frame_dir)


def create_perfect_loop(frame_dir: str, duration: int, fps: float):
    os.makedirs(frame_dir, exist_ok=True)  # create directory if it doesn't exist
    frame_gen_command = [
        "ffmpeg",
        "-i",
        "temp.mp4",
        "-t",
        str(duration),
        "-vsync",
        "vfr",
        f"{frame_dir}/frame_%04d.png",
    ]
    subprocess.run(frame_gen_command, check=True)

    try:
        duration = detect_perfect_loop(frame_dir, fps)
        print(f"Detected a perfect loop of {duration} seconds.")
        return duration
    except Exception as e:
        raise e


def detect_perfect_loop(frames_dir: str, fps: float, threshold: float = 1e-3):

    frames = sorted(os.listdir(frames_dir))

    start_frame = cv2.imread(os.path.join(frames_dir, frames[0]))

    for frame_num in range(1, len(frames)):
        current_frame = cv2.imread(os.path.join(frames_dir, frames[frame_num]))

        # print("Before diff calc, current: ", current_frame.astype("float"))

        # calculate mean squared error
        diff = np.mean((start_frame.astype("float") / 255 - current_frame.astype("float") / 255) ** 2)

        if diff < threshold:  # found the loop
            duration = frame_num / fps
            return duration

    raise Exception(
        "Failed to detect a perfect loop after examining a minute of footage, giving up. If you are convinced there is a loop, try a different start time."
    )


def get_fps(video_path) -> float:
    cmd = [
        "ffprobe",
        "-v",
        "0",
        "-select_streams",
        "v:0",
        "-show_entries",
        "stream=r_frame_rate",
        "-of",
        "csv=p=0",
        video_path,
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)
    fps: float = eval(result.stdout.strip())  # evaluates "30/1" as 30.0
    return round(fps, 2)


if __name__ == "__main__":
    run()
