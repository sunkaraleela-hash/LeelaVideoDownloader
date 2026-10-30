# LeelaVideoDownloader

A free Flutter-based video downloader powered by yt-dlp and FFmpeg.

## Features

- Download videos using yt-dlp
- Select video quality: Best, 2160p, 1440p, 1080p, 720p and 480p
- Preview video information before downloading
- Choose a custom download folder
- Merge video and audio using FFmpeg
- Simple Flutter user interface

## Requirements

- Flutter SDK
- Dart SDK
- Windows 10/11 for Windows build
- yt-dlp
- FFmpeg and FFprobe

## Tools Setup (Windows)

The yt-dlp and FFmpeg binaries are not included in this repository.

Download yt-dlp:
https://github.com/yt-dlp/yt-dlp/releases

Download FFmpeg:
https://ffmpeg.org/download.html

Place the files in these locations:

    tools/
      yt-dlp.exe
      ffmpeg/
        ffmpeg.exe
        ffprobe.exe

## Getting Started

Clone the repository:

    git clone https://github.com/sunkaraleela-hash/LeelaVideoDownloader.git
    cd LeelaVideoDownloader

Install dependencies:

    flutter pub get

Run on Windows:

    flutter run -d windows

## Build

    flutter build windows

## Project Status

Version: 1.0.0

Windows build: Tested.

Android and other platform builds: Not yet verified.

## Disclaimer

This project is intended for lawful downloading only. Users are responsible for respecting copyright, website terms of service, and applicable laws.

## Acknowledgements

- Flutter
- yt-dlp
- FFmpeg
