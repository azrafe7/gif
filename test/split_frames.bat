@echo off

:: splits a gif into png frames, using imagemagick's convert
::
:: usage: split_frames test.gif
::
::        will output test_00.png, test_01.png, test_02.png, etc.

if exist "%1" (
  echo Splitting "%1" ...
  convert -coalesce -verbose "%1" "%~n1_%%02d.png"
) else (
  echo "%1" not found.
)
