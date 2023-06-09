#! /bin/bash

usage() {
    echo "Synopsis: run-gource.bash [options] -i /path/to/ufs-weather-model/combined.log -o /path/to/output/h265-file.mp4"
    echo "Options:"
    echo "  -p 2160  =  resolution: 720, 1080, 1440, 2160"
    echo "  -s 2019-12-01 12:00:00 = start date"
    echo "  -d 0.14 = seconds of animation per day of commits"
    echo "  -i /path/to/combined.log = log created by make-commit-log.bash."
    echo "  -o /path/to/output-file.mp4 = output mp4 file; default is ufs-gource.mp4 in the"
    echo "                                same directory as the -i /path/to/combined.log file"
    echo "  -t /path/to/temp/dir = temporary directory. Default is the directory of the -i /path/to/combined.log file"
    echo "  -t 'UFS Weather Model %Y-%b-%d' = title and date format (see man strftime)"
    echo "  -c 'caption' = caption in lower left corner. Default is 'git remote get-url origin' run in the"
    echo "                 same directory as the -i /path/to/combined.log file"
    echo "  -k 120 = number of days of commits to skip. This allows the gource graph to start at full size."
    echo "  -f 3 = number of seconds to fade in"
    echo "  -v = turn on 'set -x'"
    if [[ "$#" -gt 0 ]] ; then
        echo $@
        exit 1
    else
        exit 0
    fi
}

p="2160"
start_date="2019-12-01 12:00:00"
seconds_per_day=0.14
input_file=%
temp_dir=%
output_file=%
title="UFS Weather Model %Y-%b-%d"
caption=%
unscaled_logo=%
days_to_skip=120
fade_in_seconds=3
verbose=NO

while getopts "p:s:d:i:o:T:t:c:l:k:f:vh" opt ; do
    case $opt in
        p) p="$OPTARG" ;;
        s) start_date="$OPTARG" ;;
        d) seconds_per_day="$OPTARG" ;;
        i) input_file="$OPTARG" ;;
        o) output_file="$OPTARG" ;;
        T) temp_dir="$OPTARG" ;;
        t) title="$OPTARG" ;;
        c) caption="$OPTARG" ;;
        l) unscaled_logo="$OPTARG" ;;
        k) days_to_skip="$OPTARG" ;;
        f) fade_in_seconds="$OPTARG" ;;
        v) verbose=YES ;;
        h) usage ; exit 0 ;;
        *) usage "Aborting due to illegal option." 1>&2 ;;
    esac
done

days_per_second=$( python -c "print(round(1.0/$seconds_per_day))" )
log_option='-loglevel warning -stats'

if [[ "${verbose:-NO}" == YES ]] ; then
    set -x
    log_option=' '
fi

# Apply defaults
if [[ "$input_file" == % ]] ; then
    input_file=$PWD/combined.log
fi

if [[ "$temp_dir" == % ]] ; then
    temp_dir=$PWD
fi

if [[ "$output_file" == % ]] ; then
    output_file=$PWD/ufs-${p}p-${days_per_second}x.mp4
fi

if [[ "$caption" == % ]] ; then
    caption=$( cd $( dirname "$input_file" ) && git remote get-url origin )
    caption="${caption:-%}"
fi

# Check for required software
if ( ! which python > /dev/null ) ; then
    echo "Cannot find python in the \$PATH" 1>&2
    exit 1
fi

if [[ "$unscaled_logo" != % ]] && ( ! which convert > /dev/null ) ; then
    echo "Cannot find convert (Imagemagick) in the \$PATH" 1>&2
    exit 1
fi

if [[ "$unscaled_logo" != % ]] && ( ! test -s "$unscaled_logo" > /dev/null ) ; then
    echo "$unscaled_logo: is empty or missing" 1>&2
    exit 1
fi

if ( ! which gource > /dev/null ) ; then
    echo "Cannot find gource in the \$PATH" 1>&2
    exit 1
fi

if ( ! which ffmpeg > /dev/null ) ; then
    echo "Cannot find ffmpeg in the \$PATH" 1>&2
    exit 1
fi

if( ! ffmpeg -codecs 2> /dev/null | grep hevc > /dev/null ) ; then
    echo "Your ffmpeg is missing the hevc (h265) codec!" 1>&2
    exit 1
fi

if ( ! which xvfb-run > /dev/null ) ; then
    echo "Cannot find xvfb-run in the \$PATH" 1>&2
    exit 1
fi

set -ue

# Days per second, rounded to nearest int

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

converted="$temp_dir/converted-$$-$RANDOM-$( basename $output_file )"
scaled_logo="$temp_dir/ufs-logo-$p.png"
output_dir=$( dirname "$output_file" )

test -d "$temp_dir" || mkdir -p "$temp_dir"
test -d "$output_dir" || mkdir -p "$output_dir"
rm -f "$converted"
rm -f "$output_file"

logo_option=" "
fade_option=" "
skip_option=" "

if [[ "$unscaled_logo" != % ]] ; then
    convert -geometry "$logo_width" "$unscaled_logo" "$scaled_logo"
    test -s "$scaled_logo"
    logo_option="--logo $scaled_logo"
fi

if [[ "$days_to_skip" -gt 0 ]] ; then
    time_to_skip=$( python -c "print(round($days_to_skip*$seconds_per_day))" )
    skip_option="-ss $time_to_skip"
fi

if [[ "$fade_in_seconds" -gt 0 ]] ; then
    fade_option="-vf fade=t=in:st=0:d=$fade_in_seconds"
fi

if [[ "${verbose:-NO}" == YES ]] ; then
    echo ========================================================================
    echo
fi

echo Running gource through ffmpeg

if [[ "${verbose:-NO}" == YES ]] ; then
    echo
    echo ========================================================================
fi

xvfb-run gource -o - \
       --stop-at-end --user-scale "$user_scale" --disable-input "-$resolution" \
       --start-date "$start_date" -s "$seconds_per_day" -r 60 \
       --font-size "$font_size" --file-font-size "$file_font_size" \
       --dir-font-size "$dir_font_size" --user-font-size "$user_font_size" \
       --bloom-intensity 0.7 --bloom-multiplier 0.7 --title "$caption" \
       --filename-colour "$text_color" --dir-colour "$text_color" \
       --date-format "$title" --path "$input_file" \
       $logo_option \
       --frameless --no-vsync --hide filenames | \
ffmpeg $log_option -r 60 -codec ppm -i - $log_option -r 60 "$converted"
if [[ ! -s "$converted"  ]] ; then
    echo "$converted: gource|ffmpeg did not generate mp4" 1>&2
    exit 1
fi

echo

if [[ "${verbose:-NO}" == YES ]] ; then
    echo ========================================================================
    echo
fi

echo Applying filters and converting to h265
if [[ "${verbose:-NO}" == YES ]] ; then
    echo
    echo ========================================================================
    echo
fi

ffmpeg $log_option $skip_option -i "$converted" $log_option $fade_option -codec hevc "$output_file"
if [[ ! -s "$output_file" ]] ; then
    echo "$output_file: ffmpeg could not run filters and convert to h265" 1>&2
    exit 1
fi
rm -f "$converted"

if [[ "${verbose:-NO}" == YES ]] ; then
    echo
    echo ========================================================================
    echo
fi

echo Success\!

if [[ "${verbose:-NO}" == YES ]] ; then
    echo
    echo ========================================================================
    echo
fi

ls -l "$output_file"
