::Fucking youtube wont let me use -g to get the fucking url to send to fucking ffmpeg. other than that this script should work

@echo off
set /p youtube_url="Enter YouTube URL: "
set /p start_time="Enter start time (HH:MM:SS): "
set /p duration="Enter duration (in seconds): "
set /p output_name="Enter output file name (without .gif): "

echo Fetching video URL...
for /f "delims=" %%a in ('yt-dlp -g -f "bestvideo[ext=mp4]" %youtube_url%') do set "video_url=%%a"

if not defined video_url (
    echo Failed to fetch video URL.
    pause
    exit /b
)

echo Creating GIF...
ffmpeg -ss %start_time% -t %duration% -i "%video_url%" -vf "fps=30,scale=1920:-1:flags=lanczos" -loop 0 "%output_name%.gif"

if %errorlevel% neq 0 (
    echo Failed to create GIF.
    pause
    exit /b
)

echo Done, saved to %CD%\%output_name%.gif
pause
