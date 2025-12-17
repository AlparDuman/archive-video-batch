@echo off
title Archive Media
if not defined in_subprocess (cmd /k set in_subprocess=y ^& %0 %*) & exit
setlocal enabledelayedexpansion










rem ==========[ Config ]==========

rem auto delete sourve media file
rem after successful conversion.
rem THIS WILL DELETE IRREVERSIBLY
rem yes | no
set "autoDelete=no"

rem =======[ Config Check ]=======

if not "!autoDelete!"=="yes" set "autoDelete=no"

rem ========[ Config End ]========










rem	Copyright (C) 2025 Alpar Duman
rem	This file is part of archive-media-batch.
rem	
rem	archive-media-batch is free software: you can redistribute it and/or modify
rem	it under the terms of the GNU General Public License version 3 as
rem	published by the Free Software Foundation.
rem	
rem	archive-media-batch is distributed in the hope that it will be useful,
rem	but WITHOUT ANY WARRANTY; without even the implied warranty of
rem	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
rem	GNU General Public License for more details.
rem	
rem	You should have received a copy of the GNU General Public License
rem	along with archive-media-batch. If not, see
rem	<https://github.com/AlparDuman/archive-media-batch/blob/main/LICENSE>
rem	else <https://www.gnu.org/licenses/>.

rem global variables
set "version=v2.0a"
set "url=https://github.com/AlparDuman/archive-media-batch"
set "tempFolder=%TEMP%\github-alparduman-archive-media-batch\"

