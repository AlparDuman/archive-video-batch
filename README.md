# Archive Media Batch
A windows batch wrapping [FFmpeg](https://www.ffmpeg.org/) to convert media (music, image, video) for archiving using drag & drop.

> [!WARNING]
> 1. Not all metadata are copied to the resulting media files.
> 2. Lossy may result in a reduction in quality and bit depth.
> 3. Lossless uses less common codecs.

> [!NOTE]
> Hardware accelerated, truly lossless video encoding is only available on Nvidia.

## Dependency
The folder containing the FFmpeg.exe and FFprobe.exe files must be included in the environment variables. These can be downloaded [here](https://www.ffmpeg.org/download.html). The file FFmpeg.exe must be compiled with aac, flac, pcm_s32le, libx264, h264_amf, h264_qsv, h264_nvenc, libx265, hevc_amf, hevc_qsv & hevc_nvenc.

## Setup
Move the Archive Media.bat file to a location of your choice, such as the desktop. To enable advanced features, open the batch file in a text editor and follow the configuration instructions at the beginning of the file.

## Usage
Drag and drop small quantities of files onto this batch file. If there are a large number of files, place them in a folder and then drag this folder onto the batch file.
