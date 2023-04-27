#! /bin/bash

set -xue

p="${1:-2160}"
start_date="${2:-2019-12-01 12:00:00}"
seconds_per_day="${3:-0.14}"
git_dir=/home/pidgeon/src/ufs-weather-model
temp_dir="$git_dir"
output_dir="$git_dir"
title="UFS Weather Model"
caption=$( cd "$git_dir" ; git remote get-url origin )
git_log="$git_dir/combined.log"


# Days per second, rounded to nearest int
days_per_second=$( python -c "print(round(1.0/$seconds_per_day))" )
context="${4:-}"
name="${p}p-${days_per_second}x${context:+-$context}"
date_format="%Y-%b-%d"
days_to_skip=120
fade_in_seconds=3
time_to_skip=$( python -c "print(round($days_to_skip*$seconds_per_day))" )

# Should the logo be used?
# This is disabled by default because it should only be used for official UFS reports.
use_logo="${5:-NO}"
logo=$PWD/UFS-logo-recolored-150dpi.png

# Font sizes relative to 1440p
refp=1440
font_resize() {
    python -c "print(round($2*float($1)*($p/$refp)**0.5))"
}
font_scale=1.0
font_size=$( font_resize 32 $font_scale )
file_font_size=$( font_resize 18 $font_scale )
dir_font_size=$( font_resize 21 $font_scale )
user_font_size=$( font_resize 28 $font_scale )
user_scale=1.5
text_color=AA99FF

# Calculate the horizontal pixel count for a given vertical count (16:9)
hres=$( python -c "print(round($p/9*16))" )
resolution="${hres}x${p}"

# Logo is always 1/14 of the width of the video:
logo_width=$(( hres / 14 ))

converted="$temp_dir/ufs-$name.converted.mp4"
mp4="$output_dir/ufs-$name.mp4"
h265="$output_dir/ufs-$name-h265.mp4"
scaled_logo="$temp_dir/ufs-logo-$p.png"
config_file="$temp_dir/gource-$p.conf"

test -d "$temp_dir" || mkdir -p "$temp_dir"
test -d "$output_dir" || mkdir -p "$output_dir"
rm -f "$converted"
rm -f "$h265"

cd "$temp_dir"

if [[ "${use_logo:-NO}" == YES ]] ; then
    convert -geometry "$logo_width" "$logo" "$scaled_logo"
    test -s "$scaled_logo"
    logo_option="--logo \"$scaled_logo\""
else
    logo_option=" "
fi

xvfb-run gource -o - \
       --stop-at-end --user-scale "$user_scale" --disable-input "-$resolution" \
       --start-date "$start_date" -s "$seconds_per_day" -r 60 \
       --font-size "$font_size" --file-font-size "$file_font_size" \
       --dir-font-size "$dir_font_size" --user-font-size "$user_font_size" \
       --bloom-intensity 0.7 --bloom-multiplier 0.7 --title "$caption" \
       --filename-colour "$text_color" --dir-colour "$text_color" \
       --date-format "$title $date_format" --path "$git_log" \
       $logo_option \
       --frameless --no-vsync --hide filenames | \
ffmpeg -r 60 -codec ppm -i - -r 60 "$converted"
test -s "$converted"
ffmpeg -ss "$time_to_skip" -i "$converted" -vf "fade=t=in:st=0:d=$fade_in_seconds" -codec hevc "$h265"
test -s "$h265"
rm -f "$converted"
ls -l "$h265"