rem fancy intro :)
echo:     _             _     _             __  __          _ _       
echo:    / \   _ __ ___^| ^|__ (_)_   _____  ^|  \/  ^| ___  __^| (_) __ _ 
echo:   / _ \ ^| '__/ __^| '_ \^| \ \ / / _ \ ^| ^|\/^| ^|/ _ \/ _` ^| ^|/ _` ^|
echo:  / ___ \^| ^| ^| (__^| ^| ^| ^| ^|\ V /  __/ ^| ^|  ^| ^|  __/ (_^| ^| ^| (_^| ^|
echo: /_/   \_\_^|  \___^|_^| ^|_^|_^| \_/ \___^| ^|_^|  ^|_^|\___^|\__,_^|_^|\__,_^|
echo: !version! ========= !url!
echo:

rem create clean temp folder
if exist "!tempFolder!" rmdir /s /q "!tempFolder!"
mkdir "!tempFolder!"

rem process each file
for %%F in (%*) do (
	if exist "%%~F\*" (
		call :processFolder "%%~F\"
	) else (
		call :processFile "%%~F"
	)
)

rem finished
rmdir /s /q "!tempFolder!"
timeout /t 999
exit 0










rem recursively traverse files in the folder
:processFolder
for /R "%~1" %%I in (*) do call :processFile "%%~I"
exit /b 0










rem archiving
:processFile
set "input=%~1"
set "inputDrivePath=%~dp1"
set "inputName=%~n1"
set "outputName=!inputName!.archive"
set "wip=!tempFolder!!outputName!"

rem skip on archive suffix
if not "!inputName!"=="!inputName:.archive=!" (
	echo:Skip !input!
	exit /b 0
)

rem detect audio & video streams
set "hasAudio=0"
set "hasVideo=0"
set "hasAlpha=0"

for /f "delims=" %%S in ('start "" /b /belownormal /wait ffprobe -v error -show_entries stream^=codec_type -of default^=nw^=1:nk^=1 "!input!" 2^>nul') do (
	if /i "%%S"=="audio" set "hasAudio=1"
	if /i "%%S"=="video" set "hasVideo=1"
)

rem skip no media file
if "!hasAudio!!hasVideo!"=="00" (
	echo:Skip !input!
	exit /b 0
)

rem count video stream frames
if "!hasVideo!"=="1" for /f "delims=" %%I in ('start "" /b /belownormal /wait ffprobe -v error -select_streams v:0 -count_frames -read_intervals "0%%+#2" -show_entries stream^=nb_read_frames -of csv^=p^=0 "!input!" 2^>nul') do (
	if "%%I"=="2" set "hasVideo=2"
)

rem get transparency indicator
if "!hasVideo!"=="1" for /f "tokens=*" %%i in ('start "" /b /belownormal /wait ffprobe -v error -select_streams v:0 -show_entries stream^=pix_fmt -of csv^=p^=0 "!input!" 2^>nul') do (
	set "pixfmt=%%i"
	if not "!pixfmt!"=="!pixfmt:a=!" set "hasAlpha=1"
)

rem categorise media type for conversion
if "!hasVideo!"=="2" (
	if "!hasAudio!!hasAlpha!"=="01" (
		call :convertAnimated
	) else (
		call :convertVideo
	)
) else (
	if "!hasAudio!!hasVideo!"=="01" (
		if "!hasAlpha!"=="1" (
			call :convertImageTransparent
		) else (
			call :convertImage
		)
	) else (
		if "!hasAudio!!hasVideo!"=="11" (
			call :convertMusicCover
		) else (
			call :convertMusic
		)
	)
)

rem move output to source folder
if not errorlevel 1 (
	call :exportFile "!outputExtension!"
	if "!autoDelete!"=="yes" del "!input!"
)

rem archived
exit /b 0










rem convert as animated
:convertAnimated
rem WIP
echo:ANIMATED !input!
exit /b 0










rem convert as video
:convertVideo
set "outputExtension=mp4"

rem archived already exists
if exist "!inputDrivePath!!outputName!.!outputExtension!" (
	echo:EXIST !input!
	exit /b 0
)

rem announce conversion
echo:VIDEO !input!

rem support high bit depth
set "profile=high"
set "pixfmt=yuv420p"
for /f "tokens=*" %%a in ('start "" /b /belownormal /wait ffprobe -v error -select_streams v:0 -show_entries stream^=bits_per_raw_sample -of default^=noprint_wrappers^=1:nokey^=1 "!input!" 2^>nul') do if "%%a"=="10" (
	set "profile=high10"
	set "pixfmt=yuv420p10le"
)

rem prepare query
set "query=-map 0:v -c:v libx264 -profile:v !profile! -tag:v avc1 -crf 18 -preset placebo -x264-params ref=4:log-level=error -fps_mode cfr -g 60"
set "query=!query! -map 0:a? -c:a aac -tag:a mp4a -b:a 192k"
set "query=!query! -pix_fmt !pixfmt! -movflags +faststart"
set "query=-metadata comment="!version! !url! !query!" !query!"

rem convert to temp
start "" /b /belownormal /wait ffmpeg -hide_banner -y -v error -stats -i "!input!" !query! "!wip!.!outputExtension!"

rem error
if not errorlevel 0 (
	del "!wip!.!outputExtension!"
	color 0C
    echo Encoding failed
    pause
	color 07
    exit /b 1
)

rem success
exit /b 0










rem convert as transparent
:convertImageTransparent
rem WIP
echo:IMAGE TRANSPARENT !input!
exit /b 0










rem convert as image
:convertImage
rem WIP
echo:IMAGE !input!
exit /b 0










rem convert as music
:convertMusic
rem WIP
echo:MUSIC !input!
exit /b 0










rem convert as music with cover
:convertMusicCover
rem WIP
echo:MUSICCOVER !input!
exit /b 0










rem move convert output to source folder
:exportFile
rem prepare variables
set "outputExtension=%~1"
set "robocopySource=!tempFolder!"
set "robocopyTarget=!inputDrivePath!"
if "!robocopySource:~-1!"=="\" set "robocopySource=!robocopySource:~0,-1!"
if "!robocopyTarget:~-1!"=="\" set "robocopyTarget=!robocopyTarget:~0,-1!"

rem move file
robocopy "!robocopySource!" "!robocopyTarget!" "!outputName!.!outputExtension!" /MOV /R:3 /W:5 /IS /IT /NFL /NDL /NJH /NJS /NC /NS 2>&1

rem error
if not errorlevel 0 (
	del "!wip!.!outputExtension!"
	color 0C
    echo Exporting failed
    pause
	color 07
    exit /b 1
)

rem success
exit /b 0
