#!/usr/bin/bash

[[ $# -eq 0 || $1 == help || $1 == '?' ]] && echo "Usage: $(basename $0) [audio format] [batch file or youtube video url/ID] [output directory]" && exit

video=()
format=$1
video_or_file="$2"
default_template='%(title)s.%(ext)s'
opts=(-x --audio-format $format --audio-quality best --cookies ~/Downloads/cookies.txt)
opts_start=4

[[ -f "$video_or_file"      ]] && video+=(-a)
[[ -n "$3" && ${3:0:1} != - ]] && out="$3" || out=. opts_start=3

if [[ "$out" == chapter:* ]]; then
  opts+=(-S +res -f ba\* --paths "$out" -o "$out/${default_template/title/section_title}" --split-chapters)
  out="${out:8}"
fi

test . != "$out" && mkdir -p "$_"
out+="/$default_template"
video+=("$video_or_file")
opts+=(--embed-metadata --embed-thumbnail $([[ $format == mkv ]] && printf %s --embed-info-json) --sponsorblock-remove music_offtopic ${@:$opts_start})
exec yt-dlp ${opts[@]} -o "$out" "${video[@]}"
