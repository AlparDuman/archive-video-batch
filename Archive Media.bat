@echo off
title Archive Media
if not defined in_subprocess (cmd /k set in_subprocess=y ^& %0 %*) & exit
setlocal enabledelayedexpansion










rem ==========[ Config ]==========

rem Use a hardware accelerator for
rem video conversion. Faster
rem conversion, but lower quality.
rem no | amd | intel | nvidia
set "hardwareAcceleration=no"

rem Enable lossless convertion.
rem Larger file, but higher quality.
rem LOSSLESS ANIMATED IMAGES ARE
rem ONLY SUPPORTED BY WEB BROWSERS!
rem LOSSLESS VIDEO SIZE IS INSANE!
rem yes | no
set "losslessAnimated=no"
set "losslessVideo=no"
set "losslessImage=no"
set "losslessMusic=no"

rem Automatically delete the
rem source media file after
rem successful conversion.
rem THIS WILL DELETE IRREVERSIBLY!
rem yes | no
set "autoDelete=no"

rem =======[ Config Check ]=======

for %%v in (losslessAnimated losslessVideo losslessImage losslessMusic autoDelete) do if /i not "!%%v!"=="yes" set "%%v=no"

echo " no amd intel nvidia " | find " !hardwareAcceleration: =! " >nul
if errorlevel 1 set "hardwareAcceleration=no"

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
echo:    _             _     _             __  __          _ _       
echo:   / \   _ __ ___^| ^|__ (_)_   _____  ^|  \/  ^| ___  __^| (_) __ _ 
echo:  / _ \ ^| '__/ __^| '_ \^| \ \ / / _ \ ^| ^|\/^| ^|/ _ \/ _` ^| ^|/ _` ^|
echo: / ___ \^| ^| ^| (__^| ^| ^| ^| ^|\ V /  __/ ^| ^|  ^| ^|  __/ (_^| ^| ^| (_^| ^|
echo:/_/   \_\_^|  \___^|_^| ^|_^|_^| \_/ \___^| ^|_^|  ^|_^|\___^|\__,_^|_^|\__,_^|
echo:!version! ========= !url!
echo:A wrapper for FFmpeg =================== https://www.ffmpeg.org/

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
endlocal
timeout /t 999
exit 0










rem recursively traverse files in the folder
:processFolder
for /R "%~1" %%I in (*) do call :processFile "%%~I"
exit /b 0










rem archiving
:processFile
echo:
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
		call :convertImage
	) else (
		call :convertMusic
	)
)

rem move output to source folder
if not errorlevel 1 (
	if exist "!wip!.!outputExtension!" call :exportFile "!outputExtension!"
	if "!autoDelete!"=="yes" (
		del "!input!"
		echo:DELETE !input!
	)
)

rem archived
exit /b 0










rem convert as animated
:convertAnimated
rem WIP
echo:CONVERT IMAGE ANIMATED !input!
exit /b 0










rem convert as video
:convertVideo
set "outputExtension=mp4"

rem archived already exists
if exist "!inputDrivePath!!outputName!.!outputExtension!" (
	echo:EXIST !inputDrivePath!!outputName!.!outputExtension!
	exit /b 0
)

rem announce conversion
echo:CONVERT VIDEO !input!

rem support high bit depth
set "profile=high"
set "pixfmt=yuv420p"
for /f "tokens=*" %%A in ('start "" /b /belownormal /wait ffprobe -v error -select_streams v:0 -show_entries stream^=bits_per_raw_sample -of default^=noprint_wrappers^=1:nokey^=1 "!input!" 2^>nul') do if "%%A"=="10" (
	set "profile=high10"
	set "pixfmt=yuv420p10le"
)

rem count streams
set "countAudioStreams=0"
set "countVideoStreams=0"
set "countChapterStreams=0"
for /f %%C in ('start "" /b /belownormal /wait ffprobe -v error -select_streams a -show_entries stream^=codec_name -of csv^=p^=0 "!input!" 2^>nul ^| find /c /v ""') do (
	if %%C gtr 0 set "countAudioStreams=%%C"
)
for /f %%C in ('start "" /b /belownormal /wait ffprobe -v error -select_streams v -show_entries stream^=codec_name -of csv^=p^=0 "!input!" 2^>nul ^| find /c /v ""') do (
	if %%C gtr 0 set "countVideoStreams=%%C"
)
for /f %%C in ('start "" /b /belownormal /wait ffprobe -v error -select_streams c -show_entries stream^=codec_name -of csv^=p^=0 "!input!" 2^>nul ^| find /c /v ""') do (
	if %%C gtr 0 set "countChapterStreams=%%C"
)

rem get stream titles WIP
rem mp4 muxer metadata degradation!
rem example for later integration -metadata:s:a:0 title="%title0%"
set "queryStreamTitles="
set "indexAudio=0"
set "indexVideo=0"
for /f "tokens=*" %%T in ('start "" /b /belownormal /wait ffprobe -v quiet -select_streams a -show_entries stream_tags^=title -of csv^=p^=0 "!input!" 2^>nul') do (
	set "queryStreamTitles=!queryStreamTitles! -metadata:s:a:!indexAudio! title="%%T""
	set /a "indexAudio=!indexAudio!+1"
)
for /f "tokens=*" %%T in ('start "" /b /belownormal /wait ffprobe -v quiet -select_streams v -show_entries stream_tags^=title -of csv^=p^=0 "!input!" 2^>nul') do (
	set "queryStreamTitles=!queryStreamTitles! -metadata:s:a:!indexVideo! title="%%T""
	set /a "indexVideo=!indexVideo!+1"
)
echo:!queryStreamTitles!
pause


rem 
rem ffprobe -v quiet -select_streams a -show_entries stream_tags=title,stream_tags=name,handler_name -of csv=p=0:nk=1 "Replay 2025-12-01 20-18-12.mkv"
rem mixed
rem game
rem program
rem mic
rem vc

rem empty on mkv, but mp4 returns
rem ffprobe -v error -select_streams a -show_entries stream_tags=handler_name -of csv=p=0 "Replay 2025-12-01 20-18-12.archiv.mp4"
rem SoundHandler
rem SoundHandler
rem SoundHandler
rem SoundHandler
rem SoundHandler











rem prepare query
set "query=-map 0:v -c:v libx264 -profile:v !profile! -tag:v avc1 -crf 18 -preset ultrafast -x264-params ref=4:log-level=error -fps_mode cfr -g 60"
set "query=!query! -map 0:a? -c:a aac -tag:a mp4a -b:a 192k"
set "query=!query! -map_metadata:g 0:g"
rem WIP if not "!queryStreamTitles!"=="" set "query=!query!!queryStreamTitles!"
rem remove later ->
for /L %%I in (1,1,!countAudioStreams!) do (
	set /a "indexAudio=%%~I-1"
	set "query=!query! -map_metadata:s:a:!indexAudio! 0:s:a:!indexAudio!"
)
for /L %%I in (1,1,!countVideoStreams!) do (
	set /a "indexVideo=%%~I-1"
	set "query=!query! -map_metadata:s:v:!indexVideo! 0:s:v:!indexVideo!"
)
for /L %%I in (1,1,!countChapterStreams!) do (
	set /a "indexChapter=%%~I-1"
	set "query=!query! -map_metadata:s:c:!indexChapter! 0:s:c:!indexChapter!"
)
rem remove later <-
set "query=!query! -pix_fmt !pixfmt! -movflags +faststart"
set "query=-metadata comment="Made with !version! !url! !query!" !query!"

echo:!query!
pause

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










rem convert as image with effective alpha
:convertImage
set "outputExtension=jpg"

rem override lossy for lossless
if "!losslessImage!"=="yes" set "outputExtension=png"

rem check effective alpha
if "!outputExtension!!hasAlpha!"=="jpg1" (
	set "alphaMean=255"
	set "tempShowInfo=!tempFolder!showInfo.txt"
	start "" /b /belownormal /wait ffmpeg -hide_banner -i "!input!" -vf alphaextract,showinfo -frames:v 1 -f null - 1>nul 2>"!tempShowInfo!"
	for /f "usebackq delims=" %%A in ("!tempShowInfo!") do (
		echo "%%A" | findstr /i "mean" >nul && (
			for %%B in (%%A) do (
				echo "%%B" | findstr /i "mean" >nul && (
					for /f "tokens=1 delims=]" %%C in ("%%B") do (
						for /f "tokens=2 delims=[" %%D in ("%%C") do (
							if %%D lss 255 set "alphaMean=%%D"
						)
					)
				)
			)
		)
	)
	del !tempShowInfo!
	if !alphaMean! lss 255 set "outputExtension=png"
)

rem archived already exists
if exist "!inputDrivePath!!outputName!.!outputExtension!" (
	echo:EXIST !inputDrivePath!!outputName!.!outputExtension!
	exit /b 0
)

rem announce conversion
echo:CONVERT IMAGE !input!

rem prepare query
if "!outputExtension!"=="jpg" (
	set "query=-map 0 -map_metadata 0 -pix_fmt yuvj420p -q:v 1 -qmin 1"
) else (
	set "query=-map 0 -map_metadata 0 -pix_fmt rgba -compression_level 9"
)

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










rem convert as music with optional cover image
:convertMusic
if "!losslessMusic!"=="yes" (
	set "outputExtension=flac"
) else (
	set "outputExtension=mp3"
)

rem archived already exists
if exist "!inputDrivePath!!outputName!.!outputExtension!" (
	echo:EXIST !inputDrivePath!!outputName!.!outputExtension!
	exit /b 0
)

rem announce conversion
echo:CONVERT MUSIC !input!

rem prepare query
set "query=-map 0 -map_metadata 0"
if "!losslessMusic!"=="yes" (

	set "query=!query! -c:a flac -compression_level 12"
	if "!hasVideo!"=="1" set "query=!query! -disposition:v attached_pic"

) else (

	set "query=!query! -c:a libmp3lame -q:a 0 -id3v2_version 3"
	if "!hasVideo!"=="1" (
		set "query=!query! -metadata:s:v title=#Album cover# -metadata:s:v comment=#Cover (Front)# -c:v mjpeg -q:v 1 -qmin 1 -vf #crop='min(in_w\,in_h)':'min(in_w\,in_h)',scale='if(gt(in_w\,3000)\,3000\,in_w)':'if(gt(in_h\,3000)\,3000\,in_h)':flags=lanczos#"
		set "query=!query:#="!"
	)

)

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










rem move convert output to source folder
:exportFile
rem prepare variables
set "outputExtension=%~1"
set "robocopySource=!tempFolder!"
set "robocopyTarget=!inputDrivePath!"
if "!robocopySource:~-1!"=="\" set "robocopySource=!robocopySource:~0,-1!"
if "!robocopyTarget:~-1!"=="\" set "robocopyTarget=!robocopyTarget:~0,-1!"

rem move file
robocopy "!robocopySource!" "!robocopyTarget!" "!outputName!.!outputExtension!" /MOV /R:3 /W:5 /IS /IT /NFL /NDL /NJH /NJS /NC /NS >nul 2>nul

rem error
if not errorlevel 0 (
	del "!wip!.!outputExtension!"
	color 0C
    echo SAVE !outputName!.!outputExtension!
    pause
	color 07
    exit /b 1
)

rem success
echo:SAVE !inputDrivePath!!outputName!.!outputExtension!
exit /b 0
