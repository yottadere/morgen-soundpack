ECHO "%~1"
for %%f in (%1) do set filename=%%~nf
ffmpeg -i "%~1" -bitexact -acodec pcm_s16le -ar 22050 -ac 1 "%filename%".wav -y