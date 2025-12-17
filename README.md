# Archive Video Batch

A windows batch wrapping [FFmpeg](https://www.ffmpeg.org/) to convert videos for archiving using drag & drop.

> [!WARNING]
> Output video files only contain video streams and audio streams from the original video file. Subtitles, chapters and all other metadata are therefore not copied!

| Table of Contents |
| - |
| [Dependency](#dependency) |
| [Installation](#installation) |
| [Usage](#usage) |

## Dependency

The folder containing the FFmpeg.exe and FFprobe.exe files must be included in the environment variables. These can be downloaded [here](https://www.ffmpeg.org/download.html). The file FFmpeg.exe must be compiled with aac, libx264, libx265, h264_nvenc, hevc_nvenc, h264_amf, hevc_amf, h264_qsv & hevc_qsv.

## Installation

Move the file 'Archive Video.bat' to a location where you can drag and drop the video files you want to convert, such as the desktop.

## Usage

Drag and drop video files or folders containing video files onto this batch file. Please note that Windows has a character limit for drag and drop operations. If you want to process a large number of files, first move them to a folder and then drag that folder onto the batch file.

Next, you will be asked to specify whether the script should delete the original video file after successful conversion and which codec should be used for the video. You can select the option that suits your requirements. x264 is recommended for best compatibility with old and new devices and possible licensing requirements with x265 alias hevc.

> [!NOTE]
> Windows will warn you about running this batch file because it comes from a source that is not trusted or verified. This is a good security check. If you don't trust my batch file, open it with a text editor and you can read the entire code. If you want to remove the notification, you must create a new file and copy the contents of my batch file into yours. This way, the file is created by you and Windows is happy once again. However, only do this if you trust the code!

> [!WARNING]
> The encoder options for AMD hardware acceleration are untested, as I don't have an AMD GPU to test them on :)
